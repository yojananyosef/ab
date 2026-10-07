// Donde viven los resaltados en el navegador: IndexedDB.
//
// ============================================================================
// POR QUE UNA BASE **PROPIA** Y NO UN ALMACEN MAS DE LA DE MODULOS
// ============================================================================
//
// Medido en `almacenamiento_de_modulos_web.dart`, y el fallo esta escrito alli:
//
//     abrir dos veces a la vez hace que la segunda se quede esperando un
//     `onupgradeneeded` que no va a llegar
//
// Anadir un almacen a la base `ab` obliga a subir `_versionDb` de 1 a 2, y esa subida **es**
// un `onupgradeneeded`. Con la aplicacion abierta en dos pestanas --que es lo normal en un
// lector-- la segunda se queda esperando una transaccion de version que no va a llegar.
//
// O sea: **anadir los resaltados al mismo sitio donde viven los modulos rompe la aplicacion**
// para quien tenga dos pestanas. Y el fallo es silencioso otra vez: la segunda pestana se
// queda esperando y no dice nada.
//
// Y LA SEGUNDA RAZON, que ya esta escrita en la interfaz de los resaltados: «borrar los
// modulos que no uso para ganar sitio» es una accion de limpieza, y `AGENTS.md` prohibe que
// una accion de limpieza limpie tambien el trabajo de la persona. Con dos bases distintas no
// hay forma de que lo haga **ni por error**: `deleteDatabase('ab')` no ve `ab-resaltados`.
//
// ============================================================================
// Y POR QUE VA A PELO, CON `dart:js_interop`, Y NO CON UN PAQUETE
// ============================================================================
//
// El motivo esta escrito en el fichero de modulos y es el mismo: `package:idb_shim` envuelve
// bien la API pero **no funciona en la VM**, y aqui se hacen pruebas de Dart puro. Un paquete
// que solo existe para el navegador obliga a que las pruebas que no son de navegador no se
// puedan escribir.
//
// ============================================================================
// Y POR QUE DOS ALMACENES Y NO UNO
// ============================================================================
//
// Porque los estilos **se cambian** --se renombran, se recolorean-- mucho mas que los
// resaltados, y guardarlos juntos obliga a reescribir todos los resaltados para cambiar el
// nombre de un estilo. Con dos almacenes, renombrar es una escritura y los miles de
// resaltados no se tocan.
//
// Y ADEMAS ES LA DIFERENCIA ENTRE "UN DATO" Y "UN AJUSTE": un resaltado es un versiculo con
// un estilo, y un estilo es una manera de marcar. Lo que la persona **escribe** --el nombre
// del estilo-- va en el almacen de los datos; la forma de marcar, que se puede cambiar sin
// perder nada, va con la configuracion.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:ab/domain/models/resaltado.dart';

import 'almacenamiento_de_resaltados.dart';
import 'resaltado_web.dart';

/// La base de datos de los resaltados. **Propia**, y no un almacen de la de los modulos.
///
/// El motivo --el bloqueo de version con dos pestanas-- esta en la cabecera del fichero, y es
/// la razon de que este nombre no sea `ab`.
const String _nombreDb = 'ab-resaltados';
const int _versionDb = 1;

/// Donde van los resaltados: uno por versiculo, con su estilo.
const String _almacenDeResaltados = 'resaltados';

/// Donde van los estilos, que son pocos y se cambian.
const String _almacenDeEstilos = 'estilos';

class AlmacenamientoDeResaltadosWeb implements AlmacenamientoDeResaltados {
  AlmacenamientoDeResaltadosWeb();

  web.IDBDatabase? _db;
  Future<web.IDBDatabase>? _abriendo;

  @override
  Future<Set<String>> claves() async {
    final db = await _abrir();
    final peticion = db
        .transaction(_almacenDeResaltados.toJS, 'readonly')
        .objectStore(_almacenDeResaltados)
        .getAllKeys();
    final crudos = (await _esperarRaw(peticion))?.dartify();
    if (crudos is! List) return <String>{};
    return <String>{
      for (final k in crudos.cast<Object?>())
        if (k is String) k,
    };
  }

  @override
  Future<Resaltado?> de(String clave) async {
    final db = await _abrir();
    final peticion = db
        .transaction(_almacenDeResaltados.toJS, 'readonly')
        .objectStore(_almacenDeResaltados)
        .get(clave.toJS);
    return resaltadoDesdeJs(await _esperarRaw(peticion));
  }

  @override
  Future<List<Resaltado>> todos() async {
    final db = await _abrir();
    final peticion = db
        .transaction(_almacenDeResaltados.toJS, 'readonly')
        .objectStore(_almacenDeResaltados)
        .getAll();
    final crudos = (await _esperarRaw(peticion))?.dartify();
    if (crudos is! List) return <Resaltado>[];

    // Y UNO A UNO Y DESCARTANDO, y no un `map`. Un registro que no se puede leer **no puede
    // impedir** leer los demas: si un solo registro raro hiciera fallar el `getAll` entero,
    // un resaltado mal escrito seria la perdida de los miles que estan bien.
    final salida = <Resaltado>[];
    for (final c in crudos.cast<Object?>()) {
      final leido = resaltadoDesdeJs(c.jsify());
      if (leido != null) salida.add(leido);
    }
    return salida;
  }

  @override
  Future<void> poner(Resaltado resaltado) async {
    final db = await _abrir();
    final tx = db.transaction(_almacenDeResaltados.toJS, 'readwrite');
    tx.objectStore(_almacenDeResaltados)
        .put(resaltado.aJs().jsify()!, resaltado.clave.toJS);
    // Y SE ESPERA A QUE TERMINE LA TRANSACCION, y no solo a que acepte la peticion. Aceptarla
    // no es guardarla: la transaccion puede fallar **despues**, al confirmar, por ejemplo si
    // se agota la cuota. Con solo la peticion, `poner` dira «ok» de un resaltado que no esta en
    // ningun sitio, que es justo el fallo que este change arregla.
    await _esperarTransaccion(tx);
  }

  @override
  Future<void> quitar(String clave) async {
    final db = await _abrir();
    final tx = db.transaction(_almacenDeResaltados.toJS, 'readwrite');
    tx.objectStore(_almacenDeResaltados).delete(clave.toJS);
    await _esperarTransaccion(tx);
  }

  @override
  Future<List<EstiloDeResaltado>> estilos() async {
    final db = await _abrir();
    final peticion = db
        .transaction(_almacenDeEstilos.toJS, 'readonly')
        .objectStore(_almacenDeEstilos)
        .getAll();
    final crudos = (await _esperarRaw(peticion))?.dartify();
    if (crudos is! List) return <EstiloDeResaltado>[];

    final salida = <EstiloDeResaltado>[];
    for (final c in crudos.cast<Object?>()) {
      final leido = estiloDesdeJs(c.jsify());
      if (leido != null) salida.add(leido);
    }
    return salida;
  }

  @override
  Future<void> guardarEstilo(EstiloDeResaltado estilo) async {
    final db = await _abrir();
    final tx = db.transaction(_almacenDeEstilos.toJS, 'readwrite');
    tx.objectStore(_almacenDeEstilos).put(estilo.aJs().jsify()!, estilo.id.toJS);
    await _esperarTransaccion(tx);
  }

  @override
  Future<void> borrarTodo() async {
    final db = await _abrir();
    // Y LOS **DOS** ALMACENES, y no solo el de los resaltados. Borrar los resaltados y dejar
    // los estilos es un estado que no existe en la interfaz y que hace que al volver a marcar
    // salgan los estilos viejos de una persona que los habia cambiado.
    final tx = db.transaction(_nombresJs, 'readwrite');
    tx.objectStore(_almacenDeResaltados).clear();
    tx.objectStore(_almacenDeEstilos).clear();
    await _esperarTransaccion(tx);
  }

  @override
  void dispose() {
    final db = _db;
    _db = null;
    _abriendo = null;
    db?.close();
  }

  // --- la base ---

  /// Los dos nombres, como `JSArray`, que es lo que pide `transaction` para varios almacenes.
  ///
  /// Y SE CONSTRUYE **UNA VEZ** Y EN UN `final` DE TIPO `static`, y no en cada `borrarTodo`:
  /// `transaction` **consume** el array --no lo reutiliza-- asi que uno reutilizado daria una
  /// transaccion sin almacenes en la segunda llamada, que es un `borrarTodo` que no borra y no
  /// dice nada. Y al ser `static final`, se construye una vez por isolate.
  static final JSArray<JSAny?> _nombresJs = <String>[
        _almacenDeResaltados,
        _almacenDeEstilos,
      ].jsify()! as JSArray<JSAny?>;

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
      if (!base.objectStoreNames.contains(_almacenDeResaltados)) {
        base.createObjectStore(_almacenDeResaltados);
      }
      if (!base.objectStoreNames.contains(_almacenDeEstilos)) {
        base.createObjectStore(_almacenDeEstilos);
      }
    }).toJS;

    final db = (await _esperarRaw(peticion)) as web.IDBDatabase;
    _db = db;

    // Y SI OTRA PESTANA CIERRA LA BASE O SUBE LA VERSION, ESTE `Future` SE QUEDA OBSOLETO y
    // `persistir` no volveria a abrir nunca. Se suelta para que la siguiente llamada lo haga:
    // sin esto, cerrar y volver a abrir la pestana es una app que deja de funcionar sin que se
    // pueda recuperar sin recargar. Es el mismo motivo que en el almacen de modulos, y por eso
    // se copia tambien.
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
  /// Y SE LLAMA `_esperarRaw` Y NO `_esperar` A PROPOSITO: el resultado viene como `JSAny?`
  /// porque las peticiones de IndexedDB devuelven de todo --un objeto, un numero, un array-- y
  /// quien llama tiene que decir de que tipo es. Un metodo que devolviera `T` con la
  /// conversion dentro esconderia un error en un metodo que no dice nada, y el fallo apareceria
  /// en el sitio de la llamada.
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

  /// Espera a que una transaccion termine **de verdad**.
  ///
  /// Por `oncomplete`, y no por la peticion: una transaccion puede fallar **despues** --al
  /// confirmarse, si se agota la cuota-- y en ese caso el `onerror` de la peticion individual
  /// ya ha pasado sin decir nada.
  Future<void> _esperarTransaccion(web.IDBTransaction tx) {
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
}

/// La implementacion de este fichero.
///
/// Y NO LA FABRICA COMUN DE `almacenamiento_de_resaltados.dart`, a diferencia de los modulos,
/// y es una decision: el almacen de modulos se crea **por una condicion** --el motor de
/// obtencion de bytes-- y el de resaltados se crea **siempre**. Un `almacenamiento_..._nativo.dart`
/// para una interfaz que en nativo todavia no se puede comprobar seria escribir el mismo
/// fichero dos veces para no comprobar ninguno.
AlmacenamientoDeResaltados crearAlmacenamiento() => AlmacenamientoDeResaltadosWeb();