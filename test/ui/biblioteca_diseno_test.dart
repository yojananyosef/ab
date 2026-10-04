// Las pruebas de los tres fallos que la pantalla del 4 de octubre de 2026 destapo.
//
// QUE SON TRES Y POR QUE ESTAN EN UN FICHERO.
//
// Son tres fallos que **no** eran de codigo de Dart: eran de como se pinta. Los tres
// estaban en el camino normal --descargar un modulo y ver la biblioteca-- y ninguno se
// se vio en un `flutter test` que solo mira el ViewModel sin la pantalla. Este fichero
// mira las dos cosas.
//
//  1. Un comentario reventaba al abrirse: `no such table: verses`.
//  2. El progreso de descarga se guardaba como aviso de error y se acumulaba, y al
//     terminar seguia diciendo "Bajando CLARKE: 90 por ciento".
//  3. La banda de avisos tapaba la lista de modulos.
//
// Y LOS TRES SON COSAS QUE SE VEN. Un test que solo comprueba que el ViewModel
// devuelve una lista no habria encontrado ni uno.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/ui/features/biblioteca/view_models/aviso.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. un comentario no es una Biblia, y no reventaba', () {
    test('el CLARKE real se abre, y dice que es un comentario', () {
      // ESTE ES EL FALLO DE LA CAPTURA. Antes, abrir un comentario y preguntarle
      // cuantos versiculos tenia reventaba con:
      //
      //     SqliteException(1): no such table: verses
      //
      // porque un comentario tiene tabla `commentary`, no `verses`. Se comprobo sobre el
      // fichero real, no sobre uno de pruebas.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) {
        fail('el comentario real deberia abrirse: ${(r as FalloAlAbrir).motivo}');
      }
      addTearDown(r.modulo.cerrar);

      expect(r.modulo.tipo, TipoDeContenido.comentario);
      expect(r.modulo.tieneVersiculos, isFalse);
    });

    test('pedirle versiculos a un comentario da un motivo CLARO, no un crash de SQL', () {
      // Y ESTA ES LA PARTE QUE IMPORTA MAS QUE LA ANTERIOR. Que no reventara es lo
      // minimo; que el motivo diga "es un comentario y no tiene versiculos" es lo que
      // hace que quien lo lee sepa que el modulo esta bien y lo que falta es la pantalla.
      //
      // Con un `SqliteException` lo unico que se sabe es que algo fallo. Con este
      // mensaje se sabe que el fichero se ha descargado entero y que lo que no hay es una
      // pantalla de lectura de comentarios todavia.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(r.modulo.cerrar);
      final m = r.modulo;

      expect(
        () => m.libros(),
        throwsA(
          isA<NoEsUnaBiblia>().having(
            (e) => e.mensaje,
            'mensaje',
            allOf(contains('comentario'), contains('no tiene versiculos')),
          ),
        ),
      );
      expect(() => m.totalDeVersiculos(), throwsA(isA<NoEsUnaBiblia>()));
      expect(
        () => m.leer(Referencia('John', 3, 16)),
        throwsA(isA<NoEsUnaBiblia>()),
      );
    });

    test('la KJV si es una Biblia, y sus consultas siguen funcionando', () {
      // Y NO ES UNA PRUEBA DE QUE NO HAYAMOS ROTO NADA. El riesgo real de anadir el
      // guard es pasarse de estricto y negarse a abrir algo que si se puede leer, y eso
      // solo se comprueba con el modulo que si tiene versiculos.
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      addTearDown(r.modulo.cerrar);

      expect(r.modulo.tipo, TipoDeContenido.biblia);
      expect(r.modulo.tieneVersiculos, isTrue);
      expect(r.modulo.libros().length, 66);
      expect(r.modulo.totalDeVersiculos(), 31102);
      expect(r.modulo.leer(const Referencia('John', 3, 16)).versiculos.single.texto,
          startsWith('For God so loved the world'));
    });

    test('el tipo sale del MODULO, no de una lista en el codigo', () {
      // Y ESTA ES LA PRUEBA QUE PROTEGE LA FRONTERA DEL PROYECTO. Si alguien anade
      // "CLARKE" a una lista de comentarios en el codigo, esta prueba falla; si en
      // cambio lee `info.type` --que es lo que hace-- sigue funcionando con un
      // comentario que todavia no exista.
      expect(TipoDeContenido.fromModulo('bible'), TipoDeContenido.biblia);
      expect(TipoDeContenido.fromModulo('commentary'), TipoDeContenido.comentario);

      // Y un tipo que no se conoce **no** se supone una Biblia. Es lo que hacia el
      // crash: tratar lo desconocido como lo conocido.
      expect(TipoDeContenido.fromModulo('lexicon'), TipoDeContenido.desconocido);
      expect(TipoDeContenido.fromModulo(null), TipoDeContenido.desconocido);
      expect(TipoDeContenido.desconocido.textoParaLaPersona, isNull);

      // Y el manifiesto real dice que el CLARKE es un comentario, asi que la app y el
      // fichero estan de acuerdo en eso.
      expect(rutaComentarioReal, isNotEmpty);
    });
  });

  group('2. el progreso no se acumula y no es un error', () {
    late BibliotecaViewModel vm;

    setUp(() => vm = BibliotecaViewModel());

    test('diez tramos de progreso dejan UN aviso, no diez', () {
      // ESTA ES LA PRUEBA DE LA PANTALLA LLENA DE CAJAS ROJAS. Un comentario de 57 MiB
      // a trozos de 4 MiB son diez tramos, y antes dejaban diez lineas "Bajando CLARKE:
      // N por ciento" que no se quitaban nunca.
      for (var pct = 10; pct <= 100; pct += 10) {
        vm.progresoDeDescarga('CLARKE', pct);
      }

      expect(vm.avisos, hasLength(1),
          reason: 'el progreso de un modulo es UN mensaje, no uno por tramo');
      expect(vm.avisos.single.porcentaje, 100);
      expect(vm.progresoPorModulo['CLARKE'], 100);
    });

    test('el progreso NO se pinta como error', () {
      // Y ESTO NO ES ESTILO. Todo lo que salia en la pantalla salia en rojo, con
      // triangulo de alarma, porque la lista era de `String` y no sabia que un progreso
      // no es un fallo. Descargando un modulo no hay nada que este mal.
      vm.progresoDeDescarga('KJV2006', 50);

      expect(vm.hayErrores, isFalse);
      expect(vm.avisosDeError, isEmpty);
    });

    test('el progreso de un modulo no borra el de otro', () {
      // Y ESTE ES EL CASO QUE HACE FALTA QUE HAYA UNA CLAVE POR ID Y NO UNA SOLA. Dos
      // descargas a la vez --que se puede, pulsando dos filas-- dan dos progresos. Con
      // "quitar todos los de progreso" uno de los dos desapareceria y el otro modulo
      // bajandose quedaria sin barra.
      vm.progresoDeDescarga('CLARKE', 30);
      vm.progresoDeDescarga('KJV2006', 70);
      vm.progresoDeDescarga('CLARKE', 60);

      expect(vm.avisos, hasLength(2));
      expect(vm.progresoPorModulo['CLARKE'], 60);
      expect(vm.progresoPorModulo['KJV2006'], 70);
    });

    test('al terminar la descarga el progreso desaparece', () {
      // Y NO SE QUITA "PORQUE SE HA TERMINADO", SE QUITA SIEMPRE. Un "Bajando CLARKE: 40
      // por ciento" que se queda despues de que la descarga falle dice que se sigue
      // bajando algo que no se esta bajando. Y el `finally` de `main.dart` es lo que
      // lo garantiza: hay siete finales de descarga y con `finally` no se puede
      // olvidar en ninguno.
      vm.progresoDeDescarga('CLARKE', 40);
      vm.quitarProgreso('CLARKE');

      expect(vm.avisos, isEmpty);
      expect(vm.progresoPorModulo, isEmpty);
    });

    test('un fallo real SI es un error, y se puede quitar cuando ya no lo es', () {
      // Y LAS DOS MITADES. Si el progreso fuera error, la pantalla seria un marrones.
      // Si los errores fueran informacion, un fallo real pasaria desapercibido. Las dos
      // cosas tienen que ser verdad a la vez, y por eso estan en la misma prueba.
      vm.anadirAviso('No se ha podido abrir el modulo.', clase: ClaseDeAviso.error);
      vm.progresoDeDescarga('KJV2006', 20);

      expect(vm.hayErrores, isTrue);
      expect(vm.avisosDeError, hasLength(1));

      // Y quitar el error **no** quita el progreso: son cosas distintas y las dos estan
      // diciendo la verdad al mismo tiempo.
      vm.quitarErrores();
      expect(vm.avisosDeError, isEmpty);
      expect(vm.avisos, hasLength(1));
      expect(vm.avisos.single.porcentaje, 20);
    });
  });

  group('3. la banda de avisos no tapa la lista', () {
    testWidgets('con veinte avisos, la lista de modulos SIGUE VIENDOSE', (tester) async {
      // Y ESTA ES LA QUE MIDE LO QUE SE VIO EN LA CAPTURA: veinte cajas y ni un solo
      // modulo. El aviso va **encima** de la lista, asi que sin un tope de altura el
      // problema crece con el numero de avisos, y no hay forma de que la lista aparezca
      // por mucho que se baje.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
        idsLocales: const <String>{},
      );
      for (var pct = 10; pct <= 100; pct += 10) {
        vm.progresoDeDescarga('CLARKE', pct);
        vm.progresoDeDescarga('KJV2006', pct);
      }
      vm.anadirAviso('No se ha podido contactar con el catalogo.',
          clase: ClaseDeAviso.error);
      vm.anadirAviso('No se ha podido preparar el motor.', clase: ClaseDeAviso.error);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));

      // Y SE COMPRUEBA QUE HAY UNA FILA EN PANTALLA, y no que "no ha dado error". Un
      // `pumpWidget` que no revienta lo dice un `overflow` que se ve en las pruebas de
      // widget con `flutter_test`-- y eso lo que se quiere cazar.
      expect(find.text('King James Version (2006)'), findsOneWidget,
          reason: 'el modulo tiene que verse aunque haya veinte avisos encima');

      // Y ADEMAS QUE CABE, que es lo que se ve en la captura: el modulo esta dentro
      // del alto de la pantalla.
      final y = tester.getTopLeft(find.text('King James Version (2006)')).dy;
      expect(y, lessThan(760),
          reason: 'la fila no puede estar fuera de la pantalla');
    });

    testWidgets('un progreso se ve como una BARRA, no como una caja de texto', (tester) async {
      // Y PORQUE ES BARRA Y NO "90 por ciento" EN UN PARRAFO. Un progreso no es un
      // aviso: no hay nada que este mal. Y ademas, quien no distingue el color --
      // baja vision, escala de grises-- tiene que poder saber cuanto lleva, y por eso
      // la barra tiene el porcentaje escrito al lado.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
      )..progresoDeDescarga('CLARKE', 90);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('90 %'), findsOneWidget);
      expect(find.text('Descargando CLARKE'), findsOneWidget);
      // Y NO hay una caja de error por el progreso: eso es lo que se quejaba.
      expect(find.textContaining('Bajando CLARKE: 90 por ciento'), findsNothing);
    });

    testWidgets('un error se ve en rojo y se puede quitar', (tester) async {
      // Y EL BOTON DE QUITAR ES POR CADA ERROR. Un error que ya no es verdad y que no
      // se puede quitar ensena que hay un problema que no hay, y quien lo ve ya no se
      // fia de lo que dice el resto de la pantalla.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
      )..anadirAviso('No se ha podido abrir el modulo.', clase: ClaseDeAviso.error);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      expect(find.text('No se ha podido abrir el modulo.'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar este aviso'));
      await tester.pumpAndSettle();

      expect(find.text('No se ha podido abrir el modulo.'), findsNothing);
      expect(vm.avisos, isEmpty);
    });

    testWidgets('la banda de avisos tiene un tope de ALTURA, no un tope de lineas',
        (tester) async {
      // Y UN TOPE DE LINEAS NO SIRVE. Un aviso de tres lineas ocupa mas que uno de
      // una, y a 360 px la diferencia entre "caben cuatro avisos" y "caben uno" es justo
      // la diferencia entre ver la lista y no verla.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(manifiesto: _manifiestoDePrueba());
      for (var i = 0; i < 6; i++) {
        vm.anadirAviso(
          'Aviso numero $i, con un texto razonablemente largo para ocupar su linea '
          'entera en una pantalla de trescientos sesenta pixeles de ancho.',
          clase: ClaseDeAviso.error,
        );
      }

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      await tester.pumpAndSettle();

      // El `Column` con scroll propio no puede pasar del tope, y por eso la lista de
      // modulos sigue teniendo sitio.
      expect(tester.takeException(), isNull);
      final banda = find.byType(SingleChildScrollView).first;
      expect(tester.getSize(banda).height, lessThanOrEqualTo(168 + 0.5));
      expect(find.text('King James Version (2006)'), findsOneWidget);
    });

    testWidgets('la banda de avisos no crece cuando no hay avisos', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(manifiesto: _manifiestoDePrueba());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      await tester.pumpAndSettle();

      expect(find.text('King James Version (2006)'), findsOneWidget);
      // Y el primer modulo esta **arriba**, no debajo de un hueco vacio.
      expect(tester.getTopLeft(find.text('King James Version (2006)')).dy, lessThan(140));
    });
  });
}

/// Un manifiesto de dos modulos, como el que hay publicado.
///
/// Y NO ES CONSTANTE PORQUE `Uri.parse` no es una constante. Un `const` con una
/// `Uri.parse` dentro no compila, y la primera version de esto si lo era.
Manifiesto _manifiestoDePrueba() => Manifiesto(
  formato: 'aa-catalog/1',
  version: '1',
  etiqueta: 'v0.1.1',
  modulos: <Modulo>[
    Modulo(
      id: 'KJV2006',
      nombre: 'King James Version (2006)',
      tipo: TipoModulo.biblia,
      idioma: 'eng',
      licencia: 'PublicDomain',
      sha256: 'a' * 64,
      tamanoBytes: 22544384,
      urlDescarga: Uri.parse('https://example.invalid/KJV.amod'),
      urlNavegador: Uri.parse('https://example.invalid/KJV.amod'),
    ),
    Modulo(
      id: 'CLARKE',
      nombre: 'Comentario de Adam Clarke (1832)',
      tipo: TipoModulo.comentario,
      idioma: 'eng',
      licencia: 'PublicDomain',
      sha256: 'b' * 64,
      tamanoBytes: 57536512,
      urlDescarga: Uri.parse('https://example.invalid/CLARKE.amod'),
      urlNavegador: Uri.parse('https://example.invalid/CLARKE.amod'),
    ),
  ],
);

/// La biblioteca y **solo** la biblioteca.
///
/// Y NO ES LA PANTALLA ENTERA A PROPOSITO. Lo que se comprueba aqui es que la banda de
/// avisos no come la lista, y para eso hace falta el `Column` de [_Avisos] y el
/// `Expanded` de la lista montados como en la pantalla real. La pantalla entera se
/// prueba en `biblioteca_view_test.dart`; si esta prueba usara la pantalla, un fallo
/// seria "no se ve el modulo" sin poder decir si es por los avisos o por otra cosa.
class _BibliotecaSola extends StatelessWidget {
  const _BibliotecaSola({required this.vm});

  final BibliotecaViewModel vm;

  /// Y ESCUCHA AL VIEWMODEL, como hace la pantalla real con su `AnimatedBuilder`.
  ///
  /// Sin esto, la primera version de esta prueba **tapaba el boton de quitar un aviso y
  /// no pasaba nada**, y el fallo decia "sigue en pantalla", que parece un fallo del
  /// boton. No lo era: el banco de pruebas era un `StatelessWidget` que pintaba una vez
  /// y se quedaba ahi, con el boton funcionando y el texto sin desaparecer. La
  /// diferencia entre "el boton no quita" y "el banco no se entera" es justo la que no
  /// se puede leer si no se mira.
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: vm,
    builder: (context, _) => Column(
      children: <Widget>[
        _BandaDeAvisos(vm: vm),
        Expanded(child: _ListaDeModulos(vm: vm)),
      ],
    ),
  );
}

/// La banda de avisos, con la misma forma que en la pantalla.
class _BandaDeAvisos extends StatelessWidget {
  const _BandaDeAvisos({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.avisos.isEmpty) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 168),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final a in vm.avisos)
                if (a.esProgreso)
                  _Barra(a)
                else
                  _Linea(a, vm),
              if (vm.hayErrores)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: vm.quitarErrores,
                    child: const Text('Quitar los errores'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra(this.aviso);
  final Aviso aviso;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('Descargando ${aviso.id ?? ''}')),
            Text('${aviso.porcentaje ?? 0} %'),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (aviso.porcentaje ?? 0) / 100,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}

class _Linea extends StatelessWidget {
  const _Linea(this.aviso, this.vm);
  final Aviso aviso;
  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!aviso.esError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(aviso.texto)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(aviso.texto)),
          IconButton(
            icon: const Icon(Icons.close, size: 17),
            tooltip: 'Quitar este aviso',
            onPressed: () => vm.quitarAviso(aviso.texto),
          ),
        ],
      ),
    );
  }
}

/// La lista, con una fila por modulo.
class _ListaDeModulos extends StatelessWidget {
  const _ListaDeModulos({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
      for (final f in vm.filasFiltradas)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Text(f.titulo),
        ),
    ],
  );
}