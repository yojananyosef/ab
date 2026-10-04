// La sonda: que la aplicacion escriba en el DOM lo que ha hecho, para poder leerlo.
//
// ============================================================================
// POR QUE HACE FALTA, Y POR QUE ESTA DENTRO DE LA APLICACION
// ============================================================================
//
// Flutter web pinta en un `canvas`. El DOM no tiene texto: tiene una foto. Por eso
// `--dump-dom` de un navegador **no** puede comprobar si Juan 3:16 sale pintado --solo
// ve los `<canvas>`--, y por eso una comprobacion en navegador necesita darle a la
// aplicacion una manera de decir que ha visto.
//
// Y LA MANERA ES QUE LA APLICACION LO ESCRIBA. No un piloto de pruebas aparte que
// conduzca el navegador, sino la misma aplicacion, con el mismo motor, el mismo SQLite
// en WebAssembly y el mismo almacenamiento, escribiendo en un `<pre>` lo que ha leido.
//
// POR QUE NO ES UN MENTIRO. Lo que se activa con `--dart-define` es **solo** la
// escritura del resultado. El arranque, la descarga, la comprobacion del sha256, la
// apertura del `.amod`, la consulta de Juan 3:16 y la escritura de la ruta son
// exactamente los mismos codigos: si el texto no saliera, la sonda no tendria nada que
// escribir. Un piloto externo que simulase la descarga no comprobaria el motor SQLite,
// que es justo lo que hay que comprobar.
//
// ============================================================================
// SOLO SE ACTIVA SI SE PIDE, Y COMO SE COMPRUEBA QUE NO ESTA
// ============================================================================
//
// Con `String.fromEnvironment`, que es una constante de compilacion: sin el
// `--dart-define` el codigo de la sonda no existe en el paquete. Y [sondear] vuelve de
// inmediato si no se ha pedido.
//
// Y EN UNA PRUEBA NO HACE NADA. Lo unico que se puede comprobar en la maquina de Dart
// es precisamente eso --que no haga nada--, y es lo que comprueba `sonda_test.dart`. Si
// hiciera algo, contaminaria el resto de las pruebas.
//
// ============================================================================
// LO QUE ESCRIBE, Y POR QUE CADA COSA
// ============================================================================
//
//   - `ruta`: la direccion de la que arranco. Sin esto, una sonda que pasa puede haber
//     arrancado en la biblioteca y estar comprobando otra cosa.
//   - `modulo`, `pasaje`, `versiculos`, `texto`: que ha abierto, que ha leido y **con
//     que texto**. El texto entero es lo que distingue a una app que lee de verdad de
//     una que pinta un ejemplo.
//   - `origen`: de donde salio el manifiesto, y si se esta usando una copia guardada.
//   - `catalogo`: los modulos que hay y su tamano en bytes, que es el dato de la 8.4.
//   - `bytesDescargados`: los bytes bajados **en esta ejecucion**. Es lo que hace
//     posible la 8.3: dos ejecuciones con el mismo perfil, la segunda con 0.
//   - `historial`: `history.length` antes y despues de cambiar de capitulo y de
//     cambiar de version. Es la comprobacion de la 7.5 en el navegador, y no se puede
//     hacer en ningun otro sitio: en Dart no hay historial.
//   - `resultado`: `ok`, o el motivo por el que no.
//
// Y `resultado` se escribe **siempre**, tambien cuando falla. Una sonda que solo
// escribe cuando todo va bien es una sonda que en un fallo no dice nada, y es justo
// cuando hace falta.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/repositories/catalogo_repository.dart';
import '../domain/models/referencia.dart';
import '../ui/core/rutas.dart';
import '../ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import '../ui/features/lector/view_models/lector_view_model.dart';
import 'navegador.dart';
import 'sonda_nativa.dart'
    if (dart.library.js_interop) 'sonda_web.dart' as plataforma;

/// El valor de `--dart-define=AB_SONDA`, o cadena vacia si no se paso.
///
/// Va **antes** de [kSondaActiva] en el fichero, y no por gusto: `isNotEmpty` sobre una
/// constante de compilacion no se puede hacer en una constante, asi que el orden de las
/// declarations es lo que hace que esto compile. Con el orden contrario, el error es
/// "property access on a String in a constant expression", que no dice nada de que lo
/// que hay que mover es una linea.
const String kPedidoDeSonda = String.fromEnvironment('AB_SONDA', defaultValue: '');

/// Si esta compilada para hacer la comprobacion en navegador.
///
/// Sin `--dart-define=AB_SONDA=...` el codigo de la sonda no existe en el paquete.
const bool kSondaActiva = kPedidoDeSonda.length > 0;

/// La ruta desde la que deberia arrancar esta ejecucion.
Ruta get rutaDeLaSonda => Rutas.leer(kPedidoDeSonda);

/// A donde se manda el resultado para que un script lo pueda leer.
///
/// Vacio si no se paso `--dart-define=AB_COLECTOR=...`. Y el `id` del elemento del DOM
/// va aparte porque los dos caminos existen siempre en el mismo sitio y fallan por
/// motivos distintos: el DOM siempre se puede escribir y nunca se puede leer de fuera;
/// el colector se puede leer y puede no estar.
const String kUrlDelColector =
    String.fromEnvironment('AB_COLECTOR', defaultValue: '');

/// El `id` del elemento donde se escribe el resultado.
///
/// Un `<pre>` con id propio, y no en el `body` suelto: el `body` de una aplicacion
/// Flutter esta lleno de etiquetas del motor, y buscar "ok" ahi encontraria cosas de
/// antes. Un elemento con id se busca entero y se lee entero.
const String idDelMarcador = 'ab-sonda';

/// La sonda: lo que lleva cuenta y lo que escribe.
///
/// Una clase y no un conjunto de funciones sueltas porque tiene **estado**: los bytes
/// bajados y la longitud del historial se van cogiendo en momentos distintos y hay que
/// compararlos. Y una funcion suelta con estado dentro seria una variable global.
class Sonda {
  Sonda();

  int _bytesDescargados = 0;

  /// Los bytes bajados en esta ejecucion.
  ///
  /// Lo lleva [anotarDescarga] el motor de obtencion, en el mismo sitio donde ya se
  /// cuenta el progreso. No se cuenta aqui: si lo contase la sonda, seria la sonda la
  /// que dice que se ha descargado, y lo que hay que comprobar es lo que cuenta el
  /// motor de verdad.
  int get bytesDescargados => _bytesDescargados;

  void anotarDescarga(int bytes) => _bytesDescargados += bytes;

  /// Lo ultimo escrito, o null si no se ha escrito nada.
  ///
  /// Es lo unico que se puede mirar desde una prueba, porque en la maquina de Dart no
  /// hay DOM. Y mirar esto es justo la comprobacion que importa: que sin el
  /// `--dart-define` no se escriba nada.
  String? get ultimoTextoEscrito => _ultimoTextoEscrito;

  static String? _ultimoTextoEscrito;

  /// Espera a que [cuando] devuelva algo y lo escribe.
  ///
  /// [cuando] se reevalua cada 200 ms y devuelve null mientras no haya nada que mirar.
  /// En cuanto devuelve algo, se escribe y se deja de repetir.
  ///
  /// Y DEVUELVE NULL DE VERDAD, no un mapa vacio: "todavia no" y "he visto que no hay
  /// nada" son cosas distintas, y con un mapa vacio la comprobacion escribiria un
  /// resultado sin haber comprobado nada --que es exactamente el fallo que esta sonda
  /// tiene que evitar en la aplicacion--.
  ///
  /// Y SI NUNCA DEVUELVE NADA, se escribe el motivo al cabo de [esperaMaxima]. Una
  /// comprobacion que se queda esperando para siempre en un fallo es indistinguible de
  /// una que se cuelga.
  Future<void> esperarYEscribir({
    required Map<String, Object?>? Function() cuando,
    required String motivoDeEspera,
    // Y EL PLAZO ES **MENOR** QUE EL RELOJ VIRTUAL DEL NAVEGADOR, y no mayor.
    //
    // Con 300 s de espera y 240 s de reloj virtual --que es lo que usa
    // `scripts/comprobar-en-navegador.sh`-- el navegador se va antes de que la espera
    // llegue a acabarse, y la sonda no escribe **nada**: ni un resultado ni un motivo ni
    // un error. Se queda callada, que es lo unico que no puede hacer una sonda.
    //
    // Con 150 s de espera contra 240 s de reloj, siempre hay margen para escribir el
    // motivo. Y 150 s de reloj virtual son segundos de reloj de pared, porque el
    // virtual avanza mientras no haya peticiones de red: la espera solo consume tiempo
    // real cuando esta esperando algo de verdad.
    Duration esperaMaxima = const Duration(seconds: 150),
  }) async {
    if (!kSondaActiva) return;

    // Y CON BANDERA, NO COMPARANDO [campos] CON NULL AL SALIR. La version anterior
    // comparaba, y el analizador de Dart --que no razona sobre `DateTime.now().isBefore`--
    // decia que la comparacion era siempre falsa y se quejaba de codigo muerto. El bucle
    // tambien sale por el limite, y ahi [campos] sigue siendo null; con la bandera no
    // hay nada que razonar.
    final limite = DateTime.now().add(esperaMaxima);
    Map<String, Object?>? campos;
    var agotado = true;
    Object? fallo;

    // Y UN `try` AL REDEDOR DE LA ESPERA, Y ESTO NO ES DEFENSIVA SIN MOTIVO.
    //
    // MEDIDO EL 4 DE OCTUBRE DE 2026: `cuando` empezo a tirar --por un campo nuevo que
    // todavia no estaba bien puesto-- y la excepcion salio de este metodo, del
    // `addPostFrameCallback` y de donde fuera, y **nadie la vio**. La sonda seguia
    // esperando, el navegador se quedaba hasta que lo mataban, y lo unico que habia
    // escrito era el "paso 1" de antes. Cuatro minutos de espera y ni un error.
    //
    // Un error que no se escribe es indistinguible de una espera que no termina, y para
    // esto --que existe para decir que ha pasado-- es el peor fallo posible.
    try {
      while (DateTime.now().isBefore(limite)) {
        campos = cuando();
        if (campos != null) {
          agotado = false;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (e, traza) {
      fallo = 'la sonda no ha podido mirar la aplicacion: $e\n$traza';
    }

    escribir(<String, Object?>{
      if (fallo != null) ...<String, Object?>{
        'resultado': 'excepcion',
        'motivo': fallo,
      } else if (agotado) ...<String, Object?>{
        'resultado': 'tiempo agotado',
        'motivo': motivoDeEspera,
      },
      ...?campos,
    });
  }

    /// Mide si cambiar de capitulo entra en el historial del navegador.
  ///
  /// ESTA ES LA COMPROBACION DE LA TAREA 7.5 EN EL NAVEGADOR, y no se puede hacer en
  /// ningun otro sitio: en Dart no hay `history`.
  ///
  /// Se mide `window.history.length` antes y despues de un `irA` --que es `navigate`,
  /// o sea `pushState`-- y de un `ajustarA` --que es `neglect`, o sea `replaceState`--.
  /// Y lo que se mira no es que "haya cambiado la barra", que siempre cambia, sino que
  /// **el historial crezca** en el primer caso y **no** en el segundo.
  ///
  /// Y EL AJUSTE QUE SE MIDE ES EL MISMO QUE SE USA DE VERDAD. No un ajuste inventado
  /// para la comprobacion: `ajustarA` con la ruta de ahora mismo, que es exactamente lo
  /// que hace un cambio de ajuste que no cambia de pagina --aumentar la letra, cambiar
  /// de traduccion--. Y se mide con el texto abierto y leyendo, que es cuando importa.
  ///
  /// Y SI LOS DOS NUMEROS SALEN IGUAL, NO SE DEDUCE NADA Y SE DICE. Puede que `pushState`
  /// no haya añadido entrada --el navegador decisionando lo suyo--, o que el perfil este
  /// en un modo raro. Se escribe lo medido y que el script decida; desde aqui no se
  /// puede distinguir entre un fallo de la aplicacion y una rareza del navegador, y una
  /// comprobacion que dice "ha ido bien" sin poder saberlo es peor que no comprobar.
  Future<void> medirElHistorial(NavegadorAb n) async {
    if (!kSondaActiva) return;
    _historial = await n.medirElHistorial();
  }

  /// Lo medido, si se ha medido.
  Map<String, Object?>? get historial => _historial;

  Map<String, Object?>? _historial;

  /// Escribe el resultado.
  ///
  /// Y SOLO EN WEB. En cualquier otra plataforma no hay DOM, y escribir ahi no tendria
  /// sentido: no hay nadie leyendo. Y `print` en un movil va al registro del sistema,
  /// que nadie mira.
  void escribir(Map<String, Object?> campos) {
    if (!kSondaActiva || !kIsWeb) return;
    escribirConEsteCodigo(campos);
  }

  /// El mismo [escribir], **sin** las dos guardas de plataforma.
  ///
  /// Y ES UNA FUNCION DISTINTA Y NO UN PARAMETRO PORQUE LAS DOS GUARDAS SON EL
  /// PROBLEMA. `escribir` vuelve sin hacer nada si la sonda no esta activa o si no es
  /// web, asi que en una prueba --que no es web-- no escribiria **nada** y pasaria
  /// siempre. Y una prueba que pasa siempre es una prueba que no comprueba nada, que es
  /// justo el fallo que este fichero existe para no repetir.
  ///
  /// Y LO UNICO QUE HACE ES LO MISMO, con el `try` dentro. La conversion del JSON y
  /// el guardado del texto son los dos momentos en los que esto puede fallar, y estan
  /// aqui para que se puedan probar sin un navegador.
  @visibleForTesting
  void escribirConEsteCodigo(Map<String, Object?> campos) {
    // Y EL `JsonEncoder` ESTA DENTRO DE UN `try`, y por que importa mas de lo que
    // parece.
    //
    // MEDIDO EL 4 DE OCTUBRE DE 2026: la sonda empezo a mandar `List<Aviso>` en vez de
    // `List<String>`, y `convert` **lanza** con un objeto dentro en vez de escribirlo.
    // La excepcion salio de aqui, se subio por `escribir`, y --porque quien llama esta
    // dentro de un `addPostFrameCallback` y no hay nadie que la coja-- se perdio
    // **enteramente**.
    //
    // El resultado fue el peor posible para una sonda: la app **funcionaba**, Juan 3:16
    // se leia en pantalla, y la sonda no escribia nada. Desde fuera, "la comprobacion no
    // ha dicho nada" y "la comprobacion no ha comprobado nada" son lo mismo.
    //
    // Y NO SE ARREGLA INTENTANDO QUE EL JSON SIEMPRE SALGA. Se arregla de dos maneras a
    // la vez: **no metiendo en el informe nada que `jsonEncode` no sepa escribir** --que
    // es una regla, y la respeta el `map` del informe-- y **sin tragarse el fallo** si
    // aun asi pasa, que es lo que hace este `try`.
    late final String texto;
    try {
      texto = const JsonEncoder.withIndent('  ').convert(campos);
    } catch (e) {
      texto = const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'resultado': 'la sonda no ha podido escribir su informe',
        'motivo': 'un valor del informe no se sabe convertir a JSON: $e',
      });
    }
    _ultimoTextoEscrito = texto;

    // Los dos caminos, y en este orden. El del DOM primero porque es el que no puede
    // fallar, y el del colector despues porque puede. Ver `sonda_web.dart`, que explica
    // por que hace falta el segundo.
    plataforma.escribirEnElMarcador(idDelMarcador, texto);
    if (kUrlDelColector.isNotEmpty) {
      plataforma.notificarPorHttp(kUrlDelColector, texto);
    }
  }
}

/// Cuantos versiculos tiene el capitulo pedido, leidos del modulo.
///
/// Y SE LEEN, NO SE CALCULAN. La tarea 7.1 --que Juan 3 salga con 36-- se puede
/// comprobar en Dart con el `.amod` real, y esta es la misma comprobacion en el
/// navegador: la consulta la hace el motor de SQLite compilado a WebAssembly, sobre los
/// 22 MiB que se han bajado. Si aqui salieran 51, significaria que el `.amod` del
/// navegador no es el de la maquina, y eso es justo lo que hay que descartar.
///
/// Y CUENTA LO QUE HAYA, QUE EN UN COMENTARIO SON LAS NOTAS DEL CAPITULO Y EN UNA BIBLIA
/// SUS VERSICULOS. La cuenta sale del mismo modulo que las trae, asi que no hay forma de
/// que uno y otro se separen.
int _cuentaDeCapitulo(LectorViewModel lector, Referencia esperado) {
  final modulo = lector.modulo;
  if (modulo == null) return -1;
  final p = modulo.leer(Referencia(esperado.libro, esperado.capitulo));
  return p.traeNotas ? p.notas.length : p.versiculos.length;
}

/// Lo que la sonda mira en la aplicacion, en una sola pasada.
///
/// Y VA EN UN FICHERO APARTE DE LA CLASE PORQUE NO ES ESTADO. La clase [Sonda] guarda
/// los bytes --que se van contando mientras baja el modulo-- y lo que se escribe, que
/// se lee para poder comprobar en una prueba. Todo lo demas --la ruta, el pasaje, el
/// catalogo, el historial-- se calcula aqui, en el momento, y no se guarda: entre que se
/// calcula y se escribe no pasa nada, y un valor guardado a la espera de que alguien se
/// acuerde de escribirlo es un valor que se queda viejo solo.
///
/// Y DEVUELVE NULL MIENTRAS NO HAYA NADA QUE MIRAR, que es lo que permite
/// [Sonda.esperarYEscribir] no escribir un resultado sin haber comprobado nada.
Map<String, Object?>? mirarLaAplicacion({
  required Sonda sonda,
  required NavegadorAb navegador,
  required CatalogoRepository catalogo,
  required BibliotecaViewModel biblioteca,
  required LectorViewModel lector,
  required Referencia esperado,
  required EstadoLectura estado,
}) {
  final pasaje = lector.pasaje;
  if (pasaje == null || pasaje.vacio) return null;
  if (lector.estado != EstadoLecturaTexto.leyendo) return null;

  // Y SE COMPRUEBA QUE SEA **EL PEDIDO**, Y NO SOLO QUE HAYA ALGO. Una sonda que leyera
  // cualquier pasaje y diera el texto de ese no comprobaria nada: se pide Juan 3:16, y lo
  // que se escribe tiene que ser el 16.
  //
  // Y PARA CADA TIPO DE CONTENIDO, LO QUE TOCA. Medido el 4 de octubre de 2026: la sonda
  // exigia `pasaje.versiculo(n)`, que en un comentario es siempre null porque sus notas
  // no son versiculos. El comentario se abria bien en el navegador --57.536.512 bytes,
  // `estadoLector: leyendo`-- y la sonda se quedaba esperando un versiculo que no existe,
  // hasta que expiraba y decia "no se ha podido leer Juan 3:16". Era un fallo de la
  // comprobacion, no de la app, y desde fuera no se distinguen.
  final esComentario = pasaje.traeNotas;
  final sought = esperado.versiculo ?? 1;
  if (esComentario) {
    if (pasaje.notasDe(sought).isEmpty) return null;
  } else if (pasaje.versiculo(sought) == null) {
    return null;
  }

  return <String, Object?>{
    'resultado': 'ok',
    'ruta': Uri.base.toString(),
    'rutaInterna': navegador.ruta.toString(),
    'modulo': lector.idDelModulo,
    'pasaje': lector.leyendo!.paraUrl,
    'pasajeEsperado': esperado.paraUrl,
    'titulo': pasaje.titulo,
    // Y `versiculosEnElCapitulo` es lo que trae el pasaje pedido, que si es un
    // versiculo suelto es **1**. Y eso no dice que Juan 3 tenga un versiculo: dice que
    // se ha pedido uno. Por eso tambien se pide el capitulo entero --ver
    // `capituloEntero`-- y se cuentan sus versiculos ahi, que es lo que la tarea 7.1
    // pide comprobar.
    'versiculosEnElPasaje': pasaje.total,
    'tipoDeContenido': lector.modulo?.tipo.name,
    'notas': pasaje.notas.length,
    'esComentario': esComentario,
    'capituloEntero': <String, Object?>{
      'libro': esperado.libro,
      'capitulo': esperado.capitulo,
      'versiculos': _cuentaDeCapitulo(lector, esperado),
    },
    'versiculo': esperado.versiculo,
    // Y EL TEXTO ES EL QUE TOQUE: el del versiculo en una Biblia, y el de la **primera**
    // nota en un comentario. Devolver `null` para un comentario haria que el informe no
    // dijera nada de las 2.709 caracteres que acaba de leer, que es justo lo que hay que
    // comprobar.
    'texto': esComentario
        ? (pasaje.notasDe(sought).firstOrNull?.texto ?? '')
        : (pasaje.versiculo(sought)?.texto ?? ''),
    'bytesDescargados': sonda.bytesDescargados,
    'terminos': <String, Object?>{
      'nombre': lector.terminos?.nombre,
      'licencia': lector.terminos?.licencia,
      'atribucion': lector.terminos?.atribucion,
      'copyright': lector.terminos?.copyright,
      'versificacion': lector.terminos?.versificacion,
      'defectos': lector.terminos?.numeroDeDefectos,
      'discrepancia': lector.discrepancia?.delManifiesto,
    },
    'catalogo': <String, Object?>{
      'etiqueta': catalogo.manifiesto.etiqueta,
      'origen': catalogo.origen,
      // Y DE DONDE SALIO EL MANIFIESTO, que no es lo mismo que de donde se busca.
      // `origen` es la direccion, y aqui hay una copia guardada con la de ayer. Lo que
      // se comprueba en la tarea 8.4 --que el manifiesto es el de hoy-- se mira aqui y
      // no contando los avisos: los avisos incluyen los de la descarga --"Bajando X: 50
      // por ciento"-, y con avisos siempre hay alguno, se mire lo que se mire.
      //
      // Y ADEMAS, CONTAR LOS ERRORES ES MAS BARATO QUE MIRAR LOS AVISOS, y sale de aqui
      // gratis porque los avisos ya llevan su clase.
      'estado': estado.name,
      'modulos': <Map<String, Object?>>[
        for (final m in catalogo.manifiesto.modulos)
          <String, Object?>{
            'id': m.id,
            'nombre': m.nombre,
            'tipo': m.tipo.name,
            'licencia': m.licencia,
            'bytes': m.tamanoBytes,
          },
      ],
      // Y LOS AVISOS SE CONVIERTEN A TEXTO AQUI, y no se mandan como son.
      //
      // MEDIDO EL 4 DE OCTUBRE DE 2026: la sonda paso a mandar `List<Aviso>` --que es lo
      // correcto, porque los avisos tienen tipo-- y `jsonEncode` **lanza** con un objeto
      // dentro en vez de escribirlo. Lo que pasó entonces es lo peor que puede pasar
      // con una sonda: la excepcion salio de `escribir`, se trago en el
      // `addPostFrameCallback`, y la sonda se quedo **callada**. De la pantalla se veia
      // Juan 3:16 y todo funcionaba; lo unico que faltaba era el informe.
      //
      // Y NO SE ARREGLA CON UN `try` ALREDEDOR DEL `jsonEncode`, porque eso devolveria
      // un informe vacio y seguiria sin decir nada. Se arregla no metiendo en el informe
      // nada que `jsonEncode` no sepa escribir.
      'avisos': <String>[
        for (final a in biblioteca.avisos)
          '${a.esError ? 'ERROR' : 'info'}: ${a.texto}',
      ],
      'idsLocales': biblioteca.idsLocales.toList()..sort(),
    },
    if (sonda.historial != null) 'historial': sonda.historial,
  };
}

