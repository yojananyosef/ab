// Lo que la pantalla de biblioteca muestra, y por que.
//
// UN VIEWMODEL QUE NO TOCA NADA DE PERSISTENCIA. No sabe lo que es un SQLite, ni
// un fichero, ni una peticion. Recibe datos y produce datos. Todo lo que se puede
// comprobar sin montar un widget esta aqui, y por eso casi toda la logica de esta
// pantalla se prueba sin pantalla.
//
// LO QUE NO HAY Y POR QUE. No hay cache, ni temporizadores, ni peticiones. Cada vez
// que cambia algo se vuelve a calcular desde el manifiesto y desde lo que hay en el
// dispositivo. Es lo unico que evita el fallo de MyBible, que al quedarse sin
// conexion reclasificaba todos los modulos como "solo local".
//
// Y EL ESTADO DEL FILTRO SI SE GUARDA, porque es de la sesion y no del dispositivo:
// uno escribe "espa" en el filtro, cambia de pantalla y vuelve, y espera seguir
// escribiendo "espa". Eso no se guarda en disco, y por eso no se puede quedar
// viejo.
//
// LA FILA MAS DIFICIL DE TODAS. Un modulo que ya no esta en el catalogo pero esta en
// el dispositivo tiene que seguir apareciendo, marcado como retirado, y se puede
// seguir leyendo. Es el unico caso en que hay que inventar una fila con muy poca
// informacion: no hay nombre, no hay tamano, no hay licencia. Solo el identificador
// del manifiesto, que es lo que se guardo. Y se ensena **tal cual**, sin inventar
// un nombre bonito, porque un nombre inventado seria mentira y el identificador es
// justo lo que hace falta para buscarlo.

import 'package:flutter/foundation.dart';

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/core/numeros.dart';

import 'aviso.dart';

/// Una fila de la biblioteca.
///
/// No es un `Modulo`: es un `Modulo` **mas** su estado, y a veces no hay `Modulo`.
/// Envolverlo aqui, en vez de tener un `Map<String, EstadoModulo>` al lado, evita
/// que la pantalla tenga que comprobar en cada uso si el modulo existe.
class FilaDeModulo {
  const FilaDeModulo({required this.estado, this.modulo, required this.idLocal});

  /// Lo que declara el manifiesto. Null cuando el modulo ya no esta en el catalogo.
  final Modulo? modulo;

  /// El estado, **calculado** en [BibliotecaViewModel] y no guardado.
  final EstadoModulo estado;

  /// El identificador del manifiesto. Viene del modulo, o de lo que hay en el
  /// dispositivo cuando ya no esta en el catalogo.
  final String idLocal;

  /// Lo que se ensena como titulo.
  ///
  /// El nombre del manifiesto si hay modulo. Si no hay, el identificador **tal
  /// cual**, y no un texto como "Modulo retirado": un identificador es lo que hace
  /// falta para buscarlo y un texto bonito no sirve para eso.
  String get titulo => modulo?.nombre ?? idLocal;

  /// El tamano en megabytes, o null si no se sabe.
  ///
  /// Null y no 0: un modulo retirado no tiene tamano conocido, y poner 0,0 MB
  /// seria decir que no ocupa nada, que es una informacion falsa.
  String? get megabytes => modulo?.tamanoBytes == null
      ? null
      : bytesEnCastellano(modulo!.tamanoBytes);

  /// Un id: el del manifiesto si hay, o el identificador guardado.
  String get id => modulo?.id ?? idLocal;

  /// Si el modulo esta en el dispositivo, sea del estado que sea.
  ///
  /// INCLUYE `desactualizado`, y no por comodidad. Un modulo atrasado **se lee**:
  /// la copia vieja sigue ahi, completa, y el unico efecto de estar atrasado es que
  /// hay una version nueva que se puede bajar. Excluirlo de aqui hacia que la fila no
  /// ofreciera "Leer" a alguien que tiene el texto entero en el movil, y es el fallo
  /// que hace que alguien que ya lo habia descargadono pueda leerlo.
  ///
  /// Y para el filtro "solo lo que tengo" tambien cuenta: lo tiene, aunque sea una
  /// version antigua.
  bool get descargado =>
      estado == EstadoModulo.descargado ||
      estado == EstadoModulo.desactualizado ||
      estado == EstadoModulo.retirado;
  bool get retirado => estado == EstadoModulo.retirado;
  bool get hayVersionNueva => estado == EstadoModulo.desactualizado;

  /// Si se puede leer ahora mismo.
  ///
  /// Descargado y retirado si: son los dos unicos estados con los bytes en el
  /// dispositivo. Los demas no se pueden abrir, y el boton de "Leer" no debe
  /// aparecer para no prometer lo que no se puede cumplir.
  bool get sePuedeLeer => descargado;

  /// Si se puede pedir de nuevo.
  ///
  /// `desactualizado` tambien, porque hay version nueva y bajarla es lo que quiere
  /// quien la ve marcada.
  bool get sePuedeDescargar =>
      estado == EstadoModulo.disponible || estado == EstadoModulo.desactualizado;

  @override
  String toString() => 'FilaDeModulo($id, $estado)';
}

/// Los filtros, y solo los que la pantalla tiene.
///
/// Un conjunto con los tres, y no tres campos sueltos: filtrar es "todo a la vez",
/// y con campos sueltos cada vez que se anadia uno habia que acordarse de combinarlo
/// con los otros dos.
class FiltroDeBiblioteca {
  const FiltroDeBiblioteca({
    this.texto = '',
    this.idioma,
    this.soloDescargados = false,
  });

  final String texto;

  /// El codigo ISO tal como lo declara el manifiesto: `spa`, `eng`. Null es "todos".
  final String? idioma;

  final bool soloDescargados;

  bool get vacio => texto.trim().isEmpty && idioma == null && !soloDescargados;

  FiltroDeBiblioteca copyWith({
    String? texto,
    String? idioma,
    bool? soloDescargados,
    bool limpiarIdioma = false,
  }) =>
      FiltroDeBiblioteca(
        texto: texto ?? this.texto,
        idioma: limpiarIdioma ? null : (idioma ?? this.idioma),
        soloDescargados: soloDescargados ?? this.soloDescargados,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltroDeBiblioteca &&
      other.texto == texto &&
      other.idioma == idioma &&
      other.soloDescargados == soloDescargados;

  @override
  int get hashCode => Object.hash(texto, idioma, soloDescargados);
}

class BibliotecaViewModel extends ChangeNotifier {
  /// [hashesLocales] es lo que hay en el dispositivo: id -> sha256 **de lo que hay
  /// ahi**, no el del manifiesto. Es la diferencia entre ver "descargado" y ver "hay
  /// version nueva", y sin el hash no se puede distinguir: todo local pareceria
  /// descargado y [EstadoModulo.desactualizado] no se alcanzaria nunca. Un estado
  /// inalcanzable es un estado que no existe.
  BibliotecaViewModel({
    Manifiesto? manifiesto,
    Set<String>? idsLocales,
    Map<String, String>? hashesLocales,
  })  : _manifiesto = manifiesto ?? _vacio(),
        _idsLocales = idsLocales ?? <String>{},
        _hashesLocales = hashesLocales ?? <String, String>{};

  static Manifiesto _vacio() => const Manifiesto(
    formato: 'aa-catalog/1',
    version: 'sin leer',
    etiqueta: 'sin leer',
    modulos: <Modulo>[],
  );

  Manifiesto _manifiesto;
  Set<String> _idsLocales;

  /// El sha256 de cada modulo local. Es lo que hay **de verdad** en el dispositivo,
  /// y se compara con el del manifiesto para calcular el estado.
  Map<String, String> _hashesLocales;
  FiltroDeBiblioteca _filtro = const FiltroDeBiblioteca();

  /// Los avisos, con su tipo.
  ///
  /// Y NO ES UNA LISTA DE CADENAS PORQUE ESO ES LO QUE ROMPIO LA PANTALLA. Medido el 4
  /// de octubre de 2026: con `List<String>` no hay forma de distinguir un error de un
  /// progreso, asi que todo salia en rojo, y no hay forma de reemplazar un progreso con
  /// el siguiente, asi que se acumulaban. Ver `aviso.dart`.
  List<Aviso> _avisos = const <Aviso>[];
  EstadoLectura _estadoLectura = EstadoLectura.sinConexion;
  bool _cargando = false;
  Set<String> _idsConOrigenNoLegible = <String>{};

  // --- lo que se lee ---

  Manifiesto get manifiesto => _manifiesto;

  /// Los ids que hay en el dispositivo.
  Set<String> get idsLocales => Set.unmodifiable(_idsLocales);

  /// El sha256 de lo que hay en el dispositivo, id a id.
  Map<String, String> get hashesLocales => Map.unmodifiable(_hashesLocales);

  FiltroDeBiblioteca get filtro => _filtro;

  /// Como ha ido la lectura del catalogo. La pantalla lo usa para el aviso del
  /// respaldo, y para no ensenar una lista vacia sin explicar por que.
  EstadoLectura get estadoLectura => _estadoLectura;

  bool get cargando => _cargando;

  /// Los modulos que el navegador **no deja leer**.
  ///
  /// No es lo mismo que "no estan descargados" y no es lo mismo que "no hay red".
  /// Un reintento no lo arregla: el servidor no manda cabeceras de origen cruzado, y
  /// eso no cambia por insistir. Lo unico que funciona es traer el fichero a mano.
  ///
  /// El dato lo pone la obtencion --`ObtenerModulo` devuelve `OrigenNoLegible`-- y
  /// se guarda aqui **en memoria, en esta sesion**. No se persiste: si al recargar
  /// se vuelve a comprobar y el servidor ya manda las cabeceras, esta lista tiene que
  /// estar vacia. Un dato guardado seria unaucha vez ve que "no se puede" y para
  /// siempre, y eso es exactamente el estado que se queda viejo.
  Set<String> get idsConOrigenNoLegible => Set.unmodifiable(_idsConOrigenNoLegible);

  /// Si este modulo se puede leer desde el navegador.
  ///
  /// Lo que decide que no: el navegador, no el codigo. En nativo la respuesta es
  /// siempre que si, porque no hay cabeceras de origen cruzado que mandar.
  bool origenNoLegible(String id) => _idsConOrigenNoLegible.contains(id);

  /// Los avisos del repositorio, mas los propios de la pantalla.
  List<Aviso> get avisos => List.unmodifiable(_avisos);

  /// Solo los que son un fallo. Para ensenarlos como errores.
  List<Aviso> get avisosDeError =>
      List<Aviso>.unmodifiable(_avisos.where((a) => a.esError));

  /// Si hay algo que no ha ido bien.
  bool get hayErrores => _avisos.any((a) => a.esError);

  /// El progreso de cada modulo que se esta bajando ahora mismo, por id.
  ///
  /// Y ES UN MAPA Y NO UNA LISTA PORQUE SE BUSCA POR ID. La fila de un modulo esta
  /// preguntando "cuanto lleva mi descarga", y con una lista habria que recorrerla
  /// entera por fila y por fotograma. Ademas, con dos descargas a la vez --que se puede
  /// -- el mapa no se confunde: cada modulo tiene su entrada.
  Map<String, int> get progresoPorModulo {
    final salida = <String, int>{};
    for (final a in _avisos) {
      final id = a.id;
      final pct = a.porcentaje;
      if (id != null && pct != null) salida[id] = pct;
    }
    return Map<String, int>.unmodifiable(salida);
  }

  // --- lo que se calcula ---

  /// Las filas, con su estado, **en el orden en que se pintan**.
  ///
  /// El orden es el del manifiesto, y no se reordena por tamano ni por estado. Es
  /// una decision: reordenar cada vez que cambia un estado hace que una fila se
  /// mueva debajo del dedo mientras se le esta pulsando, y en un movil eso es un
  /// fallo de verdad. El manifiesto ya viene ordenado.
  List<FilaDeModulo> get filas {
    final salida = <FilaDeModulo>[];

    for (final m in _manifiesto.modulos) {
      // El hash local es el que **calculamos al obtener el modulo**. Si no lo
      // sabemos --indice perdido, o un modulo escrito por una version anterior-- se
      // usa el del manifiesto, que hace que salga "descargado". Es una afirmacion de
      // la app sin comprobar, y es preferible a leer 22 MiB para pintar una fila.
      final shaLocal = _hashesLocales[m.id];
      final estado = calcularEstado(
        sha256DelCatalogo: m.sha256,
        enDispositivo: _idsLocales.contains(m.id)
            ? EstadoEnDispositivo.presente(shaLocal ?? m.sha256)
            : const EstadoEnDispositivo.ausente(),
        descargando: false,
        estaEnElCatalogo: true,
      );
      salida.add(FilaDeModulo(estado: estado, modulo: m, idLocal: m.id));
    }

    // Lo que esta en el dispositivo y el catalogo ya no ofrece. Se anade al final,
    // porque son cosas que ya no se pueden actualizar y no deben empujar hacia
    // abajo lo que si.
    for (final id in _idsLocales) {
      if (_manifiesto.porId(id) != null) continue;
      salida.add(
        FilaDeModulo(
          estado: EstadoModulo.retirado,
          modulo: null,
          idLocal: id,
        ),
      );
    }

    return salida;
  }

  /// Las filas despues de aplicar el filtro.
  ///
  /// El filtrado va **aqui**, y no en el `build`. Una lista filtrada dentro de
  /// `build` se recalcula en cada fotograma, y con el scroll de una lista de dos
  ///cientos modulos eso se nota en un movil.
  List<FilaDeModulo> get filasFiltradas {
    final t = _filtro.texto.trim().toLowerCase();
    return filas.where((f) {
      if (_filtro.soloDescargados && !f.descargado) return false;

      final idioma = _filtro.idioma;
      if (idioma != null && idioma.isNotEmpty) {
        // Una fila retirada no tiene idioma conocido, asi que un filtro por idioma
        // la oculta. Es lo correcto: si pides "espa" quieres Biblias en espanol,
        // no un modulo del que no se sabe nada.
        final m = f.modulo;
        if (m == null || m.idioma != idioma) return false;
      }

      if (t.isEmpty) return true;
      final m = f.modulo;
      if (m == null) return f.idLocal.toLowerCase().contains(t);
      return m.nombre.toLowerCase().contains(t) ||
          m.id.toLowerCase().contains(t) ||
          m.idioma.toLowerCase().contains(t) ||
          m.licencia.toLowerCase().contains(t) ||
          m.tipo.enElCatalogo.contains(t) ||
          // Y las dos ultimas por el texto que **se ensena**. La fila muestra
          // "dominio publico" y "comentario", y si el filtro solo busca `PublicDomain`
          // y `commentary`, quien escribe lo que ve no encuentra nada. Es el mismo
          // criterio que en `Manifiesto._coincide`, y por eso las dos formas se
          // comprueban aqui y alli: si divergen, hay una pantalla en la que se busca
          // una cosa y un filtro que busca otra.
          _textoDeLicencia(m.licencia).contains(t) ||
          _textoDeTipo(m.tipo).contains(t);
    }).toList();
  }

  /// Los idiomas que hay **de verdad** en el manifiesto, ordenados.
  ///
  /// Los que hay, y no una lista fija de idiomas posibles: una lista fija seria
  /// exactamente el tipo de dato que no debe estar escrito en el codigo de la app.
  /// Y si el catalogo no declara ningun idioma, esta vacia y el selector dice que
  /// no hay, en vez de ofrecer un desplegable con opciones que no llevan a nada.
  List<String> get idiomas => _manifiesto.idiomas;

  /// Que el filtro activo **no** deja nada.
  ///
  /// Es distinto de "el catalogo esta vacio", y la pantalla lo dice de forma
  /// distinta. "No hay nada en el catalogo" es un problema del servidor. "No hay nada
  /// que case con tu filtro" es un problema de lo que ha escrito la persona, y la
  /// solucion es distinta: quitar el filtro.
  bool get filtroSinResultados => _filasVacias && !_filtro.vacio;

  bool get catalogoVacio => _filasVacias && _filtro.vacio;

  bool get _filasVacias => filasFiltradas.isEmpty;

  // --- lo que se hace ---

  /// Acepta lo que devuelve el repositorio y recalcula.
  void aplicarResultado(
    ResultadoCatalogo resultado, {
    Set<String>? idsLocales,
    Map<String, String>? hashesLocales,
  }) {
    _manifiesto = resultado.manifiesto;
    _estadoLectura = resultado.estado;

    // Y LOS DEL REPOSITORIO SON **INFORMACION**, salvo los que el propio repositorio
    // marco como error. El repositorio ya los separa, y convertirlos todos a
    // informacion seria tirar esa distincion; convertirlos todos a error seria lo que
    // hay: una columna de cajas rojas. Se respeta lo que cada uno es.
    _avisos = <Aviso>[
      for (final a in resultado.avisos)
        Aviso.esteTexto(a, clase: _claseDe(a, resultado.estado)),
    ];
    if (idsLocales != null) _idsLocales = Set<String>.from(idsLocales);
    if (hashesLocales != null) _hashesLocales = Map<String, String>.from(hashesLocales);
    notifyListeners();
  }

  /// Cambia lo que hay en el dispositivo. No avisa a nadie mas que a la pantalla.
  /// Actualiza lo que hay en el dispositivo.
  ///
  /// [hashes] es lo que hay **de verdad**, y por eso el estado se puede calcular. Si
  /// un id viene sin hash, se cuenta como descargado sin comprobar: es lo unico
  /// honesto que se puede decir sin leer el fichero.
  void actualizarIdsLocales(Set<String> ids, {Map<String, String>? hashes}) {
    final mismosIds = _idsLocales.length == ids.length && _idsLocales.containsAll(ids);
    final mismosHashes =
        hashes == null || _mismosHashes(hashes, _hashesLocales);
    if (mismosIds && mismosHashes) return;

    _idsLocales = Set<String>.from(ids);
    if (hashes != null) _hashesLocales = Map<String, String>.from(hashes);

    // Un modulo que se ha descargado ya no depende de que el servidor deje leerlo, y
    // dejarlo anotado haria que la fila pidiera un fichero local que no hace falta.
    if (_idsLocales.isNotEmpty) {
      _idsConOrigenNoLegible = <String>{..._idsConOrigenNoLegible}..removeAll(_idsLocales);
    }
    notifyListeners();
  }

  bool _mismosHashes(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);

  void filtrarPorTexto(String texto) {
    if (texto == _filtro.texto) return;
    _filtro = _filtro.copyWith(texto: texto);
    notifyListeners();
  }

  void filtrarPorIdioma(String? idioma) {
    if (idioma == _filtro.idioma) return;
    _filtro = idioma == null
        ? _filtro.copyWith(limpiarIdioma: true)
        : _filtro.copyWith(idioma: idioma);
    notifyListeners();
  }

  void alternarSoloDescargados() {
    _filtro = _filtro.copyWith(soloDescargados: !_filtro.soloDescargados);
    notifyListeners();
  }

  void limpiarFiltros() {
    if (_filtro.vacio) return;
    _filtro = const FiltroDeBiblioteca();
    notifyListeners();
  }

  void marcarCargando(bool valor) {
    if (_cargando == valor) return;
    _cargando = valor;
    notifyListeners();
  }

  /// Anota que el navegador no deja leer un modulo.
  ///
  /// Se llama **despues** de un intento fallido, no antes: hasta que no se ha
  /// intentado, no se sabe. Y ademas se quita la anotacion en cuanto el modulo se
  /// descarga, porque ahi ya esta el fichero y da igual lo que conteste el
  /// servidor.
  void anotarOrigenNoLegible(String id) {
    if (_idsConOrigenNoLegible.contains(id)) return;
    _idsConOrigenNoLegible = <String>{..._idsConOrigenNoLegible, id};
    notifyListeners();
  }

  void quitarOrigenNoLegible(String id) {
    if (!_idsConOrigenNoLegible.contains(id)) return;
    _idsConOrigenNoLegible = <String>{..._idsConOrigenNoLegible}..remove(id);
    notifyListeners();
  }

  /// Un aviso a medida de la pantalla, para lo que el repositorio no sabe.
  ///
  /// Los avisos de la pantalla van **encima** de los del repositorio, no
  /// mezclados: son cosas distintas y no tienen que verse juntas.
  void anadirAviso(
    String aviso, {
    ClaseDeAviso clase = ClaseDeAviso.informacion,
  }) {
    _avisos = <Aviso>[Aviso.esteTexto(aviso, clase: clase), ..._avisos];
    _recortar();
    notifyListeners();
  }

  /// El progreso de una descarga, **reemplazando** el anterior del mismo modulo.
  ///
  /// Y ESTO ES LO QUE ARREGLA LA PANTALLA DE LA CAPTURA. Antes se anadia un aviso por
  /// cada diez por ciento y ninguno se iba: un comentario de 57 MiB dejaba diez lineas
  /// "Bajando CLARKE: X por ciento" para siempre, y como no cabian, tapaban la lista de
  /// modulos. Aqui la clave `progreso:$id` hace que el 90 por ciento **sustituya** al 80.
  void progresoDeDescarga(String id, int porcentaje) {
    final clave = 'progreso:$id';
    _avisos = <Aviso>[
      Aviso.progreso(id, porcentaje),
      // Y SE QUITA EL ANTERIOR DE ESE MISMO MODULO, y solo ese: los progresos de los
      // demas siguen. Con dos descargas a la vez, quitar todos los de progreso habria
      // borrado el de la que iba bien.
      for (final a in _avisos)
        if (a.clave != clave) a,
    ];
    _recortar();
    notifyListeners();
  }

  /// Quita el progreso de un modulo. Cuando ha terminado, deja de estar bajandose.
  ///
  /// Y SE QUITA Y NO SE CAMBIA POR "listo", porque el progreso ya no es verdad: el
  /// modulo ya esta en el dispositivo, y la fila lo dice con su estado. Dejarlo
  ///("", "al 100 por ciento de bajando X") para siempre es mentira.
  void quitarProgreso(String id) {
    final clave = 'progreso:$id';
    if (!_avisos.any((a) => a.clave == clave)) return;
    _avisos = <Aviso>[for (final a in _avisos) if (a.clave != clave) a];
    notifyListeners();
  }

  /// Quita un aviso, por su texto.
  ///
  /// Para los que se resuelven solos: "este modulo no se ha podido abrir" deja de ser
  /// verdad en cuanto se abre, y si se queda teaches que hay un problema que no hay.
  void quitarAviso(String texto) {
    final antes = _avisos.length;
    _avisos = <Aviso>[for (final a in _avisos) if (a.texto != texto) a];
    if (_avisos.length != antes) notifyListeners();
  }

  /// Quita todos los errores, y solo los errores.
  ///
  /// Que es el boton de "se han ido los avisos" de la pantalla. No quita los de
  /// informacion: el aviso de "estas viendo una copia del catalogo del martes" no lo
  /// ha pedido la persona y no se quita porque a ella le parezca molesto.
  void quitarErrores() {
    if (!_avisos.any((a) => a.esError)) return;
    _avisos = <Aviso>[for (final a in _avisos) if (!a.esError) a];
    notifyListeners();
  }

  /// Deja los avisos en un numero que cabe en la pantalla.
  ///
  /// Y SE CUENTA EN AVISOS, NO EN LINEAS, y no se corta la lista a un numero fijo de
  /// lineas porque un aviso largo ocupa mas que uno corto y a 360 px eso es la
  /// diferencia entre "caben cuatro" y "caben uno".
  ///
  /// Y EL CORTE ES POR LO **ULTIMO**, que es como se lee: lo mas reciente esta mas
  /// cerca de donde esta el ojo. Un aviso de hace media hora no se ve, y no se ve a
  /// proposito: si sigue siendo verdad, esta en su fila.
  void _recortar() {
    const maximo = 4;
    if (_avisos.length <= maximo) return;
    _avisos = _avisos.take(maximo).toList();
  }

  /// De que clase es un aviso del repositorio.
  ///
  /// Y NO SE ADIVINA POR EL TEXTO, aunque el texto delata el caso: es una regla
  /// escrito dos veces, y las dos se rompen por separado la primera que cambia un
  /// texto. Lo que decide es el **estado de la lectura**, que es un dato, y el estado
  /// no cambia de texto.
  static ClaseDeAviso _claseDe(String aviso, EstadoLectura estado) => switch (estado) {
    // Sin catalogo no se puede ni ofrecer la lista: eso es un fallo, y no
    // informar de ello y ensenar una lista vacia es justo el fallo que ya se cometio
    // una vez y esta escrito en `AGENTS.md`.
    EstadoLectura.sinConexion => ClaseDeAviso.error,
    EstadoLectura.hashIncorrecto => ClaseDeAviso.error,
    EstadoLectura.ilegible => ClaseDeAviso.error,
    // Del servidor y de una copia guardada si sale bien: no hay nada roto.
    EstadoLectura.delServidor => ClaseDeAviso.informacion,
    EstadoLectura.deCopiaGuardada => _claseDeCopiaGuardada(aviso),
  };

  /// El unico aviso de "todo va bien pero con una copia vieja", que es informacion.
  ///
  /// Y SE DISTINGUE POR EL TEXTO PORQUE ES EL UNICO CASO QUE LO NECESITA: el estado
  /// `deCopiaGuardada` significa "funciona, con lo de ayer", y eso no es un error. El
  /// resto de avisos de ese estado son de la propia lectura del manifiesto y ya llevan
  /// su clase.
  static ClaseDeAviso _claseDeCopiaGuardada(String aviso) =>
      aviso.toLowerCase().contains('copia guardada')
      ? ClaseDeAviso.informacion
      : ClaseDeAviso.error;
}

/// La licencia como se ensena. Va aqui porque el filtro tiene que buscar **lo que la
/// fila escribe**, y si esa conversion vive solo en la vista, el filtro y la pantalla
/// divergen en cuanto una cambia sin la otra.
String _textoDeLicencia(String licencia) =>
    switch (licencia) { 'PublicDomain' => 'dominio publico', _ => licencia };

/// El tipo como lo lee la gente.
String _textoDeTipo(TipoModulo t) =>
    switch (t) { TipoModulo.biblia => 'biblia', TipoModulo.comentario => 'comentario' };
