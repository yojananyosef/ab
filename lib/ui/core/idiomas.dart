// El idioma de un modulo, de `spa` a algo que se lee.
//
// POR QUE HAY UNA TABLA Y POR QUE NO ES LOGICA DEL CATALOGO. El manifiesto declara
// `eng` y la gente no lee `eng`: lee "ingles". Este fichero traduce **codigos de
// idioma**, que son como los meses del ano: los sabe todo el mundo y estan
// definidos fuera de aqui.
//
// Lo que NO hace es inventar. Un idioma que no esta en la tabla se ensena tal cual,
// en su codigo: `haw` sale como `haw`, y no como "hawaiano" porque no lo se. Y no
// hay ninguna entrada por defecto que suponga que los que faltan son los que uno
// espera, porque un codigo inventado es un idioma mal identificado.
//
// LA TABLA ES CORTA A PROPOSITO. Cubre los que el catalogo declara hoy y los que un
// lector de Biblia se encuentra de verdad. No es una lista exhaustiva: es lo que
// hace falta para leer el manifiesto que existe, con la cabeza puesta de que si el
// catalogo crece, esta tabla crece con el y no al reves.
//
// La alternativa --ensenar siempre el codigo-- tambien es defendible, y se
// descarta por una razon concreta: `spa` y `eng` no lo entiende todo el mundo, y
// esta app va dirigida a gente que no es tecnica.

/// El nombre de un idioma en castellano, o null si no se conoce.
String? nombreDeIdioma(String codigo) => _nombres[codigo];

/// El nombre del idioma, o el codigo si no se conoce.
///
/// Nunca devuelve una cadena vacia y nunca devuelve null: una celda de una lista
/// con un hueco es un sitio donde el ojo se para sin motivo.
String textoDeIdioma(String codigo) => _nombres[codigo] ?? codigo;

/// Los codigos que esta app sabe poner en castellano, ordenados.
///
/// Se usa para las pruebas: es la lista de lo que **no** devuelve el codigo tal
/// cual. Si el manifiesto declara un idioma que no esta aqui, la pantalla lo
/// ensena tal cual y eso esta bien.
const List<String> codigosConNombre = <String>[
  'ara', // arabe
  'deu', // aleman
  'ang', // ingles antiguo
  'ben', // bengali
  'bul', // bulgaro
  'cat', // catalan
  'ces', // checo
  'dan', // danes
  'ell', // griego
  'eng', // ingles
  'epo', // esperanto
  'est', // estonio
  'eus', // euskera
  'fas', // persa
  'fin', // finlandes
  'fra', // frances
  'heb', // hebreo
  'hin', // hindi
  'hrv', // croata
  'hun', // hungaro
  'ind', // indonesio
  'isl', // islandes
  'ita', // italiano
  'jpn', // japones
  'kor', // coreano
  'lat', // latin
  'lit', // lituano
  'nld', // neerlandes
  'nor', // noruego
  'pol', // polaco
  'por', // portugues
  'ron', // rumano
  'rus', // ruso
  'slk', // eslovaco
  'slv', // esloveno
  'spa', // espanol
  'swe', // suedio
  'tam', // tamil
  'tha', // tailandes
  'tur', // turco
  'ukr', // ucraniano
  'vie', // vietnamita
  'zho', // chino
];

const Map<String, String> _nombres = <String, String>{
  'ara': 'arabe',
  'deu': 'aleman',
  'ang': 'ingles antiguo',
  'ben': 'bengali',
  'bul': 'bulgaro',
  'cat': 'catalan',
  'ces': 'checo',
  'dan': 'danes',
  'ell': 'griego',
  'eng': 'ingles',
  'epo': 'esperanto',
  'est': 'estonio',
  'eus': 'euskera',
  'fas': 'persa',
  'fin': 'finlandes',
  'fra': 'frances',
  'heb': 'hebreo',
  'hin': 'hindi',
  'hrv': 'croata',
  'hun': 'hungaro',
  'ind': 'indonesio',
  'isl': 'islandes',
  'ita': 'italiano',
  'jpn': 'japones',
  'kor': 'coreano',
  'lat': 'latin',
  'lit': 'lituano',
  'nld': 'neerlandes',
  'nor': 'noruego',
  'pol': 'polaco',
  'por': 'portugues',
  'ron': 'rumano',
  'rus': 'ruso',
  'slk': 'eslovaco',
  'slv': 'esloveno',
  'spa': 'espanol',
  'swe': 'suedio',
  'tam': 'tamil',
  'tha': 'tailandes',
  'tur': 'turco',
  'ukr': 'ucraniano',
  'vie': 'vietnamita',
  'zho': 'chino',
};
