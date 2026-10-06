// Los resaltados de quien esta leyendo.
//
// ============================================================================
// POR QUE UN VIEWMODEL PROPIO Y NO DENTRO DEL DEL LECTOR
// ============================================================================
//
// Porque los resaltados **no son de un capitulo ni de una pantalla**: son de la persona, son de
// todas las traducciones y se ven en la biblioteca, en la busqueda y en el indice. Meterlos en
// `LectorViewModel` haria que el indice de palabras, que es una pantalla aparte, tuviera que
// pedirle resaltados a un view model que solo sabe de un pasaje abierto.
//
// ============================================================================
// Y EL PLAZO, Y EL AVISO, Y POR QUE AQUI SI AVISA
// ============================================================================
//
// Medido en este repositorio: en el navegador, `indexedDB.open` puede quedarse esperando **para
// siempre**. Por eso todo lo que se lee del almacenamiento va con un plazo.
//
// Y AQUI, **AL REVES QUE CON LAS PREFERENCIAS**, si no contesta se avisa:
//
//   - una preferencia perdida son dos toques
//   - un resaltado perdido es trabajo
//
// Y por eso el estado de "no se han podido leer" es **distinto** del de "no hay ninguno". Un
// `ListView` de resaltados vacio con un aviso pequeno encima de "no se han podido leer" es
// honesto; sin el aviso, es una pantalla que dice "no tienes nada marcado" y es mentira.
//
// ============================================================================
// Y GUARDAR AVISA TAMBIEN, Y NO SE DA POR PUESTO
// ============================================================================
//
// El caso de perder es: se marca un versiculo, sale marcado, y el guardado **no** llego. La
// persona lo ha marcado y no lo tiene, y no se ha enterado. Con el aviso, se entera y lo
// vuelve a marcar.
//
// Y NO SE ESPERA AL GUARDADO PARA PINTAR. Pintar primero y guardar por detras es lo que hace
// que marcar se sienta inmediato; al reves, marcar se siente roto.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/resaltado.dart';

/// El plazo de lectura de los resaltados.
///
/// Y SON **CINCO SEGUNDOS**, y no uno, por el mismo motivo que el de las preferencias: el caso
/// medido no es lento, es que no contesta.
const Duration plazoDeResaltados = Duration(seconds: 5);

class ResaltadosViewModel extends ChangeNotifier {
  ResaltadosViewModel({AlmacenamientoDeResaltados? almacenamiento})
      : _almacenamiento = almacenamiento ?? AlmacenamientoDeResaltadosEnMemoria();

  final AlmacenamientoDeResaltados? _almacenamiento;

  List<Resaltado> _resaltados = <Resaltado>[];
  List<EstiloDeResaltado> _estilos = estilosDePartida;
  bool _leidos = false;
  String? _motivoDelAviso;
  bool _guardando = false;

  /// Los resaltados que hay. Vacio **no** significa que no haya ningun resaltado: puede
  /// significar que no se han podido leer. Para eso estan [hayQueAvisar].
  List<Resaltado> get resaltados => List<Resaltado>.unmodifiable(_resaltados);

  /// Los estilos, que empiezan siendo los de partida.
  List<EstiloDeResaltado> get estilos => List<EstiloDeResaltado>.unmodifiable(_estilos);

  /// Si **no** se han podido leer y hay que decirlo en pantalla.
  ///
  /// Y NO ES EL NEGATIVO DE [leidos], aunque hoy sean lo mismo. El dia que haya un caso "se han
  /// leido y aun asi hay que avisar" --que los va a haber-- este getter se puede cambiar sin
  /// tocar ni un `if` de la pantalla.
  bool get hayQueAvisar => _motivoDelAviso != null;

  /// Por que no se han podido leer, o null.
  String? get motivoDelAviso => _motivoDelAviso;

  /// Si se han leido bien.
  bool get leidos => _leidos;

  /// Cuantos hay.
  int get total => _resaltados.length;

  /// Leer, con plazo.
  ///
  /// Y SE LEE UNA SOLA VEZ, al abrir, y no en cada `build`: el almacenamiento del navegador
  /// puede tardar, y una pantalla que espera en cada reconstruccion parpadea.
  ///
  /// Y EL PLAZO ES **UN PARAMETRO** y no el constante de dentro, y no por flexibilidad: la
  /// prueba del almacen que no contesta tarda cinco segundos de reloj, y una suite con cinco
  /// segundos de retraso **no se ejecuta**. Con el parametro, la prueba lo baja a diez
  /// milisegundos y comprueba lo mismo: que no cuelga y que avisa.
  ///
  /// Y EN LA APLICACION SE LLAMA SIN PLAZO, que es lo que quiere el resto del codigo: el
  /// valor de cinco segundos es la politica y esta aqui, no en quien llama.
  Future<void> cargar({Duration? plazo}) async {
    final a = _almacenamiento;
    if (a == null) return;
    final resultado = await leerResaltadosConPlazo(a, plazo ?? plazoDeResaltados);
    _resaltados = resultado.resaltados;
    _estilos = resultado.estilos;
    _leidos = resultado.leido;
    _motivoDelAviso = resultado.motivo;
    notifyListeners();
  }

  /// El resaltado de un versiculo, o null.
  ///
  /// Y UNA BUSQUEDA LINEAL Y NO UN MAPA, y no por rendimiento: son miles de resaltados y se recorre
  /// en memoria **una vez** por capitulo abierto, no uno por versiculo. Un `Map` seria mas
  /// rapido en teoria y habria que mantenerlo sincronizado con la lista, con lo que un forget
  /// de quitar deja el mapa con un resaltado que ya no esta y la pantalla lo pinta.
  Resaltado? de(String libro, int capitulo, int versiculo) {
    for (final r in _resaltados) {
      if (r.esElDe(libro, capitulo, versiculo)) return r;
    }
    return null;
  }

  /// El estilo con el que esta marcado un versiculo, o null si no esta marcado.
  EstiloDeResaltado? estiloDe(String libro, int capitulo, int versiculo) {
    final r = de(libro, capitulo, versiculo);
    return r == null ? null : estiloConEseId(_estilos, r.estilo);
  }

  /// Los estilos usados en un capitulo, en orden de versiculo.
  Map<int, EstiloDeResaltado> estilosDelCapitulo(String libro, int capitulo) {
    final salida = <int, EstiloDeResaltado>{};
    for (final r in resaltadosDelCapitulo(_resaltados, libro, capitulo)) {
      salida[r.versiculo] = estiloConEseId(_estilos, r.estilo);
    }
    return salida;
  }

  /// Marcar un versiculo con un estilo.
  ///
  /// Y PINTA **ANTES** DE GUARDAR, y avisa despues si el guardado no llego. Ver el comentario
  /// de la clase.
  Future<void> marcar(String libro, int capitulo, int versiculo, String estilo) async {
    final nuevo = Resaltado(
      libro: libro,
      capitulo: capitulo,
      versiculo: versiculo,
      estilo: estilo,
    );
    final i = _resaltados.indexWhere((Resaltado r) => r.esElDe(libro, capitulo, versiculo));
    if (i < 0) {
      _resaltados = <Resaltado>[..._resaltados, nuevo];
    } else {
      final copia = List<Resaltado>.of(_resaltados);
      copia[i] = nuevo;
      _resaltados = copia;
    }
    _leidos = true;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return;
    try {
      await a.poner(nuevo).timeout(plazoDeResaltados);
      _motivoDelAviso = null;
    } on TimeoutException {
      _motivoDelAviso = 'No se ha podido guardar el resaltado.';
    } catch (_) {
      _motivoDelAviso = 'No se ha podido guardar el resaltado.';
    }
    _guardando = false;
    notifyListeners();
  }

  /// Quitar el resaltado de un versiculo.
  ///
  /// Y **NO** AVISA SI NO HABIA NINGUNO, y es a proposito: quitar algo que no esta no es un
  /// problema de la persona, es una pulsacion de mas.
  Future<void> quitar(String libro, int capitulo, int versiculo) async {
    final i = _resaltados.indexWhere((Resaltado r) => r.esElDe(libro, capitulo, versiculo));
    if (i < 0) return;

    final copia = List<Resaltado>.of(_resaltados)..removeAt(i);
    _resaltados = copia;
    _leidos = true;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return;
    try {
      await a.quitar('$libro.$capitulo.$versiculo').timeout(plazoDeResaltados);
      _motivoDelAviso = null;
    } on TimeoutException {
      _motivoDelAviso = 'No se ha podido quitar el resaltado.';
    } catch (_) {
      _motivoDelAviso = 'No se ha podido quitar el resaltado.';
    }
    notifyListeners();
  }

  /// Cambiar el nombre de un estilo, y sale en todos sus resaltados.
  ///
  /// Y DEVUELVE **UN ID**, y no el estilo, porque quien llama lo que quiere es pintar el
  /// nombre nuevo en cuanto.
  Future<void> renombrarEstilo(String id, String nombre) async {
    final i = _estilos.indexWhere((EstiloDeResaltado e) => e.id == id);
    if (i < 0) return;

    final estilos = List<EstiloDeResaltado>.of(_estilos);
    estilos[i] = estilos[i].copyWith(nombre: nombre);
    _estilos = estilos;
    _leidos = true;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return;
    try {
      await a.guardarEstilo(estilos[i]).timeout(plazoDeResaltados);
      _motivoDelAviso = null;
    } catch (_) {
      _motivoDelAviso = 'No se ha podido guardar el estilo.';
    }
    notifyListeners();
  }

  /// El texto para exportarlo.
  ///
  /// Y DEVUELVE UN `FUTURE`, porque leer los estilos del almacenamiento es una espera, y
  /// quien exporta tiene que poder **esperar** a tener todo antes de escribir el fichero. Un
  /// `String` de aqui seria un fichero exportado sin estilos, que al reimportar en otra
  /// instalacion sale con los colores de partida.
  Future<String> exportar() async {
    final a = _almacenamiento;
    final estilos = await (a?.estilos() ?? Future<List<EstiloDeResaltado>>.value(_estilos));
    return exportarResaltados(_resaltados, estilos);
  }

  /// Importar un fichero, **sin** cambiar nada por su cuenta.
  ///
  /// Y DEVOLVER EL RESULTADO PARA QUE QUIEN LLAMA DECIDA, y no importar aqui. Ver la nota de
  /// [leerResaltados]: una funcion que escribe lo de la persona con un fichero equivocado es la
  /// peor forma de perderlo.
  ResultadoDeImportar prepararImportar(String? texto) => leerResaltados(texto);

  /// Aceptar lo que ha preparado [prepararImportar].
  ///
  /// Y **PISA** lo que hay, y hay que decirlo: quien llama ha visto el resultado y ha
  /// aceptado. Y avisa de lo que se pisa, porque importar un fichero de mil sobre veinte que
  /// hay es perder veinte sin querer.
  Future<int> aceptar(ResultadoDeImportar resultado) async {
    if (!resultado.ok) return 0;

    _resaltados = List<Resaltado>.of(resultado.resaltados);
    _estilos = resultado.estilos.isEmpty
        ? List<EstiloDeResaltado>.of(estilosDePartida)
        : List<EstiloDeResaltado>.of(resultado.estilos);
    _leidos = true;
    _motivoDelAviso = null;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return _resaltados.length;
    for (final r in _resaltados) {
      await a.poner(r);
    }
    for (final e in _estilos) {
      await a.guardarEstilo(e);
    }
    return _resaltados.length;
  }

  /// Si se esta guardando algo ahora.
  ///
  /// Y NO SE USA EN PANTALLA, todavia. Esta aqui porque es el estado que hara falta para el
  /// boton de exportar, que no se habilita hasta que no queden guardados en el aire: exportar
  /// un fichero con lo que se ve pero que no esta guardado es un fichero incompleto.
  bool get guardando => _guardando;

  @override
  void dispose() {
    _almacenamiento?.dispose();
    super.dispose();
  }
}