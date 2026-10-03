// Los modelos tal como llegan del manifiesto, antes de convertirse en dominio.
//
// Son "sucios" a proposito: guardan lo que el JSON trae, sin interpretar y sin
// corregir. El paso de "sucio" a "limpio" lo hace un `mapeo` explicito, que es
// donde se comprueba que estan todos los campos.
//
// La razon de tenerlos separados y no leer el JSON directamente en el dominio:
// si el repositorio leyera el JSON, cada sitio que consulte un modulo tendria
// que acordarse de como se llama cada clave, y en cuanto el manifiesto anadiera
// un campo habria tres sitios que tocar. Aqui se toca uno.

/// Un modulo tal como lo escribe el manifiesto.
class ModuloCatalogo {
  const ModuloCatalogo({
    required this.id,
    required this.type,
    required this.name,
    required this.language,
    required this.license,
    required this.version,
    required this.schemaVersion,
    required this.minReaderVersion,
    required this.sizeBytes,
    required this.sha256,
    required this.downloadUrl,
    required this.browserUrl,
  });

  final String id;

  /// `bible` o `commentary`. Lo decide el dominio, no aqui.
  final String type;

  final String name;
  final String language;
  final String license;
  final String version;
  final int schemaVersion;
  final int minReaderVersion;

  /// En el JSON es un numero entero. Si llega como otra cosa, el mapeo falla.
  final int sizeBytes;

  final String sha256;

  /// Release de GitHub. Para nativo.
  final String downloadUrl;

  /// GitHub Pages. Para navegador.
  final String browserUrl;

  /// Lee un modulo del JSON. Devuelve null si falta un campo obligatorio.
  ///
  /// Null y no excepcion, porque este metodo se llama por cada entrada del
  /// manifiesto y no todas tienen por que estar bien: si una esta mal, se dice
  /// cual y se sigue con las demas. Tirar la excepcion dejaria la biblioteca en
  /// blanco por un modulo malo, que es lo que no quiere nadie.
  static ModuloCatalogo? desdeJson(Map<String, dynamic> j) {
    final id = j['id'];
    final type = j['type'];
    final name = j['name'];
    final language = j['language'];
    final license = j['license'];
    final version = j['version'];
    final schemaVersion = j['schemaVersion'];
    final minReaderVersion = j['minReaderVersion'];
    final sizeBytes = j['sizeBytes'];
    final sha256 = j['sha256'];
    final downloadUrl = j['downloadUrl'];
    final browserUrl = j['browserUrl'];

    if (id is! String || id.isEmpty) return null;
    if (type is! String || name is! String || language is! String) return null;
    if (license is! String || version is! String) return null;
    if (schemaVersion is! int || minReaderVersion is! int) return null;
    if (sizeBytes is! int) return null;
    if (sha256 is! String || sha256.length != 64) return null;
    if (downloadUrl is! String || !downloadUrl.startsWith('https://')) return null;
    if (browserUrl is! String || !browserUrl.startsWith('https://')) return null;

    return ModuloCatalogo(
      id: id,
      type: type,
      name: name,
      language: language,
      license: license,
      version: version,
      schemaVersion: schemaVersion,
      minReaderVersion: minReaderVersion,
      sizeBytes: sizeBytes,
      sha256: sha256,
      downloadUrl: downloadUrl,
      browserUrl: browserUrl,
    );
  }
}

/// El manifiesto entero, tal como llega.
class ManifiestoApi {
  ManifiestoApi({required this.format, required this.version, required this.modules});

  final String format;
  final String version;

  /// Entradas que **no** se pudieron leer. Se guardan para poder decir "hay 2
  /// modulos y 1 entrada ilegible" en vez de fingir que no existen.
  ///
  /// Es mutable a proposito: se rellena al leer, y un `const` obligaria a montar
  /// el objeto entero antes de saber cuantas entradas habra.
  final List<String> ilegibles = <String>[];

  final List<ModuloCatalogo> modules;

  static ManifiestoApi? desdeJson(Map<String, dynamic> j) {
    final format = j['format'];
    final version = j['version'];
    final modules = j['modules'];
    if (format is! String || version is! String) return null;
    if (modules is! List) return null;

    final api = ManifiestoApi(format: format, version: version, modules: <ModuloCatalogo>[]);
    for (var i = 0; i < modules.length; i++) {
      final entrada = modules[i];
      if (entrada is! Map<String, dynamic>) {
        api.ilegibles.add('la entrada $i no es un objeto');
        continue;
      }
      final m = ModuloCatalogo.desdeJson(entrada);
      if (m == null) {
        api.ilegibles.add('la entrada $i (id: ${entrada['id'] ?? 'sin id'}) '
            'no tiene los campos obligatorios');
      } else {
        api.modules.add(m);
      }
    }
    return api;
  }
}

/// `latest.json`: el puntero flotante que dice que release esta vigente.
class UltimoJson {
  const UltimoJson({required this.tag, required this.url, required this.browserUrl, this.catalogSha256});

  /// `v0.1.1`.
  final String tag;

  /// Donde esta el manifiesto para clientes nativos.
  final String url;

  /// Donde esta el manifiesto para navegadores. Sin esto habria que bajar el
  /// manifiesto de la release, que no es legible desde un navegador.
  final String browserUrl;

  /// Hash del manifiesto. Se comprueba **antes** de usar su contenido.
  final String? catalogSha256;

  static UltimoJson? desdeJson(Map<String, dynamic> j) {
    final tag = j['tag'];
    final url = j['url'];
    final browserUrl = j['browserUrl'];
    final sha = j['catalogSha256'];
    if (tag is! String || tag.isEmpty) return null;
    if (url is! String || !url.startsWith('https://')) return null;
    if (browserUrl is! String || !browserUrl.startsWith('https://')) return null;
    if (sha != null && (sha is! String || sha.length != 64)) return null;
    return UltimoJson(tag: tag, url: url, browserUrl: browserUrl, catalogSha256: sha as String?);
  }
}
