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
import 'data/repositories/catalogo_repository.dart';
import 'data/services/almacenamiento.dart';
import 'app/arranque.dart';
import 'data/services/almacenamiento_de_modulos.dart';
import 'data/services/http_service.dart';
import 'data/repositories/modulo_repository.dart';
import 'data/services/sqlite_service.dart';
import 'domain/models/referencia.dart';
import 'domain/use_cases/obtener_modulo.dart';
import 'domain/use_cases/resultado_obtencion.dart';
import 'ui/core/rutas.dart';
import 'ui/core/tema.dart';
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

  @override
  void initState() {
    super.initState();

    _http = HttpService();
    _catalogo = CatalogoRepository(http: _http, almacenamiento: const Preferencias());
    _modulos = crearAlmacenamientoDeModulos();
    _biblioteca = BibliotecaViewModel();
    _lector = LectorViewModel();

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
      initialRouteInformation: RouteInformation(uri: Uri.parse(Uri.base.toString())),
    );

    _navegador = NavegadorAb(
      biblioteca: _biblioteca,
      lector: _lector,
      proveedor: _proveedorDeRutas,
      abrir: _abrirModulo,
      descargar: (id) => _descargar(id),
      abrirFicheroLocal: (id) => _ficheroLocal(id),
      reintentarCatalogo: _cargar,
    );

    // La primera lectura arranca aqui y no en el `build`, para que no se repita en
    // cada cambio de estado. `addPostFrameCallback` porque `notifyListeners` dentro
    // de `initState` avisa a una pantalla que todavia no esta montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _navegador.dispose();
    _modulos.dispose();
    _catalogo.dispose();
    super.dispose();
  }

  /// Lee el catalogo y lo que hay en el dispositivo.
  ///
  /// Delega en [arrancarBiblioteca], y no por gusto: la garantia de que el
  /// catalogo se ve aunque el almacenamiento no conteste vive ahi, y en un metodo
  /// privado de un `State` no se puede comprobar con una prueba.
  Future<void> _cargar() async {
    if (!mounted) return;
    await arrancarBiblioteca(
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
        // El progreso va como un aviso, y no en una barra: la barra por modulo vive
        // en la fila y es del grupo 7. Y **solo cada diez por ciento**, porque un
        // aviso por cada trozo de 4 MiB llenaria la pantalla en un comentario de
        // 57 MiB: catorce avisos apilados que hay que subir con el dedo.
        final pct = evento.fraccion;
        if (pct != null) {
          final tramo = (pct * 10).floor();
          if (tramo > ultimoTramo) {
            ultimoTramo = tramo;
            _biblioteca.anadirAviso('Bajando $id: ${tramo * 10} por ciento');
          }
        }
      }
      if (evento is Terminada) {
        await _terminarDescarga(id, evento.resultado, modulo.sha256);
        if (!mounted) return;
        _biblioteca.marcarCargando(false);
        return;
      }
    }
    _biblioteca.marcarCargando(false);
  }

  /// Lo que se hace con el resultado de una descarga.
  Future<void> _terminarDescarga(
    String id,
    ResultadoObtencion resultado,
    String sha256DelCatalogo,
  ) async {
    switch (resultado) {
      case Obtenido(:final bytes):
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
            // NO CABE NO IMPIDE LEER. Solo se pierde la proxima vez.
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
        _biblioteca.anadirAviso(descripcionDe(resultado));

      case HashIncorrecto():
      case DescargaIncompleta():
      case OrigenCaido():
      case Cancelado():
      case FalloInesperado():
      case HayVersionNueva():
        _biblioteca.anadirAviso(descripcionDe(resultado));
    }
  }

  /// Abrir el modulo y mirar que tiene dentro. Si no abre, se dice.
  Future<void> _comprobarQueAbre(String ruta, String id) async {
    try {
      final sqlite = Sqlite.abrir(ruta);
      try {
        if (sqlite.comprobacionRapida() != 'ok') {
          _biblioteca.anadirAviso(
            'El modulo de $id esta danado y no se va a abrir. Se puede borrar y bajar otra vez.',
          );
          return;
        }
        final n = sqlite.valor('SELECT count(*) FROM verses');
        final nombre = sqlite.info('name') ?? id;
        _biblioteca.anadirAviso('$nombre: $n versiculos, listo para leer.');
      } finally {
        sqlite.cerrar();
      }
    } catch (e) {
      _biblioteca.anadirAviso('No se ha podido abrir $id: $e');
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
