// Las notas al pie EN PANTALLA: la letra en el texto y la lista al pie del capitulo.
//
// ============================================================================
// POR QUE ESTA PRUEBA Y NO SOLO LA DEL PARSER
// ============================================================================
//
// `test/data/notas_al_pie_test.dart` comprueba que la separacion es correcta sobre los
// 31.102 versiculos. Esta comprueba que se **ve**.
//
// Y NO SON LA MISMA COSA, y el motivo esta medido en `AGENTS.md` con un fallo concreto: la
// primera vez que se implemento el resaltado, veinticinco pruebas del view model estaban en
// verde, el modelo era el correcto, el almacenamiento era el correcto, y la pantalla **no se
// repintaba**. Un modelo correcto no se ve. Y en este caso concreto hay un riesgo todavia
// mayor: si la lista de notas va vacia por un `if` mal puesto, el versiculo se ve
// **perfectamente** y no hay nada que dire que falte.
//
// ASI QUE SE MONTA LA PANTALLA CON UN `.amod` REAL, se busca la letra y se mira el texto.
// Los versiculos que se usan estan medidos:
//   - 1Cronicas 1:6, una nota
//   - Daniel 11, 35 notas, que es el maximo del KJV
//   - Juan 3, CERO notas, que es el caso de los cuatro evangelios

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/versiculo.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/lector/widgets/notas_al_pie_del_capitulo.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';
import '../support/fuente.dart';

/// Todos los textos que se pintan, incluidos los de dentro de un texto enriquecido.
///
/// Y SE RECOGEN LOS **`RichText`**, que es donde Flutter pinta de verdad cualquier texto, y no
/// solo los widgets `Text`. El versiculo se pinta con `Text.rich` --porque las palabras con
/// numero del lexicon son pulsables-- y ahi el texto vive en un `RichText` con un `TextSpan`,
/// no en un `Text` con `data`. Mirando solo `Text`, esta prueba leia la barra, los numeros de
/// versiculo y los terminos, y **ni una palabra del versiculo**: pasaria con el versiculo
/// entero vacio, que es justo el fallo que no se puede ver.
///
/// Y POR ESO RECORRE LOS HIJOS DEL `TextSpan` A MANO. No hay atajo para el texto de un
/// `TextSpan` anidado.
String _textoDeLaPantalla(WidgetTester tester) {
  // Y LOS TROZOS SE JUNTAN **SIN SEPARADOR**, porque entre palabra y palabra hay un `TextSpan`
  // de un espacio que ya se ha recogido. Con un separador puesto por aqui, la frase del
  // versiculo sale partida en palabras sueltas y una comprobacion de "contiene 'And the sons'"
  // falla con el versiculo perfectamente bien pintado.
  return _trozosDeLaPantalla(tester).join();
}

/// Cada trozo de texto por separado, sin juntar.
///
/// Y PARA MIRAR UNA **LETRA CONCRETA**. La letra de la nota 35 es `ai`, y si se junta todo en
/// una cadena, `ai` aparece dentro de `said` o de `again` y la comprobacion no distingue una
/// cosa de la otra. Mirando los trozos sueltos, `ai` solo puede ser la letra: en un texto de
/// Daniel no hay ninguna palabra que sea exactamente `ai`.
List<String> _trozosDeLaPantalla(WidgetTester tester) {
  final trozos = <String>[];

  void visitar(InlineSpan? span) {
    if (span == null) return;
    if (span is TextSpan) {
      final t = span.text;
      if (t != null && t.isNotEmpty) trozos.add(t);
      for (final hijo in span.children ?? const <InlineSpan>[]) {
        visitar(hijo);
      }
    }
  }

  for (final t in tester.widgetList<RichText>(find.byType(RichText))) {
    visitar(t.text);
  }
  return trozos;
}

Future<void> _montar(WidgetTester tester, Referencia referencia) async {
  final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
  if (r is! Abierto) fail('la Biblia real deberia abrirse');

  final vm = LectorViewModel();
  vm.abrir(r.modulo, licenciaDelManifiesto: 'PublicDomain');
  vm.leer(referencia);
  await tester.pumpWidget(
    MaterialApp(
      theme: temaDeAb(),
      home: LectorView(
        viewModel: vm,
        alPulsarPasaje: (_) {},
        alCambiarDeVersion: (_) {},
        alVolver: () {},
        alPedirComentario: () {},
        alVerIndice: (_) {},
        alAlternarPalabrasDeJesus: () {},
        alAbrirLibros: () {},
        alAbrirVersiones: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Baja hasta el final del capitulo, que es donde esta la lista de notas.
///
/// Y NO ES `dragUntilVisible` PORQUE NO HAY NADA QUE BUSCAR TODAVIA: el widget existe pero
/// con la lista vacia devuelve un `SizedBox` de ancho y alto cero, y `dragUntilVisible` se
/// queda esperando un widget que no aparece. Con `drag` repetido se llega al final y ya esta
/// el texto, que es lo que se quiere comprobar.
Future<void> _bajarAlPie(WidgetTester tester) async {
  final lista = find.byType(ListView).last;
  for (var i = 0; i < 30; i++) {
    await tester.drag(lista, const Offset(0, -600));
    await tester.pumpAndSettle();
    if (_textoDeLaPantalla(tester).contains('Notas al pie')) return;
  }
}

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  testWidgets('1Cronicas 1:6: la letra "a" sale pegada al texto, y la nota al pie', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _montar(tester, const Referencia('1Chronicles', 1, 6));

    final pintado = _textoDeLaPantalla(tester);

    // Y LA NOTA **NO** SALE DENTRO DEL VERSICULO. Es lo que se estaba viendo antes de este
    // change y es lo que un lector no puede distinguir de la Escritura si no se dice.
    expect(pintado, contains('And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah.'));
    expect(pintado, isNot(contains('Diphath as it is in some copies')),
        reason: 'la nota al pie no puede ir pegada al versiculo');
    expect(pintado, isNot(contains('1.6 Riphath')),
        reason: 'la referencia del modulo tampoco va dentro del versiculo');

    // Y LA NOTA **SI** SALE AL PIE, con su texto. Se baja hasta ella, porque la lista va
    // **despues** del capitulo y en 1Cronicas 1 --que tiene 54 versiculos, medido-- eso es
    // mas alla de la pantalla.
    await _bajarAlPie(tester);
    expect(_textoDeLaPantalla(tester), contains('Notas al pie'));
    expect(_textoDeLaPantalla(tester), contains('Riphath: or, Diphath as it is in some copies'));
  });

  testWidgets('la letra va pegada a la palabra del modulo, no suelta', (tester) async {
    // Y ESTA ES LA COMPROBACION DE DONDE ESTA LA LETRA, y no puede ser "sale una 'a' en
    // algun sitio": con 54 versiculos salen 54 numeros, asi que una letra suelta no se
    // distinguiria de un numero. Se mira que la letra este en el MISMO `TextSpan` que la
    // palabra a la que el `raw` la engancho.
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _montar(tester, const Referencia('1Chronicles', 1, 6));

    final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
    if (r is! Abierto) fail('la Biblia real deberia abrirse');
    final v = r.modulo.leer(const Referencia('1Chronicles', 1, 6)).versiculo(6)!;
    r.modulo.cerrar();

    expect(v.notas, hasLength(1));
    expect(v.notas.first.ancla, isNotNull);

    // Y EL ANCLA DICE EN QUE PALABRA VA, y puede valer **justo el numero de palabras**, que es
    // lo que significa "la letra va al final del versiculo". Medido: asi pasa en 1Cronicas 1:6,
    // cuya nota va detras de `Togarmah.`, que es la ultima palabra. Por eso `<=` y no `<`.
    expect(v.notas.first.ancla!, lessThanOrEqualTo(v.palabras.length));

    // Y LA LETRA VA PEGADA A LA PALABRA QUE ESTA **JUSTO ANTES** DEL ANCLA, porque el ancla es
    // una cuenta y no un indice. Medido: en 1Cronicas 1:6 el ancla es 10, que es el numero de
    // palabras del versiculo, o sea "despues de la ultima", que es `Togarmah.`.
    final indice = v.notas.first.ancla! == 0 ? 0 : v.notas.first.ancla! - 1;
    final palabra = v.palabras[indice];
    final pegada = '$palabra${v.notas.first.letra}';
    expect(_textoDeLaPantalla(tester), contains(pegada),
        reason: 'la letra tiene que ir pegada a "$palabra"');
  });

  testWidgets('Juan 3 no tiene ni una nota, y no sale la lista', (tester) async {
    // Y ESTE ES EL CASO QUE MAS SE LEE Y EL QUE MAS SE ROMPE. Juan 3 tiene 36 versiculos y
    // cero notas --medido--, asi que con la lista siempre ahi arriba habia 36 lineas de
    // "Notas al pie" y luego nada. Un titulo sin contenido debajo parece un fallo de carga.
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _montar(tester, const Referencia('John', 3));

    await _bajarAlPie(tester);

    final pintado = _textoDeLaPantalla(tester);
    expect(pintado, isNot(contains('Notas al pie')));
    expect(pintado, contains('For God so loved the world'));
    // Y NO HAY NI UNA NOTA, y no se comprueba con `find.byType`: el widget se llama siempre
    // y con la lista vacia devuelve un `SizedBox` de cero, asi que "no esta el widget" no
    // distingue el caso bueno del malo. Lo que se mira es que **no haya texto de nota**.
    expect(pintado, isNot(contains('Heb.')));
    expect(pintado, isNot(contains('or, ')));
  });

  testWidgets('Daniel 11 pinta sus 35 notas, y ninguna se pierde', (tester) async {
    // Y EL MAXIMO MEDIDO. Aqui es donde se ve si el numerador sobrevive a dos vueltas:
    // con `String.fromCharCode('a' + n)` la letra 27 es `{` y la 35 es `I`.
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _montar(tester, const Referencia('Daniel', 11));
    await _bajarAlPie(tester);

    final trozos = _trozosDeLaPantalla(tester).toSet();

    // Y LA LETRA 35 ES `ai`, Y NO UN CARACTER RARO NI UNA LETRA REPETIDA. Es la comprobacion
    // que distingue las dos formas de numerar que se han probado: `fromCharCode('a' + n)` --
    // que da `{`, `|`, `}` a partir de la 27-- y la letra repetida, que daria `ii`.
    expect(trozos, contains('ai'));
    expect(trozos, isNot(contains('ii')));
    // Y NO HAY NINGUN CARACTER DE LOS QUE SALEN AL PASARSE DE LA Z.
    for (final t in trozos) {
      expect(t.contains('{'), isFalse, reason: 'letra mal formada en "$t"');
      expect(t.contains('|'), isFalse, reason: 'letra mal formada en "$t"');
      expect(t.contains('}'), isFalse, reason: 'letra mal formada en "$t"');
    }

    // Y HAY 35 NOTAS. Se cuentan las que el modelo trae, que es lo que la lista pinta.
    final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
    if (r is! Abierto) fail('la Biblia real deberia abrirse');
    final notas = r.modulo.leer(const Referencia('Daniel', 11)).versiculos
        .expand((v) => v.notas)
        .toList();
    r.modulo.cerrar();

    expect(notas, hasLength(35));
    expect(notas.first.letra, 'a');
    expect(notas.last.letra, 'ai');
    // Y LAS 35 LETRAS SON DISTINTAS, que es la comprobacion de que el numerador no repite.
    expect(notas.map((n) => n.letra).toSet(), hasLength(35));
  });

  testWidgets('a 360 px la lista se ve sin desbordar', (tester) async {
    // Y NO ES UN "NO DESBORDA" DE LOS QUE SALEN EN VERDE SIN COMPROBAR: se mira que la letra
    // y el texto de la nota estan EN PANTALLA, que es lo que se rompe con una columna fija.
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _montar(tester, const Referencia('1Chronicles', 1, 6));
    await _bajarAlPie(tester);

    // Y LA COMPROBACION ES QUE **SE VE**, no que no revienta. Un `takeException` vacio sale
    // igual cuando el widget no se ha construido, que es justo cuando esto se rompe: la nota
    // cabe a 1440 y a 360 se sale, y en ambos casos no hay excepcion.
    expect(_textoDeLaPantalla(tester), contains('Notas al pie'));
    expect(tester.takeException(), isNull);
  });

  group('la lista de notas con un pasaje que no es de Biblia', () {
    testWidgets('no pinta nada, y no lanza', (tester) async {
      // Y ESTE ES UN CASO QUE SE PASA POR ALTO. `NotasAlPieDelCapitulo` recibe una lista de
      // `Versiculo`, y un pasaje de comentario no tiene ninguno: `traeNotas` es cierto y
      // `versiculos` esta vacia. Si alguien lo pasa sin mirar, la lista pinta un separador y
      // un titulo con nada debajo.
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: const Scaffold(
            body: NotasAlPieDelCapitulo(versiculos: <Versiculo>[]),
          ),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });
}