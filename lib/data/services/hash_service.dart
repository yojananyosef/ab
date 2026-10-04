// Calcular el sha256 de algo que llega a trozos.
//
// POR QUE POR TRAMOS Y NO DESPUES. Un modulo de 57.536.512 bytes son 57 MB. Si
// se guarda entero en memoria para luego hashearlo, en el momento del hash hay
// dos copias: los bytes y el resultado intermedio. En un movil de gama baja, con
// esa copia de mas, el navegador o la app se queda sin memoria justo cuando va
// bien.
//
// Hasheando por tramos, lo unico que se guarda es el hash parcial, que son 32
// bytes. Los bytes van pasando y se sueltan.

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// Calcula el sha256 de una secuencia de trozos, sin juntarlos nunca.
///
/// Se usa asi:
///
/// ```
/// final h = HashEnCurso();
/// for (final trozo in trozos) {
///   h.anadir(trozo);
///   // el progreso sale de h.bytesLeidos, que ya va por aqui
/// }
/// final digest = h.finalizar();
/// ```
class HashEnCurso {
  HashEnCurso() {
    _salida = sha256.startChunkedConversion(_acumulador);
  }

  final _acumulador = AccumulatorSink<Digest>();
  late final ByteConversionSink _salida;

  int _bytes = 0;

  /// Cuantos bytes han pasado por aqui. Es el progreso de la descarga, y sale
  /// de aqui para que **no haya dos cuentas**: si el progreso lo llevara otro,
  /// podrian dejar de cuadrar y el progreso diria 20.000.000 de 22.500.000 con
  /// el hash ya terminado.
  int get bytesLeidos => _bytes;

  /// Anade un trozo. Si el trozo son 4 MB, el trabajo por byte es el mismo.
  void anadir(List<int> trozo) {
    if (trozo.isEmpty) return;
    _bytes += trozo.length;
    _salida.add(trozo);
  }

  /// Termina y devuelve el hash en hexadecimal en minusculas.
  ///
  /// Llama a `finalizar` una vez. Una segunda llamada daria un hash distinto, y
  /// eso seria un fallo silencioso: por eso avisa.
  String finalizar() {
    if (_finalizado) {
      throw StateError('este hash ya se finalizo y no se puede volver a calcular');
    }
    _finalizado = true;
    _salida.close();
    return _acumulador.events.single.toString();
  }

  bool _finalizado = false;
}

/// El sha256 de un iterable de trozos.
String sha256DeTrozos(Iterable<List<int>> trozos) {
  final h = HashEnCurso();
  for (final t in trozos) {
    h.anadir(t);
  }
  return h.finalizar();
}

/// El sha256 de algo que ya esta entero en memoria.
///
/// Existe para comparar en las pruebas y para ficheros pequeños. Para lo grande,
/// [sha256DeTrozos].
String sha256DeBytes(List<int> bytes) => sha256.convert(bytes).toString();

/// Un sha256 tiene 64 caracteres hexadecimales, en minusculas o en mayusculas.
///
/// Las mayusculas se aceptan porque son el mismo hash. El manifiesto los escribe
/// en minusculas, pero un hash en mayusculas no es un hash distinto: rechazarlo
/// seria un fallo de forma disfrazado de fallo de fondo, y el sintoma seria "el
/// modulo esta corrupto" cuando lo unico que pasa es que alguien lo copio mal.
bool esSha256(String? v) {
  if (v == null || v.length != 64) return false;
  for (var i = 0; i < 64; i++) {
    final c = v.codeUnitAt(i);
    final esHexDe0aF = c >= 0x30 && c <= 0x39;
    final esHexDeaF = c >= 0x61 && c <= 0x66;
    final esHexDeAF = c >= 0x41 && c <= 0x46;
    if (!esHexDe0aF && !esHexDeaF && !esHexDeAF) return false;
  }
  return true;
}

/// Compara dos hashes sin que importe el orden de las letras.
///
/// El catalogo escribe en minusculas, pero un hash de mayusculas es el mismo
/// hash, y fallar por eso seria un fallo de forma, no de fondo.
bool mismoHash(String? a, String? b) {
  if (a == null || b == null) return false;
  return a.toLowerCase() == b.toLowerCase();
}

/// El hash de un fichero, leyendolo por trozos.
///
/// Se lee el fichero entero otra vez, que es lo que hace `sha256sum`. Para lo
/// que viene de la red **no** se usa: ahi los bytes ya pasaron por el hash
/// durante la descarga, y volver a leerlos seria lo segundo que peor se puede
/// hacer con 57 MB.
