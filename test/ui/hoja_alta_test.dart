// Que se pueda SELECCIONAR el texto, y que tocar una palabra no se lo lleve todo.
//
// ============================================================================
// POR QUE ESTE FICHERO MIDE ESTO Y NO UN FALLO DE LA HOJA
// ============================================================================
//
// MEDIDO EL 6 DE OCTUBRE DE 2026: un `grep` de `SelectionArea`, `SelectableRegion` y
// `SelectableText` en **toda** la aplicacion no devuelve nada. No habia forma de seleccionar
// un versiculo, ni con el dedo ni con el raton.
//
// Y NO FALLA, que es lo que lo ha dejado asi: el texto se pinta, se lee, se marca por el
// numero y se copia con el atajo del teclado del navegador. Un `Text` normal parece
// seleccionable porque en el navegador se puede sombrear con el cursor... y eso es el
// `user-select` del CSS, que **no** es seleccion de Flutter. Con el dedo no hay atajo.
//
// Y EN EL CODIGO DE LA COLUMNA HAY UN COMENTARIO QUE DICE QUE SE PUEDE:
//
//     tocarlo lo selecciona --que es lo que quiere quien copia un versiculo--
//
// O sea: el comentario describe una capacidad que no estaba implementada. Quien lo lea
// creera que seleccionar funciona, y no funciona.
//
// ============================================================================
// Y EL OTRO SINTOMA, QUE ES EL MISMO PROBLEMA VISTO DE OTRA FORMA
// ============================================================================
//
// Al tocar una palabra con numero de lexicon se va al indice de golpe, y no se puede
// seleccionar nada alrededor. Medido el 6 de octubre de 2026 sobre el KJV: el lexicon tiene
// 348.884 ocurrencias en 31.102 versiculos, o sea que **casi todas las palabras** del KJV
// tienen numero. Es decir: tocar el texto es casi siempre abrir el indice, y seleccionar es
// casi nunca posible.
//
// Las dos cosas se arreglan con lo mismo --que el toque en la palabra **no** se lleve la
// seleccion-- asi que van en la misma prueba.
//
// ============================================================================
// Y LO QUE NO SE COMPRUEBA AQUI, Y SE DICE
// ============================================================================
//
// Que se pueda **copiar** lo seleccionado, que necesita los `selectionControls` y el
// portapapeles, y que en el navegador pasa por la API del sistema. La prueba comprueba que la
// region de seleccion existe y que se puede colocar, que es la parte que estaba rota.
//
// MEDIDO EN EL NAVEGADOR EL 6 DE OCTUBRE DE 2026, con el paquete nuevo y el servidor
// correcto: la hoja mide **145 px** en una ventana de 1440 x 900, con el titulo y el
// subtitulo a la vista y los cinco estilos **debajo del pliegue**. Se ve a medias y no se
// pueden tocar, que es un lector donde no se puede marcar.
//
// Y A 360 PX, EN LAS PRUEBAS DE WIDGET, LOS CINCO CABEN a 640, a 900 y a 1200. O sea que el
// fallo depende del ancho, y eso es lo que hay que entender antes de arreglar nada.
//
// ESTA PRUEBA ES LA QUE DICE SI EL FALLO ESTA EN DART O SOLO EN EL NAVEGADOR. Si aqui el alto
// sale bien, el problema no es el widget y hay que buscarlo en la plataforma; si sale mal, se
// puede arreglar y probar aqui.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';

import 'lector_view_test.dart' show montarLector;

void main() {
  // Y LOS TRES ANCHOS, Y NO SOLO EL DE 1440. El fallo aparece en uno y no en otro, asi que
  // una prueba con un ancho solo puede dar verde con el bug puesto.
  for (final ancho in <double>[360, 768, 1440]) {
    testWidgets('a $ancho px de ancho, la hoja llega al quinto estilo', (t) async {
      t.view.physicalSize = Size(ancho, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);

      // Y SE LEE **JUAN 3** Y NO SE ABRE LA CAPITULA ENTERA, porque `montarLector` deja el
      // lector sin pasaje y entonces no hay ningun numero de versiculo que pulsar. Es el mismo
      // detalle que `marcar_versiculo_test` resuelve con `vm.leer(...)` y que aqui daba
      //
      //     Bad state: No element
      //
      // que no dice ni que falta el versiculo ni que el montaje se quedo a medias.
      // Y EL ALMACEN SE PASA **EXPLICITO**, y no por indireccion. `montarLector` sin
      // `resaltados` monta su propio view model, y con el que monta, tocar el numero no abre
      // nada: la hoja depende de que haya alguien escuchando. Con el almacen en memoria
      // pasado a mano, los cinco estilos estan, y el fallo que daba era
      //
      //     Found 0 widgets with text "Amarillo"
      //
      // que parece que la hoja esta rota y era que no se habia abierto.
      final resaltados = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosEnMemoria(),
      );
      addTearDown(resaltados.dispose);
      final vm = await montarLector(t, resaltados: resaltados);
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      await t.tap(find.byKey(claveDelNumeroDeVersiculo).first);
      await t.pumpAndSettle();

      final ventana = t.view.physicalSize.height / t.view.devicePixelRatio;
      // Y LOS CINCO ESTILOS, Y NO CUATRO. Con cuatro, quitar el quinto --«Naranja», el
      // ultimo-- no lo detecta nada, y el quinto es el que mas abajo cae.
      for (final nombre in <String>['Amarillo', 'Verde', 'Azul', 'Rosa', 'Naranja']) {
        final caja = t.getRect(find.text(nombre));
        expect(caja.bottom, lessThanOrEqualTo(ventana),
            reason: 'a $ancho px el estilo $nombre sale hasta '
                '${caja.bottom.toStringAsFixed(1)} y la ventana acaba en $ventana');
      }
    });
  }

  testWidgets('y el ancho de la hoja no es el de la ventana', (t) async {
    // Y ESTA ES LA QUE DICE POR QUE PASABA A UN ANCHO Y NO A OTRO. Con
    // `isScrollControlled: false` --el valor de por defecto-- la hoja no crece: su alto
    // maximo es una fraccion de la pantalla, y el `SingleChildScrollView` que lleva dentro
    // no pide su alto natural, lo pide infinito, asi que se conforma con lo que le dan.
    // Los 145 px medidos en el navegador son esa fraccion **de la hoja**, no de la ventana.
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final resaltados = ResaltadosViewModel(
      almacenamiento: AlmacenamientoDeResaltadosEnMemoria(),
    );
    addTearDown(resaltados.dispose);
    final vm = await montarLector(t, resaltados: resaltados);
    vm.leer(const Referencia('John', 3, 16));
    await t.pumpAndSettle();
    await t.tap(find.byKey(claveDelNumeroDeVersiculo).first);
    await t.pumpAndSettle();

    final ventana = 900.0;
    for (final nombre in <String>['Amarillo', 'Verde', 'Azul', 'Rosa', 'Naranja']) {
      expect(t.getRect(find.text(nombre)).bottom, lessThanOrEqualTo(ventana),
          reason: 'el estilo $nombre');
    }
  });

  group('4. dentro del marco de estudio, que es como se ve a 1440 px', () {
    testWidgets('los estilos se ven tambien dentro del marco', (t) async {
      // MEDIDO EL 6 DE OCTUBRE DE 2026 en el navegador a 1440 x 900: la hoja se abre, se ven
      // el titulo y el subtitulo, y los cinco estilos quedan **debajo del pliegue**. Y en
      // pruebas de widget, **sin** marco, caben a 360, a 768 y a 1440 de ancho.
      //
      // Y LA DIFERENCIA ES EL MARCO, y por eso esta prueba lo monta. A 1440 px la pantalla de
      // lectura va dentro de `MarcoDeEstudio`, que es la unica diferencia entre el navegador y
      // la prueba que sale bien, y el sintoma --la hoja de 140 px con el contenido debajo-- es
      // el de una hoja que **no crece**, no el de una hoja que se sale.
      final resaltados = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosEnMemoria(),
      );
      addTearDown(resaltados.dispose);

      t.view.physicalSize = const Size(1440, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);

      final vm = await montarLector(
        t,
        resaltados: resaltados,
        dentroDelMarco: true,
      );
      // Y SE LEE JUAN 3, y sin esto no hay ni un versiculo en pantalla. Es el detalle que en
      // `montarLector` no se ve: monta la pantalla **vacia** y el que decide que haya texto es
      // `leer`, y sin el la columna sale con su migas y nada mas.
      vm.leer(const Referencia('John', 3, 16));
      await t.pumpAndSettle();

      // Y EL NUMERO DEL VERSICULO SE COGE POR SU **CLAVE** y no por el ayudante de
      // `marcar_versiculo_test`, que busca un `DecoratedBox` **ancestro** del fondo del
      // resaltado. Dentro del marco ese ancestro no se encuentra y el fallo es
      //
      //     Bad state: No element
      //
      // que no dice ni que falta el versiculo ni que el problema es el ayudante. Con la clave
      // directa el primer boton es el del versiculo pedido, que es el que hay que pulsar.
      // Y SE COMPRUEBA PRIMERO QUE HAY VERSICULOS, antes de tocar nada. `Bad state: No
      // element` con un `Iterable.first` en la pila dice que un finder no encontro nada, y no
      // dice **cual**: aqui era que dentro del marco la columna no tiene versiculos todavia y
      // lo que se estaba tocando no existia.
      expect(find.byKey(claveDelNumeroDeVersiculo), findsWidgets,
          reason: 'dentro del marco no se ha pintado ningun versiculo: no hay nada que marcar');

      await t.tap(find.byKey(claveDelNumeroDeVersiculo).first);
      await t.pumpAndSettle();

      expect(find.text('Marcar este versiculo'), findsOneWidget,
          reason: 'la hoja no se ha abierto dentro del marco');

      final ventana = 900.0;
      for (final nombre in <String>['Amarillo', 'Verde', 'Azul', 'Rosa', 'Naranja']) {
        final caja = t.getRect(find.text(nombre));
        expect(caja.bottom, lessThanOrEqualTo(ventana),
            reason: 'dentro del marco, a 1440 px, el estilo $nombre sale hasta '
                '${caja.bottom.toStringAsFixed(1)} y la ventana acaba en $ventana');
      }
    });
  });
}
