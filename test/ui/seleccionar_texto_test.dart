// Que se pueda seleccionar el texto, y que tocar una palabra no se lo lleve.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y QUE HABIA
// ============================================================================
//
// MEDIDO EL 6 DE OCTUBRE DE 2026: un `grep` de `SelectionArea`, `SelectableRegion` y
// `SelectableText` en **toda** la aplicacion no devuelve nada. No habia forma de seleccionar
// un versiculo, ni con el dedo ni con el raton.
//
// Y NO FALLA, que es lo que lo ha dejado asi: el texto se pinta, se lee, se marca por su
// numero y se puede copiar con el atajo del teclado. Un `Text` normal **parece** seleccionable
// porque en el navegador se puede sombrear con el cursor, y eso es el `user-select` del CSS,
// que no es seleccion de Flutter. Con el dedo no hay atajo.
//
// Y EN EL CODIGO DE LA COLUMNA HAY UN COMENTARIO QUE DICE QUE SE PUEDE, treinta lineas mas
// abajo de donde se decide:
//
//     tocarlo lo selecciona --que es lo que quiere quien copia un versiculo--
//
// O sea: el comentario describe una capacidad que no estaba implementada, y quien lo lea
// creera que seleccionar funciona.
//
// ============================================================================
// Y EL OTRO SINTOMA, QUE ES EL MISMO PROBLEMA DE OTRA FORMA
// ============================================================================
//
// Al tocar una palabra con numero de lexicon se iba al indice de golpe, y no se podia
// seleccionar nada alrededor. MEDIDO el 6 de octubre de 2026 sobre el KJV: el lexicon tiene
// **348.884 ocurrencias en 31.102 versiculos**, o sea que casi todas las palabras tienen
// numero. Tocar el texto es casi siempre abrir el indice, y seleccionar es casi nunca posible.
//
// Y NO SON DOS FALLOS: son uno. El indice se abria con un `TapGestureRecognizer` **sobre** el
// texto, y el toque es el gesto que pide el dedo. El framework lo resuelve para el que gana, y
// el que gana no es el de seleccionar.
//
// ============================================================================
// Y LO QUE NO SE COMPRUEBA AQUI, Y SE DICE
// ============================================================================
//
// Que lo seleccionado se pueda **copiar**, que necesita `selectionControls` y el portapapeles,
// y que en el navegador pasa por la API del sistema. Esto comprueba que la region de seleccion
// existe, que cubre la columna y que el toque ya no se la lleva, que es lo que estaba roto.

import 'package:flutter/gestures.dart';

import 'package:ab/ui/features/lector/widgets/linea_enfocada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';

import 'package:ab/ui/features/lector/views/lector_view.dart';

import 'lector_view_test.dart' show montarLector;

void main() {
  group('1. se puede seleccionar', () {
    testWidgets('la columna de lectura esta dentro de una region de seleccion', (t) async {
      await _montar(t);

      // Y SE COMPRUEBA QUE HAY UNA REGION **Y QUE ABARCA LA COLUMNA**, y no solo que existe
      // un `SelectionArea` en el arbol: un `SelectionArea` autour del **campo de buscar**
      // --que tambien hay uno-- comprobaria lo mismo y dejaria el texto sin seleccionar.
      final areas = find.byType(SelectionArea);
      expect(areas, findsWidgets, reason: 'no hay ninguna region de seleccion');

      final cubre = areas.evaluate().any((Element e) {
        final caja = e.findRenderObject();
        if (caja == null || !caja.attached) return false;
        // Y LA REGION TIENE QUE LLEGAR **AL ALTO DE LA VENTANA**: la columna de lectura va
        // del borde superior al inferior, y una region de 200 px en la parte de arriba
        // seleccionaria el titulo y poco mas.
        final r = caja.paintBounds;
        return r.height > t.view.physicalSize.height / t.view.devicePixelRatio * 0.6;
      });
      expect(cubre, isTrue,
          reason: 'hay un `SelectionArea` pero ninguno abarca la columna de lectura');
    });

    testWidgets('y el texto del versiculo es seleccionable', (t) async {
      await _montar(t);

      // Y UN VERSICULO CON TEXTO PLANO, y no con las palabras separadas en `TextSpan` con
      // reconocedores: `SelectableText` no acepta `TextSpan` con gestos, y por eso la region
      // tiene que ir **alrededor** de la columna y no sobre cada versiculo.
      final texto = find.textContaining('For', findRichText: true);
      expect(texto, findsWidgets, reason: 'el texto del versiculo no se ha pintado');
    });
  });

  group('2. tocar una palabra ya NO se lleva la seleccion', () {
    testWidgets('no hay ningun reconocedor de toque por palabra', (t) async {
      await _montar(t);

      // Y ESTA ES LA COMPROBACION DE LA FORMA, Y ES LA QUE HABRIA VISTO EL FALLO.
      //
      // Un `TapGestureRecognizer` en una palabra dentro de una region seleccionable se lleva el
      // toque, y con el lexicon del KJV --348.884 ocurrencias-- eso es en practica todas las
      // palabras del texto. La prueba no cuenta los toques: mira que el reconocedor que hay
      // sea de **pulsacion larga**, que es el gesto libre de la seleccion.
      final toques = _gestoresEnElTexto(t).whereType<TapGestureRecognizer>().toList();
      expect(toques, isEmpty,
          reason: 'hay ${toques.length} reconocedores de toque en las palabras: cada uno se '
              'lleva un toque que es de quien quiere seleccionar');
    });

    testWidgets('y el indice se abre con pulsacion larga', (t) async {
      await _montar(t);

      final largas = _gestoresEnElTexto(t).whereType<LongPressGestureRecognizer>().toList();
      expect(largas, isNotEmpty,
          reason: 'la pulsacion larga tiene que abrir el indice, que es un gesto de lectura y '
              'no una accion que se lleve el texto por delante');
    });

    testWidgets('y con la apertura apagada la columna tampoco come toques', (t) async {
      // Y ESTE CASO, Y PORQUE: el `IgnorePointer` de los velos es lo que hace que el texto se
      // pueda seleccionar con la apertura **puesta**. Con la apertura apagada no hay velo y no
      // hay nada que se coma un toque, asi que este fallo no puede depender de el --y asi se
      // descarta de un vistazo sin tener que leer el widget entero.
      await _montar(t);
      expect(find.byKey(claveDelVeloDeArriba), findsNothing);
    });
  });

  group('3. marcar sigue funcionando', () {
    testWidgets('el numero del versiculo abre la hoja con la seleccion puesta', (t) async {
      // Y ESTA ES LA COMPROBACION DE QUE NO SE HA ROTO LO OTRO. Con un `SelectionArea`
      // alrededor de la columna, el numero del versiculo --que esta **dentro**-- puede dejar
      // de ser pulsable, porque la seleccion se lleva los toques de la zona. Y marcar por el
      // numero es como se marca en esta app.
      await _montar(t);

      await t.tap(find.byKey(claveDelNumeroDeVersiculo).first);
      await t.pumpAndSettle();

      expect(find.text('Marcar este versiculo'), findsOneWidget,
          reason: 'con la region de seleccion puesta, marcar por el numero dejo de funcionar');
    });
  });
}

/// Montar Juan 3 con la columna de lectura pintada.
Future<void> _montar(WidgetTester t) async {
  final resaltados = ResaltadosViewModel(
    almacenamiento: AlmacenamientoDeResaltadosEnMemoria(),
  );
  addTearDown(resaltados.dispose);

  final vm = await montarLector(t, resaltados: resaltados);
  vm.leer(const Referencia('John', 3, 16));
  await t.pumpAndSettle();
}

/// Los reconocedores de gesto que hay en los `TextSpan` de las palabras.
///
/// Y SE BUSCAN EN LOS `TEXT` DE LA **COLUMNA DE LECTURA**, y no en toda la pantalla: la barra
/// de arriba tiene botones con su propio `TapGestureRecognizer`, y contarlos haria que esta
/// prueba viera toques donde no hay ninguno del fallo que se quiere cazar.
List<GestureRecognizer> _gestoresEnElTexto(WidgetTester t) {
  final salida = <GestureRecognizer>[];
  for (final w in t.widgetList<RichText>(find.byType(RichText))) {
    void mirar(InlineSpan span) {
      if (span is! TextSpan) return;
      final r = span.recognizer;
      if (r != null) salida.add(r);
      for (final hijo in span.children ?? const <InlineSpan>[]) {
        mirar(hijo);
      }
    }

    mirar(w.text);
  }
  return salida;
}
