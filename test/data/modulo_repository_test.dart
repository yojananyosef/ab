// Abrir un `.amod` real y preguntarle cosas.
//
// EL MODULO ES EL DE VERDAD: 22.544.384 bytes, 31.102 versiculos, 66 libros. Un
// `.amod` de diez filas pasaria aunque el formato real tuviera algo que no se ve con
// diez filas, y lo que hay que cazar aqui es justo eso.
//
// Y CASI TODAS LAS AFIRMACIONES SON **MEDIDAS**, no supuestas: el numero de
// capitulos de cada libro sale de una consulta, y se compara con lo que se sabe. La
// comprobacion que mas importa es la de Genesis: ofrece del 1 al 50, y **no** el 51.
// El 51 es el de la RVR, y es exactamente el fallo que se produce si alguien escribe
// una tabla de numeros en vez de preguntar.

import 'dart:io';

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/libros.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  late ModuloAbierto m;

  setUpAll(() {
    final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
    if (r is! Abierto) {
      fail('no se ha podido abrir el modulo real: ${(r as FalloAlAbrir).motivo}');
    }
    m = r.modulo;
  });

  tearDownAll(() => m.cerrar());

  group('abrir', () {
    test('un modulo real se abre y pasa la comprobacion de integridad', () {
      // `ModuloAbierto.abrir` ya ha comprobado `PRAGMA quick_check` y la
      // `schema_version`. Que el KJV se abra es la prueba de que las dos funcionan.
      expect(m.id, 'KJV2006');
      expect(m.info('schema_version'), '3');
    });

    test('un fichero que no es un modulo se rechaza CON MOTIVO', () {
      final ruta = File('/tmp/opencode-no-es-un-modulo.amod');
      ruta.writeAsStringSync('esto es un texto, no una base de datos, ni de lejos.');
      addTearDown(() {
        if (ruta.existsSync()) ruta.deleteSync();
      });

      final r = ModuloAbierto.abrir(ruta.path, id: 'X');
      expect(r, isA<FalloAlAbrir>());
      expect((r as FalloAlAbrir).motivo, isNotEmpty);
    });

    test('un fichero que no existe se rechaza', () {
      final r = ModuloAbierto.abrir('/tmp/no-existe-este-fichero.amod', id: 'X');
      expect(r, isA<FalloAlAbrir>());
    });
  });

  group('7.8 los numeros salen de una consulta, no de una tabla', () {
    test('Genesis ofrece del 1 al 50, y NO el 51', () {
      // LA COMPROBACION MAS IMPORTANTE DEL FICHERO.
      final caps = m.capitulosDe('Genesis');
      expect(caps.length, 50);
      expect(caps.first, 1);
      expect(caps.last, 50);
      // El 51 es el de la RVR. Si esto alguna vez devuelve 51, significa que alguien
      // ha metido una tabla de numeros en el codigo, que es el fallo que esta tarea
      // existe para evitar.
      expect(caps.contains(51), isFalse, reason: 'el 51 es de la RVR, no de este texto');
      // Y no hay huecos: un capitulo que falta es informacion real de la traduccion,
      // y ofrecerlo lleva a una pantalla en blanco.
      for (var i = 1; i <= caps.length; i++) {
        expect(caps.contains(i), isTrue, reason: 'falta el capitulo $i');
      }
    });

    test('Juan tiene 21 capitulos y Juan 3 tiene 36 versiculos', () {
      expect(m.numeroDeCapitulos('John'), 21);
      expect(m.numerosDeVersiculos(const Referencia('John', 3)).length, 36);
    });

    test('Salmo 150 tiene 6 versiculos y es el ultimo', () {
      // Un dato que se sabe de memoria y que se comprueba contra el modulo, porque es
      // de los que se cuentan mal.
      expect(m.numerosDeVersiculos(const Referencia('Psalms', 150)), [1, 2, 3, 4, 5, 6]);
      expect(m.capitulosDe('Psalms').last, 150);
    });

    test('un libro que el modulo NO tiene devuelve null, no cero', () {
      // Null y no cero: "no lo tiene" y "tiene ninguno" son distintas, y un 0
      // llevaria a pintar un libro con cero capitulos.
      expect(m.numeroDeCapitulos('RVR1960'), isNull);
      expect(m.capitulosDe('RVR1960'), isEmpty);
    });

    test('los 66 libros del canon existen en el modulo', () {
      // La otra mitad de 7.2 desde la capa de datos: los 66 ids del canon se
      // resuelven contra el modulo real.
      final libros = m.libros();
      expect(libros.length, 66);

      // Los 66 ids salen de la tabla de libros del dominio, que es donde vive. No se
      // escribe una segunda lista de 66 lineas aqui: dos listas pueden separarse y
      // ningun aviso.
      final delCanon = <String>{for (final l in kLibros) l.id};
      expect(delCanon.length, 66, reason: 'el canon tiene 66');
      final sobrantes = libros.toSet().difference(delCanon);
      expect(sobrantes, isEmpty,
          reason: 'el modulo tiene libros que el canon no: $sobrantes');
      final faltantes = delCanon.difference(libros.toSet());
      expect(faltantes, isEmpty, reason: 'el canon tiene libros que el modulo no: $faltantes');
    });

    test('el total de versiculos del modulo es 31.102', () {
      expect(m.totalDeVersiculos(), 31102);
    });
  });

  group('7.1 leer un capitulo', () {
    test('Juan 3 sale con sus 36 versiculos, numerados y en orden', () {
      final p = m.leer(const Referencia('John', 3));
      expect(p.versiculos.length, 36);
      expect(p.versiculos.first.numero, 1);
      expect(p.versiculos.last.numero, 36);
      for (var i = 0; i < p.versiculos.length; i++) {
        expect(p.versiculos[i].numero, i + 1, reason: 'el versiculo $i no va en su sitio');
      }
      expect(p.vacio, isFalse);
      expect(p.titulo, 'Juan 3');
    });

    test('el versiculo 16 es el texto COMPLETO, no un trozo', () {
      final p = m.leer(const Referencia('John', 3, 16));
      expect(p.versiculos.length, 1);
      expect(
        p.versiculos.single.texto,
        'For God so loved the world, that he gave his only begotten Son, that '
        'whosoever believeth in him should not perish, but have everlasting life.',
      );
    });

    test('un versiculo suelto pide solo ese versiculo', () {
      final p = m.leer(const Referencia('John', 3, 16));
      expect(p.total, 1);
      expect(p.versiculo(16), isNotNull);
      // Y uno que no esta en el capitulo devuelve null, no lanza.
      expect(p.versiculo(999), isNull);
    });

    test('un pasaje que no existe sale VACIO, no null', () {
      // Vacio y no null: la pantalla tiene que poder pintar "aqui no hay nada", y eso
      // es un resultado, no un fallo.
      final p = m.leer(const Referencia('Genesis', 51));
      expect(p.vacio, isTrue);
      expect(p.versiculos, isEmpty);
    });

    test('el titulo sale en castellano, y el versiculo en la URL sale en ingles', () {
      final r = const Referencia('1Corinthians', 13);
      expect(r.texto, '1 Corintios 13');
      expect(r.paraUrl, '1Corinthians.13');
    });
  });

  group('7.3 saber si un pasaje existe', () {
    test('Juan 3:16 existe y Juan 3:37 no', () {
      expect(m.existe(const Referencia('John', 3, 16)), isTrue);
      expect(m.existe(const Referencia('John', 3, 37)), isFalse);
    });

    test('un capitulo que no existe no existe', () {
      expect(m.existe(const Referencia('Genesis', 51)), isFalse);
      expect(m.existe(const Referencia('Genesis', 50)), isTrue);
    });

    test('un libro que el modulo no tiene no existe', () {
      expect(m.existe(const Referencia('RVR1960', 1)), isFalse);
    });

    test('un versiculo con comillas y punto y coma dentro no inyecta SQL', () {
      // Con lo que venga de fuera en la cadena, esto seria una inyeccion esperando a
      // ocurrir. Se comprueba que el parametro se trata como dato: no hay versiculo,
      // y la tabla sigue viva.
      expect(m.existe(const Referencia("John'; DROP TABLE verses; --", 3, 16)), isFalse);
      expect(m.totalDeVersiculos(), 31102, reason: 'la tabla sigue viva');
    });
  });

  group('la busqueda', () {
    test('encuentra un versiculo por una palabra', () {
      final r = m.buscar('begotten');
      expect(r, isNotEmpty);
      expect(r.any((x) => x.libro == 'John' && x.capitulo == 3 && x.versiculo == 16), isTrue);
    });

    test('una palabra de una letra no busca nada, porque no significa nada', () {
      expect(m.buscar('a'), isEmpty);
      expect(m.buscar('  '), isEmpty);
    });

    test('el guion bajo y el tanto por ciento del patron se escapan', () {
      // Sin escapar, buscar "a_b" devuelve cualquier cosa: `_` es "cualquier
      // caracter" en `LIKE`, y `%` es "todo". Quien busca una palabra con guion
      // recibe miles de resultados sin entender por que.
      final conGuion = m.buscar('a_b');
      final conPorcentaje = m.buscar('%');
      expect(conGuion.length, lessThanOrEqualTo(200));
      // Un % literal no deberia encontrar nada en un texto que no lo tiene.
      expect(conPorcentaje, isEmpty, reason: 'el % se busca como un % de verdad');
    });
  });
}
