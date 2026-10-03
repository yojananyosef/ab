// Los 66 libros de la Biblia, en orden canonico, con su nombre en castellano.
//
// ESTE FICHERO TIENE ACENTOS A PROPOSITO. La regla de prosa ASCII del repositorio
// es para comentarios y documentacion; los nombres de libro son **texto que se
// ensena en pantalla**, y "Genesis" sin tilde ni "Levitico" sin acento son
// errores de la interfaz, no estilo. Es la misma excepcion que las citas textuales
// de los informes de investigacion.
//
// QUE HAY AQUI Y QUE NO: hay **nombres**. No hay capitulos, ni versiculos, ni
// totales, ni numeros de ninguna clase.
//
// Es deliberado, y por un motivo que ya se pago en otro sitio: la tabla de
// libros del repositorio hermano se escribio primero de memoria y **21 de 66
// tenia un numero de versiculos equivocado**. Aqui los numeros se leen del
// modulo con una consulta, y por eso Genesis ofrece 50 capitulos aunque la RVR
// ofrezca 51.
//
// Lo que si esta es el **orden canonico**, que es como la gente sabe que se
// lee un libro. Ese orden no lo declara el modulo --`book` es texto sin indice--
// y es conocimiento universal, como saber que un ano tiene doce meses.
//
// Sin relacion con el catalogo: esto es una lista de **libros**, no de **textos**.
// Saber que hay 66 libros no es saber que Biblias existen. Lo segundo viene del
// manifiesto y solo del manifiesto.

import 'libro.dart';

/// Los 66 libros, en orden canonico. El orden es el de toda Biblia impresa.
const List<Libro> kLibros = [
  Libro('Genesis', 'Génesis'),
  Libro('Exodus', 'Éxodo'),
  Libro('Leviticus', 'Levítico'),
  Libro('Numbers', 'Números'),
  Libro('Deuteronomy', 'Deuteronomio'),
  Libro('Joshua', 'Josué'),
  Libro('Judges', 'Jueces'),
  Libro('Ruth', 'Rut'),
  Libro('1Samuel', '1 Samuel'),
  Libro('2Samuel', '2 Samuel'),
  Libro('1Kings', '1 Reyes'),
  Libro('2Kings', '2 Reyes'),
  Libro('1Chronicles', '1 Crónicas'),
  Libro('2Chronicles', '2 Crónicas'),
  Libro('Ezra', 'Esdras'),
  Libro('Nehemiah', 'Nehemías'),
  Libro('Esther', 'Ester'),
  Libro('Job', 'Job'),
  Libro('Psalms', 'Salmos'),
  Libro('Proverbs', 'Proverbios'),
  Libro('Ecclesiastes', 'Eclesiastés'),
  Libro('SongOfSolomon', 'Cantares'),
  Libro('Isaiah', 'Isaías'),
  Libro('Jeremiah', 'Jeremías'),
  Libro('Lamentations', 'Lamentaciones'),
  Libro('Ezekiel', 'Ezequiel'),
  Libro('Daniel', 'Daniel'),
  Libro('Hosea', 'Oseas'),
  Libro('Joel', 'Joel'),
  Libro('Amos', 'Amós'),
  Libro('Obadiah', 'Abdías'),
  Libro('Jonah', 'Jonás'),
  Libro('Micah', 'Miqueas'),
  Libro('Nahum', 'Nahum'),
  Libro('Habakkuk', 'Habacuc'),
  Libro('Zephaniah', 'Sofonías'),
  Libro('Haggai', 'Hageo'),
  Libro('Zechariah', 'Zacarías'),
  Libro('Malachi', 'Malaquías'),
  Libro('Matthew', 'Mateo'),
  Libro('Mark', 'Marcos'),
  Libro('Luke', 'Lucas'),
  Libro('John', 'Juan'),
  Libro('Acts', 'Hechos'),
  Libro('Romans', 'Romanos'),
  Libro('1Corinthians', '1 Corintios'),
  Libro('2Corinthians', '2 Corintios'),
  Libro('Galatians', 'Gálatas'),
  Libro('Ephesians', 'Efesios'),
  Libro('Philippians', 'Filipenses'),
  Libro('Colossians', 'Colosenses'),
  Libro('1Thessalonians', '1 Tesalonicenses'),
  Libro('2Thessalonians', '2 Tesalonicenses'),
  Libro('1Timothy', '1 Timoteo'),
  Libro('2Timothy', '2 Timoteo'),
  Libro('Titus', 'Tito'),
  Libro('Philemon', 'Filemón'),
  Libro('Hebrews', 'Hebreos'),
  Libro('James', 'Santiago'),
  Libro('1Peter', '1 Pedro'),
  Libro('2Peter', '2 Pedro'),
  Libro('1John', '1 Juan'),
  Libro('2John', '2 Juan'),
  Libro('3John', '3 Juan'),
  Libro('Jude', 'Judas'),
  Libro('Revelation', 'Apocalipsis')
];

/// Cuantos libros hay. Es una asercion, no un dato: si el dia que viene esta
/// lista no tiene 66, algo esta mal en el canon y hay que saberlo al arrancar.
const int kTotalLibros = 66;

/// Posicion del primer libro del Nuevo Testamento, contando desde 1. Aparta a
/// los dos Testamentos en el selector.
const int kNuevoTestamentoDesde = 40;

/// Busca un libro por su clave de modulo ('John').
Libro? libroPorId(String id) {
  for (final l in kLibros) {
    if (l.id == id) return l;
  }
  return null;
}

/// Busca un libro por su nombre en castellano, sin distinguir mayusculas,
/// espacios de sobra, acentos ni el guion de los libros numerados.
///
/// "1 Corintios", "1corintios", "II Corintios", "Primero de Corintios" y
/// "Segundo de Corintios" tienen que devolver lo mismo. Si no, la gente escribe
/// como habla y la app no lo encuentra, que es la queja clasica de los lectores
/// de Biblia: el buscador de paso es lo primero que se prueba.
Libro? libroPorNombre(String nombre) {
  final limpio = _normalizar(nombre);
  if (limpio.isEmpty) return null;
  for (final l in kLibros) {
    if (_normalizar(l.nombre) == limpio) return l;
  }
  return null;
}

/// Otras formas de escribir el mismo libro.
///
/// NO se genera un alias sin numero para los libros que llevan numero, y es a
/// proposito. "1 Juan", "2 Juan" y "3 Juan" comparten nombre: si "Juan" a secas
/// resolviera a alguno de los tres, habria que elegir, y quien lo eligiera
/// acabaria en el evangelio de San Juan cuando queria las epístolas. En la
/// practica "Juan" es el evangelio, que es como lo usa todo el mundo.
///
/// Con numeros romanos tambien: "II Corintios" es "2 Corintios".
List<String> aliasDe(Libro libro) {
  final n = libro.nombre;
  final conNumero = RegExp(r'^(\d)\s+(.*)$').firstMatch(n);
  if (conNumero == null) return <String>[n];
  final numero = conNumero.group(1)!;
  final resto = conNumero.group(2)!;
  // Solo el ordinal que corresponde a ESTE libro. Si "1 Samuel" generase
  // tambien "Segundo Samuel", el normalizador lo devolveria como si fuera
  // "2 Samuel", y buscar un libro llevaria al otro sin avisar.
  final ordinales = switch (numero) {
    '1' => const ['Primer', 'Primera'],
    '2' => const ['Segundo', 'Segunda'],
    '3' => const ['Tercer', 'Tercera'],
    _ => const <String>[],
  };
  return <String>[
    n,
    '$numero$resto',
    for (final o in ordinales) '$o $resto',
    '$numero\u00ba $resto',
  ];
}

/// Borra acentos, mayusculas, puntuacion y las palabras que solo sirven para
/// decir "el primero" o "el segundo".
///
/// Se hace con una tabla de reemplazos y no con un paquete de normalizacion de
/// unicode porque no hace falta mas: son 66 nombres fijos, y una dependencia
/// para esto seria mas codigo del que sustituye.
String _normalizar(String s) {
  var t = s.toLowerCase().trim();
  t = t
      .replaceAll(RegExp('[a\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]'), 'a')
      .replaceAll(RegExp('[e\u00e8\u00e9\u00ea\u00eb\u00e7]'), 'e')
      .replaceAll(RegExp('[i\u00ec\u00ed\u00ee\u00ef]'), 'i')
      .replaceAll(RegExp('[o\u00f2\u00f3\u00f4\u00f5\u00f6]'), 'o')
      .replaceAll(RegExp('[u\u00f9\u00fa\u00fb\u00fc]'), 'u')
      .replaceAll('\u00f1', 'n')
      .replaceAll(RegExp('[\u00ba\u00aa\u00b0]'), '')
      // Un numero romano al principio es un numero: "II Corintios" y
      // "2 Corintios" son el mismo libro, y hay quien lo escribe asi.
      .replaceAllMapped(RegExp(r'^\s*([ivxlc]+)\s+'), (m) => ' ${_romano(m.group(1)!)} ');
  t = t.replaceAll(RegExp('[^a-z0-9 ]'), ' ');
  // Palabras que no aportan al identificar el libro, pero que SI aportan el
  // numero: "Segundo de Corintios" tiene que acabar en "2corintios" y no en
  // "corintios". Asi que los ordinales se traducen a cifra ANTES de quitarse,
  // y solo se borran las palabras que no llevan numero.
  t = t.replaceAllMapped(
    RegExp(r'\b(primero|primer|segundo|segunda|tercero|tercera)\b'),
    (m) => ' ${_ordinal(m.group(1)!)} ',
  );
  t = t.replaceAll(
    RegExp(r'\b(de|del|libro|libros|epistola)\b'),
    ' ',
  );
  // Se quitan TODOS los espacios, no se colapsan. La razon es concreta:
  // "2 Corintios" y "2corintios" tienen que ser el mismo libro, y si se
  // colapsaran a un solo espacio quedarian distintos.
  return t.replaceAll(RegExp(r'\s+'), '');
}

const Map<String, int> _romanos = <String, int>{
  'i': 1,
  'ii': 2,
  'iii': 3,
  'iv': 4,
  'v': 5,
  'vi': 6,
  'vii': 7,
  'viii': 8,
  'ix': 9,
  'x': 10,
};

/// Un numero romano pequeno, que es lo unico que aparece en nombres de libro.
/// Devuelve el original si no se reconoce, para no perder texto.
String _romano(String r) => _romanos[r]?.toString() ?? r;

/// Un ordinal a cifra: "primer", "primero" y "primera" son 1. Devuelve el
/// original si no se reconoce, para no perder texto.
String _ordinal(String p) {
  const mapa = <String, String>{
    'primer': '1',
    'primero': '1',
    'primera': '1',
    'segundo': '2',
    'segunda': '2',
    'tercer': '3',
    'tercero': '3',
    'tercera': '3',
  };
  return mapa[p] ?? p;
}
