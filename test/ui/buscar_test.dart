// Buscar en el texto abierto.
//
// QUE NO HAY AQUI. Que la consulta funcione ya lo comprueba
// `test/data/modulo_repository_test.dart` contra el KJV real. Aqui esta lo que es de la
// busqueda: la ruta, el ViewModel y lo que se ve.
//
// Y LOS NUMEROS ESTAN MEDIDOS sobre el fichero de verdad el 5 de octubre de 2026:
// "begotten" en 26 versiculos, "God" en 4.140, "propitiation" en 3 del KJV y 15 del
// CLARKE, y Juan 3:16 son 141 caracteres.

import 'package:ab/app/navegador.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/busqueda/view_models/busqueda_view_model.dart';
import 'package:ab/ui/features/busqueda/views/busqueda_view.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. la ruta', () {
    test('la palabra va codificada, y con espacios', () {
      // Y CON ESPACIOS Y CON UNA BARRA, que es lo que rompe una ruta escrita a mano.
      // "in the world" y "in/that" son palabras que alguien escribe de verdad en un
      // buscador de Biblia, y las dos tienen que volver a salir iguales.
      for (final palabra in <String>[
        'propitiation',
        'in the world',
        'in/that',
        'a_b',
        '100%',
        'solo el Hijo',
      ]) {
        final ruta = Rutas.escribir(RutaBusqueda('KJV2006', palabra));
        expect(Rutas.leer(ruta), RutaBusqueda('KJV2006', palabra),
            reason: 'la palabra "$palabra" no vuelve a ser ella misma');
        expect(ruta, contains('/buscar/KJV2006/'));
      }
    });

    test('con barra final es la pantalla vacia; sin ella, no se entiende', () {
      // Y LA DIFERENCIA ES UNA BARRA, y dice algo: con barra final no hay palabra
      // todavia, que es lo que escribe la lupa; sin ella, la ruta esta a medias.
      expect(Rutas.leer('/buscar/KJV2006/'), RutaBusqueda('KJV2006', ''));
      expect(Rutas.leer('/buscar/KJV2006'), isA<RutaDesconocida>());
      // Y UN ESPACIO CODIFICADO TAMBIEN ES PALABRA VACIA, y no una palabra de un espacio.
      expect(Rutas.leer('/buscar/KJV2006/%20'), RutaBusqueda('KJV2006', ''));
    });

    test('una ruta de busqueda no es una de lectura', () {
      final busqueda = Rutas.leer('/buscar/KJV2006/begotten');
      final lectura = Rutas.leer('/leer/KJV2006/John.3.16');

      expect(busqueda, isNot(lectura));
      expect(busqueda, isNot(equals(RutaBiblioteca())));
    });

    test('con prefijo de despliegue y con el hash', () {
      expect(
        Rutas.leer('/ab/buscar/KJV2006/begotten'),
        Rutas.leer('/#/buscar/KJV2006/begotten'),
      );
    });
  });

  group('2. el ViewModel', () {
    late ModuloAbierto modulo;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      addTearDown(modulo.cerrar);
    });

    test('abrir NO busca, y la palabra queda puesta', () {
      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);
      vm.abrir(_Envuelto(modulo));

      // Y ESTO ES UNA DECISION Y NO UNA OMISION. Una ruta de busqueda se abre con la
      // palabra puesta y sin resultados: entrar en un enlace trae 200 lineas de golpe sin
      // que nadie las haya pedido, y quien solo quiere pulsar "buscar" las tiene.
      expect(vm.estado, EstadoDeBusqueda.sinBuscar);
      expect(vm.busqueda.sinBuscar, isTrue);
    });

    test('busca, y los numeros son los del fichero real', () async {
      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);
      vm.abrir(_Envuelto(modulo));

      await vm.buscar('begotten');

      expect(vm.estado, EstadoDeBusqueda.conResultados);
      expect(vm.busqueda.total, 26, reason: 'medido sobre el KJV de verdad');
      expect(vm.hayResultados, isTrue);
      // Y ORDENADOS POR LIBRO, CAPITULO Y VERSICULO, que es el orden de la consulta y
      // **NO** el de las cadenas.
      //
      // Y AQUI ESTA UNA DIFERENCIA REAL Y NO UNA SUTILEZA: `ORDER BY chapter` ordena
      // 2 antes que 11, y ordenar los textos los pone al reves --"1Corinthians.11.1" por
      // delante de "1Corinthians.2.1"-. Ordenarlos por texto en una prueba daria verde
      // con una consulta mal ordenada, y quien lee veria los capitulos desordenados.
      final refs = <Referencia>[for (final r in vm.busqueda.resultados) r.referencia];
      final ordenados = <Referencia>[...refs]
        ..sort((a, b) {
          final porLibro = a.libro.compareTo(b.libro);
          if (porLibro != 0) return porLibro;
          if (a.capitulo != b.capitulo) return a.capitulo - b.capitulo;
          return (a.versiculo ?? 0) - (b.versiculo ?? 0);
        });
      expect(refs, orderedEquals(ordenados));
      expect(refs.first, const Referencia('1Corinthians', 4, 15));
    });

    test('sin resultados NO es lo mismo que sin buscar', () async {
      // Y LA DIFERENCIA ES LA QUE PERMITE DECIR "busca dos letras" Y NO MENTIR.
      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);
      vm.abrir(_Envuelto(modulo));

      await vm.buscar('xyzzy');
      expect(vm.estado, EstadoDeBusqueda.sinResultados);
      expect(vm.busqueda.sinBuscar, isFalse, reason: 'si se busco');

      await vm.buscar('x');
      expect(vm.estado, EstadoDeBusqueda.sinBuscar,
          reason: 'una letra no busca, y decir "no hay resultados" seria mentir');
    });

    test('un modulo que revienta al buscar no tumba la pantalla', () async {
      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);
      vm.abrir(const _QueRevienta());

      await vm.buscar('begotten');

      expect(vm.estado, EstadoDeBusqueda.fallo);
      expect(vm.motivoDelFallo, isNotEmpty);
      // Y NO SE QUEDA CON LOS RESULTADOS DE ANTES. Un fallo que deja la lista anterior
      // puesta parece una busqueda nueva con los mismos resultados.
      expect(vm.busqueda.resultados, isEmpty);
    });

    test('sin modulo abierto es un fallo que lo dice', () async {
      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);

      await vm.buscar('begotten');

      expect(vm.estado, EstadoDeBusqueda.fallo);
      expect(vm.motivoDelFallo, contains('No hay ningun texto abierto'));
    });
  });

  group('3. la pantalla', () {
    late ModuloAbierto modulo;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      addTearDown(modulo.cerrar);
    });

    Future<BusquedaViewModel> montar(
      WidgetTester tester, {
      double ancho = 360,
      List<Referencia>? pulsados,
    }) async {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BusquedaViewModel();
      addTearDown(vm.dispose);
      vm.abrir(_Envuelto(modulo));

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: BusquedaView(
            viewModel: vm,
            alPulsarResultado: (r) => pulsados?.add(r),
            alVolver: () {},
            alBuscar: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return vm;
    }

    testWidgets('sin buscar, dice que escriba algo y NO dice "sin resultados"',
        (tester) async {
      final vm = await montar(tester);

      expect(find.textContaining('Dos letras o mas'), findsOneWidget);
      expect(find.textContaining('no sale'), findsNothing);
      expect(vm.estado, EstadoDeBusqueda.sinBuscar);
    });

    testWidgets('los resultados salen con su versiculo y su extracto', (tester) async {
      final vm = await montar(tester);
      await vm.buscar('begotten');
      await tester.pumpAndSettle();

      expect(find.textContaining('26 coincidencias'), findsOneWidget);
      // Y LA LISTA EMPIEZA POR EL PRIMER RESULTADO **DE LA CONSULTA**, que es
      // 1 Corintios 4:15 y no Juan 3:16. Y esto no es un detalle de la prueba: en el
      // KJV "begotten" sale en 26 versiculos y Juan 3:16 es el decimoctavo.
      expect(find.text('1 Corintios 4:15'), findsOneWidget);
      // Y EL CAPITULO AL LADO, porque "Juan 3:16" y "1 Juan 2:2" empiezan igual y en una
      // lista de "Juan ..." uno no sabe cual es cual.
      expect(find.text('cap. 4'), findsWidgets);
    });

    testWidgets('avisa de que busca TEXTO y no palabras', (tester) async {
      final vm = await montar(tester);
      await vm.buscar('propitiation');
      await tester.pumpAndSettle();

      // Y ESTA FRASE ESTA PORQUE MEDIDO: "pro" sale en 2.890 versiculos del KJV, y
      // muchisimos son "propitiation" o "prophets". Quien busca "pro" y ve 200 lineas de
      // "propitiation" sin esta frase piensa que el buscador no funciona.
      expect(find.textContaining('tambien sale en'), findsOneWidget);
    });

    testWidgets('sin resultados, dice la palabra que se busco', (tester) async {
      final vm = await montar(tester);
      await vm.buscar('xyzzy');
      await tester.pumpAndSettle();

      expect(find.textContaining('"xyzzy" no sale'), findsOneWidget);
      expect(find.textContaining('coincidencias'), findsNothing,
          reason: 'cero coincidencias no se announces como si fueran un numero');
    });

    testWidgets('con mas de 200, dice cuantas hay y cuales se enseñan', (tester) async {
      final vm = await montar(tester);
      await vm.buscar('God');
      await tester.pumpAndSettle();

      expect(find.textContaining('4.140 coincidencias'), findsOneWidget);
      expect(find.textContaining('primeras 200'), findsOneWidget);
    });

    testWidgets('pulsar un resultado abre ESE pasaje', (tester) async {
      final pulsados = <Referencia>[];
      final vm = await montar(tester, pulsados: pulsados);
      await vm.buscar('begotten');
      await tester.pumpAndSettle();

      // Y SE PULSA UNO QUE ESTA **EN PANTALLA**. Los 26 resultados no caben en 900 px y
      // una `ListView` solo construye lo que se ve, asi que buscar "Juan 3:16" en la
      // lista daria 0 elementos: no es que el resultado no exista, es que no esta
      // construido. La primera version de esta prueba lo buscaba por su nombre y fallaba
      // por eso.
      await tester.tap(find.text('1 Corintios 4:15'));
      await tester.pumpAndSettle();

      expect(pulsados, hasLength(1));
      expect(pulsados.single, const Referencia('1Corinthians', 4, 15));
    });

    testWidgets('a 360 px un resultado largo no sale del borde', (tester) async {
      // Y CON EL RESULTADO MAS LARGO QUE SE PUEDE PEDIR, que no es un caso inventado: el
      // extracto son 120 caracteres y el texto va a 14 px.
      final vm = await montar(tester);
      await vm.buscar('God');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Y UN RESULTADO REAL DE LA LISTA, no un `Text` cualquiera. Con "God" la lista
      // emppieza por 1Cronicas 4:10, y su extracto son 120 caracteres: es el caso largo
      // de verdad, no uno inventado.
      final fila = find.widgetWithText(ListTile, '1 Crónicas 4:10');
      expect(fila, findsOneWidget);
      // Y SE COGE EL **MAS LARGO** de los `Text` de la fila, y no el ultimo. En un
      // `ListTile` con titulo, subtitulo y etiqueta, el ultimo es "cap. 4" --seis
      // caracteres--, y la primera version de esta comprobacion fallaba con `6 > 60`
      // mirando justo la etiqueta en vez del extracto.
      final largos = <String>[
        for (final w in tester.widgetList<Text>(
          find.descendant(of: fila, matching: find.byType(Text)),
        ))
          if (w.data != null) w.data!,
      ]..sort((a, b) => b.length - a.length);
      expect(largos.first.length, greaterThan(60),
          reason: 'un extracto de verdad, no una linea corta');
    });
  });

  group('4. el enrutador', () {
    late BibliotecaViewModel biblioteca;
    late LectorViewModel lector;
    late List<String> abiertos;

    setUp(() {
      biblioteca = BibliotecaViewModel();
      lector = LectorViewModel();
      abiertos = <String>[];
    });

    NavegadorAb montar({required Set<String> descargados}) {
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
        idsLocales: descargados,
        hashesLocales: <String, String>{for (final id in descargados) id: 'a' * 64},
      );

      return NavegadorAb(
        biblioteca: biblioteca,
        lector: lector,
        resaltados: ResaltadosViewModel(),
        // Y `abrir` RESPETA LO DESCARGADO, y no es un detalle del arnes: en la
        // aplicacion es `_abrirModulo`, que devuelve null si el fichero no esta. Un
        // arnés que abre el fichero siempre haria pasar el caso de "el texto no esta
        // descargado", y esa prueba --que es la que importa de este grupo-- pasaria sin
        // comprobar nada.
        abrir: (id, referencia) async {
          if (!descargados.contains(id)) return null;
          final ruta = id == 'CLARKE' ? rutaComentarioReal : rutaBibliaReal;
          final apertura = ModuloAbierto.abrir(ruta, id: id);
          if (apertura is! Abierto) return null;
          abiertos.add(id);
          return apertura.modulo;
        },
      );
    }

    testWidgets('una ruta de busqueda abre el texto y NO busca', (tester) async {
      // Y LA PALABRA ESTA EN EL CAMPO Y **NO HAY RESULTADOS**. Las dos mitades: ponerla
      // sin buscarla es lo que hace util un enlace, y no buscarla es lo que evita que
      // entrar en uno traiga 200 lineas de golpe.
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaBusqueda('KJV2006', 'begotten'));
      await tester.pumpAndSettle();

      expect(lector.idDelModulo, 'KJV2006');
      expect(find.byType(BusquedaView), findsOneWidget);
      // Y LA PALABRA ESTA EN EL CAMPO, escrita, y sin resultados. Quien recibe el enlace
      // ve de que va sin tener que escribirla, y quien no quiere buscarla no gasta
      // 26 consultas en hacerlo.
      expect(find.text('begotten'), findsOneWidget);
      expect(find.textContaining('coincidencias'), findsNothing);
      // Y EL TEXTO **SIGUE ABIERTO**. Buscar no es dejar de leer: volver de la busqueda
      // no puede costar volver a abrir 22 MiB.
      expect(lector.modulo, isNotNull);
    });

    testWidgets('buscar desde la pantalla pone los resultados y la URL', (tester) async {
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaBusqueda('KJV2006', ''));
      await tester.pumpAndSettle();
      await n.buscar('begotten');
      await tester.pumpAndSettle();

      expect(find.textContaining('26 coincidencias'), findsOneWidget);
      expect(Rutas.escribir(n.ruta), '/buscar/KJV2006/begotten');
    });

    testWidgets('volver de la busqueda vuelve AL PASAGE, con el comentario',
        (tester) async {
      // Y ESTO ES LO QUE HACE QUE BUSCAR NO SEA IRSE. Quien busca desde Juan 3:16
      // vuelve a Juan 3:16, y con el CLARKE al lado si lo tenia, porque buscar no quita
      // nada de lo que se estaba leyendo.
      final n = montar(descargados: <String>{'KJV2006', 'CLARKE'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();

      await n.buscarEnElTextoAbierto();
      await tester.pumpAndSettle();
      expect(find.byType(BusquedaView), findsOneWidget);
      expect(lector.idDelComentario, 'CLARKE', reason: 'no se cierra al buscar');

      await n.abrirDesdeLaBusqueda(const Referencia('John', 3, 16));
      await tester.pumpAndSettle();

      expect(find.byType(LectorView), findsOneWidget);
      expect(lector.idDelComentario, 'CLARKE');
      expect(lector.notasDe(16), isNotEmpty);
    });

    testWidgets('un resultado en el comentario busca en el comentario', (tester) async {
      // Y CON 15 RESULTADOS, medidos: "propitiation" sale en 15 notas del CLARKE y en
      // 3 versiculos del KJV. Una busqueda que devuelve 0 en un comentario de 19.742
      // notas seria un fallo de la consulta, no del texto.
      final n = montar(descargados: <String>{'KJV2006', 'CLARKE'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaBusqueda('CLARKE', 'propitiation'));
      await tester.pumpAndSettle();
      await n.buscar('propitiation');
      await tester.pumpAndSettle();

      expect(find.textContaining('15 coincidencias'), findsOneWidget);
      // Y EL PRIMER RESULTADO ES EL DEL FICHERO: 1 Corintios 4:13.
      expect(find.text('1 Corintios 4:13'), findsWidgets);
    });

    testWidgets('un texto que no esta descarga vuelve a la biblioteca', (tester) async {
      final n = montar(descargados: <String>{});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaBusqueda('KJV2006', 'begotten'));
      await tester.pumpAndSettle();

      expect(find.byType(BusquedaView), findsNothing);
      expect(lector.aviso, contains('no esta descargado'));
      expect(n.ruta, isA<RutaBiblioteca>());
      expect(abiertos, isEmpty);
    });

    testWidgets('volver a la biblioteca cierra el texto', (tester) async {
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaBusqueda('KJV2006', 'begotten'));
      await tester.pumpAndSettle();
      expect(lector.modulo, isNotNull);

      await n.irAHome();
      await tester.pumpAndSettle();

      expect(lector.idDelModulo, isNull);
    });
  });
}

/// Un modulo real envuelto en la interfaz que necesita la pantalla.
class _Envuelto implements ModuloBuscable {
  _Envuelto(this._modulo);

  final ModuloAbierto _modulo;

  @override
  Future<BusquedaEnElModulo> buscar(String palabra) async => _modulo.buscar(palabra);
}

/// Un modulo que revienta. Para comprobar que la pantalla no se cae.
class _QueRevienta implements ModuloBuscable {
  const _QueRevienta();

  @override
  Future<BusquedaEnElModulo> buscar(String palabra) async =>
      throw StateError('la base de datos ya no esta');
}

/// Un modulo del manifiesto, como lo declara el catalogo.
Modulo _modulo(String id, String nombre, TipoModulo tipo, int tamano) => Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: 'eng',
      licencia: 'PublicDomain',
      tamanoBytes: tamano,
      sha256: 'a' * 64,
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/$id'),
    );
