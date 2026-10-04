// Donde vive un `.amod` una vez descargado.
//
// LA IDEA DE ESTE FICHERO, Y POR QUE SON DOS OPERACIONES. SQLite abre de forma
// **sincrona**: `open(ruta)` no se puede esperar. IndexedDB y el disco son
// **asincronos**. De ahi la paradoja: para abrir un modulo hay que tener sus bytes
// ya en el sitio donde SQLite los ve, y ese sitio no se puede rellenar
// esperando.
//
// La solucion son dos operaciones con nombres distintos:
//
//  1. [ponerEnMemoria] es **sincrona** y devuelve una ruta que ya sirve. En web
//     mete los bytes en el sistema de ficheros virtual, que es lo que SQLite ve;
//     en nativo devuelve la ruta del fichero, que ya esta en disco.
//  2. [persistir] es **asincrona** y vuelca aIndexedDB en web, o al fichero en
//     nativo. Se espera cuando se quiere, y no se espera nunca para poder leer.
//
// El orden importa: primero (1), que es lo que permite leer, y despues (2), que es
// lo que permite no volver a bajar. Al reves no se puede abrir nada.
//
// QUE SE LEE AL VOLVER. [rutaDe] devuelve la ruta si el modulo esta, sin traer
// ningun byte de la red. Si esta en la memoria de esta sesion, es directo; si solo
// esta en el almacenamiento, lo lee, lo pone en memoria y devuelve la ruta. Esa
// ultima parte es la que hace que la segunda visita al sitio no baje 22 MiB.
//
// LO QUE NO SE ESCRIBE AQUI. Ningun estado, ningun "ultima vez abierto", ninguna
// lista de favoritos. Aqui solo hay bytes de modulos. Un estado guardado se queda
// viejo, y un estado viejo hace que la app mienta sin querer.

import 'dart:typed_data';

import 'almacenamiento_de_modulos_nativo.dart'
    if (dart.library.js_interop) 'almacenamiento_de_modulos_web.dart'
    as impl;

/// Un modulo guardado. Con solo la ruta y el tamano, no con el contenido.
///
/// Sin el contenido a proposito: [rutaDe] es lo que se llama al arrancar, y si
/// devolviera los bytes habria que traer 57 MiB a memoria para saber que estan
/// ahi. Y truerlos sin abrirlos es tirar la memoria justo para pintar una lista.
class ModuloGuardado {
  const ModuloGuardado({required this.id, required this.ruta, required this.tamanoBytes});

  final String id;

  /// Lo que se pasa a `Sqlite.abrir`. En web es una ruta del sistema de ficheros
  /// virtual; en nativo, una ruta de disco.
  final String ruta;

  final int tamanoBytes;

  @override
  String toString() => 'ModuloGuardado($id, $tamanoBytes bytes, $ruta)';
}

/// Cuanto cabe todavia, o null si la plataforma no lo dice.
class Espacio {
  const Espacio({required this.cuota, required this.usado});

  /// Bytes que el navegador dice que hay en total. Null si no lo dice.
  final int? cuota;

  /// Bytes que ya ocupa el origen.
  final int? usado;

  /// Lo que queda, o null si no se sabe.
  ///
  /// Null y no cero cuando no hay dato: "no lo sé" y "no cabe" llevan a decisiones
  /// distintas, y confundirlos es como se acaba negando una descarga que si cabia.
  int? get disponible {
    final c = cuota;
    if (c == null) return null;
    return c - (usado ?? 0);
  }

  /// Si [necesarios] caben.
  ///
  /// [margen] es un porcentaje que se deja libre a proposito. Pedir todo el hueco
  /// disponible es acabar con el navegador sin margen y que falle la escritura al
  /// final, cuando ya no hay nada que hacer: mejor decirlo antes.
  bool cabe(int necesarios, {double margen = 0.1}) {
    final d = disponible;
    if (d == null) return true; // No se sabe: se intenta y se informa si falla.
    return necesarios <= d * (1 - margen);
  }
}

/// El resultado de intentar guardar un modulo.
sealed class ResultadoDeGuardar {
  const ResultadoDeGuardar();
}

/// Se ha guardado y se puede abrir.
class Guardado extends ResultadoDeGuardar {
  const Guardado(this.modulo);
  final ModuloGuardado modulo;
}

/// **No cabe**, y se dice con palabras.
///
/// ES UN RESULTADO DE PRIMERA CLASE, NO UN FALLO SILENCIOSO. El navegador dice
/// cuanto queda con `navigator.storage.estimate()`, y si un modulo de 57 MiB no
/// cabe, lo unico util es decirlo: "no cabe, ocupa 54,9 MiB y quedan 12,0". Un
/// `catch` que se come la excepcion deja al usuario mirando una descarga que se
/// queda al 90 por ciento sin ninguna explicacion, que es la forma mas rapida de
/// que alguien piense que la app esta rota.
///
/// Y ESTE RESULTADO NO IMPIDE LEER. Un modulo que no se ha podido guardar **se
/// sigue pudiendo abrir** en esta sesion, porque los bytes estan en memoria. Solo
/// se pierde poder leerlo en la proxima. Esa distincion es la que evita que "no me
/// cabe" se convierta en "no puedo leer".
class NoCabe extends ResultadoDeGuardar {
  const NoCabe({required this.tamanoNecesario, required this.disponible, this.cuota});

  final int tamanoNecesario;

  /// Cuanto queda. Null si el navegador no lo dijo.
  final int? disponible;

  final int? cuota;

  /// El texto que se ensena. Con las cifras dentro, porque "no cabe" sin numeros
  /// no permite decidir: se puede borrar otra cosa, o no.
  String get texto => disponible == null
      ? 'No se ha podido comprobar si cabe, y no se ha podido guardar. '
          'El texto se puede leer mientras esta abierta la app.'
      : 'Este modulo ocupa ${_mib(tamanoNecesario)} y ahora mismo solo quedan '
          '${_mib(disponible!)}. Se puede leer ahora, pero no se guardara para '
          'otra vez.';
}

/// Se ha podido meter en memoria pero **no** en el almacenamiento.
///
/// Se distingue de [NoCabe] porque aqui el problema no es el tamano, y la
/// solucion tampoco: puede ser que el navegador este en modo privado, o que haya
/// fallado el disco. Decir "no cabe" cuando lo que pasa es "el disco fallo"
/// manda a la gente a borrar cosas que no tienen nada que ver.
class FalloAlPersistir extends ResultadoDeGuardar {
  const FalloAlPersistir(this.motivo);
  final String motivo;

  String get texto => 'Se puede leer, pero no se ha podido guardar para otra vez: $motivo';
}

/// La superficie que usan el resto de la app.
///
/// Sin estado, con las dos implementaciones separadas por plataforma. Quien lo
/// usa no sabe donde esta los bytes.
abstract class AlmacenamientoDeModulos {
  /// Mete los bytes donde SQLite puede verlos **ya**, y devuelve la ruta.
  ///
  /// Es **sincrona** y por eso no se espera. Devuelve una ruta que sirve
  /// inmediatamente, y el volcado persistente es [persistir].
  ///
  /// En web deja los bytes en el sistema de ficheros virtual, que son 57 MiB en
  /// memoria: es el precio de que SQLite sea sincrono, y ya se pagaba antes de
  /// esto porque los bytes venian ahi. No es un coste nuevo.
  String ponerEnMemoria(String id, List<int> bytes);

  /// Vuelca a almacenamiento que sobreviva a cerrar la app.
  ///
  /// Devuelve lo que ha pasado para que la pantalla lo diga. Que devuelva un
  /// resultado y no un error es lo que permite enseñar "no cabe, ocupa tanto" en
  /// vez de tragarselo.
  Future<ResultadoDeGuardar> persistir(String id, List<int> bytes);

  /// La ruta del modulo guardado, o null si no esta.
  ///
  /// Sin traer bytes de la red: si esta en la memoria de esta sesion, es directo;
  /// si solo esta en el almacenamiento, lo lee y lo pone en memoria.
  Future<ModuloGuardado?> rutaDe(String id);

  /// Los ids que hay guardados. Para pintar la biblioteca sin abrir nada.
  Future<List<String>> ids();

  /// Borra un modulo. Sin esto, el comentario de 57 MiB se queda para siempre
  /// ocupando sitio sin que nadie pueda quitarlo.
  Future<void> borrar(String id);

  /// Cuanto queda, o null si la plataforma no lo dice.
  Future<Espacio?> espacio();

  void dispose();
}

/// Bytes en MiB con un decimal, como se ensena.
String _mib(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';

/// Una copia de los bytes como `Uint8List`, sin copiar si ya lo es.
///
/// Se usa al volcar: `IndexedDB` y `File.writeAsBytes` aceptan listas de enteros,
/// pero si lo que tienen es un `Uint8List` se puede pasar tal cual y evitar una
/// copia de 57 MiB en un momento en que ya hay 57 MiB en memoria.
Uint8List comoBytes(List<int> bytes) =>
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

/// Crea el almacenamiento de la plataforma.
///
/// UN SOLO PUNTO DE ENTRADA Y DOS FICHEROS. Hay exactamente dos formas de guardar
/// 57 MiB segun donde se corra: un fichero en disco o IndexedDB. Si aparece una
/// tercera plataforma, se anade aqui y en ningun otro sitio.
///
/// Y el que se crea no guarda ningun estado: se crea al arrancar y se tira al
/// cerrar. Que el sistema de ficheros virtual se registre otra vez es correcto,
/// porque es global al proceso.
AlmacenamientoDeModulos crearAlmacenamientoDeModulos() => impl.crearAlmacenamiento();
