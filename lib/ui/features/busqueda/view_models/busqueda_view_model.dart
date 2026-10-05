// La pantalla de busqueda: una palabra y las coincidencias que tiene en el texto abierto.
//
// QUE HACE Y QUE NO HACE. Igual que el lector: solo pinta y pregunta. No escribe SQL, no
// abre el `.amod` y no sabe de donde sale el modulo. Eso es del repositorio y del
// enrutador.
//
// Y POR QUE HAY UN ESTADO PROPIO Y NO SE REUTILIZA EL DEL LECTOR. El lector tiene estados
// de una lectura --cargando, leyendo, no existe, fallo-- y la busqueda tiene otros --sin
// buscar, buscando, con resultados, sin resultados--. Meter la busqueda en
// `EstadoLecturaTexto` haria que "no hay resultados" fuera "el pasaje no existe", que son
// dos cosas distintas y una es un dato y la otra un fallo.

import 'package:flutter/foundation.dart';

import 'package:ab/domain/models/resultado_de_busqueda.dart';

/// En que punto esta una busqueda.
enum EstadoDeBusqueda {
  /// Todavia no se ha escrito nada. No es lo mismo que "no hay resultados".
  sinBuscar,

  /// Se esta escribiendo, esperando el modulo.
  cargando,

  /// Se ha buscado y hay resultados.
  conResultados,

  /// Se ha buscado y no hay ninguno.
  sinResultados,

  /// El modulo no se pudo abrir, o la consulta fallo.
  fallo,
}

/// La busqueda en el texto abierto.
///
/// Y NO RECIBE EL REPOSITORIO DE MODULOS, por la misma razon que el lector no lo recibe:
/// quien elige el texto abierto es la biblioteca y el enrutador, y si la busqueda recibiera
/// el repositorio habria dos sitios decidiendo que texto se mira. Recibe el modulo ya
/// abierto.
class BusquedaViewModel extends ChangeNotifier {
  BusquedaViewModel({ModuloBuscable? moduloBuscable}) : _modulo = moduloBuscable;

  /// Lo unico que necesita del modulo abierto: el metodo de buscar.
  ///
  /// Y ES UNA INTERFAZ Y NO EL `ModuloAbierto` ENTERO, y no por abstraccion por
  /// abstraccion. Es lo que hace que estas pruebas puedan necesitar **cuatro** modulos
  ///  --uno lento, uno que falla, uno vacio y uno real-- sin abrir ficheros de 57 MiB,
  ///  y sin una clase de pruebas entera que se parezca a un modulo.
  ///
  /// Y NO ES `final`, porque abrir un texto distinto tiene que poder cambiarlo: quien
  /// busca, pulsa un resultado y vuelve a buscar ya esta en otro texto, y con `final` eso
  /// seria un modulo cerrado o un modulo del texto anterior.
  ModuloBuscable? _modulo;

  ModuloBuscable? get modulo => _modulo;

  EstadoDeBusqueda _estado = EstadoDeBusqueda.sinBuscar;
  BusquedaEnElModulo _busqueda = BusquedaEnElModulo.vacia;
  String _motivoDelFallo = '';

  EstadoDeBusqueda get estado => _estado;

  /// Lo que salio, con el total y los resultados que caben.
  BusquedaEnElModulo get busqueda => _busqueda;

  String get motivoDelFallo => _motivoDelFallo;

  /// La palabra de la ultima busqueda, tal cual se escribio.
  ///
  /// Y ESTA EN DOS SITIOS A PROPOSITO: en la ruta, para que el enlace la lleve, y en la
  /// busqueda, para que la pantalla pueda ensenar lo que se busco aunque el texto haya
  /// cambiado. Sin lo segundo, quien llega a una ruta de busqueda ve una lista y no sabe
  /// de donde sale.
  String get palabra => _busqueda.palabra;

  bool get hayResultados => _busqueda.resultados.isNotEmpty;

  /// Abre el modulo en el que se busca y deja la palabra puesta, sin buscar todavia.
  ///
  /// Y **NO BUSCA**, aunque traiga palabra. Una ruta de busqueda se abre con la palabra
  /// puesta en el campo y sin resultados: entrar en un enlace trae 200 lineas de golpe
  /// sin que nadie las haya pedido, y en un movil eso son 200 consultas por un enlace que
  /// alguien acaba de copiar.
  void abrir(ModuloBuscable modulo, {String palabra = ''}) {
    _modulo = modulo;
    _estado = EstadoDeBusqueda.sinBuscar;
    _motivoDelFallo = '';

    // Y LA PALABRA **ENTRA AQUI**, y no se deja para cuando se pulse "buscar". Es lo que
    // hace que entrar por un enlace muestre el campo escrito: si la palabra se guardara
    // solo al buscar, la pantalla se abriria en blanco y quien recibiera
    // `/buscar/KJV2006/begotten` tendria que escribirla otra vez para ver lo que el enlace
    // ya decia.
    _busqueda = BusquedaEnElModulo(
      palabra: palabra,
      resultados: const <ResultadoDeBusqueda>[],
      total: 0,
    );
    /// Y LA PALABRA **NO SE PIERDE**: si venia de la ruta, el campo sale escrito y quien
    /// solo quiere pulsar "buscar" lo tiene, sin tener que escribirla otra vez.
    notifyListeners();
  }

  /// Busca la palabra.
  ///
  /// Y UNA PALABRA DE UNA LETRA NO BUSCA, y el estado **no** pasa a `sinResultados`: se
  /// queda en `sinBuscar`. Medido: "a" sale en 31.027 de los 31.102 versiculos del KJV, y
  ///  ensenar "no hay resultados" para eso es mentir: no se ha buscado nada.
  Future<void> buscar(String palabra) async {
    final limpia = palabra.trim();
    final modulo = _modulo;
    if (modulo == null) {
      _estado = EstadoDeBusqueda.fallo;
      _motivoDelFallo = 'No hay ningun texto abierto.';
      notifyListeners();
      return;
    }

    _estado = EstadoDeBusqueda.cargando;
    _motivoDelFallo = '';
    notifyListeners();

    try {
      final r = await modulo.buscar(limpia);
      _busqueda = r;
      _estado = r.sinBuscar
          ? EstadoDeBusqueda.sinBuscar
          : r.resultados.isEmpty
              ? EstadoDeBusqueda.sinResultados
              : EstadoDeBusqueda.conResultados;
    } catch (e) {
      _estado = EstadoDeBusqueda.fallo;
      _busqueda = BusquedaEnElModulo.vacia;
      _motivoDelFallo = 'No se ha podido buscar: $e';
    }
    notifyListeners();
  }
}

/// Lo que la pantalla necesita de un modulo abierto para buscar.
///
/// Y ES ESTA INTERFAZ Y NO `ModuloAbierto`, y hay una razon muy concreta: `ModuloAbierto`
/// no se puede construir en una prueba. Su constructor es privado y pide un `Sqlite` real,
//  asi que una prueba de la pantalla tendria que abrir un `.amod` de verdad --22 MiB, o
//  57 MiB para el comentario-- solo para comprobar que se pinta una lista. Con esta
//  interfaz se escribe un modulo de tres lineas que devuelve la busqueda que uno quiere.
abstract class ModuloBuscable {
  /// Busca una palabra. Devuelve los resultados y cuantos hay en total.
  Future<BusquedaEnElModulo> buscar(String palabra);
}
