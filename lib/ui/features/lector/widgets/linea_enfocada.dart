// La apertura sobre la linea que se esta leyendo.
//
// ============================================================================
// POR QUE ESTO EXISTE Y QUE ES UNA PROMESA ROTA HASTA AHORA
// ============================================================================
//
// En la hoja de formato hay un conmutador de «Linea enfocada» con cuatro posiciones: apagada,
// una linea, tres lineas, cinco lineas. Se puede tocar, **escribe la preferencia** y la
// preferencia se guarda y se lee. Y no lo miraba nadie: ni el view model de la lectura sabia
// que el campo existia, ni la vista.
//
// O sea: un interruptor que **miente**. Y es la version con cara de usuario de un fallo que
// `AGENTS.md` ya documenta con `alCambiarDeVersion` --«una funcion sin llamador no falla
// nunca»-- y aqui es peor, porque no es codigo muerto sino un boton que promete algo que no
// pasa.
//
// ============================================================================
// QUE SE VE Y POR QUE UN VELO Y NO ATENUAR EL TEXTO
// ============================================================================
//
// Un velo encima de la columna, y no el texto en un color mas claro. Con el texto atenuado hay
// un problema que no tiene arreglo: **el atenuado es el mismo para el texto que se lee y para
// el que no**, y el ojo necesita ver los dos para saber que esta leyendo. Un velo se lleva por
// delante el color del fondo y deja el texto intacto, asi que el contraste del texto --que es
// 15,17:1 en el oscuro-- no se toca. Lo que se atenua es la **periferia**, que es justo lo que
// se quiere quitar.
//
// Y ES LO QUE SE HA COPIADO. En `aletheia-reader` esto es un atenuador con modulado de ancho
// de pulso --PWM--, que apaga y enciende el fondo a mucha velocidad para que el ojo no lo vea
// como parpadeo. En pantalla, con el texto encima, el mismo efecto se consigue con un velo
// continuo y sin parpadeo: el ojo periphery es menos sensible al contraste bajo que el centro,
// y con la velocidad de refresco de una pantalla el PWM se ve como parpadeo.
//
// ============================================================================
// Y POR QUE LA BANDA ESTA EN EL **CENTRO VERTICAL** Y NO EN EL VERSICULO QUE TOCAS
// ============================================================================
//
// Porque el sitio donde el ojo esta ahora no se sabe: se sabe donde esta el **dedo**, que es
// distinto, y en un movil el texto se lee a la altura de los ojos con el telefono a media
// altura. Y una banda que se moviese con el scroll tendria que ir pegada al borde de la
// ventana, que es justo donde no se lee. En el centro --que es donde esta la lectura util-- se
// queda quieta y no llama la atencion.

import 'package:flutter/material.dart';

import 'package:ab/ui/core/tema.dart';

/// La clave del velo de la apertura, para las pruebas.
///
/// Y ES **PUBLICA** Y ES UNA CONSTANTE, y no un literal en la prueba, porque aparece en dos
/// sitios y si uno de los dos cambia el nombre el otro deja de encontrarlo y el fallo dice
/// «0 widgets» sin decir de donde.
///
/// Y **DOS** CLAVES Y NO UNA, porque los dos velos son hermanos en el mismo `Stack`: con la
/// misma clave los dos, `find.byKey` devuelve uno solo y cualquier prueba que mida el hueco
/// entre ellos sale **negativo**, porque no hay dos. Una clave repetida entre hermanos es un
/// duplicado, y el framework no avisa.
const Key claveDelVeloDeArriba = ValueKey<String>('veloDeLaApertura-arriba');
const Key claveDelVeloDeAbajo = ValueKey<String>('veloDeLaApertura-abajo');

/// La apertura sobre la linea que se esta leyendo.
class LineaEnfocada extends StatelessWidget {
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
  /// Y SE PASA Y NO SE CALCULA AQUI, porque el alto de linea sale de la preferencia --tamaño de
  /// letra por alto de linea-- y esa multiplicacion la sabe la vista, que ya la ha hecho para
  /// pintar el texto. Calcularla otra vez aqui es tener la misma cuenta en dos sitios.
  final double altoDeLinea;

  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    // Y CERO ES **CERO** Y NO "UNA LINEA", y es una distincion que hay que hacer aqui y no en
    // la hoja: con el conmutador en apagado, un `lineas` de 0 daria una banda de **cero** de
    // alto, que es la columna entera velada, que es leer a oscuras.
    if (lineas <= 0) return hijo;

    final banda = (lineas * altoDeLinea).clamp(altoDeLinea, double.infinity);

    return LayoutBuilder(
      builder: (BuildContext contexto, BoxConstraints c) {
        // Y EL VELO DE ARRIBA Y EL DE ABAJO SON **DOS** Y NO UNO CON DOS HUECOS, porque un
        // solo velo con un hueco obliga a hacer un `Path` con un recorte, y el recorte se ve
        // mal en cuanto el alto no es multiplo del de linea: el borde sale a medio pixel y se
        // ensena una linea gris que no esta en el texto.
        final alto = c.maxHeight;
        final porArriba = ((alto - banda) / 2).clamp(0.0, double.infinity);
        final porAbajo = (alto - banda - porArriba).clamp(0.0, double.infinity);

        // Y LA CLAVE, PORQUE SIN ELLA LA PRUEBA NO SE PUEDE ESCRIBIR. Un `ColoredBox` en la
        // pantalla de lectura hay varios --el fondo del velo, el de las barras, el de los
        // pulsadores-- y contarlos todos daria una cantidad que **no depende del conmutador**:
        // la prueba diria «hay velos» con la apertura apagada. Es la misma trampa que
        // `find.byKey(claveDelNumeroDeVersiculo)`, que existe porque el numero de capitulo se
        // confundia con un versiculo y tres pruebas contaban 37.
        final oscuro = Theme.of(contexto).brightness == Brightness.dark;

        return Stack(
          children: <Widget>[
            hijo,
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
        );
      },
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
///son casi el mismo color. Lo que se apaga ahi es el contraste del texto contra el crema, y
/// hace falta mas opacidad para que se note.
const double atenuacionSobreClaro = 0.58;
const double atenuacionSobreOscuro = 0.62;

/// El velo, que **no** come toques.
///
/// Y EL `IgnorePointer` PORQUE ES OBLIGATORIO Y NO POR CORTESIA: sin el, los velos estan
/// **encima** de la columna de texto y se comen todos los toques. El texto se selecciona con el
/// dedo --que es lo que hace la gente con un texto-- y con un velo encima dejaria de poder
/// seleccionarse justo en la parte que se va a leer. Un lector donde no se puede seleccionar
/// es un lector roto, y el sintoma seria «no puedo copiar un versiculo», que no apunta a nada.
///
/// Y EL COLOR ES EL DEL **FONDO** Y NO UN GRIS, porque un gris encima de un fondo crema se ve
/// como una mancha y encima de un fondo casi negro se ve como niebla. Con el color del fondo
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
