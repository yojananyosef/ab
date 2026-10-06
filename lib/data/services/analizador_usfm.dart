// El analizador del marcado que trae el `.amod` en la columna `raw`.
//
// MEDIDO SOBRE EL KJV REAL el 5 de octubre de 2026. Un versiculo entero:
//
//     \wj ¶ \+w For|strong="G1063"\+w* \+w God|strong="G2316"\+w* \+w so|strong="G3779"\+w*
//     \+w loved|strong="G0025"\+w* \+w the world|strong="G2889"\+w*, \+w that|strong="G5620"\+w* ...
//
// Y LAS CUATRO COSAS QUE HAY QUE SABER DE ESE TEXTO, TODAS MIDAS:
//
// 1. **La marca abre con `\` y cierra con `\*`, y el cierre lleva `\*` sin espacio.** Hay
//    630.866 aperturas `\w` y 72.386 `\+w` en el modulo, y el inventario entero de lo que
//    lleva barra invertida es de **diez** nombres y ningun otro: `w`, `+`, `a`, `f`, `n`,
//    `p`, `q`, `b`, `t`, `s`. No hay marcas con espacios ni nombres raros.
//
// 2. **Se anidan.** `\wj ¶ \+w For...\+w* \+w God...\+w*` tiene `\wj` abierta mientras
//   _inner_ van las palabras, y `\nd \+w LORD\+w*\nd*` idem. Por eso el estado es una
//    **pila** y no un interruptor: si fuera un interruptor, abrir y cerrar `\wj` dejaria
//    `\nd` sin cerrar y a partir de ahi el final de versiculo se tomaria por una apertura.
//
// 3. **`|strong="G2316"` va DETRAS de la palabra y pegado a ella**, siempre. Medido en los
//    cuatro versos con `\add` del modulo, el patron es `palabra|strong="G0000"` y no hay
//    ningun caso con el atributo delante.
//
// 4. **`¶` NO ES TEXTO.** Es la marca de frontera de versiculo y va suelta, o justo despues
//    de `\wj`. No aparece en la columna `text` de ninguno de los 31.102 versiculos, asi
//    que se quita; y se quita **sustituyendola por nada**, no por un espacio, porque si
//    no los 4.076 versiculos con `\wj` empiezan con un espacio que no tienen.
//
// Y EL TEXTO QUE SALE DE AQUI TIENE QUE SER **IGUAL** AL DE LA COLUMNA `text`. No
// "parecido", no "casi": el mismo. Y eso no se comprueba aqui con un ejemplo, se
// comprueba en `test/data/texto_marcado_test.dart` con los **31.102 versiculos** del
// fichero real, que es lo unico que demuestra que el marcado no se esta comiendo ni un
// caracter. Un lector que altera el texto es un lector que no se puede citar.

import 'package:ab/domain/models/nota_al_pie.dart';
import 'package:ab/domain/models/token_de_texto.dart';

/// Las anotaciones del `raw` de un versiculo, en el mismo orden que sus palabras.
///
/// Y `texto` ES EL PARAMETRO Y NO UN RESULTADO, a proposito: el texto del versiculo es el
/// de la columna `text` del modulo y no se reconstruye aqui. Ver la cabecera de
/// `token_de_texto.dart` para por que, que es la decision de la que depende que esto no
/// pueda cambiar ni un caracter de la Escritura.
///
/// Y SI NO CUADRA EL NUMERO DE PALABRAS, SE DEVUELVE UNA LISTA VACIA. Es el fallo que hay
/// que elegir: un versiculo sin los numeros del lexicon, o un versiculo con el numero de
/// la palabra de al lado. El primero no se ve; el segundo es una mentira en la pantalla.
/// Medido el 5 de octubre de 2026, la linea base es de 60,03% de los versiculos del KJV,
/// y con el aparato de variantes excluido sube.
TextoAnotado anotarTexto(String texto, String? raw) {
  final anotaciones = raw == null ? <AnotacionDePalabra>[] : anotacionesDe(raw);
  return TextoAnotado(
    texto: texto,
    anotaciones: anotaciones.length == texto.split(' ').length
        ? anotaciones
        : const <AnotacionDePalabra>[],
  );
}

// ============================================================================
// LAS NOTAS AL PIE, Y POR QUE ESTO NO ES LO MISMO QUE LAS ANOTACIONES
// ============================================================================
//
// Lo de arriba saca **anotaciones por palabra**: el numero del lexicon, si el traductor anadio
// la palabra, y si la dijo Jesus. Eso no quita nada del texto: las tres cosas van **ademas**.
//
// Una nota al pie es distinto: **quita texto del versiculo**. El `raw` dice
// `\f + \fr 1.6 \ft Riphath: or, Diphath as it is in some copies\f*` y la columna `text` trae
// esa frase **pegada al final del versiculo**. Y asi se estaba pintando: la glosa de un
// siglo XVII en el mismo cuerpo y con el mismo color que la Palabra. Medido el 6 de octubre
// de 2026, son **6.959 notas en 5.844 versiculos**, el **18,79 %** del KJV.
//
// ASI QUE AQUI SI SE TOCA EL TEXTO, y es la **unica** vez, y por eso lleva su propio metodo y
// su propia prueba en vez de colarse en [anotarTexto].
//
// Y LA REGLA ES TODO O NADA, MEDIDA:
//
//     versiculos con \f                                  5.844
//     `text` termina exactamente en "REF TEXTO" x N     5.841
//     no termina                                          3
//
// Los tres son Salmos 119:24, 119:112 y 119:160, y el motivo esta escrito en el metodo. Un
// versiculo de Salmos de tres entre 5.844 no justifica un aviso en pantalla, y sobre todo no
// justifica **mover** una nota a un sitio que no es el suyo.

/// Una nota al pie con su ancla, y la letra que le toca en el capitulo.
///
/// Y LA LETRA SE PONE AQUI Y NO EN LA VISTA, porque el orden depende de **cuantas notas tiene
/// el capitulo**, que un versiculo suelto no sabe: el mismo versiculo puede ser la tercera
/// nota de un capitulo y la primera de otro.
class NotaDeLectura {
  const NotaDeLectura({
    required this.ancla,
    required this.texto,
    required this.referencia,
  });

  /// Indice de palabra donde va la letra, o null si no se pudo saber.
  final int? ancla;

  /// El texto de la nota, sin marcas USFM y **sin** la referencia delante.
  final String texto;

  /// Lo que dice el `\fr`: `1.6`, es decir libro.capitulo.versiculo.
  ///
  /// Y SE GUARDA Y NO SE PINTA, por dos razones. Una: la columna `text` del modulo lo trae
  /// delante --`... Togarmah. 1.6 Riphath: or, Diphath...`-- y sin el no se puede comprobar
  /// que la separacion no ha quitado nada. Dos: en pantalla no vale, porque todos los
  /// versiculos de 1Cronicas 1 llevan `1.6` y no distinguirian dos notas del mismo versiculo.
  /// En pantalla va la letra; esta se queda para la prueba.
  final String referencia;

  /// La misma nota con la letra que le toca en el capitulo.
  ///
  /// Y LA LETRA SE PONE EN ESTE COPIADO Y NO AL LEER, porque el orden depende de **cuantas
  /// notas tiene el capitulo**, y un versiculo suelto no lo sabe: el mismo versiculo puede
  /// ser la tercera nota de un capitulo y la primera de otro. Quien las numera es quien ha
  /// leido el capitulo entero, que es el repositorio.
  NotaAlPie conLetra(String letra) =>
      NotaAlPie(letra: letra, texto: texto, ancla: ancla);
}

/// El texto de un versiculo **sin** sus notas al pie, y las notas con su ancla.
///
/// Y ES UN TIPO PROPIO Y NO UN PARAMETRO DE [anotarTexto], porque [anotarTexto] NO puede
/// tocar el texto: ahi las anotaciones van al lado y el texto sale entero, y eso se comprueba
/// con los 31.102 versiculos. Si la separacion de notas se colara ahi, esa comprobacion
/// empezaria a validar un texto que ya no es el del modulo, y dejaria de comprobar lo que
/// dice comprobar.
class TextoConNotas {
  const TextoConNotas({
    required this.texto,
    required this.notas,
    required this.raw,
  });

  /// El texto del versiculo sin las notas. Tal cual, si no habia notas.
  final String texto;

  /// Las notas, en el orden en que el modulo las puso. Vacia si no hay.
  final List<NotaDeLectura> notas;

  /// El `raw` **sin** los cuerpos de las notas, para el emparejamiento del lexicon.
  ///
  /// Y ESTE CAMPO ES LA RAZON DE QUE ESTA SEPARACION NO SEA UN `String`: sin el, el `raw`
  /// que se pasa a `anotarTexto` sigue traendo las palabras del cuerpo de la nota, el
  /// emparejamiento cuenta mas anotaciones que palabras tiene el texto, **descarta el
  /// versiculo entero** y el versiculo se queda sin lexicon. Medido: de los 5.844 versiculos
  /// con notas, **0** recibian anotaciones con el `raw` entero, y son mas del 90 % con el
  /// `raw` sin notas.
  ///
  /// Y ES SOLO EL `raw`, Y EL TEXTO NO. El texto sale de la columna `text`, sin tocar, y esto
  /// no lo altera.
  final String? raw;
}

/// Separa las notas al pie del versiculo, y dice donde va cada una.
///
/// Y DEVUELVE [textoSinNotas] SI NO HAY NADA QUE SEPARAR, para que el llamante no
/// tenga que comprobar `notas.isEmpty` para saber si el texto cambio: si no habia notas, el
/// texto es el del modulo, byte a byte.
TextoConNotas separarNotasAlPie(String texto, String? raw) {
  // Y EL `\f` SIN MAS, Y NO UN `raw LIKE '%\f%'` DE LA CONSULTA, porque aqui no hay consulta.
  // El modulo de comentario tiene `raw == text` en las 19.742 notas --medido--, y ahi no
  // hay nada que separar.
  if (raw == null || !raw.contains('\\f')) {
    return textoSinNotas(texto, raw);
  }

  final notas = <NotaDeLectura>[];
  final sufijo = <String>[];
  final cierres = <int>[];
  var indice = 0;
  var palabrasContadas = 0;

  // Y SE RECORRE EN UN SOLO PASADA Y NO CON UNA EXPRESION GLOBAL, porque el ancla de cada
  // nota es **la cuenta de palabras del versiculo que hay antes de ella**, y esa cuenta solo
  // sale si se va mirando el `raw` de izquierda a derecha: una `RegExp` que devolviese las
  // cuatro piezas sueltas daria las notas pero no el sitio.
  //
  // Y LA CUENTA ES **ACUMULADA Y VA SALTANDO LAS NOTAS ANTERIORES**, y no se recalcula desde
  // el principio para cada nota. Recalcular contaria tambien las palabras del cuerpo de la
  // nota anterior, que estan en el `raw` y **no** estan en el texto que se pinta: el ancla de
  // la segunda nota de un versiculo saldria desplazada por el numero de palabras de la
  // primera, y caeria fuera del texto. Medido: asi el ancla cae dentro en **6.956 de 6.956**
  // notas; recalculando desde cero, solo en 5.841.
  while (indice < raw.length) {
    final abierto = raw.indexOf('\\f ', indice);
    if (abierto < 0) break;

    final palabrasAntes = palabrasContadas + _palabrasDeRawHasta(raw, indice, abierto);

    // La referencia va entre `\fr` y el `\ft`, y el cuerpo entre `\ft` y el `\f*`.
    final ref = _entreMarcas(raw, abierto + 3, 'fr');
    final cuerpo = _entreMarcas(raw, abierto + 3, 'ft');
    if (ref == null || cuerpo == null) break;

    final cerrado = raw.indexOf('\\f*', abierto);
    if (cerrado < 0) break;

    final textoLimpio = _sinMarcas(cuerpo);
    final refLimpia = _sinMarcas(ref);
    notas.add(
      NotaDeLectura(
        ancla: palabrasAntes,
        texto: textoLimpio,
        referencia: refLimpia,
      ),
    );
    sufijo.add('$refLimpia $textoLimpio');

    // Y LO QUE SE CUENTA HASTA AQUI ES SOLO LO DEL **VERSICULO**: el tramo desde el cierre de
    // la nota anterior hasta esta apertura. Las palabras del cuerpo de esta nota todavia no
    // cuentan, y no contaran nunca, porque no son del versiculo.
    cierres.add(cerrado);
    palabrasContadas = palabrasAntes;
    indice = cerrado + 3;
  }

  if (notas.isEmpty) return textoSinNotas(texto, raw);

  // Y LA COMPROBACION EXACTA, Y ES LA MITAD DEL TRABAJO. La columna `text` tiene que
  // terminar **exactamente** en `"REF TEXTO" "REF TEXTO"`, separado por un espacio y en el
  // mismo orden. Medido: 5.841 de 5.844. Si no, **no se separa nada**: el versiculo se
  // pinta entero, con la nota dentro, como se ha pintando siempre. Es preferible ensenar
  // una nota en su sitio a moverla de sitio.
  final esperado = sufijo.join(' ');
  final recortado = texto.trimRight();
  if (!recortado.endsWith(esperado)) {
    return textoSinNotas(texto, raw);
  }

  final escritura = recortado.substring(0, recortado.length - esperado.length);
  final sinEspacios = escritura.trimRight();

  // Y EL ANCLA SE COMPRUEBA CONTRA EL TEXTO YA SIN NOTAS, y no contra el texto entero: con
  // el texto entero, la palabra 40 de un versiculo con dos notas seria la palabra 40 de un
  // texto que ya no existe, y la letra caeria a destajo.
  //
  // Medido: el ancla cae dentro en 6.956 de 6.959. Las tres que no son de Salmos 119 y el
  // motivo es el nombre hebreo de la letra. Esas se listan al pie sin letra en el texto: una
  // letra pegada a la palabra equivocada es peor que una nota sin letra.
  final total = _cuentaPalabras(sinEspacios);
  final conAncla = <NotaDeLectura>[
    for (final n in notas)
      NotaDeLectura(
        ancla: (n.ancla != null && n.ancla! <= total) ? n.ancla : null,
        texto: n.texto,
        referencia: n.referencia,
      ),
  ];

  return TextoConNotas(
    texto: sinEspacios,
    notas: conAncla,
    // Y EL `raw` QUE SE PASA ES EL QUE **NO** TIENE LOS CUERPOS DE LAS NOTAS, y para eso hay
    // que quitar cada nota entera, del `\f ` de apertura al `\f*` de cierre. Quitar solo el
    // `\ft` dejaria la referencia y las marcas, y la cuenta seguiria descuadrando.
    raw: _rawSinCuerposDeNotas(raw, cierres),
  );
}

/// El `raw` con las notas al pie enteras fuera, del `\f ` de apertura al `\f*` de cierre.
///
/// Y QUITA **TODA** LA NOTA, no solo el cuerpo: si se dejara la referencia --`1.6`-- entre el
/// `\f` y el `\ft`, y las marcas de por medio, el recuento de palabras del emparejamiento
/// seguiria teniendo dos palabras de mas por nota y el versiculo se descartaria entero.
String _rawSinCuerposDeNotas(String raw, List<int> cierres) {
  if (cierres.isEmpty) return raw;
  var salida = StringBuffer();
  var i = 0;
  for (final cerrado in cierres) {
    // Y EL `\f ` DE APERTURA SE BUSCA DESDE DONDE TERMINO LA ANTERIOR, no desde el principio,
    // para que dos notas del mismo versiculo se quiten las dos y no la misma dos veces.
    final abierto = raw.indexOf('\\f ', i);
    if (abierto < 0 || abierto >= cerrado) break;
    salida.write(raw.substring(i, abierto));
    i = cerrado + 3;
  }
  if (i < raw.length) salida.write(raw.substring(i));
  return salida.toString();
}

/// El texto tal cual, sin notas, para el caso de que no haya nada que separar.
///
/// Y ES UNA FABRICA Y NO UN `const`, porque `texto` viene del modulo y no se puede meter en
/// una constante.
TextoConNotas textoSinNotas(String texto, String? raw) =>
    TextoConNotas(texto: texto, notas: const <NotaDeLectura>[], raw: raw);

/// Cuantas palabras de texto hay, por la misma regla que usa el emparejamiento del lexicon.
int _cuentaPalabras(String texto) =>
    texto.split(' ').where((p) => _tieneLetrasNiDigitos(p)).length;

/// El valor de una marca de una nota: lo que va entre `\fr` y `\ft`, o entre `\ft` y `\f*`.
String? _entreMarcas(String raw, int desde, String cual) {
  final abre = raw.indexOf('\\$cual', desde);
  if (abre < 0) return null;
  var i = abre + cual.length + 2;
  if (i >= raw.length) return null;

  final cierra = cual == 'fr'
      ? raw.indexOf('\\ft', i)
      : raw.indexOf('\\f*', i);
  if (cierra < 0) return null;
  return raw.substring(i, cierra);
}

/// El cuerpo de un `raw` sin las marcas, que es como lo trae la columna `text`.
///
/// Y SOLO QUITA LO QUE **NO** ES TEXTO: `\nd` sin divisor, `\nd*`, `+`, `¶` y cualquier
/// `|atributo="..."`. Un `\w` suelto no aparece en un `\ft`; si apareciera, el texto traeria
/// una barra invertida y eso si seria un cambio en lo que se lee.
String _sinMarcas(String s) {
  var salida = s.replaceAll(RegExp(r'\\\+?nd\*?'), '');
  salida = salida.replaceAll('\\*', '');
  salida = salida.replaceAll(RegExp(r'\|[a-zA-Z]+="[^"]*"'), ' ');
  salida = salida.replaceAll('¶', ' ');
  salida = salida.replaceAll('+', '');
  return _colapsarEspacios(salida).trim();
}

/// Cuantas palabras hay en el `raw` antes de la posicion [hasta].
///
/// Y CUENTA IGUAL QUE [anotacionesDe], porque tiene que contar igual: si el lexicon cuenta
/// una palabra que esta nota cuenta de otra forma, el ancla de la nota y el numero del
/// lexicon apuntan a palabras distintas y las dos marcas se cruzan.
///
/// Y EL RANGO ES `[desde, hasta)` Y NO SOLO `hasta`, porque con el `raw` entero arrastraria las
/// palabras de las notas que ya se han pasado, y esas no son del versiculo.
int _palabrasDeRawHasta(String raw, int desde, int hasta) {
  var cuenta = 0;
  final buffer = StringBuffer();
  var i = desde;

  void cerrar() {
    if (buffer.isEmpty) return;
    final limpia = _colapsarEspacios(buffer.toString()).trim();
    buffer.clear();
    if (limpia.isEmpty) return;
    for (final palabra in limpia.split(' ')) {
      if (_tieneLetrasNiDigitos(palabra)) cuenta++;
    }
  }

  while (i < hasta && i < raw.length) {
    final c = raw[i];
    if (c == '\\' && i + 1 < hasta) {
      final nombre = _nombreDeMarcaEn(raw, i + 1);
      if (nombre == null) {
        buffer.write(c);
        i++;
        continue;
      }
      var j = i + 1 + nombre.length;
      if (j < raw.length && raw[j] == '*') j++;
      cerrar();
      i = j;
      continue;
    }
    if (c == '\u00b6' || c == '+') {
      cerrar();
      i++;
      continue;
    }
    buffer.write(c);
    i++;
  }
  cerrar();

  return cuenta;
}

/// Las anotaciones de un `raw`, una por palabra de como el modulo las vio.
///
/// Y ES **PUBLICA** porque hay que poder mirarla sin el texto al lado. Con el emparejamiento
/// de [anotarTexto] por dentro, un emparejamiento que falla se ve como un versiculo sin
/// lexicon y no hay forma de mirar las palabras para ver donde se ha desfasado el numero.
/// Es la razon por la que el numero de una palabra de mas --`+ 1.6` en las cronicas-- salia
/// como "209 de 31.102" y no como "la palabra 27 esta desfasada".
List<AnotacionDePalabra> anotacionesDe(String raw) {
  if (!raw.contains('\\')) {
    return <AnotacionDePalabra>[];
  }

  final abiertas = <String>[];
  String? strong;
  final palabras = <AnotacionDePalabra>[];
  final buffer = StringBuffer();

  void cerrarPalabra() {
    final limpia = _colapsarEspacios(buffer.toString()).trim();
    buffer.clear();
    if (limpia.isEmpty) return;

    // Y UNA MARCA ENVUELVE A VECES UNA **FRASE**, no una palabra. Medido en Juan 3:16 del
    // KJV:
    //
    //     \+w the world|strong="G2889"\+w*        dos palabras, un numero
    //     \+w he gave|strong="G1325"\+w*          dos palabras, un numero
    //     \+w only begotten|strong="G3439"\+w*    dos palabras, un numero
    //     \+w life|strong="G1722"\+w*            una palabra, un numero
    //
    // Una anotacion por marca daba **23** anotaciones para un versiculo de **25** palabras:
    // el emparejamiento se descartaba entero y Juan 3:16 se quedaba sin lexicon. Con una
    // anotacion por palabra el numero cuadra.
    //
    // Y EL NUMERO SE PONE EN LA **PRIMERA** PALABRA DE LA FRASE, que es lo que dice la
    // norma de USFM para los marcadores a nivel de caracter. Y SE PONE CON UN COMENTARIO
    // PORQUE HAY CASOS EN QUE EL NUMERO ES DE LA FRASE Y NO DE LA PALABRA:
    //
    //     \+w the world|strong="G2889"\+w*   G2889 es `world`, la segunda
    //     \+w he gave|strong="G1325"\+w*     G1325 es `gave`, la segunda
    //
    // Eso no se puede decidir aqui sin un lexicon, y este proyecto no tiene uno. Asi que
    // el numero va en la primera y **se dice que puede ser de la frase**, que es lo
    // cierto.
    final fuerte = strong;
    strong = null;

    var esLaPrimera = true;
    for (final palabra in limpia.split(' ')) {
      // Y UN TROZO QUE **NO TIENE LETRAS NI DIGITOS** NO ES UNA PALABRA, y no cuenta como
      // una. El `raw` separa la puntuacion como un trozo mas --
      // `\+w life|strong="G1722"\+w*.`-- mientras que en la columna `text` el punto va
      // **pegado** a la palabra: `life.`. Con la cuenta equivocada el emparejamiento se
      // descarta entero: medido, sin esta regla solo 209 de 31.102 versiculos recibian
      // anotaciones.
      if (!_tieneLetrasNiDigitos(palabra)) continue;
      palabras.add(AnotacionDePalabra(
        strong: esLaPrimera ? fuerte : null,
        // Y SI ESTA ANADIDO SE PREGUNTA A LA **PILA**, y no a una bandera.
        //
        // La bandera se ponia al abrir `dd` y no se apagaba al cerrar, asi que todo lo
        // que venia despues quedaba marcado como del traductor. Se veia en 1 Cronicas
        // 1:19, que tiene dos `dd` y despues `Peleg;` y `Joktan` -- y `Peleg` salia
        // marcado como anadido cuando lo puso el modulo.
        esAnadido: abiertas.contains('add'),
        // Y LO MISMO CON `\wj`, Y POR LA PILA Y NO CON UNA BANDERA, por lo mismo que
        // `\add`. La bandera se ponia al abrir `\wj` y no se apagaba al cerrar, y todo lo
        // que venia despues --el resto del versiculo-- salia marcado como de Jesus.
        //
        // Y `\wj` SE USA IGUAL QUE `\add`: abre con `\wj` y cierra con `\wj*`.
        esPalabraDeJesus: abiertas.contains('wj'),
      ));
      esLaPrimera = false;
    }
  }

  var i = 0;
  while (i < raw.length) {
    final c = raw[i];

    if (c == '\\' && i + 1 < raw.length) {
      final nombre = _nombreDeMarcaEn(raw, i + 1);
      if (nombre == null) {
        i++;
        continue;
      }
      var j = i + 1 + nombre.length;
      var cierra = false;
      if (j < raw.length && raw[j] == '*') {
        cierra = true;
        j++;
      }
      if (cierra) {
        // Y LA PALABRA SE CIERRA **ANTES** DE SACAR LA MARCA DE LA PILA, y no despues.
        //
        // El texto de una palabra esta **entre** su marca de apertura y su marca de
        // cierre, asi que hay que cerrarlo con el estado que hay mientras esa marca esta
        // abierta. Con el orden al reves, `\add was\add*` se cerraba despues de sacar `\add` de la pila
        // y la palabra salia **sin** marcar: en 1 Cronicas 1:19, que tiene dos `\add`,
        // no salia ninguna.
        cerrarPalabra();
        if (abiertas.isNotEmpty) abiertas.removeLast();
        i = j;
        continue;
      }
      if (nombre.startsWith('s') || nombre == 'tl') {
        var k = j;
        while (k < raw.length && _esEspacio(raw[k])) {
          k++;
        }
        final desde = k;
        while (k < raw.length && _esDigito(raw[k])) {
          k++;
        }
        if (k > desde) j = k;
      }
      // Y EL ORDEN IMPORTA: primero se cierra lo que habia, con el estado **anterior**, y
      // despues se abre la marca nueva. Al reves, la palabra justo antes de un `dd`
      // saldria marcada como anadida.
      cerrarPalabra();
      abiertas.add(nombre);
      i = j;
      continue;
    }

    if (c == '|' && raw.startsWith('|strong="', i)) {
      const prefijo = '|strong="';
      final fin = raw.indexOf('"', i + prefijo.length);
      if (fin > 0) {
        final valor = raw.substring(i + prefijo.length, fin);
        if (_pareceNumeroDelLexicon(valor)) {
          // Y EL NUMERO ES DE LA PALABRA QUE SE ESTA CERRANDO, porque el atributo va
          // detras de la palabra: en `God|strong="G2316"` el `G2316` es de `God`.
          strong = valor;
          cerrarPalabra();
        }
        i = fin + 1;
        continue;
      }
    }

    if (c == '\u00b6' || c == '+') {
      // El `\u00b6` es la frontera de versiculo y el `+` separa el aparato de variantes.
      // Los dos son una marca mas, y ninguno es texto.
      i++;
      continue;
    }

    buffer.write(c);
    i++;
  }
  cerrarPalabra();

  return palabras;
}

/// Una letra de marca.
///
/// Y SOLO MINUSCULAS, y solo las diez que hay en el modulo, medidas el 5 de octubre de
/// 2026: `w`, `a`, `f`, `n`, `p`, `q`, `b`, `t`, `s` y `+`.
bool _esNombreDeMarca(String c) =>
    c.length == 1 && c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7a;

/// El nombre de la marca que empieza en [desde], o null si ahí no hay ninguna.
///
/// Y EL `\+w` ES EL CASO RARO: es una barra, un `+` y una letra. El `+` no es una letra,
/// asi que sin este caso el `\+w` se leia como la marca `\` seguida de texto `+w`.
String? _nombreDeMarcaEn(String raw, int desde) {
  if (desde >= raw.length) return null;

  if (raw[desde] == '+') {
    var j = desde + 1;
    while (j < raw.length && _esNombreDeMarca(raw[j])) {
      j++;
    }
    return j > desde + 1 ? raw.substring(desde, j) : null;
  }

  if (!_esNombreDeMarca(raw[desde])) return null;
  var j = desde;
  while (j < raw.length && _esNombreDeMarca(raw[j])) {
    j++;
  }
  return raw.substring(desde, j);
}

/// Si el valor de un `|strong="..."` parece un numero del lexicon.
///
/// Y `G` O `H` SEGUIDO DE DIGITOS, y mas de dos digitos: `G0025` y `H0436` valen, `G1` no.
bool _pareceNumeroDelLexicon(String valor) {
  if (valor.length < 3) return false;
  final letra = valor[0];
  if (letra != 'G' && letra != 'H') return false;
  return _esTodoDigitos(valor.substring(1));
}

bool _esTodoDigitos(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    if (!_esDigito(s[i])) return false;
  }
  return true;
}

bool _esDigito(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

bool _esEspacio(String c) => c == ' ' || c == '\t' || c == '\n';

/// Si el texto tiene al menos una letra o un digito.
///
/// Y CON `isAlpha` Y CON `isDigit` DE DART, y no con una lista de signos de puntuacion.
/// Una lista tendria que enumerar `.`, `,`, `;`, `:`, `!`, `?`, `'`, `-`... y se olvidaria
/// uno, y el que se olvide seria un signo que no cuenta como palabra y descuadra el
/// emparejamiento entero de un versiculo.
bool _tieneLetrasNiDigitos(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c.codeUnitAt(0) > 0x7f) return true;
    if (_esDigito(c)) return true;
    if (c.toLowerCase() != c.toUpperCase()) return true;
  }
  return false;
}

String _colapsarEspacios(String s) => s.replaceAll(RegExp(r'[ \t\n]+'), ' ');
