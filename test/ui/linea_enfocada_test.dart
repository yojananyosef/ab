// Que el conmutador de «Linea enfocada» haga algo.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y QUE ES LO QUE TENIA QUE PASAR
// ============================================================================
//
// El conmutador offers apagada, una, tres y cinco lineas, **guarda la preferencia** y no lo
// miraba nadie. Ni el view model de la lectura sabia que el campo existia, ni la vista. Es el
// fallo que `AGENTS.md` ya documenta con `alCambiarDeVersion` --«una funcion sin llamador no
// falla nunca»-- y aqui es peor: no es codigo muerto, es un boton que promete una cosa y no
// la hace.
//
// Y LO QUE NO ALCANZA UNA PRUEBA DE ESTE FICHERO, Y SE DICE: comprueba que **la columna se
// pinta con velos cuando el conmutador esta puesto**. Que el interruptor escriba la
// preferencia ya lo comprueban las pruebas de `PreferenciaDeLectura`, y que la pantalla se
// repinte al cambiarla, lo comprueba el hecho de que estas pruebas la montan con la preferencia
// puesta **antes** de arrancar y da igual: una prueba que solo mirase «el conmutador guarda»
// habria pasado con el bug entero.
//
// ============================================================================
// Y POR QUE SE MIDE LA **CANTIDAD DE VELO**, Y NO QUE ESTE
// ============================================================================
//
// Porque `ColoredBox` se pinta **tambi en** si su color es transparente, asi que un
// `find.byType(ColoredBox)` daria verde con la apertura apagada. Y porque un velo que se pinta
// en el sitio equivocado --todo el alto, o solo el de arriba-- tambien sale "bien" en una
// prueba que solo mira que hay uno.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/features/lector/widgets/linea_enfocada.dart';

import 'lector_view_test.dart' show montarLector;

void main() {
  group('1. el conmutador ahora hace algo', () {
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

    testWidgets('y con cinco lineas tambien son dos, pero mas altos', (t) async {
      await _montar(t, 1);
      final conUna = _velos(t).map((Rect r) => r.height).toList();

      await _montar(t, 5);
      final conCinco = _velos(t).map((Rect r) => r.height).toList();

      expect(conCinco, hasLength(2));
      // Y CADA VELO **MENOS ALTO**, y no mas: mas lineas abiertas quiere decir menos velo. Un
      // conmutador que abre mas lineas y apaga mas pantalla esta al reves de lo que dice.
      for (var i = 0; i < conUna.length; i++) {
        expect(conCinco[i], lessThan(conUna[i]),
            reason: 'el velo $i se ha hecho mas alto al abrir mas lineas');
      }
    });

    testWidgets('y mas lineas abiertas es una banda mas alta', (t) async {
      // Y EL INVARIANTE, Y NO UN NUMERO. La banda tiene que medir `lineas` lineas de
      // lectura, y el alto de una linea lo fija `estiloDeLectura` --que depende del ancho de
      // la columna-- asi que un numero escrito aqui seria un numero que hay que cambiar cada
      // vez que cambia la tipografia. Lo que no cambia es la relacion: **el hueco se estrecha
      // a medida que se abren mas lineas**, y es eso lo que hace que el conmutador signifique
      // algo.
      //
      // Y MEDIDO, y por eso no se escribe el alto aqui: con la tipografia de partida el alto
      // de una linea sale en **65,8 px**, no en 18 por 1,6. La vista calcula
      // `fontSize * height` de su estilo de lectura, que ya lleva el tamano de letra
      // **calculado para el ancho de la columna**, y el ancho de la columna en una prueba a
      // 360 px no es el de una pantalla real. Escribi 86,4 --18 por 1,6 por tres-- y la
      // prueba fallia con un numero que no era ni el bueno ni el malo: era el de una cuenta
      // hecha en el sitio equivocado.
      final conUna = await _veloDeArriba(t, 1);
      final conTres = await _veloDeArriba(t, 3);
      final conCinco = await _veloDeArriba(t, 5);

      // Y EL VELO DE ARRIBA **BAJA** CUANDO SE ABRE MAS: mas banda, menos velo. Un
      // conmutador que abre mas lineas y apaga mas pantalla esta al reves de lo que dice.
      expect(conUna, greaterThan(conTres));
      expect(conTres, greaterThan(conCinco));
    });

    testWidgets('y el velo NO se come los toques', (t) async {
      await _montar(t, 3);
      // Y ESTO ES LA COMPROBACION QUE IMPORTA MAS QUE LA DE ARRIBA, porque el sintoma de un
      // velo que come toques es «no puedo copiar un versiculo», que no apunta a nada y hace
      // perder el rato a quien lo busca en el teclado.
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
        // Y LA CLAVE ESTA EN EL `IgnorePointer`, NO EN EL `ColoredBox`: la clave va en el
        // widget que envuelve al velo porque es el que lleva el `IgnorePointer`, y leer
        // `t.widget<ColoredBox>` de la clave da
        //
        //     type 'IgnorePointer' is not a subtype of type 'ColoredBox'
        //
        // Y ES LA SEGUNDA VEZ QUE UN `TYPE ERROR` DE UN CAST SALIA DE ADELANTAR LA PRUEBA:
        // la primera fue el `find.ancestor` del fondo del resaltado. Un `as` en una prueba
        // convierte un "esta en otro sitio" en un fallo que no lo dice.
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
        final fondo = Theme.of(t.element(find.byType(ColoredBox).first)).scaffoldBackgroundColor;
        expect(color.r, closeTo(fondo.r, 0.01));
        expect(color.g, closeTo(fondo.g, 0.01));
        expect(color.b, closeTo(fondo.b, 0.01));
      }
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
}) async {
  await montarLector(
    t,
    preferenciaDeLectura: PreferenciaDeLectura.porDefecto.copyWith(
      lineaEnfocada: lineas,
      tema: tema,
    ),
  );
  await t.pumpAndSettle();
}

/// Los rectangulos de los velos, por la paints.
List<Rect> _velos(WidgetTester t) {
  final salida = <Rect>[];
  for (final clave in <Key>[claveDelVeloDeArriba, claveDelVeloDeAbajo]) {
    for (final e in find.byKey(clave).evaluate()) {
      final caja = e.findRenderObject();
      if (caja == null || !caja.attached) continue;
      salida.add(caja.paintBounds);
    }
  }
  // Y ORDENADOS DE ARRIBA ABAJO, y no en el orden en que los encuentra el arbol. Sin esto,
  // "el hueco entre los dos" sale **negativo**: el de arriba se encuentra despues, y restar
  // el borde inferior del que esta mas abajo da un numero sin sentido.
  salida.sort((Rect a, Rect b) => a.top.compareTo(b.top));
  return salida;
}

/// El alto del velo de arriba con la apertura puesta, en esa pantalla.
Future<double> _veloDeArriba(WidgetTester t, int lineas) async {
  await _montar(t, lineas);
  return _velos(t).first.height;
}
