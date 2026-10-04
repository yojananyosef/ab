// Donde viven los modulos en nativo: un fichero.
//
// Uno de los dos ficheros que saben en que plataforma estamos.
//
// Y AQUI NO HAY PARADOJA. En nativo el fichero del disco es a la vez el sitio donde
// estan los bytes y el que SQLite abre, y [Sqlite.abrir] lo abre de forma sincrona
// sin problema. Asi que no hace falta el sistema de ficheros virtual ni partir el
// guardado en dos operaciones: se escribe el fichero y ya esta.
//
// Aun asi la interfaz sigue siendo la misma, y con las mismas dos operaciones. La
// razon es que **quien lo usa no debe saber donde esta**: si el metodo
// [ponerEnMemoria] devolviera algo distinto en nativo y en web, cada pantalla
// tendria que preguntar en que plataforma esta, y eso se propaga a todas partes.
//
// EL NOMBRE DEL FICHERO. Es `<id>.amod`, con el `id` que viene del manifiesto. Se
// usa a proposito y no el `sha256`: el `sha256` tiene 64 caracteres y algunos
// sistemas de ficheros de Windows siguen teniendo un limite de 260 caracteres en la
// ruta completa, que con un directorio de usuario largo se puede pasar. Y el `id`
// es lo que la gente reconoce.
//
// Y NO SE COMPRUEBA NADA AL ESCRIBIR. El hash ya se ha comprobado en la
// obtencion, antes de llegar aqui. Volver a comprobarlo seria correcto y
// completamente innecesario: son 57 MiB de lectura otra vez para obtener una
// respuesta que ya se tiene.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'almacenamiento_de_modulos.dart';

/// Subdirectorio dentro del directorio de la app. Uno solo y con nombre fijo.
const String subdirectorioDeModulos = 'modulos';

class AlmacenamientoDeModulosNativo implements AlmacenamientoDeModulos {
  AlmacenamientoDeModulosNativo({this.subdirectorio = subdirectorioDeModulos});

  /// Se puede cambiar en las pruebas y para instalar en otro sitio.
  final String subdirectorio;

  Directory? _directorio;

  /// El directorio donde se guardan, o null si no se ha podido obtener.
  Future<Directory?> directorio() async {
    final ya = _directorio;
    if (ya != null) return ya;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/$subdirectorio');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _directorio = dir;
      return dir;
    } catch (_) {
      // Un directorio que no se puede crear es una app que no puede guardar
      // nada, pero no una app que no arranca. Se devuelve null y el resultado
      // dice "no se ha podido guardar", que la pantalla enseña. Propagar el error
      // dejaria la app sin arranque, que es peor que perder el modo sin conexion.
      return null;
    }
  }

  String _nombreDe(String id) => '$id.amod';

  @override
  String ponerEnMemoria(String id, List<int> bytes) {
    // En nativo no hay nada que poner en memoria: el fichero es el sitio. Se
    // devuelve la ruta prevista aunque todavia no exista, que es lo que permite
    // llamar a esta antes de [persistir] sin tener que esperar.
    return '$subdirectorio/${_nombreDe(id)}';
  }

  @override
  Future<ResultadoDeGuardar> persistir(String id, List<int> bytes) async {
    final dir = await directorio();
    if (dir == null) {
      return const FalloAlPersistir('no se ha podido crear la carpeta de los modulos.');
    }

    final destino = File('${dir.path}/${_nombreDe(id)}');
    final contenido = comoBytes(bytes);
    try {
      // A un FICHERO TEMPORAL y despues `rename`. Escribir directamente en el
      // destino deja medio modulo si la app se cierra a mitad, y un `.amod` a
      // medias es peor que ninguno: ocupa 22 MiB, no se abre, y parece que hay una
      // Biblia guardada.
      final parcial = File('${destino.path}.parcial');
      await parcial.writeAsBytes(contenido, flush: true);
      await parcial.rename(destino.path);

      return Guardado(
        ModuloGuardado(id: id, ruta: destino.path, tamanoBytes: contenido.length),
      );
    } catch (_) {
      // Un error aqui es casi siempre "no hay sitio en disco". En nativo no se
      // puede preguntar la cuota antes --no hay API para eso, o no la hay todavia--,
      // asi que el unico sitio donde se puede decir "no cabe, con estas cifras" es
      // aqui, con el error delante. Y se distingue del fallo de otros porque el
      // texto es distinto: "el disco" no es "el navegador no deja guardar", y no
      // son la misma cosa ni la misma solucion.
      return const FalloAlPersistir('el disco no ha dejado guardar el modulo.');
    }
  }

  @override
  Future<ModuloGuardado?> rutaDe(String id) async {
    final dir = await directorio();
    if (dir == null) return null;
    final f = File('${dir.path}/${_nombreDe(id)}');
    if (!f.existsSync()) return null;
    try {
      return ModuloGuardado(
        id: id,
        ruta: f.path,
        tamanoBytes: f.lengthSync(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> ids() async {
    final dir = await directorio();
    if (dir == null) return const <String>[];
    try {
      final salida = <String>[];
      for (final e in dir.listSync()) {
        if (e is! File) continue;
        final nombre = e.uri.pathSegments.last;
        if (!nombre.endsWith('.amod')) continue;
        // Los `.parcial` NO se cuentan. Son restos de una escritura a medias, y
        // aparecer como un modulo guardado seria mentira: la biblioteca diria que
        // hay una Biblia y al abrirla no habria nada.
        salida.add(nombre.substring(0, nombre.length - 5));
      }
      return salida;
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Future<void> borrar(String id) async {
    final dir = await directorio();
    if (dir == null) return;
    try {
      final f = File('${dir.path}/${_nombreDe(id)}');
      if (f.existsSync()) f.deleteSync();
    } catch (_) {
      // Borrar que falla no se puede propagar sin dejar a la persona sin salida:
      // si el comentario de 57 MiB se queda y no se puede quitar, ya no puede
      // hacer nada por su cuenta.
    }
  }

  @override
  Future<Espacio?> espacio() async {
    // En nativo no hay una cuota que consultar: o cabe o el sistema dice que no
    // cuando se escribe. Se devuelve null y por eso [persistir] escribe y deja
    // que sea la escritura la que diga.
    return null;
  }

  @override
  void dispose() {}
}

/// La implementacion de este fichero. La llama la fabrica comun de
/// `almacenamiento_de_modulos.dart`, que es el unico sitio donde se decide.
AlmacenamientoDeModulos crearAlmacenamiento() => AlmacenamientoDeModulosNativo();
