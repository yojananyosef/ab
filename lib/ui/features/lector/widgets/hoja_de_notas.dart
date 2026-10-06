// La hoja con las notas al pie del versiculo que se esta leyendo.
//
// ============================================================================
// QUE ES Y POR QUE NO ES LA LISTA DEL PIE
// ============================================================================
//
// Al pie del capitulo, en la pantalla de lectura, esta **la lista completa** de las notas del
// capitulo: medido sobre el KJV real, **6.959 notas en 5.844 versiculos**, en **913
// capitulos**, con una media de **7,6** por capitulo y un maximo de **35** en Daniel 11.
//
// Y ESO ES LO QUE HACE QUE ESTA HOJA SEA OTRA COSA, y no un duplicado:
//
//   - La lista del pie es de **todo el capitulo** y esta es del **versiculo**. En un
//     capitulo con 7,6 notas de media, quien esta leyendo el versiculo 16 quiere las
//     **suyas**, y tener que bajar al final del capitulo para saber cuales son es un viaje
//     en balde.
//   - El pie lleva la letra y el texto. Esta lleva **a que versiculo** es cada nota, porque
//     un capitulo con 35 notas sin numero de versiculo es un muro de parrafos sin dueño.
//
// Y CUANDO NO HAY NOTAS, **NO SE ABRE NADA**. La entrada `Notas` de la fila de menu no se
// pinta si el versiculo no tiene ninguna --ver `fila_de_menu.dart`--, asi que esta hoja no
// tiene el caso de "no hay ninguna" al abrirse. Y se comprueba igual, porque un
// `showModalBottomSheet` sin `if` devuelve una hoja vacia y quien la ve no sabe si es un
// fallo o si no hay.
//
// ============================================================================
// Y CUANTAS NOTAS HAY EN UN VERSICULO, QUE ES EL MAXIMO DE ESTA HOJA
// ============================================================================
//
// Medido sobre los 6.959 notas del KJV: **la maxima por versiculo es 3**, y la mayoria
// tienen una. Y no es una suposicion de que "un versiculo tiene una nota": son las notas
// por capitulo las que llegan a 35, y dentro de un versiculo el numero es pequeno. Por eso
// esta hoja no necesita scroll: la peor lista que puede pintar son tres lineas.
//
// Y SE DICE EL **VERDADERO** NUMERO DE LA PEOR LISTA, porque si mañana un modulo trae
// treinta notas en un versiculo, esta hoja tiene que poder
// pintar mas sin que nadie lo note. Con `mainAxisSize.min` y un `ListView` dentro, una hoja de
// treinta notas tambien sale bien: lo que no sale bien es una hoja **fija** de tres lineas
// con el resto cortado sin scroll.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/nota_al_pie.dart';
import 'package:ab/domain/models/versiculo.dart';
import 'package:ab/ui/core/tema.dart';

/// El numero maximo de notas de un versiculo, medido.
///
/// Y ESTE **3** ESTA MEDIDO SOBRE LOS 6.959, y no estimado. Sale de agrupar las notas por
/// versiculo y quedarse con el maximo, que es 3. Y **NO ES UN LIMITE QUE SE IMPONGA**:
/// esta hoja no recorta nada, y si un modulo trajera mas de tres en un versiculo las
// pinta todas. El numero esta aqui para saber que el caso normal cabe de sobra y para
/// que un cambio en el parser --uno que duplique las notas-- se note en una prueba y no
/// en una hoja con treinta lineas.
const int maximoDeNotasPorVersiculo = 3;

/// Abre la hoja de notas del versiculo que se esta leyendo.
///
/// Y **DEVUELVE UN `bool`** y no un `void`, y no es por simetria: quien la abre necesita
/// saber si se ha abierto, porque la entrada `Notas` de la fila se decide antes de pulsar
/// y si entre medias el pasaje cambia --que ocurre al pasar de capitulo-- la hoja puede
/// quedar pidiendo datos que ya no son los del versiculo que se esta viendo. Un `void`
/// obligaria a comprobar el estado del view model desde fuera, y eso es la regla que este
/// proyecto tiene escrita: "una peticion que no tiene sentido no devuelve una lista vacia,
/// lanza".
Future<bool> mostrarHojaDeNotas({
  required BuildContext context,
  required List<Versiculo> versiculos,
  required String titulo,
}) async {
  final grupos = notasDelPasaje(versiculos);
  final total = grupos.fold<int>(0, (int suma, NotaDeUnVersiculo g) => suma + g.notas.length);

  // Y **ANTES** DE `showModalBottomSheet`. Abrir una hoja y cerrarla en el mismo frame es
  // un parpadeo: la hoja aparece y desaparece, y en un movil eso se ve como un fallo. Y
  // ademas es una hoja vacia, que es la forma de que alguien piense que la aplicacion no
  // ha encontrado las notas cuando lo que no ha encontrado es un motivo para abrir la hoja.
  if (grupos.isEmpty) return false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _HojaDeNotas(grupos: grupos, titulo: titulo, total: total),
  );
  return true;
}

/// Las notas con ancla del pasaje, agrupadas por versiculo y en orden de aparicion.
///
/// Y ES UNA FUNCION SUELTA Y NO UN METODO DE LA HOJA, porque quien la necesita es quien
/// decide si se abre --la entrada de la fila de menu--, y esa decision se toma en la
/// pantalla, no dentro de una hoja que todavia no existe.
///
/// Y **CUENTA LAS QUE TIENEN ANCLA**, y no todas. Una nota sin ancla no tiene letra en el
/// texto, y esta hoja existe para poder volver a la nota desde el versiculo: sin letra, la
/// nota es un parrafo suelto.
///
/// Y DEVUELVE **GRUPOS Y NOTAS SUELTAS**, y no una lista plana. El grupo es lo que sabe
/// el **versiculo** --su numero--, que es lo que no esta en la nota: `NotaAlPie` lleva la
/// letra, el texto y el ancla, y **no** el numero de versiculo, porque es el versiculo el
/// que lo tiene y duplicarlo aqui seria el mismo dato en dos sitios con dos fuentes. Y el
/// numero es justo lo que hace falta en pantalla: un capitulo con 35 notas sin saber a que
/// versiculo corresponde cada una es un muro de parrafos sin dueno.
///
/// Y LA CLAVE DEL GRUPO ES UN **REGISTRO CON DOS CAMPOS**, y no una clase, porque no tiene
/// metodo ninguno y una clase con dos campos serian 30 lineas de documentacion.
class NotaDeUnVersiculo {
  const NotaDeUnVersiculo({required this.versiculo, required this.notas});

  /// El versiculo al que se refieren estas notas.
  final int versiculo;

  /// Las notas, con su letra, en orden de aparicion.
  final List<NotaAlPie> notas;
}

/// Las notas del pasaje, agrupadas por versiculo.
List<NotaDeUnVersiculo> notasDelPasaje(List<Versiculo> versiculos) {
  final salida = <NotaDeUnVersiculo>[];
  for (final v in versiculos) {
    // Y UN VERSICULO SIN TEXTO NO TIENE NOTAS QUE MOSTRAR. Una nota al pie glosa el
    // versiculo: sin versiculo no hay nada que glosar, y el caso sale cuando el pasaje
    // esta en blanco.
    if (v.texto.isEmpty) continue;
    final conAncla = <NotaAlPie>[
      for (final n in v.notas)
        if (n.ancla != null) n,
    ];
    if (conAncla.isEmpty) continue;
    salida.add(NotaDeUnVersiculo(versiculo: v.numero, notas: conAncla));
  }
  return salida;
}

/// La hoja.
class _HojaDeNotas extends StatelessWidget {
  const _HojaDeNotas({
    required this.grupos,
    required this.titulo,
    required this.total,
  });

  final List<NotaDeUnVersiculo> grupos;
  final String titulo;

  /// Cuantas notas hay en total, en todos los versiculos.
  final int total;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final colores = context.colores;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenEstrecho,
              0,
              Medidas.margenEstrecho,
              4,
            ),
            // Y EL TITULO **DICE QUE SON LAS NOTAS DE UN VERSICULO**, y no "Notas".
            //
            // El motivo es que esta hoja y la lista del pie del capitulo se parecen mucho,
            // y quien las ve las dos sin diferencia cree que son lo mismo. El pie es de todo
            // el capitulo --son 7,6 de media-- y esta es del versiculo que se esta leyendo.
            // Decirlo en el titulo es lo que evita abrir una, leer, y no saber cual de las
            // dos se ha abierto.
            child: Text('Notas de $titulo', style: tema.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenEstrecho,
              0,
              Medidas.margenEstrecho,
              Medidas.margenEstrecho,
            ),
            // Y EL **NUMERO**, y no un "hay notas". Con 7,6 de media por capitulo y un
            // maximo de 35, saber cuantas son antes de leerlas decide si compensa mirar
            // la hoja: quien abre una nota al pie de Juan 3 quiere el versiculo y su glosa,
            // no ocho parrafos.
            child: Text(
              total == 1 ? '1 nota' : '$total notas',
              style: tema.bodySmall?.copyWith(color: colores.textoSuave),
            ),
          ),
          Flexible(
            // Y `Flexible` CON `ListView`, y no una `Column` sola. El caso normal --tres
            // notas-- cabe de sobra y no hace falta nada mas; pero si un modulo trae
            // treinta notas en un versiculo, una `Column` en una hoja sin scroll las
            // empuja fuera de la pantalla y no hay forma de verlas. Con `Flexible`, la
            // hoja crece hasta donde puede y a partir de ahi desplaza.
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenEstrecho,
                0,
                Medidas.margenEstrecho,
                Medidas.margenAncho,
              ),
              children: <Widget>[
                for (final g in grupos)
                  for (final n in g.notas) _NotaDeLaHoja(nota: n, versiculo: g.versiculo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una nota en la hoja, con su letra y el versiculo al que se refiere.
class _NotaDeLaHoja extends StatelessWidget {
  const _NotaDeLaHoja({required this.nota, required this.versiculo});

  final NotaAlPie nota;
  final int versiculo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final colores = context.colores;

    // Y LA LETRA **ADEMAS DEL NUMERO**, y no uno de los dos. El numero del versiculo es lo
    // que hace falta para saber **a que** se refiere, que es lo que no se sabe leyendo
    // una nota suelta; y la letra es lo que remite desde el texto, que es lo que hace falta
    // para volver. Con las dos, esta hoja y el pie del capitulo se leen juntos.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                nota.letra,
                style: tema.labelMedium?.copyWith(
                  color: colores.acento,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'versiculo $versiculo',
                style: tema.labelSmall?.copyWith(color: colores.textoSuave),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Y EL CUERPO EN `bodyMedium` A 14, IGUAL QUE LA LISTA DEL PIE. Es la misma
          // informacion y tiene que leer igual: si esta hoja lamase un punto por estar
          // en una hoja, entonces las dos glosas de la misma nota se verian distintas y
          // alguien pensaria que son dos textos.
          Text(
            nota.texto,
            style: tema.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
            softWrap: true,
            semanticsLabel: 'Nota ${nota.letra} sobre el versiculo $versiculo',
          ),
        ],
      ),
    );
  }
}