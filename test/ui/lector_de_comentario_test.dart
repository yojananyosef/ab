// Leer un comentario en la pantalla de lectura.
//
// QUE NO HAY AQUI Y POR QUE. No hay pruebas de que la pantalla de lectura siga
// funcionando con una Biblia: eso ya lo comprobaba `lector_view_test.dart` y no lo
// cambia este fichero. Aqui solo esta lo que es **nuevo**: que un comentario se lee.
//
// Y LA RAZON DE QUE LAS PRUEBAS USEN EL FICHERO REAL Y NO UNO INVENTADO. Todo lo que se
// comprueba --19.742 notas, 19.741 pasajes, Mateo 23:13 con dos notas, Juan 3 con 32
// versiculos con nota-- esta medido sobre el CLARKE de verdad el 4 de octubre de 2026. Un
// comentario de prueba con tres versiculos y una nota comprobaria que el codigo funciona
// con un comentario imaginario, que es justo el que no existe.
//
// Y LA PRIMERA VERSION DE ESTAS PRUEBAS DECIA "JUAN 3:16 TIENE TRES NOTAS", Y ES FALSO.
//
// Lo habia deducido leyendo que la clave primaria de `commentary` son cuatro columnas
// --`book`, `chapter`, `verse`, `seq`-- y Que eso significaba varias notas por versiculo.
// Contadas las filas, Juan 3:16 tiene **una**. De 19.742 notas hay **una sola** con dos
// notas, y es Mateo 23:13. Un numero escrito por deduccion en vez de por medicion es
// una forma de mentir sin querer, y por eso aqui todo numero sale de una cuenta.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  // El view model con un comentario abierto de verdad. Se abre una vez para todas las
  // pruebas de la vista, porque son 57 MiB y `PRAGMA quick_check` sobre eso no se paga
  // en cada prueba.
  late LectorViewModel vm;

  setUpAll(() {
    final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
    if (r is! Abierto) {
      fail('el comentario real deberia abrirse: ${(r as FalloAlAbrir).motivo}');
    }
    vm = LectorViewModel();
    vm.abrir(r.modulo, licenciaDelManifiesto: 'PublicDomain');
  });

  // Y CON UN  Y NO CON  A SECO. Un tear-off **evalua** la variable
  //  en el momento en que se declara, que es antes de que  la asigne, y
  // Dart lanza  al cargar el fichero entero. Se vio como un fallo de
  // compilacion en la linea de , que no senala el sitio real.
  tearDownAll(() => vm.dispose());

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDeAb(),
        home: LectorView(
          viewModel: vm,
          alVolver: () {},
          alPulsarPasaje: vm.leer,
          alPedirComentario: () {},
      alVerIndice: (_) {},
          alCambiarDeVersion: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('un comentario se lee', () {
    testWidgets('el capitulo sale con las notas de Juan 3', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester);
      vm.leer(const Referencia('John', 3));
      await tester.pumpAndSettle();

      expect(vm.pasaje, isNotNull);
      expect(vm.pasaje!.traeNotas, isTrue);
      // Y 32 notas, que es lo medido: Juan 3 tiene 36 versiculos con texto y **32 con
      // nota** en el CLARKE. Los cuatro que no tienen nota no salen, y esa es la
      // diferencia entre un comentario y un texto.
      expect(vm.pasaje!.notas.length, 32);
      expect(vm.pasaje!.versiculos, isEmpty);

    });

    testWidgets('cada versiculo sale con SU nota, y no todas en un muro', (tester) async {
      // Y ESTA ES LA DIFERENCIA QUE HACE QUE SE PUEDA LEER. Treinta y dos notas seguidas
      // sin decir a que versiculo corresponde cada una no se entienden: se leen enteras y
      // no se sabe nada. La nota va **debajo de su versiculo**, con el numero al lado.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester);
      vm.leer(const Referencia('John', 3));
      await tester.pumpAndSettle();

      // Y EL NUMERO DEL VERSICULO DE CADA NOTA ESTA EN PANTALLA. Se cuentan los que
      // tienen borde, que es lo que distingue la etiqueta del versiculo de un numero
      // suelto dentro del texto.
      final conBorde = find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).border != null,
      );
      expect(conBorde, findsWidgets, reason: 'cada versiculo con nota lleva su etiqueta');

      // Y DOS VERSICULOS SEGUIDOS NO SE CONFUNDEN: hay un separador entre bloque y
      // bloque, que es lo que hace que se lean como glosas y no como un solo parrafo.
      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('Mateo 23:13: el dato lo trae dos veces y se ensena una', (tester) async {
      // Y ESTE ES EL UNICO CASO REAL DE NOTAS REPETIDAS, y por eso se ensena. Si las dos
      // salieran, quien lo lee pensaria que la pantalla se ha roto.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester);
      vm.leer(const Referencia('Matthew', 23, 13));
      await tester.pumpAndSettle();

      // Y EN PANTALLA ESTA UNA, no dos. Este es el motivo por el que se quitan: quien ve
      // el mismo parrafo de 2.709 caracteres dos veces seguidas piensa que la pantalla se
      // ha roto.
      expect(find.textContaining('Wo unto you, scribes'), findsOneWidget);
      expect(find.text('2 notas'), findsNothing,
          reason: 'si dice "2 notas" y solo hay una, es peor que no decirlo');
    });

    testWidgets('un versiculo SIN nota no ensena nada en vez de ensenar un hueco',
        (tester) async {
      // Juan 3:1 no tiene nota en el CLARKE --medido-- y ese es el caso que importa:
      // ofrecer un "1" sin nada debajo parece que el versiculo esta en blanco, que es
      // distinto de que no haya nada escrito.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester);
      vm.leer(const Referencia('John', 3, 1));
      await tester.pumpAndSettle();

      // Y LA RESPUESTA ES "NO EXISTE", QUE ES LO QUE YA SABIA HACER LA APP. Juan 3:1 no
      // tiene nota, `existe` dice que no, y el ViewModel pasa a `noExiste`: sin texto y
      // con un aviso que lo explica.
      //
      // La primera version de esta prueba decia que saldria "Aqui no hay nada escrito",
      // que era un texto inventado: la pantalla nunca lo ha dicho y no hace falta que lo
      // diga. Un versiculo sin nota en un comentario **no existe** en ese comentario, y
      // es mejor decirlo asi que dejar un hueco.
      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(vm.pasaje, isNull, reason: 'no se pinta un pasaje vacio: no hay nada ahi');
      expect(find.textContaining('Juan 3:1'), findsWidgets);
    });

    testWidgets('a 360 px el comentario no sale del borde', (tester) async {
      // Y ES LA PREGUNTA DE SIEMPRE, y aqui con mas motivo: el texto de un comentario es
      // **mas largo y mas enrevesado** que el de un versiculo. Juan 3:16 del CLARKE son
      // 405 caracteres en una sola nota, y los nombres propios de los textos son largos.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester);
      vm.leer(const Referencia('John', 3, 16));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('For God so loved the world'), findsWidgets,
          reason: 'la nota de Juan 3:16 tiene que estar en pantalla');
    });
  });

  group('el comentario NO se disfraza de Biblia', () {
    testWidgets('las notas y los versiculos no se pintan igual', (tester) async {
      // Y ESTA ES LA REGLA DE LA PANTALLA, COMPROBADA. Un versiculo va en columna propia
      // con su numero grande y el cuerpo del texto; una nota va en cuerpo mas pequeno,
      // con una barra vertical y una etiqueta de color. Si se pintaran igual, el
      // comentario pareceria parte de la Sagrada Escritura, que es el modo de fallo de las
      // apps que lo hacen.
      //
      // Y LA COMPROBACION ES LA DIFERENCIA DE TAMANO, que es lo que el ojo ve. Una
      // diferencia de color o de un icono es mas sutil de lo que parece cuando ya se ha
      // visto la pantalla cien veces.
      // Y SE BUSCA POR LO QUE **EMPIEZA** CADA COSA, y no "el texto mas largo de la
      // pantalla". La version anterior cogia el mas largo y ganaba el copyright del pie --
      // 14 px y doscientas caracteres-- por ser mas largo que Juan 3:16, de modo que la
      // comparacion daba 15 contra 14 y hacia fallar algo que estaba bien.
      //
      // Y ESO NO ES UN DETALLE DE LA PRUEBA: si el heuristico es "el mas largo", anadir
      // cualquier texto largo al pie --una nota de licencia mas larga, un aviso-- cambia el
      // resultado de una comprobacion que va de los 15 a los 16 del cuerpo del texto.
      final conVersiculos = await _tamanoDelCuerpo(
        tester,
        comentario: false,
        empiezaCon: 'For God so loved the world,',
      );
      final conNotas = await _tamanoDelCuerpo(
        tester,
        comentario: true,
        empiezaCon: 'For God so loved the world - Such a love',
      );

      expect(conNotas, isNotNull, reason: 'la nota de Juan 3:16 tiene 405 caracteres');
      expect(conVersiculos, isNotNull);
      expect(conNotas!, lessThan(conVersiculos!),
          reason: 'el texto de una nota tiene que ser mas pequeno que el de un versiculo');
    });
  });

  group('la navegacion funciona igual en un comentario', () {
    test('los libros y capitulos salen del comentario, no de una tabla del proyecto', () {
      // Y NO SE INVENTA NINGUNO. Un comentario puede no comentar todo: el CLARKE tiene
      // nota en los 66 libros y en 21 capitulos de Juan, pero puede haber libros sin
      // nota. Lo que el modulo tiene es lo que se ofrece, y lo que no tiene no aparece.
      vm.leer(const Referencia('John', 3));
      final m = vm.modulo!;

      expect(m.libros().length, 66);
      expect(m.capitulosDe('John').length, 21);
      expect(vm.librosDisponibles.length, 66);
    });

    test('el selector de versiculos ofrece los que TIENEN nota', () {
      // Y NO LOS 36 DEL CAPITULO. Juan 3 tiene 36 versiculos con texto y 32 con nota, y
      // ofrecer los 36 lleva a cuatro pantallas vacias sin explicacion.
      final numeros = vm.modulo!.numerosDeVersiculos(const Referencia('John', 3));

      expect(numeros.length, 32);
      expect(numeros.contains(1), isFalse);
      expect(numeros.contains(16), isTrue);
      // Y ESTA EN ORDEN. Sin `ORDER BY`, SQLite puede devolverlos en cualquier orden y el
      // selector sale desordenado.
      expect(numeros, orderedEquals(<int>[...numeros]..sort()));
    });
  });
}

/// El cuerpo del texto principal, en el tamaño que le toca.
///
/// Y ES UNA FUNCION Y NO UN `expect` CON `find`, porque hace falta **comparar dos
/// medidas**: la del versiculo y la de la nota. Medir las dos por separado con dos
/// `expect` no dice cual es cual.
Future<double?> _tamanoDelCuerpo(
  WidgetTester tester, {
  required bool comentario,
  required String empiezaCon,
}) async {
  final abiertoComentario = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
  final abiertaBiblia = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
  if (abiertoComentario is! Abierto || abiertaBiblia is! Abierto) {
    fail('los modulos reales no abren');
  }
  addTearDown(abiertoComentario.modulo.cerrar);
  addTearDown(abiertaBiblia.modulo.cerrar);

  // Y EL NOMBRE DEL PARAMETRO ES `comentario` Y EL DEL FICHERO ES `abiertoComentario`,
  // porque con el mismo nombre el `comentario ? comentario.modulo` lee como si se
  //|Referenciara a si mismo. Y eso es lo que pasaba.
  final vm = LectorViewModel();
  vm.abrir(
    comentario ? abiertoComentario.modulo : abiertaBiblia.modulo,
    licenciaDelManifiesto: null,
  );
  vm.leer(const Referencia('John', 3, 16));
  addTearDown(vm.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: temaDeAb(),
      home: LectorView(
        viewModel: vm,
        alVolver: () {},
        alPulsarPasaje: vm.leer,
        alPedirComentario: () {},
      alVerIndice: (_) {},
        alCambiarDeVersion: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Y SE MIRA DE LOS DOS TIPOS DE TEXTO, y no solo de `Text`. Un versiculo con
  // anotaciones se pinta con `Text.rich`, que **no** es un `Text`: dentro hay
  // `TextSpan`, y su texto se saca con `toPlainText()`.
  //
  // La primera version de esta comprobacion solo miraba `Text` y devolvia null en el
  // versiculo con lexicon, o sea que la comparacion "la nota es mas pequena que el
  // versiculo" se quedaba sin mitad y daba verde sin comprobar.
  for (final texto in tester.widgetList<Text>(find.byType(Text))) {
    final estilo = texto.style;
    if (estilo == null || texto.data == null) continue;
    if (texto.data!.startsWith(empiezaCon)) return estilo.fontSize;
  }

  for (final rico in tester.widgetList<RichText>(find.byType(RichText))) {
    // Y `text` NO PUEDE SER NULL aqui, segun el tipo, asi que la comprobacion sobraria y el
    // analizador avisa. `TextSpan.style` si puede ser null, y ese es el que se mira.
    if (!rico.text.toPlainText().startsWith(empiezaCon)) continue;
    return rico.text.style?.fontSize;
  }

  fail('no hay ningun texto que empiece por "\$empiezaCon"');
}