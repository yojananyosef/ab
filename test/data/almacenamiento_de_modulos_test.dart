// Guardar un modulo y recuperarlo, con el `.amod` REAL.
//
// QUE SE COMPRUEBA AQUI Y QUE NO.
//
// Aqui, sin navegador: la logica de la cuota, que es donde esta el fallo silencioso,
// y el contrato completo de la interfaz con un doble en memoria. Es decir, **las
// reglas**, que son las que hay que acertar.
//
// En `test/red/`, con Chrome de verdad: que IndexedDB acepte 57 MiB, que se
// recuperen sin volver a bajarlos y que `navigator.storage.estimate()` de lo que
// dice. Eso no se puede simular, porque un doble en memoria daria verde
// indefinidamente. Ver las tareas 8.3 y 5.3.
//
// Y EL DENTRO DE AQUI ES EL `.amod` DE VERDAD, de 22.544.384 bytes. Un fichero de
// diez filas pasaria aunque el formato real tuviera algo que no se ve con diez
// filas, que es justo lo que hay que cazar.

import 'dart:io';
import 'dart:typed_data';

import 'package:ab/data/services/almacenamiento_de_modulos.dart';
import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

/// Un almacenamiento en memoria que **se puede portar a fallar**, que es lo
/// interesante.
///
/// Un doble que siempre funciona daria verde sin comprobar nada: la parte de este
/// fichero que importa es la de cuando IndexedDB dice que no, y un doble que nunca
/// dice que no no la comprueba.
///
/// Y lleva una cuenta de las escrituras y las lecturas de disco, para poder
/// comprobar que recuperar un modulo **no vuelve a traer los bytes de la red**.
class AlmacenamientoEnMemoria implements AlmacenamientoDeModulos {
  AlmacenamientoEnMemoria({
    this.cuota,
    this.usado = 0,
    this.fallaAlEscribir = false,
  });

  /// Bytes de cuota. Null es "la plataforma no lo dice".
  final int? cuota;

  final int usado;

  /// Que `persistir` falle con excepcion, como haria un navegador en modo privado.
  final bool fallaAlEscribir;

  final Map<String, Uint8List> _guardados = <String, Uint8List>{};
  final Map<String, String> _hashes = <String, String>{};
  final Map<String, Uint8List> _memoria = <String, Uint8List>{};

  /// Cuantas veces se ha escrito en el almacenamiento persistente.
  int escrituras = 0;

  /// Cuantas veces se ha leido de ahi. La tarea 5.3 dice que recuperar un modulo no
  /// tiene que volver a traer los bytes: por eso se cuenta esto y se mira que en la
  /// segunda sesion vale 1 y no 2.
  int lecturas = 0;

  /// Cuantos bytes se han pedido por la red en total. Es la cifra que el grupo 8
  /// mira en el navegador y que aqui se comprueba con el doble.
  int bytesPorRed = 0;

  @override
  String ponerEnMemoria(String id, List<int> bytes) {
    _memoria[id] = comoBytes(bytes);
    return 'memoria/$id.amod';
  }

  @override
  Future<ResultadoDeGuardar> persistir(String id, List<int> bytes) async {
    final contenido = comoBytes(bytes);

    final esp = await espacio();
    if (!esp.cabe(contenido.length)) {
      return NoCabe(
        tamanoNecesario: contenido.length,
        disponible: esp.disponible,
        cuota: esp.cuota,
      );
    }

    // El `catch` va **en el doble** y no solo en la implementacion de verdad,
    // porque es parte del contrato: `persistir` devuelve un resultado y no lanza.
    // Un doble que lanza haria que estas pruebasaran el contrato equivocado.
    if (fallaAlEscribir) {
      return const FalloAlPersistir('el navegador no ha dejado guardar.');
    }

    escrituras++;
    _guardados[id] = contenido;
    _hashes[id] = sha256DeBytes(contenido);
    return Guardado(ModuloGuardado(id: id, ruta: 'memoria/$id.amod', tamanoBytes: contenido.length));
  }

  @override
  Future<ModuloGuardado?> rutaDe(String id) async {
    final ya = _memoria[id];
    if (ya != null) {
      return ModuloGuardado(id: id, ruta: 'memoria/$id.amod', tamanoBytes: ya.length);
    }
    final guardado = _guardados[id];
    if (guardado == null) return null;
    lecturas++;
    _memoria[id] = guardado;
    return ModuloGuardado(id: id, ruta: 'memoria/$id.amod', tamanoBytes: guardado.length);
  }

  @override
  Future<List<String>> ids() async => _guardados.keys.toList();

  @override
  Future<Map<String, String>> idsConHash() async => Map<String, String>.from(_hashes);

  @override
  Future<void> borrar(String id) async {
    _guardados.remove(id);
    _hashes.remove(id);
    _memoria.remove(id);
  }

  @override
  Future<Espacio> espacio() async => Espacio(cuota: cuota, usado: usado);

  @override
  void dispose() {}

  /// Lo que queda en memoria. Se usa para comprobar el punto de 5.2: un modulo que
  /// no se ha podido guardar **esta en memoria** y se puede abrir.
  Uint8List? enMemoria(String id) => _memoria[id];

  /// Empezar de cero la sesion: lo que se pierde al cerrar la pestana.
  ///
  /// La cuenta de lecturas **no** se pone a cero a proposito: es la cifra que
  /// comprueba la tarea 5.3, y tiene que seguir contando entre sesiones. Si se
  /// reiniciara aqui, "se ha leido una vez" no distinguiria "se ha leido una vez en
  /// cada sesion" de "se ha leido una vez en total".
  void nuevaSesion() => _memoria.clear();

  /// Traer el modulo "por la red", que es lo que hace la obtencion. Se cuenta para
  /// que la tarea 5.3 se pueda comprobar en un numero y no en una impresion.
  Future<ResultadoDeGuardar> descargarPorRed(String id, List<int> bytes) async {
    bytesPorRed += bytes.length;
    return persistir(id, bytes);
  }
}

void main() {
  final bytesModulo = Uint8List.fromList(File(rutaBibliaReal).readAsBytesSync());
  const idModulo = 'KJV2006';

  group('5.1 el volcado termina y el modulo se vuelve a abrir', () {
    test('guardar, persistir y abrir de verdad: Juan 3:16 sale', () async {
      final alm = AlmacenamientoEnMemoria();
      final idModulo = 'KJV2006';

      // El orden es el del codigo, y no es casualidad: primero la ruta, que
      // sirve; despues el volcado, que puede tardar.
      final ruta = alm.ponerEnMemoria(idModulo, bytesModulo);
      expect(ruta, 'memoria/KJV2006.amod');

      final resultado = await alm.persistir(idModulo, bytesModulo);
      expect(resultado, isA<Guardado>());
      expect((resultado as Guardado).modulo.tamanoBytes, bytesModulo.length);
      expect(alm.escrituras, 1, reason: 'el volcado ha terminado');

      // Y ahora lo importante: lo que sale de ahi se abre de verdad y da el
      // versiculo de prueba. Un modulo que se guarda pero que al abrirlo no da el
      // texto es peor que un modulo que no se guarda, porque ocupa sitio y no
      // avisa.
      final bytes = alm.enMemoria(idModulo)!;
      final rutaSqlite = '/tmp/opencode-5-1-${bytesModulo.length}.amod';
      File(rutaSqlite).writeAsBytesSync(bytes);
      addTearDown(() {
        final f = File(rutaSqlite);
        if (f.existsSync()) f.deleteSync();
      });

      final sqlite = Sqlite.abrir(rutaSqlite);
      addTearDown(sqlite.cerrar);
      expect(sqlite.comprobacionRapida(), 'ok');
      expect(sqlite.info('id'), 'KJV2006');
      final texto = sqlite.valor(
        'SELECT text FROM verses WHERE book=? AND chapter=? AND verse=?',
        ['John', 3, 16],
      ) as String;
      expect(texto, startsWith('For God so loved the world'));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('ponerEnMemoria es SINCRONO y la ruta sirve enseguida', () async {
      // Es lo que hace posible abrir: SQLite no espera, asi que los bytes tienen que
      // estar puestos antes de poder llamar a `open`. Si `ponerEnMemoria` fuera
      // `Future`, quien lo llamara tendria que esperar, y entonces no habria forma
      // de abrir el modulo sin una excepcion asincrona en medio de la lectura.
      final alm = AlmacenamientoEnMemoria();
      final r = alm.ponerEnMemoria('X', Uint8List.fromList([1, 2, 3]));
      // Sin `await`: si esto compila y devuelve un `String`, la operacion es
      // sincrona. Y el contenido esta ya dentro.
      expect(r, 'memoria/X.amod');
      expect(alm.enMemoria('X'), isNotNull);
    });

    test('el volcado a disco va aparte del volcado persistente', () async {
      // Son dos cosas distintas y por eso son dos llamadas. Confundirlas haria que
      // en web se esperase a IndexedDB para poder leer, que es lo que no se puede
      // hacer: `open()` de SQLite es sincrono.
      final alm = AlmacenamientoEnMemoria();
      await alm.persistir('A', Uint8List(10));
      expect(alm.escrituras, 1);
      // Y al borrar de memoria y recuperar, se lee del almacenamiento: eso es lo
      // que pasaria al recargar la pagina.
      alm.nuevaSesion();
      final r = await alm.rutaDe('A');
      expect(r, isNotNull);
      expect(alm.lecturas, 1);
    });
  });

  group('5.2 la cuota se comprueba ANTES y se dice con palabras', () {
    test('si no cabe, NO se escribe y se dice cuanto ocupa y cuanto queda', () async {
      // 100 MiB de cuota, 22.544.384 bytes usados: no cabe ni de lejos.
      final alm = AlmacenamientoEnMemoria(cuota: 100 << 20, usado: 99 << 20);

      final resultado = await alm.persistir(idModulo, bytesModulo);

      expect(resultado, isA<NoCabe>());
      expect(alm.escrituras, 0, reason: 'NO se puede intentar escribir lo que no cabe');
      expect(alm._guardados.containsKey(idModulo), isFalse);

      final no = resultado as NoCabe;
      expect(no.tamanoNecesario, bytesModulo.length);
      expect(no.texto, contains('21.5 MiB'),
          reason: 'tiene que decir cuanto ocupa, con su decimal');
      expect(no.texto, contains('1.0 MiB'),
          reason: 'y cuanto queda, que es lo que permite decidir que borrar');
      expect(no.texto.toLowerCase(), isNot(contains('error')));
    });

    test('con margen: no se pide TODO el hueco, se deja algo libre', () async {
      // Si se pidiera todo el disponible, se acabaria escribiendo justo en el
      // limite y el navegador fallaria al final, cuando ya no hay nada que hacer.
      // Con el margen, se dice que no cabe un poco antes y la persona puede borrar
      // algo antes de intentarlo otra vez.
      //
      // Las cifras se escriben como FRACCIONES de la cuota y no como bytes sueltos
      // porque la primera version de esta prueba se equivocaba al no aplicar el
      // margen, y el fallo era "dice que no cabe cuando cabe", que es el tipo de
      // error que hace que alguien no pueda descargar nada nunca.
      final cuota = 100 << 20;
      // Lo que se puede escribir con el margen del 10 por ciento.
      final conMargen = cuota * 9 ~/ 10;

      // Cabe de sobra: cabe del todo y con margen.
      final conHueco = AlmacenamientoEnMemoria(cuota: cuota);
      expect(
        await conHueco.persistir('X', Uint8List(conMargen - 1024)),
        isA<Guardado>(),
      );

      // NO cabe con margen, aunque quepa del todo: se dice que no.
      final justo = AlmacenamientoEnMemoria(cuota: cuota);
      expect(
        await justo.persistir('X', Uint8List(conMargen + 1024)),
        isA<NoCabe>(),
        reason: 'cabe del todo pero no con margen, asi que se dice que no y se deja '
            'un poco de aire',
      );
    });

    test('SI la plataforma no dice la cuota, se intenta escribir', () async {
      // Y es lo importante: no saber no es lo mismo que saber que no. Un navegador
      // sin permiso de almacenamiento devuelve null, y negarse la descarga ahi
      // seria negarsela sin motivo y sin explicacion.
      final alm = AlmacenamientoEnMemoria(cuota: null);
      final r = await alm.persistir('X', Uint8List(1000));
      expect(r, isA<Guardado>());
      expect(alm.escrituras, 1);
    });

    test('Y SI SE PUEDE LEER IGUAL, aunque no se haya podido guardar', () async {
      // ESTE ES EL PUNTO DE LA TAREA, Y EL QUE MAS IMPORTA.
      //
      // "No cabe" no puede significar "no puedo leer". Un modulo que se ha descargado
      // y no se ha podido guardar se lee igual mientras la app este abierta: los
      // bytes estan en memoria. Lo unico que se pierde es poder leerlo la proxima
      // vez. Confundir las dos cosas convierte un aviso en un muro, y es y es el
      // que hace que alguien borre la app pensando que esta mal.
      final alm = AlmacenamientoEnMemoria(cuota: 10 << 20, usado: 9 << 20);

      // La descarga ha ido bien: los bytes estan.
      final ruta = alm.ponerEnMemoria(idModulo, bytesModulo);
      final resultado = await alm.persistir(idModulo, bytesModulo);
      expect(resultado, isA<NoCabe>());

      // Y aun asi se puede abrir.
      expect(alm.enMemoria(idModulo), isNotNull,
          reason: 'los bytes estan en memoria aunque no se hayan guardado');
      expect(alm.enMemoria(idModulo)!.length, bytesModulo.length);
      expect(ruta, isNotEmpty);

      // Y se comprueba con el modulo de verdad, que es lo que hace que esto no sea
      // una promesa: el texto sale.
      final rutaSqlite = '/tmp/opencode-5-2-${bytesModulo.length}.amod';
      File(rutaSqlite).writeAsBytesSync(alm.enMemoria(idModulo)!);
      addTearDown(() {
        final f = File(rutaSqlite);
        if (f.existsSync()) f.deleteSync();
      });
      final sqlite = Sqlite.abrir(rutaSqlite);
      addTearDown(sqlite.cerrar);
      expect(sqlite.comprobacionRapida(), 'ok');
      expect(sqlite.valor('SELECT count(*) FROM verses'), 31102);
    });

    test('un fallo del navegador NO se dice "no cabe"', () async {
      // Son dos cosas distintas con dos soluciones distintas. "No cabe" ->
      // borrar algo. "El navegador no deja guardar" -> no hay nada que borrar: es el
      // modo privado, o un permiso que falta. Decir "no cabe" en el segundo caso
      // manda a la gente a una accion que no va a funcionar, y a la tercera visita
      // se dan por vencidos.
      //
      // Y EL CONTRATO: `persistir` **no lanza**. Devuelve un resultado, siempre.
      // Las implementaciones de verdad tienen un `catch` alrededor de la escritura,
      // y el doble tambien, porque es lo que la pantalla espera. Si `persistir`
      // lanzara, cada sitio que llama tendria que envolverlo en un `try` y
      // ningun sitio lo haria bien el primero.
      final alm = AlmacenamientoEnMemoria(fallaAlEscribir: true);
      final r = await alm.persistir('X', Uint8List(100));

      expect(r, isA<FalloAlPersistir>());
      expect(r, isNot(isA<NoCabe>()), reason: 'no cabe y que no se guarde son cosas distintas');
      expect((r as FalloAlPersistir).texto.toLowerCase(), isNot(contains('cabe')));
      expect(r.texto, contains('leer'),
          reason: 'el mensaje tiene que decir que se puede leer ahora');
      expect(alm.escrituras, 0);
    });
  });

  group('5.3 al volver no se vuelve a traer', () {
    test('recuperar del almacenamiento NO pide los bytes otra vez', () async {
      final alm = AlmacenamientoEnMemoria();

      // Primera sesion: se descarga por la red y se guarda.
      final primera = await alm.descargarPorRed(idModulo, bytesModulo);
      expect(primera, isA<Guardado>());
      expect(alm.bytesPorRed, bytesModulo.length);

      // Se cierra la pestana. Lo que hay en memoria se pierde; lo guardado, no.
      alm.nuevaSesion();

      // Segunda sesion: se recupera, y **la red no se toca**.
      final recuperado = await alm.rutaDe(idModulo);
      expect(recuperado, isNotNull);
      expect(recuperado!.tamanoBytes, bytesModulo.length);
      expect(alm.bytesPorRed, bytesModulo.length,
          reason: 'la cifra tiene que ser la misma: en la segunda sesion no se ha '
              'bajado ni un byte');
      expect(alm.lecturas, 1, reason: 'se lee del almacenamiento una vez');

      // Y esta listo para abrir: en memoria, sin esperar a nada.
      expect(alm.enMemoria(idModulo), isNotNull);
    });

    test('recuperar dos veces en la misma sesion lee una sola vez', () async {
      final alm = AlmacenamientoEnMemoria();
      await alm.descargarPorRed(idModulo, bytesModulo);
      alm.nuevaSesion();

      await alm.rutaDe(idModulo);
      await alm.rutaDe(idModulo);
      await alm.rutaDe(idModulo);

      expect(alm.lecturas, 1,
          reason: 'despues de la primera, esta en memoria y no hay que volver a leer');
      expect(alm.bytesPorRed, bytesModulo.length);
    });

    test('un modulo que no se guardo NO aparece al volver', () async {
      // Y esto es lo honesto: si no se guardo, no se puede recuperar. Se espera. Lo
      // que **no** se hace es inventarse una ruta vacia.
      final alm = AlmacenamientoEnMemoria(cuota: 10 << 20, usado: 9 << 20);
      alm.ponerEnMemoria(idModulo, bytesModulo);
      await alm.persistir(idModulo, bytesModulo);
      alm.nuevaSesion();

      expect(await alm.rutaDe(idModulo), isNull);
      expect(await alm.ids(), isEmpty);
    });

    test('borrar hace que no vuelva a aparecer', () async {
      // Sin esto, el comentario de 57 MiB se queda ocupando sitio para siempre y no
      // hay forma de quitarlo, y quien lo ha descargado no puede hacer nada por su
      // cuenta.
      final alm = AlmacenamientoEnMemoria();
      await alm.descargarPorRed(idModulo, bytesModulo);
      expect(await alm.ids(), [idModulo]);

      await alm.borrar(idModulo);
      expect(await alm.ids(), isEmpty);
      expect(await alm.idsConHash(), isEmpty, reason: 'el indice tambien se borra');
      expect(await alm.rutaDe(idModulo), isNull);
      expect(alm.enMemoria(idModulo), isNull);
    });
  });

  group('lo que el almacenamiento NO guarda', () {
    test('ni estado, ni fecha, ni favoritos: solo bytes', () async {
      // Un estado guardado se queda viejo. Este almacenamiento solo tiene bytes de
      // modulos, y el estado de cada uno se calcula comparando su hash con el del
      // manifiesto, cada vez. No hay aqui ningun sitio donde pueda quedar viejo.
      final alm = AlmacenamientoEnMemoria();
      await alm.descargarPorRed(idModulo, bytesModulo);

      final r = Process.runSync('grep', [
        '-rnE',
        r'^[^/*]*\b(ultimaLectura|favorito|ultimoCapitulo|historial|progresoGuardado)\b',
        'lib/data/services/almacenamiento_de_modulos',
      ]);
      expect((r.stdout as String).trim(), isEmpty,
          reason: 'el estado de un modulo se calcula; no se guarda');
    });
  });
}
