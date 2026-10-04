// Un `.amod` de fuera: se reconoce o no se abre.
//
// Las pruebas usan el **KJV real** de 22.544.384 bytes, no un fichero de diez
// filas. Un `.amod` pequeno pasaria aunque el formato real tuviera algo que no se
// ve con diez filas, que es justo lo que hay que cazar: por ejemplo, que el
// identificador no este en las primeras paginas, o que la cabecera no sea la que
// se espera.
//
// Y hay una prueba que es la que de verdad importa y que casi no se escribe: la
// de que **un fichero que no es del catalogo NO se abre**, y dice su sha256.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ab/data/services/hash_service.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/use_cases/reconocer_modulo_local.dart';
import 'package:flutter_test/flutter_test.dart';

const String _rutaKjv = '/home/j/aa/modules/build/KJV2006_bible.amod';
const String _rutaClarke = '/home/j/aa/modules/build/CLARKE_commentary.amod';
const String _sha256Kjv = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
const String _sha256Clarke = '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c';

/// El manifiesto tal como lo publica el catalogo, con los dos modulos.
///
/// Sale de los mismos fixtures que usan las pruebas del repositorio, para que las
/// cifras de aqui y las de alla sean las mismas.
///
/// El JSON se lee aqui con `jsonDecode`, y **no** con el mapeo del repositorio. Es
/// a proposito: si se usara el mapeo, estas pruebas comprobarían el repositorio
/// contra si mismo, y un error en el mapeo haria que los dos modulos de verdad
/// parecieran desconocidos.
///
/// Y la primera version de esta funcion cortaba el JSON con `indexOf` y
/// `substring`, y devolvia el sha256 con una comilla delante. Daba hash de 65
/// caracteres, que no cuadraba con nada, y el fallo se veia como "el modulo real
/// no se reconoce", que es un sintoma que no señala la causa. El `jsonDecode` es
/// el mismo numero de lineas y no puede tener ese error.
Manifiesto _manifiestoReal() {
  final j = jsonDecode(File('test/fixtures/catalog_real.json').readAsStringSync())
      as Map<String, dynamic>;
  final modulos = <Modulo>[];
  for (final e in j['modules'] as List) {
    final m = e as Map<String, dynamic>;
    modulos.add(Modulo(
      id: m['id'] as String,
      nombre: m['name'] as String,
      tipo: TipoModulo.desdeCatalogo(m['type'] as String)!,
      idioma: m['language'] as String,
      licencia: m['license'] as String,
      tamanoBytes: m['sizeBytes'] as int,
      sha256: m['sha256'] as String,
      urlDescarga: Uri.parse(m['downloadUrl'] as String),
      urlNavegador: Uri.parse(m['browserUrl'] as String),
    ));
  }
  return Manifiesto(
    formato: j['format'] as String,
    version: j['version'] as String,
    etiqueta: j['version'] as String,
    modulos: modulos,
  );
}

void main() {
  const reconocer = ReconocerModuloLocal();

  setUpAll(() {
    for (final r in const [_rutaKjv, _rutaClarke]) {
      if (!File(r).existsSync()) {
        fail('falta $r, que es un modulo real del repositorio hermano. Sin el '
            'fichero REAL estas pruebas no verifican nada.');
      }
    }
  });

  group('4.5 un modulo del catalogo se reconoce', () {
    test('el KJV real es su propio modulo, con su hash', () {
      final bytes = File(_rutaKjv).readAsBytesSync();
      final archivo = ArchivoLocal(nombre: 'KJV2006_bible.amod', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      expect(r, isA<EsDelCatalogo>());
      final ok = r as EsDelCatalogo;
      expect(ok.modulo.id, 'KJV2006');
      expect(ok.modulo.tipo, TipoModulo.biblia);
      expect(archivo.sha256, _sha256Kjv);
      expect(ok.archivo.sha256, _sha256Kjv);
    });

    test('el CLARKE real tambien, y es un comentario', () {
      final bytes = File(_rutaClarke).readAsBytesSync();
      final archivo = ArchivoLocal(nombre: 'CLARKE_commentary.amod', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      expect(r, isA<EsDelCatalogo>());
      final ok = r as EsDelCatalogo;
      expect(ok.modulo.id, 'CLARKE');
      expect(ok.modulo.tipo, TipoModulo.comentario);
      expect(archivo.sha256, _sha256Clarke);
    });

    test('el hash se calcula al leer el fichero, no se lee de ningun sitio', () {
      // Si el hash se leyera del manifiesto, un manifiesto alterado haria que
      // cualquier fichero pasara por bueno. Se comprueba cambiando el hash del
      // manifiesto: el fichero sigue siendo el de verdad y tiene que dejar de
      // reconocerse.
      final bytes = File(_rutaKjv).readAsBytesSync();
      final archivo = ArchivoLocal(nombre: 'x.amod', bytes: bytes);

      final manifiestoFalso = Manifiesto(
        formato: 'aa-catalog/1',
        version: 'v0.0.0',
        etiqueta: 'v0.0.0',
        modulos: [
          Modulo(
            id: 'KJV2006',
            nombre: 'falso',
            tipo: TipoModulo.biblia,
            idioma: 'eng',
            licencia: 'PublicDomain',
            tamanoBytes: bytes.length,
            // Un hash que no es el del fichero.
            sha256: String.fromCharCodes(List.filled(64, 'f'.codeUnitAt(0))),
            urlDescarga: Uri.parse('https://example.invalid/a.amod'),
            urlNavegador: Uri.parse('https://example.invalid/a.amod'),
          ),
        ],
      );
      final r = reconocer.reconocer(archivo, manifiestoFalso);
      expect(r, isNot(isA<EsDelCatalogo>()),
          reason: 'el hash del manifiesto manda sobre el hash real, y eso es justo '
              'lo que no debe pasar');
    });
  });

  group('4.5 un fichero ajeno se rechaza Y DICE SU SHA256', () {
    test('un modulo de verdad con UN byte cambiado no se abre', () {
      // Es el caso que da miedo. Un SQLite con un byte cambiado abre PERFECTO y da
      // versiculos casi correctos. Si aqui se aceptara, el fallo no se veria
      // nunca.
      final bytes = Uint8List.fromList(File(_rutaKjv).readAsBytesSync());
      bytes[12000] = bytes[12000] ^ 0x01;
      final archivo = ArchivoLocal(nombre: 'KJV2006_bible.amod', bytes: bytes);

      final r = reconocer.reconocer(archivo, _manifiestoReal());
      expect(r, isNot(isA<EsDelCatalogo>()));
      expect(archivo.sha256, isNot(_sha256Kjv));
    });

    test('y el mensaje lleva su sha256, que es lo unico accionable', () {
      final bytes = Uint8List.fromList(File(_rutaKjv).readAsBytesSync());
      bytes[12000] = bytes[12000] ^ 0x01;
      final archivo = ArchivoLocal(nombre: 'KJV2006_bible.amod', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      final texto = switch (r) {
        EsDeVersionDistinta() => r.texto,
        NoEsDelCatalogo() => r.texto,
        NoEsUnaBaseDeDatos() => r.texto,
        EsDelCatalogo() => '',
      };
      expect(texto, contains(archivo.sha256),
          reason: 'sin el hash la persona no puede ni reportarlo ni comparar');
      expect(texto, hasLength(greaterThan(80)));
    });

    test('un modulo entero de otro sitio se dice que no esta en el catalogo', () {
      // Simula lo que llega en un pendrive que no es nuestro: un SQLite bien
      // formado, con su `id` puesto, y cuyo contenido no ha visto el gate.
      final bytes = Uint8List(4096);
      final cab = ReconocerModuloLocal.cabeceraSqlite;
      bytes.setRange(0, cab.length, cab);
      // Un `id` propio, al final del fichero, para que el patron lo encuentre.
      final id = 'CASA';
      final marca = 'id$id'.codeUnits;
      bytes.setRange(bytes.length - marca.length * 2, bytes.length - marca.length, marca);

      final archivo = ArchivoLocal(nombre: 'casa.amod', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      expect(r, isA<NoEsDelCatalogo>());
      final no = r as NoEsDelCatalogo;
      expect(no.texto, contains(archivo.sha256));
      expect(no.texto.toLowerCase(), isNot(contains('error')));
    });

    test('una version anterior de un modulo que SI esta se distingue', () {
      // El caso que hace que "no se reconoce" seria mentira: el fichero puede ser
      // perfectamente bueno y lo que este viejo es el catalogo.
      final bytes = Uint8List(4096);
      final cab = ReconocerModuloLocal.cabeceraSqlite;
      bytes.setRange(0, cab.length, cab);
      final marca = 'idKJV2006'.codeUnits;
      bytes.setRange(bytes.length - marca.length * 2, bytes.length - marca.length, marca);

      final archivo = ArchivoLocal(nombre: 'viejo.amod', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      expect(r, isA<EsDeVersionDistinta>());
      final v = r as EsDeVersionDistinta;
      expect(v.hashEnCatalogo, _sha256Kjv);
      expect(v.texto, contains(archivo.sha256));
      expect(v.texto, contains(_sha256Kjv),
          reason: 'hay que decir las dos: la del fichero y la que se espera');
    });
  });

  group('lo que no es un modulo', () {
    test('un fichero vacio', () {
      final archivo = ArchivoLocal(nombre: 'vacio.amod', bytes: const <int>[]);
      final r = reconocer.reconocer(archivo, _manifiestoReal());
      expect(r, isA<NoEsUnaBaseDeDatos>());
      expect((r as NoEsUnaBaseDeDatos).texto, contains(archivo.sha256));
    });

    test('una foto, o un PDF, o cualquier cosa', () {
      // El orden de las comprobaciones importa: esto se dice "no es un modulo" y
      // no "no esta en el catalogo". Lo segundo mandaria a la persona a buscar en
      // el catalogo un fichero que no es un modulo de ningun tipo.
      final bytes = Uint8List.fromList(
        List<int>.generate(5000, (i) => (i * 37) % 256),
      );
      final archivo = ArchivoLocal(nombre: 'foto.jpg', bytes: bytes);
      final r = reconocer.reconocer(archivo, _manifiestoReal());

      expect(r, isA<NoEsUnaBaseDeDatos>());
      final no = r as NoEsUnaBaseDeDatos;
      expect(no.texto, contains('SQLite format 3'),
          reason: 'el mensaje tiene que decir como se reconoce un modulo');
      expect(no.motivo, isNot(contains('catalogo')),
          reason: 'no es un problema de catalogo, es que no es un modulo');
    });

    test('un fichero que solo empieza bien pero esta vacio de verdad', () {
      final bytes = Uint8List.fromList(ReconocerModuloLocal.cabeceraSqlite);
      final archivo = ArchivoLocal(nombre: 'media.amod', bytes: bytes);
      // Con la cabecera puesta y nada mas, el hash no esta en el manifiesto: se
      // dice que no se reconoce, que es distinto de "no es una base de datos", y
      // las dos cosas son ciertas.
      final r = reconocer.reconocer(archivo, _manifiestoReal());
      expect(r, isNot(isA<EsDelCatalogo>()));
    });
  });

  group('la funcion es pura', () {
    test('el mismo fichero da SIEMPRE el mismo resultado', () {
      final bytes = File(_rutaKjv).readAsBytesSync();
      final manifiesto = _manifiestoReal();
      final r1 = reconocer.reconocer(
        ArchivoLocal(nombre: 'a.amod', bytes: bytes),
        manifiesto,
      );
      for (var i = 0; i < 5; i++) {
        final r2 = reconocer.reconocer(
          ArchivoLocal(nombre: 'otro-nombre-distinto.amod', bytes: bytes),
          manifiesto,
        );
        expect(r2.runtimeType, r1.runtimeType);
        if (r2 is EsDelCatalogo && r1 is EsDelCatalogo) {
          expect(r2.modulo.id, r1.modulo.id);
        }
      }
    });

    test('el nombre del fichero no cambia nada', () {
      // El nombre lo pone quien copia. Si influyera, un fichero renombrado
      // dejaria de reconocerse, que es justo el fallo que haria que la gente
      // pensara que el fichero estaba malo.
      final bytes = File(_rutaKjv).readAsBytesSync();
      final manifiesto = _manifiestoReal();
      for (final nombre in [
        'KJV2006_bible.amod',
        'mi-biblia.amod',
        'sin-extension',
        'Biblia (copia) (2).amod',
        'x' * 200,
      ]) {
        final r = reconocer.reconocer(ArchivoLocal(nombre: nombre, bytes: bytes), manifiesto);
        expect(r, isA<EsDelCatalogo>(), reason: 'el nombre "$nombre" no deberia importar');
      }
    });
  });

  group('el hash del archivo se calcula bien', () {
    test('el sha256 del KJV real es el que declara el catalogo', () {
      expect(sha256DeBytes(File(_rutaKjv).readAsBytesSync()), _sha256Kjv);
    });

    test('el sha256 del CLARKE real tambien', () {
      expect(sha256DeBytes(File(_rutaClarke).readAsBytesSync()), _sha256Clarke);
    });
  });
}
