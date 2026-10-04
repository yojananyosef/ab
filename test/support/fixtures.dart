// Donde estan los modulos reales que usan las pruebas.
//
// UN SOLO SITIO. Las cuatro pruebas que necesitan un `.amod` de verdad piden aqui
// la ruta, y no llevan una ruta escrita. La version anterior llevaba
// `/home/j/aa/modules/build/...` repetido en cuatro ficheros, y eso rompio el CI
// entero sin que ninguna prueba fallara de forma util: en un runner de GitHub
// Actions esa ruta no existe, y lo que se veia era un fallo de pruebas que no
// decia nada de su causa.
//
// Un `.amod` de verdad, y no uno de diez filas, porque un fichero pequeño pasaria
// aunque el formato real tuviera algo que no se ve con diez filas. Y con un hash
// de verdad, porque lo que se comprueba es que el codigo detecta cuando el hash
// no cuadra.
//
// DE DONDE VIENEN. De `scripts/preparar-fixtures.sh`, que los baja del sitio
// publicado y **comprueba su sha256 contra el manifiesto antes de usarlos**. No se
// versionan: son 79 MiB, y fijarlos haria que las pruebas comprobaran una version
// vieja en vez de lo que se publica hoy.
//
// SI NO ESTAN, ESTAS PRUEBAS FALLAN. No se saltan. Una prueba que se salta no
// verifica nada, y una suite donde media parte se salta en el sitio donde mas
// importa es una suite que da verde sin comprobar. El mensaje dice exactamente que
// ejecutar, para que quien lo vea no tenga que buscarlo.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El modulo de Biblia, de 22.544.384 bytes y sus 31.102 versiculos.
const String nombreModuloBiblia = 'KJV2006_bible.amod';

/// El comentario, de 57.536.512 bytes y sus 19.742 notas.
const String nombreModuloComentario = 'CLARKE_commentary.amod';

/// Los sha256 de los dos, medidos y verificados contra el manifiesto publicado.
const String sha256Biblia =
    'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
const String sha256Comentario =
    '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c';

/// Los tamanos de los dos, en bytes.
const int tamanoBiblia = 22544384;
const int tamanoComentario = 57536512;

/// Donde se buscan. Se puede cambiar con `AB_FIXTURES`, que es lo que hace el
/// script cuando se le pasa otro destino.
String get carpetaDeFixtures =>
    Platform.environment['AB_FIXTURES'] ?? 'test/fixtures';

/// La ruta de un modulo real, y **falla** si no esta.
///
/// Falla y no devuelve null porque todas las pruebas que lo usan necesitan el
/// fichero, y una de esas es precisamente la que comprueba que el hash no cuadra
/// cuando tiene que no cuadrar. Si el fichero no esta, esa prueba no tiene nada
/// que comprobar, y seguir sin avisar es como se pierde.
String rutaDeModuloReal(String nombre) {
  final ruta = '$carpetaDeFixtures/$nombre';
  if (!File(ruta).existsSync()) {
    fail(
      'falta el modulo real "$nombre" en $carpetaDeFixtures, y sin el las pruebas '
      'de este grupo no verifican nada.\n\n'
      ' Bajalo con:\n\n'
      '     bash scripts/preparar-fixtures.sh\n\n'
      'El script lo baja del sitio publicado y comprueba su sha256 contra el '
      'manifiesto antes de dejarlo. Sin ese paso, estas pruebas comprobarian un '
      'fichero cualquiera, que es peor que no comprobarlas.',
    );
  }
  return ruta;
}

/// Ruta de la Biblia real.
String get rutaBibliaReal => rutaDeModuloReal(nombreModuloBiblia);

/// Ruta del comentario real.
String get rutaComentarioReal => rutaDeModuloReal(nombreModuloComentario);
