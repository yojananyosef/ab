// Leer el manifiesto del catalogo, y saber si hay que leerlo.
//
// QUE HACE, EN ORDEN:
//
//  1. Baja `latest.json`, que dice que release esta vigente y donde esta el
//     manifiesto. Son 275 bytes.
//  2. Baja `catalog.json` de esa release.
//  3. **Comprueba el hash antes de usar su contenido.** Un manifiesto que no
//     cuadra no se lee: se dice el hash esperado y el obtenido.
//  4. Guarda una copia para poder trabajar sin conexion.
//
// Y ESTO ES LO IMPORTANTE: si algo falla, devuelve **el manifiesto guardado** en
// vez de un error. Porque el caso que se quiere evitar es el de MyBible del 25 de
// de agosto de 2024, en el que regenerar un JSON dejo a todo el mundo sin poder
// descargar nada y la respuesta de soporte fue "conecta un cable USB y borra
// `persisted_registry.json`". Un fallo del servidor **nunca** bloquea la app: lo
// unico que hace es decir que se esta usando una copia guardada.
//
// Si no hay copia guardada, entonces si es un error, y con reintentar.

import 'dart:convert';

import 'package:ab/data/models/catalogo_api.dart';
import 'package:ab/data/services/almacenamiento.dart';
import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/http_service.dart';
import 'package:ab/data/services/origen.dart';
import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';

/// Lo que devuelve la lectura del catalogo.
class ResultadoCatalogo {
  const ResultadoCatalogo({
    required this.manifiesto,
    required this.estado,
    this.avisos = const <String>[],
    this.hashEsperado,
    this.hashObtenido,
  });

  /// El manifiesto. **Nunca** es null, ni siquiera en el error: si no hay red y
  /// no hay copia guardada, se devuelve un manifiesto **vacio** y el estado
  /// dice `sinConexion`. Un null obligaria a que cada pantalla|birthcase el caso,
  /// y un caso que hay que|birthcase en todas partes es un caso mal resuelto.
  final Manifiesto manifiesto;

  /// Como ha ido la lectura.
  final EstadoLectura estado;

  /// Cosas que hay que contarle a la persona: "usando una copia guardada",
  /// "hay 1 entrada ilegible". Nunca es la unica forma de enterarse: tambien
  /// hay [estado].
  final List<String> avisos;

  /// Si hubo problema de hash, los dos. Se ensena porque el sintoma de un
  /// manifiesto alterado es "el modulo esta corrupto", y eso se dice mucho mejor
  /// con los dos hashes delante.
  final String? hashEsperado;
  final String? hashObtenido;
}

enum EstadoLectura {
  /// Se ha leido del servidor y el hash cuadra.
  delServidor,

  /// El servidor no ha llegado, pero hay copia guardada.
  deCopiaGuardada,

  /// No hay servidor **ni** copia. El manifiesto va vacio.
  sinConexion,

  /// El hash no cuadra. No se usa ese manifiesto.
  hashIncorrecto,

  /// Se ha bajado y el hash cuadra, pero el JSON no tiene la forma esperada.
  ilegible,
}

/// De donde se han sacado los modulos.
class CatalogoRepository {
  /// [origen] es de donde se lee el catalogo. Por defecto es el de
  /// `origen.dart`, y se puede pasar otro porque hay dos razones y las dos son
  /// buenas:
  ///
  /// - Las pruebas apuntan a un servidor local que se puede apagar a voluntad.
  ///   Con el origen fijo, una prueba de "y si no hay red" no se puede escribir.
  /// - Un espejo propio, si algum dia hace falta. Sin tocar el repositorio.
  CatalogoRepository({
    required this.http,
    required this.almacenamiento,
    String? origen,
  }) : origen = origen ?? origenCatalogo;

  final HttpService http;
  final Almacenamiento almacenamiento;

  /// Sin barra final, como el de `origen.dart`.
  final String origen;

  /// El puntero flotante de ESTE origen.
  Uri get urlUltimoJson => Uri.parse('$origen/latest.json');

  /// Cierra el cliente HTTP. Quien lo crea, lo cierra.
  void dispose() => http.cerrar();

  /// Lee el catalogo. No lanza: devuelve un [ResultadoCatalogo] con lo que haya
  /// podido, y el estado dice como ha ido.
  ///
  /// El orden es: servidor primero, copia guardada despues. Al reves, un fallo
  /// de red dejaria a la persona con una biblioteca vieja sin enterarse, y es
  /// mejor teachle lo de hoy aunque se haya quedado a medias.
  Future<ResultadoCatalogo> leer() async {
    final ultimo = await _bajarUltimoJson();
    // Se guarda **antes** de nada, incluso si el resultado va a ser un fallo: asi, si
    // se acaba usando la copia guardada, `_ultimo` es la que se esta ensenarndo y no
    // la de hace tres dias. Lo contrario seria que "Descargar" buscara un id que la
    // pantalla no esta mostrando.

    if (ultimo != null) {
      final delServidor = await _leerDelServidor(ultimo);
      if (delServidor.estado == EstadoLectura.delServidor) {
        _ultimo = delServidor.manifiesto;
        await _guardar(ultimo);
        return delServidor;
      }
      // El servidor no sirvio. Se cae a la copia guardada, que puede ser de otra
      // release y aun asi es mejor que una biblioteca vacia. Se cuentan los dos
      // hashes si los habia, porque el sintoma de un manifiesto alterado es "el
      // modulo esta corrupto" y se dice mucho mejor con los dos delante.
      final guardado = await _leerGuardado();
      if (guardado != null) {
        _ultimo = guardado.manifiesto;
        return ResultadoCatalogo(
          manifiesto: guardado.manifiesto,
          estado: EstadoLectura.deCopiaGuardada,
          avisos: [
            ...delServidor.avisos,
            'Se ensena una copia guardada del catalogo ${guardado.etiqueta}.',
          ],
          hashEsperado: delServidor.hashEsperado,
          hashObtenido: delServidor.hashObtenido,
        );
      }
      return delServidor;
    }

    // No hay ni puntero flotante ni manifiesto: o no hay red, o el indice no se
    // pudo leer.
    final guardado = await _leerGuardado();
    if (guardado != null) {
      _ultimo = guardado.manifiesto;
      return ResultadoCatalogo(
        manifiesto: guardado.manifiesto,
        estado: EstadoLectura.deCopiaGuardada,
        avisos: ['No se ha podido contactar con el catalogo. '
            'Se ensena una copia guardada del ${guardado.etiqueta}.'],
      );
    }
    return ResultadoCatalogo(
      manifiesto: _manifiestoVacio('desconocida'),
      estado: EstadoLectura.sinConexion,
      avisos: ['No se ha podido contactar con el catalogo.'],
    );
  }

  /// El ultimo manifiesto que se ha leido, en memoria.
  ///
  /// NO esta persistido y no se guarda en ninguna parte: se vuelve a poner en cada
  /// [leer]. Vive aqui para que quien pulse "Descargar" sepa **que** modulo es sin
  /// tener que pasarselo otra vez, y no como una copia que se pueda quedar vieja.
  Manifiesto _ultimo = const Manifiesto(
    formato: 'aa-catalog/1',
    version: 'sin leer',
    etiqueta: 'sin leer',
    modulos: <Modulo>[],
  );

  Manifiesto get manifiesto => _ultimo;

  /// Si hay una copia guardada, sin tocar la red. Para el arranque, que no
  /// puede esperar a una peticion.
  Future<Manifiesto?> guardado() async => (await _leerGuardado())?.manifiesto;


  // --- privados ---

  Future<UltimoJson?> _bajarUltimoJson() async {
    final r = await http.entero(urlUltimoJson);
    if (r == null || !r.ok || r.cuerpo.isEmpty) return null;
    try {
      return UltimoJson.desdeJson(jsonDecode(utf8.decode(r.cuerpo)) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Baja y comprueba el manifiesto de una release. **Siempre** devuelve un
  /// resultado: nunca null, para que quien llama no tenga que distinguir "no hay
  /// resultado" de "el resultado es que no hay red".
  Future<ResultadoCatalogo> _leerDelServidor(UltimoJson ultimo) async {
    final r = await http.entero(Uri.parse(ultimo.browserUrl));
    if (r == null || !r.ok) {
      return ResultadoCatalogo(
        manifiesto: _manifiestoVacio(ultimo.tag),
        estado: EstadoLectura.sinConexion,
        avisos: ['No se ha podido descargar el catalogo ${ultimo.tag}.'],
      );
    }

    final obtenido = sha256DeBytes(r.cuerpo);
    // Si el indice no declara hash, no se comprueba: no hay contra que comparar.
    // El indice **si** lo declara, y ese es el punto de el.
    if (ultimo.catalogSha256 != null && !mismoHash(ultimo.catalogSha256, obtenido)) {
      // NO se usa el contenido. Un manifiesto que no cuadra podria declarar un
      // sha256 equivocado para un modulo, y entonces se bajaria un fichero que
      // el gate del catalogo nunca vio ni verifico.
      return ResultadoCatalogo(
        manifiesto: _manifiestoVacio(ultimo.tag),
        estado: EstadoLectura.hashIncorrecto,
        avisos: ['El catalogo descargado no es el que anuncia el indice.'],
        hashEsperado: ultimo.catalogSha256,
        hashObtenido: obtenido,
      );
    }

    final api = _parsear(r.cuerpo);
    if (api == null) {
      return ResultadoCatalogo(
        manifiesto: _manifiestoVacio(ultimo.tag),
        estado: EstadoLectura.ilegible,
        avisos: ['El catalogo ${ultimo.tag} no se ha podido interpretar.'],
        hashEsperado: ultimo.catalogSha256,
        hashObtenido: obtenido,
      );
    }

    return ResultadoCatalogo(
      manifiesto: _aManifiesto(api),
      estado: EstadoLectura.delServidor,
      avisos: [
        if (api.ilegibles.isNotEmpty)
          'Hay ${api.ilegibles.length} entrada(s) del catalogo que no se han podido leer.',
      ],
      hashEsperado: ultimo.catalogSha256,
      hashObtenido: obtenido,
    );
  }

  /// Convierte los datos del manifiesto en dominio.
  ///
  /// Un `type` desconocido se salta sin tirar el manifiesto entero: el catalogo
  /// puede llevar cosas que esta app todavia no sabe leer, y es mejor ensenarr las
  /// que si entiende que ensenar una biblioteca vacia.
  Manifiesto _aManifiesto(ManifiestoApi api) {
    final modulos = <Modulo>[];
    for (final m in api.modules) {
      final tipo = TipoModulo.desdeCatalogo(m.type);
      if (tipo == null) continue;
      modulos.add(Modulo(
        id: m.id,
        nombre: m.name,
        tipo: tipo,
        idioma: m.language,
        licencia: m.license,
        tamanoBytes: m.sizeBytes,
        sha256: m.sha256,
        urlDescarga: Uri.parse(m.downloadUrl),
        urlNavegador: Uri.parse(m.browserUrl),
      ));
    }
    return Manifiesto(
      formato: api.format,
      version: api.version,
      etiqueta: api.version,
      modulos: modulos,
    );
  }

  ManifiestoApi? _parsear(List<int> cuerpo) {
    try {
      return ManifiestoApi.desdeJson(jsonDecode(utf8.decode(cuerpo)) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      // El JSON es valido pero no tiene la forma: `modules` es un numero, o
      // falta. Es un manifiesto ilegible, no una excepcion que propagar.
      return null;
    }
  }

  Future<void> _guardar(UltimoJson ultimo) async {
    final r = await http.entero(Uri.parse(ultimo.browserUrl));
    if (r == null || !r.ok) return;
    await almacenamiento.escribir(claveManifiestoGuardado, utf8.decode(r.cuerpo));
    await almacenamiento.escribir(claveEtiquetaGuardada, ultimo.tag);
  }

  Future<_Guardado?> _leerGuardado() async {
    final texto = await almacenamiento.leer(claveManifiestoGuardado);
    final etiqueta = await almacenamiento.leer(claveEtiquetaGuardada);
    if (texto == null) return null;
    final api = _parsear(utf8.encode(texto));
    if (api == null) return null;
    return _Guardado(manifiesto: _aManifiesto(api), etiqueta: etiqueta ?? api.version);
  }

  static Manifiesto _manifiestoVacio(String etiqueta) => Manifiesto(
    formato: 'aa-catalog/1',
    version: etiqueta,
    etiqueta: etiqueta,
    modulos: const <Modulo>[],
  );

  /// Los estados de cada modulo, calculados a partir del manifiesto y de lo que
  /// hay en el dispositivo.
  ///
  /// [descargados] es lo que la app tiene: id -> hash guardado. **No** se guarda
  /// aqui ningun estado: se calcula cada vez, que es lo que evita que se quede
  /// viejo.
  Map<String, EstadoModulo> estadosDe(Manifiesto manifiesto, Map<String, String> descargados) {
    final salida = <String, EstadoModulo>{};
    for (final m in manifiesto.modulos) {
      salida[m.id] = calcularEstado(
        sha256DelCatalogo: m.sha256,
        enDispositivo: descargados.containsKey(m.id)
            ? EstadoEnDispositivo.presente(descargados[m.id])
            : const EstadoEnDispositivo.ausente(),
        descargando: false,
        estaEnElCatalogo: true,
      );
    }
    return salida;
  }
}

class _Guardado {
  const _Guardado({required this.manifiesto, required this.etiqueta});
  final Manifiesto manifiesto;
  final String etiqueta;
}
