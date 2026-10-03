// El dominio del catalogo, contra el manifiesto REAL publicado.
//
// Fixture: `test/fixtures/catalog_real.json`, copiado de
// `https://yojananyosef.github.io/aa/catalog.json` el 3 de octubre de 2026.
//
// Por que un fixture y no la red en cada prueba: una prueba que depende de la
// red falla cuando falla Internet, y una suite que falla por eso se deja de
// mirar. El fixture se refresca a mano cuando el manifiesto cambia, y hay una
// prueba de red aparte para comprobar que el sitio real sigue siendo legible.

import 'dart:convert';
import 'dart:io';

import 'package:ab/data/models/catalogo_api.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/data/services/origen.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _leerFixture(String nombre) =>
    jsonDecode(File('test/fixtures/$nombre').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('origen', () {
    test('sale de una sola constante y no es la release', () {
      // Si esto cambia a la release, el navegador deja de poder descargar y no
      // hay ninguna prueba en el grupo de obtencion que lo detecte: las de ahi
      // usan un servidor local. Por eso se comprueba aqui, que es donde se
      // decide.
      expect(origenCatalogo, 'https://yojananyosef.github.io/aa');
      expect(origenCatalogo, isNot(contains('releases/download')),
          reason: 'la release no responde CORS y en navegador da Failed to fetch');
      expect(origenCatalogo.endsWith('/'), isFalse);
    });

    test('las URLs se derivan del origen', () {
      expect(urlUltimoJson.toString(), 'https://yojananyosef.github.io/aa/latest.json');
      expect(urlCatalogo('v0.1.1').toString(),
          'https://yojananyosef.github.io/aa/modulos/v0.1.1/catalog.json');
    });

    test('no hay ninguna direccion escrita a mano fuera de origen.dart', () {
      // Con el grep anclado a codigo: los comentarios si pueden mencionar
      // URLs, y de hecho deben, para explicar el porque.
      // Se exige al menos un caracter de host despues de "//", porque un
      // `https://` a secas es una COMPROBACION de esquema --"esta URL tiene que
      // ser https"-- y no una direccion escrita a mano. Confundir las dos
      // cosas haria que esta prueba diera falsas alarmas.
      final patron = '^[^/]*https?://[a-zA-Z0-9.-]';
      final r = Process.runSync('grep', ['-rnE', patron, 'lib/']);
      final lineas = (r.stdout as String).trim().split('\n').where((l) => l.isNotEmpty).toList();
      final fueraDeOrigen = lineas.where((l) => !l.startsWith('lib/data/services/origen.dart'));
      expect(fueraDeOrigen, isEmpty,
          reason: 'estas direcciones estan escritas a mano fuera de origen.dart:\n'
              '${fueraDeOrigen.join('\n')}');
    });
  });

  group('lectura del manifiesto real', () {
    test('se leen 2 modulos con los 12 campos obligatorios', () {
      final api = ManifiestoApi.desdeJson(_leerFixture('catalog_real.json'));
      expect(api, isNotNull);
      expect(api!.format, 'aa-catalog/1');
      expect(api.modules.length, 2);
      expect(api.ilegibles, isEmpty, reason: 'el manifiesto real tiene que leerse entero');
    });

    test('sizeBytes llega como entero y se ensena en megabytes con un decimal', () {
      final api = ManifiestoApi.desdeJson(_leerFixture('catalog_real.json'))!;
      final kjv = api.modules.firstWhere((m) => m.id == 'KJV2006');
      expect(kjv.sizeBytes, 22544384);
      expect(kjv.sizeBytes, isA<int>());
    });

    test('las dos URLs de cada modulo llevan al MISMO fichero', () {
      // Es la comprobacion que mas caro sale si falta: si divergen, un cliente
      // que elija la de navegador baja otra cosa que la que el gate verifico, y
      // el hash no cuadra en el sitio del cliente y no en el del servidor.
      final api = ManifiestoApi.desdeJson(_leerFixture('catalog_real.json'))!;
      for (final m in api.modules) {
        final deDescarga = Uri.parse(m.downloadUrl).pathSegments.last;
        final deNavegador = Uri.parse(m.browserUrl).pathSegments.last;
        expect(deNavegador, deDescarga, reason: 'modulo ${m.id}');
      }
    });

    test('el manifiesto mapea a dominio y se ven los megabytes', () {
      final api = ManifiestoApi.desdeJson(_leerFixture('catalog_real.json'))!;
      final m = Manifiesto(
        formato: api.format,
        version: api.version,
        etiqueta: 'v0.1.1',
        modulos: api.modules.map(_aModulo).toList(),
      );
      expect(m.total, 2);
      final kjv = m.porId('KJV2006')!;
      expect(kjv.megabytes, '21.5', reason: '22.544.384 bytes son 21,5 MB');
      expect(kjv.tipo, TipoModulo.biblia);
      expect(kjv.urlsCoincidenEnElFichero, isTrue);
      final clar = m.porId('CLARKE')!;
      expect(clar.tipo, TipoModulo.comentario);
      expect(clar.megabytes, '54.9', reason: '57.536.512 bytes son 54,9 MB');
      expect(m.deTipo(TipoModulo.biblia).length, 1);
      expect(m.deTipo(TipoModulo.comentario).length, 1);
      expect(m.idiomas, ['eng']);
    });
  });

  group('lectura de latest.json', () {
    test('trae etiqueta, las dos URLs y el hash', () {
      final u = UltimoJson.desdeJson(_leerFixture('latest_real.json'))!;
      expect(u.tag, 'v0.1.1');
      expect(u.url, contains('releases/download'));
      expect(u.browserUrl, contains('github.io'));
      expect(u.catalogSha256!.length, 64);
    });

    test('sin browserUrl se rechaza, porque en navegador no habria donde mirar', () {
      final j = _leerFixture('latest_real.json')..remove('browserUrl');
      expect(UltimoJson.desdeJson(j), isNull);
    });
  });

  group('una entrada mala no tumba el manifiesto entero', () {
    test('se lee el resto y se cuenta la ilegible', () {
      final j = _leerFixture('catalog_real.json');
      (j['modules'] as List).add(<String, dynamic>{'id': 'ROTO'});
      final api = ManifiestoApi.desdeJson(j)!;
      expect(api.modules.length, 2, reason: 'las dos buenas se siguen leyendo');
      expect(api.ilegibles.length, 1);
      expect(api.ilegibles.first, contains('ROTO'));
    });

    test('sizeBytes en texto en vez de numero se rechaza', () {
      final j = _leerFixture('catalog_real.json');
      (j['modules'] as List)[0]['sizeBytes'] = '22544384';
      final api = ManifiestoApi.desdeJson(j)!;
      expect(api.modules.length, 1);
      expect(api.ilegibles.length, 1);
    });

    test('una URL en http en vez de https se rechaza', () {
      final j = _leerFixture('catalog_real.json');
      (j['modules'] as List)[0]['browserUrl'] =
          (j['modules'] as List)[0]['browserUrl'].toString().replaceFirst('https', 'http');
      expect(ManifiestoApi.desdeJson(j)!.modules.length, 1);
    });
  });
}

/// El paso de "sucio" a "limpio". Vive aqui, y solo aqui, porque es el unico
/// sitio donde se decide que se hace con cada clave del manifiesto.
Modulo _aModulo(ModuloCatalogo m) {
  final tipo = TipoModulo.desdeCatalogo(m.type);
  if (tipo == null) {
    throw FormatException(
      'el manifiesto declara un tipo "${m.type}" que esta app no conoce. '
      'El catalogo puede ir por delante, pero entonces el gate deberia avisar.',
    );
  }
  return Modulo(
    id: m.id,
    nombre: m.name,
    tipo: tipo,
    idioma: m.language,
    licencia: m.license,
    tamanoBytes: m.sizeBytes,
    sha256: m.sha256,
    urlDescarga: Uri.parse(m.downloadUrl),
    urlNavegador: Uri.parse(m.browserUrl),
  );
}
