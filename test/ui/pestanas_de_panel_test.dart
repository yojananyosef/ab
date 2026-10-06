// Las pestanas de panel, y la fila de menu, en pantalla.
//
// ============================================================================
// QUE COMPRUEBA ESTE FICHERO Y QUE NO PUEDE COMPROBAR
// ============================================================================
//
// Las pestanas son estado --cuantos paneles hay y cual esta delante--, y eso lo comprueba
// `paneles_view_model_test.dart` contra los datos. Aqui se monta **la pantalla**, que es
// donde se ve si la fila se pinta, si el nombre del otro texto sale, y si dos columnas de
// texto caben en la ventana.
//
// Y LA MEDIDA DE QUE **DOS PANELES CABEN Y TRES NO** la hace `test/medidas/` con numeros y
// sin widgets. Aqui solo se comprueba que lo que se decide con esos numeros se ve como
// debe: que a 1440 px hay dos columnas y una fila de pestañas, y que a 360 px hay una
// columna y **ninguna** fila.
//
// ============================================================================
// Y COMO SE ABREN DOS PANELES AQUI: **POR LA DIRECCION**, Y NO CON EL `+`
// ============================================================================
//
// El `+` abre la hoja de versiones, y esa hoja ofrece **solo Biblias** --a proposito: un
// selector de version que ofrece el Comentario es un selector que ofrece cambiar de texto
// por un comentario. Con el catalogo de hoy hay **una** Biblia, y es la que ya esta abierta,
// asi que el `+` no tiene nada que ofrecer y la hoja lo dice.
//
// Eso **no es un boton roto**: es el estado real del catalogo, y por eso aqui se abren los
// dos paneles por la **ruta** `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16`, que es
// exactamente lo que llegaria de un enlace con dos ventanas. Comprobar por la ruta y no por
// el boton es lo que hace que la prueba valga para el caso real, que es que alguien recibe
// un enlace.
//
// ============================================================================
// Y LA MONTAJE ES EL REAL, CON LOS DOS `.amod` DE VERDAD
// ============================================================================
//
// No hay un doble de modulo aqui. Con un doble, la prueba mediria el arnes y no la
// pantalla, y hay un caso en este repositorio --el `--dart-define` compilado dentro que
// hacia que la comprobacion en navegador pasara sin comprobar-- que es exactamente eso.

import 'package:ab/app/navegador.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/panel_abierto.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/lector/view_models/preferencias_de_lectura.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/ui/features/lector/widgets/fila_de_menu.dart';
import 'package:ab/ui/features/lector/widgets/fila_de_pestanas.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

/// El tamano de un modulo del catalogo de pruebas.
Modulo _modulo(String id, String nombre, TipoModulo tipo, int bytes) => Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: 'eng',
      licencia: 'PublicDomain',
      tamanoBytes: bytes,
      sha256: 'a' * 64,
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/$id'),
    );

/// Un enrutador con el catalogo de verdad y los modulos que se digan descargados.
///
/// Y EL `abrir` **RESPETA LO QUE HAY DESCARGADO**, y no es un detalle del arnés: en la
/// aplicación es `_abrirModulo`, que devuelve `null` si el fichero no esta. Un arnés que
/// abriera el fichero siempre haria pasar el caso de "el texto no esta descargado", y ese
/// caso es una de las cosas que se comprueban en `navegador_test.dart`.
NavegadorAb montarNavegadorConPaneles({Set<String>? descargados}) {
  final ids = descargados ?? <String>{'KJV2006', 'CLARKE'};
  final biblioteca = BibliotecaViewModel();
  biblioteca.aplicarResultado(
    ResultadoCatalogo(
      manifiesto: Manifiesto(
        formato: 'aa-catalog/1',
        version: 'v0.1.1',
        etiqueta: 'v0.1.1',
        modulos: <Modulo>[
          _modulo('KJV2006', 'King James Version 2006', TipoModulo.biblia, tamanoBiblia),
          _modulo(
            'CLARKE',
            'Comentario de Adam Clarke',
            TipoModulo.comentario,
            tamanoComentario,
          ),
        ],
      ),
      estado: EstadoLectura.delServidor,
    ),
    idsLocales: ids,
    hashesLocales: <String, String>{for (final id in ids) id: 'a' * 64},
  );

  return NavegadorAb(
    biblioteca: biblioteca,
    preferencias: PreferenciasDeLectura(),
    resaltados: ResaltadosViewModel(),
    abrir: (id, referencia) async {
      if (!ids.contains(id)) return null;
      final ruta = id == 'CLARKE' ? rutaComentarioReal : rutaBibliaReal;
      final apertura = ModuloAbierto.abrir(ruta, id: id);
      if (apertura is! Abierto) return null;
      return apertura.modulo;
    },
  );
}

/// La ventana, **con el marco de verdad**, porque las pestanas dependen del ancho.
///
/// Y NO SE PONE UN `MediaQuery` A MANO, porque el corte lo decide `MarcoDeEstudio`, que es
/// quien sabe cuanto le queda al panel de herramientas --**226,5 px** medidos--. Si la
/// prueba pusiera un ancho inventado, estariamos midiendo una regla que no es la de la
/// pantalla.
Future<void> _montar(WidgetTester t, NavegadorAb n, Size tamano) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);

  await t.pumpWidget(MaterialApp.router(
    theme: temaDeAb(),
    routerDelegate: n,
    routeInformationParser: const AnalizadorDeRuta(),
  ));
  await t.pumpAndSettle();
}

/// La ruta de dos ventanas: el KJV delante y el CLARKE al lado.
Ruta panelesDePrueba() => RutaPaneles(
      '/leer/KJV2006/John.3.16/y/CLARKE/John.3.16',
      const RutaLectura('KJV2006', Referencia('John', 3, 16)),
      const <RutaLectura>[RutaLectura('CLARKE', Referencia('John', 3, 16))],
    );

/// Desplazar el panel [id] y mirar que **el otro** no se ha movido.
///
/// Y ES UNA FUNCION Y NO UNA PRUEBA, y el motivo esta en la llamada: hace falta repetir el
/// caso para las dos columnas --una prueba dentro de un bucle dice "fallo en la iteracion 1"
/// sin decir cual-- y con dos columnas nuevas en cada caso, montar el enrutador una vez y
/// probar las dos columnas en la misma pantalla daria el mismo `dispose` dos veces y
/// `ChangeNotifier.dispose` sobre uno ya cerrado lanza.
Future<void> _elScrollNoSeComparte(WidgetTester t, String id) async {
  final n = montarNavegadorConPaneles();
  addTearDown(n.dispose);

  await _montar(t, n, const Size(1440, 900));
  await n.irA(panelesDePrueba());
  await t.pumpAndSettle();

  // Y LA LISTA DE VERSICULOS **SE BUSCA DENTRO DEL PANEL Y POR TIPO**, y no con
  // `find.byType(Scrollable)` a pelo. En la pantalla de lectura hay **cinco** `Scrollable`
  // con dos paneles: las dos listas de texto, el campo de referencia de cada panel --que es
  // un `EditableText` con su propio `Scrollable`-- y la fila de pestanas, que es horizontal.
  // Agarrar la primera --como hacia la prueba anterior de este repositorio-- es agarrar el
  // campo de referencia, y el arrastre no hace nada: la comprobacion diria "el texto no se
  // ha movido" sin que nadie lo comprobara.
  final listaDe = find.descendant(
    of: find.byKey(ValueKey<String>('panel:$id')),
    matching: find.byType(ListView),
  );

  // Y EL OTRO PANEL ES SIEMPRE **EL KJV**, y no "el que no sea este": con dos paneles el
  // otro es el KJV, y nombrarlo deja la comprobacion legible.
  // Y EL VERSICULO QUE SE MIDE **ES EL 16**, y no un "3" cualquiera. Juan 3:16 abre el
  // capitulo **desde el 16** --`ModuloAbierto.leer` consulta `verse >= ?`--, asi que los
  // versiculos en pantalla son del 16 al 36 y el 3 no esta. Buscar el 3 daria "no se
  // encuentra" y la comprobacion diria que el scroll se comparte cuando lo que no ha
  // encontrado es un versiculo que no existe en esa vista.
  // Y EL PANEL **QUE NO SE MUEVE** ES EL OTRO, y se calcula en vez de escribirse: con
  // "siempre el KJV", la segunda llamada --la que desplaza el KJV-- compararia el KJV
  // consigo mismo y pasaria siempre, que es comprobar que el desplazamiento no hace nada
  // en vez de que no se propague.
  final otro = id == 'KJV2006' ? 'CLARKE' : 'KJV2006';
  const primerVersiculo = '16';
  final textoDelOtro = find.descendant(
    of: find.byKey(ValueKey<String>('panel:$otro')),
    matching: find.text(primerVersiculo),
  );
  expect(textoDelOtro, findsOneWidget,
      reason: 'el versiculo 16 de Juan 3 tiene que verse en la columna de $otro');

  final antes = t.getTopLeft(textoDelOtro).dy;
  await t.drag(listaDe.first, const Offset(0, -400));
  await t.pumpAndSettle();

  expect(t.getTopLeft(textoDelOtro).dy, antes,
      reason: 'desplazar el panel $id no mueve el panel $otro');
}

void main() {
  group('1. la fila de pestañas, sola', () {
    const kjv = PanelAbierto(
      moduloId: 'KJV2006',
      referencia: Referencia('John', 3, 16),
    );
    const clare = PanelAbierto(
      moduloId: 'CLARKE',
      referencia: Referencia('John', 3, 16),
      esComentario: true,
    );

    Widget fila({required List<PanelAbierto> paneles, String? delante}) => MaterialApp(
          // Y **CON EL TEMA DE LA APLICACION**, y no con el que pone Material por defecto:
          // `context.colores` lee un `ThemeExtension` propio --`Colores`--, y con el tema
          // de Material sale un `null check` en una linea que no dice nada de por que. Es
          // el mismo motivo por el que [montarNavegadorConPaneles] monta `temaDeAb()`.
          theme: temaDeAb(),
          home: Scaffold(
            body: FilaDePestanas(
              paneles: paneles,
              moduloDelante: delante,
              nombreDe: (String id) =>
                  id == 'KJV2006' ? 'King James Version 2006' : 'Comentario de Adam Clarke',
              alFrente: (_) {},
              alCerrar: (_) {},
              alAbrirOtro: () {},
            ),
          ),
        );

    testWidgets('con un panel no hay fila', (t) async {
      await t.pumpWidget(fila(paneles: const <PanelAbierto>[kjv], delante: 'KJV2006'));

      // Y SE COMPRUEBA QUE **NO** CONTA COMO UNA PESTANA, y no que este vacia: una fila
      // vacia con el borde de abajo dibujado es un cromo de 40 px que no dice nada, y el
      // nombre del texto ya esta en la barra del panel.
      expect(find.byKey(claveDeLaFilaDePestanas), findsNothing);
    });

    testWidgets('con dos hay dos pestanas y una para abrir otra', (t) async {
      await t.pumpWidget(
        fila(paneles: const <PanelAbierto>[kjv, clare], delante: 'KJV2006'),
      );

      expect(find.byKey(claveDeLaFilaDePestanas), findsOneWidget);
      expect(find.byKey(claveDeLaPestana('KJV2006')), findsOneWidget);
      expect(find.byKey(claveDeLaPestana('CLARKE')), findsOneWidget);
      // Y EL **+** ESTA, porque es la unica forma de abrir un panel, y un `+` que no esta
      // es una pestana que no se puede añadir.
      expect(find.byIcon(Icons.add), findsOneWidget);
      // Y LA **X** TAMBIEN: con dos paneles hay algo que cerrar, y sin `X` la pestana solo
      // se puede traer al frente, nunca cerrar.
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('pulsar una pestana pide traer ESE panel delante', (t) async {
      final delante = <String>[];
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Scaffold(
          body: FilaDePestanas(
            paneles: const <PanelAbierto>[kjv, clare],
            moduloDelante: 'KJV2006',
            nombreDe: (String id) =>
                id == 'KJV2006' ? 'King James Version 2006' : 'Comentario de Adam Clarke',
            alFrente: delante.add,
            alCerrar: (_) {},
            alAbrirOtro: () {},
          ),
        ),
      ));

      await t.tap(find.byKey(claveDeLaPestana('CLARKE')));
      expect(delante, <String>['CLARKE']);
    });

    testWidgets('la X pide cerrar SU panel, no el de delante', (t) async {
      // Y SE COMPRUEBA CON **TRES** PANELES Y CERRANDO EL DEL MEDIO, porque con dos no se
      // puede saber cual es el de delante: cerrando el de delante y cerrando el otro sale el
      // mismo identificador. Con tres, cerrar el del medio solo puede ser el del medio.
      const uno = PanelAbierto(moduloId: 'UNO', referencia: Referencia('John', 1));
      const dos = PanelAbierto(moduloId: 'DOS', referencia: Referencia('John', 2));
      const tres = PanelAbierto(moduloId: 'TRES', referencia: Referencia('John', 3));

      final cerrados = <String>[];
      await t.pumpWidget(MaterialApp(
        theme: temaDeAb(),
        home: Scaffold(
          body: FilaDePestanas(
            paneles: const <PanelAbierto>[uno, dos, tres],
            moduloDelante: 'UNO',
            nombreDe: (String id) => id,
            alFrente: (_) {},
            alCerrar: cerrados.add,
            alAbrirOtro: () {},
          ),
        ),
      ));

      await t.tap(find.descendant(
        of: find.byKey(claveDeLaPestana('DOS')),
        matching: find.byIcon(Icons.close),
      ));
      expect(cerrados, <String>['DOS']);
    });

    testWidgets('mide 40 px de alto, y no mas', (t) async {
      await t.pumpWidget(
        fila(paneles: const <PanelAbierto>[kjv, clare], delante: 'KJV2006'),
      );

      // Y LOS 40 PX ESTAN MEDIDOS contra el cromo de encima del primer versiculo, que a
      // 360 px eran 260 px con la barra y la cabecera. Anadir 40 mas son el 39 % de una
      // pantalla de 760, y por eso la fila no se pinta a 360 px.
      expect(t.getSize(find.byKey(claveDeLaFilaDePestanas)).height,
          kAlturaDeLaFilaDePestanas);
    });

    testWidgets('un comentario lleva su punto de color y una Biblia no', (t) async {
      // Y EL PUNTO ES SOLO DEL **COMENTARIO**, y es una distincion que se puede hacer sin
      // inventar nada. En Logos cada recurso lleva un color que elige quien lo tiene
      // abierto, y aqui **no hay ningun color en el manifiesto que sea "el color de esta
      // Biblia"**: poner el `primary` del tema seria inventar un color por texto. Lo que si
      // se puede distinguir es el **tipo**, y con el color de acento que ya usa el resto de
      // la aplicacion para "esto es un comentario".
      await t.pumpWidget(
        fila(paneles: const <PanelAbierto>[kjv, clare], delante: 'KJV2006'),
      );
      final puntos = t
          .widgetList<Container>(find.descendant(
            of: find.byKey(claveDeLaPestana('CLARKE')),
            matching: find.byType(Container),
          ))
          .where((Container c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      });
      expect(puntos, hasLength(1),
          reason: 'el CLARKE es un comentario y lleva el punto');
    });
  });

  group('2. dos textos en paralelo en la pantalla real', () {
    testWidgets('a 1440 px hay dos columnas y una fila de pestañas', (t) async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      // Y **MONTAR ANTES DE NAVEGAR**, y no al reves. El `Router` de `MaterialApp.router`
      // aplica su ruta inicial --que sin `routeInformationProvider` es `/`-- en cuanto se
      // monta, e ir a la biblioteca **cierra todos los paneles**: quien esta en la
      // biblioteca no esta leyendo. Con la navegacion antes del montaje, esa primera
      // aplicacion de `/` se lleva por delante el texto que se acaba de abrir, y la
      // comprobacion falla con "no hay ningun LectorView" sin decir por que.
      await _montar(t, n, const Size(1440, 900));
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      await t.pumpAndSettle();

      // Y **UN PANEL** AL EMPEZAR, que es el estado de partida. Y se ve con la barra de
      // arriba, que es donde esta el nombre del texto mientras no haya pestanas.
      expect(find.byType(LectorView), findsOneWidget);
      expect(find.byKey(claveDeLaFilaDePestanas), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);

      await n.irA(panelesDePrueba());
      await t.pumpAndSettle();

      expect(find.byKey(claveDeLaFilaDePestanas), findsOneWidget);
      expect(find.byType(LectorView), findsNWidgets(2));
      // Y LOS DOS NOMBRES EN LA FILA, que es lo que hace que "tengo dos textos abiertos"
      // sea una cosa que se pueda **ensenar**. Un icono de pestana sin nombre no lo hace:
      // hay que saber cuales son.
      expect(find.text('King James Version 2006'), findsOneWidget);
      expect(find.text('Comentario de Adam Clarke'), findsWidgets);
    });

    testWidgets('a 360 px hay un panel, PERO LAS PESTANAS SI', (t) async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(360, 760));
      await n.irA(panelesDePrueba());
      await t.pumpAndSettle();

      // ============================================================================
      // Y ESTA PRUEBA ESTA CONTRA LO QUE SE HABIA ESCRITO, Y EL MOTIVO ESTA MEDIDO
      // ============================================================================
      //
      // La regla de antes era "por debajo de 1.100 px no hay pestanas", y salia de un
      // argumento cierto --tres nombres a 360 px son tres columnas de 60-- y una conclusion
      // falsa, porque esos 60 px son de las **columnas**, no de la **fila**.
      //
      // Y MEDIDO EL 6 DE OCTUBRE DE 2026 en una captura a 360 px con
      // `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16`: se ve **un panel**, con su barra y su
      // campo, y el segundo panel esta abierto --22,5 MiB de paginas SQLite-- y **no hay
      // ninguna manera de llegar a el**. Ni pestañas, ni una fila, ni un boton.
      //
      // Y ESO ES PEOR QUE UNA PESTANA RECORTADA: un nombre con puntos suspensivos se sabe
      // que esta ahi y se puede ir; un panel invisible no existe. Y lo que se ve desde
      // fuera es una aplicacion que ha perdido la mitad de lo que esta leyendo, sin decir
      // nada.
      expect(find.byType(LectorView), findsOneWidget,
          reason: 'a 360 px solo se ve una columna');
      // Y POR ESO LA FILA **SI** SE PINTA: es lo que hace alcanzable el panel que no se ve.
      expect(find.byKey(claveDeLaFilaDePestanas), findsOneWidget);
      expect(find.byKey(claveDeLaPestana('CLARKE')), findsOneWidget,
          reason: 'la segunda pestana es la unica forma de llegar al segundo panel');
      // Y LA BARRA **NO**: con la fila de pestañas puesta, las dos veces el nombre del texto.
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('a 360 px los dos nombres caben en la fila sin esconderse', (t) async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(360, 760));
      await n.irA(panelesDePrueba());
      await t.pumpAndSettle();

      // Y LOS DOS **ESTAN EN PANTALLA A LA VEZ**, y no uno y el otro escondido. Con un
      // tope fijo de 200 px por nombre, la primera pastilla se comia los 360 y la segunda --
      // que es la que dice que hay dos textos-- quedaba fuera: la lista es desplazable, asi
      // que no se perdia, se **escondia**. Y quien no sepa que puede desplazar creeria que
      // solo hay un texto abierto.
      final primera = t.getRect(find.byKey(claveDeLaPestana('KJV2006')));
      final segunda = t.getRect(find.byKey(claveDeLaPestana('CLARKE')));
      expect(segunda.left, lessThan(360),
          reason: 'la segunda pestana tiene que verse sin desplazar');
      expect(primera.right, lessThanOrEqualTo(segunda.left),
          reason: 'y las dos no se pisan');
    });

    testWidgets('en 360 px abrir un segundo panel **lo abre**, y se llega con la fila',
        (t) async {
      // Y ESTO ES LA OTRA CARA DEL ARREGLO. Antes `abrirPanel` **se negaba** en pantalla
      // estrecha, con el argumento de que no cabria. El argumento era correcto para las
      // columnas y equivocado para el panel: con la fila de pestañas --que es lo que se
      // acaba de decidir-- el segundo panel **se abre y se alcanza a un toque**.
      //
      // Y LO QUE SE PIERDE AL NO ABRIRLO NO ES NADA: se pierde la posibilidad de comparar dos
      // textos en el movil, que es la interaccion mas valiosa de la categoria.
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(360, 760));
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      await t.pumpAndSettle();

      await n.abrirPanel('CLARKE');
      await t.pumpAndSettle();

      expect(n.paneles.cuantos, 2);
      expect(find.byKey(claveDeLaPestana('CLARKE')), findsOneWidget);

      // Y EL `+` **NO AVISA**, y no hay ningun aviso: abrir un panel a 360 px es una cosa
      // que se puede hacer y se ha hecho. El aviso que se pone es el del tope de **tres**,
      // que es de memoria.
      expect(n.biblioteca.avisos.map((a) => a.texto).join(' '),
          isNot(contains('columna')));
    });

    testWidgets('la fila de menu sale con pestañas y no hay barra', (t) async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(1440, 900));

      // Y CON UN SOLO TEXTO **NO HAY FILA DE MENU**, porque sus funciones estan en la barra
      // de arriba. Las dos cosas a la vez serian las mismas tres funciones en dos sitios,
      // y medido a 1440 px son 56 px de barra + 36 de fila encima del primer versiculo sin
      // que la columna de texto --que es de 769 px-- crezca nada.
      expect(find.byKey(claveDeLaFilaDeMenu), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);

      await n.irA(panelesDePrueba());
      await t.pumpAndSettle();

      // Y CON DOS, **NO HAY NINGUNA BARRA** y hay una fila de menu por panel. Es la
      // inversion de las pestanas: la fila de pestañas hace de barra.
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(claveDeLaFilaDeMenu), findsNWidgets(2));
    });

    testWidgets('cada columna tiene su scroll propio', (t) async {
      // Y LOS DOS CASOS, uno por columna, y no un bucle: un fallo dentro de un bucle dice
      // "fallo en la iteracion 1" sin decir **cual** de las dos columnas no se movio, que
      // es justo lo que hace falta saber para arreglarlo.
      //
      // Y POR QUE HAY QUE COMPROBAR LAS DOS Y NO SOLO UNA: si el arrastre se hiciera
      // siempre en la misma columna, una de las dos listas estaria anclada a la otra y la
      // comprobacion dari verde con el defecto puesto en la que no se arrastra.
      await _elScrollNoSeComparte(t, 'CLARKE');
      await _elScrollNoSeComparte(t, 'KJV2006');
    });
  });

  group('3. la fila de menu', () {
    testWidgets('Juan 3 no tiene notas al pie y la entrada NO se pinta', (t) async {
      // Y ESTO ESTA MEDIDO, y no es una excepcion: Juan 3 entero **no tiene ni una nota
      // al pie**, y los cuatro evangelios enteros tampoco. De los 31.102 versiculos del
      // KJV, 5.844 traen notas --el **18,79 %**--, asi que de cada cinco versiculos, cuatro
      // no tienen ninguna.
      //
      // Y LA ENTRADA QUE NO SE PINTA ES LA REGLA, no la excepcion: una entrada que al
      // pulsarla abre una hoja que dice "no hay" es peor que una entrada que no existe,
      // porque enseña a usar la aplicacion con una promesa que no se puede cumplir.
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(1440, 900));
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      await t.pumpAndSettle();
      await n.abrirPanel('CLARKE');
      await t.pumpAndSettle();

      expect(find.text('Notas'), findsNothing);
      // Y LAS OTRAS TRES **SI**, porque tienen algo detras siempre.
      expect(find.text('Buscar'), findsWidgets);
      expect(find.text('Formato'), findsWidgets);
    });

    testWidgets('con notas al pie la entrada se pinta', (t) async {
      // Y UN VERSICULO **CON** NOTAS, que Juan 3 no puede enseñar. 1Cronicas 1:6 es el
      // caso medido: su nota es "1.6 Riphath: or, Diphath as it is in some copies", y
      // antes de este change salia **dentro** del versiculo como si fuera Escritura.
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(1440, 900));
      await n.irA(const RutaLectura('KJV2006', Referencia('1Chronicles', 1, 6)));
      await t.pumpAndSettle();
      await n.abrirPanel('CLARKE');
      await t.pumpAndSettle();

      // Y **SOLO EN UNO** de los dos paneles: el CLARKE es un comentario y no tiene notas
      // al pie --tiene notas de comentario, que son otra cosa y salen debajo de cada
      // versiculo--. Una entrada de menu que lleva a una lista vacia es la que no debe
      // existir.
      expect(find.text('Notas'), findsOneWidget);
    });

    testWidgets('la entrada de comentario DICE el nombre del que hay abierto', (t) async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await _montar(t, n, const Size(1440, 900));
      // Y CON **TRES** PANELES Y UN CON COMENTARIO A PROPOSITO. Con dos, si el comentario
      // se aplicase al panel equivocado, el nombre saldria **las dos veces** --una por
      // panel-- y el "no hay ninguno a secas" seguiria dando verde. Con tres hay un panel
      // sin comentario, y solo puede haber un rotulo generico.
      await n.irA(RutaPaneles(
        '/leer/KJV2006/John.3.16/con/CLARKE/y/KJV_ALTERNO/John.3.16',
        const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'),
        const <RutaLectura>[RutaLectura('CLARKE', Referencia('John', 3, 16))],
      ));
      await t.pumpAndSettle();

      // Y EL TEXTO **NO ES SIEMPRE EL MISMO**: con comentario abierto dice el nombre, y sin
      // comentario dice "Comentario". Es lo que hace que se pueda confirmar de un vistazo
      // que lo que hay al lado es lo que se pidio, y no el que habia de antes.
      expect(find.text('Comentario'), findsOneWidget,
          reason: 'solo el panel sin comentario puesto pone el rotulo generico');
    });
  });

  group('4. la direccion', () {
    test('la ruta de dos ventanas se lee y se escribe igual', () {
      final leida = Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16');
      expect(leida, isA<RutaPaneles>());
      final paneles = leida as RutaPaneles;
      expect(paneles.principal.modulo, 'KJV2006');
      expect(paneles.principal.referencia, const Referencia('John', 3, 16));
      expect(paneles.resto, hasLength(1));
      expect(paneles.resto.single.modulo, 'CLARKE');

      // Y LA VUELTA ES IGUAL, que es lo que hace que recargar conserve las dos ventanas.
      expect(Rutas.escribir(paneles), '/leer/KJV2006/John.3.16/y/CLARKE/John.3.16');
    });

    test('un enlace con dos ventanas abre dos paneles', () async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16'));

      expect(n.paneles.cuantos, 2);
      expect(n.paneles.ids, <String>['KJV2006', 'CLARKE']);
      // Y EL QUE ESTA DELANTE ES EL PRIMERO DE LA RUTA, no el ultimo en abrirse. Sin esto,
      // `/leer/A/y/B` se abriria con B delante y la direccion --que empieza por A-- estaria
      // describiendo una ventana en la que se ve otra cosa.
      expect(n.paneles.idDelModulo, 'KJV2006');
    });

    test('traer el CLARKE al frente pone su identificador primero en la direccion',
        () async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16'));
      await n.ponerUnPanelAlFrente('CLARKE');

      // Y ES LA REGLA DEL SPEC DE PESTANAS, dicha de otra forma: "cuando hay dos paneles y
      // el de delante es el CLARKE, la URL lleva el identificador del de delante". Con la
      // direccion escribiendo siempre el primero, traer un panel al frente tiene que
      // reescribirla, y si no la reescribe la pestana y la barra dicen cosas distintas.
      expect(n.paneles.idDelModulo, 'CLARKE');
      expect(Rutas.escribir(n.ruta), '/leer/CLARKE/John.3.16/y/KJV2006/John.3.16');
    });

    test('cerrar un panel lo quita de la direccion y no lo vuelve a abrir', () async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16'));
      await n.cerrarUnPanel('CLARKE');

      expect(n.paneles.cuantos, 1);
      // Y LA DIRECCION **SE QUEDA EN UN PANEL Y NO EN UNA ROTA**: `/leer/KJV2006/...` y no
      // `/leer/KJV2006/.../y/` con un segmento vacio, que el parser rechaza.
      expect(Rutas.escribir(n.ruta), '/leer/KJV2006/John.3.16');

      // Y **NO SE VUELVE A ABRIR AL VOLVER A APLICAR LA RUTA**, que es el fallo que hace
      // que cerrar una ventana sea un boton que abre. La ruta se aplica dos veces seguidas,
      // que es lo que hace el historial del navegador.
      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16'));
      expect(n.paneles.cuantos, 1);
      expect(n.paneles.ids, <String>['KJV2006']);
    });

    test('cerrar el unico panel deja la biblioteca, no una lectura vacia', () async {
      final n = montarNavegadorConPaneles();
      addTearDown(n.dispose);

      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));
      await n.cerrarUnPanel('KJV2006');

      expect(n.paneles.cuantos, 0);
      expect(n.ruta, const RutaBiblioteca());
    });

    test('un enlace a un texto que no esta descarga avisa y no deja paneles', () async {
      final n = montarNavegadorConPaneles(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await n.setNewRoutePath(
        Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16'),
      );

      // Y **NO SE QUEDA CON MEDIO PANEL**: quien recibe un enlace con dos ventanas donde la
      // segunda no esta descarga se queda con la primera entera y un aviso, no con una
      // ventana partida. Volver a la biblioteca entera seria romper la lectura del texto
      // por un comentario que es un extra.
      expect(n.paneles.cuantos, 1);
      expect(n.paneles.ids, <String>['KJV2006']);
      expect(n.lector.leyendo, const Referencia('John', 3, 16));
    });
  });

  group('5. lo que se midio, y se comprueba con numeros', () {
    testWidgets('a 1440 px con dos textos cada columna tiene 68 caracteres', (t) async {
      // Y ESTA CIFRA **NO SE ESCRIBE EN LA PANTALLA**: sale de
      // [Medidas.panelesDeLecturaQueCaben], que decide cuantos panels hay por el ancho de
      // la columna. Aqui se comprueba que la regla da dos a 1440 --y por tanto que se
      // ven dos columnas--, y el numero de caracteres lo mide `test/medidas/`.
      expect(Medidas.panelesDeLecturaQueCaben(1440 - Medidas.anchoDelPanelDeHerramientas), 2);
      // Y TRES SOLO A PARTIR DE CIENTO NOVENTA, y es la misma cuenta: la diferencia entre
      // dos y tres es un ancho de columna, no un numero escrito en un sitio u otro.
      expect(Medidas.panelesDeLecturaQueCaben(1920 - Medidas.anchoDelPanelDeHerramientas), 3);
      // Y POR DEBAJO DE MIL CIEN **UNO**, con o sin panel de herramientas, que es el corte
      // que ya estaba medido para el panel lateral y que aqui no se inventa otro.
      expect(Medidas.panelesDeLecturaQueCaben(834), 1);
      expect(Medidas.panelesDeLecturaQueCaben(360), 1);
    });
  });
}