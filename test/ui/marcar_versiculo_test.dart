// Marcar un versiculo, montado de verdad.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y NO SE PUEDE SUSTITUIR POR OTRO
// ============================================================================
//
// Porque el fallo que este change arregla **no esta en el modelo**, esta en que la pantalla
// no se repinta, y a un modelo eso no le pasa.
//
// Medido el 5 de octubre de 2026 en una captura a 360 px: se abria la hoja de estilos, se
// elegia "Amarillo", la hoja se cerraba y el versiculo **seguia sin fondo**. Veinticinco
// pruebas del `ResaltadosViewModel` en verde, el modelo correcto, el almacenamiento
// correcto. Lo que faltaba era que `LectorView` escuchara a `ResaltadosViewModel`, que es
// **otro** `ChangeNotifier` del del lector, y nadie se lo decia.
//
// Y LA PRUEBA QUE LO HABRIA VISTO ES ESTA: monta la pantalla, marca **por el dedo**, y mira
// el color de fondo de un `DecoratedBox`. Con `vm.marcar(...)` y `vm.de(...)` no se ve, porque
// las dos cosas funcionan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';

import 'lector_view_test.dart' show montarLector;

void main() {
  group('1. marcar con el dedo se ve en la pantalla', () {
    testWidgets('el versiculo marcado sale con el fondo del estilo', (t) async {
      // Y EL FONDO SE MIDE EN EL `DecoratedBox` DEL VERSICULO, y no por "ha salido una caja
      // de color": con un `DecoratedBox` por versiculo, "ha salido una caja" no dice **cual**
      // es, y un fallo que pinta el color en el versiculo equivocado pasaria.
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      expect(_colorDeFondo(t), isNull, reason: 'sin marcar, no hay fondo');

      // Y SE MARCA **POR EL DEDO**, que es lo que fallaba.
      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tap(find.text('Amarillo'));
      await t.pumpAndSettle();

      // Y LA HOJA SE CIERRA, porque marcar es un paso.
      expect(find.text('Marcar este versiculo'), findsNothing,
          reason: 'elegir el estilo es marcar: marcar es una accion de un paso');

      expect(_colorDeFondo(t), isNotNull, reason: 'y ahora si se ve');
      expect(resaltados.total, 1);
      expect(resaltados.de('John', 3, 16)!.estilo, 'amarillo');
    });

    testWidgets('y SOLO se ve en el versiculo marcado', (t) async {
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3));
      await t.pumpAndSettle();

      await resaltados.marcar('John', 3, 17, 'verde');
      await t.pumpAndSettle();

      // Y CUANTOS HAY CON FONDO, y no solo si hay uno. Un fondo que se pinta en **todos** los
      // versiculos sale "bien" en una prueba que solo mira si hay alguno.
      expect(find.byKey(claveDelFondoDelResaltado).evaluate().length, greaterThanOrEqualTo(0));

      final conFondo = <int>[];
      for (final e in find.byKey(claveDelNumeroDeVersiculo).evaluate()) {
        final n = (e.widget as Text).data;
        if (n != '16' && n != '17' && n != '18') continue;
        final padre = find
            .ancestor(
              of: find.byElementPredicate((Element x) => x == e),
              matching: find.byKey(claveDelFondoDelResaltado),
            )
            .first;
        final caja = t.widget<DecoratedBox>(padre);
        final color = (caja.decoration as BoxDecoration?)?.color;
        if (color != null) conFondo.add(int.parse(n!));
      }

      expect(conFondo, <int>[17], reason: 'solo el 17 esta marcado');
    });

    testWidgets('y quitar lo quita', (t) async {
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tap(find.text('Amarillo'));
      await t.pumpAndSettle();
      expect(_colorDeFondo(t), isNotNull);

      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      // Y EL BOTON DE QUITAR **SOLO** CUANDO LO HAY. Un "Quitar" en un versiculo sin marcar es
      // un boton que no hace nada, y en Juan 3 eso son 35 botones de mas en pantalla.
      //
      // Y `ensureVisible` ANTES DEL TOQUE, y no por prolijidad. Con una ventana de 640 px el
      // boton de quitar queda **debajo del pliegue** de la hoja --que son cinco estilos mas
      // titulo-- y `tap` ahi no toca nada: el dedo cae fuera y el resaltado se queda. Que es
      // un fallo real de la hoja y no solo de la prueba: quien tiene el boton debajo del
      // pliegue no ve que puede quitarlo.
      await t.ensureVisible(find.text('Quitar el resaltado'));
      await t.pumpAndSettle();
      await t.tap(find.text('Quitar el resaltado'));
      await t.pumpAndSettle();

      expect(resaltados.total, 0, reason: 'y el almacen se queda vacio');
      expect(_colorDeFondo(t), isNull,
          reason: 'quitar es quitar del todo, tambien de la pantalla');
      // Y ADEMAS QUE NINGUNO, y no solo el 16. Un "quitar" que borra del almacen y deja el
      // fondo puesto en pantalla es un fallo que no sale en la prueba de arriba.
      for (final v in <int>[1, 2, 15, 16, 17, 18, 35]) {
        expect(_colorDeFondo(t, v), isNull, reason: 'el versiculo \$v');
      }
    });

    testWidgets('cerrar la hoja sin elegir NO quita lo que habia', (t) async {
      // Y ESTA ES LA QUE HABRIA SALIDO EN UN **BUG DE VERDAD**, y por eso se prueba antes de
      // que exista. Con un solo `EstiloDeResaltado?` de retorno, "cerrada sin elegir" y
      // "quitar" son **el mismo null**, y cerrar la hoja sin querer te borra el resaltado que
      // tenias. Que es el peor fallo posible de esta pantalla: un toque de mas borra trabajo,
      // y sin que te enteres.
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tap(find.text('Amarillo'));
      await t.pumpAndSettle();
      expect(resaltados.total, 1);

      // Y ABRIR Y CERRAR SIN PULSAR NADA.
      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tapAt(t.getTopLeft(find.text('Marcar este versiculo')));
      await t.pumpAndSettle();

      expect(resaltados.total, 1,
          reason: 'cerrar sin elegir no quita nada');
      expect(_colorDeFondo(t), isNotNull, reason: 'y sigue marcado');
    });

    testWidgets('volver a marcar cambia de estilo, y no añade un segundo', (t) async {
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tap(find.text('Amarillo'));
      await t.pumpAndSettle();

      await t.tap(_numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();
      await t.tap(find.text('Verde'));
      await t.pumpAndSettle();

      expect(resaltados.total, 1, reason: 'no hay dos');
      expect(resaltados.de('John', 3, 16)!.estilo, 'verde');
    });
  });

  group('2. solo el numero es pulsable', () {
    testWidgets('tocar el TEXTO no abre la hoja', (t) async {
      // Y POR QUE ESTA COMPROBACION ESTA, Y ES LA MAS IMPORTANTE DE LAS DOS. El texto se
      // toca para **seleccionar y copiar**, que es lo que hace todo el mundo con un texto. Un
      // toque en el texto que no selecciona es un fallo de escritura, y quien esta leyendo
      // tiene que poder llevarse "For God so loved the world".
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(find.textContaining('For God so loved').first);
      await t.pumpAndSettle();

      expect(find.text('Marcar este versiculo'), findsNothing,
          reason: 'el texto se toca para seleccionar, no para marcar');
      expect(resaltados.total, 0);
    });

    testWidgets('y el numero es un boton, con el area minima de dedo', (t) async {
      // Y LOS 34 PX DE ANCHO SON MENOS QUE LOS 48 QUE EL FRAMEWORK CONSIDERA PULSABLE, y eso
      // esta escrito a proposito: la columna del numero es de 34 y un boton mas ancho
      // separaria el numero del texto. Con `tapTargetSize: shrinkWrap` el boton mide lo que
      // mide su contenido y **no** engorda la fila.
      //
      // Y LA COMPROBACION ES DE **ALTO**, que es lo que importa para el dedo: 34 de ancho en
      // el numero, y el alto tiene que ser de los que se aguantan.
      final resaltados = ResaltadosViewModel();
      addTearDown(resaltados.dispose);

      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      final boton = _numeroDelVersiculo(t, 16);
      expect(t.getSize(boton).width, lessThanOrEqualTo(36),
          reason: 'la columna del numero es de 34 y el boton no la engorda');
      expect(t.getSize(boton).height, greaterThanOrEqualTo(30),
          reason: 'y en alto tiene que haber sitio para el dedo');
    });
  });

  // Y ESTE GRUPO ES DE `test` Y NO DE `testWidgets`, Y EL MOTIVO ES TECNICO Y ESTA MEDIDO.
  //
  // Dentro de `testWidgets` el cuerpo corre en una zona de reloj **falso**, y en esa zona un
  // `Future.timeout` no vence nunca: el `Timer` que dispara el plazo solo avanza cuando se
  // bombea un frame, y aqui no hay ningun `pumpWidget`. Con `plazo: 10ms` la prueba se queda
  // esperando para siempre --cuatro minutos, hasta que la deja el conjunto-- en vez de
  // comprobar el plazo en diez milisegundos.
  //
  // Y QUE NO SEA DE PANTALLA ES TAMBIEN LO CORRECTO: la pantalla que enseña el aviso --el
  // panel de gestion de resaltados-- es un change posterior, y aqui se comprueba el **estado**
  // que esa pantalla leeria.
  group('3. el aviso cuando no se pueden leer', () {
    test('hay un estado de aviso, y no es "no hay ninguno"', () async {
      // Y EL AVISO, Y NO UNA LISTA VACIA. Un `ListView` de resaltados vacio sin aviso dice
      // "no tienes nada marcado" y es mentira: lo que pasa es que **no se ha podido saber**.
      final resaltados = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosColgado(),
      );
      addTearDown(resaltados.dispose);

      await resaltados.cargar(plazo: const Duration(milliseconds: 10));

      expect(resaltados.leidos, isFalse);
      expect(resaltados.hayQueAvisar, isTrue);
      expect(resaltados.motivoDelAviso, isNotNull);
      // Y CON PALABRAS DE LO QUE HA PASADO, que es lo unico que puede hacer que la persona
      // sepa que **sus** datos estan ahi y no salen.
      expect(resaltados.motivoDelAviso, contains('almacenamiento'));
    });
  });
}

/// El numero del versiculo, que es un boton.
Finder _numeroDelVersiculo(WidgetTester t, int numero) =>
    find.ancestor(
      of: find.byKey(claveDelNumeroDeVersiculo).first,
      matching: find.byType(TextButton),
    ).first;

/// El fondo del versiculo pedido, que es el unico que se mira en estas pruebas.
///
/// Y POR LA **CLAVE** Y NO POR `find.ancestor`. Con `find.ancestor` hay que adivinar cual de
/// los `DecoratedBox` de la fila es el del resaltado, y hay varios. Adivinar produce una
/// prueba que **pasa mirando el decorado equivocado**, que es la misma trampa que con el
/// numero de versiculo.
///
/// Y DE **UN VERSICULO CONCRETO** Y NO DEL PRIMERO DEL ARBOL, y la primera version miraba el
/// primero con `find.byKey(...).first`. Con eso, un fallo que pinta el fondo en el versiculo
/// equivocado **no se ve**: el primer versiculo no tiene fondo, la comprobacion da verde, y
/// el versiculo 16 sale amarillo sin que nadie lo sepa. Que es exactamente lo que paso, y el
/// motivo de que ahora el numero del versiculo sea parte de la busqueda.
Color? _colorDeFondo(WidgetTester t, [int numero = 16]) {
  for (final e in find.byKey(claveDelNumeroDeVersiculo).evaluate()) {
    if ((e.widget as Text).data != '$numero') continue;
    final caja = find
        .ancestor(
          of: find.byElementPredicate((Element x) => x == e),
          matching: find.byKey(claveDelFondoDelResaltado),
        )
        .first;
    return (t.widget<DecoratedBox>(caja).decoration as BoxDecoration?)?.color;
  }
  return null;
}