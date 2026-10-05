// Las palabras de Jesus en rojo, en pantalla.
//
// QUE SE COMPRUEBA AQUI Y DONDE NO. El **color** y el **interruptor**. Que el
// marcador `\\wj` existe y lo que cubre esta en `test/data/palabras_de_jesus_test.dart`,
// contra el fichero real.
//
// Y LA PRIMERA COMPROBACION DE TODAS ES LA MISMA DE SIEMPRE Y NO ES OPCIONAL: **el texto
// que se lee es exactamente el que tiene el modulo**, con el color puesto y sin el. Un
// lector que altera el texto que va a leer es un lector que no se puede citar, y el color
// es justo el sitio donde el fallo seria facil: partir el texto en `TextSpan` y volver a
// juntarlo es una operacion que parece que no puede fallar.
//
// MEDIDO SOBRE EL KJV REAL, con el que pintan estas pruebas:
//
//     Juan 3:16    25 de 25 palabras en rojo     (todo el versiculo es de Jesus)
//     Juan 3:29     0 de 32                      (todo es del narrador)
//     Juan 3:11    24 de 24
//     Salmos 23:1   0 de 14                      (el Antiguo Testamento no tiene nada)
//     palabras en rojo en todo el KJV   41.284 de 835.159, el 4,94 %

import 'package:ab/data/repositories/modulo_repository.dart';
import 'dart:async';
import 'dart:math' as maths;

import 'package:ab/data/services/almacenamiento.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/token_de_texto.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/lector/widgets/estilo_de_palabra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. el interruptor', () {
    test('de partida estan puestas, sin preguntar', () {
      // Y NO HAY UNA PREFERENCIA QUE HAYA QUE ACTIVAR. Quien abre una app de Biblia en la
      // que el dato esta espera las letras rojas, y una funcion escondida tras un
      // interruptor apagado es una funcion que no existe.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);

      expect(vm.mostrarPalabrasDeJesus, isTrue);
    });

    test('alterna, y avisa a quien esta escuchando', () {
      var avisos = 0;
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.addListener(() => avisos++);

      vm.alternarPalabrasDeJesus();
      expect(vm.mostrarPalabrasDeJesus, isFalse);
      expect(avisos, 1);

      vm.alternarPalabrasDeJesus();
      expect(vm.mostrarPalabrasDeJesus, isTrue);
      expect(avisos, 2);
    });

    test('se guarda, y al volver a abrir se lee', () async {
      // Y PORQUE GUARDA Y POR QUE ES UNA PREFERENCIA Y NO UNA NOTA. Una preferencia que
      // se pierde al recargar hay que volver a buscar cada vez; una nota es trabajo de la
      // persona y va a otra parte. `almacenamiento.dart` tiene el motivo de por que esa
      // diferencia lo es todo.
      final memoria = AlmacenamientoEnMemoria();

      final primero = LectorViewModel(almacenamientoDeLectura: memoria);
      addTearDown(primero.dispose);
      primero.alternarPalabrasDeJesus();
      await pumpEventQueue();
      expect(memoria.datos[clavePalabrasDeJesus], 'no');

      // Y UN VIEWMODEL NUEVO CON LA MISMA PREFERENCIA, que es lo que pasa al abrir la app
      // otra vez.
      final segundo = LectorViewModel(almacenamientoDeLectura: memoria);
      addTearDown(segundo.dispose);
      expect(segundo.mostrarPalabrasDeJesus, isTrue,
          reason: 'antes de leer, el valor de partida');

      await segundo.cargarPreferencias();
      expect(segundo.mostrarPalabrasDeJesus, isFalse);
    });

    test('el valor guardado es `si` o `no`, y se puede leer de un vistazo', () async {
      final memoria = AlmacenamientoEnMemoria();
      final vm = LectorViewModel(almacenamientoDeLectura: memoria);
      addTearDown(vm.dispose);

      vm.alternarPalabrasDeJesus();
      await pumpEventQueue();
      expect(memoria.datos[clavePalabrasDeJesus], 'no');

      vm.alternarPalabrasDeJesus();
      await pumpEventQueue();
      expect(memoria.datos[clavePalabrasDeJesus], 'si');
    });

    test('sin almacenamiento funciona igual, y solo no guarda', () async {
      // Y POR QUE EL ALMACENAMIENTO ES OPCIONAL. El lector se construye en 24 pruebas que
      // no traen almacenamiento, y no tienen por que traerlo. Un interruptor de color es
      // una preferencia: sin donde guardarla funciona y se pierde, que son dos toques.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);

      await vm.cargarPreferencias();
      expect(vm.mostrarPalabrasDeJesus, isTrue);
      vm.alternarPalabrasDeJesus();
      expect(vm.mostrarPalabrasDeJesus, isFalse);
    });

    test('un almacenamiento que no contesta NO rompe la lectura', () async {
      // Y ESTE ES EL FALLO QUE YA SE HA MEDIDO EN ESTE REPOSITORIO, aqui con otra
      // forma: en el navegador, `localStorage` puede quedarse esperando para siempre. Si
      // `cargarPreferencias` **no** atrapase la excepcion, la pantalla de lectura se
      // quedaria a medias por un interruptor de color.
      //
      // Y ESTA VEZ SI SE AVISA AL USUARIO, y en el catalogo no. Aqui lo que se ha perdido
      // es una preferencia --dos toques-- y un aviso en medio de Juan 3 no le sirve a
      // nadie. La diferencia es el coste de perderlo.
      // Y CON UN PLAZO DE DIEZ MILISEGUNDOS, para que la prueba no espere cinco segundos
      // a que una `Completer` que no se completa se avise. El plazo de verdad va en el
      // ViewModel, y aqui lo que se comprueba es que existe.
      final vm = LectorViewModel(
        almacenamientoDeLectura: _QueNoContesta(),
        plazoDeLectura: const Duration(milliseconds: 10),
      );
      addTearDown(vm.dispose);

      await vm.cargarPreferencias();
      expect(vm.mostrarPalabrasDeJesus, isTrue,
          reason: 'se queda en el valor de partida');

      // Y EL PLAZO ESTA PUESTO, que es lo unico que evita que esto sea una excepcion: sin
      // el, `leer` devuelve una promesa que no se resuelve jamas, el `try` no captura
      // nada y `cargarPreferencias` **se queda esperando para siempre**. En la pantalla
      // eso no se ve como un fallo, se ve como una app que a veces no abre.
      expect(plazoDePreferenciaPorDefecto, const Duration(seconds: 5));
    });
  });

  group('2. en pantalla', () {
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
      WidgetTester tester,
      Referencia referencia, {
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
            alCambiarDeVersion: (_) {},
          ),
        ),
      );
      vm.leer(referencia);
      await tester.pumpAndSettle();
    }

    /// El texto del versiculo tal cual lo pinta la pantalla.
    String pintado(WidgetTester tester, String textoDelModulo) {
      for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
        final t = rico.text.toPlainText();
        if (t == textoDelModulo) return t;
      }
      fail('no se ha encontrado el versiculo en pantalla: "$textoDelModulo"');
    }

    /// Las palabras EN ROJO DEL VERSICULO [textoDelVersiculo], y solo de el.
    ///
    /// Y SOLO DEL VERSICULO, y no de la pantalla, y por que. La pantalla pinta un
    /// capitulo entero, y en Juan 3 hay versiculos al lado que **si** son de Jesus --
    /// 3:11 lo es entero, sus 24 palabras--: al buscar rojo en toda la pantalla, Juan 3:29
    /// salia con rojo de los versiculos de al lado y Juan 3:16 salia con mas de 25
    /// palabras. Las dos pruebas fallaban por lo mismo.
    ///
    /// Y POR ESO SE BUSCA POR **TEXTO IGUAL** y no por posicion ni por el primer
    /// `RichText`: el capitulo entero tambien es un `RichText`, y el titulo de la barra es
    /// otro. Ver `palabras_anadidas_test.dart`, que tiene el mismo aviso y el mismo motivo.
    List<String> rojas(WidgetTester tester, String textoDelVersiculo) {
      for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
        if (rico.text.toPlainText() != textoDelVersiculo) continue;
        final salida = <String>[];
        _recorrer(rico.text, Colores.palabraDeJesus, salida);
        return salida;
      }
      fail('no se ha encontrado el versiculo en pantalla: "$textoDelVersiculo"');
    }

    testWidgets('el texto es EXACTAMENTE el del modulo, con el color puesto',
        (tester) async {
      await pintar(tester, const Referencia('John', 3, 16));
      final delModulo =
          modulo.leer(const Referencia('John', 3, 16)).versiculos.single;

      expect(pintado(tester, delModulo.texto), delModulo.texto);
      expect(rojas(tester, delModulo.texto), isNotEmpty,
          reason: 'y ademas hay rojo en el versiculo');
    });

    testWidgets('Juan 3:16 sale entero en rojo: sus 25 palabras', (tester) async {
      await pintar(tester, const Referencia('John', 3, 16));

      final v = modulo.leer(const Referencia('John', 3, 16)).versiculos.single;
      final enRojo = rojas(tester, v.texto);

      expect(enRojo.length, v.palabras.length);
      expect(enRojo.join(' '), v.texto,
          reason: 'y son SUS palabras, en su orden, con su puntuacion');
    });

    testWidgets('Juan 3:29 no tiene ni una palabra en rojo', (tester) async {
      // Y ESTA ES LA MITAD QUE HACE QUE LO DE JUAN 3:16 VALGA. Un color puesto sin
      // criterio seria rojo en todo Juan 3, y entonces no estaria diciendo nada.
      await pintar(tester, const Referencia('John', 3, 29));
      final v = modulo.leer(const Referencia('John', 3, 29)).versiculos.single;

      expect(rojas(tester, v.texto), isEmpty);
    });

    testWidgets('en el Antiguo Testamento no hay ni una palabra en rojo',
        (tester) async {
      // Y NO ES UN FALLO DEL PARSER. Alli el que habla es el Dios del Antiguo Testamento
      // y este catalogo no lo marca, asi que no hay de donde sacarlo.
      await pintar(tester, const Referencia('Psalms', 23, 1));
      final v = modulo.leer(const Referencia('Psalms', 23, 1)).versiculos.single;

      expect(rojas(tester, v.texto), isEmpty);
      expect(v.palabrasDeJesus(), 0);
    });

    testWidgets('con el interruptor quitado no hay rojo y el texto es el mismo',
        (tester) async {
      await pintar(tester, const Referencia('John', 3, 16));
      final delModulo =
          modulo.leer(const Referencia('John', 3, 16)).versiculos.single;

      expect(rojas(tester, delModulo.texto), isNotEmpty);

      await tester.tap(find.byIcon(Icons.tonality));
      await tester.pumpAndSettle();

      expect(rojas(tester, delModulo.texto), isEmpty);
      expect(pintado(tester, delModulo.texto), delModulo.texto,
          reason: 'quitar el color no puede tocar el texto');
    });

    testWidgets('el icono del interruptor dice en que estado esta', (tester) async {
      // Y EL ESTADO VA EN EL COLOR DEL ICONO Y EN EL TOOLTIP, y no solo en el icono. En
      // movil el `tooltip` solo sale si se deja el dedo quieto, y eso casi nadie lo hace;
      // por eso el color tambien lo dice. Y si el icono no cambiara, la unica pista seria
      // un triangulo que aparece y desaparece, que es un aviso de error y no un
      // interruptor.
      await pintar(tester, const Referencia('John', 3, 16));

      expect(find.byIcon(Icons.tonality), findsOneWidget);
      expect(find.byIcon(Icons.tonality_outlined), findsNothing);

      final boton = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.tonality), matching: find.byType(IconButton)),
      );
      expect(boton.tooltip, contains('Palabras de Jesus en rojo: si'));
      expect(tester.widget<Icon>(find.byIcon(Icons.tonality)).color,
          Colores.palabraDeJesus);

      await tester.tap(find.byIcon(Icons.tonality));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tonality_outlined), findsOneWidget);
      final apagado = tester.widget<IconButton>(
        find.ancestor(
            of: find.byIcon(Icons.tonality_outlined), matching: find.byType(IconButton)),
      );
      expect(apagado.tooltip, contains('Palabras de Jesus en rojo: no'));
    });

    testWidgets('el rojo del texto se lee, y no es un color de adorno', (tester) async {
      // Y EL CONTRASTE ESTA MEDIDO Y NO ELEGIDO A OJO, porque es color de TEXTO DE CUERPO
      // y un rojo claro de letras rojas se lee como texto deshabilitado y no como
      // Escritura. El umbral de AAA para texto normal es 7:1.
      //
      // Y ESTA COMPROBACION VIVA EN CADA EJECUCION y no con un numero escrito: si alguien
      // cambia el color del tema y lo deja en 4:1, esta prueba se pone roja.
      await pintar(tester, const Referencia('John', 3, 16));
      expect(tester.takeException(), isNull);

      expect(_contraste(Colores.palabraDeJesus, Colores.fondo), greaterThanOrEqualTo(7),
          reason: 'sobre el fondo de la pantalla');
      expect(_contraste(Colores.palabraDeJesus, Colores.superficie),
          greaterThanOrEqualTo(7),
          reason: 'sobre una superficie, que es donde esta el versiculo');
    });

    testWidgets('a 360 y a 320 px no sale del borde, con un boton mas en la barra',
        (tester) async {
      // Y CON EL INTERRUPTOR EN LA BARRA, que es donde aparecen las barras desbordadas.
      // La barra tiene el titulo, el boton de volver, buscar, el interruptor y el del
      // comentario, y a 320 px eso son cinco cosas. Una barra que desborda a 320 no se ve
      // en la prueba anterior --que es a 360-- ni en la de 1440.
      for (final ancho in <double>[320, 360, 414]) {
        await pintar(tester, const Referencia('John', 3, 16), ancho: ancho);
        expect(tester.takeException(), isNull, reason: 'a $ancho px');
      }

      // Y CON EL VERSAICULO MAS LARGO QUE HAY EN JUAN 3, que es de 141 caracteres.
      await pintar(tester, const Referencia('John', 3, 1), ancho: 320);
      expect(tester.takeException(), isNull);
    });
  });

  group('3. la tabla de estilos, entera', () {
    // MEDIDO: en el KJV **ninguna** palabra es a la vez `\\add` y `\\wj`. Cero de 835.159.
    // Asi que el caso de las dos marcas no se puede probar con el fichero real, y por eso
    // la decision de estilo esta en una funcion pura que se puede probar entera.
    //
    // Y NO SE PUEDE DEJAR SIN PROBAR, porque el error es facil y ya se cometio: la
    // primera version hacia que "el subrayado ganara" sobre el rojo, y una palabra anadida
    // por el traductor **dentro** de las palabras de Jesus salia negra con subrayado. El
    // rojo se perdia justo en el unico sitio donde mas se nota.
    const base = TextStyle(fontSize: 16, color: Colores.texto);

    test('una palabra normal no lleva estilo', () {
      // Y **NULL** Y NO EL ESTILO BASE. Un `TextSpan` con un estilo igual al del padre se
      // parte en otra linea en el motor de texto, y un `RichText` con cuatro `TextSpan` de
      // mas por palabra son cuatro veces mas colocaciones en un capitulo de 36 versiculos.
      expect(estiloDePalabra(const AnotacionDePalabra(strong: 'G2316'), base,
          mostrarPalabrasDeJesus: true), isNull);

      // Y CON EL INTERRUPTOR PUESTO TAMBIEN, porque el numero del lexicon no se pinta y no
      // hay que inventarle un estilo.
      expect(estiloDePalabra(const AnotacionDePalabra(), base,
          mostrarPalabrasDeJesus: true), isNull);
    });

    test('una palabra del traductor sale subrayada y del color del texto', () {
      final e = estiloDePalabra(const AnotacionDePalabra(esAnadido: true), base,
          mostrarPalabrasDeJesus: true)!;

      expect(e.decoration, TextDecoration.underline);
      // Y EL COLOR ES EL DE TEXTO, no "ninguno". `copyWith(color: null)` en Dart
      // **conserva** el color del estilo base y no lo borra --que es lo unico que se
      // puede hacer sin tener que volver a construir el estilo--, asi que lo que sale es
      // el color del cuerpo. Comprobarlo asi evita escribir una comprobacion que pasaria
      // con cualquier rojo.
      expect(e.color, Colores.texto);
    });

    test('una palabra de Jesus sale en rojo y sin subrayado', () {
      final e = estiloDePalabra(const AnotacionDePalabra(esPalabraDeJesus: true), base,
          mostrarPalabrasDeJesus: true)!;

      expect(e.color, Colores.palabraDeJesus);
      expect(e.decoration, isNull);
    });

    test('una palabra de las dos cosas lleva LAS DOS, no una', () {
      final e = estiloDePalabra(
        const AnotacionDePalabra(esAnadido: true, esPalabraDeJesus: true),
        base,
        mostrarPalabrasDeJesus: true,
      )!;

      expect(e.color, Colores.palabraDeJesus);
      expect(e.decoration, TextDecoration.underline);
    });

    test('con el interruptor quitado, el rojo se va y el subrayado se queda', () {
      // Y EL SUBRAYADO NO SE VA CON EL ROJO. Son dos interruptores distintos que aqui son
      // uno: quitar las letras rojas no puede quitar el dato de que el traductor metio esa
      // palabra. Si se fueran juntos, apagar el color seria borrar informacion del
      // modulo.
      final e = estiloDePalabra(
        const AnotacionDePalabra(esAnadido: true, esPalabraDeJesus: true),
        base,
        mostrarPalabrasDeJesus: false,
      )!;

      expect(e.decoration, TextDecoration.underline);
      expect(e.color, Colores.texto, reason: 'y vuelve al color del cuerpo');
    });

    test('el tamano de la letra no cambia: es el texto del modulo', () {
      // Y NO SE PUEDE TOCAR NADA MAS DEL ESTILO. El cuerpo es de 16 px por la razon que
      // esta en `tema.dart` --por debajo de 16 px, iOS hace zoom-- y subir el tamano de
      // las palabras de Jesus las haria breaking del texto que se esta leyendo.
      final e = estiloDePalabra(const AnotacionDePalabra(esPalabraDeJesus: true), base,
          mostrarPalabrasDeJesus: true)!;

      expect(e.fontSize, 16);
      expect(e.height, isNull);
    });
  });
}

/// Recoge el texto de los tramos del color [color].
void _recorrer(InlineSpan span, Color color, List<String> salida) {
  if (span is! TextSpan) return;
  if (span.style?.color == color) {
    final texto = span.toPlainText();
    if (texto.trim().isNotEmpty) salida.add(texto);
  }
  for (final hijo in span.children ?? const <InlineSpan>[]) {
    _recorrer(hijo, color, salida);
  }
}

/// La razon de contraste entre dos colores, segun WCAG.
///
/// Y ESTA COPIA ESTA AQUI A PROPOSITO y no importada de ningun sitio. Es la formula de la
/// norma, son cuatro lineas, y si el color del tema cambia esta comprobacion tiene que
/// seguir midiendo lo mismo: si el dia que el tema pase a tener sus propias utilidades de
/// contraste, esta comprobacion dejaria de mirar lo que el analyzer cree.
double _contraste(Color a, Color b) {
  final la = _luminancia(a), lb = _luminancia(b);
  final alta = la > lb ? la : lb, baja = la > lb ? lb : la;
  return (alta + 0.05) / (baja + 0.05);
}

double _luminancia(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : maths.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

/// Un almacenamiento que se queda esperando para siempre, como el navegador.
class _QueNoContesta implements Almacenamiento {
  @override
  Future<String?> leer(String clave) => Completer<String?>().future;

  @override
  Future<void> escribir(String clave, String valor) =>
      Completer<void>().future;

  @override
  Future<void> borrar(String clave) => Completer<void>().future;
}
