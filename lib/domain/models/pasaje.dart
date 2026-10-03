// Un pasaje: una referencia y los versiculos que hay en ella.
//
// El nombre `Pasaje` y no `Capitulo` porque un pasaje puede ser un capitulo
// entero o un solo versiculo. Quien llama decide el alcance.

import 'referencia.dart';
import 'versiculo.dart';

class Pasaje {
  const Pasaje({required this.referencia, required this.versiculos, required this.titulo});

  /// Donde se ha leido. Sirve para el titulo de la pantalla y para la URL.
  final Referencia referencia;

  /// En orden. El modulo los devuelve asi y aqui no se reordena.
  final List<Versiculo> versiculos;

  /// Nombre legible: `Juan 3`. Lo pone quien lee, no se deduce aqui, para que
  /// la View no tenga que preguntar nada.
  final String titulo;

  bool get vacio => versiculos.isEmpty;

  int get total => versiculos.length;

  /// El versiculo `n`, o null si el pasaje no lo tiene.
  ///
  /// Null y no una excepcion porque se llama desde un enlace que puede venir
  /// de cualquier parte, con cualquier versiculo escrito.
  Versiculo? versiculo(int n) {
    for (final v in versiculos) {
      if (v.numero == n) return v;
    }
    return null;
  }

  /// Un pasaje vacio para cuando la referencia no existe en esa traduccion.
  ///
  /// Es un caso de primera clase, no una excepcion: en una biblioteca con
  /// distintas versificaciones, pedir Juan 3:36 en un texto que no lo tiene es
  /// normal, y la pantalla tiene que poder ensenarlo.
  factory Pasaje.vacio(Referencia r, {required String titulo}) =>
      Pasaje(referencia: r, versiculos: const <Versiculo>[], titulo: titulo);
}
