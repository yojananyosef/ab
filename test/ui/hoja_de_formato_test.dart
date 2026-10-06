// La hoja de formato y el velo de atenuacion.
//
// ============================================================================
// POR QUE SE COMPRUEBAN CON MEDIDAS Y NO CON "HA SALIDO"
// ============================================================================
//
// Los dos fallos de esta hoja **no son excepciones**:
//
//   - el deslizador del tamano de letra que **no mueve** la muestra: se ve la hoja, se ve el
//     numero, y el texto de ejemplo sale con el tamano viejo. Ningun `expect` de "no hay
//     excepcion" lo ve
//   - el velo de atenuacion que **tapa el boton de restaurar**: la hoja se abre, el boton
//     existe en el arbol, y no se puede pulsar. Un `findsOneWidget` lo encuentra
//
// Por eso lo que se mide es el **tamano del texto pintado** y la **posicion del boton**, y
// no la existencia de widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_formato.dart';
import 'package:ab/ui/features/lector/widgets/velo_de_atenuacion.dart';

/// El texto de la vista previa, para poder medirle la fuente.
const muestra = 'En el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios.';

/// Abre la hoja y la baja hasta que [objetivo] esta en pantalla.
///
/// Y POR QUE NO UN `findsOneWidget` A SECO: la hoja es un `ListView` perezoso, y lo que no
/// cabe **no esta construido**. Pedir que un control por debajo del pliegue este en el arbol
/// es pedir que la hoja tenga todo en pantalla, que no cabe en un movil, y el fallo que sale
/// dice "0 widgets" como si el control no existiera.
///
/// Y NO ES UN DETALLE DE PRUEBA: es como se comporta la hoja de verdad, y una prueba que
/// midiese "hay un boton" en una hoja que **construye** todo mediria una hoja que no existe.
Future<void> bajarHasta(WidgetTester t, Finder objetivo) async {
  await t.dragUntilVisible(objetivo, find.byType(ListView).last, const Offset(0, -200));
  await t.pumpAndSettle();
}

void main() {
  group('1. la hoja se abre y se ve entera', () {
    testWidgets('los tres deslizadores y el boton de restaurar', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => abrirHojaDeFormato(
                  contexto,
                  preferencia: PreferenciaDeLectura.porDefecto,
                  alCambiar: (_) {},
                  alRestaurar: () {},
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));

      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();

      expect(find.text('Formato de lectura'), findsOneWidget);
      expect(find.text('Tamano de letra'), findsOneWidget);
      expect(find.text('Alto de linea'), findsOneWidget);
      expect(find.text('Espaciado entre letras'), findsOneWidget);
      expect(find.text('Fondo'), findsOneWidget);

      // Y LOS DEL FINAL SE BUSCAN **DESPLAZANDOSE**, y no con `findsOneWidget`. La hoja es
      // un `ListView`, y lo que no cabe en pantalla **no esta construido**: el "Linea
      // enfocada" y el boton de restaurar estan por debajo del pliegue en un movil, y pedir
      // que estan en el arbol sin desplazarse es pedir que la hoja tenga todo en pantalla, que
      // no cabe. Un `ListView` perezoso no es un fallo: es lo que hace que una hoja con diez
      // controles no construya diez controladores de `Slider` para no enseñar ninguno.
      await bajarHasta(t, find.text('Linea enfocada'));
      expect(find.text('Linea enfocada'), findsOneWidget);

      await bajarHasta(t, find.widgetWithText(OutlinedButton, 'Restaurar valores'));
      expect(find.widgetWithText(OutlinedButton, 'Restaurar valores'), findsOneWidget);
    });

    testWidgets('a 320 px de ancho, en vertical, no se sale nada', (t) async {
      // Y A 320 Y EN VERTICAL, que es la combinacion de un telefono viejo en vertical y que
      // es donde el teclado mas se lleva sitio.
      t.view.physicalSize = const Size(320, 480);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (_) {},
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
    });

    testWidgets('con el teclado abierto el boton de restaurar NO se tapa', (t) async {
      // Y EL TECLADO, POR QUE ES LO UNICO QUE NO SE VE EN UNA CAPTURA. La hoja es un
      // `ListView` con tope del 85 % del alto: con el teclado abierto en un movil de 640 px
      // quedan unos 360 de alto util, y el boton del final queda por debajo de la pantalla y
      // hay que desplazarse hasta el. Que se vea **o no** importa mas de lo que parece: un
      // boton que hay que buscar es un boton que no se pulsa.
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            resizeToAvoidBottomInset: true,
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (_) {},
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();

      // Y SE COMPRUEBA QUE SE PUEDE LLEGAR AL BOTON, y no que esta: se le da hasta el final
      // y se mira si se puede pulsar.
      await bajarHasta(t, find.widgetWithText(OutlinedButton, 'Restaurar valores'));

      await t.tap(find.widgetWithText(OutlinedButton, 'Restaurar valores'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('2. los deslizadores MUEVEN la muestra', () {
    // Y ESTE ES EL MOTIVO DE QUE LA MUESTRA EXISTA. Sin ella, mover el deslizador cambia un
    // numero y no se ve nada mas, y el ajuste se hace a ojo con la cifra. Y es el fallo que
    // **no** se ve leyendo el codigo: la hoja funciona, los numeros cambian, el texto no se
    // mueve.
    Future<void> abrir(WidgetTester t) async {
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (_) {},
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
    }

    testWidgets('el tamano de letra cambia el texto de la muestra', (t) async {
      await abrir(t);

      // Y CON `!` EN EL `fontSize`, porque `TextStyle.fontSize` es `double?`. Sin el, el
      // `expect` recibe un `double?` donde quiere un `Object` y el fallo dice "el tipo
      // double? no se puede asignar a Object", que no es el problema: el problema es que el
      // tamano no estaba, y eso lo dira mejor el `expect` de abajo.
      final antes = t.widget<Text>(find.text(muestra)).style!.fontSize!;
      expect(antes, 18, reason: 'el valor por defecto');

      // Y SE MUEVE EL **PRIMER** `Slider`, que es el del tamano. Con tres en la hoja,
      // `find.byType(Slider).first` es el tamano porque es el primero en el `ListView`, y esa
      // es la razon de que el orden de dentro sea una regla comprobable.
      await t.drag(find.byType(Slider).first, const Offset(200, 0));
      await t.pumpAndSettle();

      final despues = t.widget<Text>(find.text(muestra)).style!.fontSize!;
      expect(despues, greaterThan(antes),
          reason: 'la muestra tiene que cambiar con el deslizador, no solo el numero');
    });

    testWidgets('el alto de linea cambia la altura de la muestra', (t) async {
      await abrir(t);

      final antes = t.getSize(find.text(muestra)).height;

      await t.drag(find.byType(Slider).at(1), const Offset(200, 0));
      await t.pumpAndSettle();

      final despues = t.getSize(find.text(muestra)).height;
      expect(despues, greaterThan(antes),
          reason: 'un alto de linea mayor tiene que ocupar mas alto');
    });

    testWidgets('el espaciado cambia el espaciado de la vista previa', (t) async {
      await abrir(t);

      // Y SE COMPRUEBA EL **ESTILO**, Y NO EL ANCHO DEL WIDGET. La primera version media
      // `getSize(find.text(muestra)).width`, y con el texto de ejemplo largo la caja ya esta
      // al ancho maximo y **no crece**: lo que cambia son los puntos de corte de linea, que
      // un ancho de widget no ve. La comprobacion pasaba sin comprobar nada.
      //
      // Y `letterSpacing` es `double?` en el `TextStyle`, y por eso el `!`.
      final antes = t.widget<Text>(find.text(muestra)).style!.letterSpacing!;

      await t.drag(find.byType(Slider).at(2), const Offset(200, 0));
      await t.pumpAndSettle();

      final despues = t.widget<Text>(find.text(muestra)).style!.letterSpacing!;
      expect(despues, greaterThan(antes),
          reason: 'espaciar las letras tiene que llegar al estilo de la vista previa');
    });

    testWidgets('los valores por defecto son los que dice el modelo', (t) async {
      await abrir(t);

      // Y LOS TRES NUMEROS DE PARTIDA, y en el orden que dice el modelo. El boton de
      // restaurar depende de que `porDefecto` sea lo que pone la hoja, y no de que la hoja
      // tenga sus numeros.
      expect(find.text('18 px'), findsOneWidget);
      expect(find.text('1.6'), findsOneWidget);
      expect(find.text('0.02 em'), findsOneWidget);
    });

    testWidgets('la atenuacion dice "sin atenuar" al maximo', (t) async {
      await abrir(t);

      // Y POR QUE HAY QUE DESPLAZARSE. El deslizador de la atenuacion esta por debajo del
      // pliegue en un movil de 800 de alto, con la vista previa y los tres deslizadores
      // encima. Un `findsOneWidget` sin desplazarse dira "0 widgets" y el fallo parecera que
      // el texto no existe, cuando lo que pasa es que aun no esta construido.
      await bajarHasta(t, find.text('sin atenuar'));

      // Y NO "100 %", porque "100 %" de atenuacion suena a que se atenua mucho y es
      // justo lo contrario. El texto tiene que decir lo que es.
      expect(find.text('sin atenuar'), findsOneWidget);
      expect(find.text('100 %'), findsNothing);
    });
  });

  group('3. elegir fondo', () {
    testWidgets('los tres fondos salen, con su nombre', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (_) {},
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();

      // Y ABAJO, PORQUE LOS TRES FONDOS ESTAN DEBAJO DEL PLIEGUE: la vista previa y los tres
      // deslizadores se llevan la primera pantalla entera.
      await bajarHasta(t, find.text('Oscuro'));

      for (final rotulo in <String>['Claro', 'Sepia', 'Oscuro']) {
        expect(find.text(rotulo), findsOneWidget, reason: rotulo);
      }
    });

    testWidgets('elegir uno avisa con ese, y no con el de partida', (t) async {
      // Y ESTE ES EL CAMINO COMPLETO: elegir un fondo **cambia el tema**, y no solo marca el
      // boton. Si el `alCambiar` no se llama, la tarjeta se marca y la pantalla no cambia, y
      // el que lo ha elegido ve un boton encendido y el mismo fondo.
      var recibido = PreferenciaDeLectura.porDefecto;

      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (PreferenciaDeLectura p) => recibido = p,
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await bajarHasta(t, find.text('Oscuro'));

      await t.tap(find.text('Oscuro'));
      await t.pumpAndSettle();

      expect(recibido.tema, TemaDeLectura.oscuro);
      // Y SOLO EL FONDO. Un cambio de fondo que se lleva el tamano puesto es el fallo de
      // "un `copyWith` que reescribe el objeto entero", y aqui se comprueba que no.
      expect(recibido.tamanoDeLetra, 18);
    });

    testWidgets('las tres muestras de fondo tienen el color de su paleta', (t) async {
      // Y QUE LA MUESTRA **ES** SU FONDO. Con un icono, hay que acordarse de como se llamaba;
      // con el fondo puesto, el que se elige es el que se ve.
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: PreferenciaDeLectura.porDefecto,
                alCambiar: (_) {},
                alRestaurar: () {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await bajarHasta(t, find.text('Oscuro'));

      // Y SE BUSCA POR EL **CONTENEDOR** que envuelve a cada rotulo, no por el `Text`: el
      // color esta en el `BoxDecoration` del contenedor y no en el texto.
      for (final (rotulo, tema) in <(String, TemaDeLectura)>[
        ('Claro', TemaDeLectura.claro),
        ('Sepia', TemaDeLectura.sepia),
        ('Oscuro', TemaDeLectura.oscuro),
      ]) {
        final contenedor = find.ancestor(
          of: find.text(rotulo),
          matching: find.byType(Container),
        );
        final decoracion = t
            .widget<Container>(contenedor.first)
            .decoration! as BoxDecoration;
        expect(decoracion.color, Colores.de(tema).fondo, reason: rotulo);
      }
    });
  });

  group('4. restaurar', () {
    testWidgets('un solo boton lo pone todo a los recomendados', (t) async {
      var recibido = const PreferenciaDeLectura(
        tamanoDeLetra: 24,
        altoDeLinea: 2.4,
        espaciado: 0.09,
        tema: TemaDeLectura.oscuro,
        atenuacion: 0.45,
      );

      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Builder(
          builder: (BuildContext contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirHojaDeFormato(
                contexto,
                preferencia: recibido,
                alCambiar: (PreferenciaDeLectura p) => recibido = p,
                alRestaurar: () => recibido = PreferenciaDeLectura.porDefecto,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();

      // Y ANTES DE PULSAR, LA HOJA MUESTRA **LO QUE HAY**, y no los recomendados. Una
      // hoja que abriera con los valores de partida en vez de con los guardados perderia la
      // preferencia entera en el momento de abrirla para mirar.
      expect(find.text('24 px'), findsOneWidget);

      // Y EL ESPACIADO SE COMPRUEBA **DESPLAZANDOSE**, porque el tercer deslizador esta
      // por debajo del pliegue: sin desplazarse, "0.09 em" da 0 widgets y el fallo parece
      // que la hoja no muestra el valor guardado.
      await bajarHasta(t, find.text('0.09 em'));
      expect(find.text('0.09 em'), findsOneWidget);

      await bajarHasta(t, find.widgetWithText(OutlinedButton, 'Restaurar valores'));
      await t.tap(find.widgetWithText(OutlinedButton, 'Restaurar valores'));
      await t.pumpAndSettle();

      expect(recibido.tamanoDeLetra, 18);
      expect(recibido.tema, TemaDeLectura.claro);
      expect(recibido.espaciado, closeTo(0.02, 0.0001));
    });
  });

  group('5. el velo de atenuacion', () {
    testWidgets('sin atenuar no pinta nada', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: ConVeloDeAtenuacion(
          atenuacion: 1,
          hijo: Scaffold(body: Text('hola')),
        ),
      ));

      // Y SE COMPRUEBA QUE **NO HAY CAJA DE COLOR**, y no que el widget `VeloDeAtenuacion` no
      // este en el arbol: el widget esta siempre --es quien decide si pinta--, y lo que no se
      // pinta cuando la atenuacion es 1 es su contenido. Preguntar por el widget daria "en
      //controlo" cuando lo que se quiere decir es "no se ve nada".
      expect(find.byType(VeloDeAtenuacion), findsOneWidget,
          reason: 'el widget esta: es quien decide');
      expect(
        find.descendant(
          of: find.byType(VeloDeAtenuacion),
          matching: find.byType(Container),
        ),
        findsNothing,
        reason: 'con atenuacion 1 no hay caja de color: seria un negro transparente',
      );
    });

    testWidgets('con atenuar hay un velo con el alpha justo', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: ConVeloDeAtenuacion(
          atenuacion: 0.6,
          hijo: Scaffold(body: Text('hola')),
        ),
      ));

      final velo = t.widget<VeloDeAtenuacion>(find.byType(VeloDeAtenuacion));
      final contenedor = find.descendant(
        of: find.byType(VeloDeAtenuacion),
        matching: find.byType(Container),
      );
      final color = t.widget<Container>(contenedor.first).color!;

      // Y EL ALPHA ES `1 - atenuacion`, que para 0,6 da 0,4. No `atenuacion`: si fuera el
      // propio valor, atenuar al 60 % pondria un negro **claro** --el 60 % de negro es gris
      // claro-- y la pantalla se pondria mas clara al atenuar, que es al reves.
      expect(color.a, closeTo(0.4, 0.01));
      expect(velo.atenuacion, 0.6);
    });

    testWidgets('el velo NO se puede pulsar a traves', (t) async {
      // Y CON UN **BOTON** DE CONTENIDO Y NO CON UN `GestureDetector`, y comparando **con y
      // sin velo**. Las dos cosas por un motivo:
      //
      //   - un `GestureDetector` con `behavior: deferToChild` y un `SizedBox.expand` debajo
      //     no recibe el toque en un `testWidgets`, y se comprobo: **tampoco** lo recibe
      //     sin velo. La comprobacion pedia una cosa que el banco de pruebas no hace, y el
      //     fallo decia "el velo bloquea" cuando lo que pasaba era que el blanco no era
      //     pulsable. Por eso ahora se compara: si **los dos** son cero, el problema es del
      //     banco; si el del velo es cero y el otro uno, es del velo.
      //   - un boton es un blanco de pulsacion de verdad, con el minimo de 48 px que hace
      //     falta para que un dedo lo alcance.
      var conVelo = 0;
      await t.pumpWidget(MaterialApp(
        home: ConVeloDeAtenuacion(
          atenuacion: 0.5,
          hijo: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => conVelo++,
                child: const Text('pulsame'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('pulsame'));
      await t.pumpAndSettle();

      var sinVelo = 0;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => sinVelo++,
              child: const Text('pulsame'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('pulsame'));
      await t.pumpAndSettle();

      expect(sinVelo, 1,
          reason: 'el banco de pruebas tiene que ser capaz de pulsar un boton');
      expect(conVelo, sinVelo,
          reason: 'con el velo puesto el boton de debajo se pulsa igual: el velo es de luz, '
              'no una cortina');
    });

    testWidgets('el velo cubre toda la pantalla, no solo el contenido', (t) async {
      // Y CON `Positioned.fill`, porque un `Container` suelto en una `Stack` mide lo que su
      // hijo --que es una `Container` sin hijo-- y eso es cero: el velo no se ve y la
      // atenuacion no hace nada, sin que ninguna excepcion salga.
      await t.pumpWidget(const MaterialApp(
        home: ConVeloDeAtenuacion(
          atenuacion: 0.5,
          hijo: Scaffold(body: SizedBox(width: 50, height: 50)),
        ),
      ));

      final velo = t.getSize(find.byType(VeloDeAtenuacion));
      final ventana = t.getSize(find.byType(MaterialApp));

      expect(velo.width, closeTo(ventana.width, 0.5));
      expect(velo.height, closeTo(ventana.height, 0.5));
    });
  });
}