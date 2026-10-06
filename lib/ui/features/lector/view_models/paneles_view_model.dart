// Los paneles abiertos, y cual esta delante.
//
// ============================================================================
// QUE HACE ESTE FICHERO Y POR QUE NO PUEDE VIVIR EN EL ENRUTADOR
// ============================================================================
//
// El enrutador sabe que pantalla se ve. Este sabe **cuantos textos hay abiertos al mismo
// tiempo**. Son dos cosas distintas, y juntarlas tiene un coste concreto: el enrutador
// vive mientras la aplicacion, y un estado de "hay dos textos abiertos" es de la
// **sesion de lectura** --se pierde al ir a la biblioteca--. Ponerlo en el enrutador
// significaria que volver de la biblioteca deja tres textos abiertos, y son 67,5 MiB de
// paginas SQLite que nadie esta mirando.
//
// ============================================================================
// Y CADA PANEL TIENE SU PROPIO `LectorViewModel`, Y NO UNO COMPARTIDO
// ============================================================================
//
// Un `LectorViewModel` tiene **un** modulo abierto. Dos textos abiertos son dos view
// models, y no hay forma de que uno solo sirva: en `LectorViewModel` `_abierto` es un
// `ModuloAbierto?`, y un solo campo no puede ser las dos Biblias.
//
// Y LOS AJUSTES DE LECTURA **NO** ESTAN EN EL VIEW MODEL, y ese es el punto entero de que
// `PreferenciasDeLectura` saliera de `lector_view_model.dart`: la letra, el alto de linea
// y el rojo de las palabras de Jesus son de la **ventana**, y con dos textos abiertos dos
// view models con sus propios ajustes serian dos letras distintas lado a lado.
//
// ============================================================================
// Y LA REFERENCIA ES **DE CADA PANEL**, Y ESO NO ES UN ARBITRIO
// ============================================================================
//
// En Logos los paneles pueden estar en sitios distintos: uno en Juan 3 y otro en el
// Salmo 119, y ambos se ven. Obligar a que todos muestren lo mismo seria inventar una
// regla que el producto no tiene, y hace que cambiar de panel cambie lo que hay en los
// demas --que es justo lo que las pestanas tienen que **no** hacer.
//
// Lo que si es de la ventana es cual esta delante. Y lo que **no** cambia de panel es
// la preferencia: ver [PreferenciasDeLectura].

import 'package:flutter/foundation.dart';

import 'package:ab/domain/models/panel_abierto.dart';
import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/domain/models/referencia.dart';

import 'lector_view_model.dart';
import 'preferencias_de_lectura.dart';

/// Los paneles abiertos y el que esta delante.
class PanelesViewModel extends ChangeNotifier {
  /// Los ajustes son **de la ventana**, y se pasan ya hechos.
  ///
  /// Y NO SE CREAN AQUI, y no por estilo: quien los crea es `main.dart`, donde esta el
  /// almacenamiento, y dos `PanelesViewModel` distintos --uno en la aplicacion y otro en
  /// una prueba-- tendrian que compartir el mismo objeto para que los ajustes de uno se
  /// vieran en el otro.
  PanelesViewModel({
    required PreferenciasDeLectura preferencias,
    // ignore: prefer_initializing_formals
  }) : _preferencias = preferencias {
    _preferencias.addListener(_alCambiarLasPreferencias);
  }

  final PreferenciasDeLectura _preferencias;

  bool _disposed = false;

  void _alCambiarLasPreferencias() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Los paneles, en orden. El primero **no** es el de delante: el de delante es el que
  /// dice [delante], y esa distincion es lo que permite mover una ventana sin cerrar las
  /// de al lado, que es lo que hace la fila de pestañas.
  final List<PanelAbierto> _paneles = <PanelAbierto>[];

  /// Que estas viendo los paneles con.
  ///
  /// Y **UNO POR PANEL**, y no un unico `LectorViewModel` con una lista de passages. Un
  /// solo view model tendria un unico `_abierto`, un unico `_pasaje` y un unico
  /// `_comentario`, y con dos textos abiertos habria que ir alternando entre ellos para
  /// pintar uno y despues el otro --con lo que el scroll, el pasaje y las notas del otro se
  /// pierden en cada cambio--. Un view model por panel es lo que hace que cada uno tenga
  /// su scroll y su pasaje, que es lo que piden las pestañas.
  final Map<String, LectorViewModel> _lectores = <String, LectorViewModel>{};

  int _delante = 0;

  // --- lo que se lee ---

  /// Los paneles abiertos, en orden.
  List<PanelAbierto> get paneles => List<PanelAbierto>.unmodifiable(_paneles);

  /// Cuantos paneles hay abiertos.
  int get cuantos => _paneles.length;

  /// Si hay mas de uno abierto.
  ///
  /// Y ESTO ES LO QUE CAMBIA LA PANTALLA: con uno hay un `Scaffold` con su barra, y con
  /// dos hay una fila de pestañas encima y dos columnas. Y `bool` y no `cuantos > 1` en
  /// la vista, porque la pregunta que hace la vista es "hay pestañas" y no "cuantos".
  bool get hayVarios => _paneles.length > 1;

  /// El panel que esta delante, o null si no hay ninguno.
  ///
  /// Y **NULL SI NO HAY NINGUNO**, y no un panel vacio: la biblioteca se pinta cuando no
  /// hay nada abierto, y un panel vacio seria una pantalla de lectura sin texto, que es
  /// la forma peor de no tener nada.
  PanelAbierto? get delante =>
      _paneles.isEmpty ? null : _paneles[_delante.clamp(0, _paneles.length - 1)];

  /// El identificador del modulo del panel de delante, o null.
  String? get idDelModulo => delante?.moduloId;

  /// Lo que se esta leyendo en el panel de delante, o null.
  Referencia? get referencia => delante?.referencia;

  /// El view model del panel de delante, o null.
  ///
  /// Y SE DEVUELVE EL DE ESE PANEL Y NO UN "EL PRIMERO", porque cambiar de panel con las
  /// pestañas tiene que cambiar el view model entero: es el unico sitio donde esta el
  /// pasaje que se ve, y devolver el de otro panel es ver Juan 3 en la pestaña de Juan 4.
  LectorViewModel? get lectorDelante {
    final p = delante;
    return p == null ? null : _lectores[p.moduloId];
  }

  /// El view model de un panel, o null si no esta abierto.
  LectorViewModel? lectorDe(String moduloId) => _lectores[moduloId];

  /// El panel de un modulo, o null si no esta abierto.
  ///
  /// Y ES PARA **NO ABRIR EL MISMO DOS VECES**. Ver `panel_abierto.dart`: dos panes del
  /// mismo modulo son 22,5 MiB abiertos dos veces.
  PanelAbierto? panelDe(String moduloId) {
    for (final p in _paneles) {
      if (p.moduloId == moduloId) return p;
    }
    return null;
  }

  /// Los ajustes de lectura de la ventana.
  ///
  /// Y PASAN POR AQUI Y NO SE LEEN DE CADA VIEW MODEL, porque son los mismos para los
  /// dos y no hay ninguna pregunta que hacer: leerlos de un panel y no de otro haria que
  /// cambiar la letra en el panel de la izquierda no se viera en el de la derecha.
  PreferenciaDeLectura get preferenciaDeLectura => _preferencias.preferencia;
  bool get mostrarPalabrasDeJesus => _preferencias.mostrarPalabrasDeJesus;

  // --- lo que se hace ---

  /// Abrir un panel con su view model.
  ///
  /// Y **NO** ABRE EL MODULO, y el motivo esta en la arquitectura: abrir un `.amod` es
  /// leer sus bytes del almacenamiento, que necesita servicios que un view model de
  /// interfaz no tiene. Quien abre es el enrutador, con su `abrir`, y lo que hace aqui es
  /// guardar el estado de que hay un panel mas.
  ///
  /// Y **NO** AVISA SI YA HAY UN PANEL DE ESE MODULO: mira [panelDe] quien quiera abrir,
  /// y quien mira es el enrutador, que es quien tiene el modulo abierto y puede traerlo al
  /// frente. Un `abrir` que sustituye en silencio el panel que habia seria abrir el mismo
  /// texto dos veces, que es justo lo que este diseno evita.
  void registrar(PanelAbierto panel, LectorViewModel lector) {
    if (panelDe(panel.moduloId) != null) return;
    _paneles.add(panel);
    _lectores[panel.moduloId] = lector;
    // Y EL QUE SE ABRE **NO** SE PONE DELANTE POR SU CUENTA. Se pone delante quien ha
    // pedido abrirlo, y no el orden en que llegaron: abrir el CLARKE desde una pestana
    // que no es la primera tiene que dejar al frente el CLARKE, y si el `add` pusiera el
    // ultimo delante, abrir un panel de fondo lo traeria delante sin que nadie lo pidiera.
    _delante = _paneles.length - 1;
    notifyListeners();
  }

  /// Poner un panel delante, y devolver si estaba.
  ///
  /// Y **NO AVISA SI NO ESTA**, porque quien llama ha mirado antes y una pestana que no
  /// existe no se puede pulsar.
  bool ponerAlFrente(String moduloId) {
    final i = _paneles.indexWhere((p) => p.moduloId == moduloId);
    if (i < 0 || i == _delante) return false;
    _delante = i;
    notifyListeners();
    return true;
  }

  /// Cambiar el pasaje de un panel, y devolver si el panel estaba.
  ///
  /// Y ES **POR PANEL Y NO GLOBAL**, y es la diferencia entre las pestañas y un cambio de
  /// texto. Juan 3 en el panel de la KJV y Juan 5 en el del CLARKE son dos estados
  /// distintos, y quien esta leyendo Juan 3 no quiere que al abrir Juan 5 en el otro se
  /// mueva el que tiene delante.
  bool leerEn(String moduloId, Referencia referencia) {
    final i = _paneles.indexWhere((p) => p.moduloId == moduloId);
    if (i < 0) return false;
    final antes = _paneles[i];
    if (antes.referencia == referencia) return false;
    _paneles[i] = antes.copyWith(referencia: referencia);
    notifyListeners();
    return true;
  }

  /// Poner o quitar el comentario de un panel.
  ///
  /// Y ES UN METODO Y NO UN `if` POR CASO, porque quien llama lee lo que dice el panel y
  /// no quiere saber si el comentario estaba o no: poner y quitar son el mismo gesto
  /// escrito de dos formas, y un metodo con dos caminos hace que el que pone y el que
  /// quita no puedan separarse nunca.
  bool ponerComentario(String moduloId, String? comentarioId) {
    final i = _paneles.indexWhere((p) => p.moduloId == moduloId);
    if (i < 0) return false;
    final antes = _paneles[i];
    if (antes.comentarioId == comentarioId) return false;
    _paneles[i] = comentarioId == null
        ? antes.copyWith(quitarComentario: true)
        : antes.copyWith(comentarioId: comentarioId);
    notifyListeners();
    return true;
  }

  /// Cerrar un panel, y devolver si estaba.
  ///
  /// Y **CIERRA SU `.amod`**, y no es un detalle: [LectorViewModel.dispose] cierra el
  /// modulo, asi que quitar un panel de la lista **no** es solo quitarlo de la pantalla.
  /// Con tres textos de 22,5 MiB --67,5 MiB de paginas SQLite medidos-- que no se cierran,
  /// en un movil de gama baja el sistema mata el proceso.
  ///
  /// Y **SE AVISA ANTES** de cerrar, y no despues. Si el `.amod` se cerrara antes de
  // quitar el panel de la lista, el frame que se pinta entre medias muestra un panel
  /// abierto cuyo modulo ya no existe, y leer de ahi da un `SqliteException` en pantalla.
  ///
  /// Y CUANDO SE QUITA EL QUE ESTA DELANTE, **OTRO PASA DELANTE**, y no se elige el
  /// primero: quien esta leyendo Juan 3 cierra la pestana de Juan 3 y quiere que se vea
  //  lo que hubiera, no volver al primero por orden de apertura.
  bool cerrar(String moduloId) {
    final i = _paneles.indexWhere((p) => p.moduloId == moduloId);
    if (i < 0) return false;

    final eraElDelante = i == _delante;
    _paneles.removeAt(i);
    final lector = _lectores.remove(moduloId);
    // Y SE AVISA **ANTES** DE DESTRUIR EL VIEW MODEL, por lo de arriba.
    notifyListeners();
    lector?.dispose();

    if (!eraElDelante) return true;
    if (_paneles.isEmpty) {
      _delante = 0;
      return true;
    }
    // Y EL INDICE SE ACORTA, y por eso se vuelve a acotar: quitar el panel del frente
    // desplaza los de detras, y el que era el siguiente pasa a estar justo antes de donde
    // estaba el que se ha cerrado.
    _delante = _delante.clamp(0, _paneles.length - 1);
    return true;
  }

  /// Cerrar todos los paneles.
  ///
  /// Y ES LO QUE PASA AL VOLVER A LA BIBLIOTECA. Ver la cabecera: quien esta en la
  /// biblioteca no esta leyendo, y 67,5 MiB de paginas SQLite abiertas para nada son
  /// memoria que en un movil no vuelve sola.
  void cerrarTodos() {
    if (_paneles.isEmpty) return;
    final lectores = _lectores.values.toList();
    _paneles.clear();
    _lectores.clear();
    _delante = 0;
    notifyListeners();
    for (final l in lectores) {
      l.dispose();
    }
  }

  /// Los identificadores de los paneles abiertos, en orden.
  List<String> get ids => <String>[for (final p in _paneles) p.moduloId];

  @override
  void dispose() {
    _disposed = true;
    _preferencias.removeListener(_alCambiarLasPreferencias);
    for (final l in _lectores.values) {
      l.dispose();
    }
    _lectores.clear();
    _paneles.clear();
    super.dispose();
  }
}