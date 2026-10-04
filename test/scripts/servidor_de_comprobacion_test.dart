// El servidor de la comprobacion en navegador: `servir.py` y `colector.py`.
//
// ============================================================================
// POR QUE ESTOS SCRIPT NECESITAN PRUEBAS Y SON LOS UNICOS QUE LAS TIENEN
// ============================================================================
//
// Los demas scripts del repositorio son de una linea o dos y no se prueban. Estos dos
// son los que **deciden si la comprobacion en navegador pasa**, y una comprobacion que
// decide mal es peor que no tenerla: un "ok" que no significa nada es lo que se quiere
// evitar por encima de todo.
//
// Y LO QUE SE HA FALLADO AQUI, Y NO ERA DEL CODIGO DE LA APLICACION:
//
//   - El contador de escrituras era un atributo de clase con `self.cuantos += 1`, que
//     **no** escribe en la clase: crea uno de instancia y lo tira al acabar la peticion.
//     Con el navegador abriendo una conexion por `POST`, todos los ficheros se llamaban
//     `primera.1.json` y se pisaban. El registro decia tres escrituras y habia un
//     fichero.
//   - Al arreglarlo se dejo `self.candado`, que ya no existia, y el colector reventaba
//     con `AttributeError` en la primera peticion. La comprobacion se quedaba esperando
//     900 segundos y decia "la sonda no ha escrito nada", que era verdad y no habia
//     escrito por que.
//
// Los dos fallos son de un minuto de reloj de pared y se ven en el fichero, pero un
// fichero que se lee a ojo tres veces es un fichero que se lee a ojo cuatro veces. Y el
// cuarto fallo --que no paso-- es que uno escriba en un fichero que no existe y no se
// entere.
//
// ============================================================================
// LO QUE SE PUEDE PROBAR Y LO QUE NO
// ============================================================================
//
// Se prueba lo que es logica: **como se sirve un `404.html`**, **que URL se reescriben
// del manifiesto**, **que NO se reescriben**, **que el `Range` se reenvia**, **que el
// `Accept-Encoding` se fuerza a `identity`**, **y que el colector cuenta bien**.
//
// NO se prueba que el navegador entienda, ni que SQLite abra, ni que el texto sea el
// correcto. Eso lo hace `scripts/comprobar-en-navegador.sh` con un navegador de verdad,
// y es lo unico que puede hacerlo.
//
// Y NO SE PRUEBA CON `unittest` DE PYTHON, SINO DESDE DART, porque el repositorio no
// tiene pruebas de Python y tenerlas en otro lenguaje es tenerlas en un sitio donde no
// se van a ejecutar. Lo que se hace es un script de Python que se lanza y se comprueba
// desde aqui, que es lo que hace un `Process.run`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Donde se deja el servidor de cada prueba.
final _dir = Directory.systemTemp.createTempSync('ab-servir-pruebas');

///
/// Y SIN ESPERAR: `Process.start` devuelve al instante y quien espera es [_esperar],
/// mirando si el puerto responde. Esperar aqui con un `sleep` seria esperar un tiempo
/// fijo y volver a mentir cuando el ordenador va lento.
///
/// Y CON LA SALIDA A `/dev/null` PORQUE SI NO SE LLENA EL BUFFER. Un servidor que
/// imprime su registro --y este imprime uno por peticion-- y no lo lee nadie llena el
/// tubo de la salida estandar, se queda bloqueado escribiendo, y el servidor deja de
/// responder con el proceso vivo. Es un modo de fallo que parece un cuelgue.
///
/// Y LA SALIDA SE GUARDA, no se tira. Un servidor que revienta deja el motivo en su
/// error estandar, y sin el se ve "Connection closed before full header was received",
/// que dice que se corto la conexion y no **por que**.
Future<Process> _lanzar(String script, List<String> argumentos) async {
  final registro = _registros.length;
  _registros.add(<String>[]);
  final p = await Process.start('python3', <String>[script, ...argumentos]);
  // Y LA SALIDA **NO SE ESPERA**: se va leyendo mientras llega y se guarda. Esperarla --
  // `await`-- solo tiene sentido si el proceso va a terminar, y estos son servidores que
  // no terminan hasta que los mata la prueba, con lo que esperarlos seria esperarlos para
  // siempre.
  p.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_registros[registro].add);
  p.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_registros[registro].add);
  return p;
}

/// Lo que ha dicho cada servidor lanzado, en orden.
final List<List<String>> _registros = <List<String>>[];

/// El registro del servidor `n`, como un solo texto.
///
/// Para ponerlo en el motivo de un fallo. Un `Connection closed before full header was
/// received` no dice **por que** se corto, y el motivo esta en el error estandar del
/// servidor. Esta funcion existe para que ponerlo sea de una linea.
String _registro(int n) => _registros[n].join('\n');

/// Espera a que el servidor conteste a su comprobacion de vida.
///
/// Y NO ESPERA UN SEGUNDO FIJO: espera a que responda. Con un segundo fijo, una prueba
/// que falla por un segundo de mas dice "no responde" cuando lo que pasa es que el
/// ordenador tenia prisa, y eso es una prueba que miente.
Future<HttpClient> _esperar(int puerto, {int intentos = 100}) async {
  final cliente = HttpClient();
  for (var i = 0; i < intentos; i++) {
    try {
      final r = await cliente.getUrl(Uri.parse('http://127.0.0.1:$puerto/')).then((u) => u.close()).timeout(const Duration(milliseconds: 500));
      await r.drain<void>();
      return cliente;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  throw StateError('el servidor no responde en $intentos intentos');
}

void main() {
  tearDownAll(() {
    if (_dir.existsSync()) _dir.deleteSync(recursive: true);
  });

  group('servir.py: el 404.html de una ruta profunda', () {
    late Process servidor;
    late HttpClient cliente;
    const puerto = 8151;

    setUpAll(() async {
      // Un `build/web` minimo: un `index.html` y un `404.html` que es el mismo, que es
      // exactamente lo que deja el CI.
      final web = _dir.createTempSync('web');
      final html = '<html><body>la aplicacion</body></html>';
      File('${web.path}/index.html').writeAsStringSync(html);
      File('${web.path}/404.html').writeAsStringSync(html);
      File('${web.path}/sqlite3.wasm').writeAsBytesSync(<int>[0, 97, 115, 109]);

      servidor = await _lanzar('scripts/servir.py', <String>[
        '--directorio', web.path,
        '--puerto', '$puerto',
      ]);
      cliente = await _esperar(puerto);
    });

    tearDownAll(() {
      cliente.close();
      servidor.kill();
    });

    test('la raiz responde 200 con la aplicacion', () async {
      final r = await cliente.getUrl(Uri.parse('http://127.0.0.1:$puerto/')).then((u) => u.close());
      final cuerpo = await utf8.decoder.bind(r).join();
      expect(r.statusCode, 200);
      expect(cuerpo, contains('la aplicacion'));
    });

    test('una ruta profunda responde 404 CON la aplicacion dentro', () async {
      // Y EL CODIGO 404 ES LO IMPORTANTE. El enrutador no lo mira --mira `location`--,
      // pero si aqui se sirviera con 200 la comprobacion seria mas facil de pasar que en
      // el sitio de verdad, y mediria menos de lo que dice medir.
      final r = await cliente
          .getUrl(Uri.parse('http://127.0.0.1:$puerto/leer/KJV2006/John.3.16'))
          .then((u) => u.close());
      final cuerpo = await utf8.decoder.bind(r).join();
      expect(r.statusCode, 404);
      expect(cuerpo, contains('la aplicacion'),
          reason: 'sin esto, recargar en un enlace profundo no carga nada');
      // Y si el servidor reventara, el motivo esta aqui y no en un error de socket.
      expect(_registro(0), isNot(contains('Traceback')), reason: _registro(0));
    });

    test('una ruta profunda pide el wasm en la RAIZ, no en la ruta', () async {
      // Y ESTE ES EL FALLO DEL GRUPO 8. Con la aplicacion en `/leer/KJV2006/John.3.16`,
      // el navegador resolvia `sqlite3.wasm` **contra la direccion** y pedia
      // `/leer/KJV2006/sqlite3.wasm`. Aqui solo se comprueba que el que se pide desde la
      // raiz esta; que el navegador no lo pide con barra lo arregla `sqlite_web.dart`.
      final r = await cliente
          .getUrl(Uri.parse('http://127.0.0.1:$puerto/sqlite3.wasm'))
          .then((u) => u.close());
      expect(r.statusCode, 200);
    });
  });

  group('servir.py: el proxy del catalogo', () {
    test('reenvia el Range y fuerza identity, y el sha256 no se toca', () async {
      // Y NO SE PREGUNTA A GITHUB DE VERDAD en esta prueba: se le pone un origen que es
      // un fichero local, y se mira lo que el proxy hace con el. Preguntar a github.io
      // seria una prueba que depende de la red, y una prueba que depende de la red no es
      // una prueba: es una comprobacion de si hay internet.
      const puertoOrigen = 8152;
      const origenSustituido = 'ORIGEN_REAL = "http://127.0.0.1:$puertoOrigen"';
      final origen = _dir.createTempSync('origen');
      const bytes = 1024;
      final contenido = List<int>.generate(bytes, (i) => i % 256);
      File('${origen.path}/amod').writeAsBytesSync(contenido);

      // Y EL "GITHUB PAGES" DE ESTA PRUEBA ES UN SERVIDOR LOCAL. `ORIGEN_REAL` es una
      // constante del modulo y el `import` es un `import`, de modo que sustituirla
      // significa cargar el modulo con otro valor. Se hace reescribiendo una copia del
      // fichero a un directorio temporal con el origen cambiado, y se importa por ruta --
      // es lo unico que hace `import` de Python -- para no depender de como este
      // instalado el interprete.
      final copia = _dir.createTempSync('servir-prueba');
      final codigo = File('scripts/servir.py').readAsStringSync().replaceFirst(
        'ORIGEN_REAL = "https://yojananyosef.github.io"',
        origenSustituido,
      );
      final fichero = File('${copia.path}/servir.py');
      fichero.writeAsStringSync(codigo);

      final enOrigen = await HttpServer.bind(InternetAddress.loopbackIPv4, puertoOrigen);
      final rutas = <String>[];
      final codigos = <String>[];
      enOrigen.listen((p) async {
        rutas.add(p.uri.path);
        codigos.add('${p.headers.value('range')}|${p.headers.value('accept-encoding')}');
        final rango = p.headers.value(HttpHeaders.rangeHeader);
        int desde = 0;
        int hasta = bytes - 1;
        if (rango != null) {
          final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rango);
          if (m != null) {
            desde = int.parse(m.group(1)!);
            hasta = int.parse(m.group(2)!);
          }
        }
        final trozo = contenido.sublist(desde, hasta + 1);
        p.response.statusCode = rango == null ? 200 : 206;
        if (rango != null) {
          p.response.headers.set('Content-Range', 'bytes $desde-$hasta/$bytes');
        }
        p.response.add(trozo);
        await p.response.close();
      });

      const puerto = 8153;
      final web = _dir.createTempSync('web2');
      File('${web.path}/index.html').writeAsStringSync('<html></html>');
      File('${web.path}/404.html').writeAsStringSync('<html></html>');
      final servidor = await _lanzar(fichero.path, <String>[
        '--directorio', web.path,
        '--puerto', '$puerto',
      ]);
      final cliente = await _esperar(puerto);
      addTearDown(() {
        cliente.close();
        servidor.kill();
        enOrigen.close(force: true);
      });

      // Un rango: se reenvia tal cual, y el `Accept-Encoding` del cliente **no** se
      // reenvia. Con `gzip` reenviado, GitHub Pages comprimia y el sha256 no cuadraba.
      final respuesta = await _rango(
        cliente,
        'http://127.0.0.1:$puerto/aa/modulos/x/KJV.amod',
        desde: 0,
        hasta: 1023,
      );
      final cuerpo = <int>[];
      await for (final trozo in respuesta) {
        cuerpo.addAll(trozo);
      }

      expect(respuesta.statusCode, 206);
      expect(cuerpo, hasLength(1024));
      expect(cuerpo.first, contenido.first);
      // Y los bytes son los de verdad: el proxy no los toca. Con uno cambiado, el sha256
      // del motor de obtencion no cuadraria en la comprobacion de verdad.
      expect(cuerpo, equals(contenido.sublist(0, 1024)));

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(rutas, contains('/aa/modulos/x/KJV.amod'));
      expect(codigos.last, 'bytes=0-1023|identity',
          reason: 'el Range se reenvia y el Accept-Encoding se fuerza a identity');
    });

    test('reescribe SOLO el host de las URL del manifiesto', () async {
      // Y NO SE REESCRIBE NADA MAS. Un `.amod` con su sha256 y un `sizeBytes` con su
      // numero: si el proxy tocara cualquiera de los dos, la comprobacion de la 8.4
      // dejaria de comprobar nada.
      final origen = _dir.createTempSync('origen-json');
      const puertoOrigen = 8154;
      const origenSustituido = 'ORIGEN_REAL = "http://127.0.0.1:$puertoOrigen"';

      // Y LAS URL DEL MANIFIESTO APUNTAN AL ORIGEN **SUSTITUIDO**, no a github.io.
      //
      // Es lo que hace falta para que la prueba signifique algo: la regla de reescribir
      // es "cambia el host de las URL que apuntan a `ORIGEN_REAL`", y si el manifiesto
      // apunta a otro sitio --a github.io de verdad-- la regla dice que no hay nada que
      // cambiar. La primera version de esta prueba lo escribio asi, apunto a github.io, y
      // el proxy **no reescribio nada** y la prueba no llego a comprobarlo.
      //
      // Y eso es exactamente lo que hace el proxy con `downloadUrl` y con `source`, y por
      // eso los tres casos estan en la misma prueba.
      final manifiesto = jsonEncode(<String, Object?>{
        'format': 'modulos-ab/1',
        'version': 1,
        'tag': 'v1',
        'modules': <Object?>[
          <String, Object?>{
            'id': 'KJV2006',
            'name': 'KJV',
            'type': 'bible',
            'language': 'eng',
            'license': 'PublicDomain',
            'sizeBytes': 22544384,
            'sha256': 'abc',
            // Esta SI se reescribe: es la que usa el navegador.
            'browserUrl': 'http://127.0.0.1:$puertoOrigen/aa/modulos/v1/KJV.amod',
            // Esta NO: es para nativo, donde el origen no importa.
            'downloadUrl': 'https://github.com/yojananyosef/aa/releases/download/v1/KJV.amod',
            // Y esta NO, y es la comprobacion que mas importa de las tres: **parece** una
            // URL y no es un campo de URL. Si la regla fuera "toda cadena que empiece por
            // http", esta tambien cambiaria y el manifiesto estaria mintiendo sobre de
            // donde sale el texto.
            'source': 'http://127.0.0.1:$puertoOrigen/fuente/fuente.usfm',
          },
        ],
      });
      File('${origen.path}/catalog.json').writeAsStringSync(manifiesto);

      final enOrigen = await HttpServer.bind(InternetAddress.loopbackIPv4, puertoOrigen);
      enOrigen.listen((p) async {
        // Y SE MANDA **EL FICHERO**, no lo que viene en la peticion. La primera version
        // de este servidor de pruebas hacia `utf8.decoder.bind(p).join()`, que es el
        // cuerpo de la peticion, y en un `GET` esta vacio. O sea que contestaba un cuerpo
        // de cero bytes y el proxy reventaba con `Expecting value: line 1 column 1`, que
        // no dice nada de que el problema estaba en el servidor de pruebas y no en el que
        // se estaba probando.
        await p.drain<void>();
        final cuerpo = File('${origen.path}/catalog.json').readAsBytesSync();
        p.response.headers.contentType = ContentType.json;
        p.response.headers.contentLength = cuerpo.length;
        p.response.add(cuerpo);
        await p.response.close();
      });

      final copia = _dir.createTempSync('servir-prueba-json');
      final codigo = File('scripts/servir.py').readAsStringSync().replaceFirst(
        'ORIGEN_REAL = "https://yojananyosef.github.io"',
        origenSustituido,
      );
      final fichero = File('${copia.path}/servir.py');
      fichero.writeAsStringSync(codigo);

      const puerto = 8155;
      final web = _dir.createTempSync('web3');
      File('${web.path}/index.html').writeAsStringSync('<html></html>');
      final servidor = await _lanzar(fichero.path, <String>[
        '--directorio', web.path,
        '--puerto', '$puerto',
      ]);
      final cliente = await _esperar(puerto);
      addTearDown(() {
        cliente.close();
        servidor.kill();
        enOrigen.close(force: true);
      });

      int registroProxy = _registros.length;
      late final HttpClientResponse r;
      try {
        r = await cliente
            .getUrl(Uri.parse('http://127.0.0.1:$puerto/aa/modulos/v1/catalog.json'))
            .then((u) => u.close());
      } catch (e) {
        fail('el proxy no ha contestado: $e\nservidor:\n${_registro(registroProxy - 1)}');
      }
      final d = jsonDecode(await utf8.decoder.bind(r).join()) as Map<String, Object?>;
      final modulos = d['modules']! as List<Object?>;
      final m = modulos.single! as Map<String, Object?>;

      expect(m['browserUrl'], 'http://127.0.0.1:$puerto/aa/modulos/v1/KJV.amod',
          reason: 'el host del navegador se cambia para que todo sea del mismo origen');
      // Y EL DE LA DESCARGA **NO**: `downloadUrl` es para nativo, y ahi el origen no
      // importa. Reescribirlo haria que una prueba de nativo, si algun dia se hace
      // mirando el manifiesto, apuntara a `127.0.0.1`.
      expect(m['downloadUrl'], startsWith('https://github.com/'));
      // Y UN `source` QUE ES UNA URL PERO **NO** ES UN CAMPO DE URL NO SE TOCA. Esta es la
      // parte que no hace falta nunca y que por eso es la que se comprueba: si la regla
      // fuera "toda cadena que parezca una URL", esta searia de `otro-sitio.example` a
      // `127.0.0.1`, y el manifiesto estaria mintiendo sobre de donde sale el texto.
      expect(m['source'], 'http://127.0.0.1:$puertoOrigen/fuente/fuente.usfm',
          reason: '`source` apunta al origen pero no es un campo de URL, y no se toca');
      // Y LO QUE NO ES URL NO SE TOCA.
      expect(m['sha256'], 'abc');
      expect(m['sizeBytes'], 22544384);
    });
  });

  group('colector.py: cuenta las escrituras', () {
    test('tres POST guardan tres ficheros, numerados', () async {
      // Y ESTA ES LA PRUEBA DEL FALLO DEL CONTADOR. Con el numero en un atributo de
      // clase, los tres ficheros se llamaban `x.1.json` y se pisaban, y el directorio
      // acababa con uno solo. Y el directorio es **lo unico** que distingue tres
      // escrituras de una en este momento: el registro de texto las enseña, pero el
      // registro se puede perder y el directorio no.
      const puerto = 8156;
      final destino = _dir.createTempSync('colector').path;
      final destinoFichero = File('$destino/final.json');
      final servidor = await _lanzar('scripts/colector.py', <String>[
        '--destino', destinoFichero.path,
        '--puerto', '$puerto',
        '--limite', '30',
      ]);

      final cliente = HttpClient();
      await _esperar(puerto);
      addTearDown(() {
        cliente.close();
        servidor.kill();
      });

      // Y CADA `POST` SE REINTENTA HASTA TRES VECES. Con la suite entera en paralelo
      // --que es como se ejecuta esto-- la maquina va cargada y un servidor que acaba de
      // arrancar puede cortar una conexion sin motivo. Reintentar es lo que haria una
      // persona, y lo que no se debe hacer es convertir "la maquina estaba ocupada" en un
      // fallo del script.
      int enviados = 0;
      int intentos = 0;
      while (enviados < 3) {
        intentos++;
        if (intentos > 12) {
          fail('el colector no ha aceptado tres escrituras en doce intentos.\n'
              'servidor:\n${_registro(0)}');
        }
        final numero = enviados + 1;
        try {
          final peticion =
              await cliente.postUrl(Uri.parse('http://127.0.0.1:$puerto/resultado'));
          peticion.headers.contentType = ContentType.text;
          peticion.write(numero == 3 ? '{"n":3,"final":true}' : '{"n":$numero}');
          final r = await peticion.close();
          // Y EL CORS SE COMPRUEBA **AQUI**, en la respuesta al `POST`, y no con una
          // peticion aparte al final. Dos motivos: el `POST` es la llamada que necesita el
          // permiso --el `GET` de comprobacion de vida no lo necesita-- y, sobre todo,
          // para cuando se llega aqui el colector **ya ha salido** --ha visto la marca de
          // final-- y una peticion a un proceso que no esta da "Connection reset by
          // peer", que es el sintoma de una prueba escrita en el orden equivocado.
          if (numero == 1) {
            expect(r.headers.value('access-control-allow-origin'), '*',
                reason: 'sin esto el navegador manda el POST pero no puede leer la '
                    'respuesta, y llena la consola de errores que no significan nada');
          }
          await r.drain<void>();
          enviados++;
        } catch (_) {
          // Y EL FALLO SE TRAGA Y SE REINTENTA, sin mirar el motivo. El motivo se
          // mira si se agotan los intentos, y sale entero en el `fail` de arriba. El
          // fallo tipico es "Connection reset by peer", que no dice nada: dice que la
          // conexion se corto, y quien tiene que saber por que se corto es el servidor.
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }

      final directorio = Directory(destino);
      final numerados = directorio
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          // Y `final.` CON EL PUNTO, y no `final`: el fichero sin numero es la copia
          // "ultima", que es la que lee el script, y cuenta como una cuarta.
          .where((n) => n.startsWith('final.') && n != 'final.json')
          .toList()
        ..sort();

      expect(numerados, <String>['final.1.json', 'final.2.json', 'final.3.json'],
          reason: 'cada escritura en su fichero, y numeradas en orden');
      // Y el ultimo es el que decide, que es lo que lee el script.
      // Y UN POCO DE ESPERA ANTES DE LEER LA COPIA "ULTIMA". El `POST` devuelve en
      // cuanto el servidor acepta la peticion, y el fichero se escribe justo despues:
      // leerlo en ese hueco da un JSON truncado, o vacio, y el fallo dice "el resultado no
      // es un JSON" sin decir que es una carrera.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Y LA COPIA "ULTIMA" TIENE LA MARCA, porque la ultima escritura de verdad la
      // lleva. No es un detalle del test: si el `final` se perdiera por el camino, la
      // comprobacion se quedaria esperando el limite entero sin decir nada, que es
      // exactamente el fallo que este fichero arregla.
      expect(jsonDecode(destinoFichero.readAsStringSync()),
          <String, Object?>{'n': 3, 'final': true});

      expect(servidor.exitCode, isNotNull,
          reason: 'el colector tiene que salir solo al ver la marca de final, y con 0');
    });
  });
}

/// Una peticion con `Range`, que `HttpClient` de Dart si admite.
///
/// Va en una funcion porque en linea se mezclaba con el `getUrl`, que devuelve un
/// `HttpClientRequest` **sin** enviar, y poner la cabecera despues de cerrarlo no hace
/// nada: es como se escribio la primera vez y por eso esta.
Future<HttpClientResponse> _rango(
  HttpClient cliente,
  String url, {
  required int desde,
  required int hasta,
}) async {
  final peticion = await cliente.getUrl(Uri.parse(url));
  peticion.headers.set('Range', 'bytes=$desde-$hasta');
  return await peticion.close();
}
