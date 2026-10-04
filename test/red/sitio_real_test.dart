@Tags(['red'])
library;

import 'dart:convert';

import 'package:ab/data/models/catalogo_api.dart';
import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/http_service.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/use_cases/obtener_modulo.dart';
import 'package:ab/domain/use_cases/resultado_obtencion.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRUEBAS CONTRA EL SITIO REAL. No son hermeticas y no se lanzan por defecto.
///
/// POR QUE ESTAN SEPARADAS. Todo lo demas del repositorio corre contra un
/// servidor de pruebas, que se puede apagar y al que se le puede cambiar lo que
/// sirve. Estas van contra `yojananyosef.github.io`, del que no se puede saber
/// nada. Si estuvieran en la suite normal:
/// - fallarian cuando falla Internet, y una suite que falla por eso se deja de
///   mirar entera, que es como se pierde una comprobacion que si importa;
/// -_when_mesen minutos cada vez, porque bajan ficheros de 22 y 57 MB.
///
/// COMO SE LANZAN. Hacen falta las dos banderas, porque el `skip` de
/// `dart_test.yaml` manda siempre:
///
///     flutter test --tags red --run-skipped
///
/// Y en CI corre en un paso aparte, porque **es la unica prueba de que este
/// change sirve de algo**. Todo lo demas demuestra que el codigo hace lo que
/// dice; esto demuestra que el sitio real responde.
///
/// QUE COMPRUEBA, Y POR QUE CADA COSA:
///
///  1. `browserUrl` baja el `.amod` y el sha256 **cuadra** con el del manifiesto.
///     Esta es la prueba de que la resolucion del problema de origen cruzado
///     sigue siendo valida hoy. Si alguien cambia el origen a la release de
///     GitHub, esta prueba es la que se entera, y no hay ninguna otra.
///
///  2. `downloadUrl` **no** deja leer desde un navegador. Se mide, no se supone:
///     se pide con la cabecera `Origin` de otro sitio y se mira si el servidor
///     contesta con permiso. La release de GitHub no manda
///     `Access-Control-Allow-Origin` en la respuesta final, y por eso da
///     `Failed to fetch` mientras compila y pasa todas las pruebas locales.
///
///  3. Las dos URLs de cada modulo llevan al **mismo fichero**, comparando el
///     ultimo segmento de la ruta. Si divergieran, un cliente que eligiera mal
///     bajaria algo que el gate del catalogo nunca vio ni verifico.

void main() {
  group('el sitio real', () {
    test('browserUrl baja el modulo y el sha256 cuadra con el del manifiesto', () async {
      final http = HttpService();
      final manifiesto = await _leerManifiesto(http);
      addTearDown(http.cerrar);

      expect(manifiesto.modulos, isNotEmpty,
          reason: 'si el catalogo esta vacio, esta prueba no comprueba nada');

      // Solo la primera Biblia: son 22 MB, y para demostrar que la via funciona no
      // hace falta bajarse tambien el comentario de 57 MB en cada ejecucion.
      final biblia = manifiesto.deTipo(TipoModulo.biblia).first;
      final obtener = ObtenerModulo(http: http, tamanoTrozo: 4 << 20);
      final eventos = <EventoObtencion>[];
      await for (final e in obtener.obtener(
        biblia,
        hashEsperado: biblia.sha256,
        usarUrlDeNavegador: true,
      )) {
        eventos.add(e);
      }

      final r = eventos.whereType<Terminada>().single.resultado;
      expect(r, isA<Obtenido>(), reason: descripcionDe(r));
      final obtenido = r as Obtenido;
      expect(obtenido.bytes.length, biblia.tamanoBytes);
      expect(sha256DeBytes(obtenido.bytes), biblia.sha256,
          reason: 'el hash de lo bajado tiene que ser el que declara el manifiesto');
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('downloadUrl NO deja leer desde un navegador, y se mide por que', () async {
      // Se pide UN byte, no el fichero entero: para ver si hay permiso no hace
      // falta bajar 22 MB, y asi la prueba tarda un segundo.
      final http = HttpService();
      final manifiesto = await _leerManifiesto(http);
      addTearDown(http.cerrar);

      final biblia = manifiesto.deTipo(TipoModulo.biblia).first;

      final conPermiso = await http.rango(biblia.urlDescarga, 0, 0);
      final sinPermiso = await http.rango(biblia.urlNavegador, 0, 0);

      // El de la release puede no responder siquiera, o responder sin permiso.
      // Lo que NO puede es dar permiso.
      if (conPermiso != null && conPermiso.codigo < 400) {
        expect(conPermiso.cabeceras.containsKey('access-control-allow-origin'), isFalse,
            reason: 'si la release llegara a mandar permiso, este repositorio puede '
                'usarla en el navegador y la resolucion de GitHub Pages queda obsoleta. '
                'Hay que volver a mirar el transporte antes de tocar nada.');
      }

      // Y el de Pages **si** tiene que darlo. Esta es la parte que sostiene todo.
      expect(sinPermiso, isNotNull);
      expect(sinPermiso!.codigo, lessThan(400));
      expect(sinPermiso.cabeceras['access-control-allow-origin'], '*');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('las dos URLs de cada modulo llevan al mismo fichero', () async {
      final http = HttpService();
      final manifiesto = await _leerManifiesto(http);
      addTearDown(http.cerrar);

      for (final m in manifiesto.modulos) {
        expect(
          m.urlNavegador.pathSegments.last,
          m.urlDescarga.pathSegments.last,
          reason: 'modulo ${m.id}: si divergen, el hash no cuadra en el cliente y '
              'no en el servidor, y no hay forma de saber cual de los dos fallo',
        );
        expect(m.urlNavegador.scheme, 'https');
        expect(m.urlDescarga.scheme, 'https');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('el manifiesto publicado se puede leer y su hash cuadra con el del indice', () async {
      final http = HttpService();
      addTearDown(http.cerrar);

      final indice = await http.entero(
        Uri.parse('https://yojananyosef.github.io/aa/latest.json'),
      );
      expect(indice, isNotNull);
      expect(indice!.ok, isTrue, reason: 'el indice esta caido o devuelve otra cosa');

      final u = UltimoJson.desdeJson(_json(indice.cuerpo))!;
      final manifiesto = await http.entero(Uri.parse(u.browserUrl));
      expect(manifiesto, isNotNull);
      expect(manifiesto!.ok, isTrue);
      expect(sha256DeBytes(manifiesto.cuerpo), u.catalogSha256,
          reason: 'el manifiesto publicado no es el que anuncia el indice');

      final api = ManifiestoApi.desdeJson(_json(manifiesto.cuerpo))!;
      expect(api.ilegibles, isEmpty, reason: 'el manifiesto publicado tiene que leerse entero');
      expect(api.modules, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

/// Lee el manifiesto publicado y lo pasa a dominio.
Future<ModuloLista> _leerManifiesto(HttpService http) async {
  final indice = await http.entero(
    Uri.parse('https://yojananyosef.github.io/aa/latest.json'),
  );
  if (indice == null || !indice.ok) {
    fail('el indice del catalogo no se ha podido leer. Si el sitio esta caido esto '
        'no es un fallo del repositorio, pero la prueba no puede seguir.');
  }
  final u = UltimoJson.desdeJson(_json(indice.cuerpo));
  if (u == null) fail('el indice no tiene la forma esperada: ${indice.cuerpo}');

  final manifiesto = await http.entero(Uri.parse(u.browserUrl));
  if (manifiesto == null || !manifiesto.ok) {
    fail('el manifiesto no se ha podido leer de ${u.browserUrl}');
  }
  return _aManifiesto(ManifiestoApi.desdeJson(_json(manifiesto.cuerpo))!);
}

/// El mapeo del manifiesto a dominio, aqui en vez de en el repositorio.
///
/// Y es a proposito que este duplicado: si se importara el del repositorio, esta
/// prueba comprobaria el repositorio contra si mismo. Que el mapeo este en dos
/// sitios es un coste de nueve lineas a cambio de que una prueba de la red pueda
/// ser independiente.
ModuloLista _aManifiesto(ManifiestoApi api) {
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
  return ModuloLista(modulos, api.format, api.version);
}

/// El JSON de una respuesta, con un mensaje util si no es un objeto.
Map<String, dynamic> _json(List<int> cuerpo) {
  final d = jsonDecode(utf8.decode(cuerpo));
  if (d is! Map<String, dynamic>) {
    throw FormatException('se esperaba un objeto JSON y ha llegado otra cosa');
  }
  return d;
}

class ModuloLista {
  const ModuloLista(this.modulos, this.formato, this.version);
  final List<Modulo> modulos;
  final String formato;
  final String version;

  List<Modulo> deTipo(TipoModulo t) => modulos.where((m) => m.tipo == t).toList();
}
