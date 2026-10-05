// Numeros en castellano, que Dart no pone.
//
// QUE ESTO NO ES UN "DETALLE DE FORMATO" Y POR QUE HACE FALTA.
//
// Dart no agrupa los miles: `4140.toString()` es `"4140"`. Y `"4.140 coincidencias"` es
// como lo escribe la gente, y `"4140 coincidencias"` no lo es. La diferencia es un
// caracter y es la diferencia entre una pantalla que parece escrita en castellano y una
// que parece un volcado de un `print`.
//
// Y NO ES SOLO UN PUNTO. En castellano el separador de millares **es** el punto, y no una
// coma --la coma es decimal-- y no un espacio. Una pantalla en español que pone "4,140"
// está contando otra cosa: cuatro con ciento cuarenta mil.
//
// Y POR QUE EMPIEZA EN LAS CUATRO CIFRAS Y NO EN LAS CINCO. La RAE dice que los numeros
// de cuatro cifras se escriben sin separador y que este puede añadirse cuando ayude a
// leerlos. Aqui se añade siempre, porque un contador en pantalla se lee de un vistazo y
// `4140` son cuatro digitos que hay que contar mientras `4.140` se lee como un numero. En
// prosa --un texto, un articulo-- la regla seria la otra, y por eso esta funcion es de la
// interfaz y no del dominio.
//
// Y EL **MENOS** TAMBIEN LLEVA SEPARADOR. Un saldo de "-4.140" se lee de un vistazo y
// "-4104" obliga a fijarse en el signo para saber si es menos.

/// El numero en castellano, con los miles separados por un punto.
///
///     0        ->  0
///     999      ->  999
///     4140     ->  4.140
///     1234567  ->  1.234.567
///     -4140    ->  -4.140
String numeroEnCastellano(int numero) {
  final conSigno = numero < 0 ? '-' : '';
  final digitos = numero.abs().toString();

  // Y NO HAY NADA QUE AGRUPAR EN UNA CIFRA O EN TRES. `999` no
  // lleva punto, porque un numero de tres cifras se entero de un vistazo y un punto
  // despues de la primera cifra estorba mas que ayuda.
  if (digitos.length <= 3) return '$conSigno$digitos';

  final grupos = <String>[];
  var desde = digitos.length;
  while (desde > 3) {
    grupos.add(digitos.substring(desde - 3, desde));
    desde -= 3;
  }
  grupos.add(digitos.substring(0, desde));

  return '$conSigno${grupos.reversed.join('.')}';
}
