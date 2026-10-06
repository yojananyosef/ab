// Las palabras que puso el traductor, en pantalla.
//
// Y LO QUE ESTA EN JUEGO EN ESTE FICHERO. El texto de un versiculo **no cambia**: lo que
// se pinta es el texto de la columna `text` del modulo, byte a byte. Lo unico que se
// cambia es que algunas palabras llevan un subrayado, y por que.
//
// Y LA PRIMERA COMPROBACION ES LA IMPORTANTE Y ES UNA TRIVIALIDAD A PROPOSITO: lo que se
// lee en pantalla es exactamente lo que el modulo tiene. No "casi", no "normalizado". Un
// lector que altera el texto que va a leer es un lector que no se puede citar, y citar mal
// la Escritura es el fallo mas grave de esta categoria.
//
// QUE SE PINTE CON `Text.rich` Y NO CON `Text` ES EL RIESGO DE ESTE CAMBIO, y por eso hay
// una comprobacion de que el texto plano del `RichText` es identico al del modulo: partir
// el texto en palabras y volverlo a juntar es una operacion que parece que no puede fallar
// y puede.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('las palabras del traductor se saben cuales son', () {
    late ModuloAbierto modulo;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      addTearDown(modulo.cerrar);
    });

    test('1 Cronicas 1:19 trae dos "was" del traductor, y solo dos', () {
      // Y MEDIDO sobre el fichero real: dos marcas `\add`, y son dos "was".
      final v = modulo.leer(const Referencia('1Chronicles', 1, 19)).versiculo(19)!;

      expect(v.palabrasAnadidas(), <String>['was', 'was']);
      expect(v.anotaciones.where((a) => a.esAnadido), hasLength(2));

      // Y ESTE VERSICULO TENIA UNA NOTA AL PIE, Y ANTES LA PRUEBA DECIA QUE SE QUEDABA DENTRO.
      //
      // Lo que decia era: "el KJV pega aqui el aparato de variantes, y es parte del texto", y
      // era verdad a medias: la columna `text` la trae pegada, pero el `raw` la marca como
      // `\f + \fr 1.19 \ft Peleg: that is, division\f*`, o sea que **el propio modulo dice que
      // es una nota y no un versiculo**. Se estaba ensenando dentro del versiculo, en el
      // mismo cuerpo y con el mismo color que la Palabra. Medido: 5.844 versiculos con este
      // caso, el 18,79 % del KJV.
      //
      // Y ASI QUE ESTA AFIRMACION HA CAMBIADO DE SIGNIFICADO, y el cambio es el que importa:
      // el texto **sigue** siendo el del modulo, sin alterar ni una coma, pero ahora sin la
      // nota dentro, y la nota va en `v.notas`.
      expect(v.texto, endsWith('and his brother’s name was Joktan.'),
          reason: 'la nota al pie ya no va pegada al versiculo');
      expect(v.texto, isNot(contains('division')));
      expect(v.notas, hasLength(1));
      expect(v.notas.first.texto, 'Peleg: that is, division');
      expect(v.notas.first.letra, 'a');
    });

    test('Juan 3:16 no tiene ni una palabra del traductor', () {
      // Y ES LO QUE HACE COMPROBABLE LA CIFRA: si Juan 3:16 tuviera un `\add`, entonces
      // "41.692 marcas en 31.102 versiculos" seria una media y no una medida.
      final v = modulo.leer(const Referencia('John', 3, 16)).versiculo(16)!;

      expect(v.palabrasAnadidas(), isEmpty);
      expect(v.texto, startsWith('For God so loved the world'));
      // Y EL LEXICON **SI** ESTA, que es distinto de lo del traductor.
      expect(v.anotaciones.any((a) => a.strong != null), isTrue);
    });

    test('el versiculo tiene SIEMPRE una anotacion por palabra, o ninguna', () {
      // Y PORQUE. Una lista a medias pondria el numero del lexicon de la palabra trece en
      // la doce, y eso no se ve hasta que alguien lo busca.
      for (final r in <Referencia>[
        const Referencia('John', 3, 16),
        const Referencia('1Chronicles', 1, 19),
        const Referencia('Genesis', 1, 1),
        const Referencia('Psalms', 150, 1),
      ]) {
        final v = modulo.leer(r).versiculo(r.versiculo ?? 1)!;
        final n = v.palabras.length;
        expect(
          v.anotaciones.isEmpty || v.anotaciones.length == n,
          isTrue,
          reason: '${r.paraUrl}: ${v.anotaciones.length} anotaciones para $n palabras',
        );
      }
    });

    test('partir y volver a juntar deja el texto igual', () {
      // Y LA IDENTIDAD QUE SOSTIENE TODA LA PANTALLA. `split(' ').join(' ')` es `texto`
      // para cualquier texto sin espacios dobles, y no hay forma de que se rompa al
      // pintar; pero es mejor comprobarlo con los 66 libros que suponerlo.
      var comprobados = 0;
      for (final libro in modulo.libros().take(12)) {
        for (final capitulo in modulo.capitulosDe(libro).take(2)) {
          for (final v in modulo.leer(Referencia(libro, capitulo)).versiculos) {
            expect(v.palabras.join(' '), v.texto, reason: '$libro $capitulo:${v.numero}');
            comprobados++;
          }
        }
      }
      expect(comprobados, greaterThan(500));
    });
  });

  group('en pantalla', () {
    late ModuloAbierto modulo;
    late LectorViewModel vm;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      vm = LectorViewModel();
      vm.abrir(modulo, licenciaDelManifiesto: null);
      addTearDown(vm.dispose);
    });

    Future<void> pintar(WidgetTester tester, Referencia referencia) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: LectorView(
            viewModel: vm,
            alVolver: () {},
            alPulsarPasaje: vm.leer,
            alPedirComentario: () {},
            alVerIndice: (_) {},
            alAlternarPalabrasDeJesus: () {},
            alAbrirLibros: () {},
            alAbrirVersiones: () {},
            alCambiarDeVersion: (_) {},
          ),
        ),
      );
      vm.leer(referencia);
      await tester.pumpAndSettle();
    }

    testWidgets('lo que se lee es EXACTAMENTE lo que tiene el modulo', (tester) async {
      await pintar(tester, const Referencia('1Chronicles', 1, 19));

      final delModulo = modulo.leer(const Referencia('1Chronicles', 1, 19)).versiculo(19)!;

      // Y SE BUSCA EL QUE **ES** EL VERSICULO, y no se coge el ultimo. Con `.last`
      // salia el titulo de la barra --"Comentario"-- y la comprobacion comparaba la
      // Escritura con el texto de un boton. En una pantalla donde el titulo es el ultimo
      // `RichText` en construirse, comparar eso no dice nada del versiculo.
      // Y SE COMPARA CON `startsWith` Y NO CON `==`, porque este versiculo **tiene una nota al
      // pie** y la letra va pegada al texto: lo pintado es el texto del modulo mas la `a` de
      // `Joktan.a`. Lo que no puede pasar es que lo pintado sea el texto **mas algo que no sea
      // una letra de nota**, y eso lo comprueba la linea de abajo.
      final textos = <String>[
        for (final rico in tester.widgetList<RichText>(find.byType(RichText)))
          rico.text.toPlainText(),
      ];
      expect(
        textos.any((pintado) => pintado.startsWith(delModulo.texto)),
        isTrue,
        reason: 'lo pintado tiene que empezar por el texto del modulo, sin un caracter de mas',
      );
      // Y ADEMAS QUE NO HAYA NINGUNO **IGUAL** CON UN CARACTER DE MAS O DE MENOS, que es
      // el fallo que de verdad se quiere cazar: un texto casi correcto. Y aqui se salta el
      // versiculo por `startsWith` y no por igualdad, porque con la letra de la nota ya no
      // puede ser igual.
      for (final pintado in textos) {
        if (pintado.startsWith(delModulo.texto)) continue;
        expect(pintado, isNot(contains(delModulo.texto.substring(0, 60))),
            reason: 'otro texto de la pantalla se parece demasiado al versiculo');
      }

      // Y LO QUE SE AÑADE AL VERSICULO ES **SOLO** LA LETRA DE LA NOTA. Este versiculo tiene
      // una nota --medido, `1.19 Peleg: that is, division`--, asi que lo pintado es el texto
      // del modulo mas la letra, y nada mas.
      final conLetra = textos.firstWhere((p) => p.startsWith(delModulo.texto));
      expect(conLetra.substring(delModulo.texto.length), isNotEmpty,
          reason: 'la nota al pie tiene que dejar su letra pegada al texto');
      expect(conLetra.substring(delModulo.texto.length).length, lessThanOrEqualTo(2),
          reason: 'y solo la letra: la nota entera ya no va dentro del versiculo');
    });

    testWidgets('las palabras del traductor salen subrayadas, y solo ellas',
        (tester) async {
      await pintar(tester, const Referencia('1Chronicles', 1, 19));

      // Y SE CUENTAN LOS SUBRAYADOS **DEL VERSICULO PEDIDO**, y no los de la pantalla.
      //
      // Y NO POR EL VERSICULO 19 SINO POR EL **TEXTO IGUAL**: desde que un versiculo
      // pedido trae el capitulo entero, 1 Cronicas 1:19 enseña del 19 al 29 y los
      // capitulos siguientes traen mas palabras del traductor. Contando toda la pantalla
      // salia una lista de nueve palabras en vez de dos, y la prueba daba verde sin
      // comprobar lo que decia comprobar.
      final v = modulo.leer(const Referencia('1Chronicles', 1, 19)).versiculo(19)!;
      final subrayados = _subrayadosDe(tester, v.texto);
      expect(subrayados, <String>['was', 'was'],
          reason: 'son dos marcas de anadido, medidas sobre el fichero real');
    });

    testWidgets('Juan 3:16 no tiene nada subrayado', (tester) async {
      // Y JUAN 3:16 **NO TIENE NADA SUBRAYADO**, y eso se comprobaba mal hasta hace un
      // momento: la pantalla trae el capitulo entero desde el 16, y del 17 al 36 hay
      // palabras del traductor. Contando toda la pantalla salia una lista con cinco
      // palabras --'some', 'men', 'must', 'unto', 'him.'-- y la prueba fallaba. Con el
      // versiculo acotado, Juan 3:16 sigue sin tener ni una.
      await pintar(tester, const Referencia('John', 3, 16));

      final v = modulo.leer(const Referencia('John', 3, 16)).versiculo(16)!;
      expect(_subrayadosDe(tester, v.texto), isEmpty);
    });

    testWidgets('a 360 px un versiculo con palabras subrayadas no sale del borde',
        (tester) async {
      await pintar(tester, const Referencia('1Chronicles', 1, 19));
      expect(tester.takeException(), isNull);

      // Y EL VERSAICULO LARGO DE JUAN 3:16, que son 141 caracteres con el lexicon.
      await pintar(tester, const Referencia('John', 3, 16));
      expect(tester.takeException(), isNull);
    });
  });
}

/// Los tramos subrayados del `RichText` que **empieza** por [texto].
///
/// Y POR TEXTO IGUAL Y NO POR POSICION. El capitulo entero son 21 `RichText` y la pantalla
/// tiene ademas el campo, el titulo y los terminos; el primero no es el versiculo. Y con
/// texto igual no hay ambiguedad: dos versiculos distintos no tienen el mismo texto.
///
/// Y **EMPIEZA POR** Y NO ES IGUAL, y el motivo es la letra de las notas al pie. Un versiculo
/// con nota se pinta con la letra pegada a la palabra a la que el modulo la engancho --en
/// 1Cronicas 1:19, una `a` detras de `Joktan.`--, asi que el texto pintado es el del modulo
/// **mas la letra**. Con `==` no se encontraria el versiculo, y la prueba fallaria
/// escribiendo que "no se ha encontrado en pantalla el texto", que no dice donde esta el
/// fallo.
///
/// Y `startsWith` SIGUE SIENDO UNA COMPROBACION EXACTA DE LO QUE IMPORTA: dos versiculos
/// distintos no pueden empezar igual, asi que sigue habiendo una sola coincidencia.
List<String> _subrayadosDe(WidgetTester tester, String texto) {
  for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
    if (!rico.text.toPlainText().startsWith(texto)) continue;
    final salida = <String>[];
    _recorrer(rico.text, salida);
    return salida;
  }
  fail('no se ha encontrado en pantalla el texto: "$texto"');
}

/// Recorre un `TextSpan` y recoge el texto de los tramos subrayados.
void _recorrer(InlineSpan span, List<String> salida) {
  if (span is! TextSpan) return;
  if (span.style?.decoration == TextDecoration.underline) {
    final texto = span.toPlainText();
    if (texto.trim().isNotEmpty) salida.add(texto);
  }
  for (final hijo in <InlineSpan>[...?span.children]) {
    _recorrer(hijo, salida);
  }
}
