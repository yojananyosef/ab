// Lo que la pantalla de lectura muestra, y las reglas del pasaje.
//
// UN VIEWMODEL QUE ABRE Y CIERRA MODULOS, PORQUE NO HAY OTRO SITIO DONDE HACERLO. La
// pantalla pinta; el repositorio de modulos guarda el abierto para que dos pantallas
// no lo abran dos veces; y este ViewModel es quien decide cuando cerrar. Que sea aqui
// y no en el repositorio es una decision: si el repositorio guardara el abierto, no
// sabria cuando cerrar, y un `.amod` de 57 MiB abierto en un movil es memoria que no
// vuelve sola.
//
// LO QUE NO HAY AQUI, Y ES LO IMPORTANTE. No hay estado de "ultimo pasaje guardado",
// ni historial, ni posicion. El unico estado que se conserva entre pantallas es el
// **capitulo y el versiculo que se esta leyendo**, y sale de la URL. Volver atras
// reconstruye la pantalla desde la direccion, que es lo unico que no se puede quedar
// viejo.
//
// Y LA REGLA DE "NO EXISTE" DE 7.3. Cuando se pide un pasaje que no esta en esa
// traduccion, se avisa **en castellano** y se ofrece el ultimo pasaje valido anterior.
// No un error y no una pantalla en blanco: las dos cosas hacen que alguien piense que
// la app esta rota cuando lo que pasa es que esa traduccion tiene 50 capitulos de
// Genesis y se ha pedido el 51.
//
// La ultima oferta es lo que hace util el aviso. "Juan 5:44 no existe en esta
// traduccion" no dice nada; "el ultimo versiculo anterior es Juan 5:43" es un
// enlace que funciona. Es la diferencia entre un error y una ayuda.

import 'package:flutter/foundation.dart';

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/libro.dart';
import 'package:ab/domain/models/libros.dart';
import 'package:ab/domain/models/pasaje.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/terminos.dart';

/// Los estados de la pantalla de lectura. Cinco, y ninguno es "cargando para
/// siempre".
enum EstadoLecturaTexto {
  /// No hay ningun modulo abierto todavia.
  sinModulo,

  /// Hay un modulo abierto y todavia no se ha pedido ningun pasaje.
  ///
  /// Es un estado que dura un frame --el enrutador abre el modulo y enseguida pide el
  /// pasaje-- pero tiene que existir. Sin el, el estado entre abrir y leer seria
  /// "cargando", y "cargando" con un `CircularProgressIndicator` que no tiene nada que
  /// cargar es un spinner que **nunca para**: se queda girando para siempre y
  /// `pumpAndSettle` se queda esperando para siempre. Pasarle a una prueba asi no es un
  /// fallo de la prueba, es un fallo de la pantalla.
  nadaLeido,

  /// Leyendo.
  cargando,

  /// Hay texto en pantalla.
  leyendo,

  /// El pasaje pedido no existe en esta traduccion. Hay un ultimo valido.
  noExiste,

  /// El modulo no se pudo abrir o no se pudo leer.
  fallo,
}

class LectorViewModel extends ChangeNotifier {
  /// NO recibe el repositorio de modulos ni el de catalogo. El lector **no elige**
  /// que texto abrir: quien decide es la biblioteca, y el lector recibe el modulo ya
  /// abierto. Un constructor que aceptara el repositorio invitaria a que el lector
  /// abriera un modulo por su cuenta, y entonces habria dos sitios decidiendo cual.
  LectorViewModel({this._abierto});


  ModuloAbierto? _abierto;

  EstadoLecturaTexto _estado = EstadoLecturaTexto.sinModulo;
  Pasaje? _pasaje;
  Terminos? _terminos;
  DiscrepanciaDeLicencia? _discrepancia;
  String? _aviso;
  String? _ultimoValido;
  String _textoBusqueda = '';
  Referencia? _pideA;
  String? _motivoDelFallo;

  // --- lo que se lee ---

  EstadoLecturaTexto get estado => _estado;
  Pasaje? get pasaje => _pasaje;
  Terminos? get terminos => _terminos;
  DiscrepanciaDeLicencia? get discrepancia => _discrepancia;
  String? get aviso => _aviso;

  /// La referencia del ultimo pasaje que si existio, como texto. Null si ninguno.
  ///
  /// Es lo que se ofrece como "el ultimo versiculo anterior". Y **no** es un
  /// `Referencia`, sino su texto: lo que se pinta es un texto y un boton, y quien
  /// lo decide como se abre es la pantalla, no el ViewModel.
  String? get ultimoValido => _ultimoValido;

  String? get motivoDelFallo => _motivoDelFallo;
  String get textoBusqueda => _textoBusqueda;
  bool get estaBuscando => textoBusqueda.trim().isEmpty;

  /// El modulo abierto, o null.
  ModuloAbierto? get modulo => _abierto;

  /// El identificador del modulo abierto.
  String? get idDelModulo => _abierto?.id;

  /// Los libros que tiene el modulo abierto, ya **ordenados en orden canonico**.
  ///
  /// El modulo los devuelve en orden alfabetico --los guarda como texto sin indice-- y
  /// reordenar aqui es lo que hace que el selector de libros se lea como una Biblia y
  /// no como un indice. Y un libro que el canon tiene y el modulo no, **no sale**.
  /// Ofrecer un libro que al pulsarlo da "no existe" es peor que no ofrecerlo.
  List<Libro> get librosDisponibles {
    final m = _abierto;
    if (m == null) return const <Libro>[];
    final hay = m.libros().toSet();
    return kLibros.where((l) => hay.contains(l.id)).toList();
  }

  /// Los capitulos del libro abierto, en orden. Vacio si no hay libro abierto.
  ///
  /// De una consulta, no de una tabla. Ver `modulo_repository.dart`.
  List<int> capitulosDe(String libro) => _abierto?.capitulosDe(libro) ?? const <int>[];

  // --- lo que se hace ---

  /// Abre un modulo y se queda con el.
  ///
  /// Cierra el anterior antes de abrir el nuevo. Sin eso, cambiar de traduccion con la
  /// KJV de 22 MiB y el CLARKE de 57 MiB abiertos a la vez son 79 MiB, y en un movil
  /// de gama baja eso es la diferencia entre que funcione y que no.
  void abrir(ModuloAbierto modulo, {required String? licenciaDelManifiesto}) {
    _cerrarSiHabia();
    _abierto = modulo;
    _terminos = Terminos.desdeModulo(modulo.info, modulo.infoEntero);
    _discrepancia = licenciaDelManifiesto == null
        ? null
        : compararLicencias(
            delManifiesto: licenciaDelManifiesto,
            delModulo: _terminos?.licencia ?? '',
          );
    _estado = EstadoLecturaTexto.nadaLeido;
    _pasaje = null;
    _ultimoValido = null;
    _motivoDelFallo = null;
    _aviso = null;
    notifyListeners();
  }

  /// Marca que no hay ningun modulo. Se usa cuando se elige uno que no esta
  /// descargado.
  void sinModulo([String? aviso]) {
    _cerrarSiHabia();
    _estado = EstadoLecturaTexto.sinModulo;
    _pasaje = null;
    _terminos = null;
    _discrepancia = null;
    _aviso = aviso;
    notifyListeners();
  }

  /// Lee un pasaje.
  ///
  /// Y si no existe, **no** deja la pantalla vacia: busca hacia atras el ultimo
  /// versiculo que si exista y lo ofrece. Esa busqueda es una consulta por versiculo y
  /// va hacia atras, asi que en el peor caso --un capitulo entero que no existe-- son
  /// unas pocas, no todas.
  void leer(Referencia referencia) {
    final m = _abierto;
    if (m == null) {
      sinModulo('No hay ningun texto abierto.');
      return;
    }

    // Se guarda lo pedido para saber, cuando llegue la respuesta, si sigue siendo lo
    // que se quiere ver. Sin esta comprobacion, al pasar de capitulo rapido se puede
    // pintar el texto del anterior encima del nuevo, y es un fallo que sale solo
    // cuando se va rapido, que es justo cuando no se mira la pantalla.
    _pideA = referencia;
    _estado = EstadoLecturaTexto.cargando;
    _aviso = null;
    _motivoDelFallo = null;
    notifyListeners();

    try {
      // Si mientras se leia se pidio otra cosa, este resultado es de una peticion
      // vieja y se tira. Sin esta comprobacion, al pasar de capitulo rapido se pinta
      // el texto del anterior encima del nuevo.
      if (_pideA != referencia) return;

      if (m.existe(referencia)) {
        _pasaje = m.leer(referencia);
        _estado = _pasaje!.vacio ? EstadoLecturaTexto.noExiste : EstadoLecturaTexto.leyendo;
        if (_pasaje!.vacio) {
          _aviso = 'En esta traduccion no hay nada en $referencia.';
          _ultimoValido = _buscarElUltimoAnterior(m, referencia);
        } else {
          _ultimoValido = null;
        }
        notifyListeners();
        return;
      }

      // No existe. Se busca atras y se ofrece.
      _estado = EstadoLecturaTexto.noExiste;
      _pasaje = null;
      _ultimoValido = _buscarElUltimoAnterior(m, referencia);
      _aviso = _ultimoValido == null
          ? 'Esta traduccion no tiene $referencia, ni el versiculo anterior.'
          : 'Esta traduccion no tiene $referencia. El ultimo versiculo anterior es $ultimoValido.';
      notifyListeners();
    } catch (e) {
      _estado = EstadoLecturaTexto.fallo;
      _pasaje = null;
      _motivoDelFallo = 'No se ha podido leer el texto: $e';
      notifyListeners();
    }
  }

  /// El ultimo versiculo existente antes de [desde], o null.
  ///
  /// Coge **hasta tres versiculos** hacia atras y no uno, porque hay un caso real que
  /// lo necesita: hay capitulos enteros que no existen en una traduccion. Si solo
  /// mirara uno, al pedir Juan 6 en una traduccion que no lo tiene ofrecen Juan 5:52,
  /// que esta en el capitulo anterior y no ayuda. Con tres cae dentro del capitulo que
  /// si existe.
  String? _buscarElUltimoAnterior(ModuloAbierto m, Referencia desde) {
    final v = desde.versiculo;
    if (v != null && v > 1) {
      final anterior = Referencia(desde.libro, desde.capitulo, v - 1);
      if (m.existe(anterior)) return anterior.texto;
      return null;
    }

    // Sin versiculo, o en el versiculo 1: se busca en los capitulos anteriores.
    for (final salto in <int>[1, 2, 3]) {
      final cap = desde.capitulo - salto;
      if (cap < 1) break;
      final numeros = m.numerosDeVersiculos(Referencia(desde.libro, cap));
      if (numeros.isEmpty) continue;
      final ultimo = numeros.last;
      return Referencia(desde.libro, cap, ultimo).texto;
    }
    return null;
  }

  /// Va al ultimo pasaje valido que se ofrecio.
  ///
  /// Devuelve null si no habia ninguno, para que la pantalla sepa si pintar el
  /// boton o no. Un boton que a veces no hace nada es peor que un boton que no
  /// existe.
  Referencia? irAlUltimoValido() {
    final texto = _ultimoValido;
    if (texto == null) return null;
    final r = Referencia.tryParse(texto);
    if (r != null) leer(r);
    return r;
  }

  /// El texto que se esta escribiendo en el campo de referencia.
  void escribirBusqueda(String texto) {
    if (texto == _textoBusqueda) return;
    _textoBusqueda = texto;
    notifyListeners();
  }

  /// Si el texto escrito es una referencia que se puede abrir.
  ///
  /// El boton de buscar se habilita con esto. Y es la **misma** regla que usa la URL,
  /// a proposito: si buscar y la URL aceptaran referencias distintas, se podria buscar
  /// una cosa y acabar en otra.
  bool get laReferenciaEsValida =>
      estaBuscando || Referencia.tryParse(_textoBusqueda) != null;

  /// La referencia del campo, o null si no es valida.
  Referencia? get referenciaEscrita =>
      estaBuscando ? null : Referencia.tryParse(_textoBusqueda);

  /// Vacia el campo de referencia.
  void limpiarBusqueda() {
    if (_textoBusqueda.isEmpty) return;
    _textoBusqueda = '';
    notifyListeners();
  }

  /// Que se esta leyendo ahora mismo, como referencia.
  Referencia? get leyendo => _pasaje?.referencia;

  @override
  void dispose() {
    _cerrarSiHabia();
    super.dispose();
  }

  void _cerrarSiHabia() {
    _abierto?.cerrar();
    _abierto = null;
  }
}
