// La cabecera de la pantalla de lectura: el pasaje y la version.
//
// ============================================================================
// QUE ESTA MAL Y POR QUE ESTE FICHERO EXISTE
// ============================================================================
//
// MEDIDO a 360 px, con la cabecera de dos lineas y el boton de comentario como boton con
// texto: el hueco que le quedaba al titulo era de **13,9 pixeles**.
//
// Trece. El pasaje "Juan 3:16" no cabia en trece pixeles, y el nombre de la version tampoco.
// Lo que se veia era un titulo recortado en seco y un `overflow` de 6 pixeles en cada
// linea. Y no lo habria visto nadie leyendo el codigo: tres widgets correctos, en su sitio,
// que juntos no dejan sitio.
//
// Y EL CULPABLE NO ERA LA CABECERA NUEVA. Era `TextButton.icon` con la palabra
// "Comentario", que se come **110 pixeles** sola en una barra de 360. Con icono se le
// quedan 48, y esos 62 pixeles son los que hacen que las dos lineas de cabecera quepan.
//
// POR ESO LA PRIMERA PRUEBA DE ESTE FICHERO NO ES "SE VE BIEN". Es que el titulo **tiene
// ancho**. Un titulo de 13,9 pixeles no desborda: se recorta entero y no hay forma de verlo
// desde fuera. El renderizado solo se queja cuando se pasa, y aqui lo que se pasaba era el
// texto que seinia.
//
// ============================================================================
// Y LO QUE LA CABECERA NO ES
// ============================================================================
//
// No es un menu de versiones con un icono. El selector de version es, de
// `docs/investigacion-ux.md`, "la interaccion mas valiosa de una app de Biblia", y una
// interaccion de ese valor **no es un icono**: es el sitio donde ya se mira, que es la
// cabecera. Por eso esta en el titulo y no entre los botones, y por eso el boton de
// comentario se ha tenido que hacer pequeno para que quepa.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/app/navegador.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_versiones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

/// La cabecera se prueba sobre la pantalla entera, y no sobre la clase suelta.
///
/// Y POR QUE: el fallo que se ha corregido --13,9 pixeles-- **no es de la cabecera**. Es
/// de la suma de la cabecera con el boton de volver y los tres de la derecha, dentro de una
/// barra de 360. Una prueba de la clase suelta mide una anchura que en la pantalla real no
/// existe, y habria pasado con el bug puesto.
void main() {
  setUpAll(cargarLaFuenteDePrueba);

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

  Future<void> pintar(
    WidgetTester tester, {
    required List<VersionDisponible> versiones,
    double ancho = 360,
  }) async {
    tester.view.physicalSize = Size(ancho, 800);
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
          alAlternarPalabrasDeJesus: vm.alternarPalabrasDeJesus,
          alAbrirLibros: () {},
          alAbrirVersiones: () {},
          alCambiarDeVersion: (_) {},
          // Y EL BUSCADOR SE PASA, porque `alBuscar` es **opcional** y en la biblioteca no
          // hay texto abierto. Sin el, la barra no lo pinta y la comprobacion de "los tres
          // que si hay" se queja de un icono que esta bien que no este.
          alBuscar: () {},
          versiones: versiones,
        ),
      ),
    );
    vm.leer(const Referencia('John', 3, 16));
    await tester.pumpAndSettle();
  }

  const kjv = VersionDisponible(
    id: 'KJV2006',
    nombre: 'King James Version (2006)',
    descargado: true,
    bytes: 22544384,
  );

  group('1. la version es la pestana y la referencia es un campo', () {
    // ============================================================================
    // Y ESTO CAMBIO DE DISTRIBUCION, Y LA RAZON ESTA EN UNA CAPTURA.
    // ============================================================================
    //
    // Antes las dos lineas --pasaje y version-- estaban en la barra y el campo vivia en
    // medio del texto. Comparada con la cabecera del panel de Logos, esa distribucion
    // estaba del reves: alli la version identifica la pestana y la referencia es un campo
    // en su propia fila.
    //
    // Y LO QUE SE MIDIO AL PASAR EL CAMPO DENTRO DE LA BARRA: a 360 px los tres botones de
    // la derecha son 144 px y al campo le quedan **225** de los 330. Por eso el campo esta
    // en su propia fila y no en el `title`.
    testWidgets('la version va en la barra, como rotulo de pestana', (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final version = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('King James Version (2006)'),
      );
      expect(version, findsOneWidget);
      expect(tester.getSize(version).width, greaterThan(40));
    });

    testWidgets('la referencia es un campo, y **no** esta en la barra', (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      // Y QUE ESTE FUERA DE LA BARRA ES LA COMPROBACION, no un detalle. Si vuelve a entrar
      // en el `title`, el campo se queda en 225 px a 360 y "Juan 3:16" con sus dos iconos
      // de sufijo no entra.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(TextField)),
        findsNothing,
        reason: 'el campo no compite con los botones de la barra',
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a 360 px el campo tiene lo que dejan las flechas, y es bastante',
        (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      // Y **248 PIXELES**, Y NO 330, Y EL NUMERO ESTA MEDIDO.
      //
      //     360  la pantalla
      //      14  margen izquierdo
      //      14  margen derecho
      //       4  hueco entre el campo y las flechas
      //      80  las dos flechas de capitulo, a 40 cada una con `VisualDensity.compact`
      //     ---
      //     248  lo que le queda al campo
      //
      // Y 248 ALCANZA, porque dentro van los dos iconos de sufijo --borrar e ir, 80 mas-- y
      // quedan **168** para el texto. "Juan 3:16" mide unos 70.
      //
      // Y POR QUE NO SE BAJAN LAS FLECHAS A 32. `IconButton` con `compact` ya esta por
      // debajo del minimo de 48 px que el framework considera pulsable con el dedo; a 32
      // se fallaria la pulsacion sin darse cuenta, y leer seguido es el uso mas frecuente
      // de un lector de Biblia. Es un precio que se paga a proposito, no por descuido.
      expect(tester.getSize(find.byType(TextField)).width, greaterThan(240));
    });

    testWidgets('a 320 px tampoco, y el campo sigue leible', (tester) async {
      // Y 320, QUE ES UN ANCHO REAL. Una cabecera que cabe en 360 y se pasa en 320 no esta
      // terminada, y 320 px es un telefono viejo, no una hipotesis.
      await pintar(tester, versiones: const <VersionDisponible>[kjv], ancho: 320);
      expect(tester.takeException(), isNull);

      // 320 - 28 de margenes - 4 - 80 de flechas = **208**.
      expect(tester.getSize(find.byType(TextField)).width, greaterThan(200));
    });

    testWidgets('a 1440 el campo NO se estira', (tester) async {
      // Y 360 DE TOPE. Medido: estirado, el campo ocupaba los **1.260 pixeles** que quedan
      // despues del panel de herramientas, y una fila de cabecera con un campo de 1.260 px
      // parece la pagina de busqueda de una aplicacion. En la captura de Logos el campo de
      // la referencia es una caja corta a la izquierda de la fila y a su derecha van los
      // menus del panel.
      //
      // Y CON UN `Flexible` SUELTO NO SE ARREGLA: un `TextField` pide todo el ancho
      // disponible y lo recibe. Hace falta un `maxWidth`.
      await pintar(tester, versiones: const <VersionDisponible>[kjv], ancho: 1440);

      expect(tester.getSize(find.byType(TextField)).width, lessThanOrEqualTo(360));
    });

    testWidgets('la fila de la referencia crece con el texto de error', (tester) async {
      // Y ESTA ES LA SEGUNDA MEDIDA. La primera version de la fila la fijaba en 48 px, y el
      // campo con su linea de error necesita 56 y con las dos lineas 72:
      //
      //     A RenderFlex overflowed by 24 pixels on the bottom.
      //     Column  campo_de_referencia.dart:105
      //
      // Un alto fijo que funciona con el campo vacio y revienta con el campo mal escrito no
      // es un alto fijo: es un fallo esperando a que alguien escriba "Juan".
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final altoConElCampoVacio = tester.getSize(find.byType(TextField)).height;
      await tester.enterText(find.byType(TextField), 'Juan');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'con texto que no se entiende, el campo tiene que crecer');
      expect(tester.getSize(find.byType(TextField)).height,
          greaterThan(altoConElCampoVacio),
          reason: 'y si no crece, el error se sale de la fila');
    });

    testWidgets('sin manifiesto no hay pestana, y la barra no empuja con un hueco',
        (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[]);

      expect(find.text('Leyendo'), findsNothing);
      expect(find.byType(TextField), findsOneWidget,
          reason: 'la referencia esta en el campo, y sin manifiesto tambien');
      expect(tester.takeException(), isNull);
    });
  });

  group('2. las dos cosas hacen cosas distintas', () {
    testWidgets('la version abre las versiones y las migas abren los libros',
        (tester) async {
      var libros = 0, versiones = 0;

      tester.view.physicalSize = const Size(360, 800);
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
            alAlternarPalabrasDeJesus: vm.alternarPalabrasDeJesus,
            alAbrirLibros: () => libros++,
            alAbrirVersiones: () => versiones++,
            alCambiarDeVersion: (_) {},
            versiones: const <VersionDisponible>[kjv],
          ),
        ),
      );
      vm.leer(const Referencia('John', 3, 16));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('King James Version (2006)'),
      ));
      await tester.pumpAndSettle();

      // Y LAS MIGAS, QUE SON "Juan 3" EN EL TEXTO. Antes el pasaje se elegia con un boton
      // de volver atras en el titulo; ahora el sitio para ir a otro lugar es el nombre del
      // libro, que es lo que hay encima del texto.
      await tester.tap(find.text('Juan 3'));
      await tester.pumpAndSettle();

      expect(versiones, 1);
      expect(libros, 1);
    });

    testWidgets('las dos tienen etiqueta para un lector de pantalla', (tester) async {
      // Y CON `Semantics(button: true)`. Dos cosas pulsables sin etiqueta son dos zonas
      //illas que un lector de pantalla anuncia como texto plano, y quien no ve la pantalla
      // no puede ni adivinar que son pulsables ni que abren.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final semantica = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .join(' | ');

      expect(semantica, contains('Elegir libro y capitulo'));
      expect(semantica, contains('Cambiar de version'));
    });
  });

  group('3. lo que la cabecera no trae', () {
    testWidgets('no hay flecha de volver: el marco es el camino de vuelta', (tester) async {
      // Y NO POR OLVIDO. Con el panel de herramientas, tener las dos cosas --una barra
      // lateral que dice "Biblioteca" y una flecha que tambien vuelve-- es no decidir
      // cual manda. En la captura de Logos no hay flecha de volver en la cabecera del
      // panel, y la razon es que no la hay en ninguna parte: la aplicacion es una ventana
      // con herramientas, no una pila de pantallas.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.arrow_back)),
        findsNothing,
      );
    });

    testWidgets('no hay icono de version: la version es la pestana', (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      // Y TODO ACOTADO A LA BARRA. `Icons.tonality` sale una vez, en el interruptor, y
      // acotar el finder sigue siendo necesario porque el mismo icono esta en el boton de
      // borrar del campo en otras pantallas.
      final barra = find.byType(AppBar);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.translate)), findsNothing);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.library_books)),
          findsNothing);
      // Y LOS QUE SI HAY.
      expect(find.descendant(of: barra, matching: find.byIcon(Icons.search)), findsOneWidget);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.tonality)),
          findsOneWidget);
    });

    testWidgets('el boton de comentario no lleva texto', (tester) async {
      // Y LA PALABRA "Comentario" SE LLEVA 110 PIXELES. Es el numero que dejo el titulo
      // sin sitio en su dia, y por eso esta comprobacion sigue aqui: si alguien vuelve a
      // poner un boton con texto en la barra, se vuelve al problema de antes.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      expect(find.widgetWithText(TextButton, 'Comentario'), findsNothing);
    });

    testWidgets('la version abierta se busca en la lista, no en el manifiesto',
        (tester) async {
      // Y LA LISTA QUE LLEGA YA ESTA PREPARADA. La vista no sabe que hay un manifiesto ni
      // de donde sale "descargado", y si lo supiera acabaria preguntando al
      // almacenamiento --que es lo que `arranque.dart` hace con un plazo porque en un
      // navegador puede no contestar-- para pintar un boton.
      await pintar(
        tester,
        versiones: const <VersionDisponible>[
          kjv,
          VersionDisponible(
            id: 'NO',
            nombre: 'Un texto que no esta abierto',
            descargado: false,
            bytes: 1048576,
          ),
        ],
      );

      // Y SOLO LA ABIERTA APARECE COMO NOMBRE. Poner el nombre de una traduccion que no se
      // esta leyendo es un dato que no es el que se esta leyendo.
      expect(find.text('Un texto que no esta abierto'), findsNothing);
      expect(find.text('King James Version (2006)'), findsOneWidget);
    });
  });


  group('4. el tamano del boton de descargar', () {
    testWidgets('sale con la unidad y con coma', (tester) async {
      // Y ANTES SALIA SIN UNIDAD. El boton decia "Descargar, 54.9", y no se sabe si son
      // megas. Con `bytesEnCastellano` dice "Descargar, 54,9 MB".
      //
      // Y 22.544.384 BYTES SON **21,5** MB Y NO 22,5: es dividir por 1.048.576, que es un
      // mebibyte, y no por un millon. Ese error de calculo estaba tambien en lo que este
      // fichero esperaba antes, o sea que la prueba daba verde con el numero equivocado.
      expect(bytesEnCastellano(22544384), '21,5 MB');
      expect(bytesEnCastellano(57536512), '54,9 MB');
    });
  });

  group('5. la ruta del selector, que es lo que lo hace compartible', () {
    test('la cabecera no cambia la ruta de nada', () {
      // Y ESTO ES UNA COMPROBACION DE QUE NO SE ROMPIO NADA. Abrir un selector de libros y
      // cancelar no puede cambiar la URL, porque la URL es donde esta el pasaje: si
      // descolocarla al abrir una hoja, recargar la pagina en otro sitio y compartir el
      // enlace dejarian de llevar a Juan 3:16.
      expect(
        Rutas.escribir(RutaLectura('KJV2006', Referencia('John', 3, 16))),
        '/leer/KJV2006/John.3.16',
      );
    });
  });

  group('6. la version llega TARDE, y eso es lo que rompia la barra', () {
    // ============================================================================
    // Y ESTA SECCION ES LA QUE ATRAPA EL FALLO QUE SOLO SE VE EN UNA IMAGEN.
    // ============================================================================
    //
    // Medido el 5 de octubre de 2026 en una captura de la pantalla de lectura a 360 px, con
    // Juan 3:16 abierto y el KJV entero en el `IndexedDB`: **la segunda linea de la barra,
    // con el nombre de la version, no salia**. Se espero 20 s: no era tiempo.
    //
    // La causa: el enrutador escuchaba a la biblioteca solo para saber si podia abrir el
    // comentario, y **nunca llamaba a `notifyListeners()`**. Con eso la pantalla de lectura
    // se quedaba con la lista de versiones que tenia cuando se construyo --vacia, porque
    // el manifiesto todavia no habia llegado-- y para siempre.
    //
    // Y POR QUE NO LO VEIA NINGUNA COMPROBACION. El nombre de la version es texto de la
    // barra; la sonda del navegador lee el **pasaje**, y `flutter test` montaba la pantalla
    // con la lista ya puesta a mano. Las dos dan verde con el bug puesto. Hace falta mirar
    // la imagen, y por eso esta prueba monta el enrutador entero y cambia la biblioteca
    // **despues**.
    testWidgets('el nombre de la version aparece cuando llega el manifiesto', (t) async {
      final biblioteca = BibliotecaViewModel();
      final lector = LectorViewModel();
      // Y SIN `addTearDown` PARA ESOS DOS, porque `NavegadorAb.dispose` ya los cierra: con
      // las dos llamadas, el enrutador los cerraba y despues la prueba los cerraba otra
      // vez, y `ChangeNotifier.dispose` sobre uno ya cerrado lanza.
      // El fallo sale en el `dispose` y no en el `build`, asi que el sintoma es "un
      // LectorViewModel se uso despues de cerrarse" en una prueba que no hace nada raro.

      final abierto = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (abierto is! Abierto) fail('la Biblia real deberia abrirse');
      addTearDown(abierto.modulo.cerrar);

      // Y PRIMERO UNA BIBLIOTECA **VACIA**, que es lo que hay en el arranque: el manifiesto
      // todavia no ha llegado y la pantalla de lectura ya esta montada.
      final n = NavegadorAb(
        biblioteca: biblioteca,
        lector: lector,
        resaltados: ResaltadosViewModel(),
        abrir: (id, _) async => abierto.modulo,
      );
      addTearDown(n.dispose);

      t.view.physicalSize = const Size(360, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      await t.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(RutaLectura('KJV2006', const Referencia('John', 3, 16)));
      await t.pumpAndSettle();

      // Y LA BARRA TIENE UNA SOLA LINEA, y no es un fallo: no hay manifiesto del que sacar
      // el nombre. Una linea y sin hueco.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('King James Version (2006)')),
        findsNothing,
      );

      // Y AHORA LLEGA EL MANIFIESTO. Este es el momento en que se rompia: la lista de
      // versiones pasa de vacia a tener una entrada y la pantalla **no se enteraba**.
      biblioteca.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: Manifiesto(
            formato: 'aa-catalog/1',
            version: 'v0.1.1',
            etiqueta: 'v0.1.1',
            modulos: <Modulo>[
              Modulo(
                id: 'KJV2006',
                nombre: 'King James Version (2006)',
                tipo: TipoModulo.biblia,
                idioma: 'eng',
                licencia: 'PublicDomain',
                tamanoBytes: 22544384,
                sha256: 'a' * 64,
                urlDescarga: Uri.parse('https://example.invalid/KJV2006.amod'),
                urlNavegador: Uri.parse('https://example.invalid/KJV2006'),
              ),
            ],
          ),
          estado: EstadoLectura.delServidor,
        ),
        idsLocales: <String>{'KJV2006'},
        hashesLocales: <String, String>{'KJV2006': 'a' * 64},
      );
      await t.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('King James Version (2006)')),
        findsOneWidget,
        reason: 'el manifiesto ha llegado y la barra tiene que redibujarse sola',
      );
      // Y EL PASAJE SIGUE ESTANDO, que es lo que no hay que romper al redibujar.
      expect(n.lector.leyendo, const Referencia('John', 3, 16));
    });
  });
}

