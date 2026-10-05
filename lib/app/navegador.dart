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
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/ui/core/rutas.dart';
import 'sonda_nativa.dart'
    if (dart.library.js_interop) 'sonda_web.dart' as plataforma;
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
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
  void _alCambiarLaBiblioteca() {
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
    final leyendo = _ruta is RutaLectura && lector.estado != EstadoLecturaTexto.sinModulo;

    final pantalla = leyendo
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
            // Y SOLO HAY BOTON DE BAJAR SI HAY ALGO QUE BAJAR. Si el comentario pedido
            // no esta en el catalogo --porque el enlace es de otro despliegue-- no hay
            // nada que ofrecer, y un boton que no hace nada es peor que no tenerlo.
            alDescargarComentario: _sePuedeDescargar(_ruta) ? descargarComentarioPedido : null,
            modulosDelCatalogo: biblioteca.manifiesto.modulos,
            alCambiarDeVersion: cambiarDeVersion,
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
