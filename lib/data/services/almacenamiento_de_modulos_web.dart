// Donde viven los modulos en el navegador: IndexedDB.
//
// Uno de los dos ficheros que saben en que plataforma estamos.
//
// QUE HACE Y POR QUE NO SE USA UN PAQUETE. IndexedDB es una API asincrona de
// callback, y `package:idb_shim` la envuelve bien pero **no funciona en la VM**:
// aqui se hacen pruebas de Dart puro, y un paquete que solo existe para el
// navegador obliga a que las pruebas que no son de navegador no se puedan
// escribir. Ademas obliga a condicionar el import en mas sitios de los que este
// fichero.
//
// Por eso va a pelo, con `dart:js_interop`. Son unas 130 lineas y son las unicas que
// hablan con la base de datos del navegador.
//
// `localStorage` queda descartado por una razon concreta y medida: son unos 5 MB, y
// el comentario ocupa 57.536.512 bytes. Ademas guarda cadenas, asi que un binario
// pasaria por `btoa`, que no aguanta bytes altos.
//
// LA ESCRITURA Y POR QUE NO ES SINCRONA. `IDBObjectStore.put` devuelve una
// peticion, y hay que esperar a que la transaccion termine para saber si ha
// funcionado. Por eso [persistir] es `Future`. Y por eso [ponerEnMemoria] **no**
// escribe aqui sino en el sistema de ficheros virtual: SQLite abre de forma sincrona
// y no puede esperar. El orden es siempre el mismo, y esta escrito en el fichero de
// la interfaz.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'almacenamiento_de_modulos.dart';
import 'hash_service.dart';
import 'sqlite_web.dart';

/// La base de datos. Un solo nombre y un solo numero de version.
const String _nombreDb = 'ab';
const int _versionDb = 1;

/// El almacen donde van los bytes. Uno solo y sin indices: se busca por clave
/// primaria y ya, que es como se usa.
///
/// Un indice por tamano o por fecha no hace falta para nada de lo que hace la app,
/// y cada indice son unos bytes por modulo que el navegador tiene que mantener.
const String _almacen = 'modulos';

class AlmacenamientoDeModulosWeb implements AlmacenamientoDeModulos {
  AlmacenamientoDeModulosWeb();

  web.IDBDatabase? _db;
  Future<web.IDBDatabase>? _abriendo;

  /// La ruta que se da a SQLite. Solo son los bytes del identificador, que ya
  /// viene del manifiesto y no es texto libre.
  ///
  /// Se pone en un subdirectorio `modulos/` para que no se mezle con nada que otro
  /// pueda escribir en el sistema de ficheros virtual, que es compartido.
  String _ruta(String id) => 'modulos/$id.amod';

  @override
  String ponerEnMemoria(String id, List<int> bytes) {
    // Esto es lo que hace posible abrir el modulo: SQLite ve el sistema de
    // ficheros virtual, y los bytes estan ahi antes de que se llame a `open`.
    escribirEnDispositivo(_ruta(id), bytes);
    return _ruta(id);
  }

  @override
  Future<ResultadoDeGuardar> persistir(String id, List<int> bytes) async {
    final contenido = comoBytes(bytes);
    final sha256Esperado = sha256DeBytes(bytes);

    // 5.2. La cuota se mira ANTES de escribir. Despues ya no hay nada que hacer,
    // y el fallo de escritura no dice ni cuanto ocupa ni cuanto queda.
    final esp = await espacio();
    if (esp != null && !esp.cabe(contenido.length)) {
      return NoCabe(
        tamanoNecesario: contenido.length,
        disponible: esp.disponible,
        cuota: esp.cuota,
      );
    }

    try {
      final db = await _abrir();
      final tx = db.transaction(_almacen.toJS, 'readwrite');
      tx.objectStore(_almacen).put(
        _registro(id, contenido, sha256Esperado).jsify()!,
        id.toJS,
      );
      // Se espera a que termine la transaccion, y no solo a que acepte la
      // peticion. Aceptarla no es guardarla: la transaccion puede fallar despues,
      // al confirmar, y ese es exactamente el fallo que hace que un modulo parezca
      // guardado y no lo este, y que se descubra al recargar.
      await _esperarTransaccion(tx);
      return Guardado(
        ModuloGuardado(id: id, ruta: _ruta(id), tamanoBytes: contenido.length),
      );
    } catch (e) {
      // Y ESTE NO ES "NO CABE". Puede ser el navegador en modo privado, o una cuota
      // cambiada entre la pregunta y la escritura, o el disco lleno. Decir "no
      // cabe" cuando lo que pasa es "el navegador no deja guardar" manda a la
      // gente a borrar cosas que no tienen nada que ver.
      return FalloAlPersistir('el navegador no ha dejado guardar');
    }
  }

  @override
  Future<ModuloGuardado?> rutaDe(String id) async {
    final ruta = _ruta(id);

    // Camino corto: ya esta en la memoria de esta sesion. Es el caso normal al
    // saltar de una pantalla a otra, y no debe costar nada.
    if (existeEnDispositivo(ruta)) {
      final bytes = leerDeDispositivo(ruta);
      return ModuloGuardado(id: id, ruta: ruta, tamanoBytes: bytes?.length ?? 0);
    }

    // 5.3. El modulo se recupera del almacenamiento **sin volver a traer los bytes
    // de la red**. Esto es lo que hace que la segunda visita no baje 22 MiB.
    try {
      final db = await _abrir();
      final registro = await _leerRegistro(db, id);
      if (registro == null) return null;

      escribirEnDispositivo(ruta, registro.bytes);
      return ModuloGuardado(id: id, ruta: ruta, tamanoBytes: registro.bytes.length);
    } catch (_) {
      // Si el almacenamiento no responde, se dice que no esta. La alternativa es
      // propagar el error y dejar la app sin arranque, que es peor: lo que se
      // pierde es el modo sin conexion, no la app.
      return null;
    }
  }

  @override
  Future<List<String>> ids() async {
    try {
      final db = await _abrir();
      final tx = db.transaction(_almacen.toJS, 'readonly');
      final peticion = tx.objectStore(_almacen).getAllKeys();
      // `getAllKeys` devuelve un array del navegador, no una lista de Dart: hay que
      // pasarlo por `dartify` y entonces ya es una `List`.
      final crudo = (await _esperarRaw(peticion))?.dartify();
      if (crudo is! List) return const <String>[];
      return crudo.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Future<Map<String, String>> idsConHash() async {
    try {
      final db = await _abrir();
      final tx = db.transaction(_almacen.toJS, 'readonly');
      final peticion = tx.objectStore(_almacen).getAll();
      final crudo = (await _esperarRaw(peticion))?.dartify();
      if (crudo is! List) return const <String, String>{};

      final salida = <String, String>{};
      for (final e in crudo) {
        if (e is! Map) continue;
        final id = e['id'];
        final sha = e['sha256'];
        // Sin hash, sin entrada: se prefiere que la pantalla lo trate como "sin
        // comprobar" a que se le pase un hash inventado.
        if (id is! String || sha is! String || sha.length != 64) continue;
        salida[id] = sha;
      }
      return salida;
    } catch (_) {
      return const <String, String>{};
    }
  }

  @override
  Future<void> borrar(String id) async {
    // Primero el sistema de ficheros virtual, que es sincrono y no puede fallar.
    // Asi, aunque IndexedDB no responda, el modulo desaparece de la sesion.
    borrarDeDispositivo(_ruta(id));
    try {
      final db = await _abrir();
      final tx = db.transaction(_almacen.toJS, 'readwrite');
      tx.objectStore(_almacen).delete(id.toJS);
      await _esperarTransaccion(tx);
    } catch (_) {
      // Borrar es la operacion que mas se echa de menos cuando falla: si el
      // comentario de 57 MiB se queda y no se puede quitar, la persona ya no
      // puede hacer nada por su cuenta. Se ha hecho todo lo que se puede sin red.
    }
  }

  @override
  Future<Espacio?> espacio() async {
    try {
      final estimacion = await web.window.navigator.storage.estimate().toDart;
      return Espacio(cuota: estimacion.quota, usado: estimacion.usage);
    } catch (_) {
      // Sin `estimate()`, que es el caso de un navegador sin permiso de
      // almacenamiento. Null significa "no se sabe", y con null se intenta
      // escribir: es preferible un fallo dicho a una descarga negada sin motivo.
      return null;
    }
  }

  @override
  void dispose() {
    _db?.close();
    _db = null;
    _abriendo = null;
  }

  // --- privados ---

  /// Abre la base de datos, o devuelve la que ya esta abierta.
  ///
  /// El `Future` se guarda porque abrir dos veces a la vez hace que la segunda se
  /// quede esperando un `onupgradeneeded` que no va a llegar: el primer `open`
  /// resuelve el primero y el segundo se queda colgado para siempre. Es el fallo
  /// clasico de IndexedDB y no dice nada cuando pasa, solo que el boton no
  /// responde.
  Future<web.IDBDatabase> _abrir() {
    final ya = _db;
    if (ya != null) return Future<web.IDBDatabase>.value(ya);
    return _abriendo ??= _abrirDeVerdad();
  }

  Future<web.IDBDatabase> _abrirDeVerdad() async {
    final peticion = web.window.indexedDB.open(_nombreDb, _versionDb);
    peticion.onupgradeneeded = ((web.Event _) {
      final db = peticion.result;
      if (db == null) return;
      final base = db as web.IDBDatabase;
      if (!base.objectStoreNames.contains(_almacen)) {
        base.createObjectStore(_almacen);
      }
    }).toJS;

    // `IDBOpenDBRequest` no redefine `result`: el paquete lo deja como `JSAny?`,
    // asi que hay que convertirlo. Se hace aqui y en ningun otro sitio, porque son
    // las dos unicas peticiones cuyo resultado no es un valor sino un objeto con
    // metodos.
    final db = (await _esperarRaw(peticion)) as web.IDBDatabase;
    _db = db;

    // Si otra pestana cierra la base o sube la version, este `Future` se queda
    // obsoleto y `persistir` no volveria a abrir nunca. Se suelta para que la
    // siguiente llamada lo haga. Sin esto, cerrar y volver a abrir la pestana es
    // una app que deja de funcionar y no hay forma de recuperarla sin recargar.
    final olvidar = ((web.Event _) {
      _db = null;
      _abriendo = null;
    }).toJS;
    db.onclose = olvidar;
    db.onversionchange = olvidar;

    return db;
  }

  /// Espera a que termine una peticion de IndexedDB y devuelve su resultado.
  ///
  /// IndexedDB no tiene promesas: todo son eventos. Este es el unico sitio donde se
  /// traducen, y por eso es el unico sitio donde se puede equivocar uno.
  ///
  /// Se llama [_esperarRaw] y no [_esperar] a proposito, y es una distincion que
  /// parece de estilo: el resultado viene como `JSAny?` porque las peticiones de
  /// IndexedDB devuelven de todo --un objeto, un numero, un array-- y quien llama
  /// tiene que decir de que tipo es. Si el metodo devolriera `T` con una conversion
  /// dentro, habria una conversion fallida escondida en un metodo que no dice
  /// nada, y el error apareceria en el sitio de la llamada.
  Future<JSAny?> _esperarRaw(web.IDBRequest peticion) {
    final completer = Completer<JSAny?>();
    peticion.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(peticion.error ?? 'fallo de IndexedDB');
      }
    }).toJS;
    peticion.onsuccess = ((web.Event _) {
      if (!completer.isCompleted) completer.complete(peticion.result);
    }).toJS;
    return completer.future;
  }

  /// Espera a que una transaccion termine de verdad.
  ///
  /// Es distinto de esperar a la peticion: una peticion puede tener exito y la
  /// transaccion fallar despues, por ejemplo si se agota la cuota al confirmar. Es
  /// justo el fallo que hace que un modulo parezca guardado y no lo este.
  Future<void> _esperarTransaccion(web.IDBTransaction tx) async {
    final completer = Completer<void>();
    tx.oncomplete = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    tx.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(tx.error ?? 'transaccion fallida');
      }
    }).toJS;
    tx.onabort = ((web.Event _) {
      if (!completer.isCompleted) completer.completeError('transaccion abortada');
    }).toJS;
    return completer.future;
  }

  Future<_Registro?> _leerRegistro(web.IDBDatabase db, String id) async {
    final tx = db.transaction(_almacen.toJS, 'readonly');
    final peticion = tx.objectStore(_almacen).get(id.toJS);
    final valor = (await _esperarRaw(peticion))?.dartify();
    if (valor is! Map) return null;

    final bytes = valor['bytes'];
    if (bytes is! Uint8List) return null;
    return _Registro(Uint8List.fromList(bytes), valor['tamano'] as int?);
  }

  Map<String, Object?> _registro(String id, Uint8List bytes, String sha256) => <String, Object?>{
    'id': id,
    'bytes': bytes,
    'tamano': bytes.length,
    // El hash va en el registro porque es lo que permite saber, al arrancar, si el
    // modulo guardado es el que anuncia el catalogo. Sin el habria que leer los 57
    // MiB para comprobarlo, en cada arranque.
    'sha256': sha256,
  };
}

class _Registro {
  const _Registro(this.bytes, this.tamano);
  final Uint8List bytes;
  final int? tamano;
}

/// La implementacion de este fichero. La llama la fabrica comun de
/// `almacenamiento_de_modulos.dart`, que es el unico sitio donde se decide.
AlmacenamientoDeModulos crearAlmacenamiento() => AlmacenamientoDeModulosWeb();
