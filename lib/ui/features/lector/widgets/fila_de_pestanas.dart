// La fila de pestañas: los paneles abiertos, con su `X` y el `+` de abrir otro.
//
// ============================================================================
// POR QUE ESTA EN UN FICHERO PROPIO Y NO EN LA VISTA DEL LECTOR
// ============================================================================
//
// La fila de pestañas es de la **ventana**, no de un panel: es la misma fila para los dos
// textos abiertos, y va encima de los dos. Si viviera en `LectorView`, cada panel
// pintaria su propia fila y habria dos filas de pestañas --una por columna-- que no
// controlarian nada. El mismo motivo por el que `MarcoDeEstudio` esta fuera de las
// pantallas.
//
// ============================================================================
// Y LO QUE **NO** SE PONE EN LA FILA, Y POR QUE CADA COSA
// ============================================================================
//
// Mirada la captura de Logos: `RVR60`, `JFB`, y un `+`. Y tambien hay, en la parte
// izquierda de la barra, un menu de **bibliotecas** --que recursos estan en que
// biblioteca--, y una **flecha** para plegar la fila entera.
//
//   - **Las bibliotecas** no se pintan. Aqui hay **un** sitio de donde leer: el catalogo.
//     Y una fila de bibliotecas con una sola entrada es una fila que dice "hay una cosa" y
//     ocupa 40 px. Un selector de bibliotecas es lo que haria una aplicacion con cuentas
//     y carpetas; este proyecto no tiene cuentas y el catalogo es el unico sitio.
//   - **La flecha para plegar** no se pinta. Plegar la fila deja la ventana sin saber
//     cuantos textos hay abiertos, y con las pestanas esa informacion es el unico sitio
//     donde se ve. En Logos la flecha existe porque la ventana es muy alta y cada pixel
//     cuenta; aqui la fila son 40 px de 760, un 5 %.
//   - **El color de la version** va en la pastilla. En Logos cada recurso tiene un color
//     que el usuario le asigna, y es una decision de quien lo tiene abierto: no hay
//     ningun color en el manifiesto que sea "el color de esta Biblia", y poner el
//     `ColorScheme.primary` seria inventar un color para cada texto. Ver `_Pestana`.
//
// ============================================================================
// Y LA ALTURA, QUE ES UNA MEDIDA Y NO UN GUSTO
// ============================================================================
//
// Medido a 360 px en una captura del 5 de octubre de 2026: la barra de arriba eran 56 px y
// el campo de referencia 48 px, y el cromo antes del primer versiculo eran **260 px** de
// 760 --el 34 % de la pantalla-- con el versiculo en el 16 %. Anadir 40 px mas de pestañas
// son el **39 %**, y ahi ya no se lee.
//
// Y POR QUE LA FILA **NO SE PUNTA EN PANTALLA ESTRECHA**, y el motivo es el mismo corte que
// el del panel de herramientas: por debajo de `Medidas.anchoParaPanelDeHerramientas` --1100
// px-- hay una columna y no cabe el paralelo, asi que las pestañas serian tres botones
// para cambiar entre tres textos que salen uno detras de otro. Medido a 360 px: tres
// pestañas de "King James Version (2006)" son tres columnas de 60 px con el nombre
// recortado en dos lineas, y el nombre de la version es lo unico que identifica el panel.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/panel_abierto.dart';
import 'package:ab/ui/core/tema.dart';

/// La altura de la fila de pestañas.
///
/// Y SON **40 px**, y no los 48 de un control de Material. Motivo medido: la fila esta
/// **encima** de la cabecera del panel --que son 48 px del campo de referencia--, y las dos
/// se suman por encima del texto. En una columna que a 1440 px mide 769 px --los 90
/// caracteres--, cada 8 px que se quita de cromo es una linea menos de滚动 por capitulo.
///
/// Y NO SE BAJA DE 40, y el motivo es el mismo que hay en `campo_de_referencia.dart` para
/// los botones: por debajo de 40 px el dedo no acierta, y un objetivo de pulsacion de 40
/// px es lo mas pequeno que Material considera razonable con el dedo.
const double kAlturaDeLaFilaDePestanas = 40;

/// La fila de pestañas de los paneles abiertos.
///
/// Y DEVUELVE **NADA** si hay un solo panel, y no una fila con un nombre. El motivo es el
/// que esta en la cabecera: por debajo de 1100 px no hay paralelo, y con un panel la fila
/// no dice nada que la cabecera del panel --que ya lleva el nombre de la version-- no diga
/// mejor.
class FilaDePestanas extends StatelessWidget {
  const FilaDePestanas({
    super.key,
    required this.paneles,
    required this.alFrente,
    required this.alCerrar,
    required this.alAbrirOtro,
    required this.nombreDe,
    required this.moduloDelante,
  });

  final List<PanelAbierto> paneles;

  /// Poner un panel delante. Recibe el identificador del modulo.
  final void Function(String moduloId) alFrente;

  /// Cerrar un panel. Recibe el identificador del modulo.
  final void Function(String moduloId) alCerrar;

  /// Abrir otro panel. Sin argumentos: quien lo abre es el enrutador, que es quien tiene
  /// el catalogo y sabe que hay descargado.
  final VoidCallback alAbrirOtro;

  /// El nombre legible de un modulo, tal como lo dice el manifiesto.
  ///
  /// Y ES UNA FUNCION Y NO UN MAPA DE NOMBRES, porque un mapa tendria que construirse con
  /// los nombres de todos los modulos del catalogo para usar dos, y ese mapa seria una
  /// copia de los identificadores en un segundo sitio --justo la lista de textos que este
  /// proyecto no quiere--. Aqui solo se pregunta por el que se pinta.
  final String Function(String moduloId) nombreDe;

  /// Que modulo es el que esta delante, tal como lo dice el estado.
  final String? moduloDelante;

  @override
  Widget build(BuildContext context) {
    // Y CON UN SOLO PANEL **NO HAY FILA**, y no una fila con el nombre. Ver la cabecera.
    if (paneles.length < 2) return const SizedBox.shrink();

    final colores = Theme.of(context).colorScheme;
    // Y EL QUE ESTA DELANTE SE PONE COMO PARAMETRO Y NO SE BUSCA AQUI, porque "cual esta
    // delante" es estado del **view model** y esta lista son solo datos: si la fila
    //聪明的 decidiera cual es el de delante con `firstWhere`, tendria que adivinarlo desde
    // el orden, y el orden de apertura no es el orden en que se ven.
    final delante = moduloDelante;

    // ============================================================================
    // Y ESTA FILA **NO ESTA DENTRO DE NINGUN `SCAFFOLD`**, Y POR ESO TRAE SU `MATERIAL`
    // ============================================================================
    //
    // La fila va **encima** de los paneles, y cada panel es un `Scaffold` propio --son
    // columnas distintas--. O sea que la fila es hermana de los `Scaffold` y no hija de
    // ninguno, y el `Material` que un `Scaffold` pone en su barra y en su cuerpo no llega
    // hasta aqui.
    //
    // Y SIN ESE `MATERIAL` LOS BOTONES **NO FUNCIONAN Y EL ERROR NO DICE DE QUE**:
    //
    //     No Material widget found.
    //     _InkResponseStateWidget widgets require a Material widget ancestor within the
    //     closest LookupBoundary.
    //
    // Es el mismo fallo que ya esta escrito en `marco_de_estudio.dart` --con el panel de
    // herramientas y con la barra de destinos--, y por eso los tres llevan su `Material`.

    // Y EL ANCHO DEL NOMBRE SE REPARTE ENTRE LOS QUE HAY, y no es un numero escrito.
    //
    // MEDIDO A 360 px el 6 de octubre de 2026, con dos pestanas: la fila gasta **48 px** que
    // no son de nombre --el padding de la lista y el `+`-- y cada pastilla gasta **40** --16
    // de padding y 24 entre la `X` y su hueco--. Quedan
    //
    //     (360 - 48 - 2 x 40) / 2 = 116 px de nombre
    //
    // y con un tope fijo de 200 la primera pastilla se comia la fila entera y la segunda --
    // que es la que dice que hay dos textos y no uno-- quedaba fuera de la pantalla. Y como la
    // lista es desplazable no se pierde: se **esconde**, que es peor, porque quien no sepa
    // que puede desplazar creera que solo hay un texto abierto.
    final nombreMaximo = _anchoDelNombre(context, paneles.length);

    return Material(
      child: Container(
      // Y LA CLAVE, PORQUE SIN ELLA LA COMPROBACION NO SE PUEDE ESCRIBIR. Con la
      // aplicacion montada hay otros `Container` en la fila --el punto del comentario, el
      // fondo de la pastilla activa-- y `find.byType` no los distingue. Igual que
      // `claveDelFondoDelResaltado` en `lector_view.dart`.
      key: claveDeLaFilaDePestanas,
      height: kAlturaDeLaFilaDePestanas,
      decoration: BoxDecoration(
        color: colores.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colores.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          // Y LA FILA **ES DESPLAZABLE**, y por un motivo concreto: los nombres de las
          // versiones son largos --"King James Version (2006)"-- y con tres textos
          // abiertos mas sus dos `X` son mas de 700 px. Sin desplazamiento, la tercera
          // pestana sale cortada por el borde y el nombre del CLARKE --que es el que
          // dice que hay dos textos y no uno-- es el que se pierde.
          //
          // Y EL `+` **FUERA** DEL DESPLAZAMIENTO, a la derecha, porque es una accion y no
          // un nombre: una accion que se va con el scroll es una accion que no se encuentra.
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: <Widget>[
                for (final p in paneles)
                  _Pestana(
                    texto: nombreDe(p.moduloId),
                    identificador: p.moduloId,
                    anchoMaximoDelNombre: nombreMaximo,
                    activa: p.moduloId == delante,
                    esComentario: p.esComentario,
                    // Y LA `X` **SOLO CON MAS DE UN PANEL**. Con uno no hay nada que
                    // cerrar y una `X` al lado del unico texto abierto cierra la lectura
                    // entera, que es un boton de salida con la forma de un boton de
                    // limpieza.
                    hayMasDeUno: paneles.length > 1,
                    alPulsar: () => alFrente(p.moduloId),
                    alCerrar: () => alCerrar(p.moduloId),
                  ),
              ],
            ),
          ),
          _BotonDeAbrirOtro(alPulsar: alAbrirOtro),
        ],
      ),
      ),
    );
  }
}

/// Los pixeles de nombre que le tocan a cada pestaña.
///
/// Y ES UNA CUENTA Y NO UN NUMERO, porque depende de dos cosas que cambian --el ancho de la
/// ventana y cuantos paneles hay-- y un numero escrito para un caso se equivoca en cuanto
/// cambia cualquiera de las dos. Y el resultado se **topea**, porque en una ventana ancha un
/// nombre sin tope se estiraria a 600 px y una pastilla de 600 no es una pastilla.
///
/// Y EL **TOPE** es de 200 px, y es la medida de "King James Version (2006)" a 13 de letra
/// mas un poco: mas alla de ahi el nombre no se lee entero ni en una ventana de 1.440, y
/// estirarlo no gana nada.
///
/// Y NUNCA **MENOS DE 60**, que es lo que cabe "Comentario" a 13 px. Un nombre mas estrecho
/// que eso no es un nombre recortado, es un剪
double _anchoDelNombre(BuildContext context, int cuantos) {
  final ancho = MediaQuery.sizeOf(context).width;
  final reparto = (ancho - kGastoDeLaFila - kGastoDeUnaPastilla * cuantos) / cuantos;
  return reparto.clamp(kAnchoMinimoDelNombre, kAnchoMaximoDelNombre);
}

/// Lo que la fila gasta y no es nombre: el padding de la lista y el boton de `+`.
const double kGastoDeLaFila = 48;

/// Lo que gasta cada pastilla y no es nombre: 16 de padding y 24 entre la `X` y su hueco.
const double kGastoDeUnaPastilla = 40;

/// El nombre mas estrecho que se considera un nombre, en px.
const double kAnchoMinimoDelNombre = 60;

/// El nombre mas ancho, en px. Medido sobre "King James Version (2006)" a 13 de letra.
const double kAnchoMaximoDelNombre = 200;

/// La clave de la fila de pestañas, para las pruebas.
///
/// Y ES PUBLICA Y ES UNA CONSTANTE, y no un literal escrito en la prueba, porque aparece
/// en dos sitios --la vista que la pinta y la prueba que la busca-- y si uno de los dos
/// cambia el nombre el otro deja de encontrarla y el fallo dice "0 widgets" sin decir de
/// donde. Ver `lector_view.dart`, que tiene el mismo motivo para
/// [claveDelFondoDelResaltado].
const Key claveDeLaFilaDePestanas = ValueKey<String>('fila-de-pestanas');

/// La clave de la pastilla de un panel, para las pruebas.
///
/// Y LLEVA EL IDENTIFICADOR DEL MODULO, y no un numero: las pruebas preguntan por la
/// pastilla **de un texto concreto** --"esta la del CLARKE"-, y un indice seria un
/// numero que cambia en cuanto se abre otro panel delante.
Key claveDeLaPestana(String moduloId) => ValueKey<String>('pestana:$moduloId');

/// Una pestaña: el nombre del texto y su `X`.
class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.texto,
    required this.identificador,
    required this.anchoMaximoDelNombre,
    required this.activa,
    required this.esComentario,
    required this.hayMasDeUno,
    required this.alPulsar,
    required this.alCerrar,
  });

  final String texto;
  final String identificador;

  /// Cuantos pixeles de nombre caben en esta pastilla. Ver [_anchoDelNombre].
  final double anchoMaximoDelNombre;

  final bool activa;
  final bool esComentario;
  final bool hayMasDeUno;
  final VoidCallback alPulsar;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final tinta = activa ? colores.onSurface : colores.outline;

    return Semantics(
      selected: activa,
      button: true,
      label: activa ? '$texto. Panel abierto' : '$texto. Traer este panel delante',
      child: InkWell(
        key: claveDeLaPestana(identificador),
        onTap: alPulsar,
        child: Container(
          // Y **SIN** `padding` horizontal grande: cada pastilla mide lo que mide su
          // nombre y la `X` son 20 px. Medido: "King James Version (2006)" son 175 px a
          // 13 de letra, y con margen de 8 a cada lado y la `X` la pastilla mide 211 px.
          // Tres son 633, y con el `+` y los bordes entran en 700 con holgura a 1100 px
          // contando el panel de herramientas.
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            // Y LA ACTIVA **DESTACADA CON UNA LINEA ARRIBA**, no con un fondo. Un fondo
            // de color en la activa hace que la fila de pestañas sea lo mas llamativo de
            // la ventana, y lo mas llamativo tiene que ser el texto.
            border: Border(
              top: BorderSide(
                color: activa ? colores.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Y EL PUNTO DE COLOR **SOLO EN UN COMENTARIO**, y con el color de acento.
              //
              // En Logos cada recurso lleva un color que elige quien lo tiene abierto. No
              // se puede copiar sin inventar el color: el manifiesto no declara ninguno. Lo
              // que si se puede distinguir sin inventar nada es **el tipo**: un comentario
              // no es Sagrada Escritura, y el color de acento es el que ya usa el resto de
              // la aplicacion para marcar "esto es un comentario" --`_ColumnaDeNotas`, las
              // cabeceras de nota, el boton de la barra. Reutilizarlo es lo coherente.
              if (esComentario) ...<Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.colores.acento,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: anchoMaximoDelNombre),
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tinta,
                        // Y LA ACTIVA EN **PESO FUERTE** y la que no en normal, y no con
                        // mas cuerpo: la pastilla esta en 13 px y subirla a 14 en la
                        // activa hace que la fila "salte" al cambiar de pestana, que es lo
                        // contrario de lo que debe hacer un elemento que se usa para no
                        // perderse.
                        fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
              if (hayMasDeUno) ...<Widget>[
                const SizedBox(width: 4),
                _Cerrar(
                  nombre: texto,
                  alPulsar: alCerrar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// La `X` de una pestaña.
///
/// Y ES DE **20 PX** Y NO DE 40, y este es un caso raro de este proyecto: por debajo del
/// alto minimo que se considera pulsable. El motivo es que esta `X` esta **al lado** de la
/// pastilla, que ya es pulsable: el objetivo real es la pastilla entera, de 40 px de alto,
/// y quien quiere cerrar esa `X` tiene el dedo justo encima. Con 40 px de `X` la pastilla
/// mediria 231 px y tres saldrían de la ventana.
class _Cerrar extends StatelessWidget {
  const _Cerrar({required this.nombre, required this.alPulsar});

  final String nombre;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar $nombre',
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          // Y EL `padding` HACE EL OBJETIVO, y no el tamano del icono. Un `Icon` de 14
          // sin padding es un objetivo de 14 px, que el dedo no acierta; con 3 px de
          // padding a cada lado son 20, que es lo que cabe y ya se toca.
          padding: const EdgeInsets.all(3),
          child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}

/// El `+` de abrir otro panel.
///
/// Y ES UN **BOTON**, NO UNA PASTILLA**: es una accion y no un nombre, y por eso no lleva
/// ni el mismo fondo ni la misma forma. Y esta fuera del desplazamiento de las
/// pestañas, a la derecha, porque una accion que se va con el scroll es una accion que no
/// se encuentra.
class _BotonDeAbrirOtro extends StatelessWidget {
  const _BotonDeAbrirOtro({required this.alPulsar});

  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir otro texto al lado',
      child: InkWell(
        onTap: alPulsar,
        child: SizedBox(
          width: 40,
          height: kAlturaDeLaFilaDePestanas,
          child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
