// SQLite en nativo (Android, Linux, Windows, macOS) con `dart:ffi`.
//
// Uno de los dos ficheros que saben en que plataforma estamos. Si anades aqui
// algo, anadelo tambien en `sqlite_web.dart`, o el codigo que funciona aqui no
// compilara alla.

import 'dart:io';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

/// Abre un modulo en solo lectura.
///
/// El modo se pasa al motor y no se controla desde fuera: esta funcion **solo**
/// sabe abrir en lectura. No hay forma de pedir escritura, ni aqui ni en la
/// version web.
CommonDatabase abrirEnSqlite(String ruta, {required bool soloLectura}) {
  return sqlite3.open(
    ruta,
    mode: soloLectura ? OpenMode.readOnly : OpenMode.readWriteCreate,
  );
}

/// En nativo no hay motor que cargar: `dart:ffi` lo trae el propio paquete.
///
/// Por eso esta funcion esta vacia y **no** se puede borrar sin mirar: quien la
/// llama la usa igual en las cuatro plataformas, y si desaparece hay que mirar los
/// dos ficheros de la interfaz.
Future<void> prepararSiHaceFalta() async {}

/// Lee un fichero del disco.
///
/// Solo con `dart:io`, que es justo lo que este fichero importa y el otro no. Por
/// eso la lectura vive aqui y no en el comun: en web no hay fichero.
Future<List<int>?> bytesDe(String ruta) async {
  final f = File(ruta);
  if (!f.existsSync()) return null;
  try {
    return f.readAsBytesSync();
  } catch (_) {
    // Un fichero que se puede abrir pero no leer no se distingue de uno que no
    // esta. En los dos casos el resultado para quien pregunta es el mismo.
    return null;
  }
}
