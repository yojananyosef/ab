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
// Y LO QUE **SI** SE SACA DE ESTE DATO, y que no se habia visto: LAS PALABRAS DE JESUS.
//
// Aqui estaba escrito que la palabra de Dios en rojo no se puede pintar, y era verdad con
// lo que se habia buscado y **falso con lo que hay**. Se busco una marca de habla divina
// --`\divine`, `\god`, una lista de versiculos-- y no la hay. Lo que hay es `\wj`, que en
// USFM es el marcador de **palabras de Jesus**, el mismo que usan las Biblias de letras
// rojas para pintar lo que dijo el. Medido el 5 de octubre de 2026 sobre el KJV entero:
//
//     \wj   2.038 aperturas   en 2.028 versiculos
//     Mateo 644   Lucas 587   Juan 419   Marcos 286
//     Apocalipsis 62   Hechos 27   1 Corintios 2   2 Corintios 1
//
// Y las dos ultimas filas son la prueba de que el marcador dice lo que dice: en 1
// Corintios 11:24 y 2 Corintios 12:9 son palabras de Cristo citadas por Pablo. Un
// marcador que significara "dialogo" tambien los traeria; uno que significara "habla
// divina" no, porque Pablo no es Cristo.
//
// ASI QUE LO QUE SE PINTA EN ROJO SON **LAS PALABRAS DE JESUS**, y se llaman asi. Lo que
// no se puede sigue sin poder: **las palabras de Dios** en general --el Dios del Antiguo
// Testamento hablando a Moises, los profetas-- no estan marcadas en ningun sitio de este
// catalogo, y no hay donde sacarlas. Pintar de rojo un texto cuyo hablante no se sabe seria
// inventarse el dato.

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
  const AnotacionDePalabra({
    this.strong,
    this.esAnadido = false,
    this.esPalabraDeJesus = false,
  });

  /// El numero del lexicon, tal cual: `G2316` para `Dios` en griego, `H0436` en hebreo.
  final String? strong;

  /// Si el modulo dice que la puso el traductor.
  final bool esAnadido;

  /// Si el modulo dice que la dijo Jesus.
  ///
  /// Y VIENE DE LA MARCA `\wj`, QUE EN USFM ES EXACTAMENTE ESO. Medido el 5 de octubre de
  /// 2026 sobre el KJV entero: 2.028 versiculos la tienen, y son los evangelios mas las
  /// citas de Cristo en los Hechos, el Apocalipsis y las epistolas.
  ///
  /// Y SE LLAMA ASI Y NO "esPalabraDeDios" PORQUE NO ES LO MISMO. Las palabras de Dios en
  /// general --el Dios del Antiguo Testamento hablando a Moises-- **no estan marcadas en
  /// ningun sitio de este catalogo**. Lo unico que hay marcado es lo que dijo Jesus, y
  /// llamarlo de otra cosa seria ensenar algo que el modulo no dice.
  final bool esPalabraDeJesus;

  @override
  String toString() => '${strong ?? '-'} '
      '${esAnadido ? 'anadido' : '-'} '
      '${esPalabraDeJesus ? 'de Jesus' : '-'}';
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
      anotaciones.any((a) => a.strong != null || a.esAnadido || a.esPalabraDeJesus);

  /// El texto partido en palabras, con la puntuacion donde estaba.
  ///
  /// Y SOLO EXISTE CUANDO HAY ANOTACIONES, y es a proposito: quien la necesita es el
  /// indice de palabras, que empareja por posicion, y ahi siempre las hay. Sin anotaciones
  /// se devuelve una lista vacia y no `texto.split(' ')`, para que un modulo sin lexicon no
  /// gaste en partir un texto de 141 caracteres cada vez que se pinta.
  List<String> get palabras => tieneAnotaciones
      ? texto.split(' ')
      : const <String>[];

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

  /// Cuantas palabras de este versiculo dijo Jesus.
  int get palabrasDeJesus =>
      anotaciones.where((a) => a.esPalabraDeJesus).length;

  /// Si el modulo marco alguna palabra como dicha por Jesus.
  ///
  /// Y MEDIDO, y con los dos lados porque los dos importan: en Juan 3 el versiculo **16
  /// entero** --sus 25 palabras-- es de Jesus, y 3:28, 3:29, 3:30 y 3:36 **no tienen ni
  /// una**, porque son palabras del narrador. Si el marcador marcara el capitulo entero o
  /// no marcara nada, esos cuatro habrian salido de la otra manera. Es el mismo par que
  /// 3:11, donde las 24 palabras del versiculo son suyas.
  ///
  /// Y DE TODO EL KJV: 2.015 versiculos y 41.284 palabras, el **4,94 %** del texto. En el
  /// Antiguo Testamento **ninguno**, y no por fallo del parser: alli no hay nada marcado,
  /// porque las palabras de Dios las dice el Dios del Antiguo Testamento y este catalogo
  /// no las marca. Ver el metodo.
  bool get tienePalabrasDeJesus => anotaciones.any((a) => a.esPalabraDeJesus);

  @override
  String toString() =>
      '${texto.length} caracteres, ${anotaciones.length} anotaciones';
}
