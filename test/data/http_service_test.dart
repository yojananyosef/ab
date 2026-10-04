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

  group('la compresion rompe los rangos, y por eso se pide identity', () {
    // Este grupo reproduce un fallo REAL, medido contra el sitio de verdad el 3 de
    // octubre de 2026. Sin esta prueba, el fallo solo se puede ver con Internet, y
    // las unicas pruebas que dependen de Internet son las que no se miran.
    late HttpServer compresor;
    late HttpService http2;

    // Un fichero de 1 MB muy comprimible: 1 MB de ceros se comprime a unos mil
    // bytes, que es donde se ve bien la diferencia entre los dos tamanos.
    late Uint8List crudo;
    late Uint8List comprimido;

    setUp(() async {
      crudo = Uint8List(1024 * 1024);
      // `gzip` de `dart:io`, que es compresion de verdad: un megas de ceros se
      // queda en unos mil bytes, que es justo la desproporcion que hace visible
      // el fallo. La primera version de esta prueba usaba bloques deflate
      // "almacenados" escritos a mano, que **no comprimen** --eso es lo que hace
      // un bloque almacenado-- y la asercion de que el comprimido sea mas
      // pequeno no se cumplia. Por eso aqui se comprime de verdad.
      comprimido = Uint8List.fromList(gzip.encode(crudo));
      compresor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      compresor.listen((p) async {
        p.response.headers.set('Access-Control-Allow-Origin', '*');
        final rango = p.headers.value(HttpHeaders.rangeHeader);
        if (rango == null) {
          p.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
          p.response.add(comprimido);
          await p.response.close();
          return;
        }
        // Como un servidor de verdad: decide segun lo que le hayan pedido en
        // `Accept-Encoding`, y si le piden `identity` sirve el rango sin comprimir.
        final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rango)!;
        final desde = int.parse(m.group(1)!);
        final hasta = int.parse(m.group(2)!);
        final quiereCrudo = p.headers.value(HttpHeaders.acceptEncodingHeader) == 'identity';

        final origen = quiereCrudo ? crudo : comprimido;
        if (desde >= origen.length) {
          p.response.statusCode = 416;
          p.response.headers.set('Content-Range', 'bytes */${origen.length}');
          await p.response.close();
          return;
        }
        final hr = hasta >= origen.length ? origen.length - 1 : hasta;
        final trozo = origen.sublist(desde, hr + 1);
        p.response.statusCode = 206;
        p.response.headers.set('Content-Range', 'bytes $desde-$hr/${origen.length}');
        if (!quiereCrudo) p.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        p.response.contentLength = trozo.length;
        p.response.add(trozo);
        await p.response.close();
      });
      http2 = HttpService();
    });

    tearDown(() async {
      http2.cerrar();
      await compresor.close(force: true);
    });

    // Una funcion y no un `Uri get urlCompresor`: los getters son miembros de una
    // clase, y esto esta dentro del cuerpo de un `group`, que es una funcion.
    Uri urlCompresor() => Uri.parse('http://127.0.0.1:${compresor.port}/modulo.amod');

    test('el comprimido es mucho mas pequeno, que es lo que hace visible el fallo', () {
      // Sin esta asercion, el resto del grupo pasaria tambien con un fichero
      // incompresible, y no probaria nada.
      // Medido: 1.048.576 bytes de ceros comprimen a 1.051. El margen es
      // amplio a proposito --lo que importa es la proporcion, no el numero--, pero
      // la cifra esta escrita para que si cambia se note.
      expect(comprimido.length, lessThan(2048));
      expect(crudo.length, 1048576);
      expect(comprimido.length * 100, lessThan(crudo.length),
          reason: 'el comprimido tiene que ser al menos cien veces mas pequeno');
    });

    test('con identity, el rango son los bytes del rango y del sitio correcto', () async {
      final r = (await http2.rango(urlCompresor(), 0, 1023))!;
      expect(r.codigo, 206);
      expect(r.cuerpo.length, 1024);
      expect(r.rangoContenido, 'bytes 0-1023/1048576');
      expect(r.totalEsperado, 1048576);
      for (var i = 0; i < 1024; i++) {
        expect(r.cuerpo[i], crudo[i], reason: 'byte $i');
      }
    });

    test('el total del Content-Range es el del FICHERO, no el del comprimido', () async {
      // Esta es la comprobacion que importa. Sin `identity`, el `Content-Range`
      // habla del fichero comprimido y el cuerpo llega descomprimido: los dos
      // numeros son de dos ficheros distintos, y el primero es el que se usa para
      // calcular el siguiente rango. Contra el sitio real eso fue: un rango de
      // 4 MiB devolvio 20.766.289 bytes, y el siguiente rango de 20.766.289 dio
      // 416. Con `identity`, los dos numeros son del mismo fichero.
      final r = (await http2.rango(urlCompresor(), 0, 4095))!;
      expect(r.totalEsperado, crudo.length);
      expect(r.cuerpo.length, 4096);
    });

    test('los tres tramos seguidos cubren el fichero entero sin solaparse', () async {
      // El recorrido completo, que es donde el fallo se manifestaba: el total
      // engañoso hacia que el siguiente rango se salia del fichero.
      var recibidos = 0;
      final listos = <int>[];
      while (recibidos < crudo.length) {
        final hasta = (recibidos + 300000) < crudo.length
            ? recibidos + 300000
            : crudo.length - 1;
        final r = (await http2.rango(urlCompresor(), recibidos, hasta))!;
        expect(r.codigo, 206, reason: 'tramo en $recibidos');
        listos.addAll(r.cuerpo);
        recibidos += r.cuerpo.length;
      }
      expect(recibidos, crudo.length);
      expect(listos.length, crudo.length);
      for (var i = 0; i < crudo.length; i += 977) {
        expect(listos[i], crudo[i], reason: 'byte $i');
      }
    });
  });
}
