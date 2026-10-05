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

  group('1. el titulo TIENE sitio, que es lo que estaba roto', () {
    testWidgets('a 360 px el pasaje se lee entero', (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final titulo = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Juan 3:16'),
      );
      expect(titulo, findsOneWidget);
      // Y CON UN MINIMO, Y NO CON "NO DESBORDA". Un `Text` de 13,9 pixeles no desborda
      // nunca: se recorta y no hay exception. El minimo sale de medir lo que ocupa el
      // pasaje con la flecha al lado, y por debajo de eso el texto no se lee.
      expect(tester.getSize(titulo).width, greaterThan(60));
    });

    testWidgets('y la version tambien, aunque sea truncada', (tester) async {
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final version = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('King James Version (2006)'),
      );
      expect(version, findsOneWidget);
      expect(tester.getSize(version).width, greaterThan(40));
    });

    testWidgets('a 320 px tampoco desborda, y el pasaje sigue leible', (tester) async {
      // Y 320, QUE ES UN ANCHO REAL. La prueba anterior de esta pantalla era a 360 y la
      // de mas ancho no encuentra nada: una cabecera que cabe en 360 y se pasa en 320 es
      // una cabecera que no esta terminada, y 320 px es un ancho de telefono viejo, no una
      // hipotesis.
      await pintar(tester, versiones: const <VersionDisponible>[kjv], ancho: 320);
      expect(tester.takeException(), isNull);

      final titulo = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Juan 3:16'),
      );
      expect(tester.getSize(titulo).width, greaterThan(50));
    });

    testWidgets('sin manifiesto el titulo no empuja con un hueco', (tester) async {
      // Y UNA SOLA LINEA, no una linea y un hueco. Un modulo al que no se le puede quitar
      // el nombre de la version --porque no hay manifiesto al que pertenece-- deja la
      // cabecera a una linea; un hueco de mas seria empujar el texto abajo sin motivo.
      await pintar(tester, versiones: const <VersionDisponible>[]);

      expect(find.text('Juan 3:16'), findsWidgets);
      expect(find.text('Leyendo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('2. las dos lineas hacen cosas distintas', () {
    testWidgets('el pasaje abre los libros y la version abre las versiones',
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
        matching: find.text('Juan 3:16'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('King James Version (2006)'),
      ));
      await tester.pumpAndSettle();

      expect(libros, 1);
      expect(versiones, 1);
    });

    testWidgets('las dos tienen etiqueta para un lector de pantalla', (tester) async {
      // Y CON `Semantics(button: true)`. Dos lineas pulsables sin etiqueta son dos zonas
      //illas que un lector de pantalla anuncia como texto plano, y quien no ve la pantalla
      // no puede ni adivinar que son pulsables ni que abren.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      final semantica = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .join(' | ');

      expect(semantica, contains('Elegir libro y capitulo'));
      expect(semantica, contains('Elegir la version del texto'));
    });
  });

  group('3. lo que la cabecera no trae', () {
    testWidgets('no hay icono de version: la version es el titulo', (tester) async {
      // Y NO UN QUINTO ICONO. La barra tiene volver, buscar, letras rojas y comentario, y
      // con un icono mas a 360 el titulo volveria a los 13,9 pixeles. El selector de
      // version no cabe en un boton porque es la interaccion mas valiosa de la categoria,
      // y lo que hace falta para que quepa es **dejarle sitio**, no anadirle sitio.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      // Y TODO ACOTADO A LA BARRA. `Icons.tonality` sale **dos** veces en pantalla: en el
      // interruptor de la barra y en el boton del campo de referencia, que se parece
      // bastante. Sin acotar, "findsOneWidget" se quejaria de algo que esta bien.
      final barra = find.byType(AppBar);
      expect(find.descendant(of: barra, matching: find.byIcon(Icons.translate)), findsNothing);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.library_books)),
          findsNothing);
      // Y LOS TRES QUE SI HAY.
      expect(find.descendant(of: barra, matching: find.byIcon(Icons.search)), findsOneWidget);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.tonality)),
          findsOneWidget);
      expect(
          find.descendant(of: barra, matching: find.byIcon(Icons.arrow_back)),
          findsOneWidget);
    });

    testWidgets('el boton de comentario no lleva texto', (tester) async {
      // Y LA PALABRA "Comentario" SE LLEVA 110 PIXELES. Es el numero que ha dejado el
      // titulo sin sitio, y por eso esta comprobacion existe: si alguien vuelve a poner un
      // boton con texto en la barra, el titulo se encoge otra vez y esta comprobacion no
      // lo dice --lo dice la de mas arriba, que mide el ancho--, pero al menos se ve que
      // se toco algo.
      await pintar(tester, versiones: const <VersionDisponible>[kjv]);

      expect(find.widgetWithText(TextButton, 'Comentario'), findsNothing);
    });

    testWidgets('la version abierta se busca en la lista, no en el manifiesto',
        (tester) async {
      // Y LA LISTA QUE LLEGA YA ESTA PREPARADA. La vista no sabe que hay un manifiesto ni
      // de donde sale "descargado", y si lo supiera acabaria preguntando al almacenamiento
      // --que es lo que `arranque.dart` hace con un plazo porque en un navegador puede no
      // contestar-- para pintar un boton.
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

