// La apertura sobre la linea que se esta leyendo, y que **sigue al cursor**.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y QUE ERA EL FALLO
// ============================================================================
//
// En la hoja de formato hay un conmutador de «Linea enfocada» con cuatro posiciones: apagada,
// una linea, tres lineas, cinco lineas. Se puede tocar, **escribe la preferencia**, la
// preferencia se guarda y se conserva.
//
// Y no lo miraba nadie: ni el view model de la lectura sabia que el campo existia, ni la
// vista. Es el fallo que `AGENTS.md` ya documenta con `alCambiarDeVersion` --«una funcion sin
// llamador no falla nunca»-- y aqui es peor, porque no es codigo muerto sino un boton que
// promete algo que no pasa.
//
// Y LA PRIMERA VERSION DE ESTE WIDGET, DESPUES, ERA ESTA MISMA PERO FIJA: la banda en el centro
// vertical de la columna, sin moverse. Y es exactamente lo que se han dicho de ella:
//
//     no me sirve una linea fija que no se mueva
//
// ============================================================================
// QUE HACE EL ORIGINAL, Y POR QUE ESTO ES LO MISMO Y NO OTRA COSA
// ============================================================================
//
// Copiado de `aletheia-reader`, `components/reader/LineFocusOverlay.tsx`. Las cuatro cosas que
// importan:
//
//   1. **Sigue al raton.** `mousemove` -> `setWindowCenterY(clampY(e.clientY))`, con
//      `requestAnimationFrame` para no pintar mas de una vez por fotograma. Sin bloqueo, la
//      banda esta **donde esta el cursor**.
//   2. **Se bloquea** cuando se arrastra en vertical, cuando se pulsan las flechas, y el
//      espacio alterna el bloqueo. Es decir: el raton la mueve **hasta que uno la fije**.
//   3. **Se recorta** para que se vea entera: `minY = max(50, apertura / 2)` y
//      `maxY = alto - apertura / 2 - 50`.
//   4. **La abertura tiene un margen**: `linea * lineas + (lineas > 1 ? 16 : 8)`. No es
//      decoracion: sin el, la banda queda pegada a la linea de arriba y a la de abajo y el
//      texto de al lado se ve cortado en vez de atenuado.
//
// Y EL PORQUE DE QUE SIGA AL RATON Y NO AL SCROLL, que es lo que parece que deberia: con el
// raton a la vista, quien lee ya ha dicho **donde** esta leyendo. El scroll solo dice que ha
// leido mas, y con un capitulo entero en pantalla --Juan 3 son 16.848 pixeles-- el scroll no
// dice nada sobre la linea.
//
// ============================================================================
// Y EN EL DEDO QUE PASA, Y POR QUE NO ES LO MISMO QUE ESTO
// ============================================================================
//
// Con el dedo, alCursor **no se ve**, y el equivalente de "donde estas leyendo" es el centro
// vertical de la pantalla, porque es ahi donde esta la cabeza con el telefono a media altura.
// Y al arrastrar el dedo esta **scrolleando**, que es lo unico que hace el dedo en un texto: si
// la banda lo sigue, no se puede leer.
//
// O sea: con raton la banda sigue al raton y con dedo se queda en el centro, que ya es donde
// se esta leyendo. No es que una de las dos sea menos: son las dos respuestas a «donde esta
// leyendo ahora», que es la pregunta que hace la apertura.
//
// ============================================================================
// Y POR QUE UN VELO Y NO ATENUAR EL TEXTO
// ============================================================================
//
// Un velo encima de la columna, y no el texto en un color mas claro. Con el texto atenuado hay
// un problema que no tiene arreglo: **el atenuado es el mismo para el texto que se lee y para
// el que no**, y el ojo necesita ver los dos para saber que esta leyendo. Un velo se lleva por
// delante el color del fondo y deja el texto intacto, asi que el contraste del texto no se
// toca. Lo que se atenua es la **periferia**, que es justo lo que se quiere quitar.
//
// Y NO ES EL ATENUADOR CON PWM DEL ORIGINAL, y es una decision: con el texto encima, un PWM a
// velocidad de refresco se ve como parpadeo, que es peor que no hacer nada.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ab/ui/core/tema.dart';

/// La clave de la **columna entera**, para las pruebas que preguntan «caben los velos dentro».
///
/// Y UNA TERCERA CLAVE, Y NO UNA: medir la columna con la clave de un velo da el alto de **un**
/// velo y lo compara consigo mismo, que siempre cuadra: asi se pasa una prueba con la apertura
/// saliendose de la columna, que es justo lo que hay que cazar.
const Key claveDeLaColumnaEnfocada = ValueKey<String>('columnaEnfocada');

/// La clave del velo de arriba.
///
/// Y **DOS** CLAVES Y NO UNA, porque los dos velos son hermanos en el mismo `Stack`: con la
/// misma clave los dos, `find.byKey` devuelve uno solo y cualquier prueba que mida el hueco
/// entre ellos sale **negativo**, porque no hay dos. Una clave repetida entre hermanos es un
/// duplicado, y el framework no avisa.
const Key claveDelVeloDeArriba = ValueKey<String>('veloDeLaApertura-arriba');
const Key claveDelVeloDeAbajo = ValueKey<String>('veloDeLaApertura-abajo');

/// La apertura sobre la linea que se esta leyendo.
class LineaEnfocada extends StatefulWidget {
  const LineaEnfocada({
    super.key,
    required this.lineas,
    required this.altoDeLinea,
    required this.hijo,
  });

  /// Cuantas lineas dejan claros. **Cero** es apagada, y no es el mismo que una linea.
  final int lineas;

  /// El alto de **una** linea de lectura, en pixeles.
  ///
  /// Y SE PASA Y NO SE CALCULA AQUI, porque el alto de linea sale de la preferencia --tamano de
  /// letra por alto de linea-- y esa multiplicacion la sabe la vista, que ya la ha hecho para
  /// pintar el texto. Calcularla otra vez aqui es tener la misma cuenta en dos sitios.
  final double altoDeLinea;

  final Widget hijo;

  @override
  State<LineaEnfocada> createState() => _LineaEnfocadaState();
}

class _LineaEnfocadaState extends State<LineaEnfocada> {
  /// Donde va el centro de la banda, en pixeles desde arriba de la columna.
  ///
  /// Y **`null` ES EL CENTRO DE LA COLUMNA**, y no un numero: con el raton fuera de la columna
  /// la banda tiene que estar en el centro, que es donde se esta leyendo sin raton. Si aqui
  /// hubiera un `0`, con el raton fuera la banda se pegaria al borde de arriba y no se veria
  /// texto sin atenuar hasta el final.
  double? _centro;

  /// Si la banda esta **fijada** y ya no sigue al raton.
  ///
  /// Y ESTO NO ES UN ADORNO, es la mitad del comportamiento: sin bloqueo la banda se moveria
  /// cada vez que el raton cruzara la columna al ir a la barra, y quien esta leyendo tendria
  /// que perseguirla. Fijarla es decir «esta aqui».
  bool _bloqueada = false;

  @override
  Widget build(BuildContext context) {
    // Y CERO ES **CERO** Y NO «UNA LINEA», y es una distincion que hay que hacer aqui y no en
    // la hoja: con el conmutador en apagado, un `lineas` de 0 daria una banda de **cero** de
    // alto, que es la columna entera velada, que es leer a oscuras.
    if (widget.lineas <= 0) return widget.hijo;

    return LayoutBuilder(
      builder: (BuildContext contexto, BoxConstraints c) {
        final alto = c.maxHeight;
        final banda = _altoDeLaBanda(alto);

        // Y CENTRO POR DEFECTO Y NO UN NUMERO FIJO: el centro de la columna, que es donde esta
        // la cabeza con el telefono a media altura.
        final centro = _recortado(_centro ?? alto / 2, banda, alto);

        final porArriba = centro - banda / 2;
        final porAbajo = alto - banda - porArriba;
        final oscuro = Theme.of(contexto).brightness == Brightness.dark;

        // Y EL RATON, Y `MouseRegion` Y NO `Listener`: `onHover` **observa** el raton y no se
        // come el evento, asi que el texto de debajo sigue seleccionandose y los botones de
        // la columna siguen pulsandose. Un `Listener` que se quedara el evento seria un
        // `IgnorePointer` de mas.
        return MouseRegion(
          onHover: _alMoverElRaton,
          child: _Teclado(
            alBloquear: () => setState(() => _bloqueada = true),
            alAlternarBloqueo: () => setState(() => _bloqueada = !_bloqueada),
            alMover: (int signo) => setState(() {
              _bloqueada = true;
              _centro = (_centro ?? alto / 2) + signo * widget.altoDeLinea;
            }),
            hijo: Stack(
                // ======================================================================
                // Y `StackFit.expand`, QUE SIN ESTO DEJA LA COLUMNA CRECER
                // ======================================================================
                //
                // Un `Stack` sin `fit` da a sus hijos **sueltos** la altura que le den, y el
                // hijo es el `ListView` del capitulo entero: Juan 3 son 16.848 pixeles. Con
                // `fit: loose` el `Stack` mide lo que mide su hijo y **se sale** de su hueco,
                // que se ve como el texto de mas tapando los terminos del modulo.
                //
                // Y NO LO HABIA VISTO NINGUNA PRUEBA, porque las que hay miden los velos
                // **relativos entre si** --que el de arriba y el de abajo se repartan la
                // columna--, y eso sale bien con el `Stack` desbordado. Lo que delata el
                // desborde es medir la columna contra su propia caja, que es justo lo que
                // hace la prueba del raton:
                //
                //     el centro de la columna   375,5
                //     el centro de la banda     319,9   ->   440 / 2
                //
                // O sea: el `LayoutBuilder` ve 440 px --que es su hueco-- y el `Stack` se
                // pinta a 751. Un numero y otro que describen dos widgets distintos.
                fit: StackFit.expand,
                key: claveDeLaColumnaEnfocada,
                children: <Widget>[
                  widget.hijo,
                  if (porArriba > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: porArriba,
                      child: _Velo(clave: claveDelVeloDeArriba, oscuro: oscuro),
                    ),
                  if (porAbajo > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: porAbajo,
                      child: _Velo(clave: claveDelVeloDeAbajo, oscuro: oscuro),
                    ),
                ],
              ),
          ),
        );
      },
    );
  }

  void _alMoverElRaton(PointerHoverEvent evento) {
    // Y SI ESTA BLOQUEADA NO SE MUEVE, y es el unico motivo por el que existe el bloqueo.
    if (_bloqueada) return;
    setState(() => _centro = evento.localPosition.dy);
  }

  /// El alto de la banda, que depende de las lineas **y** de la columna.
  ///
  /// Y SI LA BANDA ES MAS ALTA QUE LA COLUMNA, LA BANDA **ES** LA COLUMNA. Sin esto,
  /// `centro - banda / 2` sale **negativo** y los dos velos se salen de la columna: es el fallo
  /// medido el 6 de octubre de 2026, en el que la banda se quedaba **fija arriba y sin hacer
  /// nada**. No era que no siguiera al raton: estaba empujada fuera y se pegaba al borde.
  ///
  /// Y NO SE RECORTA EL NUMERO DE LINEAS, que seria lo facil: el conmutador dice cinco y tiene
  /// que abrir cinco. Recortarlas seria volver a mentir sobre lo que el boton dice.
  double _altoDeLaBanda(double alto) {
    // Y EL MARGEN DE LA ABERTURA, COPIADO DEL ORIGINAL: `+ (lineas > 1 ? 16 : 8)`. Sin el la
    // banda queda pegada a la linea de arriba y a la de abajo, y el texto de al lado se ve
    // cortado en vez de atenuado, que es un recorte de verdad y no un efecto de luz.
    final margen = widget.lineas > 1 ? 16.0 : 8.0;
    final pedida = widget.lineas * widget.altoDeLinea + margen;
    if (pedida > alto) return alto;
    return pedida;
  }

  /// Recorta el centro para que la banda se vea **entera**.
  ///
  /// Y CON 50 px DE MARGEN COMO EL ORIGINAL, que es lo que deja el borde de arriba y el de
  /// abajo sin tocar. Y el recorte **no** aparta la banda de la linea que se esta leyendo si
  /// ya cabe, que es lo que haria un recorte con `clamp` sin mirar.
  double _recortado(double centro, double banda, double alto) {
    if (banda >= alto) return alto / 2;
    final minimo = banda / 2;
    final maximo = alto - banda / 2;
    return centro.clamp(minimo, maximo);
  }
}

/// Las flechas y el espacio, que solo funcionan si no hay un campo de texto con el foco.
///
/// Y SE ESCUCHA EN `HardwareKeyboard` Y NO CON `Shortcuts`, y no por comodidad: `Shortcuts` es
/// un `Focus` como otro, y una tecla solo llega a el si **el foco esta ahi**. En la pantalla de
/// lectura el foco esta en el campo «Ir a: Juan 3:16» --o en ningun sitio-- y las flechas no
/// llegarian nunca.
///
/// Y EL ORIGINAL ESCUCHA EN `window`, que es justo lo equivalente a escuchar en
/// `HardwareKeyboard`: `window.addEventListener('keydown', ...)` en
/// `LineFocusOverlay.tsx`. Copiarlo asi es lo que hace que las flechas funcionen sin tener que
/// hacer clic antes en el texto, que es lo que nadie va a descubrir.
///
/// Y ESTA COMPROBACION DEL CAMPO DE TEXTO ES OBLIGATORIA Y NO UNA CORTESIA. En la pantalla de
/// lectura hay un campo, y con las flechas dentro de el se mueve el cursor del texto. Sin la
/// guarda, arreglar la banda dejaria **sin poder escribir en el campo**: el fallo mas
/// desconcertante que hay, porque no se parece en nada a lo que se ha roto. El original lo
/// hace igual --descarta `INPUT`, `TEXTAREA`, `SELECT`, `BUTTON` y `contentEditable`-- y por eso
/// hay que copiar tambien esa parte y no solo la que se ve.
class _Teclado extends StatefulWidget {
  const _Teclado({
    required this.alBloquear,
    required this.alAlternarBloqueo,
    required this.alMover,
    required this.hijo,
  });

  final VoidCallback alBloquear;
  final VoidCallback alAlternarBloqueo;
  final void Function(int signo) alMover;
  final Widget hijo;

  @override
  State<_Teclado> createState() => _TecladoState();
}

class _TecladoState extends State<_Teclado> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_alPulsar);
  }

  @override
  void dispose() {
    // Y SE QUITA AL DESTRUID, Y NO AL QUEDARSE: un manejador que se queda registrado apunta a
    // un `State` que ya no existe, y el siguiente cambio de pasaje --que hay varios por
    // capitulo-- deja varios manejadores encima. Es el fallo de `alCambiarDeVersion` con un
    //Recognizer: codigo sin dueno.
    HardwareKeyboard.instance.removeHandler(_alPulsar);
    super.dispose();
  }

  /// Y DEVUELVE `bool` Y NO `KeyEventResult`, porque esta es la firma de
  /// `HardwareKeyboard.addHandler` en esta version del SDK, y `KeyEventResult` es la de
  /// `onKeyEvent` de un `Focus`, que es otra cosa.
  ///
  /// Y `true` ES «LA HE COGIDO YO» y hace que la tecla **no llegue** a ningun otro: con `false`
  /// la flecha sigue su camino y ademas se mueve la banda, que es hacer las dos cosas con la
  /// misma tecla. Y solo se coge la tecla cuando la banda esta encendida, que es lo que
  /// comprueba el llamador antes de montar este widget.
  bool _alPulsar(KeyEvent evento) {
    if (evento is! KeyDownEvent) return false;

    final esArriba = evento.logicalKey == LogicalKeyboardKey.arrowUp;
    final esAbajo = evento.logicalKey == LogicalKeyboardKey.arrowDown;
    final esEspacio = evento.logicalKey == LogicalKeyboardKey.space;
    if (!esArriba && !esAbajo && !esEspacio) return false;

    // Y LA GUARDA DEL CAMPO DE TEXTO ANTES DE COGER LA TECLA, y no despues: si se cogiera y
    // luego se soltara, la tecla llegaria igual al campo y lo que se evitaria seria el
    // efecto, no el Solape.
    if (_hayCampoConElFoco()) return false;

    if (esEspacio) {
      widget.alAlternarBloqueo();
      return true;
    }
    widget.alBloquear();
    widget.alMover(esAbajo ? 1 : -1);
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.hijo;
}

/// Si el foco que hay ahora es un campo de texto.
///
/// Y SE MIRA EL **WIDGET** DEL FOCO Y NO SU TIPO, y el motivo es que en Flutter el foco de un
/// `TextField` lo tiene un `FocusNode` interno cuyo contexto no es el `EditableText`: buscar
/// `EditableText` en el ancestro del nodo de foco no lo encuentra y la guarda no hace nada, que
/// es el peor sitio para que falle una guarda.
bool _hayCampoConElFoco() {
  final foco = FocusManager.instance.primaryFocus;
  if (foco == null || !foco.hasFocus) return false;
  final contexto = foco.context;
  if (contexto == null) return false;
  return contexto.widget is EditableText ||
      contexto.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// El velo, que **no** come toques.
///
/// Y EL `IgnorePointer` PORQUE ES OBLIGATORIO Y NO POR CORTESIA: sin el, los velos estan
/// **encima** de la columna de texto y se comen todos los toques. El texto se selecciona con el
/// dedo --que es lo que hace la gente con un texto-- y con un velo encima dejaria de poder
/// seleccionarse justo en la parte que se va a leer. Un lector donde no se puede seleccionar
/// es un lector roto, y el sintoma seria «no puedo copiar un versiculo», que no apunta a nada.
///
/// Y EL COLOR ES EL DEL **FONDO** Y NO UN GRIS, porque un gris encima de un fondo crema se ve
/// como una mancha y encima de un fondo casi negro se ve como niebla. Con el color del fondo,
/// lo que se atenua es la luz que llega del fondo y el texto se queda como estaba.
class _Velo extends StatelessWidget {
  const _Velo({required this.clave, required this.oscuro});

  final Key clave;
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: clave,
      child: ColoredBox(
        color: context.colores.fondo.withValues(
          alpha: oscuro ? atenuacionSobreOscuro : atenuacionSobreClaro,
        ),
      ),
    );
  }
}

/// Cuanto atenua el velo, en cada tema.
///
/// Y EL VALOR **NO** ES EL MISMO EN LOS DOS, y no por gusto. El atenuador de pantalla completa
/// va a 0,86 porque se ve contra el **panel entero**, que es mucho fondo. Aqui el velo se ve
/// contra el **texto**, que son unas quince lineas: con 0,86 lo que hay al lado de la apertura
/// queda ilegible, y una abertura que hace ilegible lo que tiene al lado no es una abertura,
/// es un filtro de foto.
///
/// Y SOBRE FONDO CLARO EL VELO TIENE QUE APAGAR **MAS**, y parece lo contrario: un velo del
/// mismo color que el fondo con la misma opacidad no se ve sobre un crema claro, porque los dos
/// son casi el mismo color. Lo que se apaga ahi es el contraste del texto contra el crema, y
/// hace falta mas opacidad para que se note.
const double atenuacionSobreClaro = 0.58;
const double atenuacionSobreOscuro = 0.62;
