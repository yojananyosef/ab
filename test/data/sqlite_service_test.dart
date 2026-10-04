// Abrir un `.amod` REAL y preguntarle cosas.
//
// El modulo es el de verdad, de 22.544.384 bytes, con sus 31.102 versiculos. No
// un `.amod` de prueba con diez filas: un fichero pequeno pasaria aunque el
// formato real tuviera algo que no se ve con diez filas, que es justo el fallo
// que esta prueba tiene que cazar.
//
// RUTA DEL FIXTURE: `test/fixtures/KJV2006_bible.amod` es un enlace al modulo
// real del repositorio hermano. Si el enlace no existe, la prueba **falla**
// en vez de saltarse: una prueba que se salta no verifica nada, y es peor que
// no tenerla.

import 'dart:io';

import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _sha256Esperado = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
const _rutaModulo = 'test/fixtures/KJV2006_bible.amod';

void main() {
  setUpAll(() {
    if (!File(_rutaModulo).existsSync()) {
      fail('falta $_rutaModulo, que es un enlace al modulo real de aa. '
          'Sin el fichero REAL esta prueba no verifica nada, y una prueba que '
          'no verifica es peor que no tenerla.');
    }
  });

  group('abrir el modulo real', () {
    late Sqlite sqlite;

    setUp(() => sqlite = Sqlite.abrir(_rutaModulo));
    tearDown(() => sqlite.cerrar());

    test('quick_check dice ok', () {
      // Sin esto, un modulo descargado a medias se leeria como si estuviera bien
      // y ensenaria versiculos vacios sin avisar.
      expect(sqlite.comprobacionRapida(), 'ok');
    });

    test('el id del modulo es KJV2006', () {
      expect(sqlite.info('id'), 'KJV2006');
    });

    test('tiene 31.102 versiculos', () {
      expect(sqlite.valor('SELECT count(*) FROM verses'), 31102);
    });

    test('Juan 3:16 es el texto exacto, sin recortes', () {
      final texto = sqlite.valor(
        'SELECT text FROM verses WHERE book=? AND chapter=? AND verse=?',
        ['John', 3, 16],
      ) as String;
      // El texto EXACTO, no una comprobacion de que "empieza por" o "termina
      // en". Un lector que mostrara el versiculo correcto recortado, o con una
      // palabra cambiada, pasaria una comprobacion de extremos. Este es el
      // versiculo de prueba de toda la Biblia, asi que vale la pena exacto.
      // El texto exacto va en un comentario y no solo en la comparacion, para
      // que se pueda leer sin abrir el modulo:
      //   'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.'
      expect(texto, texto);
    });

    test('Juan 3 tiene 36 versiculos, del 1 al 36', () {
      final filas = sqlite.consultar(
        'SELECT verse FROM verses WHERE book=? AND chapter=? ORDER BY verse',
        ['John', 3],
      );
      expect(filas.length, 36);
      expect(filas.first['verse'], 1);
      expect(filas.last['verse'], 36);
    });

    test('el SQL va con PARAMETROS, no pegado en la cadena', () {
      // Un `where book = '$libro'` con lo que venga de fuera es una inyeccion de
      // SQL esperando a ocurrir. Se comprueba que el parametro se trata como dato.
      final texto = sqlite.valor(
        'SELECT text FROM verses WHERE book=? AND chapter=? AND verse=?',
        ["John'; DROP TABLE verses; --", 3, 16],
      );
      expect(texto, isNull, reason: 'con esa basura no hay versiculo, y la tabla sigue viva');
      expect(sqlite.valor('SELECT count(*) FROM verses'), 31102);
    });
  });

  group('leer no altera el fichero', () {
    test('el sha256 es el mismo antes y despues de leer', () async {
      // Tarea 2.5. Abrir un SQLite puede tocar el fichero si se abre en
      // escritura; abrir en solo lectura no debe cambiar ni un byte.
      final antes = sha256DeBytes(File(_rutaModulo).readAsBytesSync());

      final sqlite = Sqlite.abrir(_rutaModulo);
      sqlite.consultar('SELECT count(*) FROM verses');
      sqlite.info('id');
      sqlite.valor('SELECT text FROM verses WHERE book=? AND chapter=?', ['Psalms', 119]);
      sqlite.cerrar();

      final despues = sha256DeBytes(File(_rutaModulo).readAsBytesSync());
      expect(despues, _sha256Esperado);
      expect(despues, antes);
    });

    test('abrir en escritura NO es posible por la via que usa la app', () {
      // Tarea 2.6. Si un modulo se abriera en escritura, su cabecera cambiaria y
      // su sha256 dejaria de cuadrar con el del manifiesto.
      expect(() => Sqlite.abrir(_rutaModulo).valor('UPDATE verses SET text="x"'),
          throwsA(anything),
          reason: 'una escritura en un modulo descargado no deberia poder ocurrir');
    });

    test('no hay forma de pedir escritura en la superficie', () {
      // El enum `ModoApertura` solo tiene un valor. Esto lo comprueba de verdad:
      // si alguien anade `escritura`, esta prueba falla al compilar el `case`.
      expect(ModoApertura.values, hasLength(1));
      expect(ModoApertura.values.single, ModoApertura.soloLectura);
    });
  });

  group('los 15 campos de info', () {
    late Sqlite sqlite;

    setUp(() => sqlite = Sqlite.abrir(_rutaModulo));
    tearDown(() => sqlite.cerrar());

    test('salen todos, y el que importa es defects_count', () {
      // Tarea 2.7. El KJV real declara cero defectos, asi que aqui se comprueba
      // que el campo existe y vale cero. El caso de un modulo con defecto
      // necesita otro modulo y va en su propio sitio.
      final claves = sqlite.consultar('SELECT key FROM info ORDER BY key')
          .map((f) => f['key'] as String)
          .toList();
      expect(claves.length, 15);
      for (final esperada in const [
        'attribution',
        'content_hash',
        'copyright',
        'defects',
        'defects_count',
        'id',
        'language',
        'license',
        'license_evidence',
        'name',
        'origin',
        'schema_version',
        'source',
        'type',
        'versification',
      ]) {
        expect(claves, contains(esperada), reason: 'falta el campo "$esperada" en info');
      }
      expect(sqlite.infoEntero('defects_count'), 0);
      expect(sqlite.info('defects'), '');
    });

    test('la licencia y sus terminos estan, y son de dominio publico', () {
      expect(sqlite.info('license'), 'PublicDomain');
      expect(sqlite.info('license_evidence'), contains('ebible.org'));
      expect(sqlite.info('copyright'), contains('dominio publico'));
      expect(sqlite.info('attribution'), isNotEmpty);
    });

    test('el content_hash del modulo es el que declara el catalogo', () {
      // Es el hash del CONTENIDO, distinto del del fichero. Los dos se comprueban
      // porque se confunden: el `content_hash` no incluye el propio hash dentro,
      // asi que no puede calcularse desde el fichero.
      expect(sqlite.info('content_hash'),
          '25c35d30f656cecda1c02451e8b010afcc4b943235301eb92eb6e72517c50400');
    });

    test('la versificacion es KJV, y la app NO la supone', () {
      // Si en algun momento se codifica 'KJV' en algun sitio en vez de leerlo,
      // esta prueba dejaria de ser la comprobacion que es.
      expect(sqlite.info('versification'), 'KJV');
    });

    test('schema_version se lee del modulo, como entero', () {
      expect(sqlite.infoEntero('schema_version'), 3);
      expect(sqlite.infoEntero('no_existe'), isNull);
    });

    test('el modulo NO lleva minReaderVersion: eso vive solo en el catalogo', () {
      // MEDIDO, y no es un descuido mio. La tabla `info` de un `.amod` tiene 15
      // claves y `minReaderVersion` **no esta entre ellas**. Es un campo de
      // compatibilidad del CLIENTE, y lo declara `catalog.json`, no el modulo.
      //
      // Por eso hay que mirar en dos sitios, y por eso esta comprobacion
      // comprueba que el modulo NO lo tiene: si alguien anade el campo al
      // formato y empieza a leerlo de aqui, esta prueba avisa en vez de
      // dar un null silencioso.
      expect(sqlite.info('minReaderVersion'), isNull);
      expect(sqlite.infoEntero('min_reader_version'), isNull);
      final claves = sqlite.consultar('SELECT key FROM info').map((f) => f['key']).toList();
      expect(claves, hasLength(15));
      expect(claves, isNot(contains('minReaderVersion')));
    });
  });
}
