// SQLite en nativo (Android, Linux, Windows, macOS) con `dart:ffi`.
//
// Uno de los dos ficheros que saben en que plataforma estamos. Si anades aqui
// algo, anadelo tambien en `sqlite_web.dart`, o el codigo que funciona aqui no
// compilara alla.

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
