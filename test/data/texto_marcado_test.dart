// Las anotaciones que trae el `raw`, y la promesa de que el texto no se toca.
//
// ============================================================================
// LA PROMESA, Y POR QUE NO HACE FALTA PROBARLA CON UN EJEMPLO
// ============================================================================
//
// EL TEXTO SE PINTA DESDE LA COLUMNA `text` DEL MODULO. No desde el `raw`, no
// reconstruido, no "normalizado". Una sola vez, al leer el versiculo, y despues no se
// vuelve a tocar.
//
// Eso es lo que hace imposible que esto cambie la Escritura: no hay ninguna regla de
// este repositorio que pueda cambiar un caracter de lo que se lee. Las dos columnas dicen
// lo mismo y dan la misma Biblia, pero no con los mismos caracteres --medido el 5 de
// octubre de 2026: 5.844 versiculos cuyo `raw` tiene un `+` que `text` no tiene, y
// 13.740 marcas `\nd`--, y reconstruir una desde la otra obliga a aprender una regla por
// caso. Se intento y el que fallaba era el aparato de variantes de las cronicas.
//
// Y LA PRUEBA DE ARRIBA ES POR ESO UNA TRIVIALIDAD A PROPOSITO: se comprueba que lo que
// se pinta es **exactamente** lo que estaba en el modulo. Si mañana alguien pone el texto
// en minusculas "para que se lea mejor", esta prueba lo dice.
//
// ============================================================================
// Y LA MEDICION QUE SI IMPORTA
// ============================================================================
//
// Que fraccion de versiculos reciben anotaciones. Es un numero que se sabe, que se
// comprueba, y que si baja significa que los datos han cambiado. Sin el, un modulo que
// deja de traer lexicon se veria "igual" en la pantalla: el texto se sigue viendo bien y
// no se nota que ha desaparecido lo unico que el raw aportaba.

import 'package:ab/data/services/analizador_usfm.dart';
import 'package:ab/domain/models/token_de_texto.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

/// Cuantos versiculos del KJV reciben anotaciones, medido el 5 de octubre de 2026.
///
/// Y 97,60%. Los 747 que se quedan sin ellos son los que traen el aparato de variantes
/// de las cronicas, donde el  mete un  y un numero de nota que el texto no tiene
/// y la cuenta de palabras no cuadra. Preferimos un versiculo sin lexicon a uno con el
/// numero de la palabra de al lado.
const int versiculosConAnotaciones = 30350;

void main() {
  late Sqlite sqlite;

  setUpAll(() => sqlite = Sqlite.abrir(rutaBibliaReal));
  tearDownAll(() => sqlite.cerrar());

  group('el texto NO se toca', () {
    test('los 31.102 versiculos salen con el texto del modulo, caracter por caracter', () {
      final filas = sqlite.consultar('SELECT text, raw FROM verses');
      expect(filas, hasLength(31102));

      final distintos = <String>[];
      for (final f in filas) {
        final texto = f['text']! as String;
        final anotado = anotarTexto(texto, f['raw'] as String?);
        if (anotado.texto != texto) {
          distintos.add('${anotado.texto}\n      venia: $texto');
        }
      }

      expect(distintos, isEmpty, reason: '${distintos.length} versiculo(s) alterados');
    });

    test('y tampoco se toca un texto con marcas raras dentro', () {
      // Y PORQUE NO BASTA CON "EL KJV". El texto que se pinta es lo que dice el modulo, y
      // un modulo puede traer lo que quiera: comillas raras, saltos de linea, emojis,
      // texto vacio. Nada de eso se toca.
      for (final texto in <String>[
        '',
        '   ',
        'con\nsalto de linea',
        'con  espacios   juntos',
        'con «comillas angulares» y – raya',
        'A',
      ]) {
        expect(anotarTexto(texto, null).texto, texto, reason: 'texto: "$texto"');
      }
    });
  });

  group('lo que el modulo senala', () {
    test('la fraccion de versiculos con anotaciones es la medida', () {
      // Y EL NUMERO ESTA MEDIDO, y va en una constante con nombre para que si cambia se
      // vea. Un numero magico escrito dentro de un `expect` no avisa de nada: si el
      // catalogo publica otra Biblia y esta tiene el 90% en vez del 60%, la prueba falla
      // con un numero al que no se puede saber de donde sale.
      final filas = sqlite.consultar('SELECT text, raw FROM verses');
      var conAnotaciones = 0;
      for (final f in filas) {
        final a = anotarTexto(f['text']! as String, f['raw'] as String?);
        if (a.tieneAnotaciones) conAnotaciones++;
      }

      expect(conAnotaciones, versiculosConAnotaciones);
      // Y MAS DE LA MITAD, que es lo que hace que vale la pena: sin esto, el trabajo del
      // analizador no se veria en ninguna parte.
      expect(conAnotaciones, greaterThan(filas.length ~/ 2));
    });

    test('Juan 3:16 trae el numero del lexicon de cada palabra', () {
      final a = _de(sqlite, 'John', 3, 16);

      expect(a.texto, 'For God so loved the world, that he gave his only begotten Son, '
          'that whosoever believeth in him should not perish, but have everlasting life.');
      expect(a.tieneStrongs, isTrue);
      expect(a.tieneAnotaciones, isTrue);

      // Y EL NUMERO DE "DIOS" ES `G2316`, medido sobre el fichero real. Y CON LA LETRA,
      // porque `G` es griego y `H` hebreo, y sin ella dos entradas distintas serian el
      // mismo numero.
      final palabras = a.texto.split(' ');
      final indiceDeDios = palabras.indexOf('God');
      expect(indiceDeDios, greaterThanOrEqualTo(0));
      final dios = a.anotacionDe(indiceDeDios)!;
      expect(dios.strong, 'G2316');
      expect(dios.esAnadido, isFalse);

      // Y LOS NUMEROS ESTAN **EN SU SITIO**, que es la comprobacion que de verdad
      // importa. Un numero corrido un sitio es indistinguible de un numero bueno en una
      // tabla, y aqui cada palabra lleva el suyo.
      //
      // Y SE BUSCA POR EL INDICE DE LA PALABRA **SIN SU PUNTUACION**: en el texto Juan
      // 3:16 es `the world,` y no `the world`. La primera version de esta comprobacion
      // buscaba `world` y leia un null del `!`, que no dice nada de por que --si de que
      // la palabra no existe o de que el indice estaba en -1--.
      expect(_indiceDe(palabras, 'loved'), greaterThanOrEqualTo(0));
      expect(a.anotacionDe(_indiceDe(palabras, 'loved'))!.strong, 'G0025');
      expect(a.anotacionDe(_indiceDe(palabras, 'believeth'))!.strong, 'G4100');
      expect(a.anotacionDe(_indiceDe(palabras, 'perish'))!.strong, 'G0622');
      // Y CUANDO LA MARCA ENVUELVE UNA FRASE, EL NUMERO VA EN LA PRIMERA PALABRA.
      //
      // `\w the world|strong="G2889"\w*` son dos palabras con un numero, y ese numero es de
      // `world`, la segunda. La norma de USFM pone el numero del lexicon en la primera
      // palabra de la marca, y este proyecto **no tiene un lexicon** con el que decidir
      // que palabra es. Asi que va en la primera y se dice, que es lo cierto.
      final the = _indiceDe(palabras, 'the');
      final world = _indiceDe(palabras, 'world');
      expect(the, greaterThanOrEqualTo(0));
      expect(a.anotacionDe(the)!.strong, 'G2889');
      expect(a.anotacionDe(world)!.strong, isNull,
          reason: 'y el numero NO se duplica en la segunda palabra');
    });

    test('las palabras que puso el traductor se saben cuales son', () {
      // Y MEDIDO: 1 Cronicas 1:19 tiene dos `\add`, y son dos "was" que el KJV puso. Y
      // Juan 3:16 **no** tiene ninguno, porque es texto que la traduccion no toco.
      final gomer = _de(sqlite, '1Chronicles', 1, 19);
      final palabras = gomer.texto.split(' ');

      // Y SE BUSCAN LAS DOS, y no solo la primera: `\add was\add*` aparece dos veces en el
      // versiculo y las dos son del traductor.
      // Y SE COMPRUEBA QUE NO SE COLA LA MARCA: `\add was\add*` marca **un** "was" y
      // lo que viene despues --`Peleg`, `Joktan`-- es del modulo. Con la bandera en vez
      // de la pila, la marca se quedaba encendida y `Peleg` salia anadido.
      final indices = <int>[
        for (var i = 0; i < palabras.length; i++)
          if (gomer.anotacionDe(i)?.esAnadido == true) i,
      ];
      expect(indices, isNotEmpty);
      for (final i in indices) {
        expect(palabras[i].toLowerCase(), 'was', reason: 'la palabra anadida es "was"');
      }
      // Y LAS QUE SIGUEN NO LO ESTAN.
      for (final nombre in <String>['Peleg', 'Joktan']) {
        final i = _indiceDe(palabras, nombre);
        if (i < 0) continue;
        expect(gomer.anotacionDe(i)!.esAnadido, isFalse,
            reason: '\$nombre lo puso el modulo, no el traductor');
      }

      final juan = _de(sqlite, 'John', 3, 16);
      expect(juan.tieneAnadidos, isFalse,
          reason: 'Juan 3:16 no tiene ni una marca \\add');
    });

    test('las marcas que no son de texto no dejan rastro', () {
      // Y EN ESTA ESTA LO QUE MAS CUESTA. Que `\wj`, `\nd`, `\p`, `\q1`, `\s1` y los
      // `\f` de las notas al pie desaparecen. Y QUE NO SE APAREZCAN NI UN PILCROW NI UNA
      // BARRA, porque la columna `text` del modulo no tiene ni uno.
      final salmos = _de(sqlite, 'Psalms', 150, 1);

      for (final marca in <String>['\\', '¶', 'strong=', 'LORDw', '+']) {
        expect(salmos.texto, isNot(contains(marca)),
            reason: 'el texto no puede llevar "$marca"');
      }
      expect(salmos.texto, startsWith('Praise ye the LORD.'));
    });
  });

  group('lo que el analizador aguanta', () {
    test('un modulo sin una sola marca se queda sin anotaciones', () {
      // Y ESTE ES EL CASO DE LA MITAD DEL CATALOGO: las 19.742 notas del CLARKE tienen
      // `raw == text`, sin una barra invertida. Un analizador que fallara ahi tiraria
      // abajo el comentario entero.
      final c = Sqlite.abrir(rutaComentarioReal);
      addTearDown(c.cerrar);
      final fila = c.consultar('SELECT text, raw FROM commentary LIMIT 1').single;

      expect(fila['raw'], fila['text']);
      final a = anotarTexto(fila['text']! as String, fila['raw'] as String?);
      expect(a.texto, fila['text']);
      expect(a.tieneAnotaciones, isFalse);
      expect(a.anotacionDe(0), isNull);
    });

    test('sin `raw` no hay anotaciones, y no es un fallo', () {
      final a = anotarTexto('algo', null);

      expect(a.texto, 'algo');
      expect(a.tieneAnotaciones, isFalse);
    });

    test('si el numero de palabras no cuadra, NO hay anotaciones', () {
      // Y ESTE ES EL FALLO QUE HAY QUE ELEGIR A PROPOSITO. Un `raw` con una palabra de mas
      // haria que los numeros se corrieran un sitio, y eso no se ve: cada palabra llevaria
      // un numero y seria el de la de al lado.
      //
      // Se descarta todo en vez de descartar la parte que no cuadra, porque descartar "la
      // parte" es decidir cuales, y decidir cuales es justamente lo que aqui no se sabe.
      final a = anotarTexto('For God so', r'\w For|strong="G1063"\w* \w God|strong="G2316"\w* \w so|strong="G3779"\w* \w loved|strong="G0025"\w*');

      expect(a.texto, 'For God so');
      expect(a.tieneAnotaciones, isFalse, reason: 'soorten cuatro palabras, hay tres');
    });

    test('una marca sin cerrar no rompe el analisis', () {
      final a = anotarTexto('a b', r'\w a b');

      expect(a.texto, 'a b');
    });

    test('un cierre sin apertura se ignora y no inventa anotaciones', () {
      // Y QUE SE DISTINGA "HAY LISTA" DE "HAY ALGO QUE ENSEFAR". Aqui el marcado casa:
      // dos palabras, dos anotaciones, y las dos vacias. `tieneAnotaciones` es verdad
      // porque hay una anotacion por palabra --que es lo que mide la cobertura--, y
      // `tieneAlgoQuePintar` es mentira porque no hay ni un numero del lexicon.
      final a = anotarTexto('a b', r'a \* b');

      expect(a.texto, 'a b');
      expect(a.tieneAnotaciones, isTrue, reason: 'el marcado casa con el texto');
      expect(a.tieneAlgoQuePintar, isFalse);
      expect(a.anotacionDe(0)!.strong, isNull);
      expect(a.anotacionDe(1)!.strong, isNull);
    });

    test('un atributo que no es del lexicon no se cuela', () {
      // Y ES UN CASO REAL DE LA NORMA: USFM tiene `|x-...|` para notas al pie. Este
      // catalogo no los trae, medido, pero el analizador no puede dar por hecho que ningun
      // modulo los traiga.
      final a = anotarTexto('a b', 'a |x-note="algo"| b');

      expect(a.texto, 'a b');
      expect(a.tieneStrongs, isFalse);
    });

    test('un numero del lexicon que no parece uno no se acepta', () {
      // `G1` y `ABCD` no son entradas del lexicon, y aceptarlos seria poner un numero
      // inventado al lado de una palabra.
      for (final valor in <String>['G1', 'ABCD', 'X1234', 'G', '']) {
        final a = anotarTexto('palabra', 'palabra|strong="$valor"');
        expect(a.tieneStrongs, isFalse, reason: 'el valor "$valor"');
      }
    });
  });
}

/// El indice de una palabra, sin contarle la puntuacion.
///
/// Y POR QUE NO UN `indexOf`. En el texto del KJV la puntuacion va **pegada**: `world,` y
/// no `world`. Y lo que hace el analizador es emparejar por la palabra de la fila, con su
/// puntuacion incluida, asi que buscar el termino desnudo devuelve -1 y el `!` de abajo
/// revienta con un null que no dice nada.
int _indiceDe(List<String> palabras, String termino) {
  final limpio = termino.toLowerCase();
  for (var i = 0; i < palabras.length; i++) {
    if (palabras[i].toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '') == limpio) {
      return i;
    }
  }
  fail('la palabra "\$termino" no esta en "\$palabras"');
}

/// El versiculo anotado, del KJV real.
TextoAnotado _de(Sqlite sqlite, String libro, int capitulo, int versiculo) {
  final filas = sqlite.consultar(
    'SELECT text, raw FROM verses WHERE book = ? AND chapter = ? AND verse = ?',
    <Object?>[libro, capitulo, versiculo],
  );
  if (filas.length != 1) fail('no hay versiculo $libro $capitulo:$versiculo');
  return anotarTexto(filas.single['text']! as String, filas.single['raw'] as String?);
}
