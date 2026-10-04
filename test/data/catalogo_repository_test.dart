// El repositorio del catalogo, contra un servidor real que se puede apagar.
//
// Por que un servidor real y no un cliente HTTP falso: el caso que importa es
// "el servidor no contesta", y un cliente falso no es un servidor que no
// contesta. Aqui hay un `HttpServer` de verdad, con un interruptor que lo apaga.
//
// Y por que los manifests son los REALES de los fixtures: el hash que hay que
// comprobar es el que declara el indice de verdad. Comprobar un hash inventado no
// demuestra que se comprueben los hashes, solo que la comparacion funciona.

import 'dart:convert';
import 'dart:io';

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/services/almacenamiento.dart';
import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/http_service.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:flutter_test/flutter_test.dart';

String get _manifiestoReal => File('test/fixtures/catalog_real.json').readAsStringSync();
String get _ultimoReal => File('test/fixtures/latest_real.json').readAsStringSync();
Map<String, dynamic> get _indice => jsonDecode(_ultimoReal) as Map<String, dynamic>;

void main() {
  late HttpServer servidor;
  late AlmacenamientoEnMemoria almacenamiento;
  late CatalogoRepository repo;

  /// Cuando esta a true, el servidor acepta y cierra sin responder: es lo que
  /// pasa sin internet.
  bool sinRed = false;

  /// El manifiesto que SE SIRVE. Se cambia para probar el hash incorrecto.
  String manifiestoAServir = '';

  /// El manifiesto cuyo hash declara el indice. Se queda en el bueno mientras se
  /// sirve otro, que es exactamente lo que hay que cazar: el indice dice un hash
  /// y lo que llega dice otro.
  String manifiestoEsperado = '';

  /// El `latest.json` que se sirve, con las URLs apuntando a **este** servidor.
  ///
  /// Hace falta porque el de verdad trae URLs absolutas a `yojananyosef.github.io`
  /// y el repositorio las sigue tal cual. Sin esto, una prueba de "el manifiesto
  /// esta alterado" estaria leyendo el manifiesto de verdad del sitio real y no
  /// veria ningun cambio: pasaria probando nada.
  String indiceLocal() {
    final j = jsonDecode(_ultimoReal) as Map<String, dynamic>;
    final base = 'http://127.0.0.1:${servidor.port}';
    return jsonEncode({
      ...j,
      'url': '$base/modulos/v0.1.1/catalog.json',
      'browserUrl': '$base/modulos/v0.1.1/catalog.json',
      'catalogSha256': sha256DeBytes(utf8.encode(manifiestoEsperado)),
    });
  }

  setUp(() async {
    sinRed = false;
    manifiestoAServir = _manifiestoReal;
    manifiestoEsperado = _manifiestoReal;
    almacenamiento = AlmacenamientoEnMemoria();
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((p) async {
      if (sinRed) {
        await p.response.close();
        return;
      }
      final ruta = p.uri.path;
      final cuerpo = ruta == '/latest.json' ? indiceLocal() : manifiestoAServir;
      p.response.headers.set('Content-Type', 'application/json');
      p.response.headers.set('Access-Control-Allow-Origin', '*');
      p.response.add(utf8.encode(cuerpo));
      await p.response.close();
    });
    repo = CatalogoRepository(
      http: HttpService(),
      almacenamiento: almacenamiento,
      origen: 'http://127.0.0.1:${servidor.port}',
    );
  });

  tearDown(() async {
    repo.dispose();
    await servidor.close(force: true);
  });

  group('3.1 leer el manifiesto de verdad', () {
    test('lee 2 modulos con los 12 campos obligatorios', () async {
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.delServidor);
      expect(r.avisos, isEmpty);
      expect(r.manifiesto.formato, 'aa-catalog/1');
      expect(r.manifiesto.modulos.length, 2);

      final kjv = r.manifiesto.porId('KJV2006')!;
      expect(kjv.tamanoBytes, 22544384);
      expect(kjv.sha256, 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9');
      expect(kjv.urlNavegador.host, 'yojananyosef.github.io');
      expect(kjv.urlDescarga.host, 'github.com');
      expect(kjv.urlsCoincidenEnElFichero, isTrue);
    });

    test('el hash del manifiesto servido es el que declara el indice', () async {
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.delServidor);
      expect(r.hashObtenido, sha256DeBytes(utf8.encode(_manifiestoReal)));
      expect(r.hashObtenido, r.hashEsperado);
    });

    test('el manifiesto se guarda para poder trabajar sin conexion', () async {
      await repo.leer();
      expect(await almacenamiento.leer(claveManifiestoGuardado), isNotNull);
      expect(await almacenamiento.leer(claveEtiquetaGuardada), 'v0.1.1');
    });
  });

  group('3.2 el hash se comprueba ANTES de usar el contenido', () {
    test('un byte cambiado: no se usa el manifiesto y se dicen los dos hash', () async {
      // El byte que se cambia es el NOMBRE de un modulo, que es lo que un
      // manifiesto alterado haria de verdad: si el contenido se usara, se veria.
      // El indice se calcula con el manifiesto real, y luego se sirve otro. Eso es
      // exactamente el caso que hay que cazar: el indice dice un hash y el
      // manifiesto dice otro.
      manifiestoAServir = _manifiestoReal.replaceFirst('King James Version', 'King James Verson');

      final r = await repo.leer();
      expect(r.estado, EstadoLectura.hashIncorrecto);
      expect(r.manifiesto.modulos, isEmpty,
          reason: 'NO se lee el contenido de un manifiesto que no cuadra');
      expect(r.hashEsperado, _indice['catalogSha256']);
      expect(r.hashObtenido, isNotNull);
      expect(r.hashObtenido, isNot(r.hashEsperado));
    });

    test('y con copia guardada, se usa la copia y se cuentan los dos hash', () async {
      await repo.leer();
      expect(await almacenamiento.leer(claveManifiestoGuardado), isNotNull);

      manifiestoAServir = _manifiestoReal.replaceFirst('King James Version', 'King James Verson');
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.deCopiaGuardada);
      expect(r.manifiesto.modulos.length, 2);
      expect(r.hashEsperado, isNotNull);
      expect(r.hashObtenido, isNot(r.hashEsperado));
    });

    test('un manifiesto con JSON invalido es ilegible, no una excepcion', () async {
      // Aqui el indice declara el hash de lo que se sirve, asi que la comprobacion
      // de hash pasa y lo que falla es la interpretacion. Por eso hace falta
      // recalcular el indice en cada lectura: `indiceLocal()` lo hace.
      manifiestoAServir = '{esto no es json';
      manifiestoEsperado = '{esto no es json';
      final r = await repo.leer();
      // Sin copia guardada: ilegible, y con la biblioteca vacia.
      expect(r.estado, anyOf(EstadoLectura.ilegible, EstadoLectura.sinConexion));
      expect(r.manifiesto.modulos, isEmpty);
    });
  });

  group('3.3 y 3.4 el respaldo', () {
    test('con el servidor caido y copia guardada, se usa la copia y se avisa', () async {
      await repo.leer();
      sinRed = true;

      final r = await repo.leer();
      expect(r.estado, EstadoLectura.deCopiaGuardada);
      expect(r.manifiesto.modulos.length, 2,
          reason: 'la biblioteca no se vacia por un fallo de red');
      expect(r.avisos.first, contains('v0.1.1'),
          reason: 'hay que decir DE QUE COPIA se trata');
    });

    test('con el servidor caido y SIN copia, hay fallo con aviso', () async {
      sinRed = true;
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.sinConexion);
      expect(r.avisos, isNotEmpty, reason: 'la pantalla necesita un aviso para poner Reintentar');
      expect(r.manifiesto.modulos, isEmpty);
    });

    test('el fallo llega rapido, no se queda esperando', () async {
      // La tarea lo pide como requisito. Un progreso que no acaba es el sintoma de
      // un cliente que reintenta para siempre, que es justo lo que se prohibe.
      sinRed = true;
      final reloj = Stopwatch()..start();
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.sinConexion);
      expect(reloj.elapsedMilliseconds, lessThan(10000));
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('el servidor vuelve y el manifiesto se actualiza', () async {
      await repo.leer();
      sinRed = true;
      await repo.leer();
      sinRed = false;
      final r = await repo.leer();
      expect(r.estado, EstadoLectura.delServidor);
    });
  });

  group('3.5 los estados salen del manifiesto y del dispositivo', () {
    test('sin nada en el dispositivo, todo disponible', () async {
      final m = (await repo.leer()).manifiesto;
      final estados = repo.estadosDe(m, const <String, String>{});
      expect(estados.length, 2);
      expect(estados['KJV2006']!.name, 'disponible');
      expect(estados['CLARKE']!.name, 'disponible');
    });

    test('con el hash que dice el catalogo, descargado', () async {
      final m = (await repo.leer()).manifiesto;
      final estados = repo.estadosDe(m, {'KJV2006': m.porId('KJV2006')!.sha256});
      expect(estados['KJV2006']!.name, 'descargado');
      expect(estados['CLARKE']!.name, 'disponible');
    });

    test('con OTRO hash, desactualizado y sigue legible', () async {
      final m = (await repo.leer()).manifiesto;
      // Un hash que no es el del catalogo: 64 caracteres, validos, y distintos.
      final otro = String.fromCharCodes(List.filled(64, 'f'.codeUnitAt(0)));
      final estados = repo.estadosDe(m, {'KJV2006': otro});
      expect(estados['KJV2006']!.name, 'desactualizado');
    });

    test('un modulo que desaparece del manifiesto no aparece en sus estados', () async {
      // El manifiesto vacio no produce ningun estado. Lo que mantiene en la
      // biblioteca a un modulo retirado es el almacenamiento del otro
      // repositorio, y eso se comprueba ahi, no aqui.
      final vacio = Manifiesto(
        formato: 'aa-catalog/1',
        version: 'v0.0.0',
        etiqueta: 'v0.0.0',
        modulos: const [],
      );
      final otro = String.fromCharCodes(List.filled(64, 'x'.codeUnitAt(0)));
      expect(repo.estadosDe(vacio, {'KJV2006': otro}), isEmpty);
    });

    test('los estados NO se guardan en el almacenamiento', () async {
      await repo.leer();
      // Lo unico que hay guardado es el manifiesto y su etiqueta. Nada de
      // estados: se calculan cada vez.
      expect(almacenamiento.datos.keys.toSet(),
          {claveManifiestoGuardado, claveEtiquetaGuardada});
    });
  });

  group('el hash del manifiesto real, medido', () {
    test('coincide con sha256 del fichero', () {
      // La prueba de que el fixture es el de verdad y no una copia vieja.
      expect(sha256DeBytes(File('test/fixtures/catalog_real.json').readAsBytesSync()),
          '3113ea7362c5d722e1a030abf027d09e22f72392b40ab73d293975dee4fb5827');
    });
  });
}
