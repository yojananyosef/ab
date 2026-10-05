// El texto de un versiculo con lo que el modulo **marca** en el.
//
// QUE HAY AQUI Y POR QUE.
//
// El `.amod` guarda dos columnas: `text`, que es el texto plano, y `raw`, que es el mismo
// texto con marcado USFM. Medido sobre el KJV real el 5 de octubre de 2026, `raw` trae:
//
//     \w earth|strong="H0776"\w* \w was|strong="H1961"\w* without ...
//     \add was\add* upon the \w face|strong="H6440"\w* ...
//     \wj ¶ \+w For|strong="G1063"\+w* \+w God|strong="G2316"\+w* ...
//
// Es decir: una marca que envuelve a una palabra, un `|strong="G2316"` que le dice de que
// palabra del hebreo o del griego se trata, y marcas de estructura --`\wj` parrafo, `\p`,
// `\q1`, `\f`/`\fr`/`\ft` para notas al pie, `\nd` sin divisor, `\s1`, `\b`, `\tl`--.
//
// Y EL TEXTO **NO SE CAMBIA**. Un lector que altera el texto que va a leer es un lector que
// no se puede citar, y citar mal la Escritura es el fallo mas grave de esta categoria. Asi
// que este paquete lleva el texto tal cual y lo que guarda es lo que el modulo **senalo**:
// eso se ensena aparte, y quitarlo deja el texto exactamente igual.
//
// Y POR QUE NO SE PINTARON LOS NUMEROS DEL STRONG. Porque un numero strong a secas es un
// numero, y un numero al lado de cada palabra convierte el versiculo en una tabla. Lo que
// se guarda aqui es el **numero**, y a partir de el se puede hacer un indice; pintarlo es
// otro change.
//
// Y LO QUE **NO** SE PUEDE SACAR DE ESTE DATO, y es lo mas importante de este fichero:
//
// LA PALABRA DE DIOS EN ROJO NO ESTA AQUI. No hay ninguna marca de habla divina en los
// modulos de este catalogo. Se ha buscado una y no esta: lo que hay son `\add`, que son
// texto **anadido por los traductores**, y los `strong`, que son el lexicon. La palabra de
// Dios en rojo viene de otra parte --de una convencion de marcado, de una marca `\divine`,
// de una lista de versiculos-- y sin ella **no se puede pintar en rojo** sin inventarse que
// se sabe cual es. Ver `AGENTS.md` y el proposal del change.

/// El numero del lexicon y la marca de "anadido" de UNA palabra.
///
/// Y NO UN TROZO DE TEXTO. Esto es lo que hay que decidir antes de escribir una linea, y
/// por eso va aqui y no en un parser:
///
/// EL TEXTO SE PINTA DESDE LA COLUMNA `text` DEL MODULO, NUNCA DESDE EL `raw`.
///
/// Las dos columnas dicen lo mismo y dan la misma Escritura, pero **no** con los mismos
/// caracteres: en el KJV, medido el 5 de octubre de 2026, hay 5.844 versiculos cuyo `raw`
/// tiene un `+` que `text` no tiene, 13.740 marcas `\nd` sin divisor y notas al pie cuyo
/// numero de referencia va en una columna y no en la otra. Reconstruir `text` desde `raw`
/// obliga a aprender una regla por caso, y una regla por caso es escribir el texto del
/// modulo sin saber que se esta escribiendo. Se intento y salio: 31.102 versiculos, y el
/// que fallaba era el aparato de variantes de las cronicas.
///
/// Asi que el texto es el que dice el modulo y lo que sale de aqui son **anotaciones**:
/// que palabra es del lexicon hebreo, y que palabras puso el traductor. Y si no cuadran
/// con el texto, **no hay anotaciones**: se descartan y el texto se queda solo. Es
/// preferible un versiculo sin el numero del lexicon a un versiculo con el numero de otra
/// palabra.
class AnotacionDePalabra {
  const AnotacionDePalabra({this.strong, this.esAnadido = false});

  /// El numero del lexicon, tal cual: `G2316` para `Dios` en griego, `H0436` en hebreo.
  final String? strong;

  /// Si el modulo dice que la puso el traductor.
  final bool esAnadido;

  @override
  String toString() => '${strong ?? '-'} ${esAnadido ? 'anadido' : '-'}';
}

/// Un versiculo: su texto y las anotaciones de sus palabras.
///
/// Y `texto` VIENE DE LA COLUMNA `text` DEL MODULO Y NO SE TOCA. Ni una mayuscula, ni un
/// acento, ni un espacio. Un lector que altera el texto que va a leer es un lector que no
/// se puede citar, y citar mal la Escritura es el fallo mas grave de esta categoria.
class TextoAnotado {
  const TextoAnotado({required this.texto, required this.anotaciones});

  /// Sin anotaciones: un modulo cuyo `raw` no tiene marcado. Como el comentario, medido:
  /// las 19.742 notas del CLARKE tienen `raw == text`.
  static const TextoAnotado sinAnotar = TextoAnotado(
    texto: '',
    anotaciones: <AnotacionDePalabra>[],
  );

  /// El texto del versiculo, tal cual.
  final String texto;

  /// Una anotacion por palabra de [texto], en el mismo orden. Vacia si no se pudo
  /// emparejar con seguridad.
  final List<AnotacionDePalabra> anotaciones;

  /// Si el marcado casa con el texto y hay una anotacion por palabra.
  ///
  /// Y DICE "HAY UNA ANOTACION POR PALABRA", no "hay algo que ensefiar". Son dos cosas:
  /// un versiculo puede tener la lista llena de anotaciones **vacias**, que es lo que pasa
  /// cuando el marcado se casa con el texto pero no trae ni un numero del lexicon.
  bool get tieneAnotaciones => anotaciones.isNotEmpty;

  /// Si hay algo **que ensefiar**: un numero del lexicon o una palabra del traductor.
  ///
  /// Y ES LA QUE MIRA LA PANTALLA, porque pintar una lista de anotaciones vacias es lo
  /// mismo que no pintar nada, con mas trabajo.
  bool get tieneAlgoQuePintar =>
      anotaciones.any((a) => a.strong != null || a.esAnadido);

  /// La anotacion de la palabra [i].
  ///
  /// Null si no hay anotaciones o si [i] se sale, que es lo que pasa en un versiculo sin
  /// lexicon. Y null y no una excepcion porque lo llama la vista al pintar, y la vista no
  /// sabe que un modulo tiene lexicon y otro no.
  AnotacionDePalabra? anotacionDe(int i) =>
      i >= 0 && i < anotaciones.length ? anotaciones[i] : null;

  /// Si el modulo marco alguna palabra como anadida por el traductor.
  ///
  /// Y MEDIDO: 41.692 marcas `\add` en el KJV, sobre 31.102 versiculos, y Juan 3:16 no
  /// tiene ni una.
  bool get tieneAnadidos => anotaciones.any((a) => a.esAnadido);

  /// Si el modulo trae numeros del lexicon.
  bool get tieneStrongs => anotaciones.any((a) => a.strong != null);

  @override
  String toString() =>
      '${texto.length} caracteres, ${anotaciones.length} anotaciones';
}
