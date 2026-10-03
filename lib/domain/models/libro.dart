/// Un libro de la Biblia: su clave dentro del modulo y su nombre para la gente.
///
/// La clave va en ingles porque es lo que el modulo guarda en su columna
/// `book`. El nombre va en castellano porque es lo que se ensena. Que sean dos
/// cosas distintas es exactamente lo que hace falta: un comentario en ingles y
/// una Biblia en espanol tienen que poder apuntar a el mismo versiculo, y para
/// eso los dos apuntan a `John`, no a `Juan` ni a `Jn`.
///
/// Inmutable, sin codigo de dependencia, solo comparacion y texto.
class Libro {
  const Libro(this.id, this.nombre);

  /// Clave dentro del modulo: `Genesis`, `1Corinthians`, `Revelation`.
  final String id;

  /// Nombre en castellano, como se ensena. Lleva acentos a proposito: es texto
  /// de pantalla. Ver la nota de `libros.dart`.
  final String nombre;

  @override
  String toString() => 'Libro($id, $nombre)';

  @override
  bool operator ==(Object other) =>
      other is Libro && other.id == id && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, nombre);
}
