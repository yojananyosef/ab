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
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/indice_de_strong.dart';
import 'package:ab/domain/models/panel_abierto.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/ui/core/rutas.dart';
import 'sonda_nativa.dart'
    if (dart.library.js_interop) 'sonda_web.dart' as plataforma;
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/aviso.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/busqueda/view_models/busqueda_view_model.dart';
import 'package:ab/ui/features/busqueda/views/busqueda_view.dart';
import 'package:ab/ui/features/indice/view_models/indice_view_model.dart';
import 'package:ab/ui/features/indice/views/indice_view.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_libros.dart';
import 'package:ab/ui/features/lector/widgets/marco_de_estudio.dart' show AnchoDeEstudio, MarcoDeEstudio, DestinoDeEstudio;
import 'package:ab/ui/features/lector/widgets/fila_de_pestanas.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_versiones.dart';
import 'package:ab/ui/features/biblioteca/views/biblioteca_view.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/view_models/paneles_view_model.dart';
import 'package:ab/ui/features/lector/view_models/preferencias_de_lectura.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
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
    required this.preferencias,
    required this.resaltados,
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

  /// Los ajustes de lectura, que son **de la ventana**.
  ///
  /// Y ENTRAN POR EL CONSTRUCTOR Y NO SE CREAN AQUI, y el motivo es el mismo que en
  /// `main.dart`: guardar necesita el almacenamiento del sistema, y el enrutador no lo
  /// tiene ni deberia. Los recibe y los reparte entre los paneles --cada panel tiene su
  /// `LectorViewModel`--, y eso es lo que hace que cambiar la letra en un panel se vea en
  /// el otro.
  final PreferenciasDeLectura preferencias;

  /// Los paneles abiertos y el que esta delante.
  ///
  /// Y SE CREA AQUI Y NO EN `main.dart` por la misma razon que el indice y la busqueda:
  /// `main.dart` compone lo que hay desde el principio, y en cuanto hay una pantalla mas
  /// que crear ahi habria un segundo sitio al que volver. El enrutador es el unico que
  /// sabe que hay una ventana con varios textos.
  late final PanelesViewModel paneles =
      PanelesViewModel(preferencias: preferencias);

  /// El view model del panel que esta delante.
  ///
  /// Y ES UN **GETTER** Y NO UN CAMPO, y no es una comodidad: el panel de delante cambia
  /// al pulsar una pestana, y un campo guardado seria el del momento en que se abrio. Todo
  /// el enrutador habla de "el lector" y con este getter el lector es siempre el del
  /// panel que se esta viendo, que es lo que quiere decir la palabra.
  ///
  /// Y CUANDO NO HAY NINGUN PANEL, DEVUELVE **[lectorSinPaneles]**, y no `null`. Hay
  /// codigo --la pantalla de la biblioteca, el destino activo-- que pregunta como esta la
  /// lectura sin que haya nada abierto, y un `null` obligaria a comprobar en veinte
  /// sitios. El view model sin paneles no tiene modulo abierto y no lo tendra: no lo
  /// registra nadie.
  LectorViewModel get lector => paneles.lectorDelante ?? lectorSinPaneles;

  /// El view model que se usa cuando no hay ningun panel abierto.
  ///
  /// Y ES UNO SOLO Y NO UNO POR LLAMADA, porque un reader por llamada seria un reader
  /// distinto en cada pregunta y su estado --la preferencia, el texto escrito en el
  /// campo-- no se guardaria entre una pantalla y la siguiente.
  late final LectorViewModel lectorSinPaneles =
      LectorViewModel(preferencias: preferencias);

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
  /// Los resaltados de la persona.
  ///
  /// Y VA POR PARAMETRO Y NO SE CREA AQUI, porque los resaltados **no son de una pantalla**:
  /// son de la persona y los ven la lectura, la busqueda y el indice. Si los creara el
  /// enrutador, el indice tendria que ir a buscarlos al enrutador, y con el indice abierto el
  /// enrutador no es quien esta vivo.
  final ResaltadosViewModel resaltados;

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
    final delComentario = paneles.lectorDelante?.idDelModulo;
    if (delComentario == null) return;
    unawaited(_aplicarComentario(delComentario, comentario));
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
        // Se cierran **TODOS** los textos abiertos, y no solo el del panel de delante.
        // Volver a la biblioteca con un `.amod` de 57 MiB abierto es memoria que no
        // vuelve sola en un movil de gama baja, y quien esta en la biblioteca no esta
        // leyendo. Con tres textos abiertos son **67,5 MiB** de paginas SQLite, medido
        // con los ficheros reales.
        paneles.cerrarTodos();

      case RutaLectura():
        // Y LA DIRECCION DE ORIGEN SE ESCRIBE DE NUEVO, y no es un rodeo. Lo que se
        // necesita de ella es el texto con el que se anuncia la ruta de paneles --que lo
        // lleva tal cual-- y para eso sirve la que se escribiria, que es la misma. La
        // variable `ruta` del `switch` es la que se aplica, y no [currentConfiguration]:
        // leer el estado de ahi daria la ruta anterior, que es justo el fallo de "la
        // direccion no dice que hay dos textos abiertos".
        final laRuta = ruta;
        await _aplicarPanel(laRuta, Rutas.escribir(laRuta));

      case RutaPaneles(:final principal, :final resto, :final texto):
        await _aplicarPaneles(principal, resto, texto);

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

  /// Poner en su sitio un panel.
  ///
  /// Y ESTO ES LO QUE HACIA ANTES EL `case RutaLectura` DEL `switch`, movido a un metodo
  /// porque ahora hay dos caminos --un panel y varios-- y con el `switch` growing hacia
  /// 200 lineas nadie iba a leer lo que hacia.
  ///
  /// Y [esPrincipal] DISTINGUE LOS DOS CAMINOS **DENTRO** DEL METODO y no con dos metodos,
  /// porque "no se ha podido abrir" significa dos cosas distintas segun desde donde se
  /// venga: para el panel de delante es un fallo de la pantalla entera --no hay nada que
  /// leer-- y para uno de al lado es un panel de menos. Con dos metodos, el camino largo --
  /// el que abre el modulo-- estaria escrito dos veces, y la primera que se quede sin
  /// actualizar seria un "abrir el texto" que solo funciona para el principal.
  Future<void> _aplicarPanel(
    Ruta ruta,
    String textoDeOrigen, {
    bool esPrincipal = true,
  }) async {
    if (ruta is! RutaLectura) return;
    final modulo = ruta.modulo;

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
    final yaAbierto = paneles.lectorDe(modulo);
    if (yaAbierto != null) {
      // Y LA RUTA **SE VUELVE A CALCULAR**, y no se copia la que llega. Este es el camino
      // de "traer un panel al frente" y de "ir a otro pasaje": si aqui se asignara la ruta
      // de un solo panel que llega, las demas ventanas se quedarian abiertas en pantalla
      // y **sin estar en la direccion**, y recargar perderia la mitad de lo que se ve.
      _ruta = _rutaDeLosPaneles(ruta, textoDeOrigen);
      paneles.ponerAlFrente(modulo);
      paneles.leerEn(modulo, ruta.referencia);
      yaAbierto.leer(ruta.referencia);
      await _aplicarComentario(modulo, ruta.comentario);
      return;
    }

    final abierto = await abrir(modulo, ruta.referencia);
    if (abierto == null && !esPrincipal) {
      // Y UN PANEL **SECUNDARIO** QUE NO SE PUEDE ABRIR **SE SALTA Y YA ESTA**, y no se
      // avisa ni se vuelve a la biblioteca. Quien recibe `/leer/A/John.3/y/B/John.3` en un
      // movil donde B no esta se queda con **A entero** y un panel de menos. Volver a la
      // biblioteca entera seria romper la lectura del texto por una ventana que no se ha
      // podido abrir, y es justo lo que este caso no debe hacer.
      //
      // Y NO SE AVISA, y el motivo es que la ventana que no se abre no ha comprometido a
      // nadie: quien la pidio recibe lo que si puede, que es el texto, y el aviso de
      // "el comentario no esta descargado" --con su boton de bajar-- lo pone el panel que
      // si esta abierto cuando le piden un comentario.
      return;
    }
    if (abierto == null) {
      // El enlace pide un texto que no esta. Se avisa y se vuelve a la biblioteca:
      // quedarse en una pantalla de lectura sin texto, con la URL diciendo que se
      // esta leyendo Juan 3, es peor que volver.
      //
      // Y EL AVISO SE PONE **DESPUES** DE CERRAR LOS PANELES, y no antes. Con dos
      // paneles abiertos y un enlace a un tercero que no esta, cerrarlos y avisar en el
      // mismo paso haria que el aviso se quedara en un view model que ya no se esta
      // viendo: `lector` es el del panel de delante mientras haya paneles, y al cerrar
      // todos pasa a ser [lectorSinPaneles], que es donde tiene que estar el aviso para
      // que la biblioteca lo pueda enseñar.
      paneles.cerrarTodos();
      _ruta = const RutaBiblioteca();
      lector.sinModulo('El texto "$modulo" no esta descargado en este dispositivo.');
      return;
    }

    // Y QUE ESTE PANEL **NO ESTE DELANTE** SI HAY OTROS, y no siempre. El enrutador
    // ponia cualquiera delante sin mirar; con un panel da igual, y con dos haria que
    // `/leer/A/John.3.16/y/B/John.3.16` se abriera con B delante, y la ruta dice que
    // A es el principal. Ver `registrar` en `paneles_view_model.dart`.
    final hayAntes = paneles.cuantos > 0;
    paneles.registrar(
      PanelAbierto(
        moduloId: modulo,
        referencia: ruta.referencia,
        comentarioId: ruta.comentario,
        // Y EL TIPO **SE DIJO, NO SE ADIVINO**. Lo sabe el manifiesto, y no lo deduce nadie
        // de las tablas del fichero: ver `panel_abierto.dart`, que tiene escrito por que
        // adivinarlo por `sqlite_master` es el fallo que hace que un modulo con tablas
        // inesperadas deje de distinguirse de una Biblia sin que nadie haya cambiado nada.
        esComentario: TipoDeContenido.fromModulo(
                biblioteca.manifiesto.porId(modulo)?.tipo.enElCatalogo) ==
            TipoDeContenido.comentario,
      ),
      LectorViewModel(preferencias: preferencias),
    );
    if (hayAntes) paneles.ponerAlFrente(modulo);

    // Aqui se asigna la ruta, y **despues** de abrir. Y no antes, por un motivo que
    // sale de un fallo real: si la ruta se asignara antes de abrir y la apertura
    // fallara, `build` veria una ruta de lectura sin texto y entraria por la rama de
    // la biblioteca --correcto--, pero la ruta y la pantalla estarian fuera de paso
    // durante ese frame.
    _ruta = _rutaDeLosPaneles(ruta, textoDeOrigen);

    // Y SE LLAMA `nuevo` Y NO `lector`, porque mas abajo hay un `lector` --el getter-- y
    // un `final lector` dentro de este mismo metodo taparia al getter: dos cosas con el
    // mismo nombre en el mismo ambito, y la que se usa es la ultima que se declara. Eso
    // compila y hace lo que parece, y el aviso se acaba escribiendo en un view model que
    // no es el del panel.
    final nuevo = paneles.lectorDe(modulo)!;
    nuevo.abrir(
      abierto,
      licenciaDelManifiesto: biblioteca.manifiesto.porId(modulo)?.licencia,
    );
    nuevo.leer(ruta.referencia);
    // Y EL COMENTARIO SE ABRE **DESPUES** DE LEER EL PASAJE, y no antes. Al reves,
    // `abrirComentario` leeria unas notas de un pasaje que todavia no se ha pedido,
    // y al pedir el pasaje despues se pisarian. Es un orden de dos lineas que no se
    // ve y que solo falla cuando se abre un texto con comentario desde un enlace --
    // o sea, lo primero que hace quien recibe el enlace.
    await _aplicarComentario(modulo, ruta.comentario);
  }

  /// Poner en su sitio varios paneles: el de delante y los que van al lado.
  ///
  /// Y **ABRE EL DE DELANTE PRIMERO**, y no en el orden de la lista. Motivo: si el que
  /// falta es el secundario y se abre despues, durante ese `await` la pantalla ya tiene
  /// un panel delante y se veria el texto equivocado. Abriendo el principal primero, el
  /// orden en que se va解决办法ndo es el que se ve.
  ///
  /// Y CUANDO FALTA ALGUNO DE LOS SECUNDARIOS **SE AVISA Y SE SIGUE** con los que hay.
  /// Volver a la biblioteca entero porque el CLARKE --57 MiB-- no esta descargado seria
  /// romper la lectura del texto por un comentario que es un extra, y ese es un fallo
  /// medido: ver `mirarLaAplicacion` en `sonda.dart`.
  Future<void> _aplicarPaneles(
    RutaLectura principal,
    List<RutaLectura> resto,
    String textoDeOrigen,
  ) async {
    await _aplicarPanel(principal, textoDeOrigen);

    // Y SI EL PRINCIPAL **NO SE PUDO ABRIR**, `_aplicarPanel` ya ha avisado y ha vuelto a
    // la biblioteca. Abrir los secundarios en ese caso haria que apareciera un panel al
    // lado de una pantalla que ya no es de lectura.
    //
    // Y SE COMPRUEBA CON [_rutaDeLectura] Y NO CON UN `is`, porque `_ruta` ya es `Ruta` y
    // un `is RutaLectura` sobre el campo dira siempre lo que el campo ya es. El estado de
    // la lectura se pregunta a quien lo sabe --[lector.estado]--, que es el unico que
    // sabe si hay un modulo abierto.
    if (lector.estado == EstadoLecturaTexto.sinModulo) return;

    for (final r in resto) {
      await _aplicarPanel(r, textoDeOrigen, esPrincipal: false);
      // Y EL PRINCIPAL **VUELVE AL FRENTE** DESPUES DE CADA SECUNDARIO. Sin esto,
      // abrir los secundarios en orden dejaria el ultimo delante, y la URL --que empieza
      // por el principal-- estaria describiendo una ventana en la que se ve otra cosa.
      paneles.ponerAlFrente(principal.modulo);
    }

    _ruta = _rutaDeLosPaneles(principal, textoDeOrigen);
  }

  /// La ruta que describe los paneles que hay ahora mismo.
  ///
  /// Y SE CALCULA DESDE EL ESTADO Y NO SE COPIA LA DE ENTRADA, porque los paneles pueden
  /// haber cambiado durante la apertura --alguien ha abierto y cerrado uno mientras se
  /// abria el CLARKE-- y una ruta construida con lo que habia al empezar seria una frase
  /// que no describe la pantalla.
  ///
  /// Y `texto` **ENTRA POR PARAMETRO** y no se lee de [currentConfiguration], porque en el
  /// momento en que se llama la ruta todavia no esta asignada --se asigna justo despues--,
  /// y leerla de ahi daria siempre la anterior, que es justo el fallo de "la direccion no
  /// dice que hay dos textos abiertos".
  Ruta _rutaDeLosPaneles(RutaLectura principal, String texto) {
    final ids = paneles.ids;
    if (ids.length < 2) return principal;

    final delante = principal.modulo;
    final resto = <RutaLectura>[];
    for (final id in ids) {
      if (id == delante) continue;
      final p = paneles.panelDe(id);
      if (p == null) continue;
      final vr = paneles.lectorDe(id);
      // Y UN PANEL SECUNDARIO **SE ESCRIBE SIN COMENTARIO**, y no es que se le esconda
      // uno: un panel con comentario lleva el suyo en el `con`, que es lo que se puede
      // escribir en una direccion. Un secundario con comentario se pondria en la
      // direccion del principal con `con`, y entonces habria dos comentarios en la misma
      // direccion y el parser no sabria cual es el de cual.
      resto.add(RutaLectura(id, vr?.leyendo ?? p.referencia));
    }
    if (resto.isEmpty) return principal;
    return RutaPaneles(texto, principal, resto);
  }

  /// Poner en su sitio el indice de una palabra.
  ///
  /// Y ABRE EL TEXTO **COMO UN PANEL** si no lo hay abierto, y no en un view model
  /// suelto. Antes --con un unico lector-- abrirlo ahi era lo mismo que abrirlo en el
  /// lector, porque solo habia uno. Con paneles son dos cosas distintas: si el indice
  /// abriera su `.amod` fuera de un panel, al volver de la pantalla de indice no habria
  /// ningun panel con ese texto y habria que volver a abrir **22,5 MiB** para leer el
  /// versiculo del que se salio. Ademas un modulo abierto fuera de un panel **no lo
  /// cierra nadie**: no hay quien lo registre, y se queda abierto hasta que acabe la
  /// aplicacion.
  ///
  /// Y **NO SE CIERRA EL PASAJE AL VOLVER**: el indice se llega desde una palabra del
  /// versiculo que se esta leyendo, y al volver hay que estar en ese versiculo. Por eso
  /// vuelve con `lectura.leyendo` y no con "Juan 1".
  Future<void> _aplicarIndice(String modulo, String numero) async {
    if (!await _asegurarElPanelDe(modulo)) return;
    _ruta = RutaIndice(modulo, numero);
    await _indice.abrir(_moduloIndiciable(), numero: numero);
  }

  /// Abre el texto [modulo] como panel si no lo hay, y devuelve si se puede seguir.
  ///
  /// Y **ES UN METODO Y NO TRES COPIAS** del mismo camino, y las tres son [_aplicarBusqueda],
  /// [_aplicarIndice] y [_aplicarPanel]: abrir un texto que no esta abierto es la misma
  /// operacion en los tres, con la misma comprobacion de "esta en el dispositivo" y el
  /// mismo aviso. Con tres copias, la primera que se quede sin actualizar --y con este
  /// proyecto, tarde o temprano-- seria un enlace que no avisa.
  Future<bool> _asegurarElPanelDe(String modulo) async {
    if (paneles.panelDe(modulo) != null) return true;
    final deEntrada = RutaLectura(modulo, const Referencia('John', 1));
    await _aplicarPanel(deEntrada, Rutas.escribir(deEntrada));
    // Y SE COMPRUEBA **POR EL MODULO ABIERTO** y no por el tipo de la ruta: si el texto no
    // se pudo abrir, `_aplicarPanel` ya ha avisado y ha vuelto a la biblioteca, y seguir
    // aqui abriria un indice **sin modulo**, que es un formulario que no busca nada.
    return paneles.panelDe(modulo) != null && paneles.lectorDe(modulo)?.modulo != null;
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
    // Y EL MISMO MENSAJE QUE EL LECTOR, y no uno propio de la busqueda. Quien llega
    // a un enlace de busqueda de un texto que no tiene lee lo mismo que quien llega a un
    // enlace de lectura: "no esta descargado", y donde se puede bajar. Lo dice
    // `_asegurarElPanelDe`, que es el camino comun.
    if (!await _asegurarElPanelDe(modulo)) return;

    _ruta = RutaBusqueda(modulo, palabra);
    // Y EL **MISMO** PANEL SE QUEDA ABIERTO, y no se cierra. Buscar no es dejar de leer:
    // quien busca desde Juan 3:16 vuelve a Juan 3:16, y si la busqueda cerrara el texto
    // habria que volver a abrir 22 MiB y volver a pasarle `PRAGMA quick_check`.
    final vm = paneles.lectorDe(modulo);
    if (vm?.modulo == null) return;
    _busqueda.abrir(ModuloBuscableReal(vm!.modulo!), palabra: palabra);
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
  /// Y EL MODULO DEL PANEL **ENTRA POR PARAMETRO** Y NO SE TOMA DE "EL LECTOR", y el
  /// motivo es que con dos paneles "el lector" es el de delante, y un comentario pedido
  /// para el panel del fondo se abriria en el de delante. Un comentario pertenece al
  /// panel que lo abrio, y eso lo dice el que llama.
  Future<void> _aplicarComentario(String modulo, String? comentario) async {
    final del = paneles.lectorDe(modulo);
    if (del == null) return;

    if (comentario == null) {
      if (del.tieneComentario) del.cerrarComentario();
      paneles.ponerComentario(modulo, null);
      return;
    }

    // Y SI YA ESTA ESE MISMO, NO SE VUELVE A ABRIR PERO **SI SE VUELVEN A LEER LAS
    // NOTAS**. Son dos cosas y se separan aqui a proposito: reabrir son 57 MiB y un
    // `PRAGMA quick_check` que no hacen falta, y en cambio las notas **son** de otro
    // pasaje.
    //
    // Sin esta segunda parte, ir de Juan 3 a Juan 5 con el comentario abierto dejaba las
    // notas de Juan 3 encima de Juan 5. Medido, y era justo lo que ensefaba.
    if (del.idDelComentario == comentario) {
      del.refrescarNotas();
      paneles.ponerComentario(modulo, comentario);
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
      del.comentarioNoDisponible(
        comentario,
        'El comentario $comentario no esta descargado en este dispositivo.',
      );
      paneles.ponerComentario(modulo, comentario);
      return;
    }

    final abierto = await abrir(comentario, del.leyendo ?? const Referencia('John', 1));
    if (abierto == null) {
      del.comentarioNoDisponible(
        comentario,
        'El comentario $comentario esta en el dispositivo pero no se ha podido abrir.',
      );
      paneles.ponerComentario(modulo, comentario);
      return;
    }
    del.abrirComentario(
      abierto,
      licenciaDelManifiesto: biblioteca.manifiesto.porId(comentario)?.licencia,
    );
    paneles.ponerComentario(modulo, comentario);
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
        //
        // Y SI **NO HAY NADA ABIERTO**, ANTES NO HACIA NADA, y es lo que se quejo quien
        // tiene una Biblia descargada y le pulsa: la rama de seguridad era `irAHome()`, y
        // desde la biblioteca eso es **volver a la biblioteca**. Un boton que no cambia la
        // pantalla parece un boton roto, y lo es.
        //
        // Y POR QUE NO ES "ABRIR EL PRIMERO DEL CATALOGO": porque el primero del catalogo
        // puede no estar descargado, y abrirlo pide una descarga de 22 MiB **sin haber
        // elegido**. Lo que hace falta es lo unico que hay: una Biblia que este en el
        // dispositivo.
        if (id != null && referencia != null) {
          await irA(RutaLectura(id, referencia, lector.idDelComentario));
          return;
        }

        final biblia = _primeraBibliaEnElDispositivo();
        if (biblia != null) {
          await abrirDesdeLaBiblioteca(biblia);
          return;
        }

        // Y SI NO HAY NI UNA, SE VA A LA BIBLIOTECA **DICIENDOLO**. Que es lo que se pidio
        // y es lo unico honesto: una biblioteca con la lista de textos es el sitio donde
        // se elige uno, y sin texto no hay nada que hacer aqui. Un boton que lleva a una
        // pantalla sin explicar por que es el callejon sin salida que ya se ha descrito.
        await irAHome();
        biblioteca.pedirTexto(
          'No tienes ningun texto descargado todavia. Bajar uno para poder leer.',
        );

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
        // ================================================================================
        // MEDIDO EL 6 DE OCTUBRE DE 2026: ESTE DESTINO NO HACIA NADA, Y POR DOS MOTOS
        // ================================================================================
        //
        // **Uno**: el marco llamaba a `alElegirDestino(destino)` **sin contexto**, asi que el
        // `BuildContext?` del enrutador era siempre `null` y este caso caia en su rama de
        // seguridad, que es `irAHome()`. Desde la biblioteca, volver a la biblioteca. El
        // contexto va ahora en la firma del marco, y es el **del elemento del destino**, que
        // esta por debajo del `Navigator` y por eso puede abrir la hoja.
        //
        // **Dos**, y este seguia dando igual que se arreglara lo otro: [elegirComentario]
        // empieza con
        //
        //     if (ruta is! RutaLectura) return;
        //
        // que es lo correcto --una hoja de comentarios sin texto al que ponerlos no tiene
        // sentido-- pero **se vuelve sin decir nada**. Y volver sin decir nada desde un boton
        // es lo mismo que no hacer nada, que es como se ha leido.
        if (id != null && referencia != null) {
          if (contexto != null) {
            await elegirComentario(contexto);
          } else {
            // Y ESTA ES LA RAMA QUE NO SE PUEDE QUITAR: sin contexto no hay hoja, y sin hoja
            // no hay destino. Se avisa en vez de ir a la biblioteca en silencio.
            biblioteca.pedirTexto(
              'No se ha podido abrir la lista de comentarios desde aqui.',
            );
          }
          return;
        }

        await irAHome();
        biblioteca.pedirTexto(
          'Para poner un comentario hace falta un texto abierto. Elige uno y vuelve a '
          'pulsar Comentarios.',
        );

      case DestinoDeEstudio.biblioteca:
        await irAHome();
    }
  }

  /// Que destino de la barra lateral corresponde a la ruta de ahora.
  ///
  /// Y ES UNA TABLA, Y NO UNA CADENA DE `if`, porque hay cinco destinos y cuatro tipos de
  /// ruta y la pantalla de lectura **cae a la biblioteca** cuando no hay texto abierto. Ese
  /// caso es el que importa: si se olvidara, la barra marcaria "Biblia" mientras lo que se
  /// ve es la biblioteca, que es la marca descolocada.
  DestinoDeEstudio _destinoDeLaRuta() => switch (_ruta) {
        RutaLectura() => DestinoDeEstudio.biblia,
        // Y UNA RUTA DE PANELES **MARCA BIBLIA**, porque lo que se ve es lectura. Sin este
        // caso el `switch` no es exhaustivo y el analisis avisa; con el, la marca no se
        // inventa: es la misma pantalla con mas de un texto al lado.
        RutaPaneles() => DestinoDeEstudio.biblia,
        RutaBusqueda() => DestinoDeEstudio.buscar,
        RutaIndice() => DestinoDeEstudio.lexico,
        RutaBiblioteca() => DestinoDeEstudio.biblioteca,
        // Y LA RUTA QUE NO SE CONOCE MARCA **BIBLIA**, porque es la pantalla de lectura la
        // que se cae a la biblioteca cuando no hay texto. Sin este caso el `switch` no es
        // exhaustivo y el analisis avisa; con el caso, la marca no se inventa.
        RutaDesconocida() => DestinoDeEstudio.biblia,
      };

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

  /// Los paneles abiertos, pintados uno al lado de otro, con la fila de pestañas encima.
  ///
  /// Y ESTO ESTA EN EL ENRUTADOR Y NO EN UNA VISTA, y es una decision que conviene tener
  /// escrita: la fila de pestañas va **encima de los dos paneles**, no dentro de ninguno.
  /// Si viviera en `LectorView`, cada panel pintaria su fila y habria dos filas que no
  /// controlan nada --que es exactamente el fallo de "dos barras que compiten por el
  /// ancho", y el enrutador es el unico sitio donde vive la ventana entera.
  ///
  /// Y CUANTOS PANELES SE PINTAN NO ES CUANTOS HAY, y la cuenta sale de la medida. Medido
  /// el 6 de octubre de 2026 con Roboto a 18 px: a 1440 px con el panel de herramientas,
  /// dos textos en paralelo son **557,8 px** de columna y salen **68 caracteres** por linea;
  /// tres son **354,5 px** y **43 caracteres**, que ya es el borde; cuatro son **252 px** y
  /// **31 caracteres**, que no se lee. Y a 1920 px tres son **514,5 px** y **63
  /// caracteres**, que si se lee.
  ///
  /// O sea que **el tope no es un numero de pestanas sino un ancho de columna**, y lo
  /// decide [Medidas.panelesDeLecturaQueCaben]. Con un "maximo de dos" escrito ahi, en
  //  una ventana de 1920 se desperdiciaria un tercio de la pantalla, y con "maximo de
  //  tres" a 1440 se pondria un panel que hay que leer con lupa.
  Widget _zonaDePaneles(BuildContext context) {
    return ListenableBuilder(
      // Y SE ESCUCHA A [paneles] Y NO A CADA LECTOR. El contenido de cada panel se
      // repinta solo, porque su `LectorView` escucha a su propio view model --esta es una
      // de las razones por las que hay un view model por panel y no uno compartido--. Lo
      // que cambia aqui es **cuantos paneles hay y cual esta delante**, y eso solo lo
      // sabe [PanelesViewModel].
      listenable: paneles,
      builder: (BuildContext context, Widget? _) => _pintarPaneles(context),
    );
  }

  Widget _pintarPaneles(BuildContext context) {
    // Y EL ANCHO SE RESTA **ANTES** DE REPARTIR, y no despues. Con el panel de
    // herramientas al lado, la lectura son `ancho - 226,5` --medido--, y repartir el ancho
    // de la ventana entre dos y luego restar el panel haria que el segundo panel se
    // saliera por la derecha. Es la misma cuenta que hace `medir_paneles_test.dart`, y
    // esta escrita en un sitio para que las dos no diverjan.
    final marco = AnchoDeEstudio.of(context);
    final lectura = marco.hayPanelDeHerramientas
        ? marco.ancho - Medidas.anchoDelPanelDeHerramientas
        : marco.ancho;
    final caben = Medidas.panelesDeLecturaQueCaben(lectura);

    // Y **SE PINTAN LOS [caben] PRIMEROS Y EN SU ORDEN**, y no los que estan delante. El
    // orden es el de apertura, y es estable: si se ordenara por "cual esta delante", cada
    // vez que se trajera un panel al frente las columnas se moverian de sitio, y quien
    // esta leyendo comparando dos textos tendria que volver a buscarlos.
    final todos = paneles.paneles;
    final aPintar = todos.length <= caben ? todos : todos.sublist(0, caben);

    // ============================================================================
    // Y LA FILA DE PESTANAS SE PINTA SIEMPRE QUE HAYA **MAS DE UN PANEL ABIERTO**, Y
    // NO SI LOS QUE CABEN EN LA PANTALLA
    // ============================================================================
    //
    // Y ESTO ES LO QUE ENSENO UNA CAPTURA, Y LA PRIMERA DECISION ESTABA MAL.
    //
    // La regla escrita al principio --"por debajo de 1.100 px no hay pestanas"-- salia de un
    // argumento cierto y de una conclusion falsa. El argumento: a 360 px tres nombres de
    // texto son tres columnas de 60 px. Cierto. La conclusion: "no hay pestanas". Falsa,
    // porque Esos 60 px son de las **columnas en paralelo**, no de la fila de pestañas.
    //
    // Y MEDIDO el 6 de octubre de 2026 en una captura a 360 px con `/leer/KJV2006/John.3.16/
    // y/CLARKE/John.3.16`: se ve **un panel**, con su barra y su campo, y el segundo panel
    // esta abierto --22,5 MiB de paginas SQLite abiertos-- y **no hay ninguna manera de
    // llegar a el**. Ni pestañas, ni una fila, ni un boton. Quien recibe un enlace de dos
    // ventanas en el movil se queda mirando la mitad sin saber que hay otra mitad.
    //
    // Y ESO ES PEOR QUE UNA PESTANA RECORTADA. Un nombre con puntos suspensivos se sabe
    // que esta ahi y se puede ir; un panel invisible no existe.
    final hayPestanas = paneles.cuantos > 1;

    return Column(
      children: <Widget>[
        // Y LA FILA DE PESTANAS **SOLO CUANDO HAY MAS DE UNO**. Con uno, el nombre de la
        // version esta en la barra del panel, que es donde estaba antes de esto, y una
        // fila con un solo nombre seria el mismo dato en dos sitios. Ver `fila_de_pestanas`.
        if (hayPestanas)
          FilaDePestanas(
            // Y LA FILA RECIBE **TODOS** LOS PANELES ABIERTOS, y no los que tienen columna.
            //
            // Y ESTO ES EL MISMO ARREGLO DE ARRIBA, en el otro lado: a 360 px `aPintar` son
            // los que caben --**uno**-- y pasarle esa lista a la fila daria una fila con un
            // solo nombre, que es justo lo contrario de lo que hace falta. Quien llega por
            // un enlace de dos ventanas tiene que ver las **dos** pestanas, y la segunda es
            // la que se lleva a un panel que no tiene columna.
            paneles: todos,
            moduloDelante: paneles.idDelModulo,
            nombreDe: _nombreDeUnModulo,
            alFrente: ponerUnPanelAlFrente,
            alCerrar: cerrarUnPanel,
            alAbrirOtro: () => abrirOtroPanel(context),
          ),
        Expanded(
          child: Row(
            children: <Widget>[
              for (var i = 0; i < aPintar.length; i++) ...<Widget>[
                if (i > 0)
                  const VerticalDivider(
                    width: Medidas.divisorEntrePaneles,
                    thickness: 1,
                  ),
                Expanded(
                  // Y LA CLAVE **ES EL IDENTIFICADOR DEL MODULO**, y no el indice. Con la
                  // clave por indice, Flutter reutiliza el estado del panel del indice 0
                  // para el modulo nuevo que se abre en ese sitio, y el `_TextoDelVersiculo`
                  // se queda con los gestos de gestor del versiculo del texto anterior
                  // apuntando a un `TextSpan` que ya no existe. Es un fallo que solo sale
                  // al abrir y cerrar paneles en un orden que no sea el natural.
                  key: ValueKey<String>('panel:${aPintar[i].moduloId}'),
                  child: _lectorDe(aPintar[i].moduloId, hayPestanas, context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// La pantalla de lectura de un panel.
  ///
  /// Y [conPestanas] DICE SI HAY FILA ARRIBA, y no se deduce de la lista: con dos
  /// paneles abiertos en una ventana de 800 px se ve uno solo y **no hay fila** --por
  /// debajo de 1100 px no cabe el paralelo--, y el nombre de la version tiene que seguir
  /// en la barra. Que lo decida "hay mas de uno abierto" dejaria la ventana de 800 px sin
  /// ningun sitio donde se vea que texto esta abierto.
  Widget _lectorDe(String moduloId, bool conPestanas, BuildContext contexto) {
    final vm = paneles.lectorDe(moduloId);
    if (vm == null) return const SizedBox.shrink();

    return LectorView(
      viewModel: vm,
      // Y LA BARRA **SOLO CUANDO NO HAY PESTANAS**, y el criterio es "se ve la fila de
      // pestañas" y no "hay dos paneles". Con dos paneles en una ventana de 800 px no hay
      // fila y la barra tiene que seguir ahi; con dos paneles a 1440 hay fila y la barra
      // sobraria. Ver `mostrarBarraDeAplicacion`.
      mostrarBarraDeAplicacion: !conPestanas,
      // Y CADA PANEL **PULSA SUS PROPIAS COSAS**. Un `alPulsarPasaje` que usara
      // "el modulo del lector" moveria el panel de delante desde el de fondo, y las
      // flechas de capitulo del panel de la izquierda acabarian llevamos a Juan 5 en el
      // de la derecha. Ver `irAReferencia`.
      alPulsarPasaje: (Referencia r) => irAReferencia(moduloId, r),
      alPedirComentario: () => elegirComentarioDe(moduloId, contexto),
      alVerIndice: (String numero) => verElIndiceDeEn(moduloId, numero),
      alAlternarPalabrasDeJesus: vm.alternarPalabrasDeJesus,
      alBuscar: () => buscarEnElPanelDe(moduloId),
      alDescargarComentario: _sePuedeDescargar(_ruta) ? descargarComentarioPedido : null,
      modulosDelCatalogo: biblioteca.manifiesto.modulos,
      versiones: _versionesDisponibles(),
      alAbrirLibros: () => elegirLibroDe(moduloId, contexto),
      alAbrirVersiones: () => abrirLaHojaDeVersiones(moduloId, contexto),
      resaltados: resaltados,
      alCambiarDeVersion: (String id) => cambiarDeVersionEn(moduloId, id),
      alVolver: irAHome,
    );
  }

  // --- los paneles: abrir, cerrar y traer al frente ---

  /// El nombre legible de un modulo, tal como lo dice el manifiesto.
  ///
  /// Y **CAE AL IDENTIFICADOR** si el manifiesto no lo tiene, y no a cadena vacia. Un
  /// modulo abierto cuyo nombre no se conoce es el resultado de abrir algo que el
  /// manifiesto ya no declara --un enlace de un despliegue viejo--, y una pastilla sin
  /// nombre no dice nada de que hay ahi. Con el identificador se ve cual es, y con el
  /// identificador se puede comprobar en el catalogo.
  String _nombreDeUnModulo(String id) => biblioteca.manifiesto.porId(id)?.nombre ?? id;

  /// Poner un panel delante de los demas.
  ///
  /// Y **NO ES UN `ajustarA` CON UNA RUTA NUEVA**: es cambiar cual de los que ya estan
  /// abiertos se ve. Y ES `replaceState`, y no `pushState`, por la misma regla que
  /// cambiar de version: quien trae un panel al frente quiere seguir leyendo lo mismo, y
  /// con `pushState` el gesto de atras devolveria al panel anterior --que es lo mismo, en
  /// otra columna-- en vez de al pasaje anterior.
  Future<void> ponerUnPanelAlFrente(String moduloId) async {
    if (!paneles.ponerAlFrente(moduloId)) return;
    final p = paneles.delante;
    final vm = paneles.lectorDelante;
    if (p == null || vm == null) return;

    await ajustarA(_rutaDe(_ruta, principal: RutaLectura(
      moduloId,
      vm.leyendo ?? p.referencia,
      p.comentarioId,
    )));
  }

  /// Cerrar un panel.
  ///
  /// Y EL ORDEN IMPORTA Y ESTA ES LA RAZON: **primero se quita de la lista y se avisa, y
  /// despues se destruye su view model.** Al reves, el frame que se pinta entre medias
  /// muestra un panel abierto cuyo `.amod` ya esta cerrado, y leer de ahi da un
  /// `SqliteException` en pantalla. Y no es un caso raro: `cerrar` destruye el view model
  /// **despues** del `notifyListeners` justamente para esto, y este metodo no puede hacer
  /// al reves sin deshacer esa proteccion.
  ///
  /// Y **ES `replaceState`**, y no `pushState`, por la misma regla que abrir un panel: es
  /// un cambio de como se ve lo mismo, no un sitio nuevo. Con `pushState`, cerrar una
  /// pestana por error y pulsar atras devolveria la pestana --util-- pero dejaria la
  /// flecha de atrasINSTANCE consumida por un error, y la siguiente pulsacion ya seria
  //  "volver al pasaje anterior", que no es lo que se espera.
  Future<void> cerrarUnPanel(String moduloId) async {
    final p = paneles.panelDe(moduloId);
    if (p == null) return;

    // Y LA RUTA SE CALCULA **ANTES** DE CERRAR, y no despues. Es al reves de lo obvio y
    // el motivo es que la ruta describe los paneles que **quedan**, y despues de cerrar no
    // quedan los cerrados: construirla despues daria una ruta con el panel que se acaba
    // de cerrar, y el `build` de esa ruta lo volveria a abrir. Cerrar un panel y que se
    // vuelva a abrir solo es el peor fallo posible de esta pantalla.
    final siguiente = paneles.delante?.moduloId == moduloId
        ? _otroQueQueda(moduloId)
        : paneles.delante?.moduloId;
    if (siguiente == null) {
      await irAHome();
      return;
    }

    paneles.cerrar(moduloId);
    paneles.ponerAlFrente(siguiente);

    final vm = paneles.lectorDelante;
    final vmDel = vm;
    if (vmDel == null) return;
    await ajustarA(_rutaDe(
      _ruta,
      principal: RutaLectura(
        siguiente,
        vmDel.leyendo ?? paneles.referencia ?? const Referencia('John', 1),
        paneles.delante?.comentarioId,
      ),
    ));
  }

  /// El identificador de un panel que **no** es [moduloId].
  ///
  /// Y DEVUELVE EL **SIGUIENTE** EN LA LISTA Y NO EL PRIMERO, porque quien cierra la
  //  ventana que esta leyendo quiere ver lo que tenia al lado, no volver al primero por
  //  orden de apertura.
  String? _otroQueQueda(String moduloId) {
    for (final p in paneles.paneles) {
      if (p.moduloId != moduloId) return p.moduloId;
    }
    return null;
  }

  /// Abrir otro texto al lado del que se esta leyendo.
  ///
  /// Y **ES LA HOJA DE VERSIONES, LA MISMA** que abre el nombre de la version en la barra.
  /// Y es la misma a proposito: abrir "la KJV en otra ventana" y cambiar "a la KJV" son la
  /// misma pregunta --cual quiero al lado-- y con dos hojas distintas habria dos listas de
  /// textos del catalogo que se pueden quedar viejas cada una a su ritmo.
  ///
  /// Y **NO ABRE UN PANEL SI EL ELEGIDO YA ESTA ABIERTO**: lo trae al frente. Medido: dos
  /// paneles del mismo `.amod` son **22,5 MiB** de paginas SQLite abiertas dos veces, y en
  /// un movil de gama baja eso es la diferencia entre que funcione y que no. Ver
  /// `panel_abierto.dart`.
  Future<void> abrirOtroPanel(BuildContext contexto) async {
    final actual = paneles.idDelModulo;
    final elegida = await mostrarHojaDeVersiones(
      context: contexto,
      disponibles: _versionesDisponibles(),
      abierta: actual,
    );
    if (elegida == null) return;

    if (elegida == actual) return;
    if (paneles.panelDe(elegida) != null) {
      await ponerUnPanelAlFrente(elegida);
      return;
    }

    await abrirPanel(elegida);
  }

  /// Abrir [moduloId] como un panel mas, con la referencia que se esta leyendo.
  ///
  /// Y ES PUBLICA Y NO PRIVADA, y no por comodidad: es lo que hacen las tres cosas que
  /// pueden abrir un panel --el `+`, cambiar de version desde la hoja de la cabecera, y
  /// abrir una version en paralelo al recibir un enlace con dos ventanas--, y con tres
  /// copias del mismo camino la primera que se quede sin actualizar seria un boton que
  /// abre el panel con la referencia equivocada.
  ///
  /// Y **USA LA REFERENCIA DE DELANTE**, y no la del panel en el que se ha pulsado. Con un
  /// solo panel da igual. Con varios, abrir desde la version selectora de un panel de
  /// fondo lleva el texto nuevo **al pasaje que se esta viendo**, que es lo que quiere
  /// quien compara Juan 3 en dos traducciones: el nuevo tiene que salir en Juan 3, no en
  /// el Juan 7 que ese panel tenga guardado.
  Future<void> abrirPanel(String moduloId) async {
    if (moduloId.isEmpty) return;

    // Y SI YA ESTA ABIERTO, **LO TRAE DELANTE Y NO ABRE OTRO**. Medido: dos paneles del
    // mismo `.amod` son 22,5 MiB de paginas SQLite abiertas dos veces.
    if (paneles.panelDe(moduloId) != null) {
      await ponerUnPanelAlFrente(moduloId);
      return;
    }

    // Y EL TOPE **NO ES EL NUMERO DE PANELES, ES EL DE COLUMNAS QUE CABEN EN LA
    // PANTALLA DE AHORA**, y no son dos cosas distintas:
    //
    //   - [Medidas.maximoDePanelesDeLectura] --**tres**-- es el tope de **memoria**, y esta
    //     escrito alli con su motivo: tres textos de 22,5 MiB son 67.633.152 bytes de paginas
    //     SQLite, y en un movil de gama baja eso es lo que hace que el sistema mate el
    //     proceso.
    //
    //   - El ancho **no** pone un tope de paneles en ninguna ventana, porque las pestañas
    //     se pintan a cualquier anchura y lo que se recorta son las **columnas**. Medido: a
    //     360 px caben **una**, y con dos paneles abiertos se ve una y la otra esta en su
    //     pestaña, a un toque. Y eso es mejor que no abrirlo: abierto y a un toque se ve;
    //     cerrado se ve que no hay nada al lado, que es tambien una respuesta.
    //
    // Y SE COMPRUEBA **ANTES** de abrir, y no despues. Abrir y luego decidir que no cabe
    // deja el `.amod` abierto, que es exactamente la memoria que este limite existe para no
    // gastar.
    if (paneles.cuantos >= Medidas.maximoDePanelesDeLectura) {
      biblioteca.anadirAviso(
        'Ya hay ${Medidas.maximoDePanelesDeLectura} textos abiertos al lado. Cada uno '
        'son unas 22,5 MiB de paginas abiertas a la vez, y por encima de ahi un movil deja '
        'de responder. Cierra una ventana para abrir otra.',
        clase: ClaseDeAviso.informacion,
      );
      return;
    }

    final referencia = lector.leyendo ?? const Referencia('John', 1);
    await irA(_rutaDe(_ruta, principal: RutaLectura(moduloId, referencia)));
  }

  /// La ruta de lectura con [principal] delante, o ella misma si [actual] no es de paneles.
  ///
  /// Y **NO CAMBIA LA RUTA SI [actual] NO TIENE PANELES**, y no es una comodidad: quien
  /// llama --traer un panel al frente, abrir otro, ir a un pasaje-- no tiene que saber si
  /// hay demas, y con esta regla solo hay **un sitio** que sabe escribir una ruta con
  /// paneles. Un `if (hayVarios)` en cada uno de los tres sitios seria tres reglas que se
  /// pueden separar, y la primera que se separe da una ruta con menos pestanas de las que
  /// hay --que es el fallo que este metodo existe para que no pase.
  Ruta _rutaDe(Ruta actual, {required RutaLectura principal}) {
    if (actual is! RutaPaneles) return principal;

    final otros = <RutaLectura>[];
    for (final r in actual.resto) {
      if (r.modulo == principal.modulo) continue;
      final vm = paneles.lectorDe(r.modulo);
      if (vm == null) continue;
      otros.add(RutaLectura(r.modulo, vm.leyendo ?? r.referencia));
    }
    if (otros.isEmpty) return principal;
    return RutaPaneles(actual.texto, principal, otros);
  }

  /// Ir a otro pasaje **de este panel**, y traerlo delante.
  ///
  /// Y **TRAE EL PANEL DELANTE**, y no es un detalle: las flechas de capitulo de un panel
  /// que no esta delante las estara pulsando quien no lo esta leyendo, y mover un panel de
  /// fondo mientras se ve otro es una forma de que nadie sepa que se ha movido algo. En
  /// Logos, tocar un panel de fondo lo trae delante; y por lo demas, es lo unico que hace
  /// que la columna que se mueve sea la que se ve.
  Future<void> irAReferencia(String moduloId, Referencia referencia) async {
    final p = paneles.panelDe(moduloId);
    if (p == null) return;
    await irA(_rutaDe(
      _ruta,
      principal: RutaLectura(moduloId, referencia, p.comentarioId),
    ));
  }

  // --- lo que hace un panel concreto, y no el de delante ---

  /// Elegir el comentario **de este panel**.
  ///
  /// Y [elegirComentario] sigue siendo el metodo que abre la hoja, y no se ha
  /// duplicado: abrir una hoja y elegir un comentario son la misma operacion. Lo que cambia
  /// es a que panel se le aplica el resultado, y por eso se le dice cual.
  Future<void> elegirComentarioDe(String moduloId, BuildContext contexto) async {
    final vm = paneles.lectorDe(moduloId);
    if (vm == null) return;

    final actuales = _comentariosDisponibles();
    final elegido = await mostrarHojaDeComentarios(
      context: contexto,
      actuales: actuales,
      abierto: vm.idDelComentario,
    );
    if (elegido == null) return;

    final p = paneles.panelDe(moduloId);
    if (p == null) return;
    await ajustarA(_rutaDe(
      _ruta,
      principal: RutaLectura(moduloId, vm.leyendo ?? p.referencia, elegido),
    ));
  }

  /// Ver el indice de una palabra **de este panel**.
  ///
  /// Y **NO HACE NADA SI ESE PANEL NO ESTA ABIERTO**, y no mira el de delante. El indice
  /// es de un texto concreto: la palabra `G2316` que se toca en la columna del CLARKE es la
  /// de la columna del CLARKE, y si el panel ya no esta --porque se ha cerrado mientras
  /// estaba el indice abierto-- buscarlo en otro texto daria unos resultados que no son
  /// los de la palabra que se ha tocado.
  Future<void> verElIndiceDeEn(String moduloId, String numero) async {
    if (paneles.lectorDe(moduloId) == null) return;
    await verElIndiceDe(numero);
  }

  /// Buscar en **este** panel.
  ///
  /// Y **NO HACE NADA SI ESE PANEL NO ESTA ABIERTO**. Y no trae el panel delante, a
  /// diferencia de las hojas: abrir la busqueda es una pantalla a la que se va y se vuelve,
  /// y volver tiene que devolver al panel de donde se salio, que es el que se habia
  /// pedido la busqueda. Traerlo delante --o no-- es lo mismo en cuanto se vuelve, asi que
  /// no se toca el orden de las pestanas por algo que se deshace solo.
  Future<void> buscarEnElPanelDe(String moduloId) async {
    if (paneles.lectorDe(moduloId) == null) return;
    await buscarEnElTextoAbierto();
  }

  /// Elegir libro y capitulo **de este panel**.
  ///
  /// Y ES EL MISMO CAMINO QUE [elegirLibro] con el modulo del panel. Y **LA RUTA LLEVA EL
  /// `con` DEL PANEL QUE SE MUEVE**, y no el del de delante: cambiar de libro en el panel
  /// del fondo no puede quitarle el comentario al del frente.
  Future<void> elegirLibroDe(String moduloId, BuildContext contexto) async {
    // Y EL PANEL **SE TRAE DELANTE ANTES DE ABRIR LA HOJA**, y no despues de elegir. La
    // hoja de libros dice cual es "el que se esta leyendo" con una marca, y esa marca la
    // pone el view model del panel de delante: si se abriera la hoja con el panel del
    // fondo delante, el libro que se esta leyendo --que es el del fondo-- saldria sin
    // marcar, y quien elige creeria que va a cambiar de sitio cuando en realidad ya no
    // esta ahi.
    if (moduloId != paneles.idDelModulo) {
      await ponerUnPanelAlFrente(moduloId);
    }
    if (!contexto.mounted) return;
    await elegirLibro(contexto);
  }

  /// Abrir el selector de version **de este panel**.
  ///
  /// Y ABRE LA HOJA CON **ESTE** PANEL MARCADO COMO ABIERTO, y no con el de delante: si el
  /// panel del fondo tiene el CLARKE y se abre su hoja de versiones, tiene que verse el
  /// CLARKE como el que ya esta puesto. Con el de delante marcado, la hoja abriria con la
  /// KJV marcada y quien pulsara el CLARKE --que ya tiene abierto-- creeria que lo cambia.
  Future<void> abrirLaHojaDeVersiones(String moduloId, BuildContext contexto) async {
    final deEste = paneles.lectorDe(moduloId);
    final deEsteAlAbrir = deEste?.leyendo ?? const Referencia('John', 1);

    if (moduloId != paneles.idDelModulo) {
      await ponerUnPanelAlFrente(moduloId);
    }
    if (!contexto.mounted) return;
    await elegirVersion(contexto);

    // Y EL VALOR ELEGIDO **ABRE UN PANEL NUEVO** en vez de sustituir: cambiar de version
    // con dos textos abiertos es lo unico que hace que tener dos textos abiertos tenga
    // sentido, y sustituir seria volver al caso de un solo texto con un boton.
    //
    // Y SE COMPARA CON **[moduloId]**, y no con el de delante: `elegirVersion` deja el
    // nuevo en el panel de delante, y si se comparara con el de delante --que ahora es
    // el nuevo-- la comparacion siempre seria cierta y no se abriria nada.
    final id = paneles.lectorDelante?.idDelModulo;
    if (id == null || id == moduloId) return;
    if (paneles.panelDe(id) != null) return;
    await irA(_rutaDe(_ruta, principal: RutaLectura(id, deEsteAlAbrir)));
  }

  /// Cambiar de version **desde este panel**, abriendo la otra al lado.
  Future<void> cambiarDeVersionEn(String moduloId, String id) async {
    final p = paneles.panelDe(moduloId);
    final referencia = paneles.lectorDe(moduloId)?.leyendo ??
        p?.referencia ??
        const Referencia('John', 1);
    await irA(_rutaDe(
      _ruta,
      principal: RutaLectura(id, referencia, paneles.panelDe(id)?.comentarioId),
    ));
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
  /// El identificador de la primera Biblia que esta **en este dispositivo**, o null.
  ///
  /// ================================================================================
  /// POR QUE UNA FUNCION PROPIA Y NO UN `firstWhere` EN EL `switch`
  /// ================================================================================
  ///
  /// Porque la pregunta --"¿tengo ya algo que leer?"-- la van a hacer varios sitios a partir
  /// de ahora, y una pregunta con tres sitios que la responden es una pregunta que acaba
  /// con tres reglas distintas. Y porque **el filtro es de tipo, no de estado**: `descargado`
  /// incluye lo desactualizado y lo retirado, que se leen, asi que un "descargado" aqui
  /// significa "esta en el dispositivo y se puede abrir".
  ///
  /// Y `descargado` Y NO `sePuedeLeer` A PROPOSITO. Los dos ahora mismo coinciden, pero
  /// `sePuedeLeer` es la pregunta de "puedo pulsar Leer en esta fila" y esta es la de
  /// "puedo abrir una Biblia sin descargar nada". Confundir los dos es el fallo de hacer que
  /// el boton "Leer" aparezca en un modulo que no se puede abrir.
  String? _primeraBibliaEnElDispositivo() {
    for (final f in biblioteca.filas) {
      if (f.descargado && f.modulo?.tipo == TipoModulo.biblia) return f.id;
    }
    return null;
  }

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
    // Y LEYENDO **ES** "HAY AL MENOS UN PANEL CON MODULO", y no "la ruta es de lectura".
    //
    // Con dos paneles, la ruta es una [RutaPaneles], y si se preguntara por el tipo de la
    // ruta --como se preguntaba antes-- una ventana con dos textos abiertos se caeria en
    // la biblioteca. La pregunta correcta es si hay un modulo abierto, y eso lo sabe el
    // view model del panel de delante.
    final leyendo =
        paneles.cuantos > 0 && lector.estado != EstadoLecturaTexto.sinModulo;

    // Y EL MARCO ENVUELVE A **CUALQUIER** PANTALLA, y no solo a la de lectura.
    //
    // Cuando el marco estaba dentro de `LectorView`, pulsar "Biblioteca" en la barra lateral
    // sacaba de la barra lateral: la biblioteca se pintaba sin panel de herramientas, sin
    // saber donde estabas y sin poder cambiar de destino sin darle a "atras". Y era
    // literalmente lo que se veia: la biblioteca **desacoplada**, como si fuera otra
    // aplicacion.
    //
    // El marco es de la **aplicacion** --una ventana con herramientas al lado y destinos-- y
    // no de una pantalla. Lo pone el enrutador, que es el unico que sabe cual de las cinco
    // pantallas esta viva.
    Widget pantalla = _ruta is RutaIndice && lector.modulo != null
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
        ? _zonaDePaneles(context)
        : BibliotecaView(
            viewModel: biblioteca,
            alPulsarLeer: abrirDesdeLaBiblioteca,
            alPulsarDescargar: descargar ?? noHaceNada,
            alPulsarFicheroLocal: abrirFicheroLocal ?? noHaceNada,
            alReintentar: reintentarCatalogo ?? noHaceNadaVoid,
          );

    // Y EL DESTINO DE LA BARRA SE SACA DE LA RUTA, y no se pasa como parametro. Una
    // pantalla que sabe en que destino esta es una pantalla que lleva el estado de la
    // aplicacion, y es el mismo fallo que una vista que decide cuando abrir el catalogo.
    pantalla = MarcoDeEstudio(
      destino: _destinoDeLaRuta(),
      alElegirDestino: irAlDestino,
      hijo: pantalla,
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
