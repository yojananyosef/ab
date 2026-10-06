// El marco de la pantalla de estudio.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y QUE COMPRUEBA
// ============================================================================
//
// Porque el marco es lo primero que se ha construido **copiando una captura** en vez de
// contando pixeles, y la diferencia se nota en lo que hay que comprobar:
//
//   - El corte de ancho, 1100 px, que es una decision medida y no un gusto. Sin una
//     prueba a 1099 y a 1100, "cambia de panel a barra" es una frase en un comentario.
//   - Que los cinco destinos **llevan a algo**, porque en Logos los nueve llevan a un
//     producto y un destino que no lleva a ninguna parte es peor que uno que no existe.
//   - Que el panel lateral **no se come** la columna de lectura, que es el fallo que el
//     propio `docs/investigacion-ux.md` le atribuye a Bible Gateway.
//
// Y LO QUE NO SE COMPRUEBA AQUI, Y POR QUE. Que a 360 px las cinco cosas que se ven en la
// captura responsive de Logos estan en la barra de abajo: se comprueba en
// `cabecera_de_lectura_test`, porque alli esta el campo y los dos compiten por el ancho.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/widgets/marco_de_estudio.dart';

void main() {
  // Y CON UN HIJO QUE SE PUEDA MEDIR, porque el marco no hace nada con el: lo envuelve.
  // Y porque hay que comprobar que no le quita ancho, y eso se mide por el hijo.
  Future<void> pintar(
    WidgetTester t, {
    required double ancho,
    void Function(DestinoDeEstudio destino, BuildContext contexto)? alElegir,
  }) async {
    t.view.physicalSize = Size(ancho, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MaterialApp(
        theme: temaDeAb(),
        home: Scaffold(
          body: MarcoDeEstudio(
            destino: DestinoDeEstudio.biblia,
            alElegirDestino: alElegir ?? (_, _) {},
            hijo: const _HijoQueSeMide(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  group('1. el corte de ancho, que es una medida', () {
    testWidgets('a 1440 hay panel lateral con los nombres', (t) async {
      await pintar(t, ancho: 1440);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(t.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
      expect(find.byType(NavigationRail).evaluate().length, 1);
    });

    testWidgets('a 834 NO hay panel, hay barra de abajo', (t) async {
      // Y 834, QUE ES LA CAPTURA RESPONSIVE DE LOGOS. Ahi no hay panel lateral: hay una barra
      // de iconos abajo. Poner un panel de 176 px en una tableta de 834 se comia el 21 % de
      // la pantalla para decir cinco nombres.
      await pintar(t, ancho: 834);

      expect(find.byType(NavigationRail), findsNothing);
      expect(_botonesDeLaBarra(t), 5);
    });

    testWidgets('el corte esta en 1100, y a cada lado pasa algo', (t) async {
      // Y LOS DOS LADOS, porque un corte que solo se comprueba a un lado no es un corte: es
      // un numero escrito en un comentario. Este es el unico ancho que decide.
      await pintar(t, ancho: Medidas.anchoParaPanelDeHerramientas - 1);
      expect(find.byType(NavigationRail), findsNothing,
          reason: 'un pixel por debajo ya no hay panel');

      await pintar(t, ancho: Medidas.anchoParaPanelDeHerramientas);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('el corte no depende de la altura', (t) async {
      // Y A 1100 DE ANCHO PERO EN UN PORTATIL DE 700 DE ALTO. Si el corte mirara la
      // diagonale --que es lo que hacen algunas reglas responsive-- una tableta en vertical
      // perderia el panel. El panel ocupa 176 px de ancho y todo el alto; lo que importa es
      // el ancho.
      t.view.physicalSize = const Size(1200, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: MarcoDeEstudio(
              destino: DestinoDeEstudio.biblia,
              alElegirDestino: (_, _) {},
              hijo: const _HijoQueSeMide(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('2. los cinco destinos, y que los cinco llevan a algo', () {
    testWidgets('son cinco, y son los que existen', (t) async {
      await pintar(t, ancho: 834);

      final nombres = _botonesDeLaBarraNombres(t);
      expect(nombres, <String>[
        'Biblia',
        'Buscar',
        'Léxico',
        'Comentarios',
        'Biblioteca',
      ]);
    });

    testWidgets('no hay entradas de adorno', (t) async {
      // Y LA COMPROBACION DE QUE NO SE HA COPIADO LA LISTA ENTERA DE LOGOS. Logos tiene
      // nueve, y aqui no hay tienda ni entrenos --que ademas serian cosas que este proyecto
      // no puede tener-- ni "Asistente de estudio", "Enciclopedia biblica", "Guias de Estudio"
      // ni "Herramientas", que **no tienen nada detras**.
      //
      // Un destino que no lleva a ninguna parte es peor que un destino que no existe,
      // porque ensena a usar la aplicacion con una promesa que no se puede cumplir.
      await pintar(t, ancho: 834);

      final nombres = _botonesDeLaBarraNombres(t).join(' ');
      for (final prohibido in <String>[
        'Tienda',
        'Entrenos',
        'Asistente',
        'Enciclopedia',
        'Guas',
        'Herramientas',
        'Panel de Control',
      ]) {
        expect(nombres.contains(prohibido), isFalse,
            reason: '"$prohibido" no lleva a nada aqui');
      }
    });

    testWidgets('pulsar un destino lo avisa, y avisa el que es', (t) async {
      // Y CADA UNO POR SEPARADO, porque un `onDestinationSelected` que siempre devuelve el
      // primero pasa estas cinco pruebas igual.
      final vistos = <DestinoDeEstudio>[];
      await pintar(t, ancho: 834, alElegir: (d, _) => vistos.add(d));

      for (final d in DestinoDeEstudio.values) {
        await t.tap(find.byTooltip(d.rotulo));
        await t.pumpAndSettle();
      }

      expect(vistos, DestinoDeEstudio.values);
    });

    testWidgets('los destinos tienen icono TODOS, no solo el elegido', (t) async {
      // Y PORQUE UN DESTINO SIN ICONO EN UN DISPOSITIVO SIN PANTALLA ES UN BOTON SIN
      // NOMBRE. En la barra de abajo el icono **es** el nombre; el texto solo sale en el
      // tooltip, que en un movil sale si se deja el dedo quieto, y eso casi nadie lo hace.
      await pintar(t, ancho: 834);

      for (final d in DestinoDeEstudio.values) {
        expect(find.byTooltip(d.rotulo), findsOneWidget, reason: d.rotulo);
        expect(
          find.descendant(
            of: find.byTooltip(d.rotulo),
            matching: find.byType(Icon),
          ),
          findsOneWidget,
          reason: '${d.rotulo} tiene que tener icono, no solo un texto invisible',
        );
      }
    });
  });

  group('3. el panel no se come el texto', () {
    testWidgets('a 1440 el hijo se queda con lo que el panel no ocupa', (t) async {
      await pintar(t, ancho: 1440);

      // Y LA RELACION, Y NO UN NUMERO FIJO.
      //
      // Lo primero que se puso fue `minExtendedWidth: 176` y se dio por hecho de que el
      // panel mediria 176. **Mide 226,5**: `minExtendedWidth` es un minimo, y el
      // `NavigationRail` se ensancha hasta que quepa la etiqueta mas larga, que es
      // "Comentarios". Con 176 el nombre se recortaria, y un destino con el nombre cortado
      // es un destino que no se sabe que es.
      //
      // Lo que se comprueba es que el hijo recibe **exactamente** lo que sobra, que es la
      // propiedad que importa: si el panel se ensancha un dia, el texto se estrecha y esta
      // comprobacion se entera.
      final panel = t.getSize(find.byType(NavigationRail)).width;
      final separador = t.getSize(find.byType(VerticalDivider)).width;

      expect(panel, greaterThan(176),
          reason: 'y el minimo es un minimo: la etiqueta mas larga manda');
      expect(
        t.getSize(find.byType(_HijoQueSeMide)).width,
        1440 - panel - separador,
        reason: 'el texto se queda con todo lo que el panel no ocupa',
      );
    });

    testWidgets('a 834, sin panel, el hijo lo tiene todo', (t) async {
      await pintar(t, ancho: 834);
      expect(t.getSize(find.byType(_HijoQueSeMide)).width, 834);
    });

    testWidgets('el hijo se estira en vertical', (t) async {
      // Y QUE OCUPA EL ALTO. Un marco que dejara un hueco abajo --por ejemplo, la barra
      // contando dos veces-- se veria como una franja vacia entre el texto y el borde, y es
      // un fallo que solo aparece en una imagen.
      await pintar(t, ancho: 1440);

      final alto = t.getSize(find.byType(_HijoQueSeMide)).height;
      expect(alto, greaterThan(800), reason: 'la pantalla es de 900 de alto');
    });

    testWidgets('nada se sale por el borde', (t) async {
      // Y A LOS TRES ANCHOS QUE IMPORTAN: un movil pequeno, una tableta y un escritorio.
      // Un marco que funciona a 1440 y se pasa a 320 no esta terminado.
      for (final ancho in <double>[320, 834, 1440]) {
        await pintar(t, ancho: ancho);
        expect(t.takeException(), isNull, reason: 'a $ancho px');
      }
    });
  });

  group('4. sin marco, una pantalla sola', () {
    testWidgets('AnchoDeEstudio.of no revienta sin marco', (t) async {
      // Y PORQUE ES UN `InheritedWidget` Y NO UN PARAMETRO, HAY QUE PODER PREGUNTAR CUANDO
      // NO HAY. Hay montajes --las pruebas de la pantalla de lectura-- que no tienen marco,
      // y `dependOnInheritedWidgetOfExactType` devuelve null. Si eso se tratara como un
      // error, habria que pasar el ancho a mano a todas las pantallas y a sus subpantallas,
      // y el que se olvidara lo veria solo en la pantalla que se olvido.
      AnchoDeEstudio? leido;
      await t.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Builder(
            builder: (BuildContext c) {
              leido = AnchoDeEstudio.of(c);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(leido, isNotNull);
      expect(leido!.hayPanelDeHerramientas, isFalse,
          reason: 'sin marco se supone la situacion mas estrecha, que es la que menos quita');
    });
  });
}

/// Un hijo cualquiera, con una marca para poder medirlo.
class _HijoQueSeMide extends StatelessWidget {
  const _HijoQueSeMide();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Los `IconButton` que son un destino, y solo esos.
///
/// Y SE FILTRAN POR EL **TOOLTIP**, y no se coge "los `IconButton` de pantalla". Un
/// `IconButton` se identifica por lo que abre, que aqui esta escrito en el `tooltip` --en la
/// barra de abajo el icono **es** el nombre—. Y sin el filtro, la pantalla de lectura, que
/// tiene cuatro botones mas, haria que estas cuentas salieran con numeros que no son de este
/// marco.
///
/// Y NO HAY UN `find.byType` PARA LA BARRA, porque la barra no es un widget de Material: es
/// una `Material` con un borde y una `Row`. La primera version de esta comprobacion busco
/// un `NavigationBar` --que es la barra de pestanas de Material 3, que no es lo que hay— y
/// daria "0 widgets", que se lee como "no hay barra" y significa "no se encontro".
List<IconButton> _botonesDeDestino(WidgetTester t) => t
    .widgetList<IconButton>(find.byType(IconButton))
    .where((IconButton b) => b.tooltip != null &&
        DestinoDeEstudio.values.any((DestinoDeEstudio d) => d.rotulo == b.tooltip))
    .toList();

/// Cuantos hay.
int _botonesDeLaBarra(WidgetTester t) => _botonesDeDestino(t).length;

/// Sus nombres, que estan en el `tooltip`.
List<String> _botonesDeLaBarraNombres(WidgetTester t) =>
    _botonesDeDestino(t).map((IconButton b) => b.tooltip!).toList();