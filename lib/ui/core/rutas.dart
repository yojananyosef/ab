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

/// El lector, con un texto abierto y un pasaje en pantalla.
class RutaLectura extends Ruta {
  const RutaLectura(this.modulo, this.referencia);

  /// El identificador del modulo, tal cual lo declara el manifiesto.
  final String modulo;

  /// Que se esta leyendo. El versiculo es null cuando se lee el capitulo entero.
  final Referencia referencia;

  @override
  bool operator ==(Object other) =>
      other is RutaLectura && other.modulo == modulo && other.referencia == referencia;

  @override
  int get hashCode => Object.hash(modulo, referencia);

  @override
  String toString() => 'leer $modulo ${referencia.paraUrl}';
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

  /// `/leer/{modulo}/{libro}.{capitulo}[.{versiculo}]`.
  ///
  /// El separador es una barra entre el modulo y el pasaje, y un punto dentro del
  /// pasaje. Es la convencion que usa el propio modulo en su tabla de versiculos, y
  /// no es inventada aqui: `John.3.16` es como se escribe dentro del `.amod`.
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

    // Con prefijo de despliegue: `/ab/leer/...`. Se toma la **ultima** aparicion
    // porque un pasaje no lleva barras, asi que la ultima es la buena.
    final corte = ruta.lastIndexOf(prefijoDeLectura);
    if (corte > 0) return _leerPasaje(ruta.substring(corte));

    // Sin barra inicial, por si llega como `leer/...`.
    if (ruta.startsWith('leer/')) return _leerPasaje('/$ruta');

    return RutaDesconocida(ruta);
  }

  /// La parte que va despues de `/leer/`: `{modulo}/{libro}.{capitulo}[.{versiculo}]`.
  static Ruta _leerPasaje(String ruta) {
    final resto = ruta.substring(prefijoDeLectura.length);
    final corte = resto.indexOf('/');
    if (corte <= 0 || corte == resto.length - 1) return RutaDesconocida(ruta);

    final modulo = Uri.decodeComponent(resto.substring(0, corte));
    final pasaje = Uri.decodeComponent(resto.substring(corte + 1));

    final referencia = Referencia.tryParse(pasaje);
    if (referencia == null) return RutaDesconocida(ruta);
    if (modulo.isEmpty) return RutaDesconocida(ruta);

    return RutaLectura(modulo, referencia);
  }

  /// La direccion de una ruta.
  ///
  /// Sin el prefijo del despliegue: ese lo pone el `base href` al compilar, y
  /// escribirlo aqui tambien seria duplicarlo --y hardcodearlo, que es peor. Lo que
  /// sale de aqui es la parte relativa, que es justo lo que `SystemNavigator` y el
  /// `Router` esperan.
  static String escribir(Ruta ruta) => switch (ruta) {
        RutaBiblioteca() => biblioteca,
        RutaLectura(:final modulo, :final referencia) =>
          '$prefijoDeLectura${Uri.encodeComponent(modulo)}/${referencia.paraUrl}',
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
