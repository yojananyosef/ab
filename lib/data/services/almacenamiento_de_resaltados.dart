// Donde viven los resaltados y las notas de la persona.
//
// ============================================================================
// POR QUE NO EN LAS PREFERENCIAS DEL SISTEMA
// ============================================================================
//
// `Preferencias` --`localStorage`-- es un almacen de **ajustes**. Son unos 5 MB, y lo que hay
// ahi se pierde **sin ningun aviso** en cuanto alguien borra los datos del sitio, que es lo que
// hace la gente cuando algo va mal en una web.
//
// Y un ajuste y el trabajo de una persona **no son la misma clase de dato**. `AGENTS.md` lo
// dice: lo que ha escrito la persona "no es un estado descartable". Un ajuste perdido son dos
// toques. Un resaltado perdido es trabajo.
//
// ============================================================================
// Y POR QUE UN ALMACEN PROPIO Y NO EL DE LOS MODULOS
// ============================================================================
//
// Por la misma razon, al reves: `AlmacenamientoDeModulos` guarda **bytes de otros** --el
// `.amod` y su sha256-- y este guarda **lo de la persona**. Mezclarlos haria que una de las
// pantallas del otro store, la que ofrece "borrar los modulos que no uso para ganar sitio",
// **se llevara por delante los resaltados**. Y eso es el fallo exacto que hay que evitar: una
// accion de limpieza de espacio que limpia tambien el trabajo.
//
// ============================================================================
// Y UN REGISTRO POR VERSICULO, NO UNA LISTA
// ============================================================================
//
// En web va a `IndexedDB`, que es donde ya vive lo que tiene que sobrevivir a cerrar el
// navegador, y con **una entrada por versiculo marcado** en vez de una lista que se reescribe
// entera.
//
// Y EL MOTIVO ES EL QUE CUESTA CUANDO SE APRENDE: reescribir una lista de mil resaltados por
// cada uno que se anade es el camino corto a perderlos. Si el guardado se corta a la mitad --
// una pestana cerrada, el movil sin bateria-- se pierden mil en vez de uno, y el que se ha
// marcado ultimo es justo el que no esta.
//
// ============================================================================
// Y EL PLAZO DE CINCO SEGUNDOS, QUE NO ES UN DETALLE DE ESTILO
// ============================================================================
//
// Y AQUI, **AL REVES** QUE CON LAS PREFERENCIAS, si no contesta **se avisa**. Lo que se ha
// perdido no son dos toques: es el trabajo de la persona. Y `docs/investigacion-ux.md` ya avisa
// de un caso medido: en el navegador, `indexedDB.open` puede quedarse esperando **para
// siempre**. Una pantalla colgada por leer resaltados es una pantalla colgada, y encima
// miente: si se dibuja la pantalla sin los resaltados y no se dice nada, la persona cree que
// no tiene ninguno marcado.

import 'dart:async';

import 'package:ab/domain/models/resaltado.dart';

/// Lo que devuelve el almacenamiento de resaltados.
class ResultadoDeResaltados {
  const ResultadoDeResaltados({
    this.resaltados = const <Resaltado>[],
    this.estilos = estilosDePartida,
    this.leido = false,
    this.motivo,
  });

  final List<Resaltado> resaltados;
  final List<EstiloDeResaltado> estilos;

  /// Si se han podido leer. **False** es "no se sabe", que no es lo mismo que "no hay".
  final bool leido;

  /// Por que no se han podido leer, en castellano, o null.
  final String? motivo;

  bool get ok => leido;

  /// Si **no** se han podido leer.
  ///
  /// Y ES UN `bool` PROPIO Y NO `!ok`, porque `ok` quiere decir "todo fue bien" y aqui lo
  /// que se pregunta es "hay que avisar". Un dia habra un caso que sea "todo fue bien y aun
  /// asi hay que avisar", y con `!ok` ese caso no se puede escribir.
  bool get hayQueAvisar => !leido;
}

/// Los resaltados de la persona.
///
/// Y LA INTERFAZ **NO** ES IGUAL A LA DE LOS MODULOS, a proposito: los modulos son bytes que se
/// descargan de otro sitio y estas son las cosas que ha escrito alguien. Que las dos superficies
/// se parezcan es un modo de confundirse luego: el codigo de uno acaba guardando en el sitio del otro.
abstract class AlmacenamientoDeResaltados {
  /// Los ids de versiculo que hay marcados.
  ///
  /// Y SOLO LOS IDS, y no los resaltados enteros, para pintar la lista **sin** abrir el
  /// almacen de cada versiculo. Que es lo mismo que hace el indice de los modulos con los
  /// sha256, y por el mismo motivo: leer 22 MiB para pintar una lista seria una burrada.
  Future<Set<String>> claves();

  /// El resaltado de un versiculo, o null si no esta marcado.
  Future<Resaltado?> de(String clave);

  /// Marca un versiculo. Pisar uno que ya lo esta cambia el estilo.
  Future<void> poner(Resaltado resaltado);

  /// Quita el resaltado de un versiculo. Si no habia ninguno, no pasa nada y no avisa.
  Future<void> quitar(String clave);

  /// Todos los resaltados, para exportar y para la pantalla de gestion.
  Future<List<Resaltado>> todos();

  /// Los estilos guardados, que empiezan siendo los de partida.
  Future<List<EstiloDeResaltado>> estilos();

  /// Cambia un estilo. Los resaltados que lo usan salen con el nombre y el color nuevos.
  Future<void> guardarEstilo(EstiloDeResaltado estilo);

  /// Borra todo lo de los resaltados. Con la palabra **borrar todo** en el nombre.
  ///
  /// Y NO `borrar`, porque `borrar` tambien es "quita un resaltado" y son cosas
  /// bien distintas. Un metodo que se llama igual para las dos es un metodo que alguien llama
  /// sin querer.
  Future<void> borrarTodo();

  void dispose();
}

/// En memoria, para pruebas.
///
/// Y CON EL **PLAZO** QUE NO CUMPLE NUNCA, y no: en memoria **contesta siempre**, y el caso de
/// "no contesta" se prueba con un doble que esta en su propio fichero, que es lo que hay que
/// para probar el aviso. Un doble que a veces cuelga hace que las pruebas que no lo Proven
/// fallen de vez en cuando, y un fallo que sale uno de cada veinte veces no se depura: se
/// vuelve a ejecutar.
class AlmacenamientoDeResaltadosEnMemoria implements AlmacenamientoDeResaltados {
  AlmacenamientoDeResaltadosEnMemoria([Map<String, Resaltado>? inicial])
      : _datos = <String, Resaltado>{...?inicial};

  final Map<String, Resaltado> _datos;
  List<EstiloDeResaltado> _estilos = List<EstiloDeResaltado>.of(estilosDePartida);

  @override
  Future<Set<String>> claves() async => _datos.keys.toSet();

  @override
  Future<Resaltado?> de(String clave) async => _datos[clave];

  @override
  Future<void> poner(Resaltado resaltado) async => _datos[resaltado.clave] = resaltado;

  @override
  Future<void> quitar(String clave) async => _datos.remove(clave);

  @override
  Future<List<Resaltado>> todos() async => _datos.values.toList();

  @override
  Future<List<EstiloDeResaltado>> estilos() async => _estilos;

  @override
  Future<void> guardarEstilo(EstiloDeResaltado estilo) async {
    final i = _estilos.indexWhere((EstiloDeResaltado e) => e.id == estilo.id);
    if (i < 0) {
      _estilos = <EstiloDeResaltado>[..._estilos, estilo];
    } else {
      _estilos = List<EstiloDeResaltado>.of(_estilos)..[i] = estilo;
    }
  }

  @override
  Future<void> borrarTodo() async {
    _datos.clear();
    _estilos = List<EstiloDeResaltado>.of(estilosDePartida);
  }

  @override
  void dispose() {}
}

/// Un almacen que **nunca** contesta, para probar el plazo y el aviso.
///
/// Y ES UN DOBLE DELIBERADAMENTE ROTO, y no una bandera en el almacen bueno: una bandera
/// obligaria a que cada prueba que usa el almacen buenoлоща tenga que acordarse de apagarla, y
/// la que se olvide cuelga la suite entera sin que se sepa por que.
class AlmacenamientoDeResaltadosQueNoContesta implements AlmacenamientoDeResaltados {
  Never _colgado() => throw UnimplementedError('este almacen no contesta, a proposito');

  @override
  Future<Set<String>> claves() => _colgado();

  @override
  Future<Resaltado?> de(String clave) => _colgado();

  @override
  Future<void> poner(Resaltado resaltado) => _colgado();

  @override
  Future<void> quitar(String clave) => _colgado();

  @override
  Future<List<Resaltado>> todos() => _colgado();

  @override
  Future<List<EstiloDeResaltado>> estilos() => _colgado();

  @override
  Future<void> guardarEstilo(EstiloDeResaltado estilo) => _colgado();

  @override
  Future<void> borrarTodo() => _colgado();

  @override
  void dispose() {}
}

/// El almacen que nunca contesta, pero **sin lanzar**, para que quien llama lo pueda probar.
///
/// Y LA DIFERENCIA CON [AlmacenamientoDeResaltadosQueNoContesta] ES IMPORTANTE Y ES EL MOTIVO DE
/// QUE EXISTAN LOS DOS: este devuelve una promesa que no resuelve **nunca**, y asi se puede
/// probar el `.timeout` de verdad. El otro lanza, y con el `.timeout` de por medio un `throw`
/// sincrono pasa por encima: el plazo solo se puede probar contra una promesa que se queda
/// esperando, que es lo que hace de verdad un almacenamiento que no contesta.
class AlmacenamientoDeResaltadosColgado implements AlmacenamientoDeResaltados {
  /// La promesa que no resuelve. Una sola, compartida, para que no se acumulen.
  final Completer<void> _colgado = Completer<void>();

  @override
  Future<Set<String>> claves() => _esperando();

  @override
  Future<Resaltado?> de(String clave) => _esperando();

  @override
  Future<void> poner(Resaltado resaltado) => _esperando();

  @override
  Future<void> quitar(String clave) => _esperando();

  @override
  Future<List<Resaltado>> todos() => _esperando();

  @override
  Future<List<EstiloDeResaltado>> estilos() => _esperando();

  @override
  Future<void> guardarEstilo(EstiloDeResaltado estilo) => _esperando();

  @override
  Future<void> borrarTodo() => _esperando();

  @override
  void dispose() {}

  Future<T> _esperando<T>() {
    // Y SE DEVUELVE LA PROMESA DEL `Completer` VACIO, no una que se resuelve con un valor: lo
    // que se quiere probar es que la llamada **se queda esperando**, y una promesa que se
    // resuelve ya no cuelga nada.
    _colgado.future.then((_) {});
    return Completer<T>().future;
  }
}

/// Lee los resaltados con un plazo, y devuelve un resultado en vez de colgar.
///
/// Y ES UNA FUNCION Y NO UN METODO DEL ALMACEN, porque el plazo es una **politica** --que aqui
/// son cinco segundos-- y una politica que esta en el almacenamiento se cambia tocando el
/// almacenamiento. Y porque el `.timeout` con `onTimeout` que devuelve un valor por defecto es
/// la unica forma de que el `catch` no haga falta: con `TimeoutException` habria que envolver
/// cada llamada.
Future<ResultadoDeResaltados> leerResaltadosConPlazo(
  AlmacenamientoDeResaltados almacen,
  Duration plazo,
) async {
  try {
    final resultado = await almacen.todos().timeout(plazo);
    final estilos = await almacen.estilos().timeout(plazo);
    return ResultadoDeResaltados(
      resaltados: resultado,
      estilos: estilos,
      leido: true,
    );
  } on TimeoutException {
    return const ResultadoDeResaltados(
      leido: false,
      motivo: 'No se han podido leer los resaltados. Puede que el almacenamiento del '
          'navegador no conteste.',
    );
  } catch (_) {
    // Y AQUI SI SE AVISA Y NO SE TRAGUELO. Es al reves que con una preferencia: lo que se ha
    // perdido no son dos toques.
    return const ResultadoDeResaltados(
      leido: false,
      motivo: 'No se han podido leer los resaltados.',
    );
  }
}

/// Los resaltados de un capitulo, en orden, con el estilo de cada uno.
///
/// Y SE FILTRA EN MEMORIA y no con una consulta por versiculo, porque el capitulo entero son
/// **36 filas** y el numero de resaltados de una persona es de miles: recorrer miles de
/// entradas por cada capitulo que se abre es lo que hace que el lector vaya lento sin que se note
/// por que.
List<Resaltado> resaltadosDelCapitulo(
  List<Resaltado> todos,
  String libro,
  int capitulo,
) {
  return todos
      .where((Resaltado r) => r.libro == libro && r.capitulo == capitulo)
      .toList()
    ..sort((Resaltado a, Resaltado b) => a.versiculo.compareTo(b.versiculo));
}

/// El estilo con ese identificador, o el primero si no existe.
///
/// Y **EL PRIMERO** Y NO "NINGUNO", y no por robustez: un resaltado con un estilo que no
/// existe tiene que **verse igual**, porque lo que se ha perdido es el color, no el resaltado.
/// Un resaltado invisible es peor que uno con el color equivocado, porque con el color
/// equivocado se ve que hay algo ahi y se puede arreglar; con el invisible no hay nada que
/// arreglar.
///
/// Y EL NOMBRE ES `estiloConEseId` Y NO `estiloDe`, y no porque quede mejor: `ResaltadosViewModel`
/// tiene un **metodo** que se llama `estiloDe`, y desde dentro de la clase el nombre sin
/// punto resuelve al metodo. La llamada `estiloDe(_estilos, r.estilo)` acababa intentando
/// llamar al metodo de tres argumentos con una lista y una cadena, y el analizador decia:
///
///     3 positional arguments expected by 'estiloDe', but 2 found
///
/// Que es un fallo que sale de un nombre repetido, y de los que se pierden veinte minutos.
EstiloDeResaltado estiloConEseId(
  List<EstiloDeResaltado> estilos,
  String id,
) {
  for (final e in estilos) {
    if (e.id == id) return e;
  }
  return estilos.isEmpty ? estilosDePartida.first : estilos.first;
}