// La pantalla de busqueda: el campo arriba y las coincidencias debajo.
//
// QUE HAY Y QUE NO HAY. Como el lector, esta pantalla solo pinta. No busca: le dice al
// ViewModel que busque y espera. Y no sabe de donde sale el texto, solo lo que el
// ViewModel le cuenta.
//
// Y EL ORDEN. Primero el campo, porque es lo que se usa; despues el numero de
// coincidencias, porque responde a la pregunta inmediata --"cuanto sale esto"-- antes de
// que quien busca empiece a leer lineas; y despues los resultados.
//
// ============================================================================
// Y LOS TRES AVISOS QUE NO SON UN AVISO DE ERROR
// ============================================================================
//
// La pantalla dice tres cosas que se podrian confundir con un fallo y que **no** lo son,
// y por eso estan en su sitio y no en una caja roja:
//
//   1. "Busca al menos dos letras." Cuando no se ha buscado nada.
//   2. "No sale "God" en este texto." Cuando se ha buscado y no hay nada.
//   3. "4.140 coincidencias; estas son las primeras 200." Cuando hay mas de las que caben.
//
// La razon de distinguirlas es que las tres responden a una pregunta distinta: la primera a
// "que tengo que hacer", la segunda a "esta el texto" y la tercera a "me estoy losing
// algo". Con un solo "no hay resultados" las tres se contestan igual, y quien busca "God"
// ve 200 lineas y no tiene forma de saber que le faltan 3.940.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/busqueda/widgets/columna_de_texto.dart';

import '../view_models/busqueda_view_model.dart';

/// Un modulo que se puede buscar, para que la pantalla se pueda montar sin abrir un
/// `.amod` de 22 MiB.
typedef BuscarEnElModulo = Future<BusquedaEnElModulo> Function(String palabra);

class BusquedaView extends StatefulWidget {
  const BusquedaView({
    super.key,
    required this.viewModel,
    required this.alPulsarResultado,
    required this.alVolver,
    required this.alBuscar,
  });

  final BusquedaViewModel viewModel;

  /// Abrir el pasaje de una coincidencia.
  ///
  /// Y LE PASA LA **REFERENCIA**, no la ruta. La ruta la compone quien la aplica, que es
  /// el enrutador: una pantalla que construye su propia ruta sabe cosas de como se
  /// escriben las rutas, y en cuanto cambia el formato hay dos sitios que cambiar.
  final void Function(Referencia) alPulsarResultado;

  /// Volver a donde se estaba. Es `popState`.
  final VoidCallback alVolver;

  /// Se ha escrito una palabra y se ha pedido buscar. Es `replaceState`: buscar es un
  /// ajuste de lo que se esta viendo, igual que poner un comentario, y con `pushState`
  /// el gesto de atras devolveria una busqueda anterior.
  final void Function(String palabra) alBuscar;

  @override
  State<BusquedaView> createState() => _BusquedaViewState();
}

class _BusquedaViewState extends State<BusquedaView> {
  final TextEditingController _control = TextEditingController();
  final FocusNode _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _control.text = widget.viewModel.palabra;
    widget.viewModel.addListener(_alCambiarElEstado);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambiarElEstado);
    _control.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Y POR QUE **NO** SE TOCA EL CAMPO DESDE `build`. El mismo motivo que en el lector:
  /// escribir en un `TextEditingController` mientras se esta escribiendo mueve el cursor al
  /// final en cada letra.
  ///
  /// Y AUNQUE ASI SE TOCA, SOLO CUANDO **NO** SE ESTA ESCRIBIENDO, y con la condicion
  /// inversa de la que parece: si el campo tiene el foco, no se toca. La primera version
  /// sincronizaba siempre, y al pulsar "buscar" con el movil --con el teclado abierto-- la
  /// palabra salia escrita y el cursor se iba al final, que es donde ya estaba. Con un
  /// texto mas largo se notaba: al buscar desde una ruta con el teclado puesto, cada letra
  /// que se escribia se Cumulative y el campo se emptying.
  ///
  /// Y EL `initState` SOLO NO ALCANZA. La palabra la pone el enrutador al aplicar la ruta,
  /// y eso puede pasar **despues** de que este `State` ya exista: el `initState` leeria un
  /// campo vacio y la pantalla de busqueda se abriria sin palabra. Medido: entrar en
  //  `/buscar/KJV2006/begotten` por enlace mostraba el campo en blanco.
  void _alCambiarElEstado() {
    if (!_foco.hasFocus) _ponerLaPalabraDelViewModel();
    if (mounted) setState(() {});
  }

  void _ponerLaPalabraDelViewModel() {
    final palabra = widget.viewModel.palabra;
    if (_control.text == palabra) return;
    _control.value = TextEditingValue(
      text: palabra,
      // Y EL CURSOR AL FINAL Y NO AL PRINCIPIO: una palabra puesta sola, sin escribir,
      // tiene el cursor detras, que es donde estara cuando se empiece a escribir.
      selection: TextSelection.collapsed(offset: palabra.length),
    );
  }

  void _buscar() {
    final palabra = _control.text.trim();
    if (palabra.isEmpty) return;
    _foco.unfocus();
    widget.alBuscar(palabra);
    widget.viewModel.buscar(palabra);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.alVolver,
        ),
      ),
      body: SafeArea(
        child: ColumnaDeTexto(
          // Y EL ESTILO ES EL DEL **EXTRACTO**, que es lo mas largo de la pantalla, y no
          // el de un titulo. `ColumnaDeTexto` mide el ancho con este estilo para no pasar
          // de 90 caracteres por linea, asi que poner aqui un estilo de 22 px daria una
          // columna mas ancha y lineas de 150 caracteres.
          estilo: Theme.of(context).textTheme.bodyMedium!,
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _campo(vm),
              Expanded(child: _cuerpo(vm)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(BusquedaViewModel vm) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          8,
          Medidas.margenEstrecho,
          12,
        ),
        child: TextField(
          controller: _control,
          focusNode: _foco,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          // Y `enableSuggestions` A FALSE, porque un corrector automatico cambiaria la
          // palabra buscada por otra. Buscar "propitiacion" y que el movil mande
          // "propitiación" sin tilde, o "propitiación" con tilde, son dos busquedas
          // distintas y la que se ensena no es la que se hizo.
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Escribe una palabra',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              icon: const Icon(Icons.arrow_forward),
              onPressed: _buscar,
            ),
          ),
          onSubmitted: (_) => _buscar(),
        ),
      );

  Widget _cuerpo(BusquedaViewModel vm) {
    switch (vm.estado) {
      case EstadoDeBusqueda.sinBuscar:
        // Y UNA FRASE, no un spinner. No hay nada que esperar todavia y un spinner que
        // gira para siempre porque no hay nada que termine es la forma de hacer que la
        // app parezca colgada.
        return const _Explicacion(
          texto: 'Busca una palabra en el texto abierto. Dos letras o mas.',
          icono: Icons.search,
        );

      case EstadoDeBusqueda.cargando:
        return const _Explicacion(texto: 'Buscando...', icono: Icons.hourglass_empty);

      case EstadoDeBusqueda.sinResultados:
        return _Explicacion(
          // Y LA PALABRA VA DENTRO DEL TEXTO DEL AVISO, y no en un titulo aparte. Sin
          // ella, "no hay resultados" es un pronoun sin sujeto y quien ve la pantalla
          // tiene que subir a mirar el campo para saber de que se trata.
          texto: 'La palabra "${vm.palabra}" no sale en este texto.',
          icono: Icons.search_off,
        );

      case EstadoDeBusqueda.fallo:
        return _Explicacion(texto: vm.motivoDelFallo, icono: Icons.error_outline);

      case EstadoDeBusqueda.conResultados:
        return _resultados(vm);
    }
  }

  Widget _resultados(BusquedaViewModel vm) {
    final b = vm.busqueda;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Medidas.margenAncho),
      itemCount: b.resultados.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, i) {
        if (i == 0) return _cabecera(b);
        return _FilaResultado(
          resultado: b.resultados[i - 1],
          alPulsar: widget.alPulsarResultado,
        );
      },
    );
  }

  /// El numero de coincidencias, y si hay mas de las que caben.
  ///
  /// Y LA SEGUNDA FRASE SOLO CUANDO HAY MAS, porque "2 coincidencias" no necesita un
  /// "estas son todas" detras: es obvio. Y en cambio "4.140 coincidencias" sin decir que
  /// son 200 de ellas parece una lista corta que se ha olvidado.
  Widget _cabecera(BusquedaEnElModulo b) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          4,
          Medidas.margenEstrecho,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              b.total == 1
                  ? '1 coincidencia de "${b.palabra}"'
                  // Y EL NUMERO VA POR [numeroEnCastellano], no con `$b.total`: Dart
                  // escribe 4140 y en castellano se escribe 4.140.
                  : '${numeroEnCastellano(b.total)} coincidencias de "${b.palabra}"',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (b.hayMas) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                'Estas son las primeras ${b.resultados.length}.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colores.textoSuave),
              ),
            ],
            const SizedBox(height: 6),
            // Y EL AVISO DE QUE ESTO ES UNA BUSQUEDA **POR TEXTO**, y no por palabra.
            // Medido el 5 de octubre de 2026 sobre el KJV real: "pro" sale en 2.890
            // versiculos, y muchisimos son "propitiacion" o "prophets". Quien busca
            // "pro" y ve 200 resultados de "propitiation" sin esta frase piensa que el
            // buscador no funciona.
            Text(
              'Busca el texto entero, no palabras sueltas: "pro" tambien sale en '
              '"propitiation".',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colores.textoSuave),
            ),
          ],
        ),
      );
}

/// Una coincidencia: el versiculo y el trozo de texto alrededor.
class _FilaResultado extends StatelessWidget {
  const _FilaResultado({required this.resultado, required this.alPulsar});

  final ResultadoDeBusqueda resultado;
  final void Function(Referencia) alPulsar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = resultado.referencia;

    return ListTile(
      title: Text(r.texto, style: t.textTheme.titleSmall),
      subtitle: Text(resultado.extracto, style: t.textTheme.bodyMedium),
      // Y LA ETIQUETA DE **CAPITULO**: "Juan 3:16" y "1 Juan 2:2" empiezan igual, y en
      // una lista de "Juan ..." uno no sabe cual es cual. El numero de capitulo esta en
      // la propia referencia, no en una tabla.
      trailing: Text(
        'cap. ${r.capitulo}',
        style: t.textTheme.labelSmall?.copyWith(color: Colores.textoSuave),
      ),
      isThreeLine: true,
      onTap: () => alPulsar(r),
    );
  }
}

/// Una frase en medio de la pantalla, con un icono. Para los tres estados que no son
/// resultados y no son errores.
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
