// El estilo de una palabra del versiculo, y nada mas.
//
// Y POR QUE ESTO ESTA FUERA DEL WIDGET Y NO DENTRO. Porque son cuatro combinaciones y
// una tabla, y dentro de un `build` la tabla esta repartida en un `if` que se lee
// leyendo el `build`. Medido en el KJV: de 835.159 palabras, **cero** son a la vez
// `\add` y `\wj`, asi que el caso de las dos marcas no se puede probar con el fichero
// real --y es justo el caso que hay que probar, porque la primera version hacia que "el
// subrayado ganara" sobre el rojo, y una palabra anadida por el traductor **dentro** de
// las palabras de Jesus salia negra con subrayado: el rojo se perdia justo en el unico
// sitio donde mas se nota.
//
// Y NO ES UN `ENUM` CON CUATRO CASOS, y ese es el intento que no se hizo. Las dos marcas
// son **independientes**: "la puso el traductor" y "la dijo Jesus" no se excluyen, y una
// palabra puede tener las dos, ninguna, o una. Un enum con cuatro casos mete la tabla en
// el tipo y hay que anadir un caso cada vez que aparezca una combinacion nueva.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/token_de_texto.dart';
import 'package:ab/ui/core/tema.dart';

/// El estilo de una palabra del versiculo [a], sobre [base].
///
/// Y **NULL** CUANDO NO HAY NADA QUE ENSENAR, y no el propio [base]. Un `TextSpan` con un
/// estilo igual al del padre no se ve igual que uno sin estilo: el motor de texto puede
/// partirlo en otra linea y un `RichText` con cuatro `TextSpan` de mas por palabra es
/// cuatro veces mas trabajo de colocacion en un capitulo de 36 versiculos.
///
/// Y EL ROJO SE PONE **SOLO** SI EL INTERRUPTOR ESTA PUESTO. Que el parametro se lea en
/// cada llamada y no se guarde en un campo es lo que hace que el cambio se vea en el
/// siguiente `build` sin acordarse de que hay algo que invalidar.
TextStyle? estiloDePalabra(
  AnotacionDePalabra a,
  TextStyle base, {
  required bool mostrarPalabrasDeJesus,
}) {
  final enRojo = mostrarPalabrasDeJesus && a.esPalabraDeJesus;

  if (!a.esAnadido && !enRojo) return null;

  return base.copyWith(
    color: enRojo ? Colores.palabraDeJesus : null,
    decoration: a.esAnadido ? TextDecoration.underline : null,
    decorationColor: Colores.textoSuave,
    decorationThickness: 1,
  );
}
