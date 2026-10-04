// El arranque, y sobre todo la garantia que tiene.
//
// QUE SE COMPRUEBA. Que el catalogo **se ve** aunque el almacenamiento no conteste
// nunca, y que cuando no conteste se **dice**.
//
// POR QUE ESTE FICHERO EXISTE. La app se desplego, se abrio en un Chrome de verdad
// y se vio una biblioteca **vacia** con el texto "El catalogo no declara ningun
// modulo todavia". Era mentira: el catalogo declara dos. Lo que no contestaba era
// `indexedDB.open`, que en ese navegador no dispara ni `onsuccess` ni `onerror` ni
// `onblocked`. Medido el 4 de octubre de 2026, con el `fetch` de al lado devolviendo
// HTTP 200 y `tag=v0.1.1`.
//
// Y el aviso **no salia**, porque el `await` del almacenamiento estaba antes de
// aplicar el resultado en pantalla. O sea que la app no fallaba: fallaba
// **mintiendo**, en silencio, con un texto que parecia el correcto.
//
// El doble que "se queda colgado" no es un adorno decorativo: es el caso que mas
// caro ha salido en este repositorio.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ab/app/arranque.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/services/almacenamiento_de_modulos.dart';
import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plazo corto para que las pruebas no tarden cinco segundos.
///
/// El de verdad esta en [plazoDelAlmacenamiento] y lo prueba una de estas, para que
/// el valor no se pueda cambiar sin que alguien se entere.
const Duration plazoCorto = Duration(milliseconds: 150);

/// 64 caracteres validos, para el modulo retirado de la prueba.
const String _hashDePrueba =
    'aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff0000000011111111';

/// Un almacenamiento que se comporta como uno real en cada uno de sus modos.
///
/// Los tres modos existen porque **los tres se han dado**:
///
/// - [colgado] como el `indexedDB.open` de Chrome: no contesta y no avisa.
/// - [sinPermiso] como el modo privado, o un navegador sin almacenamiento.
/// - [con datos] como uno que va bien.
class AlmacenamientoFalso implements AlmacenamientoDeModulos {
  AlmacenamientoFalso({
    this.colgado = false,
    this.sinPermiso = false,
    this.sinHashes = false,
    this.idsLocales = const <String>{},
    this.hashes = const <String, String>{},
    this.alPreguntar,
  });

  /// Nunca contesta, y nunca avisa. Es el caso del fallo.
  final bool colgado;

  /// Contesta con una excepcion.
  final bool sinPermiso;

  /// Los ids se pueden leer pero los hashes no. Es un caso distinto de [colgado]: la
  /// biblioteca se llena, y lo que no se puede es distinguir "descargado" de "hay
  /// version nueva". Puede pasar si el indice se perdio y no se ha vuelto a escribir.
  final bool sinHashes;

  final Set<String> idsLocales;
  final Map<String, String> hashes;

  /// Se llama justo antes de responder. Lo usa una prueba para mirar que hay en
  /// pantalla en ese instante, que es como se comprueba el orden.
  final void Function()? alPreguntar;

  @override
  Future<List<String>> ids() async {
    alPreguntar?.call();
    if (colgado) return Completer<List<String>>().future;
    if (sinPermiso) throw StateError('el navegador no deja usar el almacenamiento');
    return idsLocales.toList();
  }

  @override
  Future<Map<String, String>> idsConHash() async {
    alPreguntar?.call();
    if (colgado) return Completer<Map<String, String>>().future;
    if (sinPermiso) throw StateError('el navegador no deja usar el almacenamiento');
    if (sinHashes) return const <String, String>{};
    return Map<String, String>.from(hashes);
  }

  @override
  String ponerEnMemoria(String id, List<int> bytes) => 'falso/$id.amod';

  @override
  Future<ResultadoDeGuardar> persistir(String id, List<int> bytes) async =>
      Guardado(ModuloGuardado(id: id, ruta: 'falso/$id.amod', tamanoBytes: bytes.length));

  @override
  Future<ModuloGuardado?> rutaDe(String id) async =>
      idsLocales.contains(id)
          ? ModuloGuardado(id: id, ruta: 'falso/$id.amod', tamanoBytes: 1)
          : null;

  @override
  Future<Espacio?> espacio() async => null;

  @override
  Future<void> borrar(String id) async {}

  @override
  void dispose() {}
}

/// El manifiesto REAL de los fixtures, con los numeros del catalogo publicado.
///
/// Se lee con `dart:convert` y **no** con el mapeo del repositorio, a proposito: si
/// usara el mapeo, estas pruebas comprobarian el repositorio contra si mismo. Y se
/// leen de los fixtures, no de la red: el arranque se prueba con un manifiesto
/// conocido. Que el publicado siga siendo este lo comprueba `test/red/`.
final Manifiesto manifiestoReal = _manifiestoReal();

Manifiesto _manifiestoReal() {
  final j = jsonDecode(File('test/fixtures/catalog_real.json').readAsStringSync())
      as Map<String, dynamic>;
  return Manifiesto(
    formato: j['format'] as String,
    version: j['version'] as String,
    etiqueta: j['version'] as String,
    modulos: <Modulo>[
      for (final e in j['modules'] as List)
        Modulo(
          id: (e as Map<String, dynamic>)['id'] as String,
          nombre: e['name'] as String,
          tipo: TipoModulo.desdeCatalogo(e['type'] as String)!,
          idioma: e['language'] as String,
          licencia: e['license'] as String,
          tamanoBytes: e['sizeBytes'] as int,
          sha256: e['sha256'] as String,
          urlDescarga: Uri.parse(e['downloadUrl'] as String),
          urlNavegador: Uri.parse(e['browserUrl'] as String),
        ),
    ],
  );
}

ResultadoCatalogo _resultadoDelServidor() =>
    ResultadoCatalogo(manifiesto: manifiestoReal, estado: EstadoLectura.delServidor);

void main() {
  group('la garantia: el catalogo se ve SIEMPRE', () {
    test('con el almacenamiento bien, todo normal', () async {
      final vista = BibliotecaViewModel();
      final shaReal = (manifiestoReal.porId('KJV2006')!).sha256;
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        // Un almacenamiento que va bien trae ids **y** hashes. Con ids sin hashes no
        // se puede comprobar la version, y eso ya es el caso de abajo.
        almacenamiento: AlmacenamientoFalso(
          idsLocales: const <String>{'KJV2006'},
          hashes: <String, String>{'KJV2006': shaReal},
        ),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(r.sabeLoQuePasa, isTrue);
      expect(r.hayIdsLocales, isTrue);
      expect(r.hayHashesLocales, isTrue);
      expect(vista.filas.length, 2);
      expect(r.avisos, isEmpty);
      expect(vista.cargando, isFalse, reason: 'la pantalla no se queda en "cargando"');
      expect(
        vista.filas.firstWhere((f) => f.id == 'KJV2006').estado,
        EstadoModulo.descargado,
      );
    });

    test('con el almacenamiento COLGADO, el catalogo se ve igualmente', () async {
      // El caso que hizo falta este fichero.
      final vista = BibliotecaViewModel();
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(colgado: true),
        vista: vista,
        plazo: plazoCorto,
      );

      // LO IMPORTANTE: los dos modulos estan en pantalla.
      expect(vista.filas.length, 2);
      expect(vista.filas.map((f) => f.id).toList(), ['KJV2006', 'CLARKE']);
      expect(vista.catalogoVacio, isFalse, reason: 'el catalogo NO esta vacio');
      expect(r.sabeLoQuePasa, isTrue);

      // Y se dice, en vez de quedarse muda.
      expect(r.hayIdsLocales, isFalse);
      expect(r.avisos, isNotEmpty);
      expect(vista.avisos.first, contains('almacenamiento'),
          reason: 'el aviso tiene que decir QUE es lo que no ha contestado');
    });

    test('con el almacenamiento sin permiso, tambien', () async {
      final vista = BibliotecaViewModel();
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(sinPermiso: true),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(vista.filas.length, 2);
      expect(r.hayIdsLocales, isFalse);
      expect(vista.avisos, isNotEmpty);
      expect(vista.avisos.first, contains('No se ha podido leer'));
    });

    test('el aviso dice que se puede leer lo que se baje', () async {
      // Es lo que hace que el aviso no sea un muro. Sin esta frase, quien lo lee
      // cree que la app no puede usarse, y si puede.
      final vista = BibliotecaViewModel();
      await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(colgado: true),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(vista.avisos.first.toLowerCase(), contains('leer'));
    });

    test('si el CATALOGO falla, se dice, y no se inventa una lista', () async {
      // El caso inverso: sin catalogo no hay lista, y hay que decirlo. Pero el aviso
      // es del catalogo, no del almacenamiento.
      final vista = BibliotecaViewModel();
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => const ResultadoCatalogo(
          manifiesto: Manifiesto(
            formato: 'aa-catalog/1',
            version: 'sin leer',
            etiqueta: 'sin leer',
            modulos: <Modulo>[],
          ),
          estado: EstadoLectura.sinConexion,
          avisos: <String>['No se ha podido contactar con el catalogo.'],
        ),
        almacenamiento: AlmacenamientoFalso(),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(r.sabeLoQuePasa, isFalse);
      expect(vista.catalogoVacio, isTrue);
      expect(vista.avisos, contains('No se ha podido contactar con el catalogo.'));
    });

    test('si el repositorio LANZA, no se queda sin pintar nada', () async {
      // `leer()` no deberia lanzar nunca --es su contrato--, pero un `catch` de tres
      // lineas evita que un fallo suyo deje la app en blanco.
      final vista = BibliotecaViewModel();
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => throw StateError('fallo del repositorio'),
        almacenamiento: AlmacenamientoFalso(),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(r.sabeLoQuePasa, isFalse);
      expect(vista.avisos, isNotEmpty);
      expect(vista.avisos.first, contains('fallo del repositorio'));
      expect(vista.cargando, isFalse, reason: 'y no se queda en "cargando" para siempre');
    });
  });

  group('el orden, que es la mitad del arreglo', () {
    test('el catalogo se aplica ANTES de preguntar al almacenamiento', () async {
      // Si se invirtiera, un almacenamiento lento dejaria la pantalla vacia mientras
      // espera. Se comprueba mirando lo que hay en pantalla en el instante en que se
      // pregunta, no despues: por eso el doble tiene un `alPreguntar`.
      var filasAlPreguntar = -1;
      final vista = BibliotecaViewModel();

      await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(
          colgado: true,
          alPreguntar: () => filasAlPreguntar = vista.filas.length,
        ),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(filasAlPreguntar, 2,
          reason: 'la lista ya estaba pintada cuando se pregunto por el almacenamiento');
    });

    test('el arranque NO pide un solo byte a la red', () async {
      // El almacenamiento no es la red, pero conviene que quede escrito: si alguien
      // "optimiza" preguntando al servidor que modulos tiene, se acabaria bajando el
      // catalogo dos veces.
      var peticiones = 0;
      await arrancarBiblioteca(
        leerCatalogo: () async {
          peticiones++;
          return _resultadoDelServidor();
        },
        almacenamiento: AlmacenamientoFalso(idsLocales: const <String>{'KJV2006'}),
        vista: BibliotecaViewModel(),
        plazo: plazoCorto,
      );

      expect(peticiones, 1, reason: 'el catalogo se lee una vez, no una por modulo');
    });
  });

  group('los hashes, que son los que permiten distinguir las versiones', () {
    test('con hashes, un modulo atrasado sale como atrasado y se lee', () async {
      final vista = BibliotecaViewModel();
      final shaViejo = '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c';
      await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(
          idsLocales: const <String>{'KJV2006', 'CLARKE'},
          hashes: <String, String>{'KJV2006': shaViejo, 'CLARKE': shaViejo},
        ),
        vista: vista,
        plazo: plazoCorto,
      );

      final kjv = vista.filas.firstWhere((f) => f.id == 'KJV2006');
      expect(kjv.hayVersionNueva, isTrue);
      expect(kjv.sePuedeLeer, isTrue, reason: 'el texto viejo esta ahi y se lee');
    });

    test('sin hashes, todo local sale como descargado, y se avisa', () async {
      // Sin indice de hashes no se puede comprobar nada. Los modulos salen como
      // descargados --es lo mejor que se puede decir-- y se avisa de que no se ha
      // podido comprobar, en vez de fingir que esta todo al dia.
      final vista = BibliotecaViewModel();
      final r = await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(
          idsLocales: const <String>{'KJV2006'},
          sinHashes: true,
        ),
        vista: vista,
        plazo: plazoCorto,
      );

      // Los ids se saben, los hashes no: la biblioteca se llena y los modulos salen
      // como descargados, porque es lo mejor que se puede decir sin comprobar.
      expect(r.hayIdsLocales, isTrue);
      expect(r.hayHashesLocales, isFalse);
      expect(vista.filas.firstWhere((f) => f.id == 'KJV2006').estado, EstadoModulo.descargado);
      expect(vista.avisos.any((a) => a.toLowerCase().contains('version')), isTrue);
    });

    test('un modulo retirado del catalogo sigue apareciendo', () async {
      // El caso del spec, comprobado desde el arranque y no desde el ViewModel: si
      // el almacenamiento no dijera los ids, este modulo desapareceria de la
      // biblioteca y con el se leeria el texto de otra persona.
      final vista = BibliotecaViewModel();
      await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(
          idsLocales: const <String>{'RVR1960_vieja'},
          hashes: <String, String>{'RVR1960_vieja': _hashDePrueba},
        ),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(vista.filas.length, 3);
      final retirada = vista.filas.firstWhere((f) => f.id == 'RVR1960_vieja');
      expect(retirada.retirado, isTrue);
      expect(retirada.sePuedeLeer, isTrue);
    });
  });

  group('el plazo', () {
    test('un almacenamiento lento no cuelga el arranque', () async {
      // Un `await` sin plazo sobre una promesa que no resuelve cuelga la pantalla
      // **entera**, no una parte. Con plazo, se acaba.
      final vista = BibliotecaViewModel();
      final reloj = Stopwatch()..start();

      final r = await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(colgado: true),
        vista: vista,
        plazo: plazoCorto,
      );

      expect(reloj.elapsedMilliseconds, lessThan(3000));
      expect(r.hayIdsLocales, isFalse);
      expect(vista.filas.length, 2);
    });

    test('el plazo de verdad son cinco segundos, y aqui se comprueba', () async {
      // Para que cambiarlo no sea un cambio silencioso: si alguien lo pone a dos
      // minutos, esta prueba se cae.
      expect(plazoDelAlmacenamiento, const Duration(seconds: 5));
    });

    test('conPlazo deja pasar el que llega a tiempo', () async {
      expect(await conPlazaRapida(), 7);
    });

    test('conPlazo avisa con el nombre de lo que no ha contestado', () async {
      // El mensaje tiene que decir **que** fue, no "ha expirado": si el aviso dice
      // solo eso, quien lo lee no sabe si fue el catalogo o el almacenamiento.
      await expectLater(
        conPlazaNula(),
        throwsA(
          isA<TimeoutException>().having(
            (e) => e.message,
            'message',
            allOf(contains('no ha contestado'), contains('el almacenamiento')),
          ),
        ),
      );
    });

    test('el futuro perdedor no suelta una excepcion sin manejar', () async {
      // Si el perdedor falla **despues** de que el plazo haya expirado, su excepcion
      // no debe aparecer en la consola treinta segundos despues. Se comprueba
      // esperando: si apareciera, `flutter test` lo reportaria aqui.
      final lento = Completer<String>();
      await expectLater(
        conPlazo<String>(
          lento.future,
          plazo: const Duration(milliseconds: 50),
          mensaje: 'algo lento',
        ),
        throwsA(isA<TimeoutException>()),
      );

      lento.completeError(StateError('fallo tarde, ya no importa'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      // Si aqui hubiera una excepcion sin manejar, esta prueba fallaria.
    });
  });

  group('los avisos previos', () {
    test('van primero, porque si el motor no arranco es lo mas importante', () async {
      final vista = BibliotecaViewModel();
      await arrancarBiblioteca(
        leerCatalogo: () async => _resultadoDelServidor(),
        almacenamiento: AlmacenamientoFalso(),
        vista: vista,
        avisosPrevios: const <String>['No se ha podido preparar el motor de lectura.'],
        plazo: plazoCorto,
      );

      expect(vista.avisos.first, contains('motor'));
    });
  });
}

/// Un `conPlazo` que SI llega, para comprobar que no rompe el camino bueno.
Future<int> conPlazaRapida() =>
    conPlazo<int>(Future<int>.value(7), mensaje: 'algo rapido');

/// Un `conPlaza` que no llega nunca, para comprobar el mensaje del plazo.
Future<List<String>> conPlazaNula() =>
    conPlazo<List<String>>(
      Completer<List<String>>().future,
      plazo: const Duration(milliseconds: 50),
      mensaje: 'el almacenamiento',
    );
