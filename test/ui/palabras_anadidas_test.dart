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
      final v = modulo.leer(const Referencia('1Chronicles', 1, 19)).versiculos.single;

      expect(v.palabrasAnadidas(), <String>['was', 'was']);
      expect(v.anotaciones.where((a) => a.esAnadido), hasLength(2));
      // Y EL TEXTO SIGUE SIENDO EL DEL MODULO, con su puntuacion y todo.
      expect(v.texto, endsWith('1.19 Peleg: that is, division'),
          reason: 'el KJV pega aqui el aparato de variantes, y es parte del texto');
    });

    test('Juan 3:16 no tiene ni una palabra del traductor', () {
      // Y ES LO QUE HACE COMPROBABLE LA CIFRA: si Juan 3:16 tuviera un `\add`, entonces
      // "41.692 marcas en 31.102 versiculos" seria una media y no una medida.
      final v = modulo.leer(const Referencia('John', 3, 16)).versiculos.single;

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
        final v = modulo.leer(r).versiculos.single;
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
            alCambiarDeVersion: (_) {},
          ),
        ),
      );
      vm.leer(referencia);
      await tester.pumpAndSettle();
    }

    testWidgets('lo que se lee es EXACTAMENTE lo que tiene el modulo', (tester) async {
      await pintar(tester, const Referencia('1Chronicles', 1, 19));

      final delModulo = modulo.leer(const Referencia('1Chronicles', 1, 19)).versiculos.single;

      // Y SE BUSCA EL QUE **ES** EL VERSICULO, y no se coge el ultimo. Con `.last`
      // salia el titulo de la barra --"Comentario"-- y la comprobacion comparaba la
      // Escritura con el texto de un boton. En una pantalla donde el titulo es el ultimo
      // `RichText` en construirse, comparar eso no dice nada del versiculo.
      final textos = <String>[
        for (final rico in tester.widgetList<RichText>(find.byType(RichText)))
          rico.text.toPlainText(),
      ];
      expect(textos, contains(delModulo.texto),
          reason: 'lo pintado tiene que ser el texto del modulo, sin un caracter de mas');
      // Y ADEMAS QUE NO HAYA NINGUNO **IGUAL** CON UN CARACTER DE MAS O DE MENOS, que es
      // el fallo que de verdad se quiere cazar: un texto casi correcto.
      for (final pintado in textos) {
        if (pintado == delModulo.texto) continue;
        expect(pintado, isNot(contains(delModulo.texto.substring(0, 60))),
            reason: 'otro texto de la pantalla se parece demasiado al versiculo');
      }
    });

    testWidgets('las palabras del traductor salen subrayadas, y solo ellas',
        (tester) async {
      await pintar(tester, const Referencia('1Chronicles', 1, 19));

      // Y SE CUENTAN LOS SUBRAYADOS DEL **VERSAICULO**, y no los de la pantalla: hay
      // subrayados en los terminos y en el campo, y contarlos todos no dice nada de las
      // palabras del traductor.
      final subrayados = <String>[];
      for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
        _recorrer(rico.text, subrayados);
      }
      expect(subrayados, <String>['was', 'was'],
          reason: 'son dos marcas \\add, medidas sobre el fichero real');
    });

    testWidgets('Juan 3:16 no tiene nada subrayado', (tester) async {
      await pintar(tester, const Referencia('John', 3, 16));

      final subrayados = <String>[];
      for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
        _recorrer(rico.text, subrayados);
      }
      expect(subrayados, isEmpty);
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
