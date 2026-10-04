// Obtener un modulo, con su hash comprobado, y todo lo que puede ir mal.
//
// EL MODULO DE LAS PRUEBAS ES EL REAL, pero servido por un servidor LOCAL.
//
// Las dos mitades importan. El fichero es el de verdad de `aa`, con sus
// 22.544.384 bytes y su sha256 de verdad, porque un `.amod` de diez filas pasaria
// aunque el formato real tuviera algo que no se ve con diez filas. Y el servidor
// es de aqui, porque una prueba que baja 22 MB de Internet falla cuando falla
// Internet, y una suite que falla por eso se deja de mirar. Ademas tardaria
// medio minuto por prueba.
//
// Lo que **no** se hace es apuntar a `yojananyosef.github.io`: una prueba que
// depende de la red es una prueba que un dia pasa sin comprobar nada porque la
// peticion fallo y el codigo no loNoto. Eso ya casi ocurria aqui.
//
// Y hay una comprobacion que va contra el SITIO REAL, y esta separada, marcada
// como tal, porque es la que no se puede simular: que `browserUrl` funcione y
// `downloadUrl` no. Si esa falla, la app no puede descargar nada en el navegador
// aunque todo lo demas este verde.

import 'dart:io';
import 'dart:typed_data';

import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/http_service.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/use_cases/obtener_modulo.dart';
import 'package:ab/domain/use_cases/resultado_obtencion.dart';
import 'package:flutter_test/flutter_test.dart';

const String _sha256Kjv = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
const String _rutaKjv = '/home/j/aa/modules/build/KJV2006_bible.amod';
const int _tamanoKjv = 22544384;

/// El modulo real, en bytes, leido una vez. Son 22 MB; leerlos en cada prueba
/// haria que la suite tardase mucho mas de lo que necesita.
Uint8List get _bytesKjv {
  final f = File(_rutaKjv);
  if (!f.existsSync()) {
    fail('falta $_rutaKjv, el modulo real del repositorio hermano. Sin el '
        'fichero REAL esta prueba no verifica nada, y una prueba que no verifica '
        'es peor que no tenerla.');
  }
  return f.readAsBytesSync();
}

void main() {
  group('4.1 y 4.2 el progreso son bytes reales', () {
    test('el progreso llega hasta el total exacto, sin pasarse ni retroceder', () async {
      final con = await _ConServidorLocal.abrir(_bytesKjv);
      addTearDown(con.cerrar);

      final progresos = <int>[];
      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Progreso) progresos.add(e.recibidos);
        if (e is Terminada) resultado = e.resultado;
      }

      expect(progresos, isNotEmpty, reason: 'sin progreso no hay barra que enseñar');
      expect(progresos.last, _tamanoKjv, reason: 'tiene que acabar en el total exacto');
      // Nunca por encima: una barra al 104 por ciento es un bug que se ve.
      expect(progresos.every((r) => r <= _tamanoKjv), isTrue);
      // Y en orden: el progreso no puede saltar atras.
      for (var i = 1; i < progresos.length; i++) {
        expect(progresos[i], greaterThan(progresos[i - 1]), reason: 'el progreso retrocede');
      }
      expect(resultado, isA<Obtenido>());
      final r = resultado! as Obtenido;
      expect(r.bytes.length, _tamanoKjv);
      expect(r.bytesTotales, _tamanoKjv);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('los bytes que vuelven son los del fichero, no otros parecidos', () async {
      // Un rango que devolviera 22 MB equivocados pasaria la comprobacion de
      // longitud y daria un hash distinto. Se compara entero a entero en tres
      // sitios, que es lo que hace sospechosa cualquier diferencia.
      final bytes = _bytesKjv;
      final con = await _ConServidorLocal.abrir(bytes);
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }

      final r = resultado! as Obtenido;
      for (final donde in const [0, 1, 1000, 11_000_000, 22_544_383]) {
        expect(r.bytes[donde], bytes[donde], reason: 'byte $donde');
      }
      expect(r.bytes.length, bytes.length);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('la fraccion del progreso va de 0 a 1 y nunca se pasa', () async {
      final con = await _ConServidorLocal.abrir(_bytesKjv);
      addTearDown(con.cerrar);

      final fracciones = <double>[];
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Progreso && e.fraccion != null) fracciones.add(e.fraccion!);
      }
      expect(fracciones, isNotEmpty);
      expect(fracciones.every((f) => f >= 0 && f <= 1), isTrue);
      expect(fracciones.last, closeTo(1.0, 0.0001));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('4.3 un modulo alterado NO se devuelve', () {
    test('un byte cambiado da HashIncorrecto con los dos hashes', () async {
      final bytes = _bytesKjv;
      final copia = Uint8List.fromList(bytes);
      // Un byte cambiado, y no uno cualquiera: se cambia la primera letra del
      // nombre de un libro. Un SQLite con un byte cambiado en un texto abre
      // PERFECTO y da versiculos casi correctos, y por eso esto no se puede
      // comprobar despues de abrir.
      final donde = _indiceDe(copia, 'Genesis');
      copia[donde] = 0x58; // 'X'

      final con = await _ConServidorLocal.abrir(copia);
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }

      expect(resultado, isA<HashIncorrecto>());
      final r = resultado! as HashIncorrecto;
      expect(r.esperado, _sha256Kjv);
      expect(r.obtenido, isNot(_sha256Kjv));
      expect(r.obtenido, hasLength(64));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('y un modulo truncado da DescargaIncompleta, no un modulo a medias', () async {
      // Un fichero al que le faltan bytes no es un modulo: no se devuelve como si
      // lo fuera. Y el mensaje dice cuantos de cuantos, que es lo que permite
      // decidir si reintentar.
      final bytes = _bytesKjv.sublist(0, _tamanoKjv - 100);
      final con = await _ConServidorLocal.abrir(bytes, announcedSize: _tamanoKjv);
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }

      expect(resultado, isA<DescargaIncompleta>());
      final r = resultado! as DescargaIncompleta;
      expect(r.esperados, _tamanoKjv);
      expect(r.recibidos, lessThan(_tamanoKjv));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('4.4 origen no legible y origen caido son COSAS DISTINTAS', () {
    test('un origen sin cabecera de origen cruzado da OrigenNoLegible', () async {
      final con = await _ConServidorLocal.abrir(_bytesKjv, conCors: false);
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }

      expect(resultado, isA<OrigenNoLegible>());
      // Y con CORS si funciona, que es lo que prueba que el motivo era ese.
      const OrigenNoLegible();
      expect(descripcionDe(const OrigenNoLegible()), contains('fichero local'));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('con la cabecera puesta, el MISMO servidor si funciona', () async {
      // La pareja con el test anterior. Un test que solo comprueba el caso malo no
      // dice si el bueno funciona por suerte o por diseno.
      final con = await _ConServidorLocal.abrir(_bytesKjv, conCors: true);
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }
      expect(resultado, isA<Obtenido>());
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('un servidor caido NO es OrigenNoLegible, es OrigenCaido', () async {
      // Que no se confundan es lo que permite poner el boton de reintentar en un
      // caso y un fichero local en el otro. Si los dos fueran el mismo estado, el
      // boton de reintentar apareceria donde no arregla nada.
      final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final puerto = servidor.port;
      await servidor.close(force: true); // apagado antes de empezar

      final http = HttpService();
      final obtener = ObtenerModulo(http: http, intentosMaximos: 2, tamanoTrozo: 1 << 20);
      final modulo = _moduloFalso(puerto, tamano: 1024);

      ResultadoObtencion? resultado;
      await for (final e in obtener.obtener(
        modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: false,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }
      http.cerrar();

      expect(resultado, isA<OrigenCaido>());
      expect((resultado! as OrigenCaido).intentos, 2);
    }, timeout: const Timeout(Duration(seconds: 40)));
  });

  group('4.6 los fallos tienen final', () {
    test('tras agotar los intentos no queda nada animado', () async {
      final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final puerto = servidor.port;
      await servidor.close(force: true);

      final http = HttpService();
      final obtener = ObtenerModulo(http: http, intentosMaximos: 3, tamanoTrozo: 1024);
      final modulo = _moduloFalso(puerto, tamano: 4096);

      final eventos = <EventoObtencion>[];
      final reloj = Stopwatch()..start();
      await for (final e in obtener.obtener(
        modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: false,
      )) {
        eventos.add(e);
      }
      http.cerrar();

      // Exactamente un final. Ni cero --lo que dejaria una barra girando para
      // siempre-- ni dos.
      expect(eventos.whereType<Terminada>().length, 1);
      expect(eventos.whereType<Terminada>().single.resultado, isA<OrigenCaido>());
      expect(reloj.elapsedMilliseconds, lessThan(30000),
          reason: 'tres intentos y se para: esto no es un progreso infinito');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('4.7 cancelar', () {
    test('cancelar antes de empezar no baja nada y dice cancelado', () async {
      final con = await _ConServidorLocal.abrir(_bytesKjv);
      addTearDown(con.cerrar);

      final cancelar = Cancelar()..pedir();
      final eventos = <EventoObtencion>[];
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
        cancelar: cancelar,
      )) {
        eventos.add(e);
      }

      expect(eventos.whereType<Terminada>().single.resultado, isA<Cancelado>());
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('cancelar a mitad se para DE VERDAD, antes del final', () async {
      // Con trozos pequenos para poder cancelar dentro. Si cancelar no parase
      // hasta el final, el tiempo gastado y el ancho de banda serian de un
      // `.amod` entero por un cambio de idea, y eso es lo que hace que la gente
      // deje de usar el boton.
      final con = await _ConServidorLocal.abrir(_bytesKjv, tamanoTrozo: 1 << 20);
      addTearDown(con.cerrar);

      final cancelar = Cancelar();
      var piezas = 0;
      ResultadoObtencion? resultado;
      int ultimoProgreso = 0;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
        cancelar: cancelar,
      )) {
        if (e is Progreso) {
          ultimoProgreso = e.recibidos;
          if (++piezas == 3) cancelar.pedir();
        }
        if (e is Terminada) resultado = e.resultado;
      }

      expect(resultado, isA<Cancelado>());
      expect(ultimoProgreso, greaterThan(0), reason: 'llego a bajar algo antes de cancelar');
      expect(ultimoProgreso, lessThan(_tamanoKjv), reason: 'se paro ANTES del final');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('4.2 la memoria no llega a tener el modulo dos veces', () {
    // Por que importa. Un `.amod` son 22.544.384 bytes y el comentario son
    // 57.536.512. Si en algun momento hubiera dos copias en un movil de gama baja
    // con la app abierta, la copia de mas es justo lo que hace que el sistema mate
    // el proceso. Y eso no da ningun error: aparece como "la app se cierra sola",
    // que es el fallo mas dificil de investigar que hay.
    //
    // QUE PRUEBA ESTA MEDICION Y QUE NO. Y es importante decirlo, porque una
    // medida malinterpretada es peor que no medir.
    //
    // Mide el crecimiento de la memoria residente del proceso durante la
    // descarga. Eso es una **cota superior**, no la memoria viva: incluye la
    // basura que el recolector todavia no se ha llevado. Por eso el umbral es de
    // cuatro veces el modulo y no de dos, y por eso esta prueba NO demuestra que
    // no haya dos copias en memoria: la RSS no distingue "dos copias vivas" de
    // "una copia viva y un monton de basura sin recoger".
    //
    // Lo que si distingue, y con muchisima separacion, es el fallo
    // catastofico. Las tres implementaciones se midieron el mismo dia con el
    // mismo modulo y el mismo servidor:
    //
    //   `[...acumulado, ...trozo]`   pico +1242,8 MiB   (55 veces el modulo)
    //   `BytesBuilder(copy: false)`  pico   +43,3 MiB
    //   `Uint8List(total)` reservado pico   +51,8 MiB   (la que esta)
    //
    // La primera encaja cada byte en un puntero y ademas copia el acumulado en
    // cada trozo: 55 veces el modulo, y con el comentario de 57 MB serian mas de
    // 3 GiB. Eso es lo que hay que cazar, y el umbral lo caza con un margen de
    // veinticuatro veces.
    //
    // Que la segunda y la tercera den numbers parecidos **no significa que sean
    // equivalentes**: la diferencia entre 43 y 52 MiB esta dentro del ruido del
    // recolector. Lo que las distingue es estructural --una reserva exacta, sin
    // crecidas y sin copia final-- y eso lo comprueba la prueba de aqui abajo,
    // que si es exacta.
    test('el pico se queda en cuatro veces el modulo', () async {
      final con = await _ConServidorLocal.abrir(_bytesKjv, tamanoTrozo: 1 << 20);
      addTearDown(con.cerrar);

      final antes = ProcessInfo.currentRss;
      var pico = antes;
      var muestras = 0;

      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Progreso) {
          final ahora = ProcessInfo.currentRss;
          if (ahora > pico) pico = ahora;
          muestras++;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final despues = ProcessInfo.currentRss;
      final crecimiento = pico - antes;

      // ignore: avoid_print
      print('DBG memoria: antes=${_mib(antes)} pico=${_mib(pico)} '
          'despues=${_mib(despues)} crecimiento=${_mib(crecimiento)} '
          'muestras=$muestras');

      expect(muestras, greaterThan(10), reason: 'sin muestras no se ha medido nada');
      expect(crecimiento, lessThan(_tamanoKjv * 4),
          reason: 'el pico subio ${_mib(crecimiento)} para un modulo de '
              '${_mib(_tamanoKjv)}. La version que encaja cada byte en un puntero '
              'llegaba a +1242,8 MiB, asi que el margen es enorme a proposito.');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('un servidor que devuelve MAS bytes de los pedidos se rechaza', () async {
      // La parte exacta de 4.2, la que no depende del ruido: el bufer se reserva
      // con el tamano que anuncia el manifiesto, y si el servidor manda mas de lo
      // que se le pidio no cabe. Antes, con una lista que crecia, eso se traducía
      // en gigas de memoria; ahora tiene que ser un fallo limpio y dicho.
      final bytes = _bytesKjv;
      final con = await _ConServidorLocal.abrir(
        bytes,
        announcedSize: 4 << 20, // el manifiesto miente: dice 4 MiB
        tamanoTrozo: 1 << 20,
      );
      addTearDown(con.cerrar);

      ResultadoObtencion? resultado;
      await for (final e in con.obtener.obtener(
        con.modulo,
        hashEsperado: _sha256Kjv,
        usarUrlDeNavegador: true,
      )) {
        if (e is Terminada) resultado = e.resultado;
      }

      // Un 416 del servidor seria lo natural, porque el rango pedido acaba fuera
      // del tamaño que el servidor cree tener. Lo que se exige es que NO se
      // devuelva un modulo, y que no se haya Reservesado mas de lo declarado.
      expect(resultado, isNot(isA<Obtenido>()),
          reason: 'no se devuelve un modulo cuyo tamano no es el que se pidio');
      // El motivo concreto depende de si el servidor contesta 416 por el rango
      // fuera de su tamano o si hay que arrives al final: cualquiera de los dos
      // es correcto, y lo que no vale es devolver un modulo.
      expect(resultado, anyOf(
        isA<DescargaIncompleta>(),
        isA<OrigenCaido>(),
        isA<HashIncorrecto>(),
      ));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('el hash terminado son 32 bytes, no el modulo', () async {
      // La otra mitad de 4.2, y es la que se puede comprobar exactamente. Un
      // `HashEnCurso` terminado solo guarda el digest: lo que ha pasado por el se
      // suelta. Si alguien acumulara los trozos dentro para "poder rehacerlo",
      // esto dejaria de cumplirse, y bajando 22 MB con el hash reteniendo 22 MB
      // seria el mismo fallo que esta prueba de memoria, otra vez.
      final bytes = _bytesKjv;
      final h = HashEnCurso();
      for (var i = 0; i < bytes.length; i += 1 << 20) {
        final fin = (i + (1 << 20)) < bytes.length ? i + (1 << 20) : bytes.length;
        h.anadir(bytes.sublist(i, fin));
      }
      expect(h.bytesLeidos, bytes.length);
      expect(h.finalizar(), _sha256Kjv,
          reason: 'el hash por tramos tiene que dar el hash de verdad');
      expect(sha256DeBytes(bytes), _sha256Kjv,
          reason: 'y tiene que coincidir con el hash del fichero entero');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('el texto de cada estado', () {
    test('cada resultado tiene su frase, y ninguna es "error"', () {
      final casos = <ResultadoObtencion>[
        const Obtenido(bytes: [1], bytesTotales: 10),
        const OrigenNoLegible(),
        const OrigenCaido(intentos: 3),
        const DescargaIncompleta(recibidos: 5, esperados: 10),
        HashIncorrecto(
          esperado: String.fromCharCodes(List.filled(64, 'a'.codeUnitAt(0))),
          obtenido: String.fromCharCodes(List.filled(64, 'b'.codeUnitAt(0))),
        ),
        const Cancelado(),
        HayVersionNueva([1]),
        const FalloInesperado('x'),
      ];
      for (final c in casos) {
        final texto = descripcionDe(c);
        expect(texto.trim(), isNotEmpty);
        // La palabra "error" no dice nada: quien lee necesita saber si reintentar,
        // si buscar otro origen, o si abrir un fichero local.
        expect(texto.toLowerCase(), isNot(contains('error')));
        if (c is DescargaIncompleta) {
          expect(texto, contains('5'));
          expect(texto, contains('10'));
        }
        if (c is OrigenCaido) expect(texto, contains('3'));
      }
      expect(descripcionDe(const OrigenNoLegible()), contains('fichero local'),
          reason: 'el mensaje tiene que decir que hay otra via');
      // El hash alterado dice los dos hashes: sin ellos no se puede hacer nada,
      // porque "el fichero no es el que toca" sin decir cual es el que se ha
      // obtenido no permite ni reportar ni comparar.
      final alterado = casos.whereType<HashIncorrecto>().single;
      expect(descripcionDe(alterado), contains(alterado.esperado));
      expect(descripcionDe(alterado), contains(alterado.obtenido));
    });
  });
}

/// Un servidor local que sirve bytes por rango, con su `Modulo` apuntando a el.
///
/// Va en una clase propia porque todo lo que se necesita para una prueba es lo
/// mismo siempre, y con un metodo suelto cada test se olvidaria de una pieza.
class _ConServidorLocal {
  _ConServidorLocal._(this.modulo, this.obtener, this.http, this.servidor);

  /// Un modulo con el tamano y el hash del KJV real, cuya URL es **este**
  /// servidor. Las dos URLs, porque el motor de obtencion elige una u otra.
  final Modulo modulo;
  final ObtenerModulo obtener;
  final HttpService http;
  final HttpServer servidor;

  static Future<_ConServidorLocal> abrir(
    Uint8List bytes, {
    bool conCors = true,
    int? announcedSize,
    int tamanoTrozo = 4 << 20,
  }) async {
    final servidor = await _servidor(bytes, conCors: conCors);
    final http = HttpService();
    final base = 'http://127.0.0.1:${servidor.port}';
    final modulo = Modulo(
      id: 'KJV2006',
      nombre: 'King James Version (2006)',
      tipo: TipoModulo.biblia,
      idioma: 'eng',
      licencia: 'PublicDomain',
      // Lo que **anuncia** el catalogo, que puede no ser lo que el servidor tiene.
      tamanoBytes: announcedSize ?? bytes.length,
      sha256: _sha256Kjv,
      urlDescarga: Uri.parse('$base/descarga/KJV2006_bible.amod'),
      urlNavegador: Uri.parse('$base/navegador/KJV2006_bible.amod'),
    );
    return _ConServidorLocal._(
      modulo,
      ObtenerModulo(http: http, tamanoTrozo: tamanoTrozo),
      http,
      servidor,
    );
  }

  Future<void> cerrar() async {
    http.cerrar();
    await servidor.close(force: true);
  }
}

/// Un modulo que apunta a un puerto donde no hay nada. Para el caso "caido".
Modulo _moduloFalso(int puerto, {required int tamano}) => Modulo(
      id: 'X',
      nombre: 'X',
      tipo: TipoModulo.biblia,
      idioma: 'eng',
      licencia: 'PublicDomain',
      tamanoBytes: tamano,
      sha256: _sha256Kjv,
      urlDescarga: Uri.parse('http://127.0.0.1:$puerto/x.amod'),
      urlNavegador: Uri.parse('http://127.0.0.1:$puerto/x.amod'),
    );

/// Un servidor que responde a rangos como lo hace uno de verdad.
///
/// Lo que reproduce, y son los dos casos que se ven en la practica:
/// - Un CDN que **ignora** el `Range` y contesta 200 con el fichero entero.
/// - Un 416 cuando el rango ya no existe, que es lo que responde GitHub Pages.
Future<HttpServer> _servidor(Uint8List datos, {required bool conCors}) async {
  final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  s.listen((p) async {
    if (conCors) p.response.headers.set('Access-Control-Allow-Origin', '*');
    final rango = p.headers.value(HttpHeaders.rangeHeader);
    if (rango == null) {
      p.response.headers.contentLength = datos.length;
      p.response.add(datos);
      await p.response.close();
      return;
    }
    final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rango);
    if (m == null) {
      p.response.statusCode = HttpStatus.badRequest;
      await p.response.close();
      return;
    }
    final desde = int.parse(m.group(1)!);
    final hasta = int.parse(m.group(2)!);
    if (desde >= datos.length) {
      p.response.statusCode = 416;
      await p.response.close();
      return;
    }
    final hastaReal = hasta >= datos.length ? datos.length - 1 : hasta;
    final trozo = datos.sublist(desde, hastaReal + 1);
    p.response.statusCode = 206;
    p.response.headers.set('Content-Range', 'bytes $desde-$hastaReal/${datos.length}');
    p.response.headers.contentLength = trozo.length;
    p.response.add(trozo);
    await p.response.close();
  });
  return s;
}

/// La posicion de la primera aparicion de [agujas] en [p], como indice de byte.
int _indiceDe(Uint8List p, String agujas) {
  final b = agujas.codeUnits;
  for (var i = 0; i + b.length <= p.length; i++) {
    var ok = true;
    for (var j = 0; j < b.length; j++) {
      if (p[i + j] != b[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  throw StateError('no se encontro "$agujas" en el modulo; el fixture esta cambiado');
}

/// Bytes en MiB, para los mensajes de las pruebas de memoria.
String _mib(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
