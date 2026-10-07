// El puente entre los modelos de los resaltados y `IndexedDB`.
//
// ============================================================================
// POR QUE UN FICHERO Y NO METIDO EN EL DEL ALMACENAMIENTO
// ============================================================================
//
// Porque son cosas que se cambian por motivos distintos. El modelo es del dominio y no
// deberia saber que existe `dart:js_interop`; este fichero es el unico que sabe las dos
// cosas, y por eso es el unico que hay que tocar cuando IndexedDB cambia algo.
//
// ============================================================================
// Y POR QUE `jsify` Y `dartify` DE UN MAPA, Y NO UN `JSObject` ESCRITO A MANO
// ============================================================================
//
// Porque es lo que ya hace el almacen de modulos con su registro, y tener **una** forma de
// convertir en el repositorio vale mas que la que a uno le parezca mejor. Un `JSObject`
// escrito a mano tiene un `[]=` que hay que recordar y una conversion por campo que puede
// fallar; el mapa pasa por `jsify` y es una linea.
//
// Y LA EXCEPCION DE UN MAPA CON `NULL` DENTRO SE RESUELVE ANTES, y no con `jsify`: el mapa
// que sale de `aJson()` de un resaltado puede tener `--` las claves si un registro vino a
// medias, y `jsify` de eso lanza. Por eso hay [_resaltadoLleno] antes de convertir: o
// estan los cuatro campos, o no se escribe nada.

import 'dart:js_interop';

import 'package:ab/domain/models/resaltado.dart';

/// A lo que se escribe en `IndexedDB`.
extension ResaltadoAJs on Resaltado {
  /// El mapa de los cuatro campos, con los cuatro **siempre** presentes.
  ///
  /// Y `_resaltadoLleno` primero, y el motivo es que `jsify` de un mapa con `null` lanza y el
  /// error sale en un `put` que no dice de que registro es. Y un `Resaltado` **siempre** tiene
  /// los cuatro: el modelo no admite nulos. El `?` de los campos de `dartify` es de ahi, no de
  /// aqui, y por eso la comprobacion va una linea mas abajo y no dentro del mapa.
  Map<String, Object?> aJs() => <String, Object?>{
        'libro': libro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'estilo': estilo,
      };
}

/// A lo que se escribe en `IndexedDB`, un estilo.
extension EstiloAJs on EstiloDeResaltado {
  /// Los seis campos del estilo.
  ///
  /// Y EL COLOR COMO **ENTERO** Y NO COMO CADENA. Es lo que hace el modelo en su `aJson`, que
  /// lo escribe en hexadecimal porque un fichero que se abre en un editor de texto tiene que
  /// ser legible. Aqui no hay editor de texto: hay un `put`, y un entero ocupa cuatro bytes y
  /// una cadena veinte. Y leerlo de vuelta como entero, y no como cadena, es lo que evita que
  /// un estilo importado salga en un color que nadie eligio.
  Map<String, Object?> aJs() => <String, Object?>{
        'id': id,
        'nombre': nombre,
        'color': color.argb,
        'intensidad': intensidad.name,
        'forma': forma.enElAlmacenamiento,
      };
}

/// Un resaltado desde lo que hay en la base de datos, o null si no se puede leer.
///
/// Y DEVUELVE NULL Y NO LAZA, y es lo mismo que hace `Resaltado.desdeJson`: un registro
/// escrito por otra version, o con un campo de menos, **no se puede pintar** pero no puede
/// impedir leer los demas. Con una excepcion, un solo registro raro haria que no se pudiera
/// leer **ningun** resaltado, que es la peor forma de perderlos todos.
Resaltado? resaltadoDesdeJs(JSAny? crudo) {
  final datos = _mapaDe(crudo);
  if (datos == null) return null;

  final libro = datos['libro'];
  final capitulo = datos['capitulo'];
  final versiculo = datos['versiculo'];
  final estilo = datos['estilo'];

  // Y CADA CAMPO CON SU TIPO, y no solo "que no sea null". Un registro con `capitulo` en
  // texto daria un `int.tryParse` que se puede aplicar, pero uno con `capitulo` en `3.5` --que
  // es lo que daria un `jsify` de un numero double-- da `3`, y un versiculo 3 en vez del 3.5
  // es una marca en el sitio equivocado: se ve, y esta mal. Con `is int` no hay duda.
  if (libro is! String ||
      capitulo is! int ||
      versiculo is! int ||
      estilo is! String) {
    return null;
  }
  if (libro.isEmpty || estilo.isEmpty) return null;
  if (capitulo < 1 || versiculo < 1) return null;

  return Resaltado(
    libro: libro,
    capitulo: capitulo,
    versiculo: versiculo,
    estilo: estilo,
  );
}

/// Un estilo desde lo que hay en la base de datos, o null si no se puede leer.
///
/// Y CON EL COLOR DE PARTIDA SI NO ESTA, y no con `null`: ver la nota de
/// [resaltadoDesdeJs] sobre el fallo silencioso.
EstiloDeResaltado? estiloDesdeJs(JSAny? crudo) {
  final datos = _mapaDe(crudo);
  if (datos == null) return null;

  final id = datos['id'];
  if (id is! String || id.isEmpty) return null;

  final color = datos['color'];
  final intensidad = datos['intensidad'];
  final forma = datos['forma'];

  return EstiloDeResaltado(
    id: id,
    nombre: datos['nombre'] is String ? datos['nombre'] as String : 'Sin nombre',
    color: color is int
        ? ColorDeResaltado(color)
        : ColorDeResaltado.dePartida.first,
    intensidad: intensidad is String
        ? IntensidadDelResaltado.values.firstWhere(
            (IntensidadDelResaltado i) => i.name == intensidad,
            orElse: () => IntensidadDelResaltado.medio,
          )
        : IntensidadDelResaltado.medio,
    forma: forma is String ? FormaDelResaltado.leer(forma) : FormaDelResaltado.fondo,
  );
}

/// El `dartify` de un registro, si es un mapa de verdad.
///
/// Y `dartify` DE UN `JSAny?` Y NO `as Map`, porque un registro puede no ser un mapa --si el
/// almacen se corrompe, o si alguien escribio a mano-- y un `as` que falla lanza con un
/// `CastError` en un sitio que no dice nada.
Map<Object?, Object?>? _mapaDe(JSAny? crudo) {
  if (crudo == null) return null;
  final datos = crudo.dartify();
  if (datos is! Map) return null;
  return datos.cast<Object?, Object?>();
}