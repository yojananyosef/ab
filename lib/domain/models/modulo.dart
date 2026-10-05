// Un modulo que el catalogo ofrece: una Biblia, un comentario, lo que sea.
//
// La app NO trae una lista de textos. Este modelo no dice que tipos existen:
// solo como se describe uno que el manifiesto ya ha declarado. Si el manifiesto
// anade un tipo nuevo, este modelo lo tiene que cambiar; si no lo tiene, es
// porque el manifiesto tampoco lo declaro.
//
// Las dos URLs son a proposito y ninguna sustituye a la otra:
//
// - `urlDescarga` es la release de GitHub. Es correcta para clientes nativos.
// - `urlNavegador` es el sitio de GitHub Pages. Es la unica que un navegador
//   puede leer, porque es la unica que responde `Access-Control-Allow-Origin`.
//
// Usar la equivocada funciona en una plataforma y falla en la otra, y ese es el
// fallo mas caro que puede tener este repositorio, porque compila, pasa las
// pruebas y no funciona. Ver `docs/investigacion/transporte-cors.md`.

/// Tipo de contenido. Deliberadamente corto: el catalogo solo admite Biblia y
/// comentario, y anadir mas es un change con su propio debate.
enum TipoModulo {
  biblia('bible'),
  comentario('commentary');

  const TipoModulo(this.enElCatalogo);

  /// El valor exacto que escribe el manifiesto. Va de aqui para no repetir la
  /// cadena en dos sitios, que es como un dia una se queda sin actualizar.
  final String enElCatalogo;

  static TipoModulo? desdeCatalogo(String v) {
    for (final t in TipoModulo.values) {
      if (t.enElCatalogo == v) return t;
    }
    return null;
  }
}

/// Un modulo del catalogo, ya validado y ya en Castellano.
class Modulo {
  const Modulo({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.idioma,
    required this.licencia,
    required this.tamanoBytes,
    required this.sha256,
    required this.urlDescarga,
    required this.urlNavegador,
  });

  final String id;
  final String nombre;
  final TipoModulo tipo;

  /// Codigo ISO 639-3 tal como lo escribe el manifiesto: `eng`, `spa`.
  final String idioma;

  /// `PublicDomain` o el nombre de una Creative Commons.
  final String licencia;

  final int tamanoBytes;

  /// sha256 en hexadecimal del fichero completo. Se comprueba **antes** de
  /// abrir, y un modulo que no cuadra no se abre.
  final String sha256;

  /// Release de GitHub. Para nativo.
  final Uri urlDescarga;

  /// GitHub Pages. Para navegador.
  final Uri urlNavegador;

  /// NO HAY UN `megabytes` AQUI, Y ANTES SI LO HABIA.
  ///
  /// Era `(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)` y devolvia `"21.5"` **con
  /// punto**: en castellano el punto separa los millares y la coma los decimales, asi que
  /// "21.5 MB" se lee como veintiuno con cinco megabytes. Y estaba en tres sitios de la
  /// interfaz --la biblioteca, el boton de descargar y el de quitar el comentario--, con lo
  /// que el numero estaba mal en los tres.
  ///
  /// Ahora lo formatea [bytesEnCastellano], que vive en `ui/core/numeros.dart` y es el
  /// unico sitio. Y no se ha dejado un atajo aqui para no volver a tener dos: un formateador
  /// de lo que se ve es de la interfaz, y un modelo de dominio que formatea texto para
  /// pantalla es un modelo de dominio que sabe como se ve.

  /// El mismo modulo con otro hash. Se usa cuando el manifiesto se actualiza y
  /// un modulo descargado tiene una version distinta.
  Modulo conSha256(String nuevo) => Modulo(
    id: id,
    nombre: nombre,
    tipo: tipo,
    idioma: idioma,
    licencia: licencia,
    tamanoBytes: tamanoBytes,
    sha256: nuevo,
    urlDescarga: urlDescarga,
    urlNavegador: urlNavegador,
  );

  /// Las dos URLs tienen que llevar al mismo fichero. El catalogo lo
  /// comprueba y tambien, por si acaso, aqui.
  bool get urlsCoincidenEnElFichero =>
      _fichero(urlDescarga) == _fichero(urlNavegador);

  static String _fichero(Uri u) {
    final partes = u.pathSegments.where((p) => p.isNotEmpty).toList();
    return partes.isEmpty ? '' : partes.last;
  }

  @override
  bool operator ==(Object other) => other is Modulo && other.id == id && other.sha256 == sha256;

  @override
  int get hashCode => Object.hash(id, sha256);

  @override
  String toString() => 'Modulo($id, $tipo, $nombre, $tamanoBytes bytes)';
}

/// De menor a mayor, que es como se lee una lista de descargas: primero lo
/// barato.
int compararPorTamano(Modulo a, Modulo b) => a.tamanoBytes.compareTo(b.tamanoBytes);

/// Cuanto ocupa el catalogo entero en el dispositivo, en bytes.
///
/// Se enseena en la pantalla de biblioteca porque es el numero que decide si
/// uno puede permitirse llevarselo en el movil.
int totalBytes(Iterable<Modulo> mods) =>
    mods.fold<int>(0, (suma, m) => suma + m.tamanoBytes);
