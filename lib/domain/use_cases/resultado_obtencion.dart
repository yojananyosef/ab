// Que paso al intentar obtener un modulo.
//
// Un tipo por cada final, porque cada uno pide una cosa distinta a la pantalla.
// Un solo `bool ok` con un mensaje obliga a que quien recibe adivine el motivo, y
// adivinar el motivo es como se acaba ensenando "error de red" cuando lo que
// pasa es que el servidor no deja leerlo desde el navegador, que es un problema
// distinto con una solucion distinta.

/// Lo que ha pasado, en detalle.
sealed class ResultadoObtencion {
  const ResultadoObtencion();
}

/// Salio bien. Los bytes estan en memoria y el hash cuadra.
class Obtenido extends ResultadoObtencion {
  const Obtenido({required this.bytes, required this.bytesTotales});

  final List<int> bytes;

  /// Cuantos bytes **decia** el catalogo. Null si nadie lo dijo.
  final int? bytesTotales;
}

/// No se ha podido leer porque el origen no responde a una peticion de otro
/// origen. Que es distinto de estar caido, y la solucion es distinta: un espejo
/// o un fichero local, no reintentar.
///
/// El sintoma en el navegador es `Failed to fetch`, que no dice nada. Por eso
/// hace falta un estado propio en vez de un error generico.
class OrigenNoLegible extends ResultadoObtencion {
  const OrigenNoLegible();

  @override
  String toString() =>
      'el servidor no deja leerlo desde el navegador (sin cabecera de origen cruzado)';
}

/// El servidor no esta. Se ha agotado el numero de intentos.
class OrigenCaido extends ResultadoObtencion {
  const OrigenCaido({required this.intentos, this.ultimoError});

  final int intentos;
  final Object? ultimoError;
}

/// Se han bajada algunos bytes pero no todos.
class DescargaIncompleta extends ResultadoObtencion {
  const DescargaIncompleta({required this.recibidos, required this.esperados});

  final int recibidos;
  final int esperados;
}

/// Los bytes llegaron pero **no son los que dice el catalogo**. No se abren.
///
/// Esto es el fallo que importa: un `.amod` con un byte cambiado abriria
/// perfectamente y daria versiculos casi correctos, y nadie se enteraria. Por eso
/// la comprobacion es antes de abrir, y no despues.
class HashIncorrecto extends ResultadoObtencion {
  const HashIncorrecto({required this.esperado, required this.obtenido});

  final String esperado;
  final String obtenido;
}

/// La persona ha cancelado. No es un fallo: es una decision suya.
class Cancelado extends ResultadoObtencion {
  const Cancelado();
}

/// Hay una version nueva: el hash del catalogo es distinto del que tiene el
/// fichero en el dispositivo. Se devuelve el viejo, que **se sigue leyendo**: un
/// modulo descargado no deja de ser legible por estar atrasado.
class HayVersionNueva extends ResultadoObtencion {
  const HayVersionNueva(this.bytesViejos);

  final List<int> bytesViejos;
}

/// Fallo que no encaja en ningun caso anterior. Se escribe, no se esconde.
class FalloInesperado extends ResultadoObtencion {
  const FalloInesperado(this.error);
  final Object error;
}

/// Como se cuenta en pantalla. Un texto por estado, y nunca "error".
String descripcionDe(ResultadoObtencion r) => switch (r) {
  Obtenido(:final bytesTotales) => bytesTotales == null
      ? 'Descargado'
      : 'Descargado, $bytesTotales bytes',
  OrigenNoLegible() =>
    'El servidor no permite leerlo desde el navegador. Se puede abrir un '
        'fichero local.',
  OrigenCaido(:final intentos) =>
    'No se ha podido contactar con el servidor despues de $intentos intentos.',
  DescargaIncompleta(:final recibidos, :final esperados) =>
    'Se han bajado $recibidos de $esperados bytes. Se puede reintentar.',
  HashIncorrecto(:final esperado, :final obtenido) =>
    'El fichero no es el que dice el catalogo. Se esperaba $esperado y se ha '
        'obtenido $obtenido.',
  Cancelado() => 'Descarga cancelada.',
  HayVersionNueva() => 'Hay una version nueva. Se sigue leyendo la anterior.',
  FalloInesperado() => 'Algo ha ido mal al obtener el modulo.',
};
