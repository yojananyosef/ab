// Los ajustes de lectura que son de la **ventana**, no de un texto.
//
// ============================================================================
// POR QUE ESTO SALIO DE `LectorViewModel`, Y QUE FALLO ARREGLA
// ============================================================================
//
// Los ajustes --la letra, el alto de linea, el espaciado, el tema, la atenuacion y si las
// palabras de Jesus van en rojo-- estaban **dentro** de `LectorViewModel`, que es el estado
// de leer **un** modulo. Con un solo texto abierto no se notaba: habia un `LectorViewModel`
// y sus ajustes eran los de la ventana.
//
// En cuanto hay dos paneles --que es lo que hacen las pestanas-- hay **dos** `LectorViewModel`,
// uno por panel. Y entonces cada uno tiene sus propios ajustes: se cambia la letra en el
// panel de la izquierda, se escribe en el almacenamiento, y el panel de la derecha **no se
// entera** hasta que se vuelve a abrir. Dos textos con dos letras distintas, lado a lado.
//
// Y ESO ES UN FALLO QUE NO SE VE EN UNA PRUEBA DE MODELO, porque cada `LectorViewModel`
// por separado se comporta bien: `cambiarPreferencia` cambia, `cargarPreferencias` lee, y
// todas las pruebas que hay sobre ellos siguen dando verde con el bug puesto. Lo que no se
// puede probar en solitario es que **los dos** esten de acuerdo.
//
// ASI QUE ESTO ES UN `ChangeNotifier` PROPIO Y COMPARTIDO, y `LectorViewModel` lo recibe y
// **delega**. La API publica de `LectorViewModel` no cambia ni un getter, de modo que las
// pruebas que hay siguen significando lo que significaban; lo que cambia es de donde sale
// el valor.
//
// Y SE LEE UNA VEZ, con el mismo plazo de cinco segundos y la misma excepcion atrapada que
// antes. Ver `lector_view_model.dart`, que tiene escrito por que un `await` sin plazo
// cuelga la pantalla entera, y por que aqui, a diferencia del catalogo, el silencio si es
// lo correcto.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ab/data/services/almacenamiento.dart';
import 'package:ab/domain/models/preferencia_de_lectura.dart';

/// El plazo por defecto para leer una preferencia. Cinco segundos.
///
/// Y CINCO Y NO UN SEGUNDO, porque el caso medido --el almacenamiento del navegador que
/// nunca contesta-- no es lento: no contesta. Un plazo corto no lo arregla, solo haria que
/// una preferencia se perdiera antes. Y cinco segundos es invisible para quien esta
/// esperando, porque mientras tanto se esta leyendo el texto.
const Duration plazoDePreferenciaPorDefecto = Duration(seconds: 5);

/// Los ajustes de lectura de la ventana: los mismos para todos los paneles.
///
/// Y ES UN `ChangeNotifier` Y NO UN `ValueNotifier<PreferenciaDeLectura>`, porque son dos
/// cosas las que se guardan --los ajustes y el color-- y un `ValueNotifier` de uno solo
/// obligaria a tener dos fuentes de verdad para "lo que ha elegido quien lee".
class PreferenciasDeLectura extends ChangeNotifier {
  // Y EL `ignore` ESTA ADENTRO DEL LISTADO DE PARAMETROS, EN LA LINEA ANTERIOR AL AVISO,
  // Y NO ARRIBA DEL CONSTRUCTOR: Dart anade el aviso a la linea de la lista de
  // inicializadores, y un `ignore` puesto en la linea anterior al constructor no lo calla.
  // Esta es la forma de poner el `ignore` donde el aviso aparece.
  //
  // Y EL POR QUE DEL `ignore` ESTA AQUI Y NO AL LADO: Dart pide `this._almacenamiento`
  // como formal de inicializacion, y entonces el parametro se llamaria `_almacenamiento`,
  // que es un nombre con guion bajo delante en una API. Con la lista de inicializadores
  // el parametro se llama `almacenamiento`, que es como lo llama `main.dart`, y el aviso
  // se calla **con el motivo al lado** y no con un `ignore` mudo, que es la forma de que
  // un `ignore` sobreviva a un cambio que lo hacia innecesario.
  PreferenciasDeLectura({
    Almacenamiento? almacenamiento,
    this.plazoDeLectura = plazoDePreferenciaPorDefecto,
    // ignore: prefer_initializing_formals
  }) : _almacenamiento = almacenamiento;

  /// Cuanto se espera a las preferencias antes de renunciar.
  ///
  /// Y ES UN PARAMETRO Y NO UN `const` POR DENTRO, para que una prueba pueda bajarlo a
  /// diez milisegundos y comprobar el caso --el almacenamiento que no contesta-- sin
  /// esperar cinco segundos. Es lo mismo que hace `arranque.dart` con el catalogo, y por
  /// el mismo motivo: un `await` sin plazo sobre un evento que no llega **cuelga la
  /// pantalla entera**, y hay un caso medido en este repositorio --`localStorage` en un
  /// navegador que no responde-- donde eso ocurre de verdad.
  final Duration plazoDeLectura;

  /// Donde se guarda. Y OPCIONAL, porque el lector se construye en 24 pruebas que no
  /// traen almacenamiento y no tienen por que traerlo. Sin almacenamiento los ajustes
  /// funcionan igual y no se guardan: son preferencias y perderlas son dos toques.
  final Almacenamiento? _almacenamiento;

  /// Si las palabras que dijo Jesus se pintan en rojo.
  ///
  /// Y **VERDAD** DE PARTIDA, sin preguntar. Dos motivos, y el segundo es el que decide:
  ///
  /// 1. Es lo que espera quien abre una app de Biblia en la que el dato esta. Una
  ///    preferencia oculta tras un interruptor apagado es una funcion que no existe.
  /// 2. Medido en el KJV: son 41.284 palabras de 835.159, el **4,94 %** del texto. Es una
  ///    linea de cada veinte, y no es una pantalla en rojo.
  ///
  /// Y NO AFECTA AL TEXTO, que es lo unico que no se toca. El color va en el `TextSpan` y
  /// se quita dejando el texto exactamente igual.
  bool _mostrarPalabrasDeJesus = true;
  bool get mostrarPalabrasDeJesus => _mostrarPalabrasDeJesus;

  /// Los ajustes de lectura: tamano, alto de linea, espaciado, tema, atenuacion y linea
  /// enfocada.
  PreferenciaDeLectura _preferencia = PreferenciaDeLectura.porDefecto;
  PreferenciaDeLectura get preferencia => _preferencia;

  /// Leer lo que hay guardado.
  ///
  /// Y SE LEE UNA VEZ, AL ABRIR, Y NO EN CADA `build`, y con la excepcion **atrapada
  /// aqui**. Un `catch` sin `await` en un `Future` que se lanza desde `main` deja la
  /// pantalla a medias: en el navegador, `SharedPreferences.getInstance()` depende de
  /// `localStorage`, y hay un caso medido --el del almacenamiento del navegador que nunca
  /// contesta-- donde esa llamada se queda esperando para siempre. Bloquear la lectura del
  /// texto por un interruptor de color seria el mismo fallo que el del catalogo, en un
  /// sitio donde no hace falta.
  ///
  /// Y SI FALLA, SE QUEDA EL VALOR DE PARTIDA Y NO SE AVISA. Aqui si se rompe el silencio
  /// que en el catalogo no se rompe, y el motivo: lo que se ha perdido es una preferencia
  /// que se vuelve a poner en dos toques, y un aviso de "no se ha podido leer tu
  /// preferencia de color" en medio de la lectura de Juan 3 no le sirve a nadie.
  ///
  /// ============================================================================
  /// Y AVISA **SOLO SI ALGO HA CAMBIADO**, Y ESO NO ES UN AHORRO: ES UN FALLO QUE
  /// PRODUCE AL REVISAR
  /// ============================================================================
  ///
  /// La primera version avisaba siempre. Con un solo lector no se notaba. Con varios
  /// paneles, avisar siempre es **avisar durante el `build`**, y el framework lo dice con
  /// un error que no dice nada de su causa:
  ///
  ///     setState() or markNeedsBuild() called during build.
  ///     This ListenableBuilder widget cannot be marked as needing to build because the
  ///     framework is already in the process of building widgets.
  ///
  /// Y LA CADENA ESTA ESCRITA ENTERA: `LectorView.initState` pide leer las preferencias,
  /// la lectura responde en un microtask **antes de que el primer frame termine**, y
  /// avisar ahi marca la fila de paneles --que es un **ancestro** de la pantalla que se
  /// esta montando-- como sucia, y a un ancestro no se le puede marcar mientras se esta
  /// constrIyendo.
  ///
  /// Y LA MAYORIA DE LAS VECES **NO HA CAMBIADO NADA**: los valores de partida son los
  /// mismos que los guardados, porque todavia no se ha guardado nada. Asi que avisar solo
  /// cuando cambia convierte un fallo de framework en un `notifyListeners` de verdad, y el
  /// resto del tiempo no hace nada.
  ///
  /// Y **SOLO LEE UNA VEZ**, aunque se llame varias veces.
  ///
  /// Con una ventana por panel, cada `LectorView` llama a `cargarPreferencias` al
  /// montarse, y con dos panels serian dos lecturas del almacenamiento del sistema por
  /// abrir un texto. Y eso no es un coste menor: hay un caso medido en este repositorio --
  /// el almacenamiento del navegador que nunca contesta--, y con dos lecturas sin plazo
  /// habria dos esperas de cinco segundos en vez de una.
  ///
  /// Y NO SE RELEE CUANDO CAMBIA ALGO, y no es que no haga falta: quien cambia un ajuste
  /// lo cambia por esta misma [cambiar] o [alternarPalabrasDeJesus], que ya tienen el
  /// valor en memoria. Releer del almacenamiento solo puede devolver lo que se acaba de
  /// escribir, yeso no lo puede cambiar nadie mas.
  bool _yaSeCargo = false;

  /// Si la lectura ha cambiado algo, para avisar **una vez** y no en cada dato.
  ///
  /// Y ES UN BANDERA Y NO UNA COMPARACION CON LOS VALORES DE ANTES, porque hay dos datos
  /// --el color y la tipografia-- y con dos `if` se avisaria dos veces por una lectura,
  /// que es justo lo que se quiere evitar. Ademas leer la preferencia antes de sustituirla
  /// seria una copia del estado viejo solo para compararlo, y el estado viejo no se usa
  /// para nada mas.
  bool _cambiosPendientes = false;

  Future<void> cargar() async {
    // Y LA SEGUNDA VEZ **NO AVISA NADA**, y no solo porque ya no cambia: avisar aqui es un
    // `markNeedsBuild` durante el `build` del frame en el que se abre el segundo panel.
    // Con dos textos abiertos el primero ya ha cargado y el segundo vuelve a pedir, y un
    // `notifyListeners` en ese momento falla con:
    //
    //     setState() or markNeedsBuild() called during build.
    if (_yaSeCargo) return;
    _yaSeCargo = true;
    final a = _almacenamiento;
    if (a != null) {
      try {
        final guardado = await a.leer(clavePalabrasDeJesus).timeout(plazoDeLectura);
        final rojas = guardado == null || guardado != 'no';
        if (rojas != _mostrarPalabrasDeJesus) _cambiosPendientes = true;
        _mostrarPalabrasDeJesus = rojas;

        // Y LA TIPOGRAFIA, CON **LA MISMA** EXCEPCION ATRAPADA Y EL MISMO PLAZO. Que las dos
        // lecturas compartan el `try` no es ahorre: si la primera lanza, la segunda no se
        // intenta, y es mejor que las dos campen con los valores de partida que perder el
        // color y el tamano porque el almacenamiento fallo una vez.
        final leida = PreferenciaDeLectura.deserializar(
          await a.leer(PreferenciaDeLectura.clave).timeout(plazoDeLectura),
        );
        if (leida != _preferencia) _cambiosPendientes = true;
        _preferencia = leida;
      } catch (_) {
        // Se queda como estaba. Ver el comentario de arriba.
      }
    }
    // Y SOLO SI HA CAMBIADO ALGO. Ver la nota de arriba: es lo que evita el
    // `markNeedsBuild` durante el `build` del primer frame, que con varios paneles es un
    // fallo de verdad y no un aviso.
    if (_cambiosPendientes) {
      _cambiosPendientes = false;
      notifyListeners();
    }
  }

  /// Poner las palabras de Jesus en rojo, o dejarlas como estaban.
  ///
  /// Y **GUARDA**, porque es una preferencia y una preferencia que se pierde al recargar
  /// es una preferencia que hay que volver a buscar cada vez. Y guardar **no** interrumpe:
  /// el color cambia al instante y la escritura va por detras. Al reves --esperar a que se
  /// guarde para pintar-- un interruptor que tarda se siente roto.
  ///
  /// Y EL VALOR ES `si` Y `no`, no `true` y `false`: [Almacenamiento] guarda texto, y
  /// ademas asi se puede leer el fichero de preferencias de un vistazo.
  void alternarPalabrasDeJesus() {
    _mostrarPalabrasDeJesus = !_mostrarPalabrasDeJesus;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return;
    // Sin `await` y sin `catch`: si la escritura falla, se ha perdido una preferencia y
    // no un texto. Un `unawaited` con `catch` es lo unico que no avisa de un error que no
    // tiene consecuencia y hace ruido cuando si la tiene.
    unawaited(
      a.escribir(clavePalabrasDeJesus, _mostrarPalabrasDeJesus ? 'si' : 'no')
          .catchError((Object _) {}),
    );
  }

  /// Cambiar un ajuste de lectura y guardarlo.
  ///
  /// Y ES **UN METODO Y NO SEIS**, y el que decide es [PreferenciaDeLectura]. Quien llama
  /// dice "quiero esto" y el modelo decide si cabe en el rango, con lo que un numero fuera de
  /// rango se acota **en el mismo sitio** que se guarda acotado, y no en seis sitios que se
  /// pueden separarse.
  ///
  /// Y AVISA **ANTES** DE GUARDAR, que es lo que hace que un deslizador se sienta
  /// inmediato, y guarda por detras.
  void cambiar(PreferenciaDeLectura nueva) {
    if (nueva == _preferencia) return;
    _preferencia = nueva;
    notifyListeners();

    final a = _almacenamiento;
    if (a == null) return;
    unawaited(
      a.escribir(PreferenciaDeLectura.clave, nueva.serializar())
          .catchError((Object _) {}),
    );
  }

  /// Poner los ajustes a los recomendados, en una pulsacion.
  void restaurar() => cambiar(_preferencia.restaurar());
}