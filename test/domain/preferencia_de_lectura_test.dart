// La preferencia de lectura: rangos, guardado y lo que se hace con lo que llega.
//
// ============================================================================
// POR QUE CASI TODO ESTE FICHERO ES "Y SI ME MANDAN ALGO RARO"
// ============================================================================
//
// Un ajuste de tipografia con un `Slider` no necesita muchas pruebas: el `Slider` no deja
// escribir 300. Lo que **si** necesita pruebas es lo que entra por la puerta de atrás, que es
// el almacenamiento, y por ahi llegan cuatro cosas que el control nunca mandaria:
//
//   1. una clave de una version anterior, **sin** el campo del ajuste que se acaba de anadir
//   2. un JSON a medias, si el guardado se corto
//   3. un numero fuera de rango, si alguien edito el almacenamiento
//   4. texto donde va un numero
//
// Y EL CASO 1 ES EL QUE MAS HA ROTO COSAS EN ESTE REPOSITORIO. La regla es una sola:
//
//   **Un campo que no se puede leer no puede tirar los campos que si se pueden.**
//
// Con la regla contraria --"si no se puede leer, usa los recomendados"-- el usuario que
// tenia el tamano en 20 y el alto de linea en 1,4, en el momento de anadir el espaciado,
// pierde los dos. Y el sintoma es desconcertante: aparece una aplicacion que ha vuelto a sus
// valores de fabrica sin que nadie los haya cambiado.
//
// ============================================================================
// Y LOS RANGOS ESTAN EN EL MODELO Y NO EN EL `Slider`
// ============================================================================
//
// El `Slider` los muestra, pero **no los impone**: el `min` y el `max` de un `Slider` son
// suggestions que se pueden cambiar desde codigo, y hay una via de la interfaz --el teclado--
// que tambien. Si los rangos estuvieran solo en el widget, un valor fuera de rango se
// guardaria fuera de rango y volveria con un `Slider` que dice una cosa y un texto que dice
// otra. Por eso estan en [PreferenciaDeLectura] y el widget los lee de ahi.

import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';

void main() {
  group('1. los valores de partida, y de donde salen', () {
    test('son los que estan escritos en el modelo, y estan ahi a proposito', () {
      // Y NO UNOS "REDONDOS" TIPO 18 Y 1,6 Y 0,02 PORQUE SON REDONDOS. Vienen de
      // `aletheia-reader`, donde estan medidos y con el motivo escrito. Lo que se copia es el
      // **criterio** --un valor por defecto con un motivo, no un valor por defectochosen-- y
      // no el codigo.
      final p = PreferenciaDeLectura.porDefecto;
      expect(p.tamanoDeLetra, 18);
      expect(p.altoDeLinea, 1.6);
      expect(p.espaciado, 0.02);
      expect(p.tema, TemaDeLectura.claro);
      expect(p.atenuacion, 1.0);
      expect(p.lineaEnfocada, 0);

      // Y QUE `porDefecto` Y EL CONSTRUCTOR **SIN ARGUMENTOS** SON LO MISMO, que es lo que
      // hace que "abrir por primera vez" y "restaurar valores" den lo mismo. Si fueran dos
      // listas, se separarian el dia que se cambiara un numero en una de ellas, y solo se
      // notaria en quien restaurase sin haber tocado nada.
      expect(const PreferenciaDeLectura(), same(PreferenciaDeLectura.porDefecto));
    });

    test('y el tamano por defecto no es el 16 de los campos de texto', () {
      // Y ESTA ES LA DISTINCION QUE MAS CONFUNDIRIA. En este tema el 16 px es el minimo de
      // un **campo de texto**, y lo impone el navegador del movil: por debajo de 16 hace zoom
      // al enfocar y descuelga la pagina. El cuerpo del texto no tiene ese problema, y a 16
      // px, medido, Juan 3 ocupa 16.848 pixeles a 360 de ancho.
      //
      // Asique los dos 16 son del mismo numero y de dos cosas distintas, y si el del texto
      // tambien bajara a 15 con la preferencia, escribir en el filtro de la biblioteca haria
      // que la pagina se descuelgue. Por eso el del campo **no** sale de la preferencia.
      expect(PreferenciaDeLectura.tamanoMinimo, greaterThanOrEqualTo(15));
      expect(PreferenciaDeLectura.porDefecto.tamanoDeLetra, 18);
    });
  });

  group('2. guardar y leer, sin excepciones', () {
    test('lo que se guarda se lee igual', () {
      final original = const PreferenciaDeLectura(
        tamanoDeLetra: 22,
        altoDeLinea: 2.1,
        espaciado: 0.07,
        tema: TemaDeLectura.oscuro,
        atenuacion: 0.55,
        lineaEnfocada: 3,
      );

      final leida = PreferenciaDeLectura.deserializar(original.serializar());

      expect(leida.tamanoDeLetra, 22);
      expect(leida.altoDeLinea, closeTo(2.1, 0.0001));
      expect(leida.espaciado, closeTo(0.07, 0.0001));
      expect(leida.tema, TemaDeLectura.oscuro);
      expect(leida.atenuacion, closeTo(0.55, 0.0001));
      expect(leida.lineaEnfocada, 3);
    });

    test('sin nada guardado sale lo de partida, y no se escribe nada', () {
      expect(PreferenciaDeLectura.deserializar(null), same(PreferenciaDeLectura.porDefecto));
      expect(PreferenciaDeLectura.deserializar(''), same(PreferenciaDeLectura.porDefecto));
    });

    test('un texto que no es JSON da los recomendados, y NO LANZA', () {
      // Y LA RAZON POR LA QUE ESTA HECHA SIN EXCEPCION: esto corre sobre un `localStorage`
      // que hay un caso **medido** de que nunca contesta, y un `throw` en un `await` de
      // arranque cuelga la pantalla entera. Un `catch` aqui no es prudencia: es
      // obligacion.
      for (final basura in <String>[
        'no soy json',
        '{',
        'null',
        '[]',
        '123',
        '{"t": }',
        '"un texto"',
      ]) {
        expect(
          () => PreferenciaDeLectura.deserializar(basura),
          returnsNormally,
          reason: 'con "$basura"',
        );
        expect(PreferenciaDeLectura.deserializar(basura).tamanoDeLetra, 18,
            reason: 'con "$basura"');
      }
    });
  });

  group('3. un campo malo NO tira los buenos', () {
    test('una clave antigua sin el espaciado respeta lo demas', () {
      // Y ESTE ES EL CASO IMPORTANTE, y el que mas caro sale cuando se anade un ajuste.
      //
      // Se simula una clave guardada por una version que no conocia el espaciado --que se
      // anadio despues-- escribiendo el JSON a mano, sin el campo.
      const guardada = '{"t": 22, "a": 2.1, "f": "oscuro", "n": 0.6, "l": 5}';

      final p = PreferenciaDeLectura.deserializar(guardada);

      expect(p.tamanoDeLetra, 22, reason: 'el tamano se respeta');
      expect(p.altoDeLinea, closeTo(2.1, 0.0001), reason: 'el alto de linea se respeta');
      expect(p.tema, TemaDeLectura.oscuro, reason: 'el tema se respeta');
      expect(p.atenuacion, closeTo(0.6, 0.0001), reason: 'la atenuacion se respeta');
      expect(p.lineaEnfocada, 5, reason: 'la linea enfocada se respeta');

      // Y SOLO EL CAMPO QUE FALTA sale en su recomendado. Uno, no todos.
      expect(p.espaciado, closeTo(0.02, 0.0001),
          reason: 'el espaciado, que no existia, sale en el suyo');
    });

    test('un campo con texto donde va un numero se sustituye solo', () {
      const guardada = '{"t": "22", "a": 2.1}';

      final p = PreferenciaDeLectura.deserializar(guardada);

      expect(p.tamanoDeLetra, 18, reason: '"22" es texto donde va un numero');
      expect(p.altoDeLinea, closeTo(2.1, 0.0001), reason: 'y el otro si se lee');
    });

    test('un campo que vale null no rompe nada', () {
      const guardada = '{"t": null, "a": 2.0, "e": null}';

      final p = PreferenciaDeLectura.deserializar(guardada);

      expect(p.tamanoDeLetra, 18);
      expect(p.espaciado, closeTo(0.02, 0.0001));
      expect(p.altoDeLinea, closeTo(2.0, 0.0001));
    });

    test('un tema que no es de los tres cae en el claro', () {
      const guardada = '{"f": "azul-neon", "t": 21}';

      final p = PreferenciaDeLectura.deserializar(guardada);

      expect(p.tema, TemaDeLectura.claro);
      expect(p.tamanoDeLetra, 21, reason: 'y el tamano se respeta igualmente');
    });
  });

  group('4. un numero fuera de rango se ACOTA, no se descarta', () {
    // Y LA DIFERENCIA ENTRE LAS DOS COSAS SE VE AQUI.
    //
    // Acotando, el usuario que tiene el tamano en 20 y el alto de linea en 0 --porque el
    // guardado se corto a medias-- conserva el 20 y recibe un 1,2 en el otro campo.
    // Descartando, pierde el 20 y vuelve a los dos recomendados.
    test('un tamano enorme se acota al maximo, y el resto se respeta', () {
      const guardada = '{"t": 900, "a": 1.8, "e": 0.05}';

      final p = PreferenciaDeLectura.deserializar(guardada);

      expect(p.tamanoDeLetra, PreferenciaDeLectura.tamanoMaximo);
      expect(p.altoDeLinea, closeTo(1.8, 0.0001));
      expect(p.espaciado, closeTo(0.05, 0.0001));
    });

    test('un tamano de 2 px se acota al minimo', () {
      final p = PreferenciaDeLectura.deserializar('{"t": 2}');
      expect(p.tamanoDeLetra, PreferenciaDeLectura.tamanoMinimo);
    });

    test('un alto de linea de 9 se acota, y uno de 0 tambien', () {
      expect(PreferenciaDeLectura.deserializar('{"a": 9}').altoDeLinea,
          PreferenciaDeLectura.altoDeLineaMaximo);
      expect(PreferenciaDeLectura.deserializar('{"a": 0}').altoDeLinea,
          PreferenciaDeLectura.altoDeLineaMinimo);
    });

    test('una atenuacion de 5 se acota a 1, que es "sin atenuar"', () {
      final p = PreferenciaDeLectura.deserializar('{"n": 5}');
      expect(p.atenuacion, 1.0, reason: 'atenuar mas alla de sin atenuar no tiene sentido');
    });

    test('una atenuacion de 0,01 se acota a la minima, no a 1', () {
      // Y AL REVES TAMBIEN. Acotar "hacia arriba" --cualquier cosa por debajo del minimo
      // vuelve a 1-- haria que un 0,01 mal guardado **no atenuase nada**, que es justo lo
      // contrario de lo que pedia quien lo guardo.
      final p = PreferenciaDeLectura.deserializar('{"n": 0.01}');
      expect(p.atenuacion, PreferenciaDeLectura.atenuacionMinima);
    });

    test('un espaciado negativo se acota a cero', () {
      expect(PreferenciaDeLectura.deserializar('{"e": -3}').espaciado, 0);
    });

    test('una linea enfocada que no existe se apaga', () {
      // Y SOLO EXISTEN 0, 1, 3 Y 5. Una apertura de dos lineas esta a caballo entre "una" y
      // "tres" y no se lee ni de una forma ni de la otra, y una de cuatro lineas parte el
      // texto por la mitad de una linea.
      for (final guardado in <String>['{"l": 2}', '{"l": 4}', '{"l": 99}', '{"l": -1}']) {
        expect(PreferenciaDeLectura.deserializar(guardado).lineaEnfocada, 0,
            reason: guardado);
      }
      for (final bueno in <int>[0, 1, 3, 5]) {
        expect(PreferenciaDeLectura.deserializar('{"l": $bueno}').lineaEnfocada, bueno,
            reason: 'la linea $bueno si existe');
      }
    });
  });

  group('5. cambiar', () {
    test('cada cambio acota, y en el mismo sitio que se guarda', () {
      // Y QUE NO SE ACOTE EN EL `Slider`, porque un `Slider` con `min: 15` y `max: 26` no
      // puede mandar 30 pero **si** puede quedarse con 30 si alguien le cambia el `max`, y el
      // `min` y el `max` estan en el widget y el dato esta en el modelo, y dos listas se
      // separan.
      // Y CADA UNO EN SU PROPIA PREFERENCIA, y no encadenados. Encadenados, el ultimo que
      // toca un campo manda: con `cambiarTamano(30)` y luego `cambiarTamano(10)`, el
      // resultado es 15 --el minimo-- y la comprobacion de arriba pedia 26 y fallaba. La
      // funcion estaba bien y la prueba encadenaba dos cosas del mismo campo y luego
      // comprobaba la primera.
      expect(PreferenciaDeLectura.porDefecto.cambiarTamano(30).tamanoDeLetra,
          PreferenciaDeLectura.tamanoMaximo);
      expect(PreferenciaDeLectura.porDefecto.cambiarTamano(10).tamanoDeLetra,
          PreferenciaDeLectura.tamanoMinimo);

      final p = PreferenciaDeLectura.porDefecto
          .cambiarAltoDeLinea(9)
          .cambiarEspaciado(0.5)
          .cambiarAtenuacion(0.1);

      expect(p.altoDeLinea, PreferenciaDeLectura.altoDeLineaMaximo);
      expect(p.espaciado, PreferenciaDeLectura.espaciadoMaximo);
      expect(p.atenuacion, PreferenciaDeLectura.atenuacionMinima);
    });

    test('una linea enfocada que no existe no se puede poner', () {
      final p = PreferenciaDeLectura.porDefecto.cambiarLineaEnfocada(4);
      expect(p.lineaEnfocada, 0);
    });

    test('los cambios no tocan los demas campos', () {
      // Y ESTO ES LO QUE HACE FALTA PARA QUE LOS SEIS SEAN INDEPENDIENTES. Con un solo
      // metodo que reescribiera el objeto entero, cambiar el tema borraria el tamano.
      final base = const PreferenciaDeLectura(
        tamanoDeLetra: 20,
        altoDeLinea: 1.9,
        espaciado: 0.06,
        tema: TemaDeLectura.sepia,
        atenuacion: 0.7,
        lineaEnfocada: 5,
      );

      expect(base.cambiarTema(TemaDeLectura.oscuro).tamanoDeLetra, 20);
      expect(base.cambiarTamano(22).tema, TemaDeLectura.sepia);
      expect(base.cambiarLineaEnfocada(1).atenuacion, closeTo(0.7, 0.0001));
      expect(base.cambiarEspaciado(0.09).lineaEnfocada, 5);
      expect(base.cambiarAtenuacion(0.9).espaciado, closeTo(0.06, 0.0001));
    });

    test('restaurar lo pone todo a los recomendados', () {
      final todavia = const PreferenciaDeLectura(
        tamanoDeLetra: 24,
        altoDeLinea: 2.4,
        espaciado: 0.09,
        tema: TemaDeLectura.oscuro,
        atenuacion: 0.45,
        lineaEnfocada: 5,
      );

      final restaurado = todavia.restaurar();

      expect(restaurado.tamanoDeLetra, 18);
      expect(restaurado.altoDeLinea, closeTo(1.6, 0.0001));
      expect(restaurado.espaciado, closeTo(0.02, 0.0001));
      expect(restaurado.tema, TemaDeLectura.claro);
      expect(restaurado.atenuacion, 1.0);
      expect(restaurado.lineaEnfocada, 0);
    });
  });

  group('6. el nombre del enum no es el valor guardado', () {
    test('porque Dart renombra los enum al compilar', () {
      // Y POR QUE HAY UN [enElAlmacenamiento]. Si se guardara `TemaDeLectura.oscuro.name`,
      // en el almacenamiento habia una cadena que depende de como el compilador ha llamado
      // a esa constante, y el dia que se recompile con otro nombre --que es lo que hace el
      // minificado de Dart-- la preferencia guardada **dejaria de leerse**.
      //
      // Y NO ES HIPOTETICO: es lo que pasa con `enum` en Dart en release. Por eso el valor
      // guardado es una cadena escrita a mano, y `leer` la reconoce.
      for (final t in TemaDeLectura.values) {
        expect(PreferenciaDeLectura.deserializar('{"f": "${t.enElAlmacenamiento}"}').tema,
            t,
            reason: 'el tema ${t.name} se lee con su valor escrito');
      }
    });

    test('y leer un valor que no existe da null, no el de partida', () {
      // Y POR QUE **NULL** Y NO EL DE PARTIDA: porque quien llama tiene que poder distinguir
      // "no estaba" de "estaba y era malo". Los dos acabarian en el mismo sitio, pero solo
      // uno es un dato que se ha perdido, y en un guardado eso se quiere saber.
      expect(TemaDeLectura.leer(null), isNull);
      expect(TemaDeLectura.leer('azul'), isNull);
      expect(TemaDeLectura.leer('claro'), TemaDeLectura.claro);
      expect(TemaDeLectura.leer('oscuro'), TemaDeLectura.oscuro);
    });
  });
}