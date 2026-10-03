// Una referencia a un pasaje: libro, capitulo y versiculo.
//
// Es la direccion del contenido, y tambien lo que va en la URL. Por eso tiene
// que poder escribirse y leerse de mas de una forma: "Juan 3:16", "Juan 3",
// "Jn.3.16" y "3.16" son la misma intencion y la gente las escribe todas.
//
// La clave del libro va en ingles (`John`) porque es lo que guarda el modulo. El
// nombre que se ensena va en castellano y lo pone quien llama.

import 'libros.dart';

/// Un pasaje dentro de un modulo.
class Referencia {
  const Referencia(this.libro, this.capitulo, [this.versiculo]);

  /// Clave del libro tal como la guarda el modulo: `John`.
  final String libro;

  final int capitulo;

  /// Null cuando la referencia apunta a un capitulo entero.
  final int? versiculo;

  /// Nombre en castellano del libro, o la clave si no se reconoce.
  String get nombreLibro => libroPorId(libro)?.nombre ?? libro;

  /// La misma referencia con otro versiculo.
  Referencia conVersiculo(int v) => Referencia(libro, capitulo, v);

  /// Como se escribe en pantalla: `Juan 3:16`, o `Juan 3` sin versiculo.
  String get texto =>
      versiculo == null ? '$nombreLibro $capitulo' : '$nombreLibro $capitulo:$versiculo';

  /// Como va en la URL: `John.3.16`. Sin acentos ni espacios, porque una URL
  /// con espacios es una URL que hay que codificar, y eso son caracteres de mas
  /// que se pueden perder al compartirla.
  String get paraUrl => versiculo == null ? '$libro.$capitulo' : '$libro.$capitulo.$versiculo';

  /// Lee una referencia escrita como `John.3.16`, `Juan.3.16` o `3.16`.
  ///
  /// Devuelve null si no se entiende. Que devuelva null en vez de tirar una
  /// excepcion es a proposito: esto se llama desde un campo de texto mientras
  /// la persona escribe, y una excepcion por cada tecla es una caida.
  static Referencia? tryParse(String texto, {String? libroPorDefecto}) {
    var t = texto.trim();
    if (t.isEmpty) return null;
    t = t.replaceAll(':', '.').replaceAll(' ', '');
    // "Juan3:16" sin separador: se separa tras el nombre del libro, que es lo
    // unico que puede acabar en letra.
    t = t.replaceAllMapped(RegExp(r'^([^\d.]+)(\d)'), (m) => '${m.group(1)}.${m.group(2)}');
    final partes = t.split('.').where((p) => p.isNotEmpty).toList();
    if (partes.length < 2 || partes.length > 3) return null;

    String clave;
    int cap;
    int? vers;

    if (partes.length == 3) {
      final libro = _resolverLibro(partes[0]);
      if (libro == null) return null;
      clave = libro;
      cap = int.tryParse(partes[1]) ?? -1;
      vers = int.tryParse(partes[2]) ?? -1;
    } else {
      // Dos partes: puede ser "Juan.3" o "3.16" con el libro ya puesto.
      final comoLibro = _resolverLibro(partes[0]);
      if (comoLibro != null) {
        clave = comoLibro;
        cap = int.tryParse(partes[1]) ?? -1;
      } else if (libroPorDefecto != null) {
        clave = libroPorDefecto;
        cap = int.tryParse(partes[0]) ?? -1;
        vers = int.tryParse(partes[1]) ?? -1;
      } else {
        return null;
      }
    }

    if (cap < 1 || (vers != null && vers < 1)) return null;
    return Referencia(clave, cap, vers);
  }

  /// Busca el libro por clave o por nombre en castellano. Devuelve la clave.
  static String? _resolverLibro(String s) {
    final porId = libroPorId(s);
    if (porId != null) return porId.id;
    final porNombre = libroPorNombre(s);
    if (porNombre != null) return porNombre.id;
    return null;
  }

  @override
  String toString() => texto;

  @override
  bool operator ==(Object other) =>
      other is Referencia &&
      other.libro == libro &&
      other.capitulo == capitulo &&
      other.versiculo == versiculo;

  @override
  int get hashCode => Object.hash(libro, capitulo, versiculo);
}
