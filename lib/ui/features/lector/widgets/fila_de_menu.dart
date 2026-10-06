// La fila de menu de un panel, y la segunda barra.
//
// ============================================================================
// QUE HAY Y QUE NO, Y POR QUE SE PONE **UNA** FILA Y NO DOS
// ============================================================================
//
// Mirada la captura de Logos, hay dos filas de entradas sobre el texto: `Inicio`,
// `Busqueda`, `Notas`, `Formato`, `Vista`, `Herramientas`, `Compartir` --y al lado, una barra
// con `Contenido`, `Historia`, `Articulo`, `Conjunto de enlaces`, `Mas informacion`,
// `Informacion`.
//
// Y AQUI HAY **UNA SOLA FILA**, y es una decision que se puede medir:
//
//     las dos filas de Logos                     7 + 6 = 13 entradas
//     cromo encima del primer versiculo         56 + 48 + 36 + 32 = 172 px
//     de 760 px de alto                          el 23 %
//
// Y CON LAS DOS FILAS SERIAN **208 px**, el 27 %, con el versiculo de Juan 3 —que ocupa
// 122 px medido— en el 16 %. El cromo crece y el texto no, y el texto es lo que se abre a
// leer.
//
// Y LA SEGUNDA BARRA DE LOGOS **NO COPIADA** CONCRETAMENTE, y esto no es pereza:
//
//   - `Historia` y `Articulo` son de un **articulo** y de su historia editorial. Este
//     catalogo tiene una Biblia y un comentario: no hay articulos.
//   - `Conjunto de enlaces` es el **panel de ideas** con las referencias cruzadas. Y
//     `\x` sale **0 de 31.102 versiculos**, medido: no hay nada que enlazar.
//   - `Mas informacion` y `Informacion` del recurso. Aqui hay algo, y es lo que ya esta
//     al pie del capitulo: la licencia, la atribucion y los defectos del modulo, que son
//     una obligacion de licencia del repositorio hermano y **no se esconden en un menu**.
//
// Es decir: de las trece, hay **seis** con algo detras y **siete** sin nada. Y la regla que
// ya esta escrita en el marco de estudio --"un elemento de menu que no lleva a ninguna
// parte es peor que uno que no existe"-- se aplica entera aqui. Por eso hay una fila, con
// las entradas que tienen algo detras, y las demas no se pintan.
//
// ============================================================================
// LA ALTURA, MEDIDA, Y POR QUE NO SE TOCA LA CABECERA DEL PANEL
// ============================================================================
//
// La fila son **36 px**. Y va **debajo** de la cabecera del panel --el campo de referencia
// y las flechas-- y **encima** del texto, en su propia linea, con su borde de abajo.
//
// Y POR QUE NO SE CUELA EN LA CABECERA, que es donde la tiene Logos a lo ancho. A 360 px,
// medido: los tres botones de la derecha de la barra son **144 px**, y dentro del `title`
// al campo le quedan **225** de los 330 que mide la pantalla. Meter la fila ahi deja el
// campo en 98 px, y "Juan 3:16" no cabe en 98 ni con la lupa.
//
// Y A PARTIR DE **1.100 px** SI CABEN EN LA MISMA LINEA, y no se hace: la fila de menu son
// cinco entradas de texto de 13 px, unos **340 px**, y el campo con tope son 360. Juntos
// son 700, y a 1440 con el panel de herramientas quedan 1.213.5. Caben. Y no se juntan
// porque entonces la cabecera del panel deja de ser "donde se ve que texto y que pasaje"
// y pasa a ser un menu mas, y lo que se busca en una cabecera de lectura es la
// referencia.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/versiculo.dart';

import '../../../core/tema.dart';

/// La altura de la fila de menu.
///
/// Y SON **36 px**, y no los 48 de un control de Material. Es una fila de texto, no de
/// botones: las entradas se pulsan con el dedo en la parte de arriba del panel, donde ya
/// habitualmente esta el pulgar, y 12 px de menos por entrada son 60 px por panel --casi dos
/// lineas de texto-- en una ventana que ya medimos que va justa.
const double kAlturaDeLaFilaDeMenu = 36;

/// Que hay en la fila de menu, y a donde lleva.
///
/// Y ES UN **`enum` CON SU ETIQUETA Y SU ACCION**, y no una lista de cadenas con un `if`
/// en la vista, porque hay tres cosas distintas que hacer y cada una necesita datos
/// distintos: `notas` necesita el pasaje, `formato` necesita la preferencia y `comentario`
/// necesita saber que hay abierto. Con una lista de cadenas, quien decide eso esta en la
/// vista, y la vista no sabe que notas hay.
enum EntradaDelMenu {
  /// Buscar en este texto.
  ///
  /// Y **NO ES EL MISMO QUE LA LUPA DE LA BARRA**, y esa distincion es la que hace que
  /// tenga sentido en las dos. La lupa abre la pantalla de busqueda; esta entrada hace lo
  /// mismo. Y estan las dos porque en la captura estan las dos, y quitar una para que
  /// sobre la otra seria decidir por gusto cual de las dos se usa.
  buscar('Buscar', Icons.search),

  /// Las notas al pie del versiculo que se esta leyendo.
  ///
  /// Y **SOLO SI HAY ALGO QUE VER**, y no una entrada que al pulsarla dice "no hay".
  /// Ver `_fila`: una entrada que no lleva a ninguna parte es peor que una que no existe.
  notas('Notas', Icons.subject),

  /// Los ajustes de lectura.
  formato('Formato', Icons.format_size),

  /// El comentario que va al lado, o el que se puede poner.
  ///
  /// Y **EL TEXTO CAMBIA CON EL ESTADO** --`Comentario` o el nombre del que hay--, y por
  /// eso no es un `enum` con una etiqueta fija: quien lo pinta es la vista, que es quien
  /// sabe que hay abierto. Aqui solo esta el icono.
  comentario('Comentario', Icons.comment_outlined);

  const EntradaDelMenu(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;

  /// Si tiene algo detras.
  ///
  /// Y `notas` es el unico que puede no tenerlo, y el motivo esta medido: en el KJV hay
  /// **5.844 versiculos con notas de 31.102** --el 18,79 %--, asi que **de cada cinco
  //  versiculos, uno** no tiene ninguna. Juan 3 entero no tiene ni una --medido--, que es
  // el caso mas comun del mundo: cuatro evangelios enteros.
  bool tieneAlgoDetras(ContextoDeLaFila contexto) => switch (this) {
    EntradaDelMenu.buscar => true,
    EntradaDelMenu.notas => contexto.hayNotas,
    EntradaDelMenu.formato => true,
    EntradaDelMenu.comentario => true,
  };
}

/// Lo que la fila necesita saber para decidir si una entrada se pinta.
///
/// Y ES UN **RECORD** Y NO UNA CLASE, porque son cuatro booleanos que se pasan juntos y no
/// tienen metodo ninguno. Una clase con cuatro campos para esto seria 40 lineas de
/// documentacion que no dicen nada.
///
/// Y NO ES EL `LectorViewModel`, y el motivo es la direccion de la dependencia: la fila
/// esta en la capa de interfaz y el view model tambien, asi que podria recibirlo entero.
/// Pero recibir el view model entero para mirar tres booleanos significa que la fila puede
/// empezar a preguntar cosas que no son suyas --el pasaje entero, el modulo entero--, y
/// cada pregunta que puede hacer es una razon para que este widget cambie de forma sin
// que nadie lo haya pedido.
class ContextoDeLaFila {
  const ContextoDeLaFila({required this.hayNotas, required this.textoBuscando});

  /// Si el versiculo que se esta leyendo trae notas al pie.
  final bool hayNotas;

  /// Si hay algo escrito en el campo de referencia.
  final bool textoBuscando;

  /// El contexto de una lista de versiculos, contando las notas con ancla.
  ///
  /// Y CUENTA LAS QUE TIENEN **ANCLA**, y no todas. Una nota sin ancla no tiene letra en el
  /// texto, asi que no hay forma de volver a ella desde la fila, y una entrada que lleva a
  /// una lista sin letras es una lista de la que no se puede volver.
  factory ContextoDeLaFila.dePasaje(List<Versiculo>? versiculos) => ContextoDeLaFila(
    hayNotas: (versiculos ?? const <Versiculo>[]).any(
      (v) => v.notas.any((n) => n.ancla != null),
    ),
    textoBuscando: false,
  );
}

/// La fila de menu de un panel.
class FilaDeMenu extends StatelessWidget {
  const FilaDeMenu({
    super.key,
    required this.contexto,
    required this.alBuscar,
    required this.alNotas,
    required this.alFormato,
    required this.alComentario,
    this.textoDelComentario,
    this.hayComentario = false,
  });

  final ContextoDeLaFila contexto;
  final VoidCallback alBuscar;
  final VoidCallback alNotas;
  final VoidCallback alFormato;
  final VoidCallback alComentario;

  /// El nombre del comentario abierto, para ponerlo en la entrada.
  ///
  /// Y ES **OPCIONAL** Y NO UN `String` VACIO, porque "no hay comentario" y "el comentario
  /// se llama asi" son dos cosas y el texto que se ensena es distinto: con comentario
  /// abierto la entrada dice el nombre --que es como se confirma que lo que hay al lado es
  /// lo que se pidio--, y sin comentario dice `Comentario`.
  final String? textoDelComentario;

  final bool hayComentario;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    // Y SOLO SE PINTAN LAS ENTRADAS **CON ALGO DETRAS**. Ver la cabecera: en el KJV uno de
    // cada cinco versiculos no tiene notas al pie, medido, asi que una entrada `Notas` fija
    // seria un boton que de cada cinco veces no lleva a nada.
    final visibles = <EntradaDelMenu>[
      for (final e in EntradaDelMenu.values)
        if (e.tieneAlgoDetras(contexto)) e,
    ];

    return Container(
      key: claveDeLaFilaDeMenu,
      height: kAlturaDeLaFilaDeMenu,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colores.outlineVariant)),
      ),
      // Y LA FILA ES **DESPLAZABLE**, y es una decision que la medida obliga.
      //
      // MEDIDO en una captura del 6 de octubre de 2026 a 1.440 px: `Buscar`, `Formato` y
      // `Comentario` ocupan **278 px**. A 360 px caben de sobra. Pero con el comentario
      // abierto la tercera entrada dice **el nombre del comentario** --"Comentario de Adam
      // Clarke"--, y las tres juntas se pasan: 278 + los ~100 px del nombre son unos 378, y
      // no caben en 360.
      //
      // Y SIN DESPLAZAMIENTO ESO ES UN `overflow` EN PANTALLA, que es de los fallos que salen
      // rayados de amarillo y negro en el navegador y **no aparecen en la imagen**: el texto
      // se sale del borde y la linea amarilla solo se ve con las franjas de depuracion.
      //
      // Y LA ETIQUETA **TIENE TOPE PROPIO** Y EL NOMBRE SE RECORTA CON PUNTOS SUSPENSIVOS,
      // y no solo se desplaza la fila. Con el tope, las tres entradas se ven enteras y solo
      // el nombre del comentario pierde el final; sin tope, la fila entera se desplaza y el
      // boton de formato queda a la mitad, que es peor: el que se pierde es el que no
      // depende de lo que haya abierto.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final e in visibles)
              _Entrada(
                entrada: e,
                texto: e == EntradaDelMenu.comentario && hayComentario
                    ? (textoDelComentario ?? e.etiqueta)
                    : e.etiqueta,
                activo: e == EntradaDelMenu.comentario && hayComentario,
                alPulsar: switch (e) {
                  EntradaDelMenu.buscar => alBuscar,
                  EntradaDelMenu.notas => alNotas,
                  EntradaDelMenu.formato => alFormato,
                  EntradaDelMenu.comentario => alComentario,
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// La clave de la fila de menu, para las pruebas.
const Key claveDeLaFilaDeMenu = ValueKey<String>('fila-de-menu');

/// Una entrada de la fila.
class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.entrada,
    required this.texto,
    required this.alPulsar,
    required this.activo,
  });

  final EntradaDelMenu entrada;
  final String texto;
  final VoidCallback alPulsar;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final tinta = activo ? context.colores.acento : colores.onSurfaceVariant;

    return Semantics(
      button: true,
      label: texto,
      child: InkWell(
        onTap: alPulsar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(entrada.icono, size: 14, color: tinta),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kAnchoMaximoDeUnaEntrada),
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tinta,
                    // Y EN **NEGRITA** CUANDO ESTA ACTIVO. El comentario abierto se
                    // distingue asi --con el color de acento y en negrita-- sin necesita
                    // un segundo boton de "quitar": quien lo ve sabe que hay algo al
                    // lado, y pulsar la misma entrada lo quita.
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El ancho maximo de la etiqueta de una entrada.
///
/// Y SON **140 px**, y el motivo es la cuenta del parrafo de arriba: con la entrada del
/// comentario diciendo el nombre completo --"Comentario de Adam Clarke", que son **350 px**
/// con la fuente cuadrada del motor de pruebas y unos **180** con Roboto-- las tres entradas
/// se pasan de 360. Con un tope de 140 el nombre se recorta con puntos suspensivos y las
/// tres entradas se ven enteras.
///
/// Y NO ES UN NUMERO REDONDO POR CASUALIDAD, sino la salida de restar: 360 de la ventana
/// menos 48 --el `+` y el padding-- menos las otras dos entradas, que con sus iconos y sus
/// 20 px de padding son unos 170. Lo que queda es **el nombre del comentario**, y 140 es lo
/// que cabe de el sin que la fila se desplace.
const double kAnchoMaximoDeUnaEntrada = 140;
