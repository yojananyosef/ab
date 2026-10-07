// La apertura sobre la linea que se esta leyendo.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y QUE ERA EL FALLO
// ============================================================================
//
// El conmutador de «Linea enfocada» ofrece apagada, una, tres y cinco lineas, **guarda la
// preferencia** y no lo miraba nadie. Ni el view model de la lectura sabia que el campo
// existia, ni la vista. Es el fallo que `AGENTS.md` ya documenta con `alCambiarDeVersion`
// --«una funcion sin llamador nunca falla»-- y aqui es peor: no es codigo muerto, es un boton
// que promete una cosa y no la hace.
//
// Y DESPUES HA SALIDO EL SEGUNDO FALLO, QUE ESTA EN ESTE MISMO FICHERO Y NO EN EL DE ARRIBA:
// la banda se quedaba **fija arriba** sin moverse. Y no era que no siguiera al scroll, que es
// lo que parecera leyendo el sintoma --esta en la seccion 3--.
//
// ============================================================================
// Y LO QUE NO ALCANZA UNA PRUEBA DE ESTE FICHERO, Y SE DICE
// ============================================================================
//
// Comprueba que **la columna se pinta con velos cuando el conmutador esta puesto**, y que la
// banda no se sale de la columna. Que el interruptor escriba la preferencia ya lo comprueban
// las pruebas de `PreferenciaDeLectura`.
//
// Y QUE NO SE COMPRUEBA, Y ES LO UNICO QUE FALTARIA: que la banda **siga al scroll**. La banda
// esta fijada al centro vertical de la columna con dos velos, y mientras el texto se mueve por
// debajo la apertura se queda donde esta. Que eso sea lo correcto o no --«la linea que se esta
// leyendo» pide que siga al texto, y una ventana fija no es una linea-- esta escrito como
// pendiente en `openspec/changes/la-linea-que-se-esta-leyendo/tasks.md`, 6.1, y no se finge
// aqui que este resuelto.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/features/lector/widgets/linea_enfocada.dart';

import 'lector_view_test.dart' show montarLector;

void main() {
  group('1. el conmutador hace algo', () {
    testWidgets('con la apertura apagada NO hay velo ninguno', (t) async {
      await _montar(t, 0);
      expect(_velos(t), isEmpty);
    });

    testWidgets('con una linea hay **dos** velos, arriba y abajo', (t) async {
      await _montar(t, 1);
      // Y DOS, Y NO UNO. Un solo velo con un hueco obliga a un `Path` con un recorte, y el
      // recorte se ve mal en cuanto el alto de la columna no es multiplo del de linea: el
      // borde sale a medio pixel y se ensena una linea gris que no esta en el texto.
      expect(_velos(t), hasLength(2));
    });

    testWidgets('y con cinco lineas tambien son dos', (t) async {
      await _montar(t, 5);
      expect(_velos(t), hasLength(2));
    });

    testWidgets('y mas lineas abiertas es una banda mas alta', (t) async {
      // Y EL INVARIANTE, Y NO UN NUMERO. La banda tiene que medir `lineas` lineas de lectura,
      // y el alto de una linea lo fija `estiloDeLectura` --que calcula el tamano para el
      // ancho de la columna--, asi que un numero aqui seria un numero que hay que cambiar cada
      // vez que cambia la tipografia.
      //
      // Y MEDIDO, y por eso no se escribe el alto: con la tipografia de partida el alto de una
      // linea sale en **65,8 px**, no en 18 por 1,6. Escribi 86,4 --18 por 1,6 por tres-- y la
      // prueba fallaba con un numero que no era ni el bueno ni el malo: era el de una cuenta
      // hecha en el sitio equivocado.
      final conUna = await _veloDeArriba(t, 1);
      final conTres = await _veloDeArriba(t, 3);
      final conCinco = await _veloDeArriba(t, 5);

      // Y EL VELO DE ARRIBA **BAJA** CUANDO SE ABRE MAS: mas banda, menos velo. Un conmutador
      // que abre mas lineas y apaga mas pantalla esta al reves de lo que dice.
      expect(conUna, greaterThan(conTres));
      expect(conTres, greaterThan(conCinco));
    });

    testWidgets('y el velo NO se come los toques', (t) async {
      // Y ESTO IMPORTA MAS QUE LA DE ARRIBA, porque el sintoma de un velo que come toques es
      // «no puedo copiar un versiculo», que no apunta a nada y hace perder el rato a quien lo
      // busca en el teclado.
      await _montar(t, 3);
      final conIgnore = t
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((IgnorePointer w) => w.child is ColoredBox)
          .length;
      expect(conIgnore, greaterThanOrEqualTo(2),
          reason: 'los velos estan encima de la columna y sin `IgnorePointer` se comen la '
              'seleccion del texto');
    });

    testWidgets('y la apertura apagada NO es una linea', (t) async {
      // Y EL CERO, que es una distincion que hay que hacer en el widget y no en la hoja: con
      // `lineas` de 0, una banda de alto **cero** es la columna entera velada, que es leer a
      // oscuras. Apagado tiene que ser "no hay velo".
      await _montar(t, 0);
      expect(_velos(t), isEmpty);
    });
  });

  group('2. el velo es del color del fondo, y no un gris', () {
    testWidgets('en el claro y en el oscuro el color es el del fondo', (t) async {
      // Y PORQUE MEDIRLO: un gris encima de un crema se ve como una mancha, y encima de un
      // fondo casi negro se ve como niebla. Lo que tiene que pasar es que el velo sea del
      // color del fondo, con lo que lo que se atenua es la luz que llega del fondo y el texto
      // se queda con su contraste de siempre.
      for (final tema in TemaDeLectura.values) {
        await _montar(t, 3, tema: tema);

        // Y LA CLAVE ESTA EN EL `IgnorePointer`, NO EN EL `ColoredBox`, y mirar la clave
        // esperando un `ColoredBox` da
        //
        //     type 'IgnorePointer' is not a subtype of type 'ColoredBox'
        //
        // que es la segunda vez que un `TYPE ERROR` de un cast sale de **adelantar** la
        // prueba, despues del `find.ancestor` del fondo del resaltado. Un `as` convierte un
        // "esta en otro sitio" en un fallo que no lo dice.
        final color = t
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byKey(claveDelVeloDeArriba),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color;

        final fondo = Theme.of(t.element(find.byKey(claveDelVeloDeArriba))).scaffoldBackgroundColor;
        expect(color.r, closeTo(fondo.r, 0.01));
        expect(color.g, closeTo(fondo.g, 0.01));
        expect(color.b, closeTo(fondo.b, 0.01));
      }
    });
  });

  group('3. la banda NO se queda pegada arriba', () {
    testWidgets('con una columna mas baja que la banda, no se sale', (t) async {
      // MEDIDO Y REPRODUCIDO EL 6 DE OCTUBRE DE 2026: quien probo el conmutador vio la banda
      // **fija arriba y sin hacer nada** por mas que se moviera el texto. Y no era que no
      // siguiera al scroll, que es lo que parecere leyendo el sintoma: con cinco lineas
      // pedidas y una columna baja la banda sale **mas alta que la columna**, y entonces
      //
      //     porArriba = (alto - banda) / 2      ->  un numero **negativo**
      //     .clamp(0.0, ...)                      ->  0
      //
      // y los dos velos miden cero: la apertura **desaparece** en vez de abrirse, y con los
      // dos a cero no queda nada visible que se pueda mover.
      //
      // Y POR QUE NO SE ACOTA EL NUMERO DE LINEAS, QUE SERIA LO FACIL: porque el conmutador
      // dice cinco lineas y tiene que abrir cinco. Recortar a las que caben seria volver a
      // mentir sobre lo que el boton dice, que es el fallo que este change vino a arreglar.
      await _montar(t, 5);

      // Y LA COLUMNA SE MIDE **DE LA PANTALLA** Y NO DE LA VENTANA. Escribi «60 px» pensando
      // en la columna y lo que cambie fue la ventana, y a 60 px de ventana lo que se mide es
      // una ventana diminuta: los velos dieron 385 sobre 60 y la prueba_failaba con un numero
      // que no era ni el bueno ni el malo, que es el peor sitio para estar.
      final columna = t.getRect(find.byKey(claveDeLaColumnaEnfocada));
      final velos = _velos(t);
      final suma = velos.map((Rect r) => r.height).fold<double>(0, (double a, double b) => a + b);

      expect(velos, hasLength(2),
          reason: 'siguen siendo dos velos: lo que se acota es la banda, no el numero');
      expect(suma, lessThanOrEqualTo(columna.bottom - columna.top),
          reason: 'los dos velos juntos miden $suma y la columna mide '
              '${(columna.bottom - columna.top).toStringAsFixed(1)}: se han salido, y la banda '
              'se ha ido con ellos');
    });

    testWidgets('y los dos velos se reparten la columna', (t) async {
      await _montar(t, 5);
      final velos = _velos(t);
      expect(velos.first.height, closeTo(velos.last.height, 0.5),
          reason: 'con la banda acotada a la columna no queda velo: los dos se reparten lo '
              'que sobra, y si no se reparten hay uno pegado al borde');
    });
  });
}

/// Montar la lectura con la apertura puesta **antes** de arrancar.
///
/// Y NO DESPUES, y es lo que hace que la prueba sirva: cambiar la preferencia con la pantalla
/// viva necesita que la vista se repinte, y si no se repinta la prueba pasa con un velo que no
/// esta. Ponerla antes y arrancar ya es la situacion que se quiere comprobar.
Future<void> _montar(
  WidgetTester t,
  int lineas, {
  TemaDeLectura tema = TemaDeLectura.claro,
  double? altoDeLaColumna,
}) async {
  t.view.physicalSize = Size(360, altoDeLaColumna ?? 640);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);

  await montarLector(
    t,
    preferenciaDeLectura: PreferenciaDeLectura.porDefecto.copyWith(
      lineaEnfocada: lineas,
      tema: tema,
    ),
  );
  await t.pumpAndSettle();
}

/// Los rectangulos de los velos, ordenados de arriba abajo.
///
/// Y ORDENADOS, y no en el orden en que los encuentra el arbol: sin esto, "el hueco entre los
/// dos" sale **negativo**, porque el de arriba se encuentra despues y restar el borde inferior
/// del que esta mas abajo da un numero sin sentido.
List<Rect> _velos(WidgetTester t) {
  final salida = <Rect>[];
  for (final clave in <Key>[claveDelVeloDeArriba, claveDelVeloDeAbajo]) {
    for (final e in find.byKey(clave).evaluate()) {
      final caja = e.findRenderObject();
      if (caja == null || !caja.attached) continue;
      salida.add(caja.paintBounds);
    }
  }
  salida.sort((Rect a, Rect b) => a.top.compareTo(b.top));
  return salida;
}

/// El alto del velo de arriba con la apertura puesta, en esa pantalla.
Future<double> _veloDeArriba(WidgetTester t, int lineas) async {
  await _montar(t, lineas);
  return _velos(t).first.height;
}
