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
//
// ============================================================================
// Y LA URL DEL `.wasm` SE RESUELVE CONTRA EL `<base href>`, NO CONTRA LA DIRECCION
// ============================================================================
//
// MEDIDO EL 4 DE OCTUBRE DE 2026, Y ERA UN BUG DE VERDAD, NO UN DETALLE.
//
// Con un enlace profundo --`/leer/KJV2006/John.3.16`-- el navegador pedia:
//
//     GET /leer/KJV2006/sqlite3.wasm  -> 404
//
// y la aplicacion se quedaba sin motor: sin SQLite no se abre ningun modulo, sin modulos
// no hay texto, y sin texto no hay lectura. O sea que **ningun enlace profundo
// funcionaba**, y en la raiz si. El motivo es que `WasmSqlite3.loadFromUrlString` pasa
// la cadena tal cual a `fetch`, y `fetch` resuelve una URL relativa contra la
// **direccion del documento** --`/leer/KJV2006/John.3.16`-- y no contra el `<base href>`
// que pone `--base-href`.
//
// Por eso se resuelve aqui y explicitamente contra `document.baseURI`, que si es el
// `<base href>` ya resuelto. En el sitio publicado eso da
// `https://.../ab/sqlite3.wasm` venga la direccion que venga; y en local da
// `http://127.0.0.1:8099/sqlite3.wasm`.
//
// Y NO SE USA `Uri.base` DE DART, que es la URL del documento y por tanto tiene el mismo
// fallo. Es la tentacion, porque `Uri.base` esta a mano y parece la direccion de la
// aplicacion; no lo es.

// `wasm.dart` reexporta `common.dart`, asi que con este import basta y no hace
// falta el otro. En `sqlite_nativo.dart` si hace falta `common.dart`, porque ahi
// se importa `sqlite3.dart`.
import 'package:sqlite3/wasm.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web/web.dart' as web;

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

/// La URL completa del `.wasm`, resuelta contra el `<base href>`.
///
/// Y SE CALCULA EN EL MOMENTO DE USARLA y no en una constante, porque `document` no
/// existe hasta que hay documento, y leerlo en una constante de nivel superior lanzaria
/// al cargar la biblioteca en un contexto sin DOM --que es justo lo que hace una
/// prueba--.
///
/// Y SI NO HAY `document` --en la maquina de Dart-- se devuelve el nombre a pelo. Esta
/// funcion no se llama nunca ahi, porque el import es condicional y `sqlite_nativo.dart`
// es el que se carga; el valor es solo para que la funcion tenga un `return`.
String urlDelMotorWasm() {
  final base = web.document.baseURI;
  if (base.isEmpty) return nombreDelMotorWasm;
  return web.URL(nombreDelMotorWasm, base).href;
}

/// Carga el motor y registra el sistema de ficheros virtual.
///
/// Se puede llamar mas de una vez; la segunda no hace nada. Que sea idempotente
/// es a proposito, porque quien lo llama es la UI, que no sabe si ya se ha
/// llamado.
Future<void> prepararSqliteWeb() async {
  if (_motor != null) return;
  final motor = await WasmSqlite3.loadFromUrlString(urlDelMotorWasm());
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

/// Carga el motor. En web **si** hace falta, y por eso se llama antes de pintar.
Future<void> prepararSiHaceFalta() => prepararSqliteWeb();

/// Los bytes de un modulo que ya esta en el sistema de ficheros virtual.
///
/// Si no esta, devuelve null en vez de tirar. Quien pregunta va a intentar abrirlo,
/// y "no esta" y "ha fallado al leer" llevan a la mismadecision: no se puede abrir.
Future<List<int>?> bytesDe(String ruta) async {
  try {
    return leerDeDispositivo(ruta);
  } catch (_) {
    return null;
  }
}
