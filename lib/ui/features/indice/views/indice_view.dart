// La pantalla del indice de una palabra del lexicon.
//
// QUE ES Y QUE NO ES, Y POR QUE ESTO NO ES UN DICCIONARIO.
//
// Muestra **donde mas sale una palabra en este texto**. No muestra que significa, y la
// diferencia no es de prudencia sino de dato: el significado de `G2316` esta en un
// diccionario del griego que **no esta en el `.amod`**. Medido el 5 de octubre de 2026: el
// KJV tiene dos tablas, `info` y `verses`, y las trece claves de `info` son nombre,
// licencia, copyright, origen, version, tipo, versificacion y defectos. Ni una de lexicon.
//
// Escribir los significados a mano seria poner en pantalla la opinion de quien los
// escribio. Y quien busca el significado de una palabra es que tiene un diccionario, y
// entonces no lo necesita aqui.
//
// ============================================================================
// Y POR QUE LA LISTA EMPIEZA POR LAS FORMAS DE LA PALABRA Y NO POR LOS VERSICULOS
// ============================================================================
//
// En el KJV, `G2316` sale con cuatro escrituras distintas --`God`, `gods`, `godly` y otra
// vez `God`-- y son cuatro cosas que un usuario que ha pulsado "Dios" quiere saber antes de
// mirar una lista de 1.171 versiculos. Ademas el indice es de **una** traduccion: si solo
// fuera la lista, no tendria nada que la distinga de la de otro texto.
//
// Y EL NUMERO EN GRANDE ARRIBA, porque es lo que la pantalla aporta. Quien pulsa una
// palabra ya sabe que palabra es; lo que no sabe es el numero.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/indice_de_strong_para_la_view.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/busqueda/widgets/columna_de_texto.dart';

import '../view_models/indice_view_model.dart';

class IndiceView extends StatefulWidget {
  const IndiceView({
    super.key,
    required this.viewModel,
    required this.alPulsarPasaje,
    required this.alVolver,
  });

  final IndiceViewModel viewModel;

  /// Abrir el pasaje de una entrada del indice.
  final void Function(Referencia) alPulsarPasaje;

  /// Volver al pasaje de donde se vino. Es `popState`.
  final VoidCallback alVolver;

  @override
  State<IndiceView> createState() => _IndiceViewState();
}

/// Y CON ESTADO PORQUE **ESCUCHA AL VIEWMODEL**, y no por costumbre.
///
/// La primera version de esta pantalla era `StatelessWidget` y se quedaba en
/// `cargando` para siempre: el ViewModel abria el texto y avisaba, la pantalla no se
/// enteraba, y lo unico que se veia era "Recorriendo el texto..." con un numero vacio en
/// la barra. Es el fallo de no escucharse: `StatelessWidget` se redibuja cuando cambia
/// algo del widget, y el indice entero vive en el ViewModel.
class _IndiceViewState extends State<IndiceView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_alCambiar);
  }

  @override
  void didUpdateWidget(IndiceView anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.viewModel != widget.viewModel) {
      anterior.viewModel.removeListener(_alCambiar);
      widget.viewModel.addListener(_alCambiar);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.numero),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.alVolver,
        ),
      ),
      body: SafeArea(
        child: ColumnaDeTexto(
          // Y EL ESTILO ES EL DEL **CUERPO** de la lista, y no el del numero de arriba.
          // `ColumnaDeTexto` mide el ancho con este estilo para no pasar de 90 caracteres
          // por linea; medirlo con el numero, que va en grande, daria una columna mas
          // estrecha y lineas de 40 caracteres.
          estilo: Theme.of(context).textTheme.bodyMedium!,
          hijo: _cuerpo(context, vm),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, IndiceViewModel vm) {
    switch (vm.estado) {
      case EstadoDeIndice.cargando:
        return const _Explicacion(
          texto: 'Recorriendo el texto...',
          icono: Icons.hourglass_empty,
        );

      case EstadoDeIndice.fallo:
        return _Explicacion(texto: vm.motivoDelFallo, icono: Icons.error_outline);

      case EstadoDeIndice.vacio:
        return _Explicacion(
          // Y DICE EL NUMERO Y CUANTOS HABIA, porque "no hay resultados" sin el numero
          // deja a quien mira sin saber de que estaba mirando.
          texto: 'El numero ${vm.numero} no sale en este texto.',
          icono: Icons.search_off,
        );

      case EstadoDeIndice.conEntradas:
        return _lista(context, vm);
    }
  }

  Widget _lista(BuildContext context, IndiceViewModel vm) {
    final entradas = vm.entradas;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Medidas.margenAncho),
      itemCount: entradas.length + 2,
      separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, i) {
        if (i == 0) return _cabecera(context, vm);
        if (i == 1) return _formas(context, vm);
        return _FilaDeEntrada(
          entrada: entradas[i - 2],
          alPulsar: widget.alPulsarPasaje,
        );
      },
    );
  }

  /// El numero, en grande, y cuantos versiculos lo tienen.
  Widget _cabecera(BuildContext context, IndiceViewModel vm) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          16,
          Medidas.margenEstrecho,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Y LA LETRA DEL NUMERO EN UN COLOR DISTINTO, porque `G` es griego y `H` es
            // hebreo y es el dato mas util de la linea para quien sabe de lexicon: con un
            // numero a secas no se sabe de que idioma se trata.
            Text(
              vm.numero,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colores.acento,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(height: 2),
            // Y EL NUMERO POR [numeroEnCastellano], y no con `$vm.versiculos`. Dart escribe
            // 1171 y en castellano se escribe 1.171. La primera version de esta linea
            // imprimia "1171 versiculos tienen este numero", que en una pantalla en
            // castellano parece un volcado.
            Text(
              '${numeroEnCastellano(vm.versiculos)} '
              '${vm.versiculos == 1 ? "versiculo tiene" : "versiculos tienen"} este numero',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colores.textoSuave),
            ),
            // Y LA FRASE QUE DICE LO QUE ESTO **NO** ES. Va aqui, arriba y sin adornos, y
            // no en un aviso: es la definicion de la pantalla. Sin ella, quien abre el
            // indice buscando que significa `G2316` se va a leer 1.171 versiculos creyendo
            // que se lo va a encontrar.
            const SizedBox(height: 8),
            Text(
              'Esto no es un diccionario. El significado de un numero esta en un '
              'diccionario del Griego o del Hebreo, no en el texto, y el texto no lo trae.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colores.textoSuave),
            ),
          ],
        ),
      );

  /// Las escrituras de la palabra en este texto, con su cuenta.
  Widget _formas(BuildContext context, IndiceViewModel vm) {
    final formas = vm.formas;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margenEstrecho,
        4,
        Medidas.margenEstrecho,
        12,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: <Widget>[
          for (final forma in formas.entries.take(12))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colores.acento.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${forma.key} · ${numeroEnCastellano(forma.value)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colores.acento,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
              ),
            ),
          // Y SI HAY MAS DE DOCE FORMAS SE DICE CUANTAS QUEDAN. Medido: en el KJV los
          // numeros mas usados tienen entre tres y cinco formas, asi que doce solo se
          // llega con numeros raros --y son los que alguien investigating quiere ver
          // enteros, no un resumen.
          if (formas.length > 12)
            Text(
              'y ${formas.length - 12} formas mas',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colores.textoSuave),
            ),
        ],
      ),
    );
  }
}

/// Una entrada: el versiculo y las veces que sale en el.
class _FilaDeEntrada extends StatelessWidget {
  const _FilaDeEntrada({required this.entrada, required this.alPulsar});

  /// Y EL TIPO ES LA INTERFAZ DEL DOMINIO Y NO `dynamic`. Con `dynamic` la pantalla
  /// compila aunque la entrada no tenga `referencia`, y el fallo sale en pantalla.
  final IndiceDeStrongParaLaView entrada;
  final void Function(Referencia) alPulsar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = entrada.referenciaParaLaView;
    final veces = entrada.veces;

    return ListTile(
      title: Text(r.texto, style: t.textTheme.titleSmall),
      subtitle: Text('$veces ${veces == 1 ? "vez" : "veces"}'),
      trailing: Text(
        'cap. ${r.capitulo}',
        style: t.textTheme.labelSmall?.copyWith(color: Colores.textoSuave),
      ),
      onTap: () => alPulsar(r),
    );
  }
}

/// Una frase en medio de la pantalla, con un icono. Para los estados que no son una lista
/// y no son errores.
class _Explicacion extends StatelessWidget {
  const _Explicacion({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenAncho,
          Medidas.margenAncho,
          Medidas.margenAncho,
          Medidas.margenAncho,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icono, size: 28, color: Colores.textoSuave),
            const SizedBox(height: 12),
            Text(texto, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}
