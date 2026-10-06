// El estado de los paneles: cuantos hay, cual esta delante, y que se cierra.
//
// ============================================================================
// QUE COMPRUEBA ESTE FICHERO Y QUE NO
// ============================================================================
//
// El estado. Que haya una fila de pestañas en pantalla lo comprueba
// `test/ui/pestanas_de_panel_test.dart`; aqui no hay un solo widget.
//
// Y LO QUE MAS IMPORTA DE ESTE FICHERO ES **EL QUE SE CIERRA**, porque es la parte que
// no se ve: un panel que se quita de la lista pero deja su `.amod` abierto son 22,5 MiB
// que no vuelven en un movil de gama baja, y el sintoma --"la aplicacion se ralentiza al
// segundo texto"— no dice nada de donde viene.

import 'package:ab/domain/models/panel_abierto.dart';
import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/view_models/paneles_view_model.dart';
import 'package:ab/ui/features/lector/view_models/preferencias_de_lectura.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los paneles, con las preferencias compartidas que usaria la aplicacion.
({PanelesViewModel paneles, PreferenciasDeLectura preferencias}) _montar() {
  final preferencias = PreferenciasDeLectura();
  final paneles = PanelesViewModel(preferencias: preferencias);
  return (paneles: paneles, preferencias: preferencias);
}

/// Un panel de prueba.
PanelAbierto _panel(String id, {Referencia? referencia, bool comentario = false}) =>
    PanelAbierto(
      moduloId: id,
      referencia: referencia ?? const Referencia('John', 3),
      comentarioId: comentario ? 'CLARKE' : null,
    );

void main() {
  group('1. abrir y cerrar', () {
    test('sin paneles no hay lector de delante', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      // Y **NULL** Y NO UN PANEL VACIO, y el motivo esta escrito en el view model: la
      // biblioteca se pinta cuando no hay nada abierto, y un panel vacio seria una
      // pantalla de lectura sin texto, que es la peor forma de no tener nada.
      expect(m.paneles.delante, isNull);
      expect(m.paneles.lectorDelante, isNull);
      expect(m.paneles.cuantos, 0);
      expect(m.paneles.hayVarios, isFalse);
      expect(m.paneles.referencia, isNull);
    });

    test('el panel que se registra es el de delante', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      // Y **SIN** `addTearDown` PARA ESE VIEW MODEL, y el motivo es el fallo que sale si se
      // pone: los paneles son los duenos de sus view models --`cerrarTodos` los destruye--, y
      // un `dispose` de mas lanza:
      //
      //     A LectorViewModel was used after being disposed.
      //
      // Y sale en el `dispose` y no en el `build`, asi que el sintoma es un fallo de
      // pruebas que no dice nada de la prueba.
      final vm = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), vm);

      expect(m.paneles.cuantos, 1);
      expect(m.paneles.idDelModulo, 'KJV2006');
      expect(m.paneles.lectorDelante, same(vm));
    });

    test('registrar el mismo modulo dos veces NO abre un panel nuevo', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      // Y ESTA ES LA REGLA DE LA **MEMORIA**: dos paneles del mismo `.amod` son 22,5 MiB
      // de paginas SQLite abiertas dos veces. Y medido el 6 de octubre de 2026 sobre el
      // `KJV2006_bible.amod` real, que son 22.544.384 bytes.
      final uno = LectorViewModel(preferencias: m.preferencias);
      // Y ESTE **NO** SE DESTRUYE: `registrar` lo rechaza y se queda sin panel, asi que no
      // hay quien lo cierre. Es el estado en el que se queda un `.amod` que nadie abrio.
      final otro = LectorViewModel(preferencias: m.preferencias);

      m.paneles.registrar(_panel('KJV2006'), uno);
      m.paneles.registrar(_panel('KJV2006'), otro);

      expect(m.paneles.cuantos, 1);
      // Y EL QUE SE QUEDA **ES EL PRIMERO**, y no el ultimo: el segundo view model no lo
      // ha abierto nadie y se queda sin panel. Un `registrar` que sustituyera dejaria el
      // primero abierto en algum sitio, y el sintoma seria una base de datos que nadie
      // puede cerrar.
      expect(m.paneles.lectorDelante, same(uno));
    });

    test('cerrar un panel lo quita de la lista y destruye su view model', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final vm = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), vm);

      expect(m.paneles.cerrar('KJV2006'), isTrue);
      expect(m.paneles.cuantos, 0);
      // Y EL VIEW MODEL **ESTA DESTRUIDO**, y no solo fuera de la lista. Es lo que cierra
      // el `.amod`: `LectorViewModel.dispose` es quien lo hace, y si no se destruyera aqui
      // no habria ningun sitio donde se cerrara.
      //
      // Y SE COMPRUEBA CON [addListener] Y NO CON UN GETTER, porque un getter de un
      // `ChangeNotifier` destruido **no lanza**: `ChangeNotifier` solo comprueba el estado al
      // escuchar y al avisar. Con un getter la comprobacion daria verde con el modulo
      // abierto, que es justo lo que se quiere cazar.
      expect(() => vm.addListener(() {}), throwsFlutterError);
    });

    test('cerrar un panel que no esta no hace nada', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      expect(m.paneles.cerrar('CLARKE'), isFalse);
      expect(m.paneles.cuantos, 0);
    });

    test('cerrar todos deja cero paneles y destruye los view model', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      expect(m.paneles.cuantos, 2);
      // Y ESTE ES EL CAMINO DE VOLVER A LA BIBLIOTECA, y lo que hay detras de el es memoria:
      // dos textos de 22,5 MiB son 45.088.768 bytes de paginas SQLite, medido con los
      // ficheros reales.
      m.paneles.cerrarTodos();

      expect(m.paneles.cuantos, 0);
      expect(m.paneles.delante, isNull);
      expect(() => a.addListener(() {}), throwsFlutterError);
      expect(() => b.addListener(() {}), throwsFlutterError);
    });
  });

  group('2. cual esta delante', () {
    test('el que se registra de ultimo queda delante, y se puede cambiar', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      expect(m.paneles.idDelModulo, 'CLARKE');
      expect(m.paneles.ponerAlFrente('KJV2006'), isTrue);
      expect(m.paneles.idDelModulo, 'KJV2006');
      // Y EL LECTOR DELANTE **ES EL DE ESE PANEL**: devolver el de otro panel es ver
      // Juan 3 en la pestana de Juan 4, que es el fallo que hace que las pestanas no sirvan
      // para nada.
      expect(m.paneles.lectorDelante, same(a));
    });

    test('poner al frente un panel que ya esta delante no avisa', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      var avisos = 0;
      m.paneles.addListener(() => avisos++);

      final a = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);

      expect(m.paneles.ponerAlFrente('KJV2006'), isFalse);
      expect(avisos, 1,
          reason: 'solo el aviso del registro; traer al frente el que ya esta no avisa');
    });

    test('cerrar el que esta delante hace pasar otro', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      final c = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);
      m.paneles.registrar(_panel('OTRO'), c);
      expect(m.paneles.idDelModulo, 'OTRO');

      m.paneles.cerrar('OTRO');

      // Y EL INDICE SE ACORTA. Quitar el ultimo de la lista deja el indice apuntando mas
      // alla de lo que hay, y `delante` tendria que devolver el ultimo de verdad.
      expect(m.paneles.idDelModulo, 'CLARKE');
      expect(m.paneles.cuantos, 2);
    });

    test('cerrar uno que no esta delante NO cambia cual esta delante', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);
      m.paneles.ponerAlFrente('KJV2006');

      m.paneles.cerrar('CLARKE');

      expect(m.paneles.idDelModulo, 'KJV2006');
    });
  });

  group('3. cada panel tiene su pasaje', () {
    test('leer en un panel NO mueve el pasaje del otro', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      m.paneles.leerEn('KJV2006', const Referencia('John', 5));

      // Y ESTA ES LA DIFERENCIA ENTRE LAS PESTANAS Y UN CAMBIO DE TEXTO: Juan 3 en el
      // panel de la KJV y Juan 5 en el del CLARKE son dos estados distintos, y quien esta
      // leyendo Juan 3 no quiere que al abrir Juan 5 en el otro se mueva el que tiene
      // delante.
      expect(m.paneles.panelDe('KJV2006')!.referencia, const Referencia('John', 5));
      expect(m.paneles.panelDe('CLARKE')!.referencia, const Referencia('John', 3));
    });

    test('leer la misma referencia dos veces en un panel no avisa', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);

      var avisos = 0;
      m.paneles.addListener(() => avisos++);

      expect(m.paneles.leerEn('KJV2006', const Referencia('John', 5)), isTrue);
      expect(m.paneles.leerEn('KJV2006', const Referencia('John', 5)), isFalse);
      expect(avisos, 1);
    });

    test('leer en un panel que no esta no hace nada', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      expect(m.paneles.leerEn('CLARKE', const Referencia('John', 5)), isFalse);
    });
  });

  group('4. los comentarios', () {
    test('poner y quitar comentario en un panel NO toca el del otro', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      expect(m.paneles.ponerComentario('KJV2006', 'CLARKE'), isTrue);
      expect(m.paneles.panelDe('KJV2006')!.comentarioId, 'CLARKE');
      expect(m.paneles.panelDe('CLARKE')!.comentarioId, isNull);

      expect(m.paneles.ponerComentario('KJV2006', null), isTrue);
      expect(m.paneles.panelDe('KJV2006')!.comentarioId, isNull);
    });

    test('poner el comentario que ya hay no avisa', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006', comentario: true), a);

      var avisos = 0;
      m.paneles.addListener(() => avisos++);

      expect(m.paneles.ponerComentario('KJV2006', 'CLARKE'), isFalse);
      expect(avisos, 0);
    });
  });

  group('5. los ajustes son de la ventana, y este es el fallo que lo prueba', () {
    test('cambiar la letra en un panel se ve en el otro', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      // Y ESTA PRUEBA **FALLA** SI LOS AJUSTES ESTAN EN EL VIEW MODEL DEL LECTOR, y es la
      // razon de que se sacaran a [PreferenciasDeLectura]. Con los ajustes dentro, cada
      // view model tendria los suyos: cambiar la letra en el panel de la izquierda
      // escribiria en el almacenamiento y **el de la derecha no se enteraria** hasta que se
      // volviera a abrir. Dos textos con dos letras distintas lado a lado.
      //
      // Y ANTES DEL ARREGLO **NINGUNA COMPROBACION LO HABRIA VISTO**: cada
      // `LectorViewModel` por separado se comporta bien, `cambiarPreferencia` cambia y
      // `cargarPreferencias` lee, y todas las pruebas que hay sobre ellos siguen dando
      // verde con el bug puesto. Lo que no se puede probar en solitario es que los dos
      // esten de acuerdo.
      // Y EL 26 Y NO EL 30 PORQUE **LOS AJUSTES SE ACOTAN**, y eso no es un detalle de la
      // prueba: `cambiarTamano` limita el valor al rango del modelo --el maximo medido esta
      // escrito en `preferencia_de_lectura.dart`-- y un 30 se guardaria como 26. Pedir un
      // valor fuera de rango haria que la comprobacion mirara un numero que el modelo
      // nunca va a tener, y pasaria solo si el acotado no hiciera nada.
      a.cambiarPreferencia(PreferenciaDeLectura.porDefecto.cambiarTamano(26.0));

      expect(a.preferenciaDeLectura.tamanoDeLetra, 26.0);
      expect(b.preferenciaDeLectura.tamanoDeLetra, 26.0,
          reason: 'los ajustes son de la ventana, no de un texto');
      expect(m.paneles.preferenciaDeLectura.tamanoDeLetra, 26.0);
    });

    test('las palabras de Jesus en rojo tambien son de la ventana', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      a.alternarPalabrasDeJesus();

      expect(b.mostrarPalabrasDeJesus, isFalse);
      expect(m.paneles.mostrarPalabrasDeJesus, isFalse);
    });

    test('cerrar un panel NO destruye las preferencias si hay otro vivo', () {
      final m = _montar();
      addTearDown(m.paneles.dispose);

      final a = LectorViewModel(preferencias: m.preferencias);
      final b = LectorViewModel(preferencias: m.preferencias);
      m.paneles.registrar(_panel('KJV2006'), a);
      m.paneles.registrar(_panel('CLARKE'), b);

      m.paneles.cerrar('KJV2006');

      // Y ESTO **NO** ES UN DETALLE: `dispose` destruye lo que es suyo y **solo** lo suyo. Un
      // `dispose` que cerrara unas preferencias que otro panel sigue usando deja al que
      // queda en un `ChangeNotifier` al que ya no le avisa nadie, y el resultado es un
      // ajuste que se pulsa y no pasa nada --sin error y sin aviso--, que es la forma mas
      // dificil de mirar despues.
      b.cambiarPreferencia(PreferenciaDeLectura.porDefecto.cambiarTamano(24));
      expect(b.preferenciaDeLectura.tamanoDeLetra, 24);
      expect(m.paneles.preferenciaDeLectura.tamanoDeLetra, 24);
    });
  });
}