// Lo que devuelve una busqueda: los resultados y cuantos hay.
//
// QUE ESTO NO ES UNA `List<Referencia>`. Una lista de referencias obliga a la pantalla a
// preguntar otra vez por cada versiculo para poder ensenar un trozo de texto, y eso son
// **200 consultas** para pintar 200 lineas. Aqui cada resultado trae su extracto, y la
// consulta trae las dos cosas a la vez.
//
// Y POR QUE NO SE SUSTITUIR POR UNA CONSULTA CON `GROUP_CONCAT`. Se puede, y el
// resultado seria una sola cadena con todo dentro: entonces un error de sintaxis en una
// linea rompe el resultado entero y no se puede ensenar ni la mitad. Con una fila por
// resultado, una fila mala es una fila que falta y el resto sigue en pie.
//
// Y EL **TOTAL** ESTA EN EL MISMO SITIO Y NO SE CALCULA DESPUES. Con un `limit` de 200,
// `total` es lo que dice si hay 3 o si hay 4.140, y esa diferencia cambia lo que se
// ensena en pantalla: tres resultados son una lista, y 4.140 son una muestra. Sin el
// total, quien busca "God" ve 200 lineas y no tiene forma de saber si son todas.
//
// Y `limiteDeResultados` ESTA AQUI Y NO EN PANTALLA. Es una decision de la app, no de quien
// mira, y por eso tiene nombre en el codigo y no es un numero escrito en el `limit` de una
// consulta.
import 'referencia.dart';

/// Cuantos resultados trae una busqueda como maximo.
///
/// Y 200, Y NO 1.000. Medido el 5 de octubre de 2026 sobre los modulos reales:
///
///     KJV2006  "God"          4.140 coincidencias,   6,0 ms
///     CLARKE   "propitiation"    15 coincidencias,  22,7 ms
///
/// Traer 1.000 seria el doble de tiempo y de memoria para 800 lineas que nadie va a
/// leer: la busqueda util es la que se lee, y la que no se lee ya esta en "hay 4.140".
const int limiteDeResultados = 200;

/// Cuantos caracteres de contexto se ponen a cada lado del texto encontrado.
///
/// Y 40 A CADA LADO, MEDIDOS. Con menos, "propitiation" en 1 Juan 2:2 sale como
/// `he is the propitiation for our sins` y no se ve de quien es; y el CLARKE escribe en
/// Meteorological, asi que con menos se ve `propiti` y media palabra sin principio.
///
/// Y NO ES EL VERSICULO ENTERO. El versiculo mas largo del KJV son 405 caracteres, y en
/// 200 lineas serian 81.000 caracteres en pantalla para encontrar una palabra.
const int contextoDelExtracto = 40;

/// Cuantos caracteres se pintan de extracto.
const int largoDelExtracto = 120;

/// Una coincidencia, con lo justo para ensenarla sin volver a preguntar.
class ResultadoDeBusqueda {
  const ResultadoDeBusqueda({
    required this.referencia,
    required this.extracto,
    required this.palabra,
  });

  /// Donde esta.
  final Referencia referencia;

  /// Un trozo de texto de alrededor, con la palabra dentro.
  final String extracto;

  /// La palabra buscada, tal cual la escribio quien busca.
  ///
  /// Y VA EN CADA RESULTADO Y NO EN UN CAMPO DE LA BUSQUEDA, y no por ahorrar un
  /// parametro. Es lo que permite **resaltar** la coincidencia mas adelante, y sobre todo
  /// es lo que evita el fallo de pintarla donde no es: la palabra sale del propio
  /// resultado, asi que no hay forma de que se resalte en un sitio que no lo tiene.
  final String palabra;

  /// La palabra buscada dentro de [extracto], o null si no esta.
  ///
  /// Y ES `null` Y NO UN EXCEPCION, y no por cautela: `extracto` viene de `substr`, que
  /// corta en el limite de [largoDelExtracto], y hay Extracto cuya coincidencia cae
  /// justo en el borde y se queda fuera. Con una palabra de 40 caracteres y 120 de
  /// extracto pasa de verdad.
  ///
  /// Y DEVUELVE LA **PRIMERA** Y NO LA MAS LARGA, que es lo que hace la pantalla. Es la
  /// que `instr` encontro, y la consulta esta construida para que esa sea la buena.
  int? posicionDeLaPalabra() {
    final i = extracto.toLowerCase().indexOf(palabra.toLowerCase());
    return i < 0 ? null : i;
  }

  @override
  String toString() => '${referencia.paraUrl}: $extracto';
}

/// Lo que devuelve una busqueda: los resultados y cuantos hay en total.
class BusquedaEnElModulo {
  const BusquedaEnElModulo({
    required this.palabra,
    required this.resultados,
    required this.total,
  });

  /// Una busqueda que no se ha hecho todavia.
  static const BusquedaEnElModulo vacia = BusquedaEnElModulo(
    palabra: '',
    resultados: <ResultadoDeBusqueda>[],
    total: 0,
  );

  /// La palabra buscada.
  final String palabra;

  /// Las coincidencias, en orden de libro, capitulo y versiculo.
  final List<ResultadoDeBusqueda> resultados;

  /// Cuantas hay en **total**, sin el limite.
  final int total;

  /// Si se ha dejado alguna fuera por el limite.
  ///
  /// Y ES LA COMPARACION DE ARRIBA Y NO UNA ADIVINADA: `total` no cuenta lo que se ha
  /// traído, cuenta lo que hay, y por eso se puede comparar con lo traído sin que las dos
  /// cosas sean lo mismo.
  bool get hayMas => total > resultados.length;

  /// Que no se ha buscado nada, y no que no haya salido nada.
  ///
  /// Y LA DIFERENCIA CUENTA. Una palabra de una letra no busca: `buscar` sale con cero
  /// resultados porque no se ha buscado, y quien mira ve "no hay resultados" y piensa que
  /// el texto no tiene esa palabra. Con [sinBuscar] se puede decir "busca al menos dos
  /// letras", que es lo que esta pasando de verdad.
  bool get sinBuscar => palabra.isEmpty;

  @override
  String toString() =>
      '$total resultados para "$palabra", ${resultados.length} enseñados';
}
