// El enrutador de la aplicacion: que pantalla se ve y que pone en la barra.
//
// QUE HACE ESTE FICHERO Y POR QUE NO HAY UN ENRUTADOR DE TERCEROS. Hay dos
// pantallas y cuatro rutas. Un `go_router` resolveria lo mismo con una tabla de
// rutas, un `builder` por pantalla y una documentacion aparte, y para dos pantallas
// eso es mas configuracion que codigo. Cuando haya diez rutas y tres anidamientos la
// conclusion es la contraria y habra que traerse uno; mientras tanto, leer un `switch`
// es mas rapido que leer una tabla.
//
// LO IMPORTANTE DE ESTE FICHERO: LA BARRA DE DIRECCIONES MANDA.
//
// Con `MaterialApp.router`, la ruta es estado de verdad, no una decoracion. De eso
// salen gratis las dos cosas de la tarea 7.4 --recargar conserva el pasaje y "atras"
// vuelve a la biblioteca-- solo por tenerlas bien hechas:
//
//   - Al arrancar, el `Router` pregunta al navegador cual es la ruta y la pone aqui.
//   - Al pulsar "atras", el navegador cambia la ruta, el `Router` avisa, y aqui se
//     reconstruye la pantalla desde la direccion. Sin codigo de "atras" que mantener.
//
// Y NO HAY ESTADO DE PASAJE QUE PUEDA QUEDARSE VIEJO. La pantalla de lectura no
// guarda "donde estaba": guarda el pasaje que le pide la ruta. Si el historial y la
// pantalla no pueden discrepar, es porque no hay dos.
//
// ============================================================================
// PUSH O REPLACE, Y POR QUE ESTA EN UN METODO LLAMADO `_reportarAlFramework`.
// ============================================================================
//
// ESTA ES LA TAREA 7.5 Y LA RAZON DE QUE ESTE FICHERO EXISTA.
//
// El framework decide entre `pushState` y `replaceState` por el
// `RouteInformationReportingType` que el delegado reporte, y la regla esta en el
// propio SDK: `PlatformRouteInformationProvider.routerReportsNewRouteInformation`
// pasa `replace: false` para `navigate` y `replace: true` para `neglect`.
//
//   - `navigate` -> `pushState`. Anade una entrada. "Atras" deshace el cambio.
//   - `neglect`  -> `replaceState`. Cambia la actual. "Atras" NO lo deshace.
//   - `none`     -> lo que toque; el framework compara con la ruta que ya tenia el
//                   motor. Demasiado sutil para fiarse de el.
//
// La regla de este proyecto, con el motivo de cada mitad:
//
//   - CAMBIAR DE CAPITULO, VERSICULO O LIBRO: `navigate`. Alguien que lee Juan 3 y
//     pasa a Juan 4 y pulsa "atras" quiere volver a Juan 3. Es lo que espera de
//     cualquier sitio donde se lee.
//
//   - CAMBIAR DE VERSION O DE AJUSTE: `neglect`. Cambiar el tamaño de la letra o la
//     traduccion **no es ir a otro sitio**: es seguir donde estabas con otro ajuste.
//     Con `navigate`, "atras" desharia el ajuste y dejaria a alguien que solo queria
//     letra grande con la letra pequena otra vez, y tendria que pulsar "atras" otra
//     vez para volver al pasaje. Un ajuste que se pierde con "atras" es un ajuste que
//     la gente no usa.
//
// Y POR QUE NO SE USA `none`, QUE ES LO QUE HARIA `MaterialApp` SIN ESTO. Porque
// `none` deja la decision en el comparador del motor, y el comparador dice "si la
// ruta es igual, sustituye". Un ajuste que no cambia de ruta --aumentar la letra no
// cambia `/leer/KJV2006/John.3.16`-- se resuelve como "igual" y se sustituye, que es
// lo que queremos por casualidad y no por decision. El dia que ese comparador cambie
// un detalle, el ajuste empezara a entrar en el historial sin que nadie se entere.
//
// LO QUE NO HAY AQUI. No hay historial propio, ni de "donde vine", ni de
// "literatura": se recorta la sesion actual. Eso lo decide el framework.
//
// LA DIFERENCIA ENTRE UN LECTOR Y OTRO SE COMPRUEBA EN DOS SITIOS, Y HAY QUE DECIR
// CUAL ES CUAL. En la maquina de Dart no hay `history` del navegador, asi que aqui se
// comprueba **que tipo reporta el delegado**, que es el interruptor que decide entre
// `pushState` y `replaceState`. Que el navegador lo cumpla se comprueba con el script
// del grupo 8, que abre Chrome de verdad y mira `history.length` antes y despues.
// Ninguno vale sin el otro: el primero no puede fallar y el segundo no puede mentir,
// pero cada uno se puede equivocar solo.
//
// ============================================================================
// POR QUE NO HAY `Navigator` AQUÍ
// ============================================================================
//
// Con una sola pantalla, un `Navigator` no puede hacer `pop`: su pila tiene una
// pagina y no hay a donde volver. El boton de atras de Android --y la ESC en
// escritorio-- lo que hacen es llamar a [popRoute] en el delegado, y lo que hay que
// decidir es si esto se resuelve aqui o se deja salir de la aplicacion. Esa decision
// es codigo de este proyecto, no del framework, asi que va aqui y con
// [Navigator.maybePop] no hay nada que decidir.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/indice_de_strong.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/ui/core/rutas.dart';
import 'sonda_nativa.dart'
    if (dart.library.js_interop) 'sonda_web.dart' as plataforma;
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/busqueda/view_models/busqueda_view_model.dart';
import 'package:ab/ui/features/busqueda/views/busqueda_view.dart';
import 'package:ab/ui/features/indice/view_models/indice_view_model.dart';
import 'package:ab/ui/features/indice/views/indice_view.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_libros.dart';
import 'package:ab/ui/features/lector/widgets/marco_de_estudio.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_versiones.dart';
import 'package:ab/ui/features/biblioteca/views/biblioteca_view.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_comentarios.dart';

/// Como se reporta un cambio de ruta, y que significa en el historial del navegador.
///
/// Va en un `enum` con nombre y no como `RouteInformationReportingType` en el codigo
/// porque los tres valores hacen cosas distintas y equivocarse es **silencioso**:
/// `none` funciona y hace casi lo que se quiere, y por eso es el peligroso. Al
/// nombrarlos, usar el equivocado es un error de lectura.
enum TipoDeCambioDeRuta {
  /// Se entra a otro sitio. `pushState`: "atras" deshace el cambio.
  entrar,

  /// Se cambia el ajuste sin salir de aqui. `replaceState`: "atras" no lo deshace.
  ajustar;

  RouteInformationReportingType get paraElFramework => switch (this) {
        TipoDeCambioDeRuta.entrar => RouteInformationReportingType.navigate,
        TipoDeCambioDeRuta.ajustar => RouteInformationReportingType.neglect,
      };
}

/// Que sabe hacer el delegado para abrir un texto.
///
/// Son un callback y no mas, y es el unico momento en que hace falta algo de fuera:
/// cuando se llega a una ruta de lectura hay que abrir un modulo, y abrirlo necesita
/// los bytes guardados y el manifiesto. Lo demas --leer el pasaje, pintar el aviso,
/// los terminos-- lo hace el ViewModel, que ya esta probado.
///
/// El callback es **asincrono** a proposito, y no por estilo. Abrir un modulo
/// significa leer sus bytes del almacenamiento, y eso en el navegador es una lectura
/// del sistema de ficheros virtual: si fuera sincrono, la pantalla no podria pintar
/// mientras ocurre y en un `.amod` de 57 MiB se notaria.
typedef AperturaDeModulo = Future<ModuloAbierto?> Function(String id, Referencia referencia);

/// Un [ModuloAbierto] con los libros y las primeras frases, para el selector.
///
/// Y OTRO ENVOLTORIO IGUAL QUE EL DE LA BUSQUEDA Y EL DEL INDICE, y no uno que sirva
/// para los tres. Cada interfaz es pequena y son tres llamadas; un modulo unico con los
/// metodos de tres pantallas seria una clase que depende de las tres.
class _ModuloConLibrosReal implements ModuloConLibros {
  _ModuloConLibrosReal(this._modulo);

  final ModuloAbierto _modulo;

  @override
  Map<String, List<int>> librosConCapitulos() => _modulo.librosConCapitulos();

  @override
  Map<int, String> primeraFraseDeCapitulos(String libro) =>
      _modulo.primeraFraseDeCapitulos(libro);
}

/// Un [ModuloAbierto] que se puede indexar por palabra del lexicon.
///
/// Y OTRO ENVOLTORIO IGUAL QUE EL DE LA BUSQUEDA, y no uno solo que sirva para los dos.
/// Cada interfaz es pequena y se implementa con las tres llamadas de la suya; un modulo
/// unico con metodos de las dos pantallas seria una clase que depende de las dos.
class _ModuloIndiciableReal implements ModuloIndiciable {
  _ModuloIndiciableReal(this._modulo);

  final ModuloAbierto _modulo;

  @override
  int versiculosConStrong(String numero) => _modulo.versiculosConStrong(numero);

  @override
  List<IndiceDeStrong> indiceDeStrong(String numero) => _modulo.indiceDeStrong(numero);

  @override
  Map<String, int> formasDeStrong(String numero) => _modulo.formasDeStrong(numero);
}

/// Un [ModuloAbierto] que sabe Buscar, para la pantalla de busqueda.
///
/// Y ES UN ENVOLTORIO Y NO EL `ModuloAbierto` DIRECTO, porque la pantalla de busqueda
/// depende de la interfaz `ModuloBuscable` y no de la clase entera: ver el por que en
/// `busqueda_view_model.dart`. En la aplicacion solo hay uno de estos, y se crea aqui y
/// no en un contenedor de inyeccion porque no hay contenedor: hay un sitio --el
/// enrutador-- que sabe que existe una pantalla de busqueda, y ese es el sitio.
class ModuloBuscableReal implements ModuloBuscable {
  ModuloBuscableReal(this._modulo);

  final ModuloAbierto _modulo;

  @override
  Future<BusquedaEnElModulo> buscar(String palabra) async =>
      _modulo.buscar(palabra);
}

/// El delegado: sabe que pantalla va y como se dice eso al navegador.
class NavegadorAb extends RouterDelegate<Ruta> with ChangeNotifier {
  NavegadorAb({
    required this.biblioteca,
    required this.lector,
    required this.abrir,
    this.proveedor,
    this.descargar,
    this.abrirFicheroLocal,
    this.reintentarCatalogo,
  }) {
    // Y SE ESCUCHA DESDE EL CONSTRUCTOR Y NO CUANDO TOCA LEER, porque la descarga puede
    // terminar con la biblioteca delante --el caso normal-- y con el lector delante --el
    // caso del enlace compartido, que es el que hace falta--.
    biblioteca.addListener(_alCambiarLaBiblioteca);
  }

  final BibliotecaViewModel biblioteca;
  final LectorViewModel lector;

  /// La pantalla de busqueda.
  ///
  /// Y SE CREA AQUI Y NO EN `main.dart`, y no por descuido: `main.dart` compone lo que
  /// existe desde el principio y esta pantalla se ha anadido despues, asi que ahi seria
  /// un segundo sitio al que volver cuando se anada la siguiente. El enrutador es el
  /// unico que sabe que hay tres pantallas.
  final BusquedaViewModel _busqueda = BusquedaViewModel();

  /// La pantalla del indice de una palabra del lexicon.
  ///
  /// Y EL TERCER VIEWMODEL QUE EL ENRUTADOR CREA, y por el mismo motivo que el segundo:
  /// `main.dart` compone lo que existe desde el principio, y ahi seria un segundo sitio al
  /// que volver cuando se anada la siguiente pantalla.
  final IndiceViewModel _indice = IndiceViewModel();
  final AperturaDeModulo abrir;

  /// Lo que hace la biblioteca que el enrutador no sabe hacer: descargar, abrir un
  /// fichero del dispositivo y reintentar el catalogo.
  ///
  /// Son **opcionales** y no `late final` con valor por defecto. Un `late final` sin
  /// inicializar que se lee antes de que nadie lo ponga lanza `LateInitializationError`
  /// en pantalla, y eso es un fallo que solo aparece si el enrutador construye su
  /// pantalla antes de que `main.dart` tenga las piezas --justo lo que pasaria en
  /// cualquier prueba que monte el delegado sin ellas. Con opcionales, montar el
  /// enrutador es siempre valido y lo que no se ha enchufado no hace nada.
  final void Function(String id)? descargar;
  final void Function(String id)? abrirFicheroLocal;
  final VoidCallback? reintentarCatalogo;

  /// La ruta de ahora. Es todo el estado del enrutador: no hay una pantalla
  /// "anterior" guardada en ningun sitio.
  Ruta _ruta = const RutaBiblioteca();

  /// Abre solo, en cuanto esten, los modulos que la ruta pide y todavia faltaban.
  ///
  /// Y ESTA ESCUCHA A LA BIBLIOTECA Y NO HAY NADA MAS, y es la unica parte de este
  /// fichero que mira una pantalla ajena. Hace falta por una cadena que si no esta rota:
  /// alguien pide el comentario, no esta, se ofrece bajarlo, se baja 57 MiB, y hasta
  /// aqui no habria forma de volver a abrirlo --porque quien pide una descarga es la
  /// biblioteca, y quien aplica una ruta es este enrutador--, asi que quien lo pidio se
  /// queda con el texto y el comentario a medio bajar.
  ///
  /// Y SOLO MIRA UNA COSA: que el identificador pedido este ahora entre los descargados.
  /// La biblioteca avisa de los progresos, de los errores y de los filtros, y con
  /// cualquier otro aviso esta comprobacion se cumple igual y se abriria el comentario
  /// otra vez en cada barra de progreso.
  ///
  /// ============================================================================
  /// Y ADEMAS **AVISA SIEMPRE**, Y ANTES NO LO HACIA NUNCA. ESTO ERA UN FALLO REAL.
  /// ============================================================================
  ///
  /// Medido el 5 de octubre de 2026 en una captura de la pantalla de lectura a 360 px con
  /// Juan 3:16 abierto y el modulo entero ya en el `IndexedDB`: **la segunda linea de la
  /// barra, con el nombre de la version, no salia**. Se espero 20 s. No era tiempo: era
  /// que el enrutador escuchaba a la biblioteca solo para el comentario y **no llamaba a
  //  `notifyListeners()`**, con lo que la pantalla de lectura se quedaba con la lista de
  //  versiones que tenia cuando se construyo --vacia, porque el manifiesto todavia no
  //  habia llegado-- para siempre.
  ///
  /// Y POR QUE NO SE VIO ANTES. El nombre de la version es texto de la barra, y la sonda
  /// del navegador lee el **pasaje**; `flutter test` montaba la pantalla con la lista ya
  /// puesta a mano. Los dos dan verde con el bug puesto: hace falta mirar la imagen.
  ///
  /// Y AVISA EN CADA AVISO DE LA BIBLIOTECA, con lo que repinta la pantalla en cada barra
  /// de progreso de una descarga de 57 MiB. Es trabajo de sobra y no se nota, y aun asi
  /// es lo correcto: la lista de versiones y los tamanos **son** datos de la biblioteca y
  /// la pantalla los lee, asi que cuando la biblioteca cambia hay que redibujar lo que la
  //  lee. Lo que no se puede es repintar por la descarga del comentario, que es lo que
  //  hacia antes.
  void _alCambiarLaBiblioteca() {
    notifyListeners();

    final ruta = _ruta;
    if (ruta is! RutaLectura) return;
    final comentario = ruta.comentario;
    if (comentario == null) return;
    if (lector.idDelComentario == comentario) return;
    if (!biblioteca.idsLocales.contains(comentario)) return;
    unawaited(_aplicarComentario(comentario));
  }

  @override
  Ruta get currentConfiguration => _ruta;

  /// La ruta, como [currentConfiguration]. Un alias y nada mas.
  ///
  /// Existe por la sonda, que habla de "la ruta" y no del "estado del enrutador", y
  /// porque el nombre del getter del framework no dice de quien es.
  Ruta get ruta => _ruta;

  // --- 7.5 en el navegador: el historial de verdad ---
  //
  // LO UNICO QUE NO SE PUEDE COMPROBAR EN DART, Y POR QUE ESTA EN EL ENRUTADOR Y NO EN
  // LA SONDA. [SystemNavigator.routeInformationUpdated] decide entre `pushState` y
  // `replaceState` segun el tipo que reporta el delegado, y lo unico que se puede hacer
  // con eso en Dart es mirar el tipo --que es lo que comprueba `navegador_test.dart`--.
  // Que `pushState` **anada** una entrada y que `replaceState` no lo haga solo se ve
  // preguntando a `window.history.length`, y eso es un navegador.
  //
  // Y MIDUR DOS VECES, ANTES Y DESPUES, Y NO "EL NUMERO QUE HAY". El numero absoluto
  // depende de cuanto ha cargado antes el perfil y no dice nada. Lo que dice es si ha
  // **crecido**.
  //
  // Y SE VUELVE AL PASAJE DEL QUE SE SALIO, con `replaceState`, para no dejar el
  // historial con una entrada de mas y para que lo que sigue mirando la sonda siga en
  // pantalla. Con `pushState` al volver, el perfil acabaria con una entrada que hizo la
  // propia comprobacion, y la segunda ejecucion --la de la tarea 8.3-- mediria distinto.
  Future<Map<String, Object?>> medirElHistorial() async {
    final ahora = _ruta;
    if (ahora is! RutaLectura) {
      return <String, Object?>{'medido': false, 'motivo': 'no se esta leyendo nada'};
    }

    final antes = await _longitudDelHistorialEstable();
    final otroCapitulo =
        ahora.referencia.capitulo == 1 ? 2 : ahora.referencia.capitulo - 1;

    // Un cambio de capitulo: `navigate`, o sea `pushState`.
    await irA(RutaLectura(
      ahora.modulo,
      Referencia(ahora.referencia.libro, otroCapitulo),
      ahora.comentario,
    ));
    final trasCapitulo = await _longitudDelHistorialEstable();

    // Y `ajustarA(ahora)` lleva el comentario porque `ahora` lo lleva. Sin eso, medir el
    // historial **quitaria** el comentario y lo que se mediria despues ya no es la ruta
    // que se esta leyendo: en la comprobacion en navegador se veía un resultado final con
    // `ruta: .../John.3.16` y `comentario: null` despues de haberlo abierto todo, y
    // ningun fallo visible: la propia comprobacion se habia deshecho a si misma.
    //
    // Un ajuste: `neglect`, o sea `replaceState`. Es el mismo `ajustarA` que usaria un
    // cambio de letra o de version, con una ruta que no lleva a otra pagina.
    await ajustarA(ahora);
    final trasAjuste = await _longitudDelHistorialEstable();

    // Y otro `pushState`, para comprobar tambien que entrar dos veces cuenta dos. No es
    // un dato de sobra: si el ajuste hubiera sido `pushState`, los numeros habrian
    // subido de uno en uno y este caso lo delata.
    await irA(ahora);
    final trasOtro = await _longitudDelHistorialEstable();

    return <String, Object?>{
      'medido': true,
      'antes': antes,
      'trasCambioDeCapitulo': trasCapitulo,
      'trasCambioDeAjuste': trasAjuste,
      'trasOtroCambioDeCapitulo': trasOtro,
    };
  }

  // --- lo que el framework pregunta ---

  /// El navegador ha cambiado de ruta --ha recited `Atras`, o se ha abierto un
  /// enlace-- y hay que reconstruir desde ahi.
  ///
  /// No se distingue de un arranque: las dos cosas son "la direccion es esta". Y es
  /// mejor asi, porque distinguirlo pediria una bandera que se puede quedar puesta y
  /// entonces "atras" deja de funcionar sin que se note.
  @override
  Future<void> setNewRoutePath(Ruta configuration) async {
    await _aplicar(configuration);
  }

  /// Que tipo se reporta al proveedor. Visible para las pruebas, y solo para ellas.
  ///
  /// Devuelve null si el framework todavia no ha dado ningun proveedor, que es lo que
  /// pasa en pruebas y antes del primer frame. No es un fallo: sin proveedor no hay
  /// barra de direcciones que escribir.
  RouteInformationReportingType? get tipoReportado => _tipoReportado;
  RouteInformationReportingType? _tipoReportado;

  /// La ultima ruta que se reporto, para comprobar cual se escribio.
  Ruta? get ultimaRutaReportada => _ultimaRutaReportada;
  Ruta? _ultimaRutaReportada;

  // --- lo que se pide desde dentro ---

  /// Ir a un pasaje. Es `pushState`: entrar a Juan 4 desde Juan 3 y pulsar "atras"
  /// tiene que devolver a Juan 3.
  ///
  /// Con `RutaDesconocida` no se hace nada, y con motivo: no hay ningun sitio al que
  /// ir con una ruta que no se entiende, y fingir que si --ir a la biblioteca-- seria
  /// un fallo disfrazado de acierto.
  Future<void> irA(Ruta ruta) => _irA(ruta, TipoDeCambioDeRuta.entrar);

  /// Cambiar un ajuste sin salir de aqui. Es `replaceState`.
  ///
  /// Y es un metodo aparte, no un `irA` con un parametro, porque el error de
  /// confundirlos **no se ve**: las dos llamadas funcionan y la barra se actualiza
  /// igual. Lo unico que cambia es si "atras" deshace el cambio, y eso solo se ve
  /// pulsando "atras". Un parametro booleano en un metodo que ya tiene otros se
  /// acabaria poniendo al reves una vez, y nadie lo veria.
  Future<void> ajustarA(Ruta ruta) => _irA(ruta, TipoDeCambioDeRuta.ajustar);

  Future<void> _irA(Ruta ruta, TipoDeCambioDeRuta tipo) async {
    if (ruta is RutaDesconocida) return;
    await _aplicar(ruta);
    notifyListeners();
    _reportar(ruta, tipo);
  }

  /// Le dice al framework como escribir esto en la barra.
  ///
  /// Va en un metodo propio y no en el cuerpo de [_irA] por un motivo que es el mismo
  /// que hace que las pruebas existan: **esto se puede comprobar**.
  /// [routerReportsNewRouteInformation] es publico, asi que una prueba lo puede llamar
  /// con un proveedor de mentira y mirar que tipo recibe. En el cuerpo del metodo
  /// habria que montar la aplicacion entera para verlo.
  void _reportar(Ruta ruta, TipoDeCambioDeRuta tipo) {
    _ultimaRutaReportada = ruta;
    _tipoReportado = tipo.paraElFramework;
    proveedor?.routerReportsNewRouteInformation(
      RouteInformation(uri: Uri.parse(Rutas.escribir(ruta))),
      type: tipo.paraElFramework,
    );
  }

  /// A quien se le reporta la ruta para que la escriba en la barra.
  ///
  /// Lo mismo que el `Router` de `MaterialApp.router`: **la misma instancia**. Por
  /// eso se pasa por el constructor y no se busca con un `override`: el `Router` se
  /// queda con la suya y aqui con la otra, y entonces las dos escriben y la barra va
  /// por detras de la pantalla.
  ///
  /// Y ES NULL EN LAS PRUEBAS, y no es un fallo: en la maquina de Dart no hay barra de
  /// direcciones. La app funciona igual, y lo que se comprueba en las pruebas es el
  /// **tipo** que se reporta --que es lo que decide entre `pushState` y
  /// `replaceState`--, no la llamada.
  final RouteInformationProvider? proveedor;

  // --- aplicar una ruta ---

  /// Poner en su sitio la pantalla de [ruta].
  ///
  /// Y LA RUTA NO SE ASIGNA ANTES DEL `switch`, Y POR QUE. La primera version hacia
  /// `_ruta = ruta` al principio y luego, en el caso de una ruta desconocida, contaba
  /// con deshacerlo con un `_ruta = _ruta`. Ese `_ruta = _ruta` no deshace nada: ya se
  /// habia asignado, y la prueba de "una ruta que no se entiende no cambia la pantalla"
  /// fallaba con la pantalla en estado desconocido. Que el caso sea "no hacer nada"
  /// significa **no hacer nada**, y eso solo se consigue no asignando antes.
  Future<void> _aplicar(Ruta ruta) async {
    switch (ruta) {
      case RutaBiblioteca():
        _ruta = ruta;
        // Se cierra el texto abierto. Volver a la biblioteca con un `.amod` de 57 MiB
        // abierto es memoria que no vuelve sola en un movil de gama baja, y quien
        // esta en la biblioteca no esta leyendo.
        lector.sinModulo();

      case RutaLectura(:final modulo, :final referencia, :final comentario):
        // Y SI YA ESTA ABIERTO ESE MISMO TEXTO, NO SE VUELVE A ABRIR. Y no es una
        // optimizacion: es que pasar de Juan 3 a Juan 4 no necesita volver a leer 22 MiB
        // del almacenamiento ni volver a pasarles `PRAGMA quick_check`.
        //
        // MEDIDO EL 4 DE OCTUBRE DE 2026 al montar la comprobacion en navegador: medir el
        // historial del navegador son tres cambios de ruta, y con la apertura siempre los
        // tres tardaban mas que el reloj virtual entero, de modo que la comprobacion se
        // quedaba a medias sin decir nada. Y lo que se estaba midiendo no era el
        // historial: era el coste de volver a abrir un texto que ya estaba abierto.
        //
        // Y AQUI ESTA EL RIESGO, Y POR QUE SE ACEPTA. Un modulo abierto podria haber
        // cambiado en el almacenamiento desde que se abrio. Se asume que no: solo cambia
        // si la aplicacion lo ha vuelto a guardar, y eso lo hace ella misma, y entonces
        // reabre por el camino de `_descargar`. Un fichero editado por fuera mientras la
        // aplicacion esta abierta es un caso que no se contempla, y se dice aqui en vez de
        // dejarlo para que alguien lo descubra.
        if (lector.idDelModulo == modulo && lector.modulo != null) {
          _ruta = RutaLectura(modulo, referencia, comentario);
          lector.leer(referencia);
          await _aplicarComentario(comentario);
          break;
        }

        final abierto = await abrir(modulo, referencia);
        if (abierto == null) {
          // El enlace pide un texto que no esta. Se avisa y se vuelve a la biblioteca:
          // quedarse en una pantalla de lectura sin texto, con la URL diciendo que se
          // esta leyendo Juan 3, es peor que volver.
          lector.sinModulo('El texto "$modulo" no esta descargado en este dispositivo.');
          _ruta = const RutaBiblioteca();
          break;
        // ignore: unnecessary_break
        }
        // Aqui se asigna la ruta, y **despues** de abrir. Y no antes, por un motivo que
        // sale de un fallo real: si la ruta se asignara antes de abrir y la apertura
        // fallara, `build` veria una ruta de lectura con `lector.sinModulo` y
        // entraria por la rama de la biblioteca --correcto--, pero la ruta y la
        // pantalla estarian fuera de paso durante ese frame.
        _ruta = RutaLectura(modulo, referencia, comentario);
        lector.abrir(
          abierto,
          licenciaDelManifiesto: biblioteca.manifiesto.porId(modulo)?.licencia,
        );
        lector.leer(referencia);
        // Y EL COMENTARIO SE ABRE **DESPUES** DE LEER EL PASAJE, y no antes. Al reves,
        // `abrirComentario` leeria unas notas de un pasaje que todavia no se ha pedido,
        // y al pedir el pasaje despues se pisarian. Es un orden de dos lineas que no se
        // ve y que solo falla cuando se abre un texto con comentario desde un enlace --
        // o sea, lo primero que hace quien recibe el enlace.
        await _aplicarComentario(comentario);

      case RutaIndice(:final modulo, :final numero):
        await _aplicarIndice(modulo, numero);

      case RutaBusqueda(:final modulo, :final palabra):
        await _aplicarBusqueda(modulo, palabra);

      case RutaDesconocida():
        // Una ruta que no se entiende **no** se aplica. Se queda donde se estaba y se
        // avisa, porque ir a la biblioteca por un enlace roto seria hacer algo sin que
        // nadie lo haya pedido. Es lo que pasa al abrir un enlace escrito a mano con un
        // error: se ve la pagina que se estaba leyendo y el aviso dice que el enlace
        // no vale.
        _ruta = _ruta;
    }
    notifyListeners();
  }

  /// Poner en su sitio el indice de una palabra.
  ///
  /// Y ABRE EL TEXTO SI NO ESTA ABIERTO, con el mismo camino que el lector y que la
  /// busqueda, porque `/indice/KJV2006/G2316` es un enlace completo y tiene que funcionar
  /// en un dispositivo donde el texto este o no este.
  ///
  /// Y **NO SE CIERRA EL PASAJE AL VOLVER**: el indice se llega desde una palabra del
  /// versiculo que se esta leyendo, y al volver hay que estar en ese versiculo. Por eso
  /// vuelve con `lectura.leyendo` y no con "Juan 1".
  Future<void> _aplicarIndice(String modulo, String numero) async {
    if (lector.idDelModulo != modulo) {
      final abierto = await abrir(modulo, const Referencia('John', 1));
      if (abierto == null) {
        lector.sinModulo('El texto "$modulo" no esta descargado en este dispositivo.');
        _ruta = const RutaBiblioteca();
        notifyListeners();
        return;
      }
      lector.abrir(
        abierto,
        licenciaDelManifiesto: biblioteca.manifiesto.porId(modulo)?.licencia,
      );
    }
    _ruta = RutaIndice(modulo, numero);
    await _indice.abrir(_moduloIndiciable(), numero: numero);
  }

  /// El modulo abierto, para el indice.
  ModuloIndiciable _moduloIndiciable() => _ModuloIndiciableReal(lector.modulo!);

  /// Abrir el indice de un numero del lexicon en el texto abierto.
  ///
  /// Y ES `replaceState`, y no `pushState`, porque el indice es una pantalla **encima** del
  /// pasaje y volver tiene que devolver al pasaje y no a como estaba antes de pulsar. Con
  /// `pushState`, el gesto de atras devolveria a como estaba antes de tocar la palabra, y
  /// quien solo queria volver a leer se queda en otra parte.
  Future<void> verElIndiceDe(String numero) async {
    final id = lector.idDelModulo;
    if (id == null) return;
    await ajustarA(RutaIndice(id, numero));
  }

  /// Volver del indice al pasaje de donde se vino.
  ///
  /// Y ES `pushState` PORQUE SE VUELVE, y no "atras" de una lista. Con el indice no se
  /// sustituye el pasaje: el pasaje sigue ahi debajo y el indice viene encima, y volver
  /// tiene que devolver a donde se estaba leyendo, con el comentario que hubiera.
  Future<void> volverDelIndice() async {
    final id = lector.idDelModulo;
    final referencia = lector.leyendo;
    if (id == null || referencia == null) {
      await irAHome();
      return;
    }
    await irA(RutaLectura(id, referencia, lector.idDelComentario));
  }

  /// Abrir un pasaje desde el indice.
  Future<void> abrirDesdeElIndice(Referencia referencia) async {
    final id = lector.idDelModulo;
    if (id == null) return;
    await irA(RutaLectura(id, referencia, lector.idDelComentario));
  }

  /// Poner en su sitio una busqueda.
  ///
  /// Y ABRE EL TEXTO SI NO ESTA ABIERTO, con el mismo camino que el lector, y por el
  /// mismo motivo: `/buscar/KJV2006/propitiacion` es un enlace completo y tiene que
  /// funcionar en un dispositivo donde el texto este ya en el almacenamiento o todavia no.
  ///
  /// Y **NO BUSCA**. Una ruta de busqueda se abre con la palabra puesta en el campo y sin
  /// resultados: entrar en un enlace trae 200 lineas de golpe sin que nadie las haya
  /// pedido. Quien solo quiere pulsar "buscar" lo tiene, porque el campo sale escrito.
  Future<void> _aplicarBusqueda(String modulo, String palabra) async {
    if (lector.idDelModulo != modulo) {
      final abierto = await abrir(modulo, const Referencia('John', 1));
      if (abierto == null) {
        // Y EL MISMO MENSAJE QUE EL LECTOR, y no uno propio de la busqueda. Quien llega
        // a un enlace de busqueda de un texto que no tiene esta lee lo mismo que quien
        // llega a un enlace de lectura: "no esta descargado", y donde se puede bajar.
        lector.sinModulo('El texto "$modulo" no esta descargado en este dispositivo.');
        _ruta = const RutaBiblioteca();
        notifyListeners();
        return;
      }
      lector.abrir(
        abierto,
        licenciaDelManifiesto: biblioteca.manifiesto.porId(modulo)?.licencia,
      );
    }

    _ruta = RutaBusqueda(modulo, palabra);
    // Y EL **MISMO** LECTOR SE QUEDA ABIERTO, y no se cierra. Buscar no es dejar de leer:
    // quien busca desde Juan 3:16 vuelve a Juan 3:16, y si la busqueda cerrara el texto
    // habria que volver a abrir 22 MiB y volver a pasarle `PRAGMA quick_check`.
    _busqueda.abrir(ModuloBuscableReal(lector.modulo!), palabra: palabra);
  }

  /// Abrir la pantalla de busqueda del texto abierto, en Juan 3:16.
  ///
  /// Y CON LA PALABRA **VACIA**, y no con la ultima buscada. Es una pantalla nueva y una
  /// palabra de la anterior en el campo haria creer que ya se ha buscado eso.
  Future<void> buscarEnElTextoAbierto() async {
    final id = lector.idDelModulo;
    if (id == null) return;
    await irA(RutaBusqueda(id, ''));
  }

  /// Volver de una busqueda a donde se estaba leyendo.
  ///
  /// Y ES `pushState` AL VOLVER Y `replaceState` AL BUSCAR. Buscar es un ajuste de lo que
  /// se esta viendo y "atras" desde una busqueda debe devolver **la lectura**, no la
  /// busqueda anterior; por eso la ruta de la busqueda se aplica con `replaceState` y el
  /// regreso es un `pushState` al sitio del que se salio.
  Future<void> volverDeLaBusqueda() async {
    final id = lector.idDelModulo;
    final referencia = lector.leyendo;
    if (id == null || referencia == null) {
      await irAHome();
      return;
    }
    await irA(RutaLectura(id, referencia, lector.idDelComentario));
  }

  /// Buscar desde la pantalla de busqueda.
  Future<void> buscar(String palabra) async {
    final id = lector.idDelModulo;
    if (id == null) return;
    await ajustarA(RutaBusqueda(id, palabra));
    await _busqueda.buscar(palabra);
  }

  /// Abrir el pasaje de una coincidencia.
  ///
  /// Y SE LLEVA EL COMENTARIO QUE HUBIERA. Volver de "Juan 3:16 sale propitiation" a Juan
  /// 3:16 sin el CLARKE al lado seria perderlo por haber buscado, y buscar no quita
  /// nada.
  Future<void> abrirDesdeLaBusqueda(Referencia referencia) async {
    final id = lector.idDelModulo;
    if (id == null) return;
    await irA(RutaLectura(id, referencia, lector.idDelComentario));
  }

  /// Abre, quita o deja como estaba el comentario que pide la ruta.
  ///
  /// Y LAS TRES COSAS EN UN SOLO METODO, porque es lo que hace una ruta: decir como se
  /// lee. Y **NO ES UN `if` POR CASO** sino una comparacion con lo que hay, porque lo
  /// habitual es que no haya cambiado: pasar de Juan 3 a Juan 4 con el CLARKE al lado
  /// vuelve a pasar por aqui, y reabrir 57 MiB en cada capitulo seria lo que hace que
  /// nadie lea con comentario abierto.
  ///
  /// Y CUANDO EL COMENTARIO NO ESTA DESCARGADO NO ES UN ERROR, y esta es la parte que
  /// importa. El enlace `/leer/KJV2006/John.3.16/con/CLARKE` puede llegar a un
  /// dispositivo donde el CLARKE --57 MiB-- no esta y no va a estar. Lo que hay ahi es
  /// Juan 3:16 del KJV, entero, y un aviso de que al lado no hay nada. Un enrutador que
  /// en ese caso volviera a la biblioteca habria roto la lectura por un comentario que
  /// es un extra.
  Future<void> _aplicarComentario(String? comentario) async {
    if (comentario == null) {
      if (lector.tieneComentario) lector.cerrarComentario();
      return;
    }

    // Y SI YA ESTA ESE MISMO, NO SE VUELVE A ABRIR PERO **SI SE VUELVEN A LEER LAS
    // NOTAS**. Son dos cosas y se separan aqui a proposito: reabrir son 57 MiB y un
    // `PRAGMA quick_check` que no hacen falta, y en cambio las notas **son** de otro
    // pasaje.
    //
    // Sin esta segunda parte, ir de Juan 3 a Juan 5 con el comentario abierto dejaba las
    // notas de Juan 3 encima de Juan 5. Medido, y era justo lo que ensefaba.
    if (lector.idDelComentario == comentario) {
      lector.refrescarNotas();
      return;
    }

    if (!biblioteca.idsLocales.contains(comentario)) {
      // Y NO SOLO SE AVISA: SE OFRECE BAJARLO, y con el boton, no con un "se puede bajar
      // en la biblioteca" que obliga a dar la vuelta, buscarlo y volver.
      //
      // MEDIDO el 4 de octubre de 2026 en la comprobacion en navegador, con
      // `/leer/KJV2006/John.3.16/con/CLARKE`: el comentario no se abria, 0 bytes bajados
      // y Juan 3:16 entero sin nada al lado. O sea, exactamente el fallo que hace que un
      // enlace con un comentario no sirva de nada: quien lo recibe no tiene forma de
      // CONSEguir el comentario sin dejar de estar leyendo.
      lector.comentarioNoDisponible(
        comentario,
        'El comentario $comentario no esta descargado en este dispositivo.',
      );
      return;
    }

    final abierto = await abrir(comentario, lector.leyendo ?? const Referencia('John', 1));
    if (abierto == null) {
      lector.comentarioNoDisponible(
        comentario,
        'El comentario $comentario esta en el dispositivo pero no se ha podido abrir.',
      );
      return;
    }
    lector.abrirComentario(
      abierto,
      licenciaDelManifiesto: biblioteca.manifiesto.porId(comentario)?.licencia,
    );
  }

  // --- elegir comentario ---

  /// Abre la hoja con los comentarios que hay, y quita el que haya si se pide.
  ///
  /// Y LA LISTA SALE DEL MANIFIESTO CRUZADO CON LO DESCARGADO, y no de una lista escrita
  /// aqui. Un "CLARKE" en el codigo seria el mismo fallo que una tabla de libros: la app
  /// sabria lo que hay antes de que lo haya, y en cuanto el catalogo publicase un
  /// segundo comentario --que es lo que va a pasar-- este sitio no sabria de el.
  Future<void> elegirComentario(BuildContext context) async {
    final ruta = _ruta;
    if (ruta is! RutaLectura) return;

    final actuales = _comentariosDisponibles();
    final elegido = await mostrarHojaDeComentarios(
      context: context,
      actuales: actuales,
      abierto: lector.idDelComentario,
    );
    if (elegido == null) return;

    // Y ES `replaceState` Y NO `pushState`. Poner un comentario es un **ajuste** de lo
    // que se esta leyendo, igual que cambiar de traduccion: quien lo pone quiere seguir
    // en Juan 3:16, no volver atras a como estaba antes de pulsarlo. Y con `pushState`,
    // el gesto de atras devolveria el texto sin comentario, que es lo que ya se tiene.
    await ajustarA(RutaLectura(ruta.modulo, ruta.referencia, elegido));
  }

  /// Si el comentario que pide la ruta esta en el catalogo y todavia no esta aqui.
  bool _sePuedeDescargar(Ruta ruta) {
    if (ruta is! RutaLectura) return false;
    final comentario = ruta.comentario;
    if (comentario == null) return false;
    if (descargar == null) return false;
    if (biblioteca.idsLocales.contains(comentario)) return false;
    return biblioteca.manifiesto.porId(comentario) != null;
  }

  /// Baja el comentario pedido y no dice nada mas: cuando termine, la biblioteca avisa y
  /// [_alCambiarLaBiblioteca] lo abre.
  ///
  /// Y ES **PUBLICO** Y NO PRIVADO, y por eso esta aqui y no metido en el widget. Lo que
  /// hace el boton de la pantalla es exactamente esto, y la comprobacion en navegador --
  /// que no puede pulsar un boton-- necesita hacer lo mismo que la persona que abre el
  /// enlace. Si estuviera en otro sitio habria dos caminos para bajar el comentario, y el
  /// que se comprobaria no seria el que se usa.
  void descargarComentarioPedido() {
    final ruta = _ruta;
    if (ruta is! RutaLectura) return;
    final comentario = ruta.comentario;
    if (comentario == null) return;
    descargar?.call(comentario);
  }

  /// Las Biblias del catalogo, con su estado y su tamano, para el selector de version.
  ///
  /// Y SOLO LAS BIBLIAS, no los comentarios. Un selector de version que ofrece el
  /// Comentario de Adam Clarke es un selector que ofrece cambiar de texto por un
  /// comentario, y eso es otra pantalla y otro boton --el que ya esta en la barra— con su
  /// propia hoja. Dos caminos para lo mismo, y uno de los dos mal.
  ///
  /// Y EL ESTADO DE CADA UNA VIENE DE LA BIBLIOTECA, que es quien sabe que esta
  /// descargado, y no de `modulo.tamanoBytes`, que es lo que ocupa en el servidor. Enseñar
  /// el tamano del servidor como si fuera el coste de bajarlo es un dato que no es el que
  /// se necesita para decidir.
  List<VersionDisponible> _versionesDisponibles() {
    final ids = biblioteca.idsLocales;
    return <VersionDisponible>[
      for (final m in biblioteca.manifiesto.modulos)
        if (TipoDeContenido.fromModulo(m.tipo.enElCatalogo) == TipoDeContenido.biblia)
          VersionDisponible(
            id: m.id,
            nombre: m.nombre,
            descargado: ids.contains(m.id),
            bytes: m.tamanoBytes,
          ),
    ];
  }

  /// Abrir el selector de version y cambiar a la que se pulse.
  ///
  /// Y SE CIERRA LA HOJA ANTES DE CAMBIAR, y no se cambia con la hoja abierta: cambiar de
  /// texto reabre el modulo y repinta la pantalla, y una hoja abierta encima de una pantalla
  /// que se repinta debajo se queda puesta en un sitio que ya no corresponde.
  Future<void> elegirVersion(BuildContext context) async {
    final actual = lector.idDelModulo;
    final elegida = await mostrarHojaDeVersiones(
      context: context,
      disponibles: _versionesDisponibles(),
      abierta: actual,
    );
    if (elegida == null || elegida == actual) return;
    await cambiarDeVersion(elegida);
  }

  /// Abrir el selector de libro y capitulo, y leer lo que se pulse.
  ///
  /// Y SOLO BIBLIAS. Un comentario no tiene capitulos --tiene notas por versiculo— y
  /// abrirlo aqui daria una lista de libros vacia, que es una pantalla en blanco con un
  /// titulo encima.
  Future<void> elegirLibro(BuildContext context) async {
    final modulo = lector.modulo;
    if (modulo == null || modulo.tipo != TipoDeContenido.biblia) return;

    final elegido = await mostrarHojaDeLibros(
      context: context,
      modulo: _ModuloConLibrosReal(modulo),
      leyendo: lector.leyendo,
    );
    if (elegido == null) return;

    // Y SI ES OTRO LIBRO, LA HOJA SE ABRE EN SU PRIMER CAPITULO Y NO EN EL VERSICULO QUE
    // SE ESTABA LEYENDO. Al pasar de Juan a Josue no hay un versiculo de Josue que
    // corresponda al 16 de Juan: inventarlo seria llevar a un sitio que no existe.
    final esElMismoLibro = lector.leyendo?.libro == elegido.libro;
    await irA(RutaLectura(
      lector.idDelModulo ?? '',
      esElMismoLibro
          ? elegido
          : Referencia(elegido.libro, elegido.capitulo),
      lector.idDelComentario,
    ));
  }

  /// Los comentarios descargados, con su nombre. De donde sale: el manifiesto.
  List<ComentarioDisponible> _comentariosDisponibles() {
    final ids = biblioteca.idsLocales;
    return <ComentarioDisponible>[
      for (final m in biblioteca.manifiesto.modulos)
        if (ids.contains(m.id) &&
            TipoDeContenido.fromModulo(m.tipo.enElCatalogo) == TipoDeContenido.comentario)
          ComentarioDisponible(id: m.id, nombre: m.nombre),
    ];
  }

  // --- atras ---

  /// El boton de atras, la ESC y el gesto de atras del sistema.
  ///
  /// Leyendo, "atras" es la biblioteca. En la biblioteca, "atras" **no** se resuelve
  /// aqui: se devuelve `false` y el sistema sale de la aplicacion, que es lo que
  /// espera quien esta en la biblioteca y pulsa atras. Devolver `true` sin hacer nada
  /// dejaria la aplicacion en un estado en el que el boton no responde, y eso se ve
  /// como que la app esta colgada.
  @override
  Future<bool> popRoute() async {
    if (_ruta is! RutaBiblioteca) {
      await irAHome();
      return true;
    }
    return false;
  }

  /// Volver a la biblioteca. Es `pushState`: es otro sitio, y "atras" desde la
  /// biblioteca tiene que devolver al pasaje.
  Future<void> irAHome() => irA(const RutaBiblioteca());

  /// Ir a la pantalla de un destino del panel de herramientas.
  ///
  /// Y CADA DESTINO **TENIA** QUE LLEVAR A ALGO, porque en Logos los nueve llevan a un
  /// producto y un destino que no lleva a ninguna parte es peor que un destino que no
  /// existe. Los cinco que hay aqui son los cinco que existen de verdad.
  ///
  /// Y CUANDO EL DESTINO **NO** SE PUEDE CUMPLIR, SE VA A LA BIBLIOTECA Y NO SE PINTA UN
  /// AVISO. "Buscar" sin texto abierto no busca nada, y el sitio donde se elige un texto
  /// es la biblioteca; un aviso encima dira "no hay texto abierto" y dejara al usuario
  /// buscando el mismo boton.
  Future<void> irAlDestino(DestinoDeEstudio destino, [BuildContext? contexto]) async {
    final id = lector.idDelModulo;
    final referencia = lector.leyendo;

    switch (destino) {
      case DestinoDeEstudio.biblia:
        // Y AL PANEL DE LECTURA CON **SU** PASAJE. Pulsar "Biblia" con Juan 3 abierto
        // vuelve a Juan 3, y no a la pagina de inicio del texto: el panel de
        // herramientas es como se sale de aqui, no como se vuelve a entrar.
        if (id != null && referencia != null) {
          await irA(RutaLectura(id, referencia, lector.idDelComentario));
        } else {
          await irAHome();
        }

      case DestinoDeEstudio.buscar:
        if (id != null) {
          await irA(RutaBusqueda(id, ''));
        } else {
          await irAHome();
        }

      case DestinoDeEstudio.lexico:
        // Y EL LEXICO **NO TIENE PANTALLA PROPIA**: se llega desde una palabra del texto,
        // porque quien quiere saber donde mas sale `G2316` ya esta leyendo la palabra y la
        // toca. Asi que este destino abre el indice de la **primera palabra con numero de
        // la lectura actual**, y si la lectura no trae ninguno --porque el modulo no es
        // KJV con Strongs-- a la biblioteca, que es donde se baja uno que si lo trae.
        final strong = _primeraPalabraConIndice();
        if (strong != null) {
          await verElIndiceDe(strong);
        } else {
          await irAHome();
        }

      case DestinoDeEstudio.comentarios:
        // Y ESTE ES EL UNICO QUE **NO** CAMBIA DE RUTA, y no es una excepcion: abrir un
        // comentario es elegir uno, y elegir uno es una hoja con una lista. La hoja la abre
        // quien tiene el manifiesto --la biblioteca-- asi que el enrutador la abre con el
        // mismo metodo que usa el boton de la cabecera.
        // Y NECESITA UN CONTEXTO, porque elegir comentario es abrir una hoja. El que
        // llega es el de la pantalla de lectura, que esta vivo mientras el marco esta
        // vivo, que es justo cuando se ha podido pulsar el destino.
        if (contexto != null) {
          await elegirComentario(contexto);
        } else {
          await irAHome();
        }

      case DestinoDeEstudio.biblioteca:
        await irAHome();
    }
  }

  /// El numero de la primera palabra con indice de la lectura actual, o null.
  String? _primeraPalabraConIndice() {
    final versiculos = lector.pasaje?.versiculos;
    if (versiculos == null) return null;
    for (final v in versiculos) {
      for (final a in v.anotaciones) {
        final s = a.strong;
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /// La longitud del historial, DESPUES DE QUE EL FRAMEWORK HAYA ESCRITO LA URL.
  ///
  /// Y HAY QUE ESPERAR, Y POR QUE MEDIR DIRECTO DA UN NUMERO DESPLAZADO.
  ///
  /// `notifyListeners` no escribe nada en la barra: avisa al `Router`, y el `Router`
  /// reconstruye, y **en esa reconstruccion** llama a `routerReportsNewRouteInformation`,
  /// que es lo que acaba en `SystemNavigator.routeInformationUpdated`. O sea que cuando
  /// el delegado devuelve de `irA`, la URL todavia no esta cambiada.
  ///
  /// MEDIDO EL 4 DE OCTUBRE DE 2026 en el navegador, con la comprobacion del grupo 8: los
  /// numeros salian **una medicion tarde**. El cambio de capitulo no anadia entrada y el
  /// cambio de ajuste si --justo al reves de lo que tiene que pasar--, y el segundo
  /// cambio de capitulo si la anadia. Leyendo los cuatro en fila, el crecimiento aparece
  /// un paso mas adelante, y por eso lo de "el ajuste anade una entrada" no era un
  /// bug del `ajustarA` sino de medir antes de tiempo.
  ///
  /// Por eso se esperan frames. Dos, y no uno: el primero reconstruye el `Router` y el
  /// segundo deja que lo que este escribio llegue al navegador. Y hay un tope de diez,
  /// porque si no llegara nunca el numero devuelto seria el inicial y la comprobacion
  /// creeria que no cambia nada, que es justo el fallo que se quiere cazar.
  Future<int?> _longitudDelHistorialEstable() async {
    var largo = plataforma.longitudDelHistorial();
    for (var i = 0; i < 10; i++) {
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(Duration.zero);
      final otro = plataforma.longitudDelHistorial();
      if (otro == largo) return largo;
      largo = otro;
    }
    return largo;
  }

  // --- abrir un texto desde la biblioteca ---

  /// Abrir un texto desde la biblioteca, en Juan 1.
  ///
  /// Y Juan 1 y no "el capitulo que se leia la ultima vez", porque ese dato no existe:
  /// no se guarda historial de lectura a proposito. Inventar un "ultimo" seria un
  /// estado que puede no ser de esta sesion, y abrir en otro sitio del texto sin que
  /// se haya pedido es peor que abrir en el primero.
  ///
  /// Y **NO ABRE EL MODULO AQUI**. La primera version lo abria y luego llamaba a
  /// [irA], que lo volvia a abrir: el modulo se abria dos veces y en la prueba se
  /// veia clarisimo --`['KJV2006', 'KJV2006']`. En un `.amod` de 57 MiB son 57 MiB
  /// leidos dos veces, y la segunda conexion a la base de datos se queda abierta. Aqui
  /// solo se pide el sitio al que ir, y quien abre es [irA], que es quien lo hace para
  /// todo lo demas.
  Future<void> abrirDesdeLaBiblioteca(String id) async {
    await irA(RutaLectura(id, const Referencia('John', 1)));
  }

  /// Cambiar de version de texto sin salir del pasaje.
  ///
  /// Es un ajuste, asi que `replaceState`: quien cambia de traduccion quiere seguir
  /// leyendo Juan 3 en la otra, no volver atras a la anterior. Y si "atras" lo
  /// deshaciera, el gesto se perderia en cuanto se pulsara la flecha para seguir
  /// leyendo, que es la forma mas facil de perder un ajuste.
  Future<void> cambiarDeVersion(String id) async {
    await ajustarA(RutaLectura(
      id,
      lector.leyendo ?? const Referencia('John', 1),
      lector.idDelComentario,
    ));
  }

  // --- la pantalla ---

  @override
  Widget build(BuildContext context) {
    // Cuando la ruta es de lectura pero no hay texto abierto --o no se ha podido
    // abrir-- lo que se pinta es la biblioteca con el aviso. Una pantalla de lectura
    // sin texto es una pantalla en blanco con un titulo, que es peor que no tener
    // nada.
    // Y LA BIBLIOTECA SIGUE SIENDO EL "NO HAY TEXTO". Una ruta de busqueda sin texto
    // abierto tambien cae aqui, y por la misma razon que la de lectura: una pantalla de
    // busqueda sin modulo es un campo de texto que no busca nada.
    final leyendo = _ruta is RutaLectura && lector.estado != EstadoLecturaTexto.sinModulo;

    final pantalla = _ruta is RutaIndice && lector.modulo != null
        ? IndiceView(
            viewModel: _indice,
            alPulsarPasaje: abrirDesdeElIndice,
            alVolver: volverDelIndice,
          )
        : _ruta is RutaBusqueda && lector.modulo != null
        ? BusquedaView(
            viewModel: _busqueda,
            alPulsarResultado: abrirDesdeLaBusqueda,
            alVolver: volverDeLaBusqueda,
            alBuscar: buscar,
          )
        : leyendo
        ? LectorView(
            viewModel: lector,
            // Y LA RUTA NUEVA **SE LLEVA EL COMENTARIO DELANTERO**. Sin esto, pasar de
            // Juan 3 a Juan 4 lo quita y hay que volver a pulsarlo en cada capitulo, y un
            // comentario que hay que volver a pedir cada capitulo no se usa. Y no es
            // que se pierda: la ruta lleva el identificador, asi que la URL de Juan 3:17
            // con el CLARKE al lado se puede copiar y dice lo que es.
            alPulsarPasaje: (r) => irA(RutaLectura(
              lector.idDelModulo ?? '',
              r,
              lector.idDelComentario,
            )),
            // Y LA HOJA SE ABRE CON EL CONTEXTO QUE DA ESTE `build`, que es el unico que
            // esta vivo mientras hay una pantalla. Guardarlo en un campo del delegado
            // seria guardar un `BuildContext` mas alla de la vida de su widget, que es
            // justo lo que `use_build_context_synchronously` avisa de y por lo que
            // existe.
            alPedirComentario: () => elegirComentario(context),
            // Y EL INDICE SE ABRE DESDE LA PALABRA, y no desde un boton: quien quiere
            // saber donde mas sale `G2316` ya esta leyendo la palabra y la toca. Un boton
            // en la barra obligaria a escribir el numero, y nadie escribe `G2316`.
            alVerIndice: verElIndiceDe,
            alAlternarPalabrasDeJesus: lector.alternarPalabrasDeJesus,
            // Y LA LUPA ABRE LA BUSQUEDA **DEL TEXTO ABIERTO**, y no una busqueda en
            // general. No hay una busqueda en general todavia y no la hay a proposito:
            // ver `buscar-en-el-texto`.
            alBuscar: buscarEnElTextoAbierto,
            // Y SOLO HAY BOTON DE BAJAR SI HAY ALGO QUE BAJAR. Si el comentario pedido
            // no esta en el catalogo --porque el enlace es de otro despliegue-- no hay
            // nada que ofrecer, y un boton que no hace nada es peor que no tenerlo.
            alDescargarComentario: _sePuedeDescargar(_ruta) ? descargarComentarioPedido : null,
            modulosDelCatalogo: biblioteca.manifiesto.modulos,
            versiones: _versionesDisponibles(),
            alAbrirLibros: () => elegirLibro(context),
            alAbrirVersiones: () => elegirVersion(context),
            alCambiarDeVersion: cambiarDeVersion,
            alCambiarDeDestino: (d) => irAlDestino(d, context),
            alVolver: irAHome,
          )
        : BibliotecaView(
            viewModel: biblioteca,
            alPulsarLeer: abrirDesdeLaBiblioteca,
            alPulsarDescargar: descargar ?? noHaceNada,
            alPulsarFicheroLocal: abrirFicheroLocal ?? noHaceNada,
            alReintentar: reintentarCatalogo ?? noHaceNadaVoid,
          );

    // Y ESTE `Navigator` NO ES PARA NAVEGAR: es por el `Overlay`.
    //
    // La primera version de este fichero devolvia la pantalla pelada, sin `Navigator`, y
    // `test/widget_test.dart` --que monta esta misma aplicacion-- fallo al escribir en
    // el campo del filtro de la biblioteca con un error que no tiene nada que ver con la
    // biblioteca:
    //
    //     No Overlay widget found. EditableText widgets require an Overlay ancestor.
    //
    // Un `TextField` necesita un `Overlay` por debajo para el cursor y la seleccion. Sin
    // `Navigator` --que es lo que lo mete-- no hay, y fallaria igual en el navegador, con
    // la gente escribiendo en el filtro de la biblioteca y sin poder.
    //
    // Y CON UNA SOLA PAGINA NO PUEDE HACER `pop`, asi que el boton de atras no lo
    // resuelve el `Navigator`: eso lo decide [popRoute] de este delegado, que sabe si
    // toca ir a la biblioteca o dejar salir de la aplicacion. Ver el razonamiento de
    // arriba.
    return Navigator(
      pages: <Page<void>>[
        MaterialPage<void>(key: const ValueKey<String>('pantalla'), child: pantalla),
      ],
      onDidRemovePage: (_) {
        // No debe ocurrir: la lista se reconstruye entera y siempre tiene una pagina.
        // Si ocurriera, no se hace nada, porque la ruta la gobierna
        // [currentConfiguration] y vaciarla aqui dejaria la barra diciendo `/leer/...`
        // con la biblioteca en pantalla.
      },
    );
  }

  // La biblioteca necesita cuatro cosas mas que el enrutador no tiene: descargar,
  // abrir un fichero del dispositivo, reintentar el catalogo y saber como abrir un
  // modulo. Van como callbacks que inyecta `main.dart`, porque son servicios --HTTP,
  // almacenamiento, selector de archivos-- y el enrutador no debe saber de ellos.
  @override
  void dispose() {
    biblioteca.removeListener(_alCambiarLaBiblioteca);
    _indice.dispose();
    _busqueda.dispose();
    lector.dispose();
    super.dispose();
  }
}

/// Un callback que no hace nada.
///
/// Para lo que el enrutador no sabe hacer y nadie ha enchufado. Un boton que no
/// responde es malo, pero es **mejor** que una excepcion al construir la pantalla: con
/// este, el enrutador se puede montar en una prueba sin los seis servicios de
/// `main.dart`, y lo que no se ha probado aqui se prueba con ellos puestos.
void noHaceNada(String id) {}

/// Un [VoidCallback] que no hace nada.
void noHaceNadaVoid() {}

/// Convierte la barra de direcciones en rutas y al reves.
///
/// Es de una linea y media porque [Rutas] ya sabe hacerlo. Existe porque
/// `MaterialApp.router` lo pide, no porque aportara algo.
class AnalizadorDeRuta extends RouteInformationParser<Ruta> {
  const AnalizadorDeRuta();

  @override
  Future<Ruta> parseRouteInformation(RouteInformation routeInformation) async =>
      Rutas.leer(routeInformation.uri.toString());

  @override
  RouteInformation? restoreRouteInformation(Ruta configuration) =>
      RouteInformation(uri: Uri.parse(Rutas.escribir(configuration)));
}
