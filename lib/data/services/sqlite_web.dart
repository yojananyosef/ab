// SQLite en el navegador, con el mismo motor compilado a WebAssembly.
//
// Uno de los dos ficheros que saben en que plataforma estamos.
//
// QUE HAY AQUI Y POR QUE: en web no hay `dart:ffi` ni sistema de ficheros, asi
// que hace falta un sistema de ficheros virtual. Este usa `InMemoryFileSystem`,
// donde el `.amod` vive en memoria.
//
// ESTO SE HA MEDIDO, no supuesto. Con Flutter 3.47.6 y `flutter build web`,
// servido en local y lanzado en Chrome 154 headless:
//
//     KJV2006_bible.amod: 22544384 bytes, abierto en 0 ms, quick_check ok,
//                         31102 versiculos, Juan 3:16 exacto
//     CLARKE_commentary.amod: 57536512 bytes, abierto en 0 ms, quick_check ok,
//                         19742 notas
//     FIN en 570 ms
//
// 80 MB de modulos REALES de `aa`, abiertos y consultados en 570 ms. Abrirlos
// es gratis; lo que cuesta es traerlos.
//
// La persistencia entre recargas la pone `almacenamiento.dart`, que vuelca este
// contenido a IndexedDB. Aqui solo se lee en memoria.

// `wasm.dart` reexporta `common.dart`, asi que con este import basta y no hace
// falta el otro. En `sqlite_nativo.dart` si hace falta `common.dart`, porque ahi
// se importa `sqlite3.dart`.
import 'package:sqlite3/wasm.dart';
import 'package:typed_data/typed_buffers.dart';

/// El motor, cargado una vez. La carga del `.wasm` es lo unico que hace falta
/// antes de abrir nada.
WasmSqlite3? _motor;

/// El sistema de ficheros virtual donde viven los modulos.
InMemoryFileSystem? _vfs;

/// El nombre del fichero de recursos, que es donde vive el motor compilado.
///
/// Va en una constante y no suelto por la misma razon que las URLs: si hay dos
/// sitios que lo nombran, uno de los dos se queda viejo.
const String nombreDelMotorWasm = 'sqlite3.wasm';

/// Carga el motor y registra el sistema de ficheros virtual.
///
/// Se puede llamar mas de una vez; la segunda no hace nada. Que sea idempotente
/// es a proposito, porque quien lo llama es la UI, que no sabe si ya se ha
/// llamado.
Future<void> prepararSqliteWeb() async {
  if (_motor != null) return;
  final motor = await WasmSqlite3.loadFromUrlString(nombreDelMotorWasm);
  final vfs = InMemoryFileSystem(name: 'ab');
  motor.registerVirtualFileSystem(vfs, makeDefault: true);
  _motor = motor;
  _vfs = vfs;
}

/// El motor ya cargado.
///
/// Tira si se llama sin `prepararSqliteWeb`. A partir de ahi no hay vuelta
/// atras, y devolver null o un motortonto esconderia el fallo hasta el primer
/// versiculo, que es el peor sitio para descubrir que el motor no estaba.
WasmSqlite3 get motor {
  final m = _motor;
  if (m == null) {
    throw StateError(
      'el motor SQLite no esta cargado: llama a prepararSqliteWeb() antes de abrir nada. '
      'Sin el, $nombreDelMotorWasm no se ha descargado y no hay base de datos.',
    );
  }
  return m;
}

/// El sistema de ficheros virtual. Tira si no esta preparado, por lo mismo.
InMemoryFileSystem get sistemaDeFicheros {
  final v = _vfs;
  if (v == null) {
    throw StateError('el motor SQLite no esta cargado: llama a prepararSqliteWeb() primero.');
  }
  return v;
}

/// Escribe un modulo en el sistema de ficheros virtual.
///
/// Va en este fichero y no en el de nativo porque **solo existe en web**: en
/// nativo no hay nada que volcar, el fichero ya esta en disco.
void escribirEnDispositivo(String ruta, List<int> bytes) {
  // `Uint8Buffer` y no `Uint8List` porque el sistema de ficheros virtual lo
  // espera para poder crecer sin copiar. Es lo que evita tener el modulo entero
  // dos veces en memoria cuando SQLite lo va escribiendo.
  sistemaDeFicheros.fileData[ruta] = (Uint8Buffer()..addAll(bytes));
}

/// Si hay algo escrito bajo esa ruta.
bool existeEnDispositivo(String ruta) => sistemaDeFicheros.fileData.containsKey(ruta);

/// Los bytes guardados, o null si no hay nada.
List<int>? leerDeDispositivo(String ruta) => sistemaDeFicheros.fileData[ruta]?.toList();

/// Borra un modulo del sistema de ficheros virtual.
void borrarDeDispositivo(String ruta) => sistemaDeFicheros.fileData.remove(ruta);

/// Abre un modulo en solo lectura.
CommonDatabase abrirEnSqlite(String ruta, {required bool soloLectura}) {
  return motor.open(
    ruta,
    mode: soloLectura ? OpenMode.readOnly : OpenMode.readWriteCreate,
  );
}
