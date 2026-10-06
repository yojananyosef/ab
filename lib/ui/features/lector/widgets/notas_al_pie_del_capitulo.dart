// Las notas al pie del capitulo, al final del texto.
//
// ============================================================================
// POR QUE ESTO ESTA EN UN FICHERE PROPIO Y NO EN LA VISTA
// ============================================================================
//
// La vista del lector ya tiene 1.689 lineas y cuatro widgets privados que son cosas
// distintas: las notas del comentario, los terminos, el numero de capitulo y el marcador.
// Una quinta cosa mas, con su propia regla de estilo y su separacion respecto al texto,
// es un fichero mas.
//
// Y LA REGLA DE SEPARACION ES LA MAS IMPORTANTE DE ESTE FICHERO. Una nota al pie es la
// glosa de un editor del siglo XVII **sobre** el versiculo, y no es el versiculo. Por eso va:
//
//   - en cuerpo mas pequeno, que es la diferencia de tamaño de la que se distingue
//   - con color suave, que es informacion secundaria
//   - con una linea de encima que la separa del texto que glosa
//
// Y eso es exactamente lo que hace la columna de notas del comentario, en `_ColumnaDeNotas`.
// Un lector que pinta las dos en el mismo formato esta enseñando la Escritura y la glosa
// como si fueran lo mismo, y quien lee rapido se lleva la impresion de que Adam Clarke
// estaba citando la Biblia cuando en realidad estaba escribiendo sobre ella.

// No hay logica de negocio aqui: solo pintura. De donde salen las notas lo sabe el
// view model, y el texto del versiculo lo trae el modelo.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/nota_al_pie.dart';
import 'package:ab/domain/models/versiculo.dart';
import 'package:ab/ui/core/tema.dart';

/// Las notas al pie de un capitulo, o nada si no hay ninguna.
///
/// Y DEVUELVE **NADA** Y NO UNA LISTA VACIA, porque una lista vacia pintada es un hueco y un
/// separador con nada encima, que se ve como un fallo de maquetado. Y Juan 3 no tiene ni una
/// nota --medido--, asi que el caso de "no hay lista" no es raro: es el de los cuatro
/// evangelios enteros, Hechos y Romanos, que son el libro que mas se lee.
///
/// Y SE SALTAN LAS NOTAS SIN ANCLA. Una nota sin sitio en el texto se sigue enseñando al
/// pie, pero sin letra: la letra en el texto es la que remite a la nota, y una letra que no
/// esta no puede hacer de remite.
class NotasAlPieDelCapitulo extends StatelessWidget {
  const NotasAlPieDelCapitulo({super.key, required this.versiculos});

  final List<Versiculo> versiculos;

  /// Todas las notas del capitulo, en orden de versiculo y en orden de aparicion.
  ///
  /// Y ESTA LA LISTA COMPLETA Y NO UN FILTRO EN LA VISTA, porque el criterio --"notas que se
  /// pueden mostrar"-- es una pregunta sobre el dato, no sobre como se pinta. Y aqui hay dos
  /// condiciones: que la nota tenga ancla para poder rematar a ella desde el texto, y que el
  /// versiculo tenga texto. Un versiculo sin texto --que sale cuando el pasaje esta en blanco--
  /// no puede tener notas al pie: no hay sobre que glosar.
  List<NotaAlPie> get _notas => <NotaAlPie>[
        for (final v in versiculos)
          if (v.texto.isNotEmpty)
            for (final n in v.notas)
              if (n.ancla != null) n,
      ];

  @override
  Widget build(BuildContext context) {
    final notas = _notas;
    if (notas.isEmpty) return const SizedBox.shrink();

    final tema = Theme.of(context).textTheme;
    final colores = context.colores;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: DecoratedBox(
        // Y LA LINEA DE ENCIMA VA EN EL **CONTENEDOR** Y NO EN CADA NOTA, porque una nota
        // por versiculo con su propia linea pondria quince rayas horizontales en un capitulo
        // con quince notas, y eso es un muro. La separacion va **entre el texto y la lista**.
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colores.linea)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Notas al pie',
                style: tema.titleSmall?.copyWith(color: colores.textoSuave),
              ),
              const SizedBox(height: 8),
              for (final n in notas) _NotaAlPieEnElPie(nota: n),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una nota, con su letra, al pie del capitulo.
class _NotaAlPieEnElPie extends StatelessWidget {
  const _NotaAlPieEnElPie({required this.nota});

  final NotaAlPie nota;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final colores = context.colores;

    // Y LA LETRA Y EL TEXTO VAN EN LA MISMA LINEA, y no la letra en una columna. La letra
    // en columna obligaria a reservar 24 px para un caracter de dos, y a 360 px son 24 px de
    // un total de 260: un 9 % de la nota que se va en dejar hueco.
    //
    // Y LA LETA NO ESTA EN NEGRITA COMO EN UN INDICE, porque aqui no hay indice: el indice
    // de un libro usa negrita para separar visualmente las entradas, y aqui lo que separa es
    // el cuerpo mas pequeno y el color suave, que ya estan puestos.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: tema.bodyMedium?.copyWith(color: colores.textoSuave),
          children: <InlineSpan>[
            TextSpan(
              text: nota.letra,
              style: TextStyle(color: colores.acento, fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: '  '),
            TextSpan(text: nota.texto),
          ],
        ),
        style: tema.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      ),
    );
  }
}