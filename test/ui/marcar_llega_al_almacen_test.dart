// Que la hoja de estilos se pueda usar de verdad.
//
// ============================================================================
// POR QUE ESTE FICHERO Y NO UNA CAPTURA
// ============================================================================
//
// Y POR QUE AQUI NO ESTA LA PRUEBA DE QUE MARCAR LLEGA AL ALMACEN, que es lo que hacia este
// change. Ya esta, en `almacenamiento_de_resaltados_test.dart`, grupo 3: view model, almacen y
// fichero, y sobrevive a cerrar y volver a abrir.
//
// Y NO SE HA INTENTADO AQUI, Y ESTA ES LA RAZON Y ES UN DATO: una prueba de `testWidgets` que
// toca un versiculo y **lee un fichero** se queda colgada. Dentro de `testWidgets` el reloj es
// falso, un `Future` de E/S real no avanza porque solo avanza el reloj al bombear un frame, y
// la prueba muere con
//
//     did not complete
//
// al cabo de varios minutos, sin mencionar ni el fichero ni el reloj. Medido el 6 de octubre
// de 2026: **cuatro minutos y cincuenta y dos segundos** antes de decir una frase que no
// señala el motivo. Con `runAsync` tampoco, porque el problema no es leer sino que la
// escritura la dispara un `await` de la propia prueba.
//
// Y LO QUE MIDE ESTE FICHERO ES LA ALTURA DE LA HOJA, porque medido en el navegador el 6 de
// octubre de 2026 la hoja de estilos media **145 px** en una ventana de 900 y en una de 1200:
// los mismos 145, con los cinco estilos **debajo del pliegue**.
//
// Y ES EL MISMO FALLO QUE EL `RenderFlex overflowed by 216 pixels` QUE EL `SingleChildScrollView`
// TAPO: uno da una excepcion y el otro no da ninguna, y los dos dejan la hoja inservible. Un
// `SingleChildScrollView` **no pide** su alto natural --lo pide infinito-- asi que con el
// `isScrollControlled` de por defecto la hoja se conforma con lo que le dan y no crece.
//
// Con `SingleChildScrollView` se tapo la excepcion y la hoja dejo de crecer. Un
// `SingleChildScrollView` **no pide** su alto natural: lo pide infinito. Con
// `isScrollControlled: false` --lo de por defecto-- la hoja tampoco crece, porque su alto
// maximo es una fraccion de la pantalla que se aplica **al hijo**, y el hijo no la pide.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';

import 'lector_view_test.dart' show montarLector;
import 'marcar_versiculo_test.dart' show numeroDelVersiculo;

void main() {
  group('1. la hoja se puede usar', () {
    for (final alto in <double>[640, 900, 1200]) {
      testWidgets('a $alto px de alto, los cinco estilos se ven', (t) async {
        // Y SE MIDE **LA HOJA ENTERA**, y no si el texto "Amarillo" existe en el arbol. Un
        // `find.text` encuentra un widget que esta **fuera de la ventana**, y ahi no se ve y no
        // se puede tocar: es el caso que se dio con los 145 px, donde los cinco estilos
        // existian en el arbol y no se veia ninguno.
        final almacen = AlmacenamientoDeResaltadosEnMemoria();
        addTearDown(almacen.dispose);
        final resaltados = ResaltadosViewModel(almacenamiento: almacen);
        addTearDown(resaltados.dispose);
        final vm = await montarLector(t, resaltados: resaltados);
        vm.leer(const Referencia('John', 3, 16));
        await t.pumpAndSettle();

        t.view.physicalSize = Size(360, alto);
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.reset);
        await t.pumpAndSettle();

        await t.tap(numeroDelVersiculo(t, 16));
        await t.pumpAndSettle();

        final ventana = t.view.physicalSize.height / t.view.devicePixelRatio;
        for (final nombre in <String>['Amarillo', 'Verde', 'Azul', 'Rosa', 'Naranja']) {
          final caja = t.getRect(find.text(nombre));
          expect(
            caja.bottom,
            lessThanOrEqualTo(ventana),
            reason: 'el estilo $nombre sale hasta ${caja.bottom.toStringAsFixed(1)} y la '
                'ventana acaba en $ventana: esta **debajo del pliegue**, se ve a medias y '
                'no se puede tocar',
          );
        }
      });
    }

    testWidgets('y la hoja es mas alta que el titulo y el subtitulo', (t) async {
      // Y ESTA ES LA COMPROBACION DE LA **FORMA** Y NO DEL RESULTADO, y es la que habria
      // parado los 145 px. Una hoja que se conforma con lo que le dan y no pide su alto
      // natural cabe siempre y no se ve nunca: no desborda, no lanza, y no sirve.
      final almacen = AlmacenamientoDeResaltadosEnMemoria();
      addTearDown(almacen.dispose);
      final resaltados = ResaltadosViewModel(almacenamiento: almacen);
      addTearDown(resaltados.dispose);
      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(numeroDelVersiculo(t, 16));
      await t.pumpAndSettle();

      final titulo = t.getRect(find.text('Marcar este versiculo'));
      final amarillo = t.getRect(find.text('Amarillo'));
      expect(amarillo.top, greaterThan(titulo.bottom),
          reason: 'el primer estilo tiene que estar **debajo** del titulo, no al lado');
      expect(amarillo.height, greaterThan(0));
    });
  });
}

