// Los numeros en castellano.
//
// POR QUE HACE FALTA UNA FUNCION Y POR QUE NO BASTA CON UNA REGEX. Porque el separador
// de millares depende de la posicion de la coma decimal --que en castellano es una coma--
// y por eso no se puede poner "un punto cada tres caracteres" sin mirar si lo que viene
// detras es decimal o no. Aqui no hay decimales: son contadores, y un contador entero.
//
// Y POR QUE `numeroEnCastellano` ESTA EN `ui/core` Y NO EN EL DOMINIO. Porque es una
// decision de como se ensena un numero, y el dominio no decide eso. Un `int` en el
// dominio es 4140; como se escribe es de la pantalla.
import 'package:ab/ui/core/numeros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('el separador de millares', () {
    test('con menos de cuatro cifras no hay nada que separar', () {
      // Y "999" **no** lleva punto, porque un numero de tres cifras se lee entero de un
      // vistazo y un punto detras de la primera cifra estorba mas que ayuda. En cambio
      // "1.000" y "1.234" si llevan, porque ya son cuatro.
      expect(numeroEnCastellano(0), '0');
      expect(numeroEnCastellano(7), '7');
      expect(numeroEnCastellano(99), '99');
      expect(numeroEnCastellano(999), '999');
    });

    test('con cuatro o mas cifras, el punto cada tres', () {
      expect(numeroEnCastellano(1000), '1.000');
      // Y ESTE ES EL QUE SALIA MAL: `4140.toString()` es "4140" y en una pantalla en
      // castellano son 4.140. Dart no pone el separador y nadie lo pone por el.
      expect(numeroEnCastellano(4140), '4.140');
      expect(numeroEnCastellano(20000), '20.000');
      expect(numeroEnCastellano(1234567), '1.234.567');
    });

    test('el menos tambien lleva separador', () {
      expect(numeroEnCastellano(-1), '-1');
      expect(numeroEnCastellano(-999), '-999');
      expect(numeroEnCastellano(-4140), '-4.140');
      expect(numeroEnCastellano(-1234567), '-1.234.567');
    });

    test('es un punto, y no una coma', () {
      // Y POR QUE IMPORTA. En castellano la coma es el separador **decimal**: "4,140" son
      // cuatro con ciento cuarenta mil. Una pantalla que pone la coma pone una cifra
      // distinta de la que quiere decir.
      expect(numeroEnCastellano(4140), isNot('4,140'));
      expect(numeroEnCastellano(4140), '4.140');
    });

    test('los numeros que salen en pantalla salen asi', () {
      // Y ESTOS SON LOS **REALES** de las busquedas, medidos el 5 de octubre de 2026
      // sobre el KJV y el CLARKE de verdad. Con `toString` a secas el primero seria
      // "4140" y la pantalla pareceria un volcado.
      expect(numeroEnCastellano(4140), '4.140'); // "God" en el KJV
      expect(numeroEnCastellano(26), '26'); // "begotten" en el KJV
      expect(numeroEnCastellano(15), '15'); // "propitiation" en el CLARKE
      expect(numeroEnCastellano(3), '3'); // "propitiation" en el KJV
      expect(numeroEnCastellano(19742), '19.742'); // las notas del CLARKE
      expect(numeroEnCastellano(31102), '31.102'); // los versiculos del KJV
    });
  });
}
