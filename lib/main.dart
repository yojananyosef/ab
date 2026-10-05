// Donde se enchufan las piezas.
//
// UN SOLO FICHERO, Y ES A PROPOSITO. `get_it` y `provider` hacen lo mismo con menos
// lineas, y por eso no estan: lo que hay aqui son quince lineas de codigo real y
// ninguna dependencia. El orden de construccion se lee de arriba abajo, que es
// exactamente lo que se necesita saber cuando algo no arranca.
//
// LO QUE HACE ESTE FICHERO Y LO QUE NO. Conecta y arranca. No decide nada: que
// origen se usa sale de `origen.dart`, como un modulo, como se guarda sale de su
// servicio. Si este fichero empieza a tener `if` de plataforma, es que algo se ha
// metido donde no toca.
//
// LO QUE NO HAY AQUI Y POR QUE.
// - **Un contenedor de inyeccion de dependencias.** No hay `get_it` ni `provider`.
//   Con cinco pantallas y seis servicios, un contenedor es mas configuracion que
//   codigo, y el orden de construccion se lee mejor explicito.
// - **Pruebas de humo con la app entera.** Hay una, en `test/widget_test.dart`, y
//   monta esta misma app con el mismo codigo. Un doble de cien lineas que solo se
//   usa en pruebas acaba siendo una segunda implementacion que nadie prueba.
// - **Un enrutador.** La primera pantalla es una y no hay por donde navigating. El
//   enrutador llega con el grupo 7, cuando haya un pasaje al que ir.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'app/navegador.dart';
import 'app/sonda.dart';
import 'data/repositories/catalogo_repository.dart';
import 'data/services/almacenamiento.dart';
import 'app/arranque.dart';
import 'data/services/almacenamiento_de_modulos.dart';
import 'data/services/http_service.dart';
import 'data/repositories/modulo_repository.dart';
import 'data/services/sqlite_service.dart';
import 'domain/models/referencia.dart';
import 'domain/models/tipo_de_contenido.dart';
import 'domain/use_cases/obtener_modulo.dart';
import 'domain/use_cases/resultado_obtencion.dart';
import 'ui/core/rutas.dart';
import 'ui/core/tema.dart';
import 'ui/features/biblioteca/view_models/aviso.dart';
import 'ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'ui/features/lector/view_models/lector_view_model.dart';

Future<void> main() async {
  // Los enlaces del motor y de las plataformas se preparan **antes** de la primera
  // pantalla, y no cuando hace falta.
  //
  // La razon es que en web `sqlite3.wasm` son 750.007 bytes que se descargan: si se
  // preparase al abrir el primer modulo, el primer versiculo de Juan se quedaria
  // esperando sin decir nada de por que. Preparandolo aqui, la espera es la de
  // arrancar, que es donde la gente ya espera.
  //
  // Y el fallo, si lo hay, es un fallo de arranque y se ve como un fallo de
  // arranque, no como un versiculo que no sale.
  try {
    await prepararPlataforma();
  } catch (e) {
    // Se sigue arrancando. Un fallo aqui no puede impedir abrir la biblioteca, que
    // es lo unico que hay: es mejor una biblioteca sin modulos que una pantalla en
    // blanco. Lo que no se puede es tragarselo sin decir nada, asi que el aviso
    // aparece en la propia biblioteca.
    _avisoDeArranque = 'No se ha podido preparar el motor de lectura: $e';
  }

  // La estrategia de direccion va **antes** de `runApp`, y no cuando hace falta.
  //
  // Cambiarla con la aplicacion ya montada deja la barra a medio camino: el framework
  // ya leyo la ruta con la estrategia antigua y el historial ya tiene una entrada que no
  // se parece a lo que se ve. Lo que se hace despues es recargar, y una aplicacion que
  // hay que recargar para que cuadre la barra esta rota.
  //
  // Y el resultado se guarda solo para que quede escrito que se ha intentado: no se
  // avisa de nada al usuario, porque una barra con `#!/leer/...` en vez de con barras
  // es una diferencia de forma y no de funcionamiento. Ver `rutas.dart`.
  await prepararEstrategiaDeDireccion();

  runApp(const AbApp());
}

/// Un aviso del arranque, si ha habido.
///
/// Vive aqui porque lo produce `main()` y lo consume la biblioteca, que es la
/// primera pantalla. Es texto y no un error: la app arranca y lo ensenar, en vez de
/// morir antes de pintar nada.
String? _avisoDeArranque;

/// Prepara lo que depende de la plataforma.
///
/// En web carga el motor SQLite; en nativo no hay nada que hacer. La funcion vive
/// en `sqlite_service.dart` porque es el unico sitio que sabe en que plataforma
/// esta, y aqui no hay ni un `if`.
Future<void> prepararPlataforma() async {
  await prepararSiHaceFalta();
}

/// La app.
class AbApp extends StatefulWidget {
  const AbApp({super.key});

  @override
  State<AbApp> createState() => _AbAppState();
}

class _AbAppState extends State<AbApp> {
  late final CatalogoRepository _catalogo;
  late final HttpService _http;
  late final AlmacenamientoDeModulos _modulos;
  late final BibliotecaViewModel _biblioteca;
  late final LectorViewModel _lector;
  late final PlatformRouteInformationProvider _proveedorDeRutas;
  late final NavegadorAb _navegador;

  /// La sonda de la comprobacion en navegador. Existe siempre; solo hace algo si se
  /// compilo con `--dart-define=AB_SONDA=...`.
  final Sonda _sonda = Sonda();

  @override
  void initState() {
    super.initState();

    _http = HttpService();
    _catalogo = CatalogoRepository(http: _http, almacenamiento: const Preferencias());
    _modulos = crearAlmacenamientoDeModulos();
    _biblioteca = BibliotecaViewModel();
    // Y CON LAS PREFERENCIAS DEL SISTEMA, que es donde vive la unica preferencia de
    // lectura --si las palabras de Jesus van en rojo. Es la primera vez que el lector
    // guarda algo, y es una preferencia y no una nota: `almacenamiento.dart` tiene el
    // motivo de por que esa diferencia lo es todo.
    _lector = LectorViewModel(almacenamientoDeLectura: const Preferencias());

    // El proveedor de rutas va aqui y no dentro de `MaterialApp.router`, porque es el
    // **mismo** que necesita el enrutador para poder reportarle las rutas. Si cada uno
    // tuviese el suyo, los dos escribirian en la barra y la pantalla iria por detras.
    //
    // Y LA RUTA INICIAL ES LA DE LA BARRA DEL NAVEGADOR, tal cual. Sin recortar el
    // prefijo del despliegue: `PlatformRouteInformationProvider` entrega la ruta a
    // `setNewRoutePath`, y la ruta entera --`/ab/leer/KJV2006/John.3.16`-- se resuelve
    // sola porque `Rutas.leer` busca la ultima aparicion de `/leer/`. Recortarla aqui
    // seria hacerlo dos veces.
    _proveedorDeRutas = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        // Con la sonda activa manda la ruta que se le pidio, y no la de la barra. Es lo
        // que permite probar un enlace profundo sin tener que escribirlo en el
        // navegador a mano, que es lo unico que se podria hacer de otra manera.
        uri: Uri.parse(
          kSondaActiva ? kPedidoDeSonda : Uri.base.toString(),
        ),
      ),
    );

    _navegador = NavegadorAb(
      biblioteca: _biblioteca,
      lector: _lector,
      proveedor: _proveedorDeRutas,
      abrir: _abrirModulo,
      descargar: (id) => _descargar(id),
      abrirFicheroLocal: (id) => _ficheroLocal(id),
      reintentarCatalogo: () => _cargar(),
    );

    // La primera lectura arranca aqui y no en el `build`, para que no se repita en
    // cada cambio de estado. `addPostFrameCallback` porque `notifyListeners` dentro
    // de `initState` avisa a una pantalla que todavia no esta montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarYComprobar());
  }

  @override
  void dispose() {
    _navegador.dispose();
    _modulos.dispose();
    _catalogo.dispose();
    super.dispose();
  }

  /// Cargar el catalogo y, si la sonda esta activa, mirar lo que pasa.
  ///
  /// Y LA MEDICION DEL HISTORIAL VA DESPUES, Y NO EN EL MISMO `await`.Va en su propio
  /// paso porque necesita que la pantalla de lectura ya este leyendo: `medirElHistorial`
  /// sale adelante si no hay ningun texto abierto, y entonces no mide nada. Encadenado
  /// detras de [mirarLaAplicacion], que no devuelve nada hasta que hay un pasaje.
  Future<void> _cargarYComprobar() async {
    final res = await _cargar();

    if (!kSondaActiva) return;

    final ruta = rutaDeLaSonda;
    _moduloDeLaSonda = switch (ruta) {
      RutaLectura(:final modulo) => modulo,
      _ => 'KJV2006',
    };
    final esperado = switch (ruta) {
      RutaLectura(:final referencia) => referencia,
      _ => const Referencia('John', 3, 16),
    };

    // Y EL COMENTARIO QUE LA RUTA PIDE, O NULL SI NO PIDE NINGUNO.
    //
    // Y NO SE USA COMO "ALGO MAS QUE COMPROBAR" SINO COMO **CONDICION PARA DAR EL
    // RESULTADO POR BUENO**. Con una ruta `/leer/KJV2006/John.3.16/con/CLARKE` en un
    // perfil donde el CLARKE no esta, Juan 3:16 se lee a los dos segundos: la comprobacion
    // tendria su "ok" con el comentario sin abrir, 0 bytes bajados, y todo pareceria
    // bien. Medido el 4 de octubre de 2026, y fue exactamente eso lo que paso.
    final comentarioEsperado = switch (ruta) {
      RutaLectura(:final comentario?) => comentario,
      _ => null,
    };

    // Y BAJA EL TEXTO SI NO ESTA, antes de mirarlo.
    //
    // La sonda pide un enlace profundo --`/leer/KJV2006/John.3.16`-- y en una ejecucion
    // con el perfil limpio el texto no esta. La aplicacion, como esta, vuelve a la
    // biblioteca con un aviso, que es lo correcto para alguien que abre un enlace y no
    // tiene el texto: no se le descarga 22 MiB sin que lo pida.
    //
    // Aqui si se lo pide, porque lo pide **la comprobacion**. Y de ahi tambien sale el
    // dato de la 8.3: la primera ejecucion baja el modulo entero y la segunda, con el
    // mismo perfil, baja cero bytes. Ese numero lo cuenta el motor de obtencion --
    // [Sonda.anotarDescarga]--, no la sonda.
    await _bajarSiFalta(esperado);

    // Y SE VUELVE A PEDIR EL PASAJE, y no se espera a que aparezca solo.
    //
    // Al arrancar, el enrutador pide la ruta --`/leer/KJV2006/John.3.16`-- y no puede
    // abrir el texto porque todavia no esta, asi que avisa y vuelve a la biblioteca.
    // Eso es lo correcto para alguien que abre un enlace y no tiene el modulo. Y aqui
    // significa que, despues de bajar el texto, **nadie vuelve a intentar leer**:
    // la pantalla se queda en la biblioteca con un aviso, y la comprobacion se queda
    // esperando un pasaje que no va a llegar.
    //
    // Que lo vuelva a pedir la propia sonda y no la aplicacion es una decision
    // consciente. En la aplicacion, pedir de nuevo seria Automatico, y Automatico es
    // exactamente lo que no hay que hacer: alguien que abre un enlace, no tiene el texto
    // y lo descarga tendria que verse al final en Juan 3:16 sin haberlo pedido. Lo que
    // falta para que sea Automatico de verdad es **preguntar**, y esa es una pantalla
    // que todavia no existe. Ver `openspec/changes`.
    // Y DENTRO DE UN `try`, Y CON UNA ESCRITURA DESPUES, por lo mismo que los pasos
    // siguientes: si `irA` se queda colgado --porque leer los bytes guardados del
    // almacenamiento del navegador no conteste-- hay que poder distinguirlo de que la
    // lectura del pasaje no llegue. Sin esta escritura, "tiempo agotado" no dice donde
    // se ha quedado, y en un fallo de este tipo la unica pista es el registro del
    // navegador, que no dice nada.
    try {
      // Y **CON** EL COMENTARIO DE LA RUTA, y no a secas. MEDIDO el 5 de octubre de
      // 2026: con `RutaLectura(_moduloDeLaSonda, esperado)` esta navegacion se come el
      // `/con/`, el enrutador quita el comentario --`cerrarComentario`--, y a partir de
      // ahi el paso 0 ya no ve `comentarioPedido` y no ofrece bajar nada. 0 bytes y un
      // "ok" final, otra vez.
      //
      // Y QUE SE LLEVE EL `comentario` DE LA RUTA Y NO UN ID PUESTO A MANO, porque la
      // sonda no sabe que comentario hay: solo sabe que la ruta pide uno.
      await _navegador.irA(RutaLectura(_moduloDeLaSonda, esperado, comentarioEsperado));
    } catch (e, traza) {
      _sonda.escribir(<String, Object?>{
        'resultado': 'excepcion',
        'motivo': 'no se ha podido pedir el pasaje $esperado: $e\n$traza',
      });
      return;
    }
    _sonda.escribir(<String, Object?>{
      'paso': 2,
      'resultado': 'pasaje pedido, el modulo esta abierto',
      'estadoLector': _lector.estado.name,
      'idDelModulo': _lector.idDelModulo,
    });

    // Y SE ESCRIBE UN "PASO 1" ANTES DE MIRAR EL PASAJE. Por que: si el texto no sale,
    // hay que saber si no se ha bajado, si no se ha abierto o si no se ha leido, y son
    // tres fallos distintos con tres arreglos distintos. Con una sola escritura al final
    // --"tiempo agotado"-- no se sabe cual de los tres es, y se averigua mirando el
    // registro del navegador, que no dice nada de esto.
    _sonda.escribir(<String, Object?>{
      'paso': 1,
      'resultado': 'catalogo leido, texto bajando',
      'estadoDelCatalogo': res.estadoDelCatalogo.name,
      'etiqueta': _catalogo.manifiesto.etiqueta,
      'modulos': _catalogo.manifiesto.modulos.length,
      'idsLocales': _biblioteca.idsLocales.toList()..sort(),
      'bytesDescargados': _sonda.bytesDescargados,
      // Y TAMBIEN AQUI, POR EL MISMO MOTIVO: `jsonEncode` no sabe escribir un
      // `Aviso`. Este es el informe de diagnostico que se escribe **antes** de mirar el
      // pasaje, asi que si revienta aqui se pierde justo el que dice si el texto se
      // bajo. Ver `sonda.dart`.
      'avisos': <String>[for (final a in _biblioteca.avisos) a.texto],
    });

    // 0. Si la ruta pide un comentario que no esta, se acepta la descarga.
    //
    // Y ESTO ES LO QUE HACE UNA PERSONA, y la comprobacion en navegador no puede hacer
    // otra cosa: abrir un enlace a `/leer/KJV2006/John.3.16/con/CLARKE` en un movil donde
    // el CLARKE no esta **ofrece** bajarlo, y lo unico que se puede comprobar sin una
    // mano es aceptar la oferta y ver si funciona.
    //
    // Y NO PIDE NADA: si no hay nada que bajar, no hace falta. La primera version de esta
    // comprobacion no lo hacia y se quedaba 900 s esperando con Juan 3:16 entero y
    // **0 bytes** bajados, que es exactamente el fallo que esta comprobacion existe para
    // encontrar.
    //
    // Y SE ESPERA A QUE **HAYA PASAGE** ANTES DE OFRECER LA DESCARGA. La primera version
    // miraba solo si faltaba el comentario, y al empezar la sonda todavia no se ha
    // aplicado la ruta --eso pasa despues--, asi que `comentarioPedido` era null, la
    // espera se daba por buena y no se bajaba **nada**. Medido el 4 de octubre de 2026:
    // Juan 3:16 entero, 0 bytes, y un "ok" al final porque lo que se miraba era el texto.
    var offeredDownload = false;
    await _sonda.esperarAQue(
      () {
        if (_lector.pasaje == null) return false;
        if (_lector.tieneComentario) return true;
        if (_lector.comentarioPedido == null) return true;
        // Y SOLO UNA VEZ. `esperarAQue` pregunta cada 200 ms, y sin esta bandera se
        // pediria la misma descarga mientras la anterior esta en marcha.
        if (!offeredDownload) {
          offeredDownload = true;
          _navegador.descargarComentarioPedido();
        }
        return false;
      },
      // Y 420 s Y NO 150. Es el unico sitio de la sonda que espera a algo de verdad --
      // una descarga de 57 MiB-- y el limite de 150 s esta puesto para que la sonda
      // escriba su motivo antes de que el navegador se vaya al minuto 240 de reloj
      // virtual. Aqui el navegador sigue vivo hasta el minuto 660, asi que 420 s de
      // espera dejan margen de sobra para el paso siguiente.
      esperaMaxima: const Duration(seconds: 420),
    );

    _sonda.escribir(<String, Object?>{
      'paso': '0',
      'resultado': 'ruta aplicada, viendo que comentario falta',
      'comentarioEsperado': comentarioEsperado,
      'comentarioPedido': _lector.comentarioPedido,
      'tieneComentario': _lector.tieneComentario,
      'ofrecioLaDescarga': offeredDownload,
      'catalogoLoTiene': comentarioEsperado == null
          ? false
          : _catalogo.manifiesto.porId(comentarioEsperado) != null,
      'bytesDescargados': _sonda.bytesDescargados,
      'avisos': <String>[for (final a in _biblioteca.avisos) a.texto],
    });

    // 1. El pasaje. Es lo que comprueban 8.2 y 8.4.
    await _sonda.esperarYEscribir(
      motivoDeEspera: 'no se ha podido leer $esperado en el navegador',
      cuando: () => mirarLaAplicacion(
        sonda: _sonda,
        navegador: _navegador,
        catalogo: _catalogo,
        biblioteca: _biblioteca,
        lector: _lector,
        esperado: esperado,
        estado: res.estadoDelCatalogo,
        comentarioEsperado: comentarioEsperado,
      ),
    );

    // 2. El historial, con la pantalla ya leyendo.
    //
    // Y ESTE PASO VA DENTRO DE UN `try`, por lo mismo que el paso 1: una excepcion aqui
    // se traga igual de bien que antes, y la comprobacion 7.5 --que se toca el historial
    // del navegador-- se queda sin comprobar **sin decir nada**. Con el paso 1 sola se
    // sabia que Juan 3:16 se habia leido; con el paso 2 fallido no se sabe ni eso, porque
    // el paso 1 se habia escrito antes.
    if (esperado.versiculo == null) return;
    try {
      await _sonda.medirElHistorial(_navegador);
    } catch (e, traza) {
      _sonda.escribir(<String, Object?>{
        'resultado': 'excepcion',
        'motivo': 'no se ha podido medir el historial: $e\n$traza',
      });
      return;
    }

    // Y SE VUELVE A MIRAR UNA SOLA VEZ, y el resultado se guarda en una variable. La
    // primera version llamaba a `mirarLaAplicacion` **tres** veces --dos en el `spread` y
    // otra en el `if`-- y cada llamada hace una consulta al modulo. Tres consultas para
    // mirar lo mismo, y una de ellas decidia si lo demas se enseena. Con la variable, una
    // consulta y una decision.
    final despues = mirarLaAplicacion(
      sonda: _sonda,
      navegador: _navegador,
      catalogo: _catalogo,
      biblioteca: _biblioteca,
      lector: _lector,
      esperado: esperado,
      estado: res.estadoDelCatalogo,
    );
    _sonda.escribir(<String, Object?>{
      ...?despues,
      if (despues == null)
        'resultado': 'el texto dejo de estar en pantalla tras medir el historial',
      // Y ESTA ES LA MARCA DE "YA NO VA A HABER OTRA". El colector la ve y se para, en
      // vez de quedarse esperando un limite de tiempo entero a una escritura que no va a
      // llegar.
      //
      // MEDIDO EL 4 DE OCTUBRE DE 2026: el colector se paraba en la **primera** escritura
      // y las dos siguientes --la del historial-- llegaban a un servidor que ya no
      // escuchaba. Y como el `POST` se manda con `keepAlive`, algunas veces llegaban y
      // otras no, segun el estado de la conexion: o sea que la comprobacion del historial
      // pasaba o no segun el dia. Con la marca, se para cuando tiene todo.
      'final': true,
    });
  }

  /// El identificador del modulo que pide la ruta de la sonda.
  ///
  /// Y UN CAMPO Y NO UN `late final` CON VALOR, porque `initState` no puede llamar a
  /// `rutaDeLaSonda` --que es un `const` de compilacion-- sin que el analizador se queje
  /// de que se usa antes de declarar. Se deja vacio y se rellena en el constructor.
  String _moduloDeLaSonda = '';

  /// Baja el texto de la ruta de la sonda si no esta ya en el dispositivo.
  ///
  /// Y SOLO EN LA SONDA, y se dice explicitamente: bajar 22 MiB porque ha aparecido una
  /// ruta es una decision de producto, y tomarla aqui para que la comprobacion pase
  /// seria decidir la politica de la aplicacion desde el sitio que la mide.
  ///
  /// Lo que **si** falta, y se anota para el cambio siguiente, es ofrecer la descarga
  /// cuando alguien abre un enlace a un texto que no tiene. Ahora avisa y vuelve a la
  /// biblioteca; deberia preguntar "¿lo descargas?". Ver `openspec/changes`.
  Future<void> _bajarSiFalta(Referencia esperado) async {
    if (!kSondaActiva) return;

    // El `switch` va con un `default` explicito, porque `return` dentro de un patron no
    // es una expresion en Dart: `_ => return` no compila. Es la forma que si funciona, y
    // por eso el "no hay modulo en la ruta" se dice asi y no con un patron.
    final ruta = rutaDeLaSonda;
    if (ruta is! RutaLectura) return;
    final id = ruta.modulo;
    if (id.isEmpty) return;

    if (_biblioteca.idsLocales.contains(id)) return;
    if (_catalogo.manifiesto.porId(id) == null) return;

    await _descargar(id);
  }

  /// Lee el catalogo y lo que hay en el dispositivo.
  ///
  /// Delega en [arrancarBiblioteca], y no por gusto: la garantia de que el
  /// catalogo se ve aunque el almacenamiento no conteste vive ahi, y en un metodo
  /// privado de un `State` no se puede comprobar con una prueba.
  /// El arranque, y lo que ha pasado.
  ///
  /// Y DEVUELVE EL RESULTADO Y NO UN `void`, y no porque lo necesite quien llama --que lo
  /// ignora-- sino porque la sonda necesita saber **de donde salio el manifiesto**: si del
  /// servidor o de una copia guardada. Y esa es justo la diferencia entre "el manifiesto
  /// es el de hoy" y "se esta enseñando el de ayer", que es lo que comprueba la tarea 8.4
  /// y que no se puede mirar contando los avisos, porque los de la descarga estan siempre.
  Future<ResultadoDelArranque> _cargar() async {
    if (!mounted) return arranqueVacio();
    return arrancarBiblioteca(
      leerCatalogo: _catalogo.leer,
      almacenamiento: _modulos,
      vista: _biblioteca,
      avisosPrevios: <String>[?_avisoDeArranque],
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'AB',
    debugShowCheckedModeBanner: false,
    theme: temaDeAb(),
    routerDelegate: _navegador,
    routeInformationParser: const AnalizadorDeRuta(),
    routeInformationProvider: _proveedorDeRutas,
  );

  // --- acciones ---
  //
  // Las tres van aqui y no en la vista porque necesitan cosas que la vista no tiene:
  // el motor de obtencion, el almacenamiento y el selector de archivos.

  /// Abrir un modulo ya descargado, y devolverlo abierto.
  ///
  /// ES LO QUE LLAMA EL ENRUTADOR, y por eso devuelve `null` en vez de avisar. Quien
  /// llama --el enrutador-- tiene que poder distinguir "no esta" de "esta y hay un
  /// problema", y el aviso lo pone quien lo va a ensenar. Un `abrir` que avisa por su
  /// cuenta obliga al que llama a mirar si hay aviso, y se acaba mirando dos veces o
  /// ninguna.
  ///
  /// Y DEVUELVE UN MODULO **ABIERTO**, no una ruta. El `LectorViewModel` lo cierra en su
  /// `dispose`, que es quien sabe cuando se deja de leer. Devolver la ruta obligaria a
  /// que alguien mas cerrara, y dos sitios cerrando es uno de sobra o ninguno.
  ///
  /// Y COMPRUEBA LA INTEGRIDAD ANTES DE DEVOLVER, y no despues: `ModuloAbierto.abrir`
  /// hace `PRAGMA quick_check` y devuelve el motivo si no cuadra. Abrir un `.amod`
  /// descargado a medias da versiculos vacios y silenciosos, que es la forma mas
  /// incomoda de que alguien crea que la Biblia esta danada cuando lo que esta danado es
  /// la descarga.
  Future<ModuloAbierto?> _abrirModulo(String id, Referencia referencia) async {
    final bytes = await _bytesDe(id);
    // Sin bytes no hay modulo, y sin avisar: el enrutador pone el aviso cuando ve el
    // `null`, que es el unico sitio donde se decide que pantalla se ensena.
    if (bytes == null) return null;

    final ruta = _modulos.ponerEnMemoria(id, bytes);
    switch (ModuloAbierto.abrir(ruta, id: id)) {
      case Abierto(:final modulo):
        return modulo;
      case FalloAlAbrir(:final motivo):
        _biblioteca.anadirAviso(motivo);
        return null;
    }
  }

  /// Que clase de contenido declara un modulo ya descargado.
  ///
  /// Y NO ES LO MISMO QUE ABRIRLO. Abrir hace `quick_check` sobre las 57 MB de un
  /// comentario, y esta pregunta solo lee una fila de la tabla `info`. La diferencia
  /// son segundos en un movil, y es la razon de que la biblioteca **no** abra un
  /// modulo entero para pintar una etiqueta.
  ///
  /// Y DEVUELVE NULL SI NO SE PUEDE SABER, en vez de suponer. Un modulo que no se ha
  /// descargado, o cuya tabla `info` no se puede leer, no tiene etiqueta, y la fila lo
  /// dira como "no se sabe" en vez de mentir con "Biblia".
  Future<TipoDeContenido?> tipoDeContenido(String id) async {
    final bytes = await _bytesDe(id);
    if (bytes == null) return null;
    return ModuloAbierto.tipoDeContenidoDe(_modulos.ponerEnMemoria(id, bytes));
  }

  /// Descargar un modulo y guardarlo.
  ///
  /// ESTO YA ES EL CODIGO DE VERDAD, no un boton de mentira. Y el orden es el que
  /// esta escrito en [AlmacenamientoDeModulos], y por eso no se puede cambiar:
  ///
  ///   1. Descargar por rango, comprobando el sha256 mientras llegan los bytes.
  ///   2. Poner los bytes donde SQLite puede verlos. **Sincrono**, y por eso antes
  ///      que el volcado: sin esto no se puede abrir nada.
  ///   3. Volcar al almacenamiento, que si es asincrono y puede fallar.
  ///
  /// Y si (3) falla, no se deshace (2): el modulo se sigue pudiendo leer mientras la
  /// app este abierta. Es la regla de 5.2, y por eso el fallo se ensenar y no se
  /// traga.
  Future<void> _descargar(String id) async {
    final modulo = _catalogo.manifiesto.porId(id);
    if (modulo == null) {
      _biblioteca.anadirAviso('Este modulo ya no esta en el catalogo.');
      return;
    }

    _biblioteca.marcarCargando(true);
    final obtener = ObtenerModulo(http: _http);
    var ultimoTramo = 0;

    try {
      await for (final evento in obtener.obtener(
        modulo,
        hashEsperado: modulo.sha256,
        // En navegador va la URL de Pages; en nativo las dos valen. No se decide
        // leyendo el User-Agent: `kIsWeb` lo sabe el framework, y un User-Agent se
        // puede falsear.
        usarUrlDeNavegador: kIsWeb,
      )) {
        if (!mounted) return;
        if (evento is Progreso) {
          // Solo cada diez por ciento, porque un aviso por cada trozo de 4 MiB seria
          // catorce actualizaciones en un comentario de 57 MiB. Y con la barra se
          // reemplaza en el sitio, sin historial.
          final pct = evento.fraccion;
          if (pct != null) {
            final tramo = (pct * 10).floor();
            if (tramo > ultimoTramo) {
              ultimoTramo = tramo;
              // Y NO ES UN AVISO, ES UN PROGRESO. La distincion no es de estilo:
              // antes cada diez por ciento anadia un aviso, y como nada los quitaba,
              // un comentario de 57 MiB dejaba diez lineas "Bajando CLARKE: N por
              // ciento" para siempre, todas en rojo. Y al terminar seguian ahi,
              // diciendo que se estaba bajando algo que ya estaba bajado.
              //
              // `progresoDeDescarga` reemplaza el anterior del mismo modulo, y el
              // `finally` de abajo lo quita cuando acaba, salga bien o mal.
              _biblioteca.progresoDeDescarga(id, tramo * 10);
            }
          }
        }
        if (evento is Terminada) {
          await _terminarDescarga(id, evento.resultado, modulo.sha256);
          return;
        }
      }
    } finally {
      // Y AQUI SE QUITA, Y NO EN CADA RAMA DEL `switch` QUE HAY DEBAJO. Hay siete
      // finales posibles y con el `finally` es imposible olvidarse en uno: un progreso
      // que se queda puesto despues de que la descarga acabe --bien o mal-- es una
      // linea que miente sobre lo que esta haciendo la app.
      _biblioteca.quitarProgreso(id);
      _biblioteca.marcarCargando(false);
    }
  }

  /// Lo que se hace con el resultado de una descarga.
  Future<void> _terminarDescarga(
    String id,
    ResultadoObtencion resultado,
    String sha256DelCatalogo,
  ) async {
    switch (resultado) {
      case Obtenido(:final bytes):
        // Los bytes bajados se cuentan aqui, en el sitio donde el motor los ha traido.
        // Y no se cuentan en la sonda: lo que hay que medir es lo que cuenta el motor de
        // obtencion, no lo que diga un contador puesto al lado.
        _sonda.anotarDescarga(bytes.length);

        // El paso sincrono: los bytes donde SQLite los ve. Sin esto, el paso
        // siguiente no tiene nada que abrir.
        final ruta = _modulos.ponerEnMemoria(id, bytes);
        final guardado = await _modulos.persistir(id, bytes);

        switch (guardado) {
          case Guardado():
            _biblioteca.actualizarIdsLocales(
              {..._biblioteca.idsLocales, id},
              hashes: {..._biblioteca.hashesLocales, id: sha256DelCatalogo},
            );
            _biblioteca.quitarOrigenNoLegible(id);
            _biblioteca.anadirAviso('$id descargado y guardado.');
          case NoCabe(:final texto):
            // NO CABE NO IMPIDE LEER. Solo se pierde la proxima vez. Y por eso no es
            // un error: una advertencia que salta al descargar es roja, y aqui la
            // descarga ha ido bien.
            _biblioteca.anadirAviso(texto);
          case FalloAlPersistir(:final texto):
            _biblioteca.anadirAviso(texto);
        }

        // Comprobar que se abre de verdad. Es media linea y es la diferencia entre
        // "descargado" y "descargado y sirve": un modulo que no abre no sirve para
        // nada, y sin esta comprobacion el fallo se descubre en el grupo 7, cuando
        // ya hay una pantalla de lectura que ya espera Juan 3:16.
        await _comprobarQueAbre(ruta, id);

      case OrigenNoLegible():
        // Se anota para que la fila lo explique y ofrezca el fichero local, y no un
        // reintentar que se sabe que va a fallar igual.
        _biblioteca.anotarOrigenNoLegible(id);
        _biblioteca.anadirAviso(descripcionDe(resultado), clase: ClaseDeAviso.error);

      // Y ESTOS CINCO SI SON ERRORES: no se ha podido bajar el modulo o no ha quedado
      // entero, y sin el no se puede leer nada.
      case HashIncorrecto():
      case DescargaIncompleta():
      case OrigenCaido():
      case Cancelado():
      case FalloInesperado():
        _biblioteca.anadirAviso(descripcionDe(resultado), clase: ClaseDeAviso.error);

      case HayVersionNueva():
        _biblioteca.anadirAviso(descripcionDe(resultado));
    }
  }

  /// Abrir el modulo y mirar que tiene dentro. Si no abre, se dice.
  ///
  /// Y ESTA FUNCION TENIA EL CRASH DE LA CAPTURA. Medido el 4 de octubre de 2026 con
  /// el CLARKE real, aqui salia:
  ///
  ///     No se ha podido abrir CLARKE: SqliteException(1): while preparing statement,
  ///     no such table: verses
  ///
  /// Porque hacia `SELECT count(*) FROM verses` **de todo lo que se descarga**, y un
  /// comentario no tiene esa tabla: tiene `commentary`. El modulo se descargaba bien, se
  /// guardaba bien, y aqui reventaba -- y como el aviso se guardaba como error rojo,
  /// lo primero que se veia era un error gigante en una pantalla con veinte cajas.
  ///
  /// Y NO SE COMPRUEBA SI HAY TABLA `verses`, SINO QUE DICE EL MODULO QUE ES. Se lee
  /// `info.type` y se pregunta por lo que corresponde: un comentario no tiene
  /// versiculos que contar, y no es un fallo que no los tenga. Ver
  /// `tipo_de_contenido.dart`, donde esta el motivo de fondo.
  Future<void> _comprobarQueAbre(String ruta, String id) async {
    Sqlite? sqlite;
    try {
      sqlite = Sqlite.abrir(ruta);
      final check = sqlite.comprobacionRapida();
      if (check != 'ok') {
        _biblioteca.anadirAviso(
          'El modulo de $id esta danado y no se va a abrir. Se puede borrar y bajar otra vez.',
          clase: ClaseDeAviso.error,
        );
        return;
      }

      final nombre = sqlite.info('name') ?? id;
      final tipo = TipoDeContenido.fromModulo(sqlite.info('type'));

      // Y LO QUE SE DICE DE CADA TIPO ES DISTINTO A PROPOSITO. A un comentario no se le
      // anuncia "0 versiculos": eso suena a que esta vacio o a que la descarga fallo, y
      // las dos cosas son mentira. Se le dice lo que es y que se podra leer cuando haya
      // pantalla para el.
      if (tipo == TipoDeContenido.comentario) {
        // Y UN COMENTARIO YA SE PUEDE LEER, y el aviso lo dice con su numero de notas y
        // no con un "todavia no". Antes decia "falta la pantalla de comentarios", que
        // era verdad el 4 de octubre de 2026 y hoy es mentira.
        // Y EL NOMBRE DE LA TABLA SALE DEL TIPO, IGUAL QUE EN EL REPOSITORIO. La
        // primera version de esto escribia `FROM commentary` a mano, que es
        // exactamente lo que la prueba `el nombre de la tabla sale del tipo y no de las
        // consultas` prohibe en el repositorio: el dia que haya un segundo tipo de
        // comentario, esta linea daria `no such table: commentary` en el sitio mas
        // visible, que es el aviso de descarga.
        final tabla = tipo.tablaDeContenido!;
        final notas = sqlite.valor('SELECT count(*) FROM $tabla') as int?;
        final passages = sqlite.valor(
          'SELECT count(*) FROM (SELECT DISTINCT book, chapter, verse FROM $tabla)',
        ) as int?;
        _biblioteca.anadirAviso(
          '$nombre: $notas notas sobre $passages versiculos, listo para leer.',
        );
        return;
      }
      if (tipo == TipoDeContenido.desconocido) {
        _biblioteca.anadirAviso(
          '$nombre declara un tipo de contenido que la app no conoce, asi que no se '
          'puede abrir. Se ha descargado bien.',
          clase: ClaseDeAviso.error,
        );
        return;
      }

      final n = sqlite.valor(
        'SELECT count(*) FROM '
        '(SELECT DISTINCT book, chapter, verse FROM ${tipo.tablaDeContenido!})',
      );
      _biblioteca.anadirAviso('$nombre: $n versiculos, listo para leer.');
    } catch (e) {
      _biblioteca.anadirAviso('No se ha podido abrir $id: $e', clase: ClaseDeAviso.error);
    } finally {
      sqlite?.cerrar();
    }
  }

  Future<void> _ficheroLocal(String id) async {
    _biblioteca.anadirAviso(
      'Abrir un fichero del dispositivo se enchufa aqui; el motor ya esta y '
      'probado, y lo que falta es el selector en esta pantalla.',
    );
  }

  Future<List<int>?> _bytesDe(String id) async {
    final g = await _modulos.rutaDe(id);
    if (g == null) return null;
    final bytes = await _leerDeDispositivo(g.ruta);
    return bytes;
  }

  Future<List<int>?> _leerDeDispositivo(String ruta) async {
    try {
      return await bytesDe(ruta);
    } catch (_) {
      return null;
    }
  }
}
