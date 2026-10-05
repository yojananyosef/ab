// La pantalla de lectura: el capitulo, sus versiculos, y los terminos.
//
// QUE HAY Y QUE NO HAY EN UNA VISTA. Solo pinta. No lee ficheros, no hace
// consultas, no decide nada de lo que se puede o no se puede abrir: eso es del
// ViewModel, que ya esta probado contra el `.amod` real. Si aqui hay un
// `if (pasaje.vacio)` es un bug de arquitectura, aunque compile.
//
// ============================================================================
// EL ORDEN DE LA PANTALLA, Y POR QUE
// ============================================================================
//
//   1. El titulo del pasaje con las flechas de capitulo.
//   2. El campo de referencia.
//   3. Los avisos: pasaje inexistente, discrepancia de licencia, texto incompleto.
//   4. El capitulo, versiculo a versiculo.
//   5. Los terminos del modulo.
//
// Y EL ORDEN DE LOS AVISOS ES EL QUE IMPORTA. El aviso de "este pasaje no existe en
// esta traduccion" va **antes** del texto y no despues, y no por beautitud: si
// estuviera debajo, quien pide Juan 5:44 ve un espacio en blanco y
// pensaria que la aplicacion se ha roto, en vez de leer que ese versiculo no esta.
// Un aviso debajo de un texto que no sale es un aviso que no se ve.
//
// Y LOS TERMINOS VAN AL FINAL Y EN EL SCROLL, NO FIJOS. Un pie fijo taparia
// versiculos, que es lo peor que puede hacer un pie. Se llega a el bajando, y quien
// lee el texto va a leerlos al final, que es cuando ya sabe si le sirve.
//
// ============================================================================
// Y LO QUE NO HAY: AJUSTES EN ESTA PANTALLA
// ============================================================================
//
// No hay un boton de tamano de letra aqui. Existe --`ajustarA`-- y es `replaceState`,
// y llega con la pantalla de ajustes. Pero no se pinta todavia, y la razon es que un
// ajuste que aparece en un sitio y no en el otro se acaba usando menos: quien lee no
// busca el boton, espera que este. Cuando se anada, que este en el lector y no solo
// en una pantalla a la que hay que ir.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/nota.dart';
import 'package:ab/domain/models/token_de_texto.dart';
import 'package:ab/domain/models/pasaje.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/versiculo.dart';
import 'package:ab/ui/core/tema.dart';

import '../view_models/lector_view_model.dart';
import '../widgets/campo_de_referencia.dart';
import '../../busqueda/widgets/columna_de_texto.dart';
import '../widgets/estilo_de_palabra.dart';
import '../widgets/terminos_del_modulo.dart';

class LectorView extends StatefulWidget {
  const LectorView({
    super.key,
    required this.viewModel,
    required this.alPulsarPasaje,
    required this.alCambiarDeVersion,
    required this.alVolver,
    required this.alPedirComentario,
    required this.alVerIndice,
    required this.alAlternarPalabrasDeJesus,
    this.alDescargarComentario,
    this.alBuscar,
    this.modulosDelCatalogo = const <Modulo>[],
  });

  final LectorViewModel viewModel;

  /// Ir a otro pasaje del texto abierto. Es `pushState`.
  final void Function(Referencia referencia) alPulsarPasaje;

  /// Cambiar de version sin salir del pasaje. Es `replaceState`.
  final void Function(String id) alCambiarDeVersion;

  /// Volver a la biblioteca. Es `pushState`.
  final VoidCallback alVolver;

  /// Pedir un comentario para ponerlo al lado, o quitar el que hay.
  ///
  /// Y NO PINTA NADA Y NO SABE QUE HAY DESCARGADO, y por eso es un boton y no una hoja
  /// aqui dentro. La lista de comentarios sale del manifiesto y de lo que hay en el
  /// almacenamiento, y eso lo sabe quien tiene la biblioteca, no esta pantalla. Esta
  /// solo tiene un boton y el nombre del que hay abierto.
  final VoidCallback alPedirComentario;

  /// Bajar el comentario pedido, o null si no se puede.
  ///
  /// Y ES **OPCIONAL** Y NO UN BOLEANO, porque no es lo mismo "no se puede bajar" que
  /// "bajar y no avisar". Con un `bool descargar` habria que decidir en la vista **por
  /// que** no se puede --que no este en el catalogo, o que esta bajando ya-- y esa
  /// informacion no la tiene. Un `null` es lo que dice "no hay nada que ofrecer", y la
  /// pantalla no pinta boton y ya esta.
  final VoidCallback? alDescargarComentario;

  /// Los modulos que dice el catalogo, para poner el tamano en el boton de descargar.
  ///
  /// Y **SOLO** para eso. La pantalla de lectura no busca, no filtra y no download: pide
  /// un tamano para un boton. Lo que se pasa es el catalogo entero porque es lo que hay
  /// a mano, y separar un `Map<String, String>` de tamanos seria una copia de los
  /// identificadores en otro sitio, que es justo la lista que este proyecto no quiere.
  final List<Modulo> modulosDelCatalogo;

  /// Abrir la busqueda en este texto.
  ///
  /// Y OPCIONAL, porque hay una pantalla --la biblioteca-- donde no hay texto abierto y no
  /// hay nada que buscar. Un boton que no hace nada es peor que no tenerlo.
  final VoidCallback? alBuscar;

  /// Abrir el indice de la palabra [numero] en este texto.
  ///
  /// Y OBLIGATORIA, y no opcional como `alBuscar`, porque sin lexicon no hay indice y la
  /// palabra no es pulsable: el boton de buscar puede faltar --en la biblioteca no hay texto
  /// abierto-- y este no, porque es justo lo que se ofrece cuando hay texto.
  final void Function(String numero) alVerIndice;

  /// Poner las palabras de Jesus en rojo, o dejarlas como estaban.
  final VoidCallback alAlternarPalabrasDeJesus;

  @override
  State<LectorView> createState() => _LectorViewState();
}

class _LectorViewState extends State<LectorView> {
  late final TextEditingController _control;

  /// Que estaba escrito en el campo cuando se abrio, para no sobreescribir lo que
  /// alguien esta escribiendo con un `build`.
  ///
  /// Sin esto, cada vez que el capitulo cambia --que es lo que pasa al pulsar la
  /// flecha-- el `TextEditingController` se actualiza y **borra** lo que se estaba
  /// escribiendo. Quien esta escribiendo "Juan 5:1" para saltar al 17 ve como su
  /// "1" desaparece al cambiar de capitulo. Es de los fallos mas molestos que hay, y
  /// sale solo si se escribe mientras se navega.
  String _textoDelCampo = '';

  @override
  void initState() {
    super.initState();
    _control = TextEditingController();
    widget.viewModel.addListener(_alCambiarElEstado);
    // Y LA PREFERENCIA SE LEE AL ABRIR LA PANTALLA, y no al arrancar la app. Es una
    // lectura, es idempotente, y el momento en que puede haber cambiado es justo este: si
    // se leyera al arrancar, abrir una pestana nueva --que es como se lee en el escritorio,
    // una al lado de otra-- se pintaria con el color de la primera.
    unawaited(widget.viewModel.cargarPreferencias());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambiarElEstado);
    _control.dispose();
    super.dispose();
  }

  void _alCambiarElEstado() {
    // El campo **no** se toca. Solo se reordena lo de arriba, que es lo que depende
    // del estado.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.leyendo?.texto ?? 'Leyendo'),
        leading: IconButton(
          tooltip: 'Volver a la biblioteca',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.alVolver,
        ),
        actions: <Widget>[
          if (widget.alBuscar != null)
            IconButton(
              tooltip: 'Buscar en este texto',
              icon: const Icon(Icons.search),
              onPressed: widget.alBuscar,
            ),
          // Y EL INTERRUPTOR DE LAS LETRAS ROJAS. El icono es un circulo medio
          // relleno, que es lo que es literalmente el texto: una parte en color y otra
          // sin color. Y va con el estado en el `tooltip`, porque un icono que cambia de
          // tono no dice si esta puesto o quitado.
          IconButton(
            tooltip: vm.mostrarPalabrasDeJesus
                ? 'Palabras de Jesus en rojo: si'
                : 'Palabras de Jesus en rojo: no',
            icon: Icon(
              vm.mostrarPalabrasDeJesus ? Icons.tonality : Icons.tonality_outlined,
              // Y EL COLOR DEL ICONO TAMBIEN DICE EL ESTADO, porque el `tooltip` en movil
              // solo sale si se deja el dedo quieto, y eso casi nadie lo hace.
              color: vm.mostrarPalabrasDeJesus
                  ? Colores.palabraDeJesus
                  : Colores.textoSuave,
            ),
            onPressed: widget.alAlternarPalabrasDeJesus,
          ),
          _BotonDeComentario(
            id: vm.idDelComentario,
            alPulsar: widget.alPedirComentario,
          ),
          SizedBox(width: Medidas.margenEstrecho / 2),
        ],
      ),
      body: SafeArea(child: _cuerpo(vm)),
    );
  }

  Widget _cuerpo(LectorViewModel vm) {
    final estiloVersiculo = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 16,
          height: 1.7,
          color: Colores.texto,
        );

    return ColumnaDeTexto(
      estilo: estiloVersiculo,
      hijo: ListView(
        // `shrinkWrap` con un `ListView` dentro de un `Column` no hace falta: el
        // `ListView` es el unico hijo que hace scroll, y el `ColumnaDeTexto` solo
        // limita el ancho.
        padding: EdgeInsets.zero,
        children: <Widget>[
          MargenDeLectura(
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                _campoDeReferencia(vm),
                const SizedBox(height: 12),
                _tituloConFlechas(vm),
                const SizedBox(height: 12),
                if (vm.aviso != null) ...<Widget>[
                  AvisoDePasajeInexistente(
                    texto: vm.aviso!,
                    ultimoValido: vm.ultimoValido,
                    alIrAlUltimoValido: () {
                      final r = vm.irAlUltimoValido();
                      if (r != null) widget.alPulsarPasaje(r);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                // Y EL AVISO DEL COMENTARIO VA **DESPUES** DEL AVISO DEL PASAJE, y no es
                // por orden de importancia sino por cercania: los dos son de la misma
                // lectura y el de arriba es el del texto, que es lo que se esta
                // leyendo. Poner el del comentario primero haria que abrir Juan 3:1 --que
                // no tiene nota en el CLARKE, medido-- dijera dos veces que no hay
                // nada, y dos avisos que dicen lo mismo confunden mas que uno.
                if (vm.motivoDelComentario != null) ...<Widget>[
                  _AvisoDelComentario(
                    texto: vm.motivoDelComentario!,
                    hayComentario: vm.tieneComentario,
                    alQuitar: widget.viewModel.cerrarComentario,
                    // Y BAJAR SOLO CUANDO NO HAY UNO ABIERTO, que es el unico caso en el
                    // que tiene sentido: si ya hay un comentario al lado y sale un aviso,
                    // el aviso es por otro, y un boton de "bajar" ahi consuela de lo
                    // contrario.
                    alDescargar: vm.tieneComentario ? null : widget.alDescargarComentario,
                    tamano: _tamanioDeDescarga(vm.comentarioPedido),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          MargenDeLectura(hijo: _capitulo(vm, estiloVersiculo)),

          PieDeLectura(
            hijo: MargenDeLectura(
              hijo: TerminosDelModulo(
                terminos: vm.terminos,
                discrepancia: vm.discrepancia,
                ruta: vm.modulo?.ruta ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- el campo ---

  Widget _campoDeReferencia(LectorViewModel vm) => CampoDeReferencia(
        control: _control,
        alEscribir: (t) {
          _textoDelCampo = t;
          vm.escribirBusqueda(t);
        },
        alBuscar: () {
          final r = vm.referenciaEscrita;
          if (r == null) return;
          widget.alPulsarPasaje(r);
        },
        alLimpiar: () {
          _textoDelCampo = '';
          _control.clear();
          vm.limpiarBusqueda();
        },
        esValido: vm.laReferenciaEsValida,
        hayTexto: _textoDelCampo.trim().isNotEmpty,
      );

  // --- el titulo y las flechas ---

  Widget _tituloConFlechas(LectorViewModel vm) {
    final r = vm.leyendo;
    if (r == null) return const SizedBox.shrink();

    // Las flechas no saben cuantos capitulos hay: **preguntan**. Y preguntan con la
    // lista que devuelve la consulta al modulo, no con un numero escrito. El KJV
    // acaba en Juan 21; una traduccion puede acabar antes.
    //
    // Y se compara con el **numero de versiculos del capitulo siguiente**, no con el
    // de capitulos: asi un salto sobre un capitulo que la traduccion no tiene --que
    // existe-- no lleva a un capitulo en blanco. Ver `capitulosDe`.
    final capitulos = vm.capitulosDe(r.libro);
    final pos = capitulos.indexOf(r.capitulo);
    final anterior = pos > 0 ? capitulos[pos - 1] : null;
    final siguiente = pos >= 0 && pos < capitulos.length - 1 ? capitulos[pos + 1] : null;

    return TituloDelPasaje(
      referencia: r,
      hayAnterior: anterior != null,
      haySiguiente: siguiente != null,
      // Con `!` porque los botones estan deshabilitados cuando no hay capitulo, y
      // un boton deshabilitado no llama. Si alguna vez los llamara, el `!` dira que
      // se llego aqui con un null, que es mejor que una excepcion en pantalla.
      alAnterior: () => widget.alPulsarPasaje(Referencia(r.libro, anterior!)),
      alSiguiente: () => widget.alPulsarPasaje(Referencia(r.libro, siguiente!)),
      alVolver: widget.alVolver,
    );
  }

  // --- el capitulo ---

  Widget _capitulo(LectorViewModel vm, TextStyle estilo) {
    switch (vm.estado) {
      case EstadoLecturaTexto.sinModulo:
        return _nadaPintado(
          vm.aviso ?? 'No hay ningun texto abierto.',
          'Vuelve a la biblioteca y elige uno.',
        );

      case EstadoLecturaTexto.nadaLeido:
        // Ni spinner ni texto. Un modulo recien abierto sin pasaje pedido no tiene
        // nada que ensenar, y un "cargando" aqui seria un spinner que gira para
        // siempre porque no hay nada que termine.
        return const SizedBox.shrink();

      case EstadoLecturaTexto.cargando:
        return const _Cargando();

      case EstadoLecturaTexto.fallo:
        return _nadaPintado(
          vm.motivoDelFallo ?? 'No se ha podido leer.',
          'Puedes volver a la biblioteca e intentarlo otra vez.',
        );

      case EstadoLecturaTexto.noExiste:
        // El aviso ya esta arriba, con su boton. Aqui no se pinta texto, porque no
        // hay. Y **no** se pinta un hueco con el numero del versiculo pedido: un
        // "37" sin texto parece que el versiculo existe y esta en blanco, que es
        // distinto de que no exista.
        return const SizedBox.shrink();

      case EstadoLecturaTexto.leyendo:
        final p = vm.pasaje;
        if (p == null || p.vacio) {
          return _nadaPintado(
            p?.traeNotas == true
                ? 'Aqui no hay nada escrito sobre este pasaje.'
                : 'Este pasaje esta vacio en esta traduccion.',
            '',
          );
        }

        // Y UN `if` SOBRE EL PASAJE, Y NO UN `if` POR FRAGMENTO. La pantalla decide una
        // vez como se pinta lo que hay: versiculos o notas. Con un `if` por fragmento, una
        // nota y un versiculo en la misma lista se pintarian con el mismo formato, y eso
        // es exactamente la confusion que hay que evitar: que el comentario pareciese
        // parte de la Escritura.
        if (p.traeNotas) {
          return _ColumnaDeNotas(pasaje: p, estilo: estilo);
        }

        // Y CADA VERSICULO CON SUS NOTAS DEBAJO, y no todas las notas al final del
        // capitulo. Treinta y dos notas al final son un anexo: hay que ir y volver del
        // versiculo a la nota y de la nota al versiculo, y lo que se acaba leyendo es
        // el capitulo entero dos veces.
        //
        // Y SI NO HAY NOTAS DE ESE VERSICULO, NO SE PINTA NADA. Ni una linea de
        // separacion, ni un hueco, ni un "sin comentario": en el CLARKE hay 32
        // versiculos con nota de cada 36 de Juan 3, y cuatro separaciones vacias seguidas
        // parecen un fallo de maquetado.
        final conNotas = vm.tieneComentario;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final v in p.versiculos) ...<Widget>[
              _Versiculo(
                versiculo: v,
                estilo: estilo,
                alVerIndice: widget.alVerIndice,
                mostrarPalabrasDeJesus: vm.mostrarPalabrasDeJesus,
              ),
              if (conNotas) ..._notasDe(vm, v.numero, estilo),
            ],
          ],
        );
    }
  }

  /// El tamano del comentario pedido, como lo dice el manifiesto, o cadena vacia.
  ///
  /// Y SE LE PIDE AL **MANIFIESTO** Y NO A LA BIBLIOTECA, porque la pantalla de lectura
  /// no la tiene y no deberia: la unica razon por la que se despinta un boton de
  /// "Descargar" es que hay algo en el catalogo.
  String _tamanioDeDescarga(String? id) {
    if (id == null) return '';
    final modulo = _modulosPorId[id];
    if (modulo == null) return '';
    return modulo.megabytes;
  }

  /// Los modulos del manifiesto que se han pedido descargar, por identificador.
  ///
  /// Y SE LLENA CUANDO SE PINTA LA BARRA Y NO SE PASA COMO PARAMETRO, y la razon es que
  /// `LectorView` ya recibe siete cosas y una octava de "datos" es como se acaba
  /// pasando el manifiesto entero a una pantalla que solo necesita un tamano.
  Map<String, Modulo> get _modulosPorId => <String, Modulo>{
        for (final m in widget.modulosDelCatalogo) m.id: m,
      };

  /// Las notas de un versiculo, o nada si no las hay.
  List<Widget> _notasDe(LectorViewModel vm, int versiculo, TextStyle estilo) {
    final notas = vm.notasDe(versiculo);
    if (notas.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(height: 10),
      _EncabezadoDeNota(versiculo: versiculo, total: notas.length),
      for (final nota in notas) _Nota(nota: nota, estilo: estilo),
    ];
  }

  Widget _nadaPintado(String texto, String ayuda) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(texto, style: Theme.of(context).textTheme.bodyLarge),
            if (ayuda.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                ayuda,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colores.textoSuave),
              ),
            ],
          ],
        ),
      );
}

/// Las notas de un capitulo de comentario.
///
/// Y SE PINTAN **DISTINTAS** DE UN VERSICULO, Y NO ES UNA CUESTION DE ESTILO. Un
/// versiculo es la Sagrada Escritura: columna propia, numero grande, el texto del mismo
/// cuerpo que el resto de la lectura. Una nota es el comentario de un hombre de 1832, y
/// por eso va en un cuerpo mas pequeño, con una linea de encima que la separa de la
/// anterior, con el versiculo al que se refiere a la izquierda en lugar de un numero
/// suelto, y con la certeza visual de que **no es la Palabra**.
///
/// Y ESTA SEPARACION ES LO QUE LA HACE UTIL Y LO QUE LA HACE HONESTA. Un comentario
/// pegado al texto con el mismo formato no se distingue de la Escritura, y quien lo lee
/// rapido se lleva la impresion de que Adam Clarke estaba citando la Biblia cuando en
/// realidad estaba escribiendo sobre ella.
///
/// Y AGRUPA POR VERSICULO, no una nota detras de otra. Treinta y dos notas seguidas sin
/// decir a que versiculo corresponde cada una son un muro de texto: se lee entero y no
/// se entiende nada. La nota se lee **al lado** de su versiculo, y por eso cada versiculo
/// con nota sale con su numero y sus notas debajo.
class _ColumnaDeNotas extends StatelessWidget {
  const _ColumnaDeNotas({required this.pasaje, required this.estilo});

  final Pasaje pasaje;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    final numeros = pasaje.versiculosConNota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < numeros.length; i++) ...<Widget>[
          if (i > 0)
            const Divider(height: 26, thickness: 1, color: Colores.linea),
          _EncabezadoDeNota(
            versiculo: numeros[i],
            total: pasaje.notasDe(numeros[i]).length,
          ),
          for (final nota in pasaje.notasDe(numeros[i]))
            _Nota(nota: nota, estilo: estilo),
        ],
      ],
    );
  }
}

/// "Juan 3:16", y "2 notas" cuando hay mas de una.
///
/// Y EL NUMERO DE NOTAS PORQUE EN 19.742 notas hay **un** versiculo con dos --Mateo
/// 23:13--, y sin decirlo no se entiende por que hay dos parrafos seguidos debajo del
/// mismo versiculo.
class _EncabezadoDeNota extends StatelessWidget {
  const _EncabezadoDeNota({required this.versiculo, required this.total});

  final int versiculo;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: <Widget>[
        // Y UN RECTANGULO Y NO UN CIRCULO, para que no parezca un boton. Y en el color
        // del comentario, que es el mismo que usa el resto de la pantalla para los
        // terminos: quien lee un comentario tiene que poder distinguirlo de la
        // Escritura sin leer nada, y el color es lo primero que ve.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colores.acento.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colores.acento.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$versiculo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colores.acento,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (total > 1)
          Text(
            total == 2 ? '2 notas' : '$total notas',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    ),
  );
}

/// Una nota de comentario.
///
/// Y EL `indentation` Y LA BARRA VERTICAL, porque la nota pertenece a un versiculo y
/// tiene que quedar **dentro** de el. Es lo que hace que se lea como glosa y no como un
/// versiculo mas.
class _Nota extends StatelessWidget {
  const _Nota({required this.nota, required this.estilo});

  final Nota nota;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    // Y UN CUERPO MAS PEQUENO QUE EL DE LOS VERSICULOS, y no por crammed: porque es
    // texto secundario. La lectura principal es la Escritura; el comentario va en voz
    // baja, y subirlo a voz alta es como se ensena un comentario como si fuera el texto.
    final cuerpo = estilo.copyWith(fontSize: 15, height: 1.55);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 3,
            height: 20,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              color: Colores.acento.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              nota.texto,
              style: cuerpo,
              softWrap: true,
              // Y CON NOMBRE ACCESIBLE QUE DIGA A QUE VERSICULO. Un lector de pantalla
              // lee el cuerpo de la nota y no sabe de que versiculo es, que es la
              // informacion que hace falta para entenderla.
              semanticsLabel: 'Nota sobre el versiculo ${nota.versiculo}',
            ),
          ),
        ],
      ),
    );
  }
}

/// El boton de la barra para poner un comentario al lado, o quitar el que hay.
///
/// Y DICE EL NOMBRE DEL COMENTARIO Y NO SOLO UN ICONO. Un icono de bocadillo en una
/// barra dice "aqui hay comentarios" y no dice cuales, y quien esta leyendo Juan 3:16 con
/// el CLARKE al lado necesita poder confirmar en un vistazo que lo que tiene al lado es lo
/// que pidio y no el que habia de antes.
///
/// Y CUANDO NO HAY NINGUNO DICE "COMENTARIO", que es lo que hay que hacer, y no un icono
/// apagado sin texto: un control sin etiqueta en una barra es un control que no se ve.
class _BotonDeComentario extends StatelessWidget {
  const _BotonDeComentario({required this.id, required this.alPulsar});

  final String? id;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final hay = id != null;

    return Tooltip(
      message: hay
          ? 'El comentario es $id. Púlsalo para cambiarlo o quitarlo.'
          : 'Poner un comentario al lado del texto',
      child: TextButton.icon(
        onPressed: alPulsar,
        icon: Icon(
          hay ? Icons.comment : Icons.comment_outlined,
          size: 20,
          // Y EL ICONO TAMBIEN DICE SI HAY ALGO, y no solo el texto: el color del boton
          // cambia con el, de modo que se distingue de un vistazo sin leer.
          color: hay ? Colores.acento : Colores.textoSuave,
        ),
        label: Text(
          hay ? id! : 'Comentario',
          style: TextStyle(
            color: hay ? Colores.acento : Colores.textoSuave,
            fontWeight: hay ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        // Y `VisualDensity.compact` PORQUE LA BARRA ES ALTA Y EL TEXTO ES DE 16. Con la
        // densidad normal el boton empuja la barra a 56 de alto y el titulo --"Juan 3:16"--
        // sube con el, y el titulo no tiene por que moverse porque se haya abierto una
        // hoja.
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
    );
  }
}

/// "El comentario X no esta descargado en este dispositivo."
///
/// Y CON UN BOTON DE "QUITAR" SOLO SI HAY UNO ABIERTO. Un aviso sin boton deja a quien lo
/// ve sin salida: puede volver a la biblioteca y buscar el comentario otra vez, que es
/// un rodeo de tres toques para deshacer algo que cabe en uno.
class _AvisoDelComentario extends StatelessWidget {
  const _AvisoDelComentario({
    required this.texto,
    required this.hayComentario,
    required this.alQuitar,
    required this.alDescargar,
    required this.tamano,
  });

  final String texto;
  final bool hayComentario;
  final VoidCallback alQuitar;

  /// Null cuando no hay nada que bajar.
  final VoidCallback? alDescargar;

  /// "57,5 MB", o cadena vacia si no se sabe el tamano.
  ///
  /// Y EL TAMANO EN EL BOTON Y NO EN EL TEXTO DEL AVISO, porque el boton es lo que se
  /// pulsa y es donde se decide si se bajan 57 MiB o 300. Y **solo si se sabe**: el
  /// manifiesto lo dice y sin el no se inventa.
  final String tamano;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colores.acento.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colores.linea),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 20, color: Colores.textoSuave),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: t.textTheme.bodyMedium),
          ),
          // Y EL BOTON SE ENCOGE EN UNA LINEA Y SE DEJA VER ENTERO. Con el nombre
          // completo del texto --"KJV2006 es un texto de Biblia, no un comentario"-- el
          // aviso necesita su ancho, y si el boton no cede lo que se acorta es el texto,
          // que es justo lo que no debe pasar.
          if (hayComentario)
            TextButton(
              onPressed: alQuitar,
              style: _estiloDeBoton,
              child: const Text('Quitar'),
            )
          else if (alDescargar != null)
            TextButton(
              onPressed: alDescargar,
              style: _estiloDeBoton,
              // Y CON EL TAMANO EN EL MISMO BOTON, no en una linea aparte. Un "Descargar"
              // sin tamano es un boton cuyo coste no se sabe, y ante un boton cuyo coste
              // no se sabe lo que hace la gente es no pulsarlo.
              child: Text(tamano.isEmpty ? 'Descargar' : 'Descargar, $tamano'),
            ),
        ],
      ),
    );
  }

  static final ButtonStyle _estiloDeBoton = TextButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );
}

/// El texto de un versiculo, con lo que el modulo marco de cada palabra.
///
/// Y SON DOS CAMINOS Y SE ESCOGE UNO, y no por gusto sino por lo que se pueda comprobar:
///
///   - Sin anotaciones --el comentario, y el 2,4% de los versiculos del KJV-- se pinta
///     con un `Text` de toda la vida. Es el camino viejo y no se toca.
///
///   - Con anotaciones se pinta con `Text.rich`, y **el texto sale del mismo sitio**: las
///     palabras se parten por el espacio y se vuelven a juntar con el espacio. Es lo que
///     hace que `texto.split(' ').join(' ') == texto` para cualquier texto, y esa
///     identidad es la que asegura que lo que se lee es lo que el modulo tiene.
///
/// Y LO QUE SE PINTA DE OTRA MANERA SON LAS PALABRAS QUE PUSO EL TRADUCTOR, y solo eso.
/// Las del CLARKE son 41.692 marcas `\add` sobre 31.102 versiculos, y Juan 3:16 no tiene
/// ni una.
///
/// Y LO QUE **NO** SE PINTA ES LA PALABRA DE DIOS EN ROJO, y hay que decirlo aqui porque es
/// lo que se espera de un cambio como este. **No se puede**: medido el 5 de octubre de
/// 2026 sobre el KJV entero, no hay ni una marca de habla divina en 31.102 versiculos. Lo
/// que hay son los numeros del lexicon y los `\add`. Pintar de rojo lo que uno no sabe
/// que es la Palabra es inventarse el dato, y este dato es la Escritura.
class _TextoDelVersiculo extends StatefulWidget {
  const _TextoDelVersiculo({
    required this.versiculo,
    required this.estilo,
    required this.alVerIndice,
    required this.mostrarPalabrasDeJesus,
  });

  final Versiculo versiculo;
  final TextStyle estilo;

  /// Abrir el indice de un numero del lexicon. Lo llama quien ha pulsado la palabra.
  final void Function(String numero) alVerIndice;

  /// Si las palabras de Jesus van en rojo.
  final bool mostrarPalabrasDeJesus;


  @override
  State<_TextoDelVersiculo> createState() => _TextoDelVersiculoState();
}

/// Y ES UN `StatefulWidget` Y NO UNO SIN ESTADO POR LOS **GESTORES DE GESTO**.
///
/// Y NO ES UN DETALLE DE FORMA. Un `TapGestureRecognizer` es un objeto que hay que
/// **cerrar**, y el `dispose` es el unico sitio donde se puede. Sin estado no hay
/// `dispose`: los reconocedores se acumulan en cada `build` --y `build` corre en cada
/// cambio de estado del lector, que son varios por capitulo-- y cada uno se queda
/// apuntando a un `TextSpan` que ya no existe.
///
/// Y SE CREAN EN `initState` Y SE RELLENAN EN `didUpdateWidget`, y no en `build`: un
/// reconocedor por palabra **por build** es trabajo de GPU por cada tecla que se escribe
/// en el campo de arriba.
class _TextoDelVersiculoState extends State<_TextoDelVersiculo> {
  /// Un reconocedor por palabra **con numero**, y `null` en las que no lo tienen.
  ///
  /// Y LA LISTA MIDE LAS PALABRAS DEL VERSICULO Y NO LAS QUE TIENEN NUMERO, y por eso es
  /// una lista y no un mapa: el indice de la palabra es el mismo numero que ocupa la
  /// palabra, y buscar en un mapa en cada `build` seria trabajo por palabra por repintado.
  List<TapGestureRecognizer?>? _gestores;

  @override
  void initState() {
    super.initState();
    _gestores = _crearGestores(widget.versiculo);
  }

  @override
  void didUpdateWidget(_TextoDelVersiculo anterior) {
    super.didUpdateWidget(anterior);
    // Y SOLO SI EL VERSICULO **HA CAMBIADO**. Al cambiar de palabra buscada o de cualquier
    // otra cosa de la pantalla el versiculo es el mismo, y rehacer los reconocedores seria
    // tirar los que ya estan bien.
    if (anterior.versiculo != widget.versiculo) {
      _cerrarGestores();
      _gestores = _crearGestores(widget.versiculo);
    }
  }

  @override
  void dispose() {
    _cerrarGestores();
    super.dispose();
  }

  void _cerrarGestores() {
    for (final g in _gestores ?? const <TapGestureRecognizer?>[]) {
      g?.dispose();
    }
    _gestores = null;
  }

  List<TapGestureRecognizer?>? _crearGestores(Versiculo v) {
    if (v.anotaciones.isEmpty) return null;
    return <TapGestureRecognizer?>[
      for (var i = 0; i < v.palabras.length; i++)
        if (i < v.anotaciones.length && v.anotaciones[i].strong != null)
          // Y UN GESTOR POR PALABRA **CON NUMERO**, y no por palabra. Una palabra sin
          // numero no es pulsable porque no hay nada a que ir: el indice es de numeros.
          TapGestureRecognizer()
            ..onTap = () => widget.alVerIndice(v.anotaciones[i].strong!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.versiculo;
    final anotaciones = v.anotaciones;

    if (anotaciones.isEmpty) {
      return Text(
        v.texto,
        style: widget.estilo,
        // Sin esto, una palabra muy larga --un nombre propio largo en otra escritura, una
        // URL en un texto-- sale del borde. Flutter ya parte por el ancho, pero no
        // siempre, y un texto que sale del borde es texto que no se puede seleccionar.
        softWrap: true,
      );
    }

    final palabras = v.palabras;
    return Text.rich(
      TextSpan(
        style: widget.estilo,
        children: <InlineSpan>[
          for (var i = 0; i < palabras.length; i++) ...<InlineSpan>[
            if (i > 0) const TextSpan(text: ' '),
            TextSpan(
              text: palabras[i],
              recognizer: (_gestores != null && i < _gestores!.length)
                  ? _gestores![i]
                  : null,
              style: _estiloDePalabra(anotaciones, i),
            ),
          ],
        ],
      ),
      softWrap: true,
    );
  }

  /// El estilo de una palabra, delegado a [estiloDePalabra].
  ///
  /// Y AQUI NO HAY NINGUNA DECISION, y por eso esta el metodo entero. La tabla de que
  /// marca se pinta con que marca esta en `widgets/estilo_de_palabra.dart`, que es donde
  /// se puede probar entera.
  TextStyle? _estiloDePalabra(List<AnotacionDePalabra> anotaciones, int i) {
    if (i >= anotaciones.length) return null;
    return estiloDePalabra(
      anotaciones[i],
      widget.estilo,
      mostrarPalabrasDeJesus: widget.mostrarPalabrasDeJesus,
    );
  }
}

/// Un versiculo: el numero en su columna y el texto al lado.
///
/// Y EL NUMERO NO SE PONE EN UNA CAJA NI EN UN CIRCULO. Un numero dentro de una
/// forma tiene peso visual y rompe el ritmo de la lectura: el ojo va al numero en
/// vez de al texto, y leer 36 veces "el numero va primero" es peor que leer el texto
/// con un numero al margen. Y en un movil el margen se come el ancho, y el ancho es
/// lo que no sobra.
///
/// Y EL NUMERO SE PINTA EN UN ANCHO FIJO, para que todos los versiculos del capitulo
/// cuenten igual de ancho. Con el numero pegado al texto, el 1 queda en 8 px y el 36
/// en 20, y el texto empieza en un sitio distinto en cada versiculo. Que el texto
/// empiece siempre en el mismo sitio es lo que hace que una columna de versiculos se
/// pueda leer como una columna.
class _Versiculo extends StatelessWidget {
  const _Versiculo({
    required this.versiculo,
    required this.estilo,
    required this.alVerIndice,
    required this.mostrarPalabrasDeJesus,
  });

  final Versiculo versiculo;
  final TextStyle estilo;

  /// Pasa de la palabra al indice. Se pasa de uno a otro porque `_Versiculo` esta en medio
  /// y no sabe que hay un indice detras.
  final void Function(String numero) alVerIndice;

  /// Si las palabras de Jesus van en rojo. Tambien se pasa de uno a otro, y por lo mismo.
  final bool mostrarPalabrasDeJesus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text(
              '${versiculo.numero}',
              textAlign: TextAlign.right,
              style: estilo.copyWith(
                fontSize: 13,
                color: Colores.textoSuave,
                height: 1.9,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TextoDelVersiculo(
              versiculo: versiculo,
              estilo: estilo,
              alVerIndice: alVerIndice,
              mostrarPalabrasDeJesus: mostrarPalabrasDeJesus,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que se ve mientras llega el capitulo.
///
/// Un `CircularProgressIndicator` centrado y sin texto, porque en un capitulo de tres
/// segundos un "cargando" parpadeando es ruido. Y no es un `FutureBuilder`: el
/// ViewModel ya avisa cuando ha terminado, y un `FutureBuilder` dentro del estado
/// seria un segundo sitio que sabe si hay texto.
///
/// Y NO HAY UN DELAY PARA QUE NO PARPADEE. Un spinner que aparece y desaparece en
/// 12 ms por un capitulo de un versiculo es un fogonazo, y un fogonazo molesta mas
/// que una espera de 40 ms. Podria remediarse con un temporizador que no pinte nada
/// hasta los 150 ms, y no se hace: en la maquina de Dart el capitulo de Juan 3 esta
/// en 4 ms, de modo que cualquier espera solo se veria en produccion, y un
/// temporizador que aqui nunca se ve es un temporizador que nadie llega a probar.
class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}
