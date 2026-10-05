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
