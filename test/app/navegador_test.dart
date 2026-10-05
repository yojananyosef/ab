// El enrutador: que pantalla va, que se pone en la barra, y que hace "atras".
//
// ============================================================================
// QUE SE COMPRUEBA AQUÍ Y QUE NO, Y POR QUE
// ============================================================================
//
// AQUI SE COMPRUEBA EL **INTERRUPTOR**: que tipo de cambio reporta el delegado, y por
// tanto si el framework va a escribirlo con `pushState` o con `replaceState`. Eso se
// puede comprobar en la maquina de Dart porque `RouteInformationProvider` es una
// clase publica a la que se le puede preguntar, y el tipo que recibe decide el
// `replace` que el SDK pasa a `SystemNavigator.routeInformationUpdated`.
//
// NO SE COMPRUEBA QUE EL NAVEGADOR OBEDEZCA. En la maquina de Dart no hay
// `history.length`. Que `pushState` anada una entrada y que `replaceState` no lo haga
// se comprueba en el grupo 8, con Chrome de verdad. Ver el `README` de por que son dos
// sitios y no uno.
//
// ============================================================================
// Y UN DETALLE QUE PARECE UN TRUCO Y NO LO ES
// ============================================================================
//
// El tipo que se comprueba **no es el que el framework se queda**, sino el ultimo que
// el delegado ha reportado, guardado en `_tipoReportado`. Es verdad que el framework
// recibe el mismo: se le pasa a `RouteInformationProvider.routerReportsNewRouteInformation`
// con el mismo `tipo.paraElFramework`. Comprobar el valor guardado y no el del
// proveedor es mas comodo, y no es mas debil: si los dos dejaran de coincidir, el
//unico cambio para que se note seria tocar el metodo que los escribe, que es una
// linea.

import 'package:ab/app/navegador.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/biblioteca/views/biblioteca_view.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

/// Un enrutador con un modulo real detras.
///
/// Y CON UN PROVEEDOR DE MENTIRA, que es lo que permite ver que tipo se reporta. El
/// proveedor de verdad --`PlatformRouteInformationProvider`-- llama a un metodo de
/// canal que en la maquina de Dart no llega a ningun sitio, asi que a traves de el no
/// se ve nada.
NavegadorAb montarNavegador({
  List<String>? abiertos,
  List<String>? noDescargados,
}) {
  final cuantosSeAbren = abiertos ?? <String>[];
  final sinDescargar = noDescargados ?? <String>[];
  final biblioteca = BibliotecaViewModel();
  final lector = LectorViewModel();

  return NavegadorAb(
    biblioteca: biblioteca,
    lector: lector,
    abrir: (id, referencia) async {
      if (sinDescargar.contains(id)) return null;
      final apertura = ModuloAbierto.abrir(rutaBibliaReal, id: id);
      if (apertura is! Abierto) {
        fail('no se ha podido abrir el modulo: ${(apertura as FalloAlAbrir).motivo}');
      }
      cuantosSeAbren.add(id);
      return apertura.modulo;
    },
    proveedor: _ProveedorDeMentira(),
  );
}

/// Un proveedor de rutas que solo anota lo que recibe.
///
/// Extiende [RouteInformationProvider] y no lo implementa a mano porque la clase base
/// es un [Listenable], y un `noSuchMethod` sobre un `Listenable` no compila: `addListener`
/// y `removeListener` son abstractas de verdad.
class _ProveedorDeMentira extends RouteInformationProvider {
  final List<({Uri uri, RouteInformationReportingType type})> recibido =
      <({Uri uri, RouteInformationReportingType type})>[];

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  RouteInformation get value => RouteInformation(uri: Uri.parse('/'));

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    recibido.add((uri: routeInformation.uri, type: type));
  }
}

void main() {
  group('7.4 arrancar desde la direccion', () {
    test('una ruta de lectura abre el texto y lee el pasaje', () async {
      final abiertos = <String>[];
      final n = montarNavegador(abiertos: abiertos);
      addTearDown(n.dispose);

      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16'));

      expect(n.currentConfiguration, const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      expect(abiertos, <String>['KJV2006']);
      expect(n.lector.estado, EstadoLecturaTexto.leyendo);
      // Y EL PASAJE TRAE EL CAPITULO **DESDE EL VERSICULO PEDIDO**, no un versiculo
      // suelto: Juan 3 va del 1 al 36 y desde el 16 son 21. La razon esta medida en una
      // captura a 360 px, donde el versiculo suelto era el 16 % de la pantalla. Ver la
      // nota de `leer` en `modulo_repository.dart`.
      expect(n.lector.pasaje!.versiculos.length, 21);
      expect(n.lector.pasaje!.versiculo(16), isNotNull);
      expect(n.lector.pasaje!.versiculo(15), isNull);
    });

    test('la biblioteca es la pantalla inicial', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);

      expect(n.currentConfiguration, const RutaBiblioteca());
      await n.setNewRoutePath(const RutaBiblioteca());
      expect(n.lector.estado, EstadoLecturaTexto.sinModulo);
    });

    test('un enlace a un texto que no esta descarga avisa y vuelve a la biblioteca', () async {
      final n = montarNavegador(noDescargados: <String>['CLARKE_commentary']);
      addTearDown(n.dispose);

      await n.setNewRoutePath(
        const RutaLectura('CLARKE_commentary', Referencia('John', 3)),
      );

      // Quedarse en una pantalla de lectura sin texto, con la direccion diciendo que se
      // esta leyendo Juan 3, es peor que volver a la biblioteca con un aviso.
      expect(n.currentConfiguration, const RutaBiblioteca());
      expect(n.lector.estado, EstadoLecturaTexto.sinModulo);
      expect(n.lector.aviso, isNotNull);
      expect(n.lector.aviso, contains('CLARKE_commentary'));
    });

    test('una ruta que no se entiende no cambia la pantalla', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);

      await n.setNewRoutePath(const RutaDesconocida('/lo-que-sea'));
      expect(n.currentConfiguration, const RutaBiblioteca());

      // Y lo mismo desde la lectura: se queda leyendo y avisa.
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));
      final estadoAntes = n.lector.leyendo;
      await n.setNewRoutePath(const RutaDesconocida('/otra'));
      expect(n.currentConfiguration, const RutaLectura('KJV2006', Referencia('John', 3)));
      expect(n.lector.leyendo, estadoAntes);
    });
  });

  group('7.5 push o replace', () {
    test('cambiar de capitulo es `navigate`, o sea `pushState`', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));

      await n.irA(const RutaLectura('KJV2006', Referencia('John', 4)));

      // Alguien que lee Juan 3, pasa a Juan 4 y pulsa "atras" quiere volver a Juan 3.
      expect(n.tipoReportado, RouteInformationReportingType.navigate);
      expect(n.ultimaRutaReportada, const RutaLectura('KJV2006', Referencia('John', 4)));
      expect(n.lector.leyendo, const Referencia('John', 4));
    });

    test('ir a un versiculo suelto tambien es `navigate`', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));

      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      expect(n.tipoReportado, RouteInformationReportingType.navigate);
    });

    test('cambiar de version es `neglect`, o sea `replaceState`', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3, 16)));

      await n.cambiarDeVersion('CLARKE_commentary');

      // ESTA ES LA TAREA 7.5: cambiar de version **no** entra en el historial.
      // "Atras" deshaceria el cambio de version y dejaria a alguien que solo queria
      // seguir leyendo en la misma traduccion otra vez en la anterior, con el mismo
      // gesto con el que se sigue leyendo.
      expect(n.tipoReportado, RouteInformationReportingType.neglect);
      expect(n.lector.leyendo, const Referencia('John', 3, 16),
          reason: 'y se sigue en el mismo pasaje');
    });

    test('ajustar a otra ruta es `neglect`', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));

      await n.ajustarA(const RutaLectura('KJV2006', Referencia('John', 4)));
      expect(n.tipoReportado, RouteInformationReportingType.neglect);
    });

    test('volver a la biblioteca es `navigate`', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));

      await n.irAHome();
      expect(n.tipoReportado, RouteInformationReportingType.navigate);
      expect(n.currentConfiguration, const RutaBiblioteca());
    });

    test('el enum traduce los dos valores a los del framework', () {
      // La traduccion en si misma, porque es donde esta el interruptor y donde un
      // cambio-equivocado seria silencioso: los dos tipos funcionan y hacen casi lo que
      // se quiere.
      expect(TipoDeCambioDeRuta.entrar.paraElFramework,
          RouteInformationReportingType.navigate);
      expect(TipoDeCambioDeRuta.ajustar.paraElFramework,
          RouteInformationReportingType.neglect);
      // Y **nunca** `none`, que es lo que haria `MaterialApp` sin esto.
      for (final tipo in TipoDeCambioDeRuta.values) {
        expect(tipo.paraElFramework, isNot(RouteInformationReportingType.none));
      }
    });

    test('una ruta que no se entiende no se reporta', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.irA(const RutaDesconocida('/lo-que-sea'));
      expect(n.tipoReportado, isNull,
          reason: 'no hay ningun sitio al que ir, y no se escribe nada en la barra');
      expect(n.currentConfiguration, const RutaBiblioteca());
    });

    test('la ruta que se reporta es la que se puede volver a leer', () async {
      final proveedor = _ProveedorDeMentira();
      final biblioteca = BibliotecaViewModel();
      final lector = LectorViewModel();
      final n = NavegadorAb(
        biblioteca: biblioteca,
        lector: lector,
        abrir: (id, ref) async => null,
        proveedor: proveedor,
      );
      addTearDown(n.dispose);

      await n.irA(const RutaBiblioteca());

      expect(proveedor.recibido, hasLength(1));
      expect(proveedor.recibido.single.uri.toString(), '/');
      // Y lo que se ha escrito en la barra se lee de vuelta como la misma ruta. Es lo
      // que hace que recargar conserve el pasaje.
      expect(Rutas.leer(proveedor.recibido.single.uri.toString()),
          const RutaBiblioteca());
    });
  });

  group('7.4 "atras"', () {
    test('leyendo, "atras" es la biblioteca y se resuelve aqui', () async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));

      final resuelto = await n.popRoute();

      expect(resuelto, isTrue);
      expect(n.currentConfiguration, const RutaBiblioteca());
      expect(n.lector.estado, EstadoLecturaTexto.sinModulo);
    });

    test('en la biblioteca, "atras" NO se resuelve y sale la aplicacion', () async {
      // Devolver `true` sin hacer nada dejaria la aplicacion en un estado en el que el
      // boton no responde, y eso se ve como que la app esta colgada.
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());

      expect(await n.popRoute(), isFalse);
      expect(n.currentConfiguration, const RutaBiblioteca());
    });

    test('"atras" cierra el texto abierto', () async {
      // Un `.amod` de 57 MiB abierto en la biblioteca es memoria que no vuelve sola en
      // un movil de gama baja, y quien esta en la biblioteca no esta leyendo.
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));
      expect(n.lector.modulo, isNotNull);

      await n.popRoute();
      expect(n.lector.modulo, isNull);
    });
  });

  group('abrir desde la biblioteca', () {
    test('abre Juan 1 y deja el texto abierto', () async {
      final abiertos = <String>[];
      final n = montarNavegador(abiertos: abiertos);
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.abrirDesdeLaBiblioteca('KJV2006');

      expect(abiertos, <String>['KJV2006']);
      expect(n.currentConfiguration, const RutaLectura('KJV2006', Referencia('John', 1)));
      expect(n.lector.estado, EstadoLecturaTexto.leyendo);
      // Juan 1 tiene 51 versiculos, que es lo que se lee al abrir.
      expect(n.lector.pasaje!.versiculos.length, 51);
    });

    test('si el modulo no se puede abrir, no cambia de pantalla', () async {
      final n = montarNavegador(noDescargados: <String>['CLARKE_commentary']);
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.abrirDesdeLaBiblioteca('CLARKE_commentary');

      expect(n.currentConfiguration, const RutaBiblioteca());
    });

    // Un caso de widget por separado, porque montar la pantalla entera tres veces en
    // el mismo `test` haria que la segunda，tapara la primera.
    testWidgets('en la biblioteca se ve la biblioteca', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());
      await _montar(n, t);

      expect(find.byType(BibliotecaView), findsOneWidget);
      expect(find.byType(LectorView), findsNothing);
    });

    testWidgets('leyendo se ve el lector, no la biblioteca', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaLectura('KJV2006', Referencia('John', 3)));
      await _montar(n, t);

      expect(find.byType(LectorView), findsOneWidget);
      expect(find.byType(BibliotecaView), findsNothing);
      expect(n.lector.estado, EstadoLecturaTexto.leyendo);
    });

    testWidgets('con una ruta de lectura sin texto, se ve la biblioteca', (t) async {
      // Una pantalla de lectura sin texto es una pantalla en blanco con un titulo, que
      // es peor que no tener nada.
      final n = montarNavegador(noDescargados: <String>['CLARKE_commentary']);
      addTearDown(n.dispose);
      await n.setNewRoutePath(
        const RutaLectura('CLARKE_commentary', Referencia('John', 3)),
      );
      await _montar(n, t);

      expect(find.byType(BibliotecaView), findsOneWidget);
      expect(find.byType(LectorView), findsNothing);
    });

    testWidgets('la pantalla esta dentro de un Navigator, y por el Overlay', (t) async {
      // El `Navigator` no esta para navegar --con una sola pagina no puede hacer
      // `pop`-- sino por el `Overlay` que necesita un `TextField`. Sin el, escribir en
      // el filtro de la biblioteca lanza "No Overlay widget found", y eso es lo que
      // paso cuando se quito.
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());
      await _montar(n, t);

      expect(find.byType(Navigator), findsOneWidget);
      expect(find.byType(Overlay), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}

/// Monta la pantalla que construye el enrutador.
///
/// Va con el tema de verdad, porque las pantallas leen `Theme.of(context)` al
/// construirse y con el tema por defecto darian error.
Future<void> _montar(NavegadorAb n, WidgetTester t) async {
  t.view.physicalSize = const Size(360, 640);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  // Y EL PROVEEDOR DE RUTAS TAMBIEN, y va con la ruta que ya tiene el enrutador.
  //
  // Sin el, `MaterialApp.router` se monta con la ruta por defecto --la barra del
  // navegador, que en una prueba es `/`-- y el `Router` llama enseguida a
  // `setNewRoutePath(biblioteca)`, que **borra** el pasaje que la prueba acaba de pedir.
  // La primera version de esta prueba no lo montaba y la pantalla salia con la
  // biblioteca en vez del lector, sin ninguna excepcion: el enrutador estaba bien y lo
  // que se habia montado era otra cosa.
  await t.pumpWidget(MaterialApp.router(
    theme: temaDeAb(),
    routerDelegate: n,
    routeInformationParser: const AnalizadorDeRuta(),
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation:
          RouteInformation(uri: Uri.parse(Rutas.escribir(n.currentConfiguration))),
    ),
  ));
  await t.pump();
}
