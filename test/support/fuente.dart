// Una fuente de verdad para poder medir.
//
// ============================================================================
// POR QUE ESTO HACE FALTA Y NO ES UN ADORNO
// ============================================================================
//
// En `flutter test` **todas las letras miden lo mismo**: el motor de pruebas pinta
// cada glifo como un cuadrado del tamano de la fuente, asi que la "a" y la "m" miden
// las dos lo mismo. Con esa fuente, medir el ancho de una frase y dividirlo entre sus
// caracteres da exactamente `tamanoDeLetra * 90`, y la columna de 90 caracteres sale
// de 1440 px a 16 px.
//
// Con eso, la tarea 7.7 --"a 1440 px el ancho de la columna no supera el limite"--
// es **imposible de comprobar**: el limite mide 1440 y la pantalla menos los margenes
// mide 1392, asi que siempre manda la pantalla y la comprobacion daria verde sin
// comprobar nada. Y la comprobacion de que dos letras distintas miden distinto, que
// es la que demuestra que se esta midiendo el ancho de las letras y no el numero de
// caracteres, daria falsa.
//
// O sea: sin una fuente proporcional, estas pruebas darian verde sin medir. Con
// Roboto --la misma familia que trae el SDK-- miden de verdad.
//
// Y LA FUENTE NO SE COPIA AL REPOSITORIO. Es un binario de 171.676 bytes y el
// repositorio ya decidio que los ficheros binarios de prueba no se versionan --los
// modulos reales se bajan con `scripts/preparar-fixtures.sh`--. Ademas esta fuente
// viene del SDK que ejecuta la prueba, con lo que si el SDK cambia, la fuente cambia
// tambien y no puede quedarse vieja sin que nadie se entere.
//
// SI NO SE ENCUENTRA, LA PRUEBA SE SALTA Y LO DICE. Un "skip" callado es un fallo
// escondido; un "skip" con el motivo puesto es informacion. Y el motivo es real: sin
// el SDK de Flutter al lado no hay fuente que cargar, y entonces estas medidas
// serian numeros inventados que darian verde.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// El nombre con el que se registra la fuente de pruebas.
///
/// No es 'Roboto' porque ese nombre ya lo trae el SDK: registrar otra fuente con el
/// mismo nombre **no** la sustituye, se queda la primera, y entonces las medidas
/// serian las de la fuente del SDK y no las de la de pruebas, sin que se note. Con un
/// nombre propio, cargar la fuente es cargar la fuente.
const String kFamiliaDePrueba = 'AbPrueba';

/// La ruta del fichero de la fuente, o null si no se encuentra.
///
/// Se busca por `FLUTTER_ROOT`, que el motor de pruebas pone en el entorno, y si no
/// esta se deduce del ejecutable: `flutter_tester` cuelga de `cache/artifacts/engine`
/// y la fuente de `cache/artifacts/material_fonts`. Los dos caminos se prueban
/// porque `FLUTTER_ROOT` no esta en todas las versiones del SDK.
String? rutaDeLaFuenteDePrueba() {
  final entorno = Platform.environment['FLUTTER_ROOT'];
  final raices = <String>[
    ?entorno,
    File(Platform.resolvedExecutable).parent.parent.parent.parent.path,
  ];

  for (final raiz in raices) {
    final f = File('$raiz/artifacts/material_fonts/Roboto-Regular.ttf');
    if (f.existsSync()) return f.path;
  }
  return null;
}

/// Carga la fuente de pruebas y la deja lista para medir.
///
/// Devuelve `false` si no se pudo, y entonces las pruebas que necesitan medir
/// saltan. Devolver un bool y no lanzar es a proposito: la fuente que falta es un
/// problema del entorno, y un problema del entorno no puede hacer fallar a la suite.
Future<bool> cargarLaFuenteDePrueba() async {
  final ruta = rutaDeLaFuenteDePrueba();
  if (ruta == null) return false;

  final cargador = FontLoader(kFamiliaDePrueba)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
  return true;
}

/// El motivo por el que una prueba de medida salta, si salta.
///
/// Va en un sitio para que el texto sea el mismo en todas y se pueda buscar.
const String _motivoSinFuente =
    'No se encuentra la fuente del SDK, asi que las medidas serian de la fuente de '
    'pruebas --donde todas las letras miden lo mismo-- y darian verde sin medir nada. '
    'Se necesita "artifacts/material_fonts/Roboto-Regular.ttf" en el SDK de Flutter.';

/// Salta la prueba si no hay fuente de verdad.
///
/// Y USA [markTestSkipped] Y NO UNA ASERCION FALLA, porque lo que falla es el
/// entorno de pruebas, no el codigo. Con una asercion, un `flutter test` en un
/// contenedor sin las fuentes de material seria un rojo que no significa nada y que
// alguien acabaria ignorando.
void saltarSiNoHayFuente() {
  markTestSkipped(_motivoSinFuente);
}
