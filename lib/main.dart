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

import 'data/repositories/catalogo_repository.dart';
import 'data/services/almacenamiento.dart';
import 'data/services/almacenamiento_de_modulos.dart';
import 'data/services/http_service.dart';
import 'data/services/sqlite_service.dart';
import 'domain/use_cases/obtener_modulo.dart';
import 'domain/use_cases/resultado_obtencion.dart';
import 'ui/core/tema.dart';
import 'ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'ui/features/biblioteca/views/biblioteca_view.dart';

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

  @override
  void initState() {
    super.initState();

    _http = HttpService();
    _catalogo = CatalogoRepository(http: _http, almacenamiento: const Preferencias());
    _modulos = crearAlmacenamientoDeModulos();
    _biblioteca = BibliotecaViewModel();

    // La primera lectura arranca aqui y no en el `build`, para que no se repita en
    // cada cambio de estado. `addPostFrameCallback` porque `notifyListeners` dentro
    // de `initState` avisa a una pantalla que todavia no esta montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _modulos.dispose();
    _catalogo.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    _biblioteca.marcarCargando(true);

    final resultado = await _catalogo.leer();
    if (!mounted) return;

    // Los ids que ya hay en el dispositivo. Se piden aunque la lectura del
    // catalogo haya fallado, porque puede haber modulos de una sesion anterior y
    // son justo los que hay que ensenar aunque no se sepa que mas hay.
    final ids = await _idsLocales();
    final hashes = await _hashesLocales();

    _biblioteca.aplicarResultado(resultado, idsLocales: ids, hashesLocales: hashes);
    if (_avisoDeArranque != null) _biblioteca.anadirAviso(_avisoDeArranque!);
    _biblioteca.marcarCargando(false);
  }

  Future<Set<String>> _idsLocales() async {
    try {
      return (await _modulos.ids()).toSet();
    } catch (_) {
      // Si el almacenamiento no responde, se sigue con una biblioteca vacia de "lo
      // que tengo". No se propaga: perder la lista de lo descargado es una molestia,
      // no un fallo de la app.
      return <String>{};
    }
  }

  /// Los hashes de lo que hay en el dispositivo, para poder distinguir "descargado"
  /// de "hay version nueva".
  ///
  /// Viene de un indice de 64 bytes por modulo, no de leer los 22 MiB: hashear 79 MiB
  /// al arrancar para pintar una lista seria la razon por la que alguien cierra la
  /// app en un movil viejo.
  Future<Map<String, String>> _hashesLocales() async {
    try {
      return await _modulos.idsConHash();
    } catch (_) {
      return const <String, String>{};
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AB',
    debugShowCheckedModeBanner: false,
    theme: temaDeAb(),
    home: BibliotecaView(
      viewModel: _biblioteca,
      alPulsarLeer: _leer,
      alPulsarDescargar: _descargar,
      alPulsarFicheroLocal: _ficheroLocal,
      alReintentar: _cargar,
    ),
  );

  // --- acciones ---
  //
  // Las tres van aqui y no en la vista porque necesitan cosas que la vista no tiene:
  // el motor de obtencion, el almacenamiento y el selector de archivos.

  /// Abrir un modulo.
  ///
  /// Todavia no hay lector: eso es el grupo 7. Lo que se hace ahora es **comprobar
  /// que se puede abrir**, que es la mitad del trabajo del grupo 2 y la que
  /// detecta el fallo antes de que exista una pantalla que lo muestre.
  Future<void> _leer(String id) async {
    // El lector de verdad es el grupo 7. Lo que hay aqui es comprobar que el
    // modulo se abre y ensena cuanto tiene, que es lo que hay que comprobar antes de
    // escribir una pantalla que lo muestre.
    final bytes = await _bytesDe(id);
    if (bytes == null) {
      _biblioteca.anadirAviso('Este modulo todavia no se ha descargado.');
      return;
    }
    final ruta = _modulos.ponerEnMemoria(id, bytes);
    try {
      final sqlite = Sqlite.abrir(ruta);
      try {
        final cuenta = sqlite.valor('SELECT count(*) FROM verses');
        final nombre = sqlite.info('name');
        _biblioteca.anadirAviso('$nombre esta listo: $cuenta versiculos.');
      } finally {
        sqlite.cerrar();
      }
    } catch (e) {
      _biblioteca.anadirAviso('No se ha podido abrir el modulo: $e');
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
