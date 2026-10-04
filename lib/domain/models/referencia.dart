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
  ///
  /// LOS ESPACIOS SE MANTIENEN HASTA EL FINAL, y no es un detalle: la primera
  /// version hacia `replaceAll(' ', '')` antes de partir, y con eso
  /// "Segundo de Corintios 13" llegaba al normalizador como `SegundodeCorintios13`,
  /// donde ni el ordinal "segundo" ni la palabra "de" tienen limites de palabra y no
  /// se reconocen. O sea que **quitar los espacios rompia las formas de decir las
  /// cosas**. Ahora se parte con una expresion regular sobre el texto tal cual, y el
  /// nombre del libro sale con sus espacios.
  ///
  /// Y EL ORDEN DE LOS INTENTOS. Primero se prueba el texto tal cual, que es como
  /// escribe la gente. Solo si eso no cuela se prueba partiendo "Juan3:16" sin
  /// espacios, porque esa particion es agresiva --parte tras cualquier letra seguida de
  /// un numero-- y parte cosas que no son una referencia, como "1Corinthians13".
  static Referencia? tryParse(String texto, {String? libroPorDefecto}) {
    final normal = texto.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(':', '.');
    if (normal.isEmpty) return null;

    final r = _intentar(normal, libroPorDefecto);
    if (r != null) return r;

    // "Juan3:16": tras el nombre del libro, que es lo unico que puede acabar en letra.
    final pegado = normal.replaceAllMapped(
      RegExp(r'([^\s\d.])(\d)'),
      (m) => '${m.group(1)}.${m.group(2)}',
    );
    return _intentar(pegado, libroPorDefecto);
  }

  /// Un intento de partido. Devuelve null si no encaja con ninguna forma.
  static Referencia? _intentar(String texto, String? libroPorDefecto) {
    // El nombre del libro es lo mas corto que deje un numero detras. No se recorre
    // "letra seguida de numero" porque eso parte "1Corinthians13" por la mitad.
    final m = RegExp(r'^(.*?)[\s.]*(\d+)(?:[\s.]+(\d+))?$').firstMatch(texto);
    if (m == null) return null;

    final nombre = (m.group(1) ?? '').trim();
    final capitulo = int.tryParse(m.group(2) ?? '');
    final versiculo = m.group(3) == null ? null : int.tryParse(m.group(3)!);
    if (capitulo == null || capitulo < 1) return null;
    if (versiculo != null && versiculo < 1) return null;

    // Solo numeros: "3.16" con el libro ya puesto.
    if (nombre.isEmpty) {
      if (libroPorDefecto == null) return null;
      return Referencia(libroPorDefecto, capitulo, versiculo);
    }

    final clave = _resolverLibro(nombre);
    if (clave == null) return null;
    return Referencia(clave, capitulo, versiculo);
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
