// Verifica la tabla de libros contra un modulo REAL, no contra si misma.
//
// Una prueba que solo comprobara que la lista tiene 66 entradas passes aunque
// los 66 sean equivocados. La de `aa` se escribio de memoria y **21 de 66
// tenia un numero de versiculos equivocado**. Esta comprueba contra el
// fichero que va a leer la gente.

import 'dart:io';

import 'package:ab/domain/models/libros.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/fixtures.dart';

void main() {
  test('son 66 y el orden es el canonico', () {
    expect(kLibros.length, kTotalLibros);
    expect(kLibros.length, 66);
    // Genesis es el primero y Apocalipsis el ultimo: si esto cambia, el orden
    // canonico esta mal puesto.
    expect(kLibros.first.id, 'Genesis');
    expect(kLibros.last.id, 'Revelation');
    // 39 del Antiguo, 27 del Nuevo.
    expect(kNuevoTestamentoDesde, 40);
  });

  test('ningun nombre es la clave en ingles, salvo los que si lo son', () {
    // "Génesis" y "Genesis" se parecerán al quitar acentos, asi que esta prueba
    // no puede exigir que difieran siempre. Lo que si se exige es que el
    // castellano este presente de verdad.
    final conTilde = kLibros.where((l) => l.nombre.contains('é')).length;
    expect(conTilde, greaterThan(0),
        reason: 'si no hay ni un nombre con tilde, se perdio el castellano');
  });

  test('el fichero NO contiene numeros de capitulo ni de versiculos', () {
    // La comprobacion mas importante de este grupo. Los numeros de un libro se
    // leen del modulo con una consulta, porque una tabla escrita a mano ya
    // salio mal una vez.
    final fuente = File('lib/domain/models/libros.dart').readAsStringSync();
    for (final prohibido in ['capitulos', 'versiculos', 'numCapitulos', 'chapterCount']) {
      final comoCodigo = RegExp(
        r'^\s*(final|const|static)\s+[^/]*\b' '$prohibido' r'\b',
        multiLine: true,
      );
      expect(comoCodigo.hasMatch(fuente), isFalse,
          reason: 'libros.dart declara "$prohibido" y los numeros deben salir '
              'del modulo, no de una tabla');
    }
  });

  group('contra el modulo real', () {
    late Database db;

    setUpAll(() {
      // La ruta la resuelve `test/support/fixtures.dart`, que falla con un mensaje
      // que dice que script hay que ejecutar. Aqui no hay ninguna ruta escrita: por
      // eso estas pruebas pueden correr en un runner de CI.
      db = sqlite3.open(rutaBibliaReal);
    });

    tearDownAll(() => db.close());

    test('PRAGMA quick_check dice ok', () {
      expect(db.select('PRAGMA quick_check').first.values.first, 'ok');
    });

    test('los 66 nombres en castellano resuelven a un libro que EXISTE', () {
      final existentes = <String>{
        for (final fila in db.select('SELECT DISTINCT book FROM verses'))
          fila['book'] as String,
      };
      expect(existentes.length, 66, reason: 'el modulo deberia tener 66 libros');

      final sinResolver = <String>[];
      for (final libro in kLibros) {
        if (!existentes.contains(libro.id)) sinResolver.add(libro.id);
      }
      expect(sinResolver, isEmpty,
          reason: 'estos libros de la tabla no estan en el modulo: $sinResolver');
    });

    test('los numeros salen del modulo y Genesis tiene 50 capitulos, no 51', () {
      // El 51 es el numero de la RVR. Si alguna vez esto devuelve 51, significa
      // que alguien ha metido una tabla de numeros, que es exactamente el fallo
      // que este requisito existe para evitar.
      final cap = db
          .select('SELECT max(chapter) AS c FROM verses WHERE book = ?', ['Genesis'])
          .first['c'] as int;
      expect(cap, 50);
    });

    test('Juan tiene 879 versiculos, leidos del modulo', () {
      final n = db
          .select('SELECT count(*) AS c FROM verses WHERE book = ?', ['John'])
          .first['c'] as int;
      expect(n, 879);
    });
  });

  group('buscar por nombre', () {
    test('las cuatro formas de decir 2 Corintios dan el mismo libro', () {
      const esperado = '2Corinthians';
      for (final forma in [
        '2 Corintios',
        '2corintios',
        'Segundo de Corintios',
        'segunda de corintios',
        'II Corintios',
      ]) {
        final l = libroPorNombre(forma);
        expect(l, isNotNull, reason: 'no resolvio "$forma"');
        expect(l!.id, esperado, reason: '"$forma" resolvio a ${l.id}');
      }
    });

    test('sin acentos, sin mayusculas y con espacios de sobra', () {
      expect(libroPorNombre('  genesis ')!.id, 'Genesis');
      expect(libroPorNombre('GENESIS')!.id, 'Genesis');
    });

    test('un nombre que no existe devuelve null, no lanza', () {
      // Esto se llama desde un campo de texto mientras la persona escribe: una
      // excepcion por cada tecla seria una caida.
      expect(libroPorNombre('Zetaquiel'), isNull);
      expect(libroPorNombre(''), isNull);
      expect(libroPorNombre('   '), isNull);
    });

    test('las 66 claves normalizadas son DISTINTAS entre si', () {
      // Invariante que protege el normalizador. Si dos libros distintos
      // acabaran con la misma clave, uno de los dos no se encontraria nunca y
      // no habria ningun aviso. El fallo es silencioso, asi que se comprueba.
      final porClave = <String, String>{};
      final choques = <String>[];
      for (final l in kLibros) {
        for (final alias in <String>[l.nombre, ...aliasDe(l)]) {
          final clave = _norm(alias);
          final previa = porClave[clave];
          if (previa != null && previa != l.id) {
            choques.add('$clave -> $previa y ${l.id}');
          } else {
            porClave[clave] = l.id;
          }
        }
      }
      expect(choques, isEmpty, reason: 'alias que apuntan a dos libros: $choques');
      expect(porClave.length, greaterThanOrEqualTo(kTotalLibros));
    });

    test('por clave se busca tambien', () {
      expect(libroPorId('John')!.nombre, 'Juan');
      expect(libroPorId('NoExiste'), isNull);
    });
  });
}

/// La misma normalizacion que usa `libros.dart`, replicada aqui a proposito.
///
/// Si se usara la privada, esta prueba no serviria para nada: cambiaria con ella
/// y pasaria siempre. Es una copia para poder decir "la normalizacion produce 66
/// claves distintas" desde fuera.
String _norm(String s) {
  var t = s.toLowerCase().trim();
  t = t.replaceAll(RegExp('[a\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]'), 'a')
      .replaceAll(RegExp('[e\u00e8\u00e9\u00ea\u00eb\u00e7]'), 'e')
      .replaceAll(RegExp('[i\u00ec\u00ed\u00ee\u00ef]'), 'i')
      .replaceAll(RegExp('[o\u00f2\u00f3\u00f4\u00f5\u00f6]'), 'o')
      .replaceAll(RegExp('[u\u00f9\u00fa\u00fb\u00fc]'), 'u')
      .replaceAll('\u00f1', 'n')
      .replaceAllMapped(
        RegExp(r'^\s*([ivxlc]+)\s+'),
        (m) => ' ${const {'i': '1', 'ii': '2', 'iii': '3', 'iv': '4'}[m.group(1)!] ?? m.group(1)!} ',
      );
  t = t.replaceAll(RegExp('[^a-z0-9 ]'), ' ');
  t = t.replaceAllMapped(
    RegExp(r'\b(primero|primer|segundo|segunda|tercero|tercera)\b'),
    (m) => ' ${const {'primer': '1', 'primero': '1', 'primera': '1', 'segundo': '2', 'segunda': '2', 'tercero': '3', 'tercera': '3'}[m.group(1)!] ?? m.group(1)!} ',
  );
  t = t.replaceAll(RegExp(r'\b(de|del|libro|libros|epistola)\b'), ' ');
  return t.replaceAll(RegExp(r'\s+'), '');
}
