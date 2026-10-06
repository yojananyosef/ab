// El marco de la pantalla de estudio: donde van las herramientas.
//
// ============================================================================
// POR QUE ESTO EXISTE Y NO ERA UN ADORNO
// ============================================================================
//
// Medido el 5 de octubre de 2026, poniendo una captura de esta aplicacion al lado de una
// de Logos con la misma tarea --leer Juan 1-- y contando las cosas estructurales:
//
//     panel de herramientas a la izquierda      Logos si    aqui no
//     pestanas por panel                        Logos si    aqui no
//     paneles lado a lado con scroll propio     Logos si    aqui no
//     fila de menu por panel                    Logos si    aqui no
//     segunda barra de formato                  Logos si    aqui no
//     migas de pan sobre el texto               Logos si    aqui no
//     numero de capitulo grande y epigrafes     Logos si    aqui no
//     numeros de versiculo en linea             Logos si    columna a la izquierda
//     panel de ideas a la derecha               Logos si    aqui no
//     barra inferior en pantalla estrecha       Logos si    el campo en medio del cuerpo
//
// De diez cosas, **una** estaba: el texto con su numeracion. Y no era que estivesse
// repartido de otra forma: no estaba.
//
// Y EL FALLO NO ERA EL DISENO, ERA EL METODO. Se hicieron nueve changes, cada uno probado,
// y varios verificados con capturas. Pero las capturas eran **de la aplicacion propia**:
// decian «no desborda» y «el versiculo sale», nunca «esto se parece a lo que te
// ensenaron». La herramienta que faltaba se uso para lo facil. Faltaba poner la captura al
// lado y recorrer **esta misma lista**, que es lo que esta arriba y es lo que se recorre en
// `openspec/changes/el-marco-de-estudio/specs/marco/spec.md`.
//
// ============================================================================
// LOS CINCO DESTINOS, Y POR QUE CINCO Y NO NUEVE
// ============================================================================
//
// Logos tiene nueve en su panel: Panel de Control, Biblioteca, Buscar, Biblia, Asistente
// de estudio, Enciclopedia biblica, Guias de Estudio, Notas y Herramientas.
//
// Aqui hay **cinco**, y son cinco porque son los que existen:
//
//     Biblia        la pantalla de lectura, que es la que esta abierta
//     Buscar        la pantalla de busqueda
//     Lexico        el indice de palabras del `.amod`, que ya funciona
//     Comentarios   el modulo de comentario, que ya se puede abrir al lado
//     Biblioteca    los modulos, que es donde se baja el texto
//
// Y LOS OTROS CUATRO NO SE PONEN, y no por pereza:
//
//   - «Asistente de estudio», «Enciclopedia biblica», «Guias de Estudio» y «Herramientas»
//     **no tienen nada detras**. En Logos cada uno abre un producto. Un destino que no
//     lleva a ninguna parte es peor que un destino que no existe, porque enseña a usar la
//     aplicacion con una promesa que no se puede cumplir.
//
//   - «Panel de Control» es la pagina de inicio con recomendaciones, y necesita una cuenta.
//     Este proyecto ya tiene escrito que no hay cuentas.
//
//   - «Tienda» y «Entrenos» son tintoreria comercial, y tambien esta escrito que no hay
//     compras ni anuncios. Eso no es una carencia: es una decision.
//
// ============================================================================
// Y EL CORTE DE ANCHO, MEDIDO
// ============================================================================
//
// Mirada la captura responsive de Logos a 768 px: **no hay panel lateral**. Hay una barra
// de iconos abajo y un campo «Introduzca un pasaje o busqueda» a su derecha. Mirada la de
// escritorio a 1920 px: panel con los nombres, de unos 200 px.
//
// El corte va en [Medidas.anchoParaPanelDeHerramientas], 1100 px, y no en 900 porque con
// nombres el panel mide unos 200 px y la columna de lectura no puede bajar de los 900.

import 'package:flutter/material.dart';

import 'package:ab/ui/core/tema.dart';

/// A donde va el marco.
enum DestinoDeEstudio {
  biblia('Biblia', Icons.auto_stories_outlined, Icons.auto_stories),
  buscar('Buscar', Icons.search, Icons.search),
  lexico('Léxico', Icons.menu_book_outlined, Icons.menu_book),
  comentarios('Comentarios', Icons.forum_outlined, Icons.forum),
  biblioteca('Biblioteca', Icons.library_books_outlined, Icons.library_books);

  const DestinoDeEstudio(this.rotulo, this.icono, this.iconoElegido);

  /// Lo que se ve escrito al lado del icono.
  ///
  /// Y EN CASTELLANO Y SIN TILDES EN EL CODIGO. Las tildes estan en el codigo fuente y se
  /// ven bien; el problema son los ficheros que se leen en una terminal sin suporte, y este
  /// proyecto escribe sus textos sin acentos por decision. La pantalla **si** los lleva, y
  /// por eso el rotulo va aqui y no construido con `String.fromCharCodes`.
  final String rotulo;

  final IconData icono;
  final IconData iconoElegido;
}

/// El marco.
///
/// Y **NO** COLOCA EL CAMPO DE REFERENCIA, y es una decision medida. La primera version de
/// este fichero lo llevaba: en pantalla estrecha iba en la barra de abajo, que es donde lo
/// tiene la captura responsive de Logos, y en la cabecera con panel.
///
/// Medido a 360 px con los cinco destinos: cinco `IconButton` de Material son de 48 px
/// --el minimo que el framework considera pulsable con el dedo-- y son **240 px**. De 360
/// quedan **98 px** para el campo, y el campo no cabe en 98 px ni el texto "Juan 3:16" con
/// sus dos iconos de sufijo. La prueba lo midiо: `98.0`, y el campo entero son 280.
///
/// Y ADEMAS NO SON EL MISMO CAMPO. El de la barra de Logos es una busqueda global --
/// «Introduzca un pasaje o busqueda»-- y el de la cabecera es **la referencia del panel**, el
/// pasaje que se esta leyendo. Meter el segundo donde estaba el primero seria cambiar de
/// sitio un control por parecerse a otro.
///
/// Asi que el campo se queda en la cabecera del panel en los dos anchos, y la barra de abajo
/// lleva los destinos. Lo que cambia con el ancho es el marco: panel lateral o barra.
class MarcoDeEstudio extends StatelessWidget {
  const MarcoDeEstudio({
    super.key,
    required this.destino,
    required this.alElegirDestino,
    required this.hijo,
  });

  final DestinoDeEstudio destino;
  final void Function(DestinoDeEstudio destino) alElegirDestino;

  /// Lo que hay en el centro: la pantalla que esta abierta.
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final ancho = c.maxWidth;
        final conPanel = ancho >= Medidas.anchoParaPanelDeHerramientas;

        if (conPanel) {
          return AnchoDeEstudio(
            hayPanelDeHerramientas: true,
            ancho: ancho,
            child: Row(
              children: <Widget>[
                // Y ESTE **NO** ESTA DENTRO DEL SCAFFOLD, y por eso necesita su propio
                // `Material`. El `Scaffold` pone el suyo en la barra y en el cuerpo, y el
                // marco vive **fuera** de el.
                Material(
                  child: _PanelDeHerramientas(
                    destino: destino,
                    alElegir: alElegirDestino,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: hijo),
              ],
            ),
          );
        }

        return AnchoDeEstudio(
          hayPanelDeHerramientas: false,
          ancho: ancho,
          child: Column(
            children: <Widget>[
              Expanded(child: hijo),
              _BarraDeAbajo(destino: destino, alElegir: alElegirDestino),
            ],
          ),
        );
      },
    );
  }
}

/// Si este marco tiene panel de herramientas lateral.
///
/// Y VA POR [InheritedWidget] Y NO POR UN PARAMETRO DE CADA PANTALLA, porque la pregunta
/// que se hace es **«donde coloco yo mi campo»**, y la respuesta depende de la pantalla
/// que hay dentro. Si el marco lo dijera por parametro, cada pantalla que dibujase un
/// campo tendria que recibir el ancho, decidir por su cuenta, y se equivocaria de una
/// forma distinta cada vez que el corte cambiara.
class AnchoDeEstudio extends InheritedWidget {
  const AnchoDeEstudio({
    super.key,
    required this.hayPanelDeHerramientas,
    required this.ancho,
    required super.child,
  });

  final bool hayPanelDeHerramientas;
  final double ancho;

  static AnchoDeEstudio of(BuildContext context) {
    final encontrado =
        context.dependOnInheritedWidgetOfExactType<AnchoDeEstudio>();
    // Y SI NO HAY MARCO, SE ASUME QUE NO HAY PANEL, que es lo que se ve si una pantalla se
    // monta sola en una prueba. Es la situacion mas estrecha y la que menos sitio quita.
    if (encontrado == null) {
      return const AnchoDeEstudio(
        hayPanelDeHerramientas: false,
        ancho: 360,
        child: SizedBox.shrink(),
      );
    }
    return encontrado;
  }

  @override
  bool updateShouldNotify(AnchoDeEstudio anterior) =>
      hayPanelDeHerramientas != anterior.hayPanelDeHerramientas ||
      ancho != anterior.ancho;
}

/// El panel lateral con los nombres.
///
/// Y `NavigationRail` extendido, que ya trae elBehavior de Material: fondos, estados de
/// hover y foco, y el `tooltip` de cada icono. Es exactamente la pieza que hace Logos, y
/// hacerla a mano habria sido rehacer un menu con mal comportamiento de teclado.
class _PanelDeHerramientas extends StatelessWidget {
  const _PanelDeHerramientas({required this.destino, required this.alElegir});

  final DestinoDeEstudio destino;
  final void Function(DestinoDeEstudio destino) alElegir;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return NavigationRail(
      extended: true,
      // Y **SIN** `minWidth`, porque con `extended: true` tiene que ser `null`:
      //
      //     Failed assertion: line 118 pos 15: 'minWidth == null || minWidth > 0'
      //
      // Con la barra normal el ancho minimo se usa; con la extendida manda
      // `minExtendedWidth`. Poner `minWidth: 0` para "quitar el margen" no quita nada y
      // rompe la asercion.
      // Y EL MINIMO **ES [Medidas.anchoDelPanelDeHerramientas]**, y no un 176 escrito aqui.
      //
      // El motivo es que ese numero no lo usa solo este panel: lo usa **quien reparte la
      // lectura**, y es decir, el enrutador al decidir cuantos paneles de texto caben. Con un
      // 176 aqui y un 226,5 en `Medidas`, los dos son el mismo ancho medido en dos sitios, y
      // el dia que el mas largo --"Comentarios"-- crezca una letra, el panel se ensancha y
      // **la cuenta de paneles sigue con el numero viejo**: salen tres columnas donde solo
      // caben dos, y cada una por debajo del ancho de lectura que decide que se puede leer.
      //
      // Con el minimo aqui, el panel mide exactamente lo que `Medidas` dice, y los dos
      // sitios no pueden separarse porque son el mismo numero.
      minExtendedWidth: Medidas.anchoDelPanelDeHerramientas,
      selectedIndex: destino.index,
      onDestinationSelected: (int i) => alElegir(DestinoDeEstudio.values[i]),
      backgroundColor: colores.surfaceContainerLow,
      destinations: <NavigationRailDestination>[
        for (final d in DestinoDeEstudio.values)
          NavigationRailDestination(
            icon: Icon(d.icono),
            selectedIcon: Icon(d.iconoElegido),
            label: Text(d.rotulo),
          ),
      ],
    );
  }
}

/// La barra de abajo, que es lo que hay en la captura responsive de Logos.
class _BarraDeAbajo extends StatelessWidget {
  const _BarraDeAbajo({required this.destino, required this.alElegir});

  final DestinoDeEstudio destino;
  final void Function(DestinoDeEstudio destino) alElegir;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    // Y TAMBIEN CON SU `MATERIAL`, y por el mismo motivo: la barra de abajo es hermana del
    // `Scaffold`, no hija suya. Sin el, un `TextField` dentro lanza al construirse.
    return Material(
      color: colores.surfaceContainer,
      child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colores.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, Medidas.margenEstrecho, 4),
          child: Row(
            children: <Widget>[
              for (final d in DestinoDeEstudio.values)
                IconButton(
                  tooltip: d.rotulo,
                  isSelected: d == destino,
                  icon: Icon(d == destino ? d.iconoElegido : d.icono),
                  selectedIcon: Icon(d.iconoElegido),
                  color: d == destino ? colores.onSurface : colores.outline,
                  onPressed: () => alElegir(d),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}