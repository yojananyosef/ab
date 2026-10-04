// Una nota de comentario: a que versiculo se refiere y que dice.
//
// QUE NO SEA UN `Versiculo` ES LO IMPORTANTE, Y NO UNA DISTINCION ESTETICA. Un
// versiculo es un texto **sagrado** y se pinta como texto sagrado, en su columna, con su
// numero y sin nada alrededor. Una nota es el comentario de un hombre de 1832 sobre ese
// versiculo, y se pinta de otra manera: mas pequeña, con el versiculo al que se refiere
// al lado, y con la certeza de que **no es la Palabra**.
//
// Confundir las dos cosas en un solo tipo hace que el comentario parezca parte de la
// Escritura. Y ese es exactamente el modo de fallo de las apps que ensenan el
// comentario en el mismo cuerpo y con el mismo formato.
//
// Y DE DONDE VIENEN LOS DATOS. Del `.amod`, tabla `commentary`, medido sobre el CLARKE
// real el 4 de octubre de 2026:
//
//     CREATE TABLE commentary (
//       book TEXT, chapter INTEGER, verse INTEGER, seq INTEGER, text TEXT, raw TEXT,
//       PRIMARY KEY (book, chapter, verse, seq)
//     ) WITHOUT ROWID
//
// Y 19.742 filas.
//
// EL `seq` ES LO QUE OBLIGA A QUE ESTO SEA UNA CLASE PROPIA. La clave primaria son
// **cuatro** columnas: un versiculo puede tener varias notas y `seq` las ordena. En
// Juan 3:16 hay tres. Una consulta que devuelve una fila por versiculo se perderia las
// otras dos, y un `Versiculo` --que solo tiene `numero` y `texto`-- no tiene donde
// meterlas.
//
// Y EL TEXTO SE PASA TAL CUAL, como el de los versiculos. Un comentario que se altera
// deja de ser citable, y citar mal a un teologo es el mismo fallo que citar mal la
// Escritura.

/// Una nota de comentario sobre un versiculo.
///
/// Inmutable y sin metodos de UI, como [Versiculo]. La View decide como se pinta.
class Nota {
  const Nota({
    required this.versiculo,
    required this.orden,
    required this.texto,
  });

  /// El versiculo al que se refiere, dentro del capitulo.
  ///
  /// Y ES UN `int` Y NO UNA `Referencia`, a proposito: la referencia **completa** --con
  /// el capitulo-- la tiene el pasaje que la contiene, y meterla aqui seria
  /// repetirla en cada nota para poder desincronizarla una vez.
  final int versiculo;

  /// El orden dentro de ese versiculo. Es el `seq` del modulo.
  ///
  /// Y SE EXPONE PORQUE HAY QUE PODER SER CIERTO. Sin el, dos notas del mismo versiculo
  /// son indistinguibles, y el orden en que las dio el autor es informacion: la primera
  /// suele ser la glosa y las siguientes las disquisiciones.
  final int orden;

  /// El texto, tal cual lo trae el modulo.
  ///
  /// Viene del campo `text`, que ya viene limpio de marcas USFM. El campo `raw` con
  /// `\+w ...|strong=` no se usa aqui, igual que en los versiculos: la palabra de Dios en
  /// rojo es un change aparte y no se mezcla con esto.
  final String texto;

  /// Como lo identifica la app. `Juan 3:16.2` para la segunda nota de Juan 3:16.
  ///
  /// Y SOLO PARA DIAGNOSTICO Y PARA EL `tooltip`. En pantalla lo que se ve es el numero
  /// del versiculo y el texto de la nota; esto es lo que va en la etiqueta accesible y
  /// en el registro.
  String get referencia => '$versiculo.$orden';

  @override
  String toString() => 'Juan $versiculo.$orden: ${texto.length} caracteres';

  @override
  bool operator ==(Object other) =>
      other is Nota &&
      other.versiculo == versiculo &&
      other.orden == orden &&
      other.texto == texto;

  @override
  int get hashCode => Object.hash(versiculo, orden, texto);
}