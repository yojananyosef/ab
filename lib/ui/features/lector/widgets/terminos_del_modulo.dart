// Los terminos del modulo, a la vista y sin menus.
//
// ============================================================================
// POR QUE ESTO NO ES UNA PANTALLA DE "ACERCA DE"
// ============================================================================
//
// El repositorio hermano --el que construye los `.amod`-- declaro que cada modulo
// lleve en su tabla `info` su `copyright`, su `attribution`, su `license`, su
// `license_evidence`, sus `defects` y su `versification`. Los declaro **para que la
// app los ensene**, y una obligacion que hay que ir a buscar a un menu no se
// cumple: se cumple mostrandola.
//
// Que es exactamente lo que hacen los lectores que la cumplen bien. Los que la
// incumplen ponen "KJV" en un desplegable junto al nombre del texto y dan por hecho
// que nadie lo abre. Aqui esta en la propia pantalla de lectura, y se llega sin
// pulsar nada.
//
// Y LA REGLA DE LA TAREA 7.11 SE TOMA EN EL SENTIDO ESTRICTO. Decia "accesibles en
// un solo toque", y se podria hacer un desplegable de un toque. Se hace sin toque:
// todo visible. Un toque es un obstaculo, y aqui no hay nada que ganar con un
// obstaculo: lo que hay es una ficha de cuatro lineas que cabe al final del capitulo y
// que se lee de un vistazo.
//
// ============================================================================
// SI EL INDICE Y EL TEXTO NO DICEN LO MISMO, MANDA EL TEXTO
// ============================================================================
//
// `catalog.json` dice una licencia y la tabla `info` del modulo dice otra. Puede
// pasar: el indice es un puntero y un puntero se puede quedar viejo o equivocado.
// El modulo es lo que se esta leyendo, y es lo que va a citar quien cite.
//
// Asi que se ensena **la del modulo** y se avisa de que discrepan las dos, con las
// dos a la vista. No se elige una y se calla la otra: si solo se ensena una de las
// dos, alguien que tenga el manifiesto delante ve una contradiccion sin explicacion,
// y lo que hace con una contradiccion sin explicacion es no fiarse de nada.
//
// ============================================================================
// Y LOS DEFECTOS SE DICEN CON NUMERO
// ============================================================================
//
// Un modulo puede llegar con `defects_count` de 3, y eso significa que tres
// versiculos vienen incompletos. Se dice "este texto tiene 3 versiculos incompletos" y
// el texto de `defects`, si lo hay. Un icono de aviso no dice cuantos, y sin saber
// cuantos no se puede decidir si merece la pena.
//
// Y CON CERO NO APARECE NADA. Un aviso que aparece cuando no hay nada molesta, y
// uno que no aparece cuando hay algo oculta. Y `defects_count` ausente y
// `defects_count` de cero son cosas distintas: la primera significa "el modulo no lo
// dice" y la segunda "el modulo dice que no tiene ninguno".

import 'package:flutter/material.dart';

import 'package:ab/domain/models/terminos.dart';

import '../../../core/tema.dart';

/// Los terminos del modulo, tal como se ensenan.
///
/// Y SI NO HAY NINGUNO, NO SE ENSENA NADA. Un modulo que no declara nada no tiene
/// ficha, y poner una ficha vacia con "sin licencia" seria inventar un dato que no
/// esta ahi. No se ensena nada y ya esta.
class TerminosDelModulo extends StatelessWidget {
  const TerminosDelModulo({
    super.key,
    required this.terminos,
    required this.discrepancia,
    required this.ruta,
  });

  final Terminos? terminos;
  final DiscrepanciaDeLicencia? discrepancia;

  /// De donde salio el texto. Se ensena porque quien esta leyendo puede necesitar
  /// saberlo --un `.amod` de otra persona, una copia local-- y ese es el caso en el
  /// que mas dudas hay.
  final String ruta;

  @override
  Widget build(BuildContext context) {
    final t = terminos;
    if (t == null) return const SizedBox.shrink();

    final visibles = t.visibles;
    final avisoDeDefectos = t.avisoDeDefectos;
    final d = discrepancia;
    if (visibles.isEmpty && avisoDeDefectos == null && d == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Divider(color: Colores.linea),
        const SizedBox(height: 8),

        if (visibles.isNotEmpty) ...<Widget>[
          Text(
            'Sobre este texto',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (final v in visibles)
            _Termino(etiqueta: v.etiqueta, valor: v.valor),
        ],

        // La discrepancia va **encima** de los terminos y no despues. La razon: lo
        // primero que hay que saber de esta ficha es si es de fiar. Y va con las dos
        // licencias escritas, porque decir "discrepan" sin decir cuales es un aviso
        // que obliga a ir a buscarlas.
        if (d != null) ...<Widget>[
          const SizedBox(height: 8),
          _Aviso(
            icono: Icons.report_gmailerrorred_outlined,
            texto: d.texto,
          ),
        ],

        if (avisoDeDefectos != null) ...<Widget>[
          const SizedBox(height: 8),
          _Aviso(
            icono: Icons.warning_amber_outlined,
            texto: avisoDeDefectos,
          ),
        ],

        const SizedBox(height: 8),
        // La ruta va en letra pequena y **sin** etiqueta, porque es el dato menos
        // interesante de la ficha y lo que mas da es que no estorbe.
        Text(
          ruta,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colores.textoSuave, fontSize: 12),
        ),
      ],
    );
  }
}

/// Un termino y su valor.
class _Termino extends StatelessWidget {
  const _Termino({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      // `Text.rich` y no `RichText` a pelo. Los dos pintan lo mismo, pero `Text.rich`
      // conserva la semantica de texto y lo hace seleccionable, y `RichText` pelado no.
      // Y hay una razon mas practica: un `RichText` no lo encuentra `find.text`, asi
      // que una prueba que buscara "Atribucion" en la pantalla no lo encontraria y
      // concluiria que el termino no se ensena cuando si que se ensena. Con `Text.rich`
      // el texto esta en el sitio de siempre y las pruebas miran lo que se ve.
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$etiqueta: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: valor),
          ],
        ),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colores.textoSuave, height: 1.45),
      ),
    );
  }
}

/// Un aviso: lo que hay que saber antes de leer.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icono, size: 18, color: Colores.peligro),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colores.peligro, height: 1.45),
          ),
        ),
      ],
    );
  }
}

/// El aviso de que un pasaje no existe en esta traduccion, con la salida.
///
/// Y LLEVA UN BOTON, no solo texto. "Juan 5:44 no existe en esta traduccion" es una
/// frase; "Juan 5:44 no existe. El ultimo versiculo anterior es Juan 5:43, aqui"
/// tiene salida. Y el boton va porque un enlace que hay que copiar y pegar a mano es
/// una salida que no es una salida.
///
/// Y EL AVISO NO ES UN ERROR EN ROJO PURO: es un aviso. Un error rojo entero hace
/// pensar que la aplicacion se ha roto, y lo que ha pasado es que esa traduccion
/// tiene 21 capitulos de Juan y se ha pedido el 22.
class AvisoDePasajeInexistente extends StatelessWidget {
  const AvisoDePasajeInexistente({
    super.key,
    required this.texto,
    required this.ultimoValido,
    required this.alIrAlUltimoValido,
  });

  final String texto;

  /// El pasaje que si existe, como texto. Null si no hay ninguno anterior.
  final String? ultimoValido;

  final VoidCallback alIrAlUltimoValido;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colores.fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colores.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.info_outline, size: 18, color: Colores.textoSuave),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texto,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colores.texto, height: 1.45),
                ),
              ),
            ],
          ),
          if (ultimoValido != null) ...<Widget>[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: alIrAlUltimoValido,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('Ir a $ultimoValido'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
