// Lo que la sonda tiene que hacer cuando algo va mal: **decirlo**.
//
// MEDIDO EL 4 DE OCTUBRE DE 2026. La sonda empezo a mandar `List<Aviso>` en vez de
// `List<String>` --que es lo correcto, porque los avisos tienen tipo-- y `jsonEncode`
// **lanza** con un objeto dentro en vez de escribirlo. La excepcion salio de `escribir`,
// se subio por la cadena y, como no habia nadie que la cogiera, se perdio.
//
// Lo que se vio desde fuera fue esto: la app **funcionaba**, Juan 3:16 se leia en la
// pantalla del navegador, la descarga iba bien... y la sonda no escribia nada. La
// comprobacion en navegador decia "la sonda no ha escrito nada en 900 s", que es un
// fallo de la comprobacion, y no de la app.
//
// Y ESO ES LO PEOR QUE PUEDE PASAR CON UNA COMPROBACION: "no ha comprobado nada" y
// "no ha dicho nada" se ven igual desde fuera. Una comprobacion que se traga sus
// errores es peor que no tenerla, porque ocupa el hueco de una que funciona.
//
// Y NO SE ARREGLA SOLO CON UN `try`. Un `try` que devuelve un informe vacio sigue
// mintiendo. Hacen falta **las dos** cosas: no meter en el informe nada que `jsonEncode`
// no sepa escribir, y que si aun asi falla, se escriba el fallo.

import 'package:ab/app/sonda.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('la sonda no se traga sus propios fallos', () {
    test('un informe con un valor que no es JSON escribe el fallo, no revienta', () {
      // Y ESTA ES LA PRUEBA DEL FALLO DE ARRIBA. Un `Map<String, Object?>` acepta
      // **cualquier** cosa: un `List<Aviso>`, un `Modulo`, una funcion. Y
      // `jsonEncode` lanza con casi todos ellos, en vez de escribir `"[object]"`.
      //
      // Se prueba con un objeto que no sabe convertirse a JSON, que es exactamente lo
      // que paso al mandar la lista de avisos.
      final sonda = Sonda();

      // Y NO LANZA. Si lanza, la excepcion se traga en el `addPostFrameCallback` y
      // vuelve a pasar lo de siempre: pantalla correcta, sonda muda.
      expect(
        () => sonda.escribirConEsteCodigo(<String, Object?>{
          'resultado': 'ok',
          // Una clase que `jsonEncode` no sabe escribir. `jsonEncode` **lanza** con
          // esto; no escribe nada y no avisa.
          'avisos': <Object>[Object()],
        }),
        returnsNormally,
        reason: 'una sonda que lanza al escribir es una sonda muda',
      );

      // Y ADEMAS DICE ALGO. Un informe vacio es tan inútil como ninguno.
      expect(sonda.ultimoTextoEscrito, isNotNull);
      expect(sonda.ultimoTextoEscrito, contains('no ha podido escribir'),
          reason: 'y tiene que decir **por que**, no solo que fallo');
    });

    test('un informe normal se escribe entero, sin tocar nada', () {
      // Y ESTA ES LA MITAD QUE NO SE PUEDE OLVIDAR. Con un `try` alrededor que se
      // tragase tambien el camino bueno --un `catch` que devuelve un texto generico, o
      // un `return` temprano-- esta prueba falla. Un arreglo de un fallo que rompe la
      // funcion es el mismo fallo con mas pasos.
      final sonda = Sonda();

      sonda.escribirConEsteCodigo(<String, Object?>{
        'resultado': 'ok',
        'pasaje': 'John.3.16',
        'versiculosEnElPasaje': 1,
        'terminos': <String, Object?>{'licencia': 'PublicDomain'},
      });

      expect(sonda.ultimoTextoEscrito, contains('"resultado": "ok"'));
      expect(sonda.ultimoTextoEscrito, contains('"pasaje": "John.3.16"'));
      expect(sonda.ultimoTextoEscrito, contains('"licencia": "PublicDomain"'));
      expect(sonda.ultimoTextoEscrito, isNot(contains('no ha podido escribir')));
    });

    test('una lista de cadenas --que es lo que se manda de verdad-- se escribe', () {
      // Y ESTE ES EL INFORME REAL. Los avisos de la sonda son `List<String>`, y eso es
      // lo que se manda porque `List<Aviso>` no se sabe convertir. El cambio de uno a
      // otro fue el que rompio la comprobacion, asi que lo que se manda ahora tiene una
      // prueba que lo fija.
      final sonda = Sonda();

      sonda.escribirConEsteCodigo(<String, Object?>{
        'catalogo': <String, Object?>{
          'estado': 'delServidor',
          'avisos': <String>[
            'info: King James Version (2006): 31102 versiculos, listo para leer.',
            'info: KJV2006 descargado y guardado.',
          ],
        },
      });

      expect(sonda.ultimoTextoEscrito, contains('31102 versiculos'));
      expect(sonda.ultimoTextoEscrito, contains('descargado y guardado'));
    });

    test('la sonda avisa de cuanto ha bajada ella sola, sin que se lo pregunten', () {
      // Y ESTO NO ES UN ADITIVO. `escribir` sin el `try` anterior lanzaba **antes** de
      // guardarse el texto, asi que una sonda que fallaba no actualizaba su contador: el
      // informe siguiente decia cero bytes bajados cuando se habían bajado 22 MiB, que
      // es un dato falso que no se distingue de "no se ha bajado nada".
      final sonda = Sonda();

      sonda.escribirConEsteCodigo(<String, Object?>{'resultado': 'ok'});
      final antes = sonda.bytesDescargados;

      sonda.escribirConEsteCodigo(<String, Object?>{'loQueSea': Object()});
      expect(sonda.bytesDescargados, antes,
          reason: 'un informe que no se puede escribir no puede cambiar lo que se ha visto');
    });
  });
}