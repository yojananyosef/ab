// La direccion del navegador y lo que significa.
//
// UNA RUTA ES UNA FRASE, Y HAY QUE PODER COPIARLA Y MANDARLA. La ruta del lector
// es `/leer/KJV2006/John.3.16`: el identificador del modulo, el libro en la clave que
// usa el **modulo** --`John`, no `Juan`--, y el capitulo y el versiculo.
//
// POR QUE LA CLAVE Y NO EL NOMBRE EN CASTELLANO. Porque la ruta la resuelve el
// modulo, no la tabla de libros de este proyecto. Si la ruta dijera "Juan", habria
// que traducirla al abrir, y si la tabla de traduccion y el modulo no coincidieran
// --y hay 66 libros-- la ruta abriria un libro distinto del que dice. Con la clave
// del modulo la ruta no se puede malinterpretar: o abre lo que dice o no abre.
//
// Y EL IDENTIFICADOR DEL MODULO VA EN LA RUTA PORQUE EL LECTOR ABRE UN TEXTO
// CONCRETO. Sin el, `/leer/John.3.16` no dice que se esta leyendo. Con el, la
// direccion es una cita completa y quien la recibe sabe que texto esta mirando.
//
// EL PREFIJO DEL DESPLIEGUE NO SE ADIVINA, SE BUSCA. En el sitio publicado esta en
// `/ab/leer/...`, y `/ab/` lo pone `--base-href` al compilar. No se puede leer el
// `<base href>` desde Dart sin ir al DOM, y no se va a ir al DOM por esto. En vez de
// eso se busca la **ultima** aparicion de `/leer/`, y es exacto: un pasaje no lleva
// barras --es `John.3.16`--, asi que en una ruta valida `/leer/` aparece una vez, y
// si aparece mas de una la que manda es la ultima, que es donde empieza el pasaje.
// Hardcodear `/ab/` seria peor: el mismo binario en local, servido en la raiz, ya no
// funcionaria.
//
// `PathUrlStrategy` Y `HashUrlStrategy` COMO RESERVA, Y POR QUE HACE FALTA.
// GitHub Pages no sabe servir el documento de entrada para una ruta que no existe:
// devuelve su propia pagina de 404, con un 404 de verdad y sin aplicacion dentro. El
// arreglo es un `404.html` que es el `index.html` --lo hace el CI-- y a partir de ahi
// recargar conserva el pasaje. Si ese fichero no esta, o si el sitio se sirve de una
// forma que no lo admite, la ruta con barra se queda sin nada, y es mejor un
// `#!/leer/...` feo que una pagina en blanco. De ahi la reserva.
//
// LO QUE NO HAY AQUI. No hay un enrutador de verdad, ni tabla de rutas, ni
// `go_router`. Hay cuatro rutas y dos formas de volver a casa, y con eso un `switch`
// se lee mejor que una tabla. Si mañana hay diez rutas y tres anidamientos, la
// conclusion es la contraria y habra que traerse uno.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:ab/domain/models/referencia.dart';

/// Que hay en pantalla ahora mismo.
///
/// Esto **es** el estado de navegacion, no una copia. La direccion del navegador es
/// la que dice, y el historial es quien la cambia cuando se pulsa "atras".
sealed class Ruta {
  const Ruta();
}

/// La biblioteca: la lista de textos.
class RutaBiblioteca extends Ruta {
  const RutaBiblioteca();

  @override
  bool operator ==(Object other) => other is RutaBiblioteca;

  @override
  int get hashCode => 2;

  @override
  String toString() => 'biblioteca';
}

/// El lector, con un texto abierto y un pasaje en pantalla, y con un comentario al lado.
///
/// Y LA RUTA ES UNA FRASE QUE SE PUEDE COPIAR Y MANDAR:
///
///     /leer/KJV2006/John.3.16                 el texto, a secas
///     /leer/KJV2006/John.3.16/con/CLARKE      el texto, con el comentario al lado
///
/// Y EL COMENTARIO VA **DETRAS** DEL PASAJE, en un segmento `con`, y no antes. Va
/// detras porque es lo que se **anade** a algo, y porque el pasaje es la parte que el
///omodulo resuelve: si el comentario fuera lo que va primero, bastaria mover dos
///_segmentos para que `/leer/CLARKE/KJV2006/John.3.16` dijera lo mismo y significara
/// otra cosa.
///
/// Y EN UN SEGMENTO Y NO EN UN PARAMETRO DE CONSULTA, por dos motivos. Uno: la URL es lo
/// que se copia y se manda, y con dos mecanismos --ruta y consulta-- hay que decidir
/// cual gana cuando discrepan, y no hay regla que no haya que inventar. Dos: `Rutas` ya
/// corta por barras porque el despliegue anade un prefijo que no se puede adivinar, y
/// mirar tambien el `?` es mas codigo para una frase que ya cabe en la ruta.
///
/// Y PUEDE SER NULO, y entonces la ruta es la de antes, sin cambios: una direccion
/// `/leer/KJV2006/John.3.16` de hace un mes sigue abriendo lo mismo que abria.
class RutaLectura extends Ruta {
  const RutaLectura(this.modulo, this.referencia, [this.comentario]);

  /// El identificador del modulo, tal cual lo declara el manifiesto.
  final String modulo;

  /// Que se esta leyendo. El versiculo es null cuando se lee el capitulo entero.
  final Referencia referencia;

  /// El identificador del comentario que va al lado, o null si no hay ninguno.
  ///
  /// Es un **identificador**, no un `ModuloAbierto`. La ruta es un texto: no lleva
  /// bases de datos dentro, y por eso mismo no puede asegurar que ese modulo siga
  /// descargado. Eso lo comprueba quien la aplica.
  final String? comentario;

  @override
  bool operator ==(Object other) =>
      other is RutaLectura &&
      other.modulo == modulo &&
      other.referencia == referencia &&
      other.comentario == comentario;

  @override
  int get hashCode => Object.hash(modulo, referencia, comentario);

  @override
  String toString() =>
      'leer $modulo ${referencia.paraUrl}${comentario == null ? '' : ' con $comentario'}';
}

/// Una busqueda en un texto abierto.
///
///     /buscar/KJV2006/propitiacion
///
/// Y LA PALABRA VA **CODIFICADA** EN LA RUTA, y no es un detalle. Sin codificar, buscar
/// "in the world" --que es una frase con un espacio y con palabras corriente-- deja una
/// ruta con espacios dentro, que el navegador codifica por su cuenta al escribirla en la
/// barra y al volverla a leer llega distinta: la palabra buscada seria "in" o "in%20the".
/// Con `Uri.encodeComponent` lo que sale y lo que vuelve es lo mismo, y se comprueba.
///
/// Y EL TEXTO **NO SE ABRE** CON ESTA RUTA. `/leer/...` abre un pasaje y ensena el texto;
/// una busqueda ensena una lista de coincidencias, y quien elige una de ellas abre el
/// pasaje. Son dos cosas distintas y por eso son dos rutas: `RutaLectura` no tiene que
/// saber de busquedas, y la pantalla de busqueda no tiene que fingir que lee.
class RutaBusqueda extends Ruta {
  const RutaBusqueda(this.modulo, this.palabra);

  /// El identificador del modulo en el que se busca, tal cual lo declara el manifiesto.
  final String modulo;

  /// La palabra buscada, ya sin espacios alrededor.
  ///
  /// Y VA CRUDA, NO codificada: la ruta la codifica y la decodifica, y guardar aqui una
  /// cadena con `%20` seria el patron que hace que una ruta se Compare con si misma.
  final String palabra;

  @override
  bool operator ==(Object other) =>
      other is RutaBusqueda && other.modulo == modulo && other.palabra == palabra;

  @override
  int get hashCode => Object.hash(modulo, palabra);

  @override
  String toString() => 'buscar $modulo "$palabra"';
}

/// El indice de una palabra en un texto abierto.
///
///     /indice/KJV2006/G2316
///
/// Y DICE EL **NUMERO**, no la palabra. Es lo unico que esta en el modulo: ver
/// `indice_de_strong.dart`. La palabra la pone quien pulsa, y un enlace con la palabra
/// tendria que adivinar cual de las que llevan ese numero es la buena, que en el KJV son
/// `God`, `gods`, `godly` y `gods` otra vez para el mismo `G2316`.
///
/// Y EL NUMERO VA **CRUDO**, como va en la ruta del pasaje. Con la letra: `G` es griego y
/// `H` hebreo, y `G2316` y `H2316` son dos entradas distintas del lexicon.
class RutaIndice extends Ruta {
  const RutaIndice(this.modulo, this.numero);

  /// El identificador del modulo en el que se busca, tal cual lo declara el manifiesto.
  final String modulo;

  /// El numero del lexicon, tal cual lo trae el modulo.
  final String numero;

  @override
  bool operator ==(Object other) =>
      other is RutaIndice && other.modulo == modulo && other.numero == numero;

  @override
  int get hashCode => Object.hash(modulo, numero);

  @override
  String toString() => 'indice $modulo $numero';
}

/// Una ruta que no se entiende.
///
/// No es un error: es lo que llega al abrir una direccion escrita a mano con un
/// error, y tambien lo que llega de un historial de otra pagina. Se distingue de
/// [RutaBiblioteca] a proposito, porque tratar un enlace roto como "estoy en la
/// biblioteca" es silencioso, y tratar la biblioteca como un enlace roto es ruidoso.
class RutaDesconocida extends Ruta {
  const RutaDesconocida(this.texto);
  final String texto;

  @override
  bool operator ==(Object other) => other is RutaDesconocida && other.texto == texto;

  @override
  int get hashCode => texto.hashCode;

  @override
  String toString() => 'desconocida "$texto"';
}

/// Convierte texto de direccion en rutas, y al reves.
///
/// Sin estado y sin el navegador: son funciones puras, y eso es lo que permite
/// probarlas todas en la maquina de Dart sin montar nada.
class Rutas {
  const Rutas._();

  /// `/leer/{modulo}/{libro}.{capitulo}[.{versiculo}][/con/{comentario}]`.
  ///
  /// El separador es una barra entre el modulo y el pasaje, y un punto dentro del
  /// pasaje. Es la convencion que usa el propio modulo en su tabla de versiculos, y
  /// no es inventada aqui: `John.3.16` es como se escribe dentro del `.amod`. El
  /// comentario, si lo hay, va en un segmento mas, detrás del pasaje.
  static const String prefijoDeLectura = '/leer/';

  /// La ruta de la biblioteca.
  static const String biblioteca = '/';

  /// Lee una ruta de direccion.
  static Ruta leer(String direccion) {
    var ruta = direccion.trim();
    if (ruta.isEmpty) return const RutaBiblioteca();

    // Con estrategia de hash llega `/#/leer/...`: lo anterior al `#` es la pagina,
    // que no es ruta nuestra, y lo que sigue si.
    final hash = ruta.indexOf('#');
    if (hash >= 0) ruta = ruta.substring(hash + 1);

    if (ruta.isEmpty || ruta == '/') return const RutaBiblioteca();
    if (ruta.endsWith('/index.html') || ruta.endsWith('/index.htm')) {
      return const RutaBiblioteca();
    }
    // Con estrategia de barra y sin prefijo: `/leer/...`.
    if (ruta.startsWith(prefijoDeLectura)) return _leerPasaje(ruta);
    if (ruta.startsWith(prefijoDeBusqueda)) return _buscar(ruta);
    if (ruta.startsWith(prefijoDeIndice)) return _indice(ruta);

    // Con prefijo de despliegue: `/ab/leer/...`. Se toma la **ultima** aparicion
    // porque un pasaje no lleva barras, asi que la ultima es la buena.
    final corte = ruta.lastIndexOf(prefijoDeLectura);
    if (corte > 0) return _leerPasaje(ruta.substring(corte));

    // Y LO MISMO PARA `/buscar/`, con el mismo "ultima aparicion" por el mismo motivo.
    // Sin esta linea, `/ab/buscar/KJV2006/begotten` era una ruta que no se entiende, y en
    // el sitio publicado **toda** busqueda compartida seria un enlace roto: es el fallo
    // que no se ve en desarrollo, porque en desarrollo no hay prefijo, y que aparece solo
    // en produccion.
    final corteDeBusqueda = ruta.lastIndexOf(prefijoDeBusqueda);
    if (corteDeBusqueda > 0) return _buscar(ruta.substring(corteDeBusqueda));

    final corteDelIndice = ruta.lastIndexOf(prefijoDeIndice);
    if (corteDelIndice > 0) return _indice(ruta.substring(corteDelIndice));

    // Sin barra inicial, por si llega como `leer/...`.
    if (ruta.startsWith('leer/')) return _leerPasaje('/$ruta');
    if (ruta.startsWith('buscar/')) return _buscar('/$ruta');
    if (ruta.startsWith('indice/')) return _indice('/$ruta');

    return RutaDesconocida(ruta);
  }

  /// La parte que va despues de `/leer/`:
  ///
  ///     {modulo}/{libro}.{capitulo}[.{versiculo}][/con/{comentario}]
  ///
  /// Y SE CORTA POR **TODAS** LAS BARRAS, Y NO POR LA PRIMERA. La primera version
  /// tomaba `resto.indexOf('/')` y se llevaba todo lo demas como pasaje, asi que
  /// `/leer/KJV2006/John.3.16/con/CLARKE` le preguntaba a `Referencia.tryParse` por
  /// `John.3.16/con/CLARKE`, que no es un pasaje y devolvia null. El error era
  /// silencioso --una ruta desconocida-- y por eso mismo es el que hay que evitar.
  ///
  /// Y CUATRO PARTES COMO MAXIMO. Una quinta no es una ruta de este proyecto, y
  /// aceptarla seria inventarse una sintaxis que nadie ha escrito.
  static Ruta _leerPasaje(String ruta) {
    final resto = ruta.substring(prefijoDeLectura.length);
    final partes = resto.split('/');
    if (partes.length < 2 || partes.length > 4) return RutaDesconocida(ruta);

    final modulo = Uri.decodeComponent(partes[0]);
    if (modulo.isEmpty) return RutaDesconocida(ruta);

    final referencia = Referencia.tryParse(Uri.decodeComponent(partes[1]));
    if (referencia == null) return RutaDesconocida(ruta);

    // Y SIN COMENTARIO SI NO HAY MAS PARTES. Y si las hay, tienen que ser exactamente
    // `con` y un identificador: `/leer/KJV2006/John.3.16/CLARKE` no es una ruta con
    // comentario, es una ruta mal escrita, y tratarla como lo primero haria que un
    // enlace con un segmento de mas abriera el texto **sin** comentario y sin decir
    // nada, que es la forma de que un enlace mal escrito parezca un enlace bueno.
    String? comentario;
    if (partes.length >= 3) {
      if (partes[2] != 'con') return RutaDesconocida(ruta);
      if (partes.length < 4) return RutaDesconocida(ruta);
      comentario = Uri.decodeComponent(partes[3]);
      if (comentario.isEmpty) return RutaDesconocida(ruta);
    }

    return RutaLectura(modulo, referencia, comentario);
  }

  /// `/buscar/{modulo}/{palabra}`.
  ///
  /// Y EN SU PROPIO PREFIJO, y no dentro de `/leer/`, porque una busqueda **no** es un
  /// pasaje. Si fuera `/leer/KJV2006/buscar/propitiacion`, entonces `RutaLectura` tendria
  /// un caso mas que no es una lectura, y `Referencia.tryParse` tendria que saber que hay
  /// una palabra de mas en el medio para decir que la ruta no se entiende.
  static const String prefijoDeBusqueda = '/buscar/';

  /// La parte que va despues de `/buscar/`: `{modulo}/{palabra}`.
  ///
  /// Y TRES PARTES COMO MAXIMO, como en el lector. Una palabra con una barra dentro es
  /// una palabra con una barra: se codifica, se lee, y si aun asi sobran partes es que la
  /// ruta esta mal escrita.
  static Ruta _buscar(String ruta) {
    final resto = ruta.substring(prefijoDeBusqueda.length);
    final partes = resto.split('/');
    if (partes.length != 2) return RutaDesconocida(ruta);

    final modulo = Uri.decodeComponent(partes[0]);
    final palabra = Uri.decodeComponent(partes[1]).trim();

    // Y UNA PALABRA VACIA **ES** LA PANTALLA DE BUSQUEDA, y no una ruta que no se
    // entiende. Es el caso de `/buscar/KJV2006/`, que es lo que escribe la propia app al
    // pulsar la lupa: la pantalla con el campo puesto y sin buscar. Lo contrario --
    // mandarlo a la biblioteca -- obliga a volver a abrirla y a buscar el texto otra vez.
    //
    // Y LO QUE NO SE ENTIENDE ES `/buscar/KJV2006`, SIN barra final. Esa no la escribe
    // nadie y no dice que pantalla es: es una ruta a medio escribir. La diferencia entre
    // las dos es una barra, y esa barra es la que dice " aqui no hay palabra todavia".
    if (modulo.isEmpty) return RutaDesconocida(ruta);

    return RutaBusqueda(modulo, palabra);
  }

  /// `/indice/{modulo}/{numero}`.
  ///
  /// Y DOS PARTES, y sin barra final tolera: un indice sin numero no es un indice, es un
  /// fallo de escritura, y por eso `/indice/KJV2006/` no se entiende.
  static const String prefijoDeIndice = '/indice/';

  /// La parte que va despues de `/indice/`: `{modulo}/{numero}`.
  static Ruta _indice(String ruta) {
    final resto = ruta.substring(prefijoDeIndice.length);
    final partes = resto.split('/');
    if (partes.length != 2) return RutaDesconocida(ruta);

    final modulo = Uri.decodeComponent(partes[0]);
    final numero = Uri.decodeComponent(partes[1]).trim().toUpperCase();

    // Y EL NUMERO **SE COMPRUEBA AQUI**, y no en la pantalla. Una ruta que no se entiende
    // avisa y se queda donde estaba; una ruta que se entiende pero lleva un numero que no
    // es un numero del lexicon abre una pantalla vacia sin decir por que. Comprobarlo en
    // el parser es lo unico que evita las dos cosas a la vez.
    final esNumero = numero.length >= 4 &&
        (numero[0] == 'G' || numero[0] == 'H') &&
        RegExp(r'^[GH][0-9]{3,}$').hasMatch(numero);
    if (modulo.isEmpty || !esNumero) return RutaDesconocida(ruta);

    return RutaIndice(modulo, numero);
  }

  /// La direccion de una ruta.
  ///
  /// Sin el prefijo del despliegue: ese lo pone el `base href` al compilar, y
  /// escribirlo aqui tambien seria duplicarlo --y hardcodearlo, que es peor. Lo que
  /// sale de aqui es la parte relativa, que es justo lo que `SystemNavigator` y el
  /// `Router` esperan.
  static String escribir(Ruta ruta) => switch (ruta) {
        RutaBiblioteca() => biblioteca,
        RutaIndice(:final modulo, :final numero) =>
          '$prefijoDeIndice${Uri.encodeComponent(modulo)}/${Uri.encodeComponent(numero)}',
        RutaBusqueda(:final modulo, :final palabra) =>
          '$prefijoDeBusqueda${Uri.encodeComponent(modulo)}/${Uri.encodeComponent(palabra)}',
        RutaLectura(:final modulo, :final referencia, :final comentario) =>
          '$prefijoDeLectura${Uri.encodeComponent(modulo)}/${referencia.paraUrl}'
          '${comentario == null ? '' : '/con/${Uri.encodeComponent(comentario)}'}',
        RutaDesconocida(:final texto) => texto,
      };
}

/// Prepara la estrategia de direccion del navegador.
///
/// Se llama **antes** de `runApp`, y por eso devuelve un futuro en vez de ser `void`:
/// cambiar la estrategia despues de que arranque la aplicacion deja la barra a medio
/// camino y hay que recargar para que cuadre.
///
/// Con estrategia de barra primero y con el hash de reserva. Y la reserva no es
/// teorica: si `index.html` no esta copiado como `404.html`, GitHub Pages responde
/// con su pagina de error a `/ab/leer/KJV2006/John.3.16` y con estrategia de barra
/// no hay aplicacion que lo pinte. Es lo que hace el CI, pero el CI tambien puede
/// fallar, y una aplicacion que solo funciona cuando el despliegue fue bien es una
/// aplicacion que falla sin avisar.
///
/// Y DEVUELVE SI HA PODIDO PONER LA DE BARRA, porque quien lo llama tiene que
/// saberlo: si acabo en el hash, la ruta que se ve es distinta y hay que decirlo.
Future<bool> prepararEstrategiaDeDireccion() async {
  if (!kIsWeb) return false;
  try {
    usePathUrlStrategy();
    return true;
  } catch (e) {
    // No es un fallo de la aplicacion: es que este sitio no admite la estrategia de
    // barra. El hash funciona en todas partes, a costa de la barra.
    debugPrint('No se ha podido usar la estrategia de ruta con barra: $e');
  }
  try {
    setUrlStrategy(const HashUrlStrategy());
  } catch (e) {
    debugPrint('Tampoco se ha podido usar la estrategia de hash: $e');
  }
  return false;
}

/// La ruta con la que arranca la aplicacion.
///
/// En web la lee de la barra del navegador; en el resto, la biblioteca.
///
/// Y SE LEE UNA VEZ, al arrancar. No se escucha el `popstate` aqui: de eso se encarga
/// el `Router`, que es quien tiene el historial y quien llama a
/// `SystemNavigator.routeInformationUpdated` --que es el `pushState` y el
/// `replaceState` del navegador-- segun el tipo que le reporta el delegado. Ver
/// `lib/app/navegador.dart`.
///
/// Leerla otra vez desde aqui seria tener dos sitios de donde viene la ruta, y el
/// segundo siempre gana.
Ruta rutaInicial([String? direccion]) {
  final d = direccion ?? (kIsWeb ? Uri.base.toString() : '/');
  return Rutas.leer(d);
}
