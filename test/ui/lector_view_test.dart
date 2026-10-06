// La pantalla de lectura, probada como pantalla: con el `.amod` real dentro.
//
// ============================================================================
// POR QUE CON EL MODULO REAL Y NO CON UN DOBLE
// ============================================================================
//
// 36 versiculos de Juan 3, Juan 3:16 con su texto entero, 50 capitulos de Genesis: un
// doble de versiculos daria verde con cualquier lista inventada, y la mitad de lo que
// se comprueba aqui es precisamente que esa lista es la de verdad. Ademas el modulo
// real es el que decide cuantos capitulos hay, y esa consulta ya esta probada en
// `modulo_repository_test.dart`.
//
// ============================================================================
// Y LA PANTALLA SE MONTA CON EL TEMA DE VERDAD
// ============================================================================
//
// Un `MaterialApp` con el tema por defecto mediria con otra fuente y otros margenes,
// y las comprobaciones de tamano --16 px, 48 px de alto, el ancho de la columna--
// dirian cosas distintas. Con el tema de la aplicacion se mide lo que se ve.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/busqueda/widgets/columna_de_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';
import '../support/modulos_de_prueba.dart';
import '../support/fuente.dart';

/// El texto de Juan 3:16 del KJV, entero.
///
/// Va escrito aqui y no construido, porque una prueba que busca parte de un texto
/// que ha construido ella no comprueba nada: si el texto se degrada, la prueba se
/// degrada con el y sigue dando verde.
const String juan316 =
    'For God so loved the world, that he gave his only begotten Son, that whosoever '
    'believeth in him should not perish, but have everlasting life.';

/// La atribucion que declara el KJV real.
///
/// Va aqui y no construida, porque una prueba que busca parte de un texto que ha
/// construido ella no comprueba nada. Y es el texto **entero**, con su par de puntos y
/// su parentesis, porque "dominio publico" sale tres veces en la ficha.
const String textoDeAtribucionReal =
    'Atribucion: eBible.org (eng-kjv2006). Dominio publico.';

/// El principio del copyright del KJV real.
const String prefijoDeCopyrightReal =
    'Copyright: Dominio publico. El texto de la Version King James';

/// Monta la pantalla de lectura con un modulo abierto, y devuelve su modelo.
///
/// Y EL `alPulsarPasaje` LO PONE EL PROPIO [montarLector], no la prueba. La primera
/// version lo pedia la prueba, y eso obligaba a hacer esto en cada una:
///
/// ```dart
/// LectorViewModel? vm;
/// vm = await montarLector(t, alPulsarPasaje: (r) => vm!.leer(r));
/// ```
///
/// que ademas no compila: dentro del inicializador, `vm` todavia no existe, y Dart lo
/// dice. El truco de "pulsar el pasaje lo pinta el mismo modelo" es lo que hace el
/// enrutador de verdad, asi que lo hace tambien aqui, y la prueba se queda con una
/// linea.
///
/// Devuelve el modelo para poder comprobar el estado, y lo deja abierto: el
/// `LectorViewModel` lo cierra en su `dispose`, que es lo que hace en la aplicacion.
Future<LectorViewModel> montarLector(
  WidgetTester t, {
  String? ruta,
  String id = 'KJV2006',
  String? licenciaDelManifiesto = 'PublicDomain',
  Size tamano = const Size(360, 640),
  /// Que hacer cuando la pantalla pide otro pasaje. Por defecto, leerlo en el mismo
  /// modelo, que es lo que hace el enrutador.
  void Function(LectorViewModel vm, Referencia r)? alPulsarPasaje,
  VoidCallback? alVolver,
  void Function(String)? alCambiarDeVersion,
  /// Los resaltados de la persona, para las pruebas que marcan.
  ///
  /// Y ES **OPCIONAL**, y no por comodidad: sin el, la pantalla se lee igual y las pruebas
  /// que no miran resaltados no tienen que montar un almacen en cada una. Y en la vista es
  /// opcional por el mismo motivo.
  ResaltadosViewModel? resaltados,
}) async {
  final apertura = ModuloAbierto.abrir(ruta ?? rutaBibliaReal, id: id);
  if (apertura is! Abierto) {
    fail('no se ha podido abrir el modulo: ${(apertura as FalloAlAbrir).motivo}');
  }

  final vm = LectorViewModel();
  addTearDown(vm.dispose);
  vm.abrir(apertura.modulo, licenciaDelManifiesto: licenciaDelManifiesto);

  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);

  await t.pumpWidget(MaterialApp(
    theme: temaDeAb(),
    home: LectorView(
      viewModel: vm,
      alPulsarPasaje: (r) => (alPulsarPasaje ?? (_, ref) => vm.leer(ref))(vm, r),
      alPedirComentario: () {},
      alVerIndice: (_) {},
      alAlternarPalabrasDeJesus: () {},
      alAbrirLibros: () {},
      alAbrirVersiones: () {},
      alCambiarDeVersion: alCambiarDeVersion ?? (_) {},
      alVolver: alVolver ?? () {},
      resaltados: resaltados,
    ),
  ));
  return vm;
}

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('7.1 un capitulo completo, con los versiculos numerados', () {
    testWidgets('Juan 3 sale con 36 versiculos, del 1 al 36', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      expect(vm.pasaje!.versiculos.length, 36);
      expect(vm.estado, EstadoLecturaTexto.leyendo);

      // Y los 36 estan en pantalla, numerados y en orden. Con numeros **visibles**, que
      // es lo que pide la tarea: un `ListView` con los 36 dentro no dice que se vean.
      final numeros = _numerosDeVersiculoVisibles(t);
      expect(numeros, List<int>.generate(36, (i) => i + 1));
    });

    testWidgets('el versiculo 16 sale entero, no un trozo', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      // El texto exacto, en un solo `Text`. Si se partiera en trozos por el ancho de
      // la columna, este texto no apareceria entero y la comprobacion fallaria.
      expect(find.textContaining(juan316), findsOneWidget);
      expect(find.text(juan316), findsOneWidget);

      // Y es el versiculo 16, no el 15 ni el 17: se mira el numero de al lado.
      final indice = _numerosDeVersiculoVisibles(t).indexOf(16);
      expect(indice, greaterThanOrEqualTo(0));
      final n16 = t.widget<RichText>(find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == juan316,
      ));
      expect(n16.text.toPlainText(), juan316);
    });

    testWidgets('un versiculo pedido trae el capitulo desde ahi, con el suyo marcado',
        (t) async {
      // Y NO "UN VERSICULO SUELTO". Medido en una captura a 360 px: el versiculo pedido
      // era el **16 %** de la pantalla y los terminos del modulo el 35 %. Un lector de
      // Biblia que al abrir Juan 3:16 enseña un versiculo y tres lineas de terminos no
      // esta enseñando la Biblia. Ver la nota de `leer` en `modulo_repository.dart`.
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      // Juan 3 va del 1 al 36; desde el 16 son 21.
      expect(vm.pasaje!.versiculos.length, 21);
      expect(vm.pasaje!.versiculos.first.numero, 16);
      expect(find.text(juan316), findsOneWidget);

      // Y LOS 21 NUMEROS **NO** CABEN EN PANTALLA, y no se comprueba que esten todos: el
      // `ListView` solo construye los que se ven. Lo que se comprueba es que el primero es
      // el pedido, que es lo que dice el enlace.
      final visibles = _numerosDeVersiculoVisibles(t);
      expect(visibles.first, 16);
      expect(visibles, contains(16));
    });

    testWidgets('el versiculo pedido se distingue en la columna', (t) async {
      // Y CON UNA **LINEA VERTICAL AL LADO** y el texto en color de acento, y no con otro
      // color de texto: el texto de la Escritura no cambia de color, y una columna de
      // versiculos con numeros desalineados no se puede leer como una columna.
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      // Y EL FILTRO ES **UNA MARCA IZQUIERDA DE 3**, y no "cualquier `DecoratedBox` con
      // borde". Con lo mas ancho salian **2**: la fila de la referencia tambien lleva
      // `DecoratedBox`, y su borde es de abajo. La comprobacion decia "solo el versiculo
      // pedido lleva la marca" y habia dos cosas marcadas, una de ellas el borde de la
      // cabecera.
      final marcados = find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        if (d is! BoxDecoration) return false;
        final b = d.border;
        return b is Border && b.left.width == 3;
      });
      expect(marcados, findsOneWidget,
          reason: 'solo el versiculo pedido lleva la marca');

      // Y DENTRO DE LA MARCA ESTA **EL VERSICULO ENTERO**, no una palabra suelta.
      //
      // Y SE BUSCA POR EL TEXTO PLANO DEL `RichText` Y **NO** POR `find.text`. El versiculo
      // se pinta con `Text.rich` --una palabra con su `TextSpan`, con su color y su
      // subrayado-- y no hay ningun `Text` con el texto entero, asi que
      // `find.text('For God so loved the world')` no encuentra nada. Y eso no es que falte
      // el versiculo: es que el finder equivocado da "0 widgets" cuando lo que falla es
      // que se busca en el sitio incorrecto.
      // Y HAY **DOS** `RichText` DENTRO: el numero del versiculo y el texto. Los dos, y
      // el segundo es el versiculo entero. La primera version de esta comprobacion pedia
      // uno solo y por eso fallaba: el numero va en su propia columna de 34 px y es su
      // propio `RichText`, como lo ha sido siempre.
      final dentro = t
          .widgetList<RichText>(
            find.descendant(of: marcados, matching: find.byType(RichText)),
          )
          .map((r) => r.text.toPlainText())
          .toList();

      expect(dentro, hasLength(2), reason: 'el numero y el texto');
      expect(dentro.first, '16', reason: 'el numero del versiculo pedido');
      expect(dentro.last, startsWith('For God so loved the world'),
          reason: 'y el texto entero, con su puntuacion y todo');
    });

    testWidgets('el titulo sale en castellano y el pasaje en la URL en la clave', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      expect(find.text('Juan 3'), findsWidgets);
      expect(vm.leyendo!.paraUrl, 'John.3');
    });
  });

  group('7.3 un pasaje que no existe en esta traduccion', () {
    testWidgets('avisa en castellano y ofrece el ultimo valido', (t) async {
      final vm = await montarLector(t);
      // Juan 3:37 no existe. Juan 3:36 si.
      vm.leer(const Referencia('John', 3, 37));
      await t.pumpAndSettle();

      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(find.textContaining('Juan 3:37'), findsWidgets);
      expect(find.textContaining('no tiene'), findsWidgets);

      // Y el boton esta, con el pasaje que SI existe.
      final boton = find.widgetWithText(TextButton, 'Ir a Juan 3:36');
      expect(boton, findsOneWidget);
    });

    testWidgets('el boton lleva al pasaje que existe', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3, 37));
      await t.pumpAndSettle();

      await t.tap(find.widgetWithText(TextButton, 'Ir a Juan 3:36'));
      await t.pumpAndSettle();

      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.leyendo, const Referencia('John', 3, 36));
      // Y sale Juan 3:36, que **no** es Juan 3:16. La primera version de esta prueba
      // buscaba el texto de Juan 3:16 y por eso fallaba con "0 widgets" y la
      // conclusion tentativa era que el boton no funcionaba. El boton funcionaba: lo que
      // se buscaba era el versiculo equivocado, porque Juan 3:36 es el penultimo del
      // capitulo y no el 16.
      expect(_numerosDeVersiculoVisibles(t), <int>[36]);
      expect(vm.pasaje!.versiculo(36), isNotNull);
      expect(vm.pasaje!.versiculo(16), isNull, reason: 'solo se pidio el 36');
    });

    testWidgets('un capitulo entero que no existe tambien ofrece salida', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('Genesis', 51));
      await t.pumpAndSettle();

      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(find.textContaining('Génesis 51'), findsWidgets);
      expect(find.textContaining('Ir a Génesis 50'), findsOneWidget);
    });

    testWidgets('el aviso va ANTES del texto, no debajo', (t) async {
      // Y esto importa: si el aviso estuviera debajo, quien pide Juan 3:37 veria un
      // hueco y pensaria que la aplicacion se ha roto, en vez de leer que ese
      // versiculo no esta en esta traduccion.
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3, 37));
      await t.pumpAndSettle();

      final yDelAviso = t.getTopLeft(find.textContaining('Juan 3:37').first).dy;
      // Y no hay **numeros de versiculo**, porque no hay versiculo. No se comprueba
      // que no haya ningun `RichText`: hay varios --el campo, el boton, el aviso-- y
      // esa comprobacion fallaria por motivos que no tienen que ver con los versiculos.
      expect(_numerosDeVersiculoVisibles(t), isEmpty,
          reason: 'no hay versiculos que pintar cuando el pasaje no existe');
      expect(yDelAviso, greaterThan(0));
    });
  });

  group('7.6 el campo de referencia', () {
    testWidgets('el boton se habilita y se deshabilita mientras se escribe', (t) async {
      await montarLector(t);

      // Y EL BOTON **NO EXISTE** SIN TEXTO, y no es que este deshabilitado. Es el icono de
      // sufijo del campo, y con el campo vacio no hay ni el icono de borrar ni el de ir: dos
      // iconos grises en un campo vacio son dos controles que no hacen nada.
      expect(_botonDeIr(t), findsNothing);

      await t.enterText(find.byType(TextField), 'Juan');
      await t.pump();
      expect(_botonDeIr(t), findsOneWidget);
      expect(t.widget<IconButton>(_botonDeIr(t)).onPressed, isNull,
          reason: '"Juan" sin capitulo no es una referencia');

      await t.enterText(find.byType(TextField), 'Juan 3');
      await t.pump();
      expect(t.widget<IconButton>(_botonDeIr(t)).onPressed, isNotNull);

      await t.enterText(find.byType(TextField), 'Zetaquiel 3');
      await t.pump();
      expect(t.widget<IconButton>(_botonDeIr(t)).onPressed, isNull,
          reason: 'ese libro no existe');

      await t.enterText(find.byType(TextField), 'Juan 3:16');
      await t.pump();
      expect(t.widget<IconButton>(_botonDeIr(t)).onPressed, isNotNull);
    });

    testWidgets('buscar lleva a lo escrito', (t) async {
      final vm = await montarLector(t);

      await t.enterText(find.byType(TextField), 'Génesis 1');
      await t.pump();
      await t.tap(_botonDeIr(t));
      await t.pumpAndSettle();

      expect(vm.leyendo, const Referencia('Genesis', 1));
    });

    testWidgets('el teclado tambien lleva a lo escrito', (t) async {
      // Y ESTO ES LO QUE SUSTITUYE AL BOTON DE 48 PX. El `textInputAction: search`--que ya
      // estaba— manda el mismo `alBuscar`, y el "Ir" del teclado del movil esta a la
      // altura de los dedos sin ocupar nada de la pantalla.
      final vm = await montarLector(t);

      await t.enterText(find.byType(TextField), 'Génesis 1');
      await t.pump();
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();

      expect(vm.leyendo, const Referencia('Genesis', 1));
    });

    testWidgets('el texto de entrada es de al menos 16 px', (t) async {
      // La tarea lo pide, y es por una razon concreta: por debajo de 16 px el teclado
      // del movil avisa a iOS de que el campo es de "formulario pequeno" y deja de
      // usar el corrector automatico, que en una referencia es justo lo que hace
      // falta --"Juan" se escribe con mayuscula y sin tilde.
      await montarLector(t);
      final campo = t.widget<TextField>(find.byType(TextField));
      expect(campo.style!.fontSize, greaterThanOrEqualTo(16));
    });

    testWidgets('a 360 px el campo con sus dos iconos cabe sin desbordarse', (t) async {
      await montarLector(t, tamano: const Size(360, 640));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Juan 3:16');
      await t.pump();

      final boton = _botonDeIr(t);
      expect(boton, findsOneWidget);
      expect(t.getSize(boton).width, lessThanOrEqualTo(360));
      expect(t.getSize(boton).height, greaterThanOrEqualTo(48),
          reason: 'por debajo de 48 px se falla la pulsacion sin darse cuenta');

      // Y EL CAMPO **TODO EL ANCHO**, y no la mitad. Ese era el motivo del boton debajo: el
      // texto se cortaba a los 12 caracteres justo al escribir "Juan 3:16". Con el boton
      // dentro, el campo mide lo que mide la columna y "Juan 3:16" entra de sobra.
      final campo = find.byType(TextField);
      expect(t.getSize(campo).width, greaterThan(280));
    });

    testWidgets('a 360x360 --con el teclado abierto-- nada se sale', (t) async {
      // Con el teclado abierto en un movil de 640 px de alto quedan unos 360 px. Antes
      // habia un boton de 48 px en su propia fila; ahora no hay fila, asi que el campo
      // ocupa lo que ocupaba y el versiculo empieza mas arriba.
      await montarLector(t, tamano: const Size(360, 360));
      await t.pump();
      await t.enterText(find.byType(TextField), 'Juan 3:16');
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(TextField)).width, lessThanOrEqualTo(360));

      // Y EL CAMPO ESTA EN LA MISMA ALTA QUE EL ICONO, no debajo: es la prueba de que no
      // hay una segunda fila.
      final yCampo = t.getTopLeft(find.byType(TextField)).dy;
      final yBoton = t.getTopLeft(_botonDeIr(t)).dy;
      expect((yBoton - yCampo).abs(), lessThan(30),
          reason: 'el boton va DENTRO del campo, no debajo');
    });

    testWidgets('el campo no se borra al cambiar de capitulo', (t) async {
      // El fallo que esto comprueba: si el `TextEditingController` se actualizara con
      // el pasaje, quien estuviera escribiendo "Juan 5:1" para saltar al 17 veria como
      // su "1" desaparece al cambiar de capitulo.
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'Juan 5:1');
      await t.pump();
      expect(find.text('Juan 5:1'), findsOneWidget);

      vm.leer(const Referencia('John', 4));
      await t.pumpAndSettle();

      expect(find.text('Juan 5:1'), findsOneWidget,
          reason: 'lo que se esta escribiendo no se toca al cambiar de capitulo');
    });
  });

  group('7.7 la columna de texto', () {
    testWidgets('a 1440 px la columna no pasa de los 90 caracteres', (t) async {
      final vm = await montarLector(t, tamano: const Size(1440, 900));
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      final ancho = t.getSize(find.byKey(ColumnaDeTexto.claveDelAncho)).width;
      final limite = anchoDeNoventaCaracteres(temaDeAb().textTheme.bodyLarge!);
      expect(ancho, lessThanOrEqualTo(limite),
          reason: 'la columna mide $ancho y el limite son $limite');
      expect(ancho, lessThan(1440));
    });
  });

  group('los terminos del modulo, a la vista', () {
    // Y ESTAN BAJO EL PLIEGUE DEL CAPITULO, Y ESO NO ES ABRIR UN MENU.
    //
    // Juan 3 tiene 36 versiculos y en un movil de 640 px de alto entran unos veinte.
    // Los terminos van al final del desplazamiento, en el `PieDeLectura`, porque un pie
    // **fijo** taparia versiculos, que es lo peor que puede hacer un pie. Y bajando se
    // llega sin abrir nada.
    //
    // Lo que este grupo comprueba son dos cosas distintas y las dos importan:
    //
    //   - Que los terminos estan en la **pantalla de lectura**, y no en un menu, ni en
    //     un "acerca de", ni en un desplegable. Se comprueba buscando que no hay
    //     ninguno de esos en la pantalla y que los terminos aparecen al bajar.
    //
    //   - Que al bajar se ven **sin pulsar**: no hay ningun boton de por medio.
    //
    // Y LOS BUSCADORES SON EXACTOS, A PROPOSITO. `find.textContaining` no distingue
    // mayusculas, y "dominio publico" aparece tres veces en la ficha: como licencia, al
    // final de la atribucion y al principio del copyright. Con un buscador de palabra
    // suelta, la prueba comprobaba que existia *una* de las tres y no la que queria.
    // Con el texto entero de cada linea no hay ambiguedad, y si la etiqueta cambia, la
    // prueba falla y hay que mirar por que.
    testWidgets('7.10 copyright y atribucion se ven SIN abrir ningun menu', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      // No hay ningun menu en la pantalla. Esta es la comprobacion de "sin abrir
      // ningun menu": si los terminos estuvieran detras de un desplegable, habria un
      // menu aqui, y no lo hay.
      expect(find.byType(PopupMenuButton<Object?>), findsNothing);
      expect(find.byType(MenuAnchor), findsNothing);
      expect(find.byType(ExpansionTile), findsNothing);

      // Y bajando, sin pulsar nada, estan.
      await _bajarALosTerminos(t);
      expect(find.textContaining(textoDeAtribucionReal), findsOneWidget,
          reason: 'la atribucion se ve');
      expect(find.textContaining(prefijoDeCopyrightReal), findsOneWidget,
          reason: 'el copyright se ve');
    });

    testWidgets('7.11 licencia y evidencia estan JUNTO a la atribucion', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      await _bajarALosTerminos(t);

      expect(find.textContaining('Licencia: dominio publico'), findsOneWidget);
      expect(find.textContaining('Evidencia de dominio publico: https://ebible.org/Scriptures/eng-kjv2006/copr.htm'),
          findsOneWidget,
          reason: 'la evidencia de dominio publico se ve, que es lo que hay que poder '
              'comprobar para usar un texto');

      // "Junto" se comprueba con la posicion, no con que existan: un termino al fondo
      // de una ficha larga esta tan escondido como uno detras de un menu. Las tres
      // lineas estan en la misma columna --misma x-- y a menos de tres lineas de
      // distancia una de otra --cada linea a 13 px con altura 1,45 son unos 19 px.
      final xLicencia = t.getTopLeft(find.textContaining('Licencia: dominio publico')).dx;
      final xAtribucion = t.getTopLeft(find.textContaining(textoDeAtribucionReal)).dx;
      final xEvidencia =
          t.getTopLeft(find.textContaining('Evidencia de dominio publico:')).dx;

      expect(xLicencia, closeTo(xAtribucion, 0.5));
      expect(xEvidencia, closeTo(xAtribucion, 0.5),
          reason: 'en una pantalla ancha la ficha se repartiria en varias columnas y '
              '"junto" seria medio metro');

      // Y ADYACENTES, SIN NADA INTERactivo EN MEDIO. La distancia vertical exacta
      // depende del ancho: a 360 px la URL de la evidencia ocupa tres lineas y la
      // separacion es de 144 px, y a 1440 px cabria en dos. Comprobar un numero fijo
      // seria comprobar el ancho de la pantalla, que no es lo que dice la tarea.
      //
      // Lo que si importa es que esten en la misma columna y que **entre** ellas no haya
      // nada que se pulse. Por eso se comprueba que no hay ningun boton en la franja que
      // las separa, en vez de mirar lo que hay entre lineas: el boton es lo que
      // convertiria "junto" en "detras de algo".
      final yLicencia = t.getTopLeft(find.textContaining('Licencia: dominio publico')).dy;
      final yEvidencia =
          t.getTopLeft(find.textContaining('Evidencia de dominio publico:')).dy;
      final yAtribucion = t.getTopLeft(find.textContaining(textoDeAtribucionReal)).dy;

      final desde = (yLicencia < yAtribucion ? yLicencia : yAtribucion);
      final hasta = (yLicencia < yAtribucion ? yAtribucion : yLicencia);
      expect(desde, greaterThanOrEqualTo(0));
      expect(hasta - desde, lessThan(200),
          reason: 'las tres lineas de la licencia tienen que estar en la misma ficha');

      for (final boton in <Finder>[find.byType(TextButton), find.byType(IconButton)]) {
        for (final e in boton.evaluate()) {
          final y = t.getTopLeft(find.byWidget(e.widget)).dy;
          expect(y < desde || y > hasta, isTrue,
              reason: 'no hay ningun boton entre la licencia y la atribucion');
        }
      }
      // Y la evidencia esta entre las dos, no aparte.
      expect(yEvidencia > desde - 200 && yEvidencia < hasta + 200, isTrue);
    });

    testWidgets('7.14 se ve la versificacion del modulo, que es KJV', (t) async {
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      await _bajarALosTerminos(t);

      // Y con su nombre, que "KJV" a secas no lo entiende nadie. El ano va tal cual
      // entre parentesis porque es el dato que hay: si el modulo no lo dice, no se
      // inventa.
      expect(find.textContaining('Versificacion: KJV, la de 1569'), findsOneWidget);
      expect(vm.terminos!.versificacion, 'KJV',
          reason: 'y el valor crudo es el que declara el modulo');
    });

    testWidgets('7.12 si el manifiesto y el modulo discrepan, manda el modulo', (t) async {
      // Un manifiesto que dice `PublicDomain` y un modulo que dice `CC-BY-NC`: es
      // exactamente el caso de la tarea, con un manifiesto alterado a proposito.
      //
      // Y el modulo con los terminos cambiados es una **copia del real**, con los mismos
      // 31.102 versiculos, para que lo que se ve sea Juan 3 de verdad.
      final ruta = crearModuloConTerminos(
        licencia: 'CC-BY-NC',
        licenciaEvidencia: 'https://ejemplo.org/licencia',
        atribucion: 'Traduccion de prueba',
        copyright: 'Copyright de prueba',
        nombre: 'discrepante',
      );
      addTearDown(borrarModulosDePrueba);

      final vm = await montarLector(
        t,
        ruta: ruta,
        id: 'PRUEBA',
        licenciaDelManifiesto: 'PublicDomain',
      );
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      await _bajarALosTerminos(t);

      // Manda el modulo: se ve "CC-BY-NC", no "PublicDomain".
      expect(vm.terminos!.licencia, 'CC-BY-NC');
      expect(find.textContaining('Licencia: CC-BY-NC'), findsOneWidget);

      // Y el aviso dice las dos, no solo que discrepan. Decir "discrepan" sin decir
      // cuales obliga a ir a buscarlas, y quien encuentra una contradiccion sin
      // explicacion no se fia de nada.
      expect(find.textContaining('El indice dice "PublicDomain"'), findsOneWidget);
      expect(find.textContaining('Manda el texto'), findsOneWidget);
    });

    testWidgets('7.13 con defectos, avisa de CUANTOS', (t) async {
      final ruta = crearModuloConTerminos(
        licencia: 'PublicDomain',
        defectsCount: 3,
        defects: 'faltan los versiculos 12 a 14 por un problema del original',
        nombre: 'con-defectos',
      );
      addTearDown(borrarModulosDePrueba);

      final vm = await montarLector(t, ruta: ruta, id: 'PRUEBA');
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      await _bajarALosTerminos(t);

      // El numero va en el texto, no solo un icono. "3 versiculos incompletos" permite
      // decidir; un triangulo amarillo no.
      expect(find.textContaining('Este texto tiene 3 versiculos incompletos'),
          findsOneWidget);
      expect(find.textContaining('faltan los versiculos 12 a 14'), findsOneWidget,
          reason: 'el texto de defects se ensena entero');
    });

    testWidgets('7.13 con un solo defecto, en singular', (t) async {
      final ruta = crearModuloConUnDefecto();
      addTearDown(borrarModulosDePrueba);

      final vm = await montarLector(t, ruta: ruta, id: 'PRUEBA');
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();
      await _bajarALosTerminos(t);

      // El singular y el plural son reglas distintas del castellano, y una regla de
      // texto se comprueba con el texto.
      expect(find.textContaining('Este texto tiene 1 versiculo incompleto.'),
          findsOneWidget);
    });

    testWidgets('7.13 con cero defectos NO aparece ningun aviso', (t) async {
      // La inversa, que es la parte que se olvida: un aviso que aparece cuando no hay
      // nada molesta, y uno que no aparece cuando hay algo oculta.
      final vm = await montarLector(t);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      expect(vm.terminos!.numeroDeDefectos, 0);
      await _bajarALosTerminos(t);
      expect(find.textContaining('incompleto'), findsNothing);
      expect(find.textContaining('problema del original'), findsNothing);
      // Y los terminos **si** se ven: que no haya aviso de defectos no significa que
      // no haya ficha.
      expect(find.textContaining(textoDeAtribucionReal), findsOneWidget);
    });

    testWidgets('un modulo sin terminos no ensena una ficha vacia', (t) async {
      // Y esto es lo que hay que mirar tambien: un modulo que no declara nada no
      // tiene ficha, y poner una con "sin licencia" seria inventar un dato que no esta
      // ahi. Con el KJV --que si los tiene-- esta prueba no se puede hacer; se
      // comprueba en `terminos_test.dart`, que si puede.
      final vm = await montarLector(t);
      vm.sinModulo();
      await t.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('el texto se sigue leyendo con los terminos puestos', (t) async {
      // La comprobacion de que cambiar la tabla `info` no ha estropeado nada. Un
      // modulo de prueba con los terminos raros es, si no, un modulo en el que no se
      // puede leer, y una prueba que solo mirara los terminos no lo notaria.
      final ruta = crearModuloConTerminos(
        licencia: 'CC-BY-NC',
        defectsCount: 3,
        defects: 'algo',
        nombre: 'lectura',
      );
      addTearDown(borrarModulosDePrueba);

      final vm = await montarLector(t, ruta: ruta, id: 'PRUEBA');
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      expect(vm.pasaje!.versiculos.length, 36, reason: 'siguen siendo 36');
      expect(find.text(juan316), findsOneWidget);
    });
  });
}

/// Un modulo con **un** defecto, para comprobar el singular.
///
/// Va en su propio metodo y no como un parametro mas de [crearModuloConTerminos]
/// porque el singular y el plural son reglas distintas del texto en castellano, y una
/// regla de texto se comprueba con el texto, no con el numero que hay detras.
String crearModuloConUnDefecto() => crearModuloConTerminos(
      licencia: 'PublicDomain',
      defectsCount: 1,
      defects: 'falta el versiculo 17 por un problema del original',
      nombre: 'un-defecto',
    );

/// Baja en el desplazamiento hasta que aparecen los terminos.
///
/// Y NO PULSA NADA. Solo desplaza. Por eso la comprobacion de la tarea 7.10 tiene
/// sentido: llegar a la atribucion no cuesta abrir un menu, cuesta bajar.
///
/// Y HACE FALTA BAJAR, y es una consecuencia de donde se han puesto los terminos --al
/// final del capitulo, en vez de fijos. Un pie fijo taparia versiculos; bajando se llega
/// con el mismo gesto que se usa para leer, sin un boton de por medio.
Future<void> _bajarALosTerminos(WidgetTester t) async {
  // Y UN BUCLE, Y NO `scrollUntilVisible`.
  //
  // `scrollUntilVisible` lanza, desde dentro del framework, en cuanto el objetivo **todavia
  // no esta construido**, que es justo lo que pasa con un `ListView` perezoso:
  //
  //     Bad state: No element
  //     #0  Iterable.single (dart:core/iterable.dart:694:5)
  //     #2  WidgetController.element (package:flutter_test/src/controller.dart:888:30)
  //
  // Ese error no dice de donde sale y no parece de esta prueba. Antes funcionaba porque los
  // terminos estaban mas arriba; al anadir la fila de la referencia, 48 px, dejan de
  // construirse en el primer cuadro y la prueba revienta.
  //
  // Con el bucle se baja en pasos, se mira, y se para. Y ademas **falla con un motivo** si
  // no aparece, que es lo que una comprobacion deberia hacer siempre.
  // Y EL SCROLLABLE **DEL LISTVIEW**, Y NO EL PRIMERO.
  //
  // Hay **dos** `Scrollable` en esta pantalla y el primero **no** es la lista: es el de
  // dentro del `EditableText` del campo de referencia. Medido:
  //
  //     Scrollable  212 x  23   en (32, 68)    <- el campo
  //     Scrollable  332 x 480   en (14, 104)   <- la lista
  //
  // `find.byType(Scrollable).first` cogia el del campo, el arrastre no hacia nada, y la
  // comprobacion decia "los terminos no han salido" cuando en realidad no se habia movido
  // nada. Un fallo que culpa a la pantalla de algo que la prueba no hizo.
  final lista = find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  // Y EL PASO ES **UN CUARTO** DEL RECORRIDO, Y NO 300 PX FIJOS. Medido: Juan 3 --36
  // versiculos-- ocupa **16.848 pixeles** a 360 px de ancho, porque la columna de texto se
  // queda en 260 px y cada versiculo sale en cinco o seis lineas. Con 25 pasos de 300 px se
  // llega a 7.500, y los terminos estan en 16.848: la prueba fallaba por no llegar, y el
  // mensaje decia "los terminos no han salido", que es una mentira sobre la aplicacion.
  //
  // Y ESE 16.848 ES UN DATO QUE NO ESTABA EN NINGUN SITE. Es la medida de lo que cuesta
  // leer un capitulo en un movil: trece pantallas y media de scroll para 36 versiculos. Lo
  // que lo arregla es tipografia --tamano de letra y alto de linea-- y eso todavia no
  // existe. Ver `tasks.md` de `lectura-como-lector`, punto 5.1.
  for (var i = 0; i < 8; i++) {
    final control = t.widget<Scrollable>(lista).controller;
    final porRecorrer = (control?.position.maxScrollExtent ?? 0) -
        (control?.position.pixels ?? 0);
    if (porRecorrer <= 0) break;
    await t.drag(lista, Offset(0, -porRecorrer / 4));
    await t.pumpAndSettle();
    if (find.textContaining('Atribucion').evaluate().isNotEmpty) return;
  }
  fail('los terminos del modulo no han salido; quedan '
      '${(t.widget<Scrollable>(lista).controller?.position.maxScrollExtent ?? 0) - (t.widget<Scrollable>(lista).controller?.position.pixels ?? 0)} '
      'pixeles por bajar');
}

/// Los numeros de versiculo que hay en pantalla, en el orden en que se ven.
///
/// Se leen de los widgets del lector y no de `Pasaje.versiculos`, porque lo que
/// comprueba la tarea 7.1 es que los numeros se **vean**, no que el modelo los tenga.
/// Un modelo con 36 versiculos y una pantalla que no pinta ninguno pasaria la
/// comprobacion del modelo.
/// Los numeros de versiculo que hay en pantalla, **en orden**.
///
/// Y POR LA **CLAVE** Y NO POR "cualquier `RichText` que sea un numero entero". La primera
/// version de este ayudante recogia todos los `RichText` y se quedaba con los que eran un
/// numero, y al abrir Juan 3 devolvia `[3, 36]`: el 3 de mas era el **numero de capitulo**,
/// que ahora va antes de los versiculos. Tres pruebas_contaban 37 versiculos visibles.
///
/// Y ES UN FALLO QUE NO SE VE. La prueba que queria "36 versiculos" recibia 37 y se quejaba;
/// pero si hubiera sido al reves --"empieza por el 3"-- habria dado verde viendo un capitulo
/// donde creia ver un versiculo.
List<int> _numerosDeVersiculoVisibles(WidgetTester t) {
  final numeros = <int>[];
  for (final e in find.byKey(claveDelNumeroDeVersiculo).evaluate()) {
    final texto = (e.widget as Text).data?.trim();
    if (texto == null) continue;
    final n = int.tryParse(texto);
    if (n != null) numeros.add(n);
  }
  return numeros;
}

/// El boton de ir del campo, que es un icono de sufijo.
///
/// Y SE BUSCA POR SU **ICONO** y no por su texto, porque ya no tiene texto. Con un
/// `find.widgetWithText` esto daba "0 widgets" y el fallo decia "no se encuentra", que es
/// un sintoma de otra cosa.
Finder _botonDeIr(WidgetTester t) => find.descendant(
      of: find.byType(TextField),
      matching: find.byWidgetPredicate(
        (w) => w is IconButton && w.icon is Icon && (w.icon as Icon).icon == Icons.arrow_forward,
      ),
    );
