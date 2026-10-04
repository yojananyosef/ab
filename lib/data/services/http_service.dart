// Pedir bytes, por trozos, y decir cuanto va.
//
// POR QUE POR TROZOS Y NO ENTERA LA URL. Un modulo son 22 o 57 MB. Si se pide
// entero, el progreso no se puede saber hasta que llega, la barra se queda en
// cero durante medio minuto y no se puede cancelar. Con peticiones por rango se
// sabe cuanto va, se puede cancelar entre trozo y trozo, y si se corta se puede
// decir cuantos bytes llegaron.
//
// LO QUE ESTE FICHERO NO HACE, Y ES LO IMPORTANTE: **no reintenta, no decide si
// el fallo es de red o de origen cruzado, y no avisa de nada**. Eso lo decide
// arriba, en quien sabe lo que esta pasando. Un cliente HTTP que reintenta por
// su cuenta es un cliente que hide el fallo en vez de contarlo.

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Respuesta a una peticion, con lo justo para saber que paso.
///
/// El cuerpo se guarda como `Uint8List` y no como `String` a proposito: un
/// `.amod` son bytes, no texto, y convertirlo a `String` con la codificacion
/// equivocada es una forma de corromperlo.
class Respuesta {
  const Respuesta({
    required this.codigo,
    required this.cabeceras,
    required this.cuerpo,
    required this.urlFinal,
  });

  /// 200, 206 para un rango, 404, 416 si el rango no vale...
  final int codigo;

  /// En minusculas, como las da el estandar.
  final Map<String, String> cabeceras;

  final Uint8List cuerpo;

  /// Donde ha acabado la peticion.
  ///
  /// Importa porque estas URLs redirigen a una pagina firmada con caducidad, y por
  /// eso no se pueden guardar para siempre: un enlace de descarga caduca.
  final String urlFinal;

  bool get ok => codigo >= 200 && codigo < 300;

  /// `bytes 0-1023/22544384`, tal cual lo dice el servidor.
  String? get rangoContenido => cabeceras['content-range'];

  /// De las 22544384 cosas que tiene el fichero, cuantas ha pedido este trozo.
  ///
  /// Null si el servidor no lo dice, y entonces el total se tiene que ir
  /// sumando a mano, que es lo que hace el caso de un modulo pequeno.
  int? get totalEsperado {
    final r = rangoContenido;
    if (r == null) return null;
    final slash = r.lastIndexOf('/');
    if (slash < 0) return null;
    return int.tryParse(r.substring(slash + 1));
  }

  int get inicioRango {
    final r = rangoContenido;
    if (r == null) return 0;
    return int.tryParse(r.split(' ').first.split('-').first) ?? 0;
  }
}

/// Cliente HTTP. Envuelto en una clase para poder sustituirlo en las pruebas sin
/// red.
class HttpService {
  HttpService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// Pedir un rango: de [desde] hasta [hasta], **ambos incluidos**.
  ///
  /// Devuelve null si el servidor no acepta el rango, para que quien llama pueda
  /// caer a pedirlo entero. No es teoria: hay servidores de CDN que contestan 200
  /// con el fichero completo e ignoran el `Range`, y en ese caso pedir por rango
  /// sin mas descarga 22 MB y dice que ha pedido 22 MB.
  Future<Respuesta?> rango(Uri url, int desde, int hasta) async {
    final peticion = http.Request('GET', url)
      ..headers['Range'] = 'bytes=$desde-$hasta'
      // NO se pone `Origin`. En un navegador, esa cabecera la pone el
      // navegador y no se puede cambiar desde el codigo: ponerla aqui a mano
      // no concede ningun permiso, solo confunde. El permiso lo tiene que dar
      // el servidor, y no hay forma de pedirlo.
      ..headers['Accept'] = 'application/octet-stream';

    try {
      final enviada = await _cliente.send(peticion);
      final respuesta = await http.Response.fromStream(enviada);
      return Respuesta(
        codigo: respuesta.statusCode,
        cabeceras: respuesta.headers.map((k, v) => MapEntry(k.toLowerCase(), v)),
        cuerpo: respuesta.bodyBytes,
        urlFinal: respuesta.request?.url.toString() ?? url.toString(),
      );
    } on http.ClientException {
      return null;
    }
  }

  /// Pedir el fichero entero. Se usa para el manifiesto, que son 1.468 bytes.
  Future<Respuesta?> entero(Uri url) async {
    final peticion = http.Request('GET', url)..headers['Accept'] = 'application/json';
    try {
      final enviada = await _cliente.send(peticion);
      final respuesta = await http.Response.fromStream(enviada);
      return Respuesta(
        codigo: respuesta.statusCode,
        cabeceras: respuesta.headers.map((k, v) => MapEntry(k.toLowerCase(), v)),
        cuerpo: respuesta.bodyBytes,
        urlFinal: respuesta.request?.url.toString() ?? url.toString(),
      );
    } on http.ClientException {
      return null;
    }
  }

  /// Descansar. Se usa entre reintentos, y vive aqui para que quien reintenta
  /// no tenga que inventarse el tiempo de espera.
  Future<void> esperar(Duration d) => Future<void>.delayed(d);

  void cerrar() => _cliente.close();
}
