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
import 'package:ab/domain/models/nota.dart';
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

  // --- el comentario que va al lado ---
  //
  // Y SON TRES CAMPOS Y NO UNO, Y POR QUE. El modulo abierto es una base de datos que
  // hay que cerrar; el pasaje es lo que se esta pintando, y no tiene por que estar --se
  // pide al abrir el comentario y se queda si luego se pide otro pasaje--; y el motivo
  // del fallo es lo que dice la pantalla cuando el comentario no se pudo abrir. Meterlo
  // todo en un solo `ModuloAbierto?` obligaria a consultar `!= null` para saber tres
  // cosas distintas, y en dos de ellas la respuesta es "si" y en la otra "no".
  ModuloAbierto? _comentario;
  Pasaje? _notas;
  String? _motivoDelComentario;

  // Y EL **PEDIDO**, QUE NO ES LO MISMO QUE EL ABIERTO. Es lo que la pantalla necesita
  // para poder decir "Descargar el CLARKE, 57 MiB": con el identificador del que se
  // pidio, no hace falta saber de donde salio para ofrecer bajarlo, y sin el no hay
  // forma de poner ese boton --el aviso solo lleva texto.
  String? _comentarioPedido;

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

  // --- el comentario que va al lado ---

  /// El identificador del comentario abierto, o null si no hay ninguno.
  String? get idDelComentario => _comentario?.id;

  /// El identificador del comentario que se pidio, haya abierto o no.
  ///
  /// Y ES DISTINTO DE [idDelComentario] PORQUE EL CASO INTERESANTE ES EL DE PEDIRLO Y
  /// NO PODER: sin este identificador, quien recibe un enlace con un comentario que no
  /// tiene ve un texto que dice "no esta descargado" y **nada mas**, y 57 MiB no se
  /// bajan solos. Con el, la pantalla puede ofrecer bajarlo.
  String? get comentarioPedido => _comentarioPedido;

  /// Si hay un comentario abierto al lado del texto.
  bool get tieneComentario => _comentario != null;

  /// El modulo del comentario abierto, o null.
  ///
  /// Y ES PARA LO QUE **NO** ESTA EN LAS NOTAS. [notasDe] da las de un versiculo y
  /// [versiculosConNota] las del pasaje que se esta leyendo; para contar las del capitulo
  /// entero hay que preguntar al modulo, y quien lo tiene abierto es este.
  ModuloAbierto? get moduloDeComentario => _comentario;

  /// Por que no se pudo abrir el comentario pedido, o null si no ha pasado nada.
  ///
  /// Y ESTO **NO ES UN FALLO DE LECTURA**, y por eso es un aviso aparte y no el
  /// `_aviso` del texto. Leer Juan 3:16 del KJV con el CLARKE pedido y no descargado es
  /// Juan 3:16 del KJV, entero y legible, con un aviso de que al lado no hay nada. Si
  /// esto fuera el estado de lectura, quien sharea un enlace desde su movil --donde si
  /// esta el comentario-- y lo abre en otro --donde no-- veria un error por algo que
  /// funciona.
  String? get motivoDelComentario => _motivoDelComentario;

  /// Las notas del versiculo [versiculo], en orden.
  ///
  /// Y SALEN DEL COMENTARIO, NO DEL PASAJE. Un `Pasaje` es de un modulo, y el versiculo
  /// con su nota no viene del mismo sitio que el versiculo con su texto: por eso hay
  /// dos y por eso esto no es `pasaje.notasDe`.
  ///
  /// Y SI NO HAY COMENTARIO, UNA LISTA VACIA Y NADA MAS. No una excepcion: sin comentario
  /// es el caso normal, el de `/leer/KJV2006/John.3.16` a secas, y el de quien todavia
  /// no ha elegido ninguno.
  List<Nota> notasDe(int versiculo) => _notas?.notasDe(versiculo) ?? const <Nota>[];

  /// Si ese versiculo tiene alguna nota.
  bool tieneNotasDe(int versiculo) => notasDe(versiculo).isNotEmpty;

  /// Los versiculos de este pasaje que tienen nota en el comentario abierto.
  List<int> get versiculosConNota => _notas?.versiculosConNota ?? const <int>[];

  /// Cuantas notas hay en el pasaje que se esta leyendo.
  int get totalDeNotas => _notas?.notas.length ?? 0;

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
    // Y ABRIR UN TEXTO CIERRA EL COMENTARIO. No es que se le olvide: cambiar de
    // traduccion es cambiar de lectura entera, y dejar el comentario del anterior al
    // lado del nuevo haria que las notas de Juan 3:16 de una traduccion anadida
    // al Juan 3:16 de otra, que es el peor sitio donde puede estar un comentario.
    _cerrarComentario();
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
    _cerrarComentario();
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
      return;
    }

    // Y LAS NOTAS SE PIDEN AL FINAL Y EN SU PROPIA FUNCION, y es lo unico que se hace
    // fuera de la del texto. La razon es la regla de este cambio: **que el comentario
    // no tenga nota para este pasaje no puede cambiar como se lee el texto**. Juan 3:1
    // no tiene nota en el CLARKE --medido--, y leer Juan 3:1 del KJV con el CLARKE al
    // lado tiene que ensefiar el versiculo, no decir que no existe.
    //
    // Y por eso `_leerNotas` no toca `_estado`, ni `_aviso`, ni `_pasaje`, ni `_ultimoValido`,
    // y ni siquiera avisa a los oyentes: si no hay comentario, no hay nada que contar y
    // un `notifyListeners` de mas es un frame rebuilding la pantalla sin motivo.
    _leerNotas(referencia);
  }

  /// Las notas del pasaje pedido, del comentario abierto. No toca nada mas.
  ///
  /// Y SE PREGUNTA SI EL COMENTARIO TIENE EL PASAJE, y no se espera una lista vacia para
  /// deducirlo. `existe` es una consulta de `count(*)` y esta es la unica forma de saber
  /// si el comentario tiene Juan 3:1 o si simplemente no comenta eso; las dos cosas dan
  /// una lista vacia y solo una de las dos es una coincidencia.
  void _leerNotas(Referencia referencia) {
    final c = _comentario;
    if (c == null) return;
    // Y UN `try` AQUI Y NO AL LLAMANTE. Un comentario que revienta al consultarse --
    // una tabla que no esta donde decia, un `.amod` cambiado por fuera-- no puede
    // llevarse por delante el texto que se estaba leyendo: lo que esta leyendo quien
    // tiene abierto Juan 3:16 del KJV es el KJV, y las notas son un extra. Sin este
    // `try`, la excepcion sale de `leer` y tumba la pantalla entera.
    try {
      _notas = c.existe(referencia) ? c.leer(referencia) : null;
    } catch (_) {
      _notas = null;
    }
  }

  /// Vuelve a pedir las notas de lo que se esta leyendo.
  ///
  /// Y ESTE METODO EXISTE POR UN FALLO MEDIDO. Al ir de Juan 3 a Juan 5 con el CLARKE
  /// al lado, las notas seguian siendo las de Juan 3: 32 notas donde --
  /// medido-- hay 43. Juan 5 ensenaba el comentario de otro pasaje sin decir nada, que
  /// es peor que no ensenar ninguno.
  ///
  /// La causa era que quien.apply el comentario compara con lo que ya hay abierto y, si
  /// es el mismo, no hace nada. Y para **abrir** eso es lo correcto --reabrir 57 MiB
  /// para volver a traer las mismas notas no tiene sentido--, pero **leerlas** es otra
  /// cosa: el pasaje ha cambiado.
  ///
  /// Y NO SE VUELVE A PEDIR SI SON LAS MISMAS, que es lo que evita que `leer` y esto se
  /// turnen y hagan un bucle de consultas.
  void refrescarNotas() {
    final ref = _pasaje?.referencia;
    if (ref == null || _comentario == null) return;
    if (_notas?.referencia == ref) return;
    _leerNotas(ref);
    notifyListeners();
  }

  /// Abre un comentario al lado del texto y pide las notas de lo que se esta leyendo.
  ///
  /// Y **NO SE TOCA EL ESTADO DE LECTURA**, ni el pasaje ni el titulo. Abrir un
  /// comentario anade algo al lado de lo que ya se estaba leyendo; si se tocara el
  /// estado, la pantalla pasaria por `cargando` y el texto que se estaba leyendo
  //// desapareceria un instante para volver a aparecer, y eso en un texto de 1832 que se
  /// esta leyendo es desconcertante.
  ///
  /// Y SE COMPRUEBA QUE SEA UN COMENTARIO. Un modulo que no trae notas se acepta --el
  /// que sea traera lo que traiga y no hay nada que suponER-- pero se avisa, porque abrir
  /// `/leer/KJV2006/John.3.16/con/KJV2006` tiene que decir algo en vez de ensenar el
  /// texto y dejar pensar que se ha equivocado la ruta.
  void abrirComentario(
    ModuloAbierto modulo, {
    required String? licenciaDelManifiesto,
  }) {
    _cerrarComentario();
    _comentario = modulo;
    _comentarioPedido = modulo.id;

    if (modulo.tieneTextosDeBiblia) {
      _motivoDelComentario =
          '${modulo.id} es un texto de Biblia, no un comentario: al lado no hay nada '
          'que ensenar.';
    } else {
      _motivoDelComentario = null;
    }

    final ref = _pasaje?.referencia;
    if (ref != null) _leerNotas(ref);
    notifyListeners();
  }

  /// Quita el comentario de al lado y deja el texto como estaba, y avisa a quien mira.
  void cerrarComentario() {
    _cerrarComentario();
    notifyListeners();
  }

  /// Lo mismo, pero sin avisar. Para cuando quien llama avisa **por su cuenta** porque
  /// esta cambiando de algo mas --el texto entero, o el final de la vida de la pantalla--,
  /// y dos `notifyListeners` seguidos reconstruyen lo mismo dos veces.
  void _cerrarComentario() {
    _comentario?.cerrar();
    _comentario = null;
    _notas = null;
    _motivoDelComentario = null;
    _comentarioPedido = null;
  }

  /// Un comentario que no se pudo abrir. El texto **sigue leido**.
  ///
  /// Y ES UN METODO Y NO UN PARAMETRO PORQUE ES LO MAS FRECUENTE. Alguien que recibe
  /// `/leer/KJV2006/John.3.16/con/CLARKE` en un movil donde el CLARKE no esta
  /// descargado --y no lo va a tener nunca si pesa 57 MiB-- tiene Juan 3:16 entero y
  /// un aviso de que al lado no hay nada. Lo raro es que **no** haya nada, no que haya
  /// algo a medias.
  void comentarioNoDisponible(String id, String motivo) {
    _cerrarComentario();
    _comentarioPedido = id;
    _motivoDelComentario = motivo;
    notifyListeners();
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
    _cerrarComentario();
    _cerrarSiHabia();
    super.dispose();
  }

  void _cerrarSiHabia() {
    _abierto?.cerrar();
    _abierto = null;
  }
}
