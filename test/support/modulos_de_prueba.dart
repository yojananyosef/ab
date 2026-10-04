// Modulos con los terminos cambiados, para probar lo que el KJV real no tiene.
//
// ============================================================================
// POR QUE HACE FALTA ESTO
// ============================================================================
//
// Las tareas 7.12 y 7.13 necesitan dos cosas que el modulo real **no** tiene:
//
//   - Que el manifiesto y el modulo digan licencias distintas.
//   - Que `defects_count` sea mayor que cero, con su texto de `defects`.
//
// El KJV real declara `PublicDomain` y cero defectos, y esta bien: es el modulo que
// hay. Fabricar un `.amod` entero desde cero seria mas facil --y estaria mal, porque
// un `.amod` de diez versiculos pasaria aunque el formato real tuviera algo que solo
// se ve con 31.102--. Lo que se hace es **copiar el real y cambiarle la tabla
// `info`**, que es justo lo que haria un modulo publicado por otra persona con unos
// terminos distintos.
//
// Y EL SHA256 CAMBIA, Y ESTA BIEN. Se comprueba que el modulo se abre y se lee
// igualmente con los terminos cambiados, y no se comprueba que siga siendo el mismo
// fichero: es otro fichero, con otros terminos, y por eso tiene otro resumen. La
// aplicacion no lo vuelve a comprobar porque lo que compara es el que declara el
// manifiesto, y el manifiesto de la prueba lo pone la propia prueba.
//
// ============================================================================
// Y ESTOS FICHEROS NO SE VERSIONAN
// ============================================================================
//
// Se crean en el directorio temporal y se borran al terminar. Son de 22 MiB, y un
// repositorio no es un sitio para 22 MiB de un fichero que se puede volver a crear en
// un segundo. El `TMPDIR` se lee de donde toque: si no hay, va a `/tmp`, que en esta
// maquina es un tmpfs de 3,7 GB que se llena con facilidad. Ver `AGENTS.md`.

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'fixtures.dart';

/// La carpeta donde se crean los modulos de prueba.
///
/// Del `TMPDIR` del entorno y no de `/tmp` a secas, por el motivo que esta escrito en
/// `AGENTS.md`: `/tmp` es un tmpfs pequeno y un `.amod` de 22 MiB mas los ficheros
/// intermedios lo llenan.
String carpetaDeModulosDePrueba() {
  final base = Platform.environment['TMPDIR'] ?? '/tmp';
  final dir = Directory('$base/opencode-modulos-de-prueba');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir.path;
}

/// Un modulo real con otros terminos.
///
/// Devuelve la ruta del fichero creado. Los terminos se cambian **en la copia**, con
/// un `UPDATE` de la tabla `info`, que es la unica que se toca. La tabla `verses` no se
/// mira: por eso el modulo sigue teniendo sus 31.102 versiculos y Juan 3 sigue
/// teniendo 36, y la prueba puede comprobar que los terminos no han estropeado el
/// texto.
///
/// Y SI EL TERMINO NO EXISTIA, SE INSERTA. Un `UPDATE` de una fila que no esta no
/// cambia nada y lo da todo por hecho: el modulo se queda sin el termino y la
/// aplicacion lo enseena vacio, que es exactamente el fallo que la prueba quiere ver.
/// Por eso se mira `changes()` y, si es cero, se inserta.
String crearModuloConTerminos({
  required String licencia,
  String? licenciaEvidencia,
  String? atribucion,
  String? copyright,
  int defectsCount = 0,
  String? defects,
  String? versificacion,
  String nombre = 'modulo-de-prueba',
}) {
  final ruta = '${carpetaDeModulosDePrueba()}/$nombre.amod';
  final origen = rutaDeModuloReal(nombreModuloBiblia);

  final f = File(ruta);
  if (f.existsSync()) f.deleteSync();
  f.writeAsBytesSync(File(origen).readAsBytesSync(), flush: true);

  final db = sqlite3.open(ruta);
  try {
    void poner(String clave, String? valor) {
      if (valor == null) return;
      db.execute('UPDATE info SET value = ? WHERE key = ?', [valor, clave]);
      final cambiados = db.select('SELECT changes() AS n').first['n'];
      if ((cambiados as int) == 0) {
        db.execute('INSERT INTO info (key, value) VALUES (?, ?)', [clave, valor]);
      }
    }

    poner('license', licencia);
    poner('license_evidence', licenciaEvidencia);
    poner('attribution', atribucion);
    poner('copyright', copyright);
    poner('defects_count', '$defectsCount');
    poner('defects', defects);
    poner('versification', versificacion);
  } finally {
    db.close();
  }

  return ruta;
}

/// Los terminos tal como han quedado en un modulo de prueba.
///
/// Para comprobar, desde fuera, que los terminos se escribieron de verdad y no solo
/// que la pantalla los pinta. Una prueba que solo mira la pantalla puede pasar con un
/// modulo en el que el `UPDATE` no hizo nada y los terminos que se ven sean los del
/// original.
({String license, String defectsCount, String versification}) terminosDelModulo(
  String ruta,
) {
  final db = sqlite3.open(ruta, mode: OpenMode.readOnly);
  try {
    String de(String clave) => (db.select('SELECT value FROM info WHERE key = ?', [clave])
            .firstOrNull?['value'] as String? ??
        '');
    return (
      license: de('license'),
      defectsCount: de('defects_count'),
      versification: de('versification'),
    );
  } finally {
    db.close();
  }
}

/// Borra los modulos de prueba.
///
/// Va en un `tearDownAll` de cada prueba, y no en un `setUp`, para que los ficheros
/// se limpien aunque la prueba falle. Un `.amod` de 22 MiB por prueba que se queda en
/// el disco llenaria el tmpfs en una veinte de pruebas.
void borrarModulosDePrueba() {
  final dir = Directory(carpetaDeModulosDePrueba());
  if (!dir.existsSync()) return;
  for (final e in dir.listSync()) {
    try {
      e.deleteSync();
    } catch (_) {
      // Si no se puede borrar, se sigue. Un fichero que se queda es un problema de
      // disco del sistema, y hacer fallar la prueba por eso seria peor que dejar el
      // fichero.
    }
  }
}
