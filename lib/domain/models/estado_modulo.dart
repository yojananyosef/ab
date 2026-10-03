// En que estado esta un modulo.
//
// LA REGLA IMPORTANTE: el estado **no se guarda**. Se calcula, cada vez, de
// comparar tres cosas: lo que declara el manifiesto, lo que hay en el
// dispositivo y que hash tiene cada uno.
//
// Por que no se guarda. El fallo de MyBible del 25 de agosto de 2024, que
// dejo de descargar para todo el mundo, fue de metadatos mal guardados. Y hay un
// caso concreto y facil de ver: su app, al quedarse sin conexion,
// **reclasificaba todos los modulos** como "solo local", incluidos los que
// nunca se habian descargado. Un estado guardado se queda viejo, y un estado
// viejo es justo lo que hace que la app mienta sin querer.
//
// Los mismos tres estados que documenta MyBible, mas uno que hace falta y uno
// que sobra. "Solo local" **no** se usa: lo que no se ha descargado no se ha
// descargado, y se ve en el catalogo, no en la biblioteca.

/// Estado de un modulo, calculado, nunca persistido.
enum EstadoModulo {
  /// En el catalogo, no en el dispositivo. Se puede descargar.
  disponible('Disponible'),

  /// Trayendose ahora mismo.
  descargando('Descargando'),

  /// En el dispositivo y su hash coincide con el del manifiesto.
  descargado('Descargado'),

  /// En el dispositivo, pero el manifiesto declara otro hash: hay version nueva.
  desactualizado('Hay version nueva'),

  /// En el dispositivo y **ya no esta en el catalogo**. Se sigue leyendo.
  retirado('Retirado del catalogo');

  const EstadoModulo(this.texto);

  /// Como lo ve la persona. Texto, no solo color: un estado que solo se
  /// distingue por el color no lo lee quien tiene baja vision o una pantalla
  /// en escala de grises.
  final String texto;
}

/// Que sabe el dispositivo de un modulo.
///
/// Deliberadamente minimo. Si anadimos un campo mas, aparece un sitio mas donde
/// puede quedar viejo, y eso es justo lo que este diseno evita.
class EstadoEnDispositivo {
  const EstadoEnDispositivo({required this.hayFichero, this.sha256Guardado});

  /// No hay nada en el dispositivo.
  const EstadoEnDispositivo.ausente()
    : hayFichero = false,
      sha256Guardado = null;

  /// Esta el fichero, con este hash. El hash es el que **calculamos al
  /// obtenerlo**, no el que el manifiesto dice.
  const EstadoEnDispositivo.presente(this.sha256Guardado) : hayFichero = true;

  final bool hayFichero;
  final String? sha256Guardado;

  bool get presente => hayFichero;
}

/// Calcula el estado. Funcion pura: mismos datos, mismo estado, siempre.
///
/// Que sea pura no es purismo, es lo que hace que sea comprobable: una prueba
/// puede dar los mismos datos y exigir el mismo estado, sin montar una app.
EstadoModulo calcularEstado({
  required String sha256DelCatalogo,
  required EstadoEnDispositivo enDispositivo,
  required bool descargando,
  /// False cuando el modulo ya no aparece en el manifiesto. Solo importa si el
  /// modulo esta en el dispositivo.
  required bool estaEnElCatalogo,
}) {
  if (descargando) return EstadoModulo.descargando;

  if (!enDispositivo.presente) {
    // No esta en el dispositivo. Solo puede estar disponible, y si el manifiesto
    // lo retiro ya no hay nada que hacer con el, asi que no se ensena. Se
    // descarta aqui y en ningun otro sitio.
    return EstadoModulo.disponible;
  }

  if (!estaEnElCatalogo) return EstadoModulo.retirado;

  // Esta en el dispositivo. El hash guardado es el que se calculo al obtenerlo,
  // y el del catalogo es el que declara el manifiesto ahora. Si no son el mismo,
  // hay version nueva: el modulo viejo **sigue siendo legible**, y por eso el
  // estado no es un error.
  return enDispositivo.sha256Guardado == sha256DelCatalogo
      ? EstadoModulo.descargado
      : EstadoModulo.desactualizado;
}
