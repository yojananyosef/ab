// Lo que la pantalla del indice necesita de una entrada.
//
// Y ES UN PUENTE Y NO UN `dynamic`, y no por gusto: una pantalla que recibe `dynamic` no
// puede comprobar nada de lo que recibe, y compila con una entrada mal formada hasta que
// revienta en pantalla. Con esta interfaz el error sale al compilar.
//
// Y ES **TAN PEQUEÑA** A PROPOSITO. La pantalla no necesita el numero del lexicon --ya lo
// tiene en la ruta-- ni las palabras de la entrada: solo necesita donde pulsar y cuantas
// veces sale. Anadirle mas seria darle datos que no usa.

import 'referencia.dart';

/// Lo unico que la pantalla del indice lee de una entrada.
abstract class IndiceDeStrongParaLaView {
  /// Donde sale.
  Referencia get referenciaParaLaView;

  /// Cuantas veces sale en ese versiculo.
  int get veces;
}
