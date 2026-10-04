// Peticiones por rango, contra un servidor DE VERDAD en local.
//
// No un mock: el fallo que importa en un rango es que el servidor no lo
// entienda, y un mock que hace lo que uno quiere no lo demuestra. El servidor de
// aqui es `HttpServer` de `dart:io`, que ademas puede contestar 200 con el
// fichero entero e ignorar el `Range`, que es lo que hacen algunos CDN.

import 'dart:io';
import 'dart:typed_data';

import 'package:ab/data/services/http_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un fichero de 1 MB con un patron reconocible, para comprobar que el rango
/// devuelve **esos** bytes y no otros.
Uint8List _payload(int n) => Uint8List.fromList(List<int>.generate(n, (i) => i % 251));

void main() {
  late HttpServer servidor;
  late HttpService http;
  late Uint8List contenido;
  // Un `Uri get url` dentro de main() no seria legal en Dart: los getters son
  // miembros de una clase. Por eso esto es una variable que se rellena en el
  // setUp, y no un atajo.
  late Uri url;
  int peticiones = 0;
  int ultimaDesde = -1;
  int ultimaHasta = -1;

  setUp(() async {
    peticiones = 0;
    ultimaDesde = -1;
    ultimaHasta = -1;
    contenido = _payload(1024 * 1024);
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((peticion) async {
      peticiones++;
      final rango = peticion.headers.value(HttpHeaders.rangeHeader);
      peticion.response.headers.set('Access-Control-Allow-Origin', '*');
      if (rango == null) {
        peticion.response.headers.contentLength = contenido.length;
        peticion.response.add(contenido);
        await peticion.response.close();
        return;
      }
      final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rango);
      if (m == null || int.parse(m.group(1)!) > int.parse(m.group(2)!)) {
        peticion.response.statusCode = HttpStatus.badRequest;
        await peticion.response.close();
        return;
      }
      final desde = int.parse(m.group(1)!);
      final hasta = int.parse(m.group(2)!);
      ultimaDesde = desde;
      ultimaHasta = hasta;
      final trozo = contenido.sublist(desde, hasta + 1);
      peticion.response.statusCode = 206;
      peticion.response.headers.set('Content-Range', 'bytes $desde-$hasta/${contenido.length}');
      peticion.response.headers.contentLength = trozo.length;
      peticion.response.add(trozo);
      await peticion.response.close();
    });
    http = HttpService();
    url = Uri.parse('http://127.0.0.1:${servidor.port}/modulo.amod');
  });

  tearDown(() async {
    http.cerrar();
    await servidor.close(force: true);
  });



  test('un rango bytes=0-1023 devuelve EXACTAMENTE 1024 bytes', () async {
    final r = await http.rango(url, 0, 1023);
    expect(r, isNotNull);
    expect(r!.codigo, 206);
    expect(r.cuerpo.length, 1024);
    expect(ultimaDesde, 0);
    expect(ultimaHasta, 1023);
  });

  test('los bytes del rango son los del fichero, byte a byte', () async {
    // Un rango que devolviera 1024 bytes equivocados daria un hash distinto y
    // un modulo que no cuadra. No basta con mirar la longitud.
    final r = (await http.rango(url, 500000, 500999))!;
    expect(r.cuerpo.length, 1000);
    for (var i = 0; i < 1000; i++) {
      expect(r.cuerpo[i], contenido[500000 + i], reason: 'byte $i del rango');
    }
  });

  test('la respuesta dice cuantos bytes tiene el fichero entero', () async {
    final r = (await http.rango(url, 0, 99))!;
    expect(r.rangoContenido, 'bytes 0-99/1048576');
    expect(r.totalEsperado, 1048576);
    expect(r.inicioRango, 0);
  });

  test('dos peticiones por rango van al sitio correcto', () async {
    await http.rango(url, 0, 1023);
    await http.rango(url, 1024, 2047);
    expect(peticiones, 2);
    expect(ultimaDesde, 1024);
  });

  test('un rango invertido no cuelga: contesta 400 y vuelve', () async {
    // Pasa si alguien calcula mal los limites. Un 400 es una respuesta; lo que
    // no vale es quedarse esperando.
    final r = await http.rango(url, 2047, 1024);
    expect(r, isNotNull);
    expect(r!.codigo, 400);
  });

  test('el cuerpo es Uint8List, no texto', () async {
    final r = (await http.rango(url, 0, 10))!;
    // Si esto se convirtiera a String con una codificacion cualquiera, un
    // `.amod` se corromperia al pasar por aqui.
    expect(r.cuerpo, isA<Uint8List>());
  });

  test('el servidor responde con su cabecera de origen cruzado', () async {
    final r = (await http.rango(url, 0, 9))!;
    expect(r.cabeceras['access-control-allow-origin'], '*');
    expect(r.ok, isTrue);
  });

  test('el manifiesto se pide entero, sin Range', () async {
    // El manifiesto son 1.468 bytes. Pedirlo por rango no tiene sentido.
    final r = (await http.entero(url))!;
    expect(r.codigo, 200);
    expect(r.cuerpo.length, contenido.length);
    expect(ultimaDesde, -1, reason: 'no se pidio ningun rango');
  });
}
