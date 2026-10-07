// Donde viven los resaltados fuera del navegador: un fichero JSON.
//
// ============================================================================
// POR QUE UN FICHERO Y NO IndexedDB
// ============================================================================
//
// Porque en nativo hay disco y en el navegador no hay nada. Y porque el fallo medido que
// motivó la base de datos **propia** --el bloqueo de `onupgradeneeded` con dos pestanas-- es
// de IndexedDB y no aplica aqui.
//
// Y POR QUE **UN** FICHERO Y NO UNO POR RESALTADO, y no por gusto: un fichero por versiculo
// son miles de ficheros en un directorio del sistema, y borrarlos uno a uno al quitar un
// resaltado deja el directorio lleno de ficheros y el borrado de "mis datos" necesita un recorrido
// que puede fallar a mitad. Un solo fichero con los dos dentro es una escritura, y una
// escritura se puede hacer **entera o no hacer**.
//
// ============================================================================
// Y POR QUE LA ESCRITURA ES **ATOMICA**
// ============================================================================
//
// Se escribe a `x.json.parcial` y se renombra encima. Es lo mismo que hace el almacen de
// modulos con los `.amod` de 57 MiB, y por el mismo motivo: un fichero JSON se puede escribir
// a medias si se cierra el telefono en mitad, y un JSON a medias **no es** un JSON. Escribir
// a un temporal y renombrar hace que el fichero que hay sea siempre uno entero: el anterior o
// el nuevo, nunca uno roto.
//
// ============================================================================
// Y LO QUE NO SE COMPRUEBA AQUI
// ============================================================================
//
// `AGENTS.md` lo dice y aqui se repite porque este fichero es nuevo: en esta maquina no hay
// SDK de Android ni GTK, asi que **esto no se ha ejecutado**. Lo que si esta comprobado es
// la parte de Dart --el formato del fichero y la conversion-- que es la que puede estar mal
// sin que nadie se entere en un movil.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:ab/domain/models/resaltado.dart';

import 'almacenamiento_de_resaltados.dart';

/// El nombre del fichero, dentro del directorio de soporte de la aplicacion.
const String _nombre = 'resaltados.json';

/// El subdirectorio donde vive, que es uno propio.
///
/// Y UNO PROPIO Y NO EN LA RAIZ DEL DIRECTORIO DE SOPORTE, porque ahi estan los modulos y la
/// accion de «borrar los modulos que no uso» no debe poder tocar esto ni de rebote. Con dos
/// sitios separados, esa accion borra una carpeta y no toca la otra.
const String _subdirectorio = 'resaltados';

class AlmacenamientoDeResaltadosNativo implements AlmacenamientoDeResaltados {
  AlmacenamientoDeResaltadosNativo({Directory? directorio})
      : _directorioDado = directorio;

  final Directory? _directorioDado;
  Directory? _directorio;

  Map<String, Resaltado> _resaltados = <String, Resaltado>{};
  List<EstiloDeResaltado> _estilos = List<EstiloDeResaltado>.of(estilosDePartida);
  bool _leido = false;

  @override
  Future<Set<String>> claves() async {
    await _leerSiFalta();
    return _resaltados.keys.toSet();
  }

  @override
  Future<Resaltado?> de(String clave) async {
    await _leerSiFalta();
    return _resaltados[clave];
  }

  @override
  Future<List<Resaltado>> todos() async {
    await _leerSiFalta();
    return _resaltados.values.toList();
  }

  @override
  Future<List<EstiloDeResaltado>> estilos() async {
    await _leerSiFalta();
    return List<EstiloDeResaltado>.unmodifiable(_estilos);
  }

  @override
  Future<void> poner(Resaltado resaltado) async {
    await _leerSiFalta();
    _resaltados[resaltado.clave] = resaltado;
    await _volcar();
  }

  @override
  Future<void> quitar(String clave) async {
    await _leerSiFalta();
    if (_resaltados.remove(clave) == null) return;
    await _volcar();
  }

  @override
  Future<void> guardarEstilo(EstiloDeResaltado estilo) async {
    await _leerSiFalta();
    final i = _estilos.indexWhere((EstiloDeResaltado e) => e.id == estilo.id);
    final copia = List<EstiloDeResaltado>.of(_estilos);
    if (i < 0) {
      copia.add(estilo);
    } else {
      copia[i] = estilo;
    }
    _estilos = copia;
    await _volcar();
  }

  @override
  Future<void> borrarTodo() async {
    _resaltados = <String, Resaltado>{};
    _estilos = List<EstiloDeResaltado>.of(estilosDePartida);
    await _volcar();
  }

  @override
  void dispose() {
    _directorio = null;
  }

  // --- el fichero ---

  Future<void> _leerSiFalta() async {
    if (_leido) return;
    _leido = true;
    try {
      final dir = await _directorioDeLosDatos();
      final fichero = File('${dir.path}/$_nombre');
      if (!await fichero.exists()) return;

      final texto = await fichero.readAsString();
      final decodificado = jsonDecode(texto);
      if (decodificado is! Map<String, Object?>) return;

      // Y CADA RESALTADO **POR SEPARADO**, y uno malo no se lleva a los demas. Es lo mismo
      // que en el navegador y por el mismo motivo: un registro raro no puede impedir leer los
      // miles que estan bien.
      final r = <String, Resaltado>{};
      final lista = decodificado['resaltados'];
      if (lista is List) {
        for (final e in lista) {
          final leido = Resaltado.desdeJson(e);
          if (leido != null) r[leido.clave] = leido;
        }
      }
      _resaltados = r;

      // Y SI EL FICHERO **NO** TRAE ESTILOS, LOS DE PARTIDA, y no una lista vacia. Un
      // resaltado con un estilo que no esta en la lista se ve igual con el primero, asi que
      // un fichero sin estilos no deja nada invisible.
      final e = <EstiloDeResaltado>[];
      final listaEstilos = decodificado['estilos'];
      if (listaEstilos is List) {
        for (final x in listaEstilos) {
          if (x is Map<String, Object?>) e.add(EstiloDeResaltado.desdeJson(x));
        }
      }
      _estilos = e.isEmpty
          ? List<EstiloDeResaltado>.of(estilosDePartida)
          : e;
    } catch (_) {
      // Y UN FICHERO QUE NO SE PUEDE LEER **NO** BORRA LO QUE HAY EN MEMORIA. Es el mismo
      // principio que el del navegador: lo que se ha perdido son datos de una persona, y
      // quedarse sin ellos en silencio es peor que quedarse con los de memoria.
      _resaltados = <String, Resaltado>{};
      _estilos = List<EstiloDeResaltado>.of(estilosDePartida);
    }
  }

  /// Escribir el fichero entero, a un temporal y renombrando.
  ///
  /// Y SI LA ESCRITURA FALLA, EL ESTADO EN MEMORIA **SE QUEDA** como estaba. Un `throw`
  /// aqui dejaria la memoria y el disco distintos, y lo que se veria en pantalla seria un
  /// resaltado que no esta guardado: exactamente el fallo que este change arregla.
  Future<void> _volcar() async {
    try {
      final dir = await _directorioDeLosDatos();
      final destino = File('${dir.path}/$_nombre');
      final parcial = File('${destino.path}.parcial');

      await parcial.writeAsString(jsonEncode(<String, Object?>{
        'formato': 'ab-resaltados/1',
        'resaltados': _resaltados.values.map((Resaltado r) => r.aJson()).toList(),
        'estilos': _estilos.map((EstiloDeResaltado e) => e.aJson()).toList(),
      }));

      await parcial.rename(destino.path);
    } catch (_) {
      // Y AQUI NO SE Lanza, y el motivo esta escrito en la cabecera del metodo.
    }
  }

  Future<Directory> _directorioDeLosDatos() async {
    final ya = _directorio;
    if (ya != null) return ya;
    final dado = _directorioDado;
    if (dado != null) return dado;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_subdirectorio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _directorio = dir;
  }
}

/// La implementacion de este fichero. La llama la fabrica comun de
/// `almacenamiento_de_resaltados.dart`, que es el unico sitio donde se decide.
AlmacenamientoDeResaltados crearAlmacenamiento() => AlmacenamientoDeResaltadosNativo();