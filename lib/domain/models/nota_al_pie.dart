// Una nota al pie: la glosa que el modulo anade a un versiculo.
//
// ============================================================================
// POR QUE ESTO EXISTE Y POR QUE HACE FALTA YA
// ============================================================================
//
// Medido el 6 de octubre de 2026 sobre el `KJV2006_bible.amod` real --22.544.384 bytes,
// 31.102 versiculos--:
//
//     versiculos con \f                       5.844   (18,79 %)
//     notas al pie en total                   6.959
//     capitulos con notas                       913
//     notas por capitulo: media                7,6
//     el capitulo con mas notas: Daniel 11, con 35
//     el ancla cae dentro del versiculo     6.956 de 6.959
//
// Y LA COLUMNA `text` LAS TRAE **PEGADAS AL FINAL**, con su referencia delante. Un
// versiculo real:
//
//     1Cronicas 1:6
//     text: And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. 1.6 Riphath: or,
//           Diphath as it is in some copies
//     raw:  And the \w sons|strong="H1121"\w* ... \f + \fr 1.6 \ft Riphath: or,
//           Diphath as it is in some copies\f*
//
// O sea que **la pantalla de lectura estaba pintando la nota como si fuera Escritura**, en
// el mismo cuerpo y con el mismo color que la Palabra. Eso no es una carencia estetica: es
// texto que no es el texto del versiculo, ensenado como si lo fuera, y quien copia desde
// ahi copia una glosa del siglo XVII pegada al versiculo.
//
// ============================================================================
// Y POR QUE LA LETRA Y NO LA REFERENCIA DEL MODULO
// ============================================================================
//
// El `\fr` del modulo es `1.6`: **libro.capitulo.versiculo**. En pantalla seria un numero
// repetido en cada nota del capitulo --todos los versiculos de 1Cronicas 1 llevan `1.6`--
// y no distinguiria dos notas del mismo versiculo, que existen: hay 5.844 versiculos con
// mas de una nota, y el maximo medido es 35 en Daniel 11.
//
// La letra se reinicia en cada capitulo y va en orden de aparicion, que es como lo hace
// Logos y como lo hace cualquier Biblia impresa con notas al pie.
//
// ============================================================================
// Y POR QUE [ancla] ES UN INDICE DE PALABRA Y NO UN OFFSET DE CARACTER
// ============================================================================
//
// La columna `text` y la columna `raw` no tienen los mismos caracteres: el `raw` trae las
// marcas, el `text` no. Un offset de caracter del `raw` no señala nada en el `text`. La
// cuenta que si funciona es la de **palabras**, que es la misma que ya se usa para el
// emparejamiento del lexicon, y por eso va en el mismo sitio y con el mismo criterio.
//
// Y SI EL ANCLA NO CUADRA, NO SE ENGANCHA. Medido: el ancla cae dentro del versiculo en
// 6.956 de 6.959 notas. Las tres que no --Salmos 119:24, 119:112 y 119:160-- tienen el
// nombre hebreo de la letra despues de la nota, y ese nombre no esta en el `\ft`. En esas,
// la nota se lista al pie y **no** se pone letra en el texto: una letra pegada a la palabra
// equivocada es peor que una nota sin letra.
//
// ============================================================================
// Y LO QUE NO ESTA AQUI, MEDIDO
// ============================================================================
//
// No hay **referencias cruzadas**: `\x` sale **0** de 31.102. No hay **epigrafes de
// seccion**: `\s1` sale 35 veces y las 35 son la suscripcion final de las epistolas. Los
// enlaces azules y los titulos de seccion de la captura de Logos **no se pueden pintar**
// con este modulo, y estan medidos para que no se vuelva a buscar.

/// Una nota al pie de un versiculo.
///
/// Inmutable y sin metodos de UI, como [Versiculo] y [Nota]. Quien decide como se pinta es
/// la vista.
class NotaAlPie {
  const NotaAlPie({
    required this.letra,
    required this.texto,
    required this.ancla,
  });

  /// La letra con la que se marca en el texto: `a`, `b`, `c`...
  ///
  /// Y VA EN EL MODELO Y NO SE CALCULA AL PINTAR, porque el orden depende de **cuantas notas
  /// tiene el capitulo**, que no lo sabe un versiculo suelto: el mismo versiculo puede ser la
  /// tercera nota de un capitulo y la primera de otro. Quien las numera es quien ha leido el
  /// capitulo entero, que es el repositorio.
  final String letra;

  /// El texto de la nota, tal cual lo trae el modulo.
  ///
  /// Viene del `\ft`, ya sin las marcas USFM. Y **NO** lleva delante la referencia del
  /// `\fr`: esa es `1.6`, el lugar de la nota, y en el pie va la letra. Poner las dos cosas
  /// seria decir dos veces lo mismo y con numeros distintos.
  final String texto;

  /// **Cuantas palabras** de [Versiculo.texto] hay antes de la letra, o null si no se pudo
  /// saber.
  ///
  /// Y NO ES EL INDICE DE LA PALABRA SINO LA CUANTA, y la diferencia se ve en el caso mas
  /// frecuente del KJV: una nota que va **despues de la ultima palabra**.-alli el indice seria
  /// 10 en un texto de 10 palabras, fuera de rango, y la letra no se pintaria; con la cuenta,
  /// 10 quiere decir "despues de la palabra 9", que es justo lo que dice.
  ///
  /// Y EL `0` ES "ANTES DE LA PRIMERA PALABRA", que tambien existe: una nota pegada a la
  /// primera palabra del versiculo.
  ///
  /// Y ES `int?` Y NO `-1` PORQUE SON DOS COSAS DISTINTAS: "la nota va antes de la primera
  /// palabra" y "no se donde va" no se parecen en nada, y con un `-1` la vista tendria que
  /// acordarse de que es un valor especial. Un null lo dice.
  final int? ancla;

  @override
  String toString() => '$letra ancla=${ancla ?? "-"} $texto';
}