// Abrir un `.amod` y preguntarle cosas.
//
// LO IMPORTANTE DE ESTE FICHERO: es el unico que sabe que hay un SQLite. Ni la
// UI ni el dominio saben, y por eso la app funciona igual en web y en nativo con
// el mismo codigo de lectura.
//
// Como funciona el reparto de plataformas:
//
// - `sqlite_nativo.dart` usa `dart:ffi` a traves de `sqlite3_flutter_libs`.
// - `sqlite_web.dart` usa `sqlite3.wasm`, que es el mismo SQLite compilado.
//
// Los dos exponen la misma clase, `Sqlite`, con los mismos metodos. Detras hay
// un motor distinto, pero la superficie es la misma, y eso es lo que permite que
// el repositorio y los casos de uso no sepan donde se estan.
//
// Las dos implementaciones deben ofrecer **exactamente** los mismos metodos.
// Si una anade algo, la otra tambien, o el codigo que funciona en una
// plataforma no compila en la otra. Es el precio de no duplicar 300 lineas de
// consultas.

import 'package:sqlite3/common.dart';

import 'sqlite_nativo.dart'
    if (dart.library.js_interop) 'sqlite_web.dart'
    as impl;

/// Modo de apertura. Se limita a solo lectura a proposito: un `.amod` abierto
/// en escritura cambia su cabecera, y su `sha256` deja de coincidir con el que
/// declara el manifiesto. Ademas, escribir en un modulo descargado seria una
/// forma de perder el texto de la otra persona.
///
/// Por eso **no hay modo de escritura** en esta superficie. No es una
/// limitacion pendiente: es que escribir en un modulo descargado no debe poder ocurrir.
enum ModoApertura { soloLectura }

/// Un motor SQLite abierto sobre un modulo.
class Sqlite {
  Sqlite._(this._db);

  final CommonDatabase _db;

  /// Abre un modulo en solo lectura.
  ///
  /// [ruta] es una ruta en el sistema de ficheros **virtual**, no del sistema:
  /// en web no hay sistema de ficheros. Quien la escribe es
  /// [AlmacenamientoDeModulos], y nadie mas.
  static Sqlite abrir(String ruta) =>
      Sqlite._(impl.abrirEnSqlite(ruta, soloLectura: true));

  /// Cierra. Si no se cierra, el fichero se queda abierto y en un movil con
  /// pocos recursos eso se nota.
  void cerrar() => _db.close();

  /// Consulta y devuelve las filas.
  ///
  /// Nunca devuelve null ni lanza por "no hay resultados": una consulta sin
  /// filas devuelve una lista vacia, que es lo que quien pregunta quiere saber.
  List<Map<String, Object?>> consultar(String sql, [List<Object?> parametros = const []]) {
    final ResultSet r = _db.select(sql, parametros);
    return r.map((Row fila) => fila.map((k, v) => MapEntry(k, v as Object?))).toList();
  }

  /// Lo mismo, pero devuelve un unico valor o null si no hay fila.
  ///
  /// Es el 90 por ciento de las consultas: `SELECT value FROM info WHERE key=?`.
  Object? valor(String sql, [List<Object?> parametros = const []]) {
    final filas = consultar(sql, parametros);
    if (filas.isEmpty) return null;
    return filas.first.values.first;
  }

  /// `PRAGMA quick_check`. Dice si el fichero esta entero.
  ///
  /// No es un adorno: comprueba que un modulo descargado a medias no se lea
  /// como si estuviera bien y muestre versiculos vacios sin avisar.
  String comprobacionRapida() => (valor('PRAGMA quick_check') ?? 'desconocido').toString();

  /// Un valor de la tabla `info`, que es donde el modulo declara lo que es.
  String? info(String clave) => valor('SELECT value FROM info WHERE key = ?', [clave]) as String?;

  /// Un entero de la tabla `info`. Null si no esta o no se puede leer.
  int? infoEntero(String clave) {
    final v = info(clave);
    return v == null ? null : int.tryParse(v.trim());
  }
}
