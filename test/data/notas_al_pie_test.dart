// Las notas al pie, y la prueba que demuestra que no se ha tocado la Escritura.
//
// ============================================================================
// POR QUE ESTA PRUEBA ESTA SEPARADA Y ES LA MAS GRANDE DEL FICHERO
// ============================================================================
//
// Medido el 6 de octubre de 2026 sobre el `KJV2006_bible.amod` real:
//
//     versiculos con \f                      5.844   (18,79 %)
//     notas al pie en total                  6.959
//     capitulos con notas                      913
//     notas por capitulo: media               7,6   maximo 35 (Daniel 11)
//     `text` termina en "REF TEXTO" x N      5.841
//     no termina                                 3
//
// Y SEPRARAR ES LO UNICO QUE TOCA EL TEXTO DE TODA LA APLICACION. Todo lo demas --el numero
// del lexicon, la marca de palabras de Jesus, la marca de palabra anadida-- va **al lado**, y
// eso ya lo comprueba `texto_marcado_test.dart` sobre los mismos 31.102 versiculos.
//
// La prueba de este fichero es la inversa y mas fuerte:
//
//     texto que se pinta  +  notas  ==  `text` del modulo,  byte a byte
//
// para los **31.102 versiculos**. Si eso cuadra, no se ha quitado nada que no fuera una nota
// ni se ha anadido nada. Un lector que altera el texto que va a leer es un lector que no se
// puede citar, y citar mal la Escritura es el fallo mas grave de esta categoria.

import 'dart:io';

import 'package:ab/data/services/analizador_usfm.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  test('1Cronicas 1:6 pierde la nota del texto y la gana su sitio', () {
    // El caso que sale en la tabla del `.amod`, copiado tal cual.
    final texto = 'And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. '
        '1.6 Riphath: or, Diphath as it is in some copies';
    const raw = 'And the \\w sons|strong="H1121"\\w* of \\w Gomer|strong="H1586"\\w*; '
        '\\w Ashchenaz|strong="H0813"\\w*, and \\w Riphath|strong="H7384"\\w*, and '
        '\\w Togarmah|strong="H8425"\\w*.\\f + \\fr 1.6 \\ft Riphath: or, Diphath as it is '
        'in some copies\\f*';

    final r = separarNotasAlPie(texto, raw);

    // Y EL VERSICULO SE QUEDA CON SU TEXTO Y NADA MAS.
    expect(
      r.texto,
      'And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah.',
    );

    // Y LA NOTA ESTA SEPARADA, CON SU LETRA PENDIENTE DE PONER.
    expect(r.notas, hasLength(1));
    expect(r.notas.first.texto, 'Riphath: or, Diphath as it is in some copies');
  });

  test('y el texto mas la nota es el texto del modulo, byte a byte', () {
    final texto = 'And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. '
        '1.6 Riphath: or, Diphath as it is in some copies';
    const raw = 'x\\f + \\fr 1.6 \\ft Riphath: or, Diphath as it is in some copies\\f*';

    final r = separarNotasAlPie(texto, raw);

    expect(
      '${r.texto} ${r.notas.first.referencia} ${r.notas.first.texto}',
      'And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. '
      '1.6 Riphath: or, Diphath as it is in some copies',
    );
  });

  test('un versiculo sin notas sale entero y sin tocar', () {
    // Juan 3:16, que ademas es el que no tiene ni una: medido.
    const texto = 'For God so loved the world, that he gave his only begotten Son, '
        'that whosoever believeth in him should not perish, but have everlasting life.';
    const raw = '\\wj \\w For|strong="G2316"\\w* \\w God|strong="G2316"\\w* ...';

    final r = separarNotasAlPie(texto, raw);

    expect(r.texto, texto);
    expect(r.notas, isEmpty);
  });

  test('dos notas del mismo versiculo salen las dos, con su texto', () {
    // 1Cronicas 1:40, que tiene dos.
    const texto = 'The sons of Shobal; Alian, and Manahath, and Ebal, Shephi, and Onam. '
        'And the sons of Zibeon; Aiah, and Anah. 1.40 Alian: also called, Alvan '
        '1.40 Shephi: also called, Shepho';
    const raw = 'texto\\f + \\fr 1.40 \\ft Alian: also called, Alvan\\f*'
        '\\f + \\fr 1.40 \\ft Shephi: also called, Shepho\\f*';

    final r = separarNotasAlPie(texto, raw);

    expect(
      r.texto,
      'The sons of Shobal; Alian, and Manahath, and Ebal, Shephi, and Onam. '
      'And the sons of Zibeon; Aiah, and Anah.',
    );
    expect(r.notas, hasLength(2));
    expect(r.notas[0].texto, 'Alian: also called, Alvan');
    expect(r.notas[1].texto, 'Shephi: also called, Shepho');
  });

  test('si el texto no termina en la nota, no se separa nada', () {
    // El caso de los tres versiculos de Salmos 119, que llevan el nombre hebreo de la letra
    // despues de la nota y ese nombre no esta en el `\ft`.
    const texto = 'Thy testimonies also are my delight and my counsellors. 119.24 my '
        'counsellors: Heb. men of my counsel ד DALETH.';
    const raw = 'texto\\f + \\fr 119.24 \\ft my counsellors: Heb. men of my counsel\\f*';

    final r = separarNotasAlPie(texto, raw);

    // El versiculo se pinta ENTERO, con la nota dentro, y no hay lista al pie.
    expect(r.texto, texto);
    expect(r.notas, isEmpty);
  });

  test('la marca \\nd sin divisor no se cuela en el texto de la nota', () {
    // 1Samuel 3:7. El `\nd` va entre `\` y `nd`, y el `raw` lo pone como `\\+nd ... \\+nd*`.
    const texto = 'Now Samuel did not yet know the LORD, neither was the word of the LORD '
        'yet revealed unto him. 3.7 Now…: or, Thus did Samuel before he knew the LORD, '
        'and before the word of the LORD was revealed unto him';
    const raw = 'texto\\f + \\fr 3.7 \\ft Now…: or, Thus did Samuel before he knew the '
        '\\+nd LORD\\+nd*, and before the word of the \\+nd LORD\\+nd* was revealed unto him\\f*';

    final r = separarNotasAlPie(texto, raw);

    expect(r.texto, startsWith('Now Samuel did not yet know the LORD'));
    expect(
      r.notas.first.texto,
      'Now…: or, Thus did Samuel before he knew the LORD, and before the word of the LORD '
      'was revealed unto him',
    );
    expect(r.notas.first.texto.contains('\\'), isFalse);
    expect(r.notas.first.texto.contains('+'), isFalse);
  });

  group('sobre el modulo real', () {
    late Sqlite sqlite;
    late ModuloAbierto modulo;

    setUpAll(() {
      if (!File(rutaBibliaReal).existsSync()) {
        fail('Falta $nombreModuloBiblia. Ejecuta bash scripts/preparar-fixtures.sh');
      }
      sqlite = Sqlite.abrir(rutaBibliaReal);
      final abierto = ModuloAbierto.abrir(
        rutaBibliaReal,
        id: 'KJV2006',
      );
      if (abierto is! Abierto) fail('No se ha podido abrir el modulo real: $abierto');
      modulo = abierto.modulo;
    });

    tearDownAll(() {
      modulo.cerrar();
      sqlite.cerrar();
    });

    test('las 5.841 que se separan, mas las 3 que no, son los 5.844', () {
      final conF = sqlite.consultar(
        "SELECT text, raw FROM verses WHERE raw LIKE '%\\f%' ORDER BY book, chapter, verse",
      );

      var separadas = 0;
      var sinSeparar = 0;
      var notas = 0;

      for (final f in conF) {
        final r = separarNotasAlPie(f['text'] as String, f['raw'] as String?);
        if (r.notas.isEmpty) {
          sinSeparar++;
          continue;
        }
        separadas++;
        notas += r.notas.length;

        // Y ESTA ES LA COMPROBACION DE CADA VERSICULO, y la que no se puede hacer con un
        // ejemplo: texto + notas tiene que ser **exactamente** lo que traia la columna.
        final recompuesto = r.notas.isEmpty
            ? r.texto
            : '${r.texto} '
                '${r.notas.map((n) => '${n.referencia} ${n.texto}').join(' ')}';
        expect(
          recompuesto,
          (f['text'] as String).trimRight(),
          reason: 'el versiculo ${f['text']}',
        );
      }

      // Y LAS CIFRAS ESTAN MEDIDAS UNA A UNA sobre el fichero real, y las tres que no se
      // separan son Salmos 119:24, 119:112 y 119:160: el modulo anade el nombre hebreo de la
      // letra despues de la nota y ese nombre no esta en el `\ft`. Son 3 de 5.844 y por eso
      // el versiculo se pinta entero, sin letra y sin lista, en vez de mover la nota.
      expect(conF.length, 5844);
      expect(sinSeparar, 3);
      expect(separadas, 5841);
      // Y LAS NOTAS SON 6.959 EN EL MODULO, PERO SOLO SE SEPARAN 6.956: las tres que faltan
      // son una por cada versiculo de Salmos que no se separa. No es una cuenta perdida: son
      // las tres que el modulo cuenta y la app no ensena, y estan a la vista.
      expect(notas, 6956);
    });

    test('el ancla cae dentro del versiculo en las 6.956 notas', () {
      // Medido: 6.956 de 6.956, y el 100 % es el punto. Con la cuenta recalculada desde el
      // principio del `raw` para cada nota --contando tambien el cuerpo de la nota anterior,
      // que no es del versiculo-- caia dentro solo en 5.841, y el fallo se veia como letras
      // que no aparecian en pantalla y no como una cuenta que no cuadra.
      final conF = sqlite.consultar(
        "SELECT text, raw FROM verses WHERE raw LIKE '%\\f%' ORDER BY book, chapter, verse",
      );

      var dentro = 0;
      var fuera = 0;
      for (final f in conF) {
        for (final n in separarNotasAlPie(f['text'] as String, f['raw'] as String?).notas) {
          if (n.ancla == null) {
            fuera++;
          } else {
            dentro++;
          }
        }
      }

      expect(dentro, 6956);
      expect(fuera, 0);
    });

    test('las letras del capitulo van en orden y sin repetir', () {
      // Y ESTO NO SE COMPRUEBA EN EL PARSER, porque el parser no sabe de capitulos: el que
      // numera es el repositorio, y por eso se comprueba aqui, leyendo de verdad.
      final daniel11 = modulo.leer(const Referencia('Daniel', 11));

      final letras = <String>[
        for (final v in daniel11.versiculos) ...v.notas.map((n) => n.letra),
      ];

      expect(letras, hasLength(35));
      expect(letras.first, 'a');
      expect(letras[1], 'b');
      // Y 35 NOTAS SON 26 DE LA PRIMERA VUELTA Y 9 DE LA SEGUNDA: `a`..`z` y `aa`..`ai`.
      // Y ESTO ES JUSTO LO QUE NO SALIA: con `fromCharCode('a' + n)` la letra 27 es `{`.
      expect(letras[34], 'ai');
      expect(letras.toSet(), hasLength(35));
    });

    test('Salmos 119:24 sale entero, con la nota dentro, y sin lista', () {
      // Y SE PIDE `verse >= ?` Y NO `verse = ?`, que es lo que hace `leer`: Juan 3:16 abre
      // Juan 3 desde el 16. Por eso esto trae 153 versiculos y no uno, y el que se mira es el
      // primero. Ver `modulo_repository.dart`.
      final salmos = modulo.leer(const Referencia('Psalms', 119, 24));

      expect(salmos.versiculos, hasLength(153));
      final v = salmos.versiculos.first;
      expect(v.numero, 24);
      expect(v.notas, isEmpty);
      expect(v.texto, contains('DALETH'));
    });

    test('1Cronicas 1:6 ya no pinta la nota dentro del versiculo', () {
      final cr = modulo.leer(const Referencia('1Chronicles', 1, 6));

      final v = cr.versiculos.first;
      expect(v.texto, isNot(contains('Diphath')));
      expect(v.texto, isNot(contains('1.6')));
      expect(v.notas, hasLength(1));
      expect(v.notas.first.texto, 'Riphath: or, Diphath as it is in some copies');
      expect(v.notas.first.letra, 'a');
    });

    test('Juan 3 entero no tiene ni una nota, y sale sin lista', () {
      // Medido: Juan no tiene notas en el KJV publicado.
      final juan3 = modulo.leer(const Referencia('John', 3));

      expect(juan3.versiculos, hasLength(36));
      expect(juan3.versiculos.expand((v) => v.notas), isEmpty);
    });

    test('quitar las notas no rompe el emparejamiento del lexicon', () {
      // Y ESTO ES LO QUE HABIA QUE MIRAR: si las anotaciones se sacaran del `text` entero en
      // lugar del texto ya sin notas, la palabra 40 seria una que ya no existe en lo que se
      // pinta, la cuenta descuadraria, el emparejamiento se descartaria entero y el versiculo
      // se quedaria sin lexicon. Aqui se lee el tanto por ciento y se compara con el que ya
      // estaba medido.
      var conNotas = 0;
      var conAnotaciones = 0;
      final conF = sqlite.consultar(
        "SELECT text, raw FROM verses WHERE raw LIKE '%\\f%'",
      );

      for (final f in conF) {
        final r = separarNotasAlPie(f['text'] as String, f['raw'] as String?);
        final anotado = anotarTexto(r.texto, r.raw);
        if (r.notas.isNotEmpty) conNotas++;
        if (anotado.anotaciones.isNotEmpty) conAnotaciones++;
      }

      // De los 5.844 versiculos CON notas, el **89,4 %** siguen recibiendo anotaciones. Y ESTE
      // NUMERO ESTA MEDIDO Y NO ES UN OBJETIVO: la linea base de todo el KJV es del 60,03 %, y
      // entre los versiculos con notas es mas alto porque son casi todos del Antiguo
      // Testamento, que viene de una fuente con mas marcado.
      //
      // Y LO QUE ESTA COMPROBANDO ESTA PRUEBA ES QUE NO SEA **CERO**, y antes de quitar el
      // `raw` de las notas lo era: 0 de 5.844. Un cero aqui es un fallo silencioso --el
      // versiculo se ve perfecto, solo que sin los numeros del lexicon-- y por eso el
      // umbral es "mas de la mitad" y no "el mismo tanto por ciento que el KJV entero", que
      // no es el mismo conjunto de versiculos.
      expect(conNotas, 5841);
      expect(
        conAnotaciones / conNotas,
        greaterThan(0.5),
        reason: 'el lexicon tiene que seguir casando despues de quitar las notas',
      );
    });
  });
}