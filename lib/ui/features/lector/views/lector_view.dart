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
import 'package:ab/domain/models/resaltado.dart';
import 'package:ab/domain/models/versiculo.dart';
import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/tema.dart';

import '../view_models/lector_view_model.dart';
import '../widgets/campo_de_referencia.dart';
import '../../busqueda/widgets/columna_de_texto.dart';
import '../widgets/estilo_de_palabra.dart';
import '../widgets/hoja_de_versiones.dart';
import '../widgets/hoja_de_formato.dart';
import '../widgets/linea_enfocada.dart';
import '../widgets/hoja_de_resaltado.dart';
import '../view_models/resaltados_view_model.dart';
import '../widgets/fila_de_menu.dart';
import '../widgets/hoja_de_notas.dart';
import '../widgets/notas_al_pie_del_capitulo.dart';
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
    required this.alAbrirLibros,
    required this.alAbrirVersiones,
    this.resaltados,
    this.alDescargarComentario,
    this.alBuscar,
    this.modulosDelCatalogo = const <Modulo>[],
    this.versiones = const <VersionDisponible>[],
    this.mostrarBarraDeAplicacion = true,
  });

  /// Si este panel pinta su propia `AppBar`.
  ///
  /// Y **NO ES UN GUSTO**, es lo que evita que dos pestanas muestren dos barras. Con un
  /// solo panel abierto, la barra es lo unico que dice que texto esta abierto --el nombre
  /// de la version vive ahi-- y sin ella la pantalla no sabe que se esta leyendo nada.
  ///
  /// Y CON DOS PANELES **NO HAY NINGUNA BARRA**, y el motivo es que el nombre de la
  /// version pasa a estar en la **pestana**, que es donde esta en Logos. Poner las dos
  /// cosas --la barra en cada panel y el nombre en la pestana-- seria el mismo dato dos
  /// veces en la parte de arriba de la ventana, y medido a 1440 px son dos lineas de texto
  /// de las que solo una cambia al cambiar de pestana.
  ///
  /// Y POR DEFECTO **SI**, y no porque sea lo de siempre: las 24 pruebas que montan esta
  /// pantalla sin panel de pestañas tienen que ver lo que ve quien lee con un solo texto
  /// abierto, que es la barra.
  final bool mostrarBarraDeAplicacion;

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

  /// Los resaltados de la persona, para pintar las marcas y para marcar.
  ///
  /// Y ES **OPCIONAL**, y no por comodidad de las pruebas: sin almacen de resaltados no hay
  /// nada que marcar, y una pantalla de lectura sin ese dato **se lee igual**. Que sea
  /// opcional hace que los montajes de prueba no tengan que montar un almacen, y que no se
  /// misture "no hay resaltados" con "no se pueden leer los resaltados", que son dos cosas
  /// distintas y la segunda tiene un aviso.
  final ResaltadosViewModel? resaltados;

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

  /// Abrir el selector de libro y capitulo.
  final VoidCallback alAbrirLibros;

  /// Abrir el selector de version del texto.
  final VoidCallback alAbrirVersiones;

  /// Las versiones del catalogo, con su estado, para el selector.
  ///
  /// Y SE PREPARA FUERA Y SE PASA, y no se arma en la vista. La vista no sabe que hay un
  /// manifiesto, ni de donde sale `descargado`, y si lo supiera acabaria preguntando al
  /// almacenamiento --que es lo que `arranque.dart` hace con un plazo porque en un
  /// navegador puede no contestar-- para pintar un boton.
  final List<VersionDisponible> versiones;

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
    // Y LOS RESALTADOS TAMBIEN, y no solo el view model de la lectura.
    //
    // ============================================================================
    // MEDIDO EL 5 DE OCTUBRE DE 2026 EN UNA CAPTURA, Y NO EN UNA PRUEBA
    // ============================================================================
    //
    // Marcar un versiculo **no se veia**. La hoja se abria, se elegia un estilo, la hoja se
    // cerraba y el versiculo seguia sin fondo: twenty y cinco pruebas del view model en verde,
    // el modelo correcto, el almacenamiento correcto, y **la pantalla no se repintaba**.
    //
    // El motivo: `LectorView` escuchaba a `LectorViewModel` y solo a el, y marcar llama a
    // `notifyListeners` de `ResaltadosViewModel`, que es **otro** `ChangeNotifier`. Nada le
    // decia a la pantalla que el fondo de un versiculo habia cambiado.
    //
    // Y POR QUE NINGUNA PRUEBA LO HABRIA VISTO. Las de este change usan `vm.marcar(...)` y
    // comprueban `vm.de(...)`: el modelo. Para ver el fallo haria falta una prueba que
    // **monte la pantalla**, marque por el dedo y mire el color de fondo de un `DecoratedBox` --
    // y esa prueba es la que toca hacer ahora, y no antes.
    widget.resaltados?.addListener(_alCambiarElEstado);
    // Y LA PREFERENCIA SE LEE AL ABRIR LA PANTALLA, y no al arrancar la app. Es una
    // lectura, es idempotente, y el momento en que puede haber cambiado es justo este: si
    // se leyera al arrancar, abrir una pestana nueva --que es como se lee en el escritorio,
    // una al lado de otra-- se pintaria con el color de la primera.
    unawaited(widget.viewModel.cargarPreferencias());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambiarElEstado);
    widget.resaltados?.removeListener(_alCambiarElEstado);
    _control.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LectorView anterior) {
    super.didUpdateWidget(anterior);
    // Y SI CAMBIA EL VIEWMODEL DE RESALTADOS, se cambia la escucha. Con `resaltados`
    // opcional, un `build` puede montarlo y otro no, y sin esto la pantalla se queda
    // escuchando al viejo --o, peor, sin escuchar a ninguno-- y marcar deja de verse.
    if (anterior.resaltados != widget.resaltados) {
      anterior.resaltados?.removeListener(_alCambiarElEstado);
      widget.resaltados?.addListener(_alCambiarElEstado);
    }
  }

  void _alCambiarElEstado() {
    // El campo **no** se toca. Solo se reordena lo de arriba, que es lo que depende
    // del estado.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    // Y **SIN MARCO AQUI**, y no por descuido. El marco --el panel de herramientas o la
    // barra de destinos-- lo pone el enrutador, que envuelve **todas** las pantallas.
    //
    // Cuando estaba aqui, la barra lateral solo existia en la lectura: al pulsar
    // "Biblioteca" se salia de la barra, y la biblioteca se veia **desacoplada**, sin panel
    // y sin poder cambiar de destino. Un marco que solo envuelve una pantalla de cinco no
    // es un marco: es una decoracion de la lectura.
    return _panelConBarra(vm);
  }

  /// El `Scaffold` y la decision de si el campo va en la cabecera o en la barra de abajo.
  /// Lo que va en el `title` de la barra: la version, como rotulo de pestana.
  ///
  /// Y SE CALLA EN UN METODO Y NO EN EL `build` CON UN `case`, porque un `case` dentro de
  /// una expresion ternaria no es Dart: `x case final String n ? a : b` se lee como un
  /// identificador llamado `case`. Y el compilador dice «can't be used as an identifier
  /// because it's a keyword», que es un error de sintaxis y no dice nada de que la intencion
  /// estaba bien.
  Widget _tituloDeLaBarra(LectorViewModel vm) {
    final nombre = _nombreDeLaVersionAbierta(vm);
    if (nombre == null) return const _SinVersion();
    return _PestanaDeVersion(nombre: nombre, alPulsar: widget.alAbrirVersiones);
  }

  /// La barra de arriba, cuando este panel la tiene.
  ///
  /// Y EN UN METODO APARTE Y NO EN EL `Scaffold` EN LINEA, por un motivo concreto: con
  /// pestanas hay dos caminos --con barra y sin barra-- y con todo el `AppBar` escrito en
  /// linea habia que elegir entre "todo" y "nada", y con lo que habia que poner la barra
  /// dentro de un `if` de 80 lineas en medio de un `Column`. En un metodo son 80 lineas
  /// con nombre, y el `body` se lee sin ellas.
  PreferredSizeWidget _appBar(LectorViewModel vm) {
    return AppBar(
        titleSpacing: Medidas.margenEstrecho,
        // Y LA BARRA MIDE LOS **56 px** DE MATERIAL, y no mas, porque en ella va **solo**
        // la linea de la version. El campo de la referencia va en su propia fila debajo,
        // como en Logos.
        //
        // Y ESO NO ES UN DETALLE DE ESTILO, ES UNA MEDIDA. Con el campo dentro del `title`
        // de la barra, a 360 px los tres botones de la derecha --buscar, letras rojas,
        // comentario-- se llevan 144 px, y al campo le quedan **225**. Medido, y el campo
        // entero con sus margenes son 330.
        //
        // En su propia fila el campo tiene los **330 px** de la pantalla, y la fila son 48.
        // Antes de este change ese campo vivia **en medio del texto**, y era lo mismo: lo
        // que cambia no es el sitio dentro de la pantalla sino que **deja de competir** con
        // los botones de la barra.
        // Y EL TITULO **ES LA CABECERA**, y no un `Text` con la referencia. Es la decision
        // que mas se ve de esta pantalla y la que mas se habia tardado: la referencia y la
        // version son las dos cosas que mas se usan --una para ir a otro sitio, otra para
        // comparar-- y estaban en un icono y en ningun sitio.
        //
        // Y SON DOS LINEAS Y NO UNA CON LOS DOS NOMBRES JUNTOS. En una sola linea a 360 px
        // sale "Juan 3:16 - King James Version (2006)" recortado, y recortado es peor que
        // en dos sitios: el nombre de la version es el que se puede perder, porque se sabe
        // de memoria, y el pasaje es el que no.
        //
        // Y NO HAY ICONO DE NINGUNO DE LOS DOS. Se **ahorra** un boton, que es el problema
        // que tenia la barra --cuatro iconos y ninguno util-- en vez de anadir uno mas.
        title: _tituloDeLaBarra(vm),
        // Y **SIN FLECHA DE VOLVER**, y no por olvidado sino por decision. El panel de
        // herramientas **es** el camino de vuelta, y tener las dos cosas --una barra lateral
        // que dice "Biblioteca" y una flecha que tambien vuelve-- es no decidir cual manda.
        // En la captura de Logos no hay flecha de volver en la cabecera del panel, y la
        // razon es que no la hay en ninguna parte: la aplicacion es una ventana con
        // herramientas, no una pila de pantallas.
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
                  ? context.colores.palabraDeJesus
                  : context.colores.textoSuave,
            ),
            onPressed: widget.alAlternarPalabrasDeJesus,
          ),
          // Y EL BOTON DE **FORMATO**, que es el `Formato` de la fila de menu de Logos.
          //
          // Y ESTA DUPLICADO CON LA FILA DE MENU **A PROPOSITO**, y hay que decirlo porque
          // con las dos barras es la pregunta evident. El motivo es que las dos cosas
          // siguen siendo distintas pantallas: con un solo panel la fila de menu **no se
          // pinta** --ver `fila_de_menu.dart`, el cromo medido-- y entonces el formato
          // solo se abre desde el icono; con dos o mas, la barra **no se pinta** y el
          // formato solo se abre desde la fila. Lo que hay siempre es la funcion, y hay
          // una sola entrada visible en cada anchura.
          IconButton(
            tooltip: 'Formato de lectura',
            icon: const Icon(Icons.format_size),
            onPressed: () => abrirHojaDeFormato(
              context,
              preferencia: vm.preferenciaDeLectura,
              alCambiar: vm.cambiarPreferencia,
              alRestaurar: vm.restaurarPreferencia,
            ),
          ),
          _BotonDeComentario(
            id: vm.idDelComentario,
            alPulsar: widget.alPedirComentario,
          ),
          SizedBox(width: Medidas.margenEstrecho / 2),
        ],
      );
  }

  Widget _panelConBarra(LectorViewModel vm) {
    return Scaffold(
      appBar: widget.mostrarBarraDeAplicacion ? _appBar(vm) : null,
      body: SafeArea(
        // Y LA FILA DE LA REFERENCIA VA **DEBAJO** DE LA BARRA Y **ENCIMA** DEL TEXTO, y
        // es una fila propia con su borde. Antes de este change estaba en medio del texto
        // --con su boton de "Buscar" debajo, que eran 164 px-- y despues dentro del `title`
        // de la barra, donde le quedaban 225 px de los 330. Aqui tiene la pantalla.
        child: Column(
          children: <Widget>[
            _CabeceraDelPanel(
              campoDeReferencia: _campoDeReferencia(vm),
              flechas: _tituloConFlechas(vm),
            ),
            // Y LA FILA DE MENU **SOLO CUANDO NO HAY BARRA**, y no es una preferencia.
            //
            // Con la barra de aplicacion puesta, buscar, formato y comentario ya estan
            // en ella, y una fila de menu repetiria las tres funciones 40 px mas abajo.
            // Con varias pestanas hay una fila de pestañas arriba en vez de una barra --
            // es lo que hace Logos, y es lo que evita que dos barras compitan por el
            // ancho--, asi que las funciones tienen que estar en algun sitio, y la fila
            // de menu es el sitio donde las puso Logos.
            //
            // Y LA INVERSION ES LA QUE IMPORTA: **la fila aparece cuando desaparece la
            // barra**, nunca las dos. Medido a 1440 px, la barra son 56 px y la fila 36, y
            // las dos a la vez son 92 px de cromo por encima del primer versiculo, con la
            // fila de pestañas y la cabecera por delante. Una columna de 769 px de texto
            // no necesita eso encima.
            if (!widget.mostrarBarraDeAplicacion) ...<Widget>[
              FilaDeMenu(
                contexto: _contextoDeLaFila(vm),
                textoDelComentario: vm.idDelComentario,
                hayComentario: vm.tieneComentario,
                alBuscar: _buscarEnEstePanel,
                alNotas: () => _abrirNotasDe(vm),
                alFormato: () => abrirHojaDeFormato(
                  context,
                  preferencia: vm.preferenciaDeLectura,
                  alCambiar: vm.cambiarPreferencia,
                  alRestaurar: vm.restaurarPreferencia,
                ),
                alComentario: widget.alPedirComentario,
              ),
            ],
            Expanded(child: _cuerpo(vm)),
          ],
        ),
      ),
    );
  }

  /// Lo que la fila de menu necesita saber: si este pasaje trae notas al pie.
  ///
  /// Y SE CUENTA **CON ANCLA**, y no todas. Una nota sin ancla no tiene letra en el texto
  /// y esta hoja existe para volver a la nota desde el versiculo: sin letra es un parrafo
  /// suelto. Medido: el ancla cae dentro del versiculo en **6.956 de 6.959** notas, asi que
  /// las tres que no son la excepcion y no la regla.
  ContextoDeLaFila _contextoDeLaFila(LectorViewModel vm) {
    // Y UN PASAGE **DE NOTAS** NO TIENE NOTAS AL PIE. Un panel de comentario trae notas
    // de comentario --`Pasaje.notas`-- y no notas al pie, que son cosa de un texto de
    // Biblia. Preguntar por `versiculos` en un panel de comentario da una lista vacia, y
    // eso es correcto: en un comentario no hay glosas al pie.
    final p = vm.pasaje;
    if (p == null || p.traeNotas) {
      return const ContextoDeLaFila(
        hayNotas: false,
        textoBuscando: false,
      );
    }
    return ContextoDeLaFila.dePasaje(p.versiculos);
  }

  /// Abrir la hoja con las notas al pie de este pasaje.
  ///
  /// Y NO SE ABRE NADA SI NO HAY, y no se avisa: la entrada de la fila no se llega a ver sin
  //  notas, y si entre medias el pasaje cambia la peticion ya no tiene sentido. Devolver
  //  un `bool` permite que quien llama lo sepa sin mirar el estado del view model desde
  //  fuera, que es la regla del proyecto.
  Future<void> _abrirNotasDe(LectorViewModel vm) async {
    final p = vm.pasaje;
    if (p == null) return;
    await mostrarHojaDeNotas(
      context: context,
      versiculos: p.versiculos,
      titulo: p.referencia.texto,
    );
  }

  /// Buscar en este panel, si se puede.
  ///
  /// Y **NO HACE NADA SI NO HAY**, en vez de mirar si el callback existe: la entrada se
  /// pinta solo cuando hay algo detras --ver `fila_de_menu.dart`--, y una entrada que
  /// aparece sin hacer nada es peor que una entrada que no aparece.
  void _buscarEnEstePanel() => widget.alBuscar?.call();

  /// Marcar o quitar el resaltado de un versiculo.
  ///
  /// Y ABRE LA HOJA DE ESTILOS Y **ESPERA A QUE SE ELIJA UNO**, y no pone nada antes: elegir
  /// el estilo **es** marcar. Y si vuelve null, es que se ha cerrado sin elegir o se ha
  /// pulsado "quitar", y entonces lo que se hace es quitar.
  Future<void> _marcar(
    LectorViewModel vm,
    String libro,
    int capitulo,
    int versiculo,
  ) async {
    final r = widget.resaltados;
    if (r == null) return;

    final actual = r.de(libro, capitulo, versiculo);
    final elegido = await elegirEstilo(
      context,
      estilos: r.estilos,
      estiloActual: actual?.estilo,
      hayResaltado: actual != null,
    );
    if (!mounted) return;

    // Y LAS **TRES** SALIDAS, y la de cerrar sin hacer nada **no toca nada**. Ver la nota de
    // `EleccionDeResaltado`: con un unico `null` para "cerrar" y para "quitar", un toque de
    // mas fuera de la hoja te borraba el resaltado que tenias.
    if (elegido == null) return;

    if (elegido.quita) {
      await r.quitar(libro, capitulo, versiculo);
      return;
    }
    await r.marcar(libro, capitulo, versiculo, elegido.estilo!.id);
  }

  Widget _cuerpo(LectorViewModel vm) {
    // Y EL TEXTO DE LECTURA SALE DE LA PREFERENCIA, y no de un `copyWith` con numeros
    // escritos aqui. Los tres valores --tamano, alto de linea y espaciado-- estan en
    // `estiloDeLectura`, y el motivo de que no esten aqui es que este `copyWith` era
    // **inmutable y silencioso**: cambiar el valor por defecto no lo cambiaba, porque el
    // numero estaba en la linea de al lado y no en ningun sitio al que se pudiera mirar.
    final estiloVersiculo = estiloDeLectura(
      Theme.of(context).textTheme,
      widget.viewModel.preferenciaDeLectura,
    );


    // ================================================================================
    // Y LA APERTURA DE LA LINEA QUE SE ESTA LEYIENDO, QUE HASTA AHORA NO EXISTIA
    // ================================================================================
    //
    // El conmutador de la hoja de formato se llama «Linea enfocada», ofrece apagada, una,
    // tres y cinco lineas, **guarda la preferencia** y no lo miraba nadie: ni este view model
    // sabia que el campo existia, ni la vista. Un boton que promete y no pasa nada, que es la
    // version con cara de usuario del fallo que `AGENTS.md` ya documenta con
    // `alCambiarDeVersion` --«una funcion sin llamador no falla nunca»--.
    //
    // Y EL ALTO DE LINEA SALE DE `estiloVersiculo`, que **ya** tiene el tamano de letra y el
    // alto de linea de la preferencia multiplicados. No se vuelven a multiplicar aqui: son las
    // mismas dos cifras en dos sitios y un dia divergen, que es lo que paso con el margen de
    // la fila --`14` escrito en un sitio y `margenPara` en otro-- que esta en `AGENTS.md`.
    return LineaEnfocada(
      lineas: widget.viewModel.preferenciaDeLectura.lineaEnfocada,
      altoDeLinea: _altoDeUnaLinea(estiloVersiculo),
      // Y LA SELECCION, QUE **NO EXISTIA**.
      //
      // MEDIDO EL 6 DE OCTUBRE DE 2026: un `grep` de `SelectionArea`, `SelectableRegion` y
      // `SelectableText` en toda la aplicacion no devuelve **nada**. No hay forma de
      // seleccionar un versiculo. Y el codigo de aqui mismo, treinta lineas mas abajo, dice
      //
      //     tocarlo lo selecciona --que es lo que quiere quien copia un versiculo--
      //
      // O sea: el comentario describe una capacidad que no esta implementada, y el que lo
      // leeria creeria que seleccionar funciona. Con este `SelectionArea` por fin es verdad.
      //
      // Y VA **UNO** ALREDEDOR DE TODA LA COLUMNA Y NO UNO POR VERSICULO, porque si no no se
      // puede seleccionar a caballo de dos versiculos --«...en el principio... / ...creo la
      // tierra»-- que es justo lo que se copia.
      hijo: SelectionArea(
      child: ColumnaDeTexto(
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
                // Y EL CUERPO **EMPIEZA POR LAS MIGAS**, no por el campo. Medido a 360 px
                // antes de este cambio: el campo y su boton eran 164 px, mas 48 px de
                // flechas en su propia fila, y eran **212 px por encima del primer
                // versiculo**. Los dos han subido a la cabecera del panel --que es donde
                // Logos tiene la referencia-- y aqui solo queda una linea de 32 px que
                // ademas dice algo que antes no decia en ninguna parte: como se llama el
                // libro.
                _MigasDelLibro(
                  referencia: vm.leyendo,
                  alPulsar: widget.alAbrirLibros,
                ),
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

          MargenDeLectura(hijo: _NumeroDeCapitulo(capitulo: vm.leyendo?.capitulo)),

          MargenDeLectura(hijo: _capitulo(vm, estiloVersiculo)),

          // Y LAS NOTAS AL PIE VAN **DESPUES** DEL CAPITULO Y **ANTES** DE LOS TERMINOS.
          //
          // Y NO ES COSMETICA: la lista de notas pertenece al capitulo que se acaba de leer,
          // asi que va pegada a el. Y los terminos del modulo --la licencia, la atribucion-- son
          // de otra cosa: son del **fichero**, no del capitulo, y van al final de todo. Poner
          // los terminos antes haria que al bajar al final de Juan 3 apareciera una linea de
          // licencia antes que las notas de Juan 3, que es justo al reves de como se lee.
          MargenDeLectura(
            hijo: NotasAlPieDelCapitulo(
              // Y SOLO CUANDO EL PASAJE **TRAIGA VERSICULOS**. Un pasaje de comentario no
              // tiene, y sus notas las pinta `_ColumnaDeNotas` debajo de cada versiculo, con
              // otra regla: alli la nota va pegada a su versiculo porque es lo unico que hay.
              versiculos: vm.pasaje?.traeNotas == true
                  ? const <Versiculo>[]
                  : vm.pasaje?.versiculos ?? const <Versiculo>[],
            ),
          ),

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
      ),
      ),
    );
  }

  /// El alto de **una** linea de lectura, en pixeles.
  ///
  /// Y `fontSize` POR `height`, y en ese orden: `TextStyle.height` es un **multiplicador**, no
  /// un alto en pixeles. Con 18 px de letra y 1,6 de alto de linea el alto real es de 28,8 px, y
  /// una banda de «tres lineas» son 86,4 px. Tomarse `height` como si fueran pixeles daria una
  /// banda de 4,8 px, que es mas fina que una linea de texto y no tapa nada.
  double _altoDeUnaLinea(TextStyle estilo) {
    final tamano = estilo.fontSize ?? 18;
    final alto = estilo.height ?? 1.6;
    return tamano * alto;
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

    // Y SIN EL TITULO NI LA FLECHA DE VOLVER: los dos estan ya en la barra de arriba, y
    // medidos costaban 40 px por encima del primer versiculo. Ver `FlechasDeCapitulo`.
    return FlechasDeCapitulo(
      hayAnterior: anterior != null,
      haySiguiente: siguiente != null,
      // Con `!` porque los botones estan deshabilitados cuando no hay capitulo, y
      // un boton deshabilitado no llama. Si alguna vez los llamara, el `!` dira que
      // se llego aqui con un null, que es mejor que una excepcion en pantalla.
      alAnterior: () => widget.alPulsarPasaje(Referencia(r.libro, anterior!)),
      alSiguiente: () => widget.alPulsarPasaje(Referencia(r.libro, siguiente!)),
    );
  }

  // --- el capitulo ---

  Widget _capitulo(LectorViewModel vm, TextStyle estilo) {
    // Y LOS ESTILOS DE LOS RESALTADOS DE ESTE CAPITULO, **UNA VEZ**, y no uno por versiculo.
    //
    // El view model puede tener miles de resaltados y el capitulo tiene 36 versiculos:
    // recorrer la lista entera por cada versiculo que se pinta son 36 mil comparaciones por
    // capitulo abierto, y eso es lo que hace que el lector vaya lento sin que se note el
    // motivo. Con el mapa ya hecho, es una busqueda por numero de versiculo.
    //
    // Y LA RAZON DE QUE ESTE **AQUI** Y NO EN EL `build`: este metodo es el que pinta el
    // capitulo, y antes estaba en el `build` de la vista, que se ejecuta tambien al abrir la
    // hoja de formato y al cambiar el tema. Calcular el mapa en el `build` es hacerlo treinta
    // veces por cada cambio de tema.
    final estilosDelCapitulo = <int, EstiloDeResaltado>{};
    final referencia = vm.leyendo;
    final vmResaltados = widget.resaltados;
    if (referencia != null && vmResaltados != null) {
      estilosDelCapitulo.addAll(
        vmResaltados.estilosDelCapitulo(referencia.libro, referencia.capitulo),
      );
    }

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
                // Y SI ESTE ES EL VERSICULO QUE SE PIDIO. Un enlace a Juan 3:16 abre el
                // capitulo entero desde el 16, y el 16 queda en **color** para que se vea
                // de donde se salio. Sin esto, un enlace a un versiculo abre un capitulo
                // y no dice nada de cual era.
                esElPedido: p.esElPedido(v.numero),
                // Y EL ESTILO DEL RESALTADO DE ESE VERSICULO, que llega ya resuelto desde
                // `estilosDelCapitulo`: una vez por capitulo abierto, no una vez por versiculo.
                estiloDelResaltado: estilosDelCapitulo[v.numero],
                alMarcar: () => _marcar(vm, p.referencia.libro, p.referencia.capitulo, v.numero),
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
    return bytesEnCastellano(modulo.tamanoBytes);
  }

  /// El nombre de la version que esta abierta, o null si no hay ninguna.
  ///
  /// Y SE BUSCA EN `versiones`, que es la lista que trae el estado. Si se buscara en
  /// `modulosDelCatalogo` saldria el nombre tambien para un modulo que no esta
  /// descargado, que es un nombre de una traduccion que no se esta leyendo.
  String? _nombreDeLaVersionAbierta(LectorViewModel vm) {
    final id = vm.idDelModulo;
    if (id == null) return null;
    for (final v in widget.versiones) {
      if (v.id == id) return v.nombre;
    }
    return null;
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
                    ?.copyWith(color: context.colores.textoSuave),
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
            Divider(height: 26, thickness: 1, color: context.colores.linea),
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
            color: context.colores.acento.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: context.colores.acento.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$versiculo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colores.acento,
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
              color: context.colores.acento.withValues(alpha: 0.45),
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
/// La cabecera de la pantalla de lectura: el pasaje y la version.
///
/// Y ES UNA CLASE SUELTA Y NO UN `title:` CON UN `Column`, por una razon que se ve al
/// usarla en un movil: un `title` de `AppBar` con dos lineas **centra verticalmente** y no
/// se deja alinear arriba, asi que el pasaje queda a media altura y la version pegada al
/// suelo de la barra, y en una barra de 56 px eso son ocho pixeles de hueco entre las dos
/// lineas y ninguna se lee bien.
///
/// Y LAS DOS LINEAS SON PULSABLES, y cada una hace lo suyo: el pasaje abre el selector de
/// libro y capitulo, y la version abre el selector de texto. Es la division que usa todo
/// el mundo --YouVersion y Logos-- y es la que hace que una cabecera con dos lineas no sea
/// un adorno sino el sitio donde estan las dos cosas que mas se tocan.
///
/// Y LA LINEA DE LA VERSION SE PINTA EN `bodySmall` Y NO EN `titleSmall`, y con el color
/// suave. Es un dato secundario --se sabe de memoria cual es la version-- y del mismo modo
/// el pasaje es el dato primario. Al reves, las dos lineas del mismo peso hacen que la
/// version parezca tan importante como el pasaje y no lo es.
///
/// Y CUANDO NO HAY VERSION NO SE PINTA LA LINEA, y no un hueco. Un modulo sin manifiesto al
/// que pertenece deja la cabecera a una linea y no con un espacio vacio que empuja el
/// texto hacia abajo.
/// La decoracion de un versiculo: el fondo del resaltado, su contorno y la marca del pedido.
///
/// Y EN UN SITIO Y NO EN EL CUATRO `BorderSide` EN LINEA, y no por legibilidad.
///
/// La primera version de esto escribia los cuatro lados uno a uno, cada uno con su
/// condicional de "si hay resaltado", que son **cuatro** copias de la misma pregunta y
/// cuatro sitios donde equivocarse. Y con el error de la linea de pelo: un `BorderSide` de
/// ancho `0` con `BorderRadius` distinto de cero **no se puede pintar**, y el framework avisa
/// al pintar, que es despues de que todas las pruebas de construccion hayan pasado.
BoxDecoration _decoracionDelResaltado({
  required Color? color,
  required Color contorno,
  required double grosor,
  required Color acento,
  required bool esElPedido,
}) {
  final marcaDelPedido = BorderSide(color: acento, width: 3);
  final ladoDelResaltado = grosor > 0
      ? BorderSide(color: contorno, width: grosor)
      // Y SIN UN BORDE EN LUGAR DE UNO DE ANCHO CERO. Un `BorderSide.none` **no** es una
      // linea de pelo: no pide pintar nada, y con el radio no hay problema.
      : BorderSide.none;

  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(4),
    border: Border(
      left: esElPedido ? marcaDelPedido : ladoDelResaltado,
      top: ladoDelResaltado,
      right: ladoDelResaltado,
      bottom: ladoDelResaltado,
    ),
  );
}

/// La clave del fondo del resaltado de un versiculo, para las pruebas.
///
/// Y ES PUBLICA Y ES UNA CONSTANTE, y no un literal escrito en la prueba, porque aparece en dos
/// sitios --la vista que lo pinta y la prueba que lo busca-- y si uno de los dos cambia el
/// nombre, el otro deja de encontrarlo y el fallo dice "0 widgets" sin decir de donde.
const Key claveDelFondoDelResaltado = ValueKey<String>('fondoDelResaltado');

/// La clave del numero de un versiculo, para las pruebas.
///
/// Y ES UNA CONSTANTE PUBLICA Y NO UN LITERAL EN CADA PRUEBA, porque el mismo numero
/// aparece en tres sitios --la vista que lo pinta, la prueba que lo busca y la prueba que
/// cuenta la columna-- y si uno de los tres cambia el nombre, las otras dos dejan de
/// encontrarlo y el fallo dice "0 widgets" sin decir de donde.
const Key claveDelNumeroDeVersiculo = ValueKey<String>('numeroDeVersiculo');

/// La fila de la referencia, debajo de la barra y encima del texto.
///
/// ============================================================================
/// POR QUE ESTO NO ES LA BARRA
/// ============================================================================
///
/// Comparada con la cabecera del panel de Logos, la distribucion estaba del reves:
///
///   - En Logos la **version identifica la pestana** --arriba, en la tira-- y la
///     **referencia es un campo** en su propia fila de cabecera.
///   - Aqui las dos cosas estaban en la barra, una encima de otra, y el campo en medio
///     del texto.
///
/// Que la version sea la pestana no es un detalle de maquetacion: es lo que hace que
/// "tengo dos textos abiertos" sea una cosa que se pueda **ensenar**. Una tira de
/// pestanas dice RVR60 y JFB; dos lineas de texto en una barra no dicen eso.
///
/// Y POR QUE UNA FILA Y NO DENTRO DE LA BARRA. Medido a 360 px: los tres botones de la
/// derecha --buscar, letras rojas, comentario-- son **144 px**, y dentro del `title` al
/// campo le quedan **225** de los 330 que mide la pantalla. En su propia fila tiene los
/// 330.
///
/// Y ES UNA FILA DE **48 px**, no mas. Con el borde de abajo, porque en Logos la fila de
/// la cabecera esta separada del texto por una linea, y sin ella el campo flota encima de
/// los versiculos y parece un texto suelto.
class _CabeceraDelPanel extends StatelessWidget {
  const _CabeceraDelPanel({
    required this.campoDeReferencia,
    required this.flechas,
  });

  final Widget campoDeReferencia;
  final Widget flechas;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colores.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colores.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          4,
          Medidas.margenEstrecho,
          4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Y EL CAMPO **NO** SE ESTIRA. A 360 px --sin panel de herramientas-- mide lo que
            // queda, que son 248 px. Con panel, se queda en **360** y el resto de la fila
            // queda vacio a la derecha, que es lo que hay en la captura de Logos: el campo
            // de la referencia es una caja corta a la izquierda de la fila de cabecera y a
            // su derecha van los menus del panel, que aqui todavia no existen.
            //
            // Estirado a 1440 --1.260 pixeles-- el campo parece la pagina de busqueda de
            // una aplicacion y no la cabecera de un panel de lectura, y el hueco de la
            // derecha queda como un error de maquetacion en vez de como sitio reservado.
            //
            // Y CON UN **TOPE**, Y NO CON UN `Flexible` SUELTO, porque un `Flexible` sin
            // `fit` deja que el hijo pida lo que quiera y un `TextField` pide todo: la
            // primera version de esta fila usaba `Expanded` y despues `Flexible`, y en las
            // dos capturas de 1440 el campo seguia ocupando los 1.260 px. Lo que hace falta
            // es un `maxWidth`, no una regla de reparto.
            //
            // Y DENTRO DE UN `Flexible` SUELTO, Y NO SUELTO A SECO. Un hijo **no flexible**
            // de una `Row` recibe del alto principal una restriccion **sin limite**, y un
            // `TextField` con ancho sin limite pide infinito: la fila se sale y los
            // versiculos no se ven. El `Flexible` pone el limite de la fila y el
            // `ConstrainedBox` pone el de 360, que es el mas pequeno de los dos.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: campoDeReferencia,
              ),
            ),
            const SizedBox(width: 4),
            flechas,
          ],
        ),
      ),
    );
  }
}

/// Lo que se ve en la barra cuando no hay manifiesto y, por tanto, no hay version.
///
/// Y NO UN HUECO. Una barra de 56 px con un `Text` que pone "Leyendo" en el sitio donde
/// deberia ir la version no dice nada; un hueco de 56 px dice que se esta cargando algo, y
/// no se esta cargando nada. Y "Leyendo" se queda en la fila de la referencia, que es donde
/// esta el pasaje.
class _SinVersion extends StatelessWidget {
  const _SinVersion();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// El rotulo de la version, que hace de pestana.
///
/// Y ES UN BOTON, porque abre el selector de versiones. Y lleva un cuadrado de color a la
/// izquierda como en Logos, y ese cuadrado **no finge un color**: con una sola version
/// descargada no hay con que comparar, asi que va en el color de superficie, que es lo que
/// se ve de verdad. Un cuadrado de color que significa "esto es una version y se puede
/// comparar" sin que se pueda comparar es peor que no ponerlo.
class _PestanaDeVersion extends StatelessWidget {
  const _PestanaDeVersion({required this.nombre, required this.alPulsar});

  final String nombre;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$nombre. Cambiar de version',
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colores.surfaceContainerHighest,
                  border: Border.all(color: colores.outlineVariant),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  nombre,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: colores.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las migas del libro, encima del texto.
///
/// Y ES LO PRIMERO DEL CUERPO. Medido a 360 px antes de este change: el campo y su boton
/// eran 164 px, y las flechas de capitulo 48 px mas su hueco, y eran **212 px por encima
/// del primer versiculo** en una pantalla de 760. Los dos han subido a la cabecera del
/// panel.
///
/// Y ADEMAS DIJE ALGO QUE ANTES NO SE DECIA EN NINGUN SITIO: como se llama el libro. En
/// Logos esta el nombre del libro --"San Juan", "The Gospel according to John"-- y es un
/// salto al selector de libros. Aqui solo aparecia dentro del texto de la referencia, y no
/// como algo pulsable.
///
/// Y VA EN `bodySmall` Y CON COLOR SUAVE, y no en `titleMedium`, porque es una posicion en
/// el libro y no el titulo de la pagina. En grande compite con el numero de capitulo, que va
/// justo debajo.
class _MigasDelLibro extends StatelessWidget {
  const _MigasDelLibro({required this.referencia, required this.alPulsar});

  final Referencia? referencia;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final r = referencia;
    if (r == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        label: '${r.nombreLibro} ${r.capitulo}. Elegir libro y capitulo',
        child: InkWell(
          onTap: alPulsar,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: <Widget>[
                Icon(Icons.menu_book_outlined,
                    size: 15, color: context.colores.textoSuave),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${r.nombreLibro} ${r.capitulo}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.colores.textoSuave),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El numero de capitulo, antes de los versiculos.
///
/// Y VA DENTRO DE LA COLUMNA DE LECTURA, y no centrado en la ventana. El motivo es el
/// mismo que el de las migas: si se sale de la columna, el texto deja de tener un sitio fijo
/// al que volver el ojo, y en un capitulo largo --Salmos 119, 176 versiculos medido-- eso es
/// justo lo que hace falta.
///
/// Y ES UN NUMERO Y NO UN TITULO. "Capitulo 1" ocupa media linea y no dice nada que el 1 no
/// diga; el 1 solo, en grande y ligero, es lo que pone un libro impreso.
class _NumeroDeCapitulo extends StatelessWidget {
  const _NumeroDeCapitulo({required this.capitulo});

  final int? capitulo;

  @override
  Widget build(BuildContext context) {
    final c = capitulo;
    if (c == null) return const SizedBox.shrink();

    // Y EN `headlineLarge`, Y NO EN `displaySmall`.
    //
    // La primera version lo puso en `displaySmall` --36 px-- y en una captura a 360 px el
    // numero se comia **72 pixeles de alto**, que es un 9 % de la pantalla para un digito.
    // En `headlineLarge` son 32 px y con `letterSpacing` se separa, que es lo que hace que
    // se lea como un capitulo y no como un titular.
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Center(
        child: Text(
          '$c',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: context.colores.textoSuave,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
        ),
      ),
    );
  }
}


class _BotonDeComentario extends StatelessWidget {
  const _BotonDeComentario({required this.id, required this.alPulsar});

  final String? id;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final hay = id != null;

    // Y ES UN **ICONO** Y NO UN BOTON CON TEXTO, y esto se cambio al medir, no por gusto.
    //
    // MEDIDO A 360 PX con las dos lineas de cabecera y el boton con su texto: el hueco que
    // le quedaba al titulo era de **13,9 pixeles**. Trece. El nombre de la version y el
    // pasaje no cabian en trece pixeles, y lo que se veia era un titulo recortado en seco
    // y un `overflow` de 6 pixeles en cada linea.
    //
    // Y LA PALABRA "Comentario" SE LLEVA **110 PIXELES** SOLA. Con icono se le quedan 48,
    // y esos 62 pixeles son los que hacen que "Juan 3:16" y "King James Version (2006)"
    // quepan en una barra de 360.
    //
    // Y NO SE PIERDE NADA, porque el estado **ya estaba en el icono** --con color-- y el
    // identificador exacto estaba en el `tooltip`, que es donde lo busca la gente que quiere
    // saber que comentario tiene abierto y no solo que hay uno.
    return IconButton(
      tooltip: hay
          ? 'El comentario es $id. Púlsalo para cambiarlo o quitarlo.'
          : 'Poner un comentario al lado del texto',
      icon: Icon(
        hay ? Icons.comment : Icons.comment_outlined,
        size: 20,
        color: hay ? context.colores.acento : context.colores.textoSuave,
      ),
      onPressed: alPulsar,
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
        color: context.colores.acento.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colores.linea),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 20, color: context.colores.textoSuave),
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
    required this.esElPedido,
    required this.estiloDelResaltado,
    required this.alMarcar,
  });

  final Versiculo versiculo;
  final TextStyle estilo;

  /// El estilo con el que esta marcado, o null si no esta marcado.
  ///
  /// Y LLEGA **YA RESUELTO** y no el [Resaltado] entero, porque el versiculo solo necesita
  /// saber el color y la forma; y llega resuelto porque la busqueda del estilo por id es la
  /// que hace el view model, una vez por capitulo, y no una vez por versiculo.
  final EstiloDeResaltado? estiloDelResaltado;

  /// Tocar el numero para marcar o quitar.
  final VoidCallback alMarcar;

  /// Si este es el versiculo que se pidio en la URL.
  ///
  /// Y EL NUMERO **NO** CAMBIA. Se mantiene en su columna de 34 px para todos, porque una
  /// columna de versiculos con numeros desalineados no se puede leer como una columna. Lo
  /// que cambia es el **color** del texto, que es lo que permite ver el punto de partida
  /// sin romper la columna.
  final bool esElPedido;

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
  List<LongPressGestureRecognizer?>? _gestores;

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
    for (final g in _gestores ?? const <LongPressGestureRecognizer?>[]) {
      g?.dispose();
    }
    _gestores = null;
  }

  List<LongPressGestureRecognizer?>? _crearGestores(Versiculo v) {
    if (v.anotaciones.isEmpty) return null;
    return <LongPressGestureRecognizer?>[
      for (var i = 0; i < v.palabras.length; i++)
        if (i < v.anotaciones.length && v.anotaciones[i].strong != null)
          // Y UN GESTOR POR PALABRA **CON NUMERO**, y no por palabra. Una palabra sin
          // numero no es pulsable porque no hay nada a que ir: el indice es de numeros.
          //
          // ========================================================================
          // Y ES **PULSACION LARGA** Y NO UN TOQUE, y este cambio sale de un fallo medido
          // ========================================================================
          //
          // MEDIDO EL 6 DE OCTUBRE DE 2026: un `grep` de `SelectionArea` y `SelectableRegion`
          // en toda la aplicacion no devuelve nada, y a la vez tocar una palabra se iba al
          // indice de golpe. Son **el mismo problema** visto de dos maneras, y no por casual:
          // el lexicon del KJV tiene **348.884 ocurrencias en 31.102 versiculos**, o sea que
          // casi todas las palabras tienen numero. Con un toque por palabra, tocar el texto
          // es casi siempre abrir el indice.
          //
          // Y CON UN `TapGestureRecognizer` SOBRE EL TEXTO SELECCIONABLE, EL TOCO SE LLEVA LA
          // SELECCION. Es el gesto que pide el dedo al tocar, asi que el framework lo resuelve
          // para el que gana, y el que gana no es el de seleccionar. Quien quiere copiar un
          // versiculo no puede ni empezar: toca, y se va al indice.
          //
          // Y LA PULSACION LARGA ES EL GESTO **LIBRE** DE LA SELECCION: en Flutter es lo que
          // arranca el selection de un texto, con el dedo o con el raton. Con el indice en la
          // pulsacion larga, los dos gestos dejan de pelear y ademas se parecen a lo que hace
          // la gente en los otros lectores, donde la palabra se revela al mantenerla pulsada.
          //
          // Y NO SE PIERDE NADA: la pulsacion larga tambien era el gesto de seleccionar. Lo
          // que se hace es decidir, de los dos gestos que ya existian, cual de los dos
          // **nombres** el indice --que es una accion de lectura-- y cual selecciona.
          LongPressGestureRecognizer()
            ..onLongPress = () => widget.alVerIndice(v.anotaciones[i].strong!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.versiculo;
    final anotaciones = v.anotaciones;

    // Y ESTA RAMA ES SOLO PARA EL VERSICULO SIN ANOTACIONES **Y SIN NOTAS**. Con notas pero
    // sin anotaciones --que es el caso de un modulo sin lexicon-- hace falta el camino de
    // abajo, porque si no la letra de la nota no se veria. Y se ha visto: la primera version
    // de esto separaba las dos cosas y un versiculo con nota y sin lexicon salia sin letra.
    if (anotaciones.isEmpty && v.notas.isEmpty) {
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
    // Y LA LETRA DE LA NOTA VA **PEGADA A LA PALABRA**, y por eso se mete en el mismo
    // `TextSpan` de la palabra y no en una fila aparte: es una letra en superindice al final
    // de la palabra a la que el modulo la engancho, que es lo que hace Logos y lo que hace
    // una Biblia impresa.
    //
    // Y SI DOS NOTAS CAEN EN LA MISMA PALABRA, SE PONEN LAS DOS SEGUIDAS, y no se pierde
    // ninguna: hay versiculos con dos notas en la misma palabra y con una sola se ensenaria
    // media nota sin avisar.
    final letras = <int, List<String>>{};
    for (final n in v.notas) {
      final a = n.ancla;
      if (a == null) continue;
      // Y [NotaAlPie.ancla] ES **CUANTAS PALABRAS HAY ANTES** de la nota, no el indice de la
      // palabra: asi es como se cuenta y asi queda escrito en el parser. La letra se pinta
      // **despues** de la palabra que va justo antes, o sea en el indice `a - 1`, y con `a == 0`
      // --una nota antes de la primera palabra-- antes de la primera, que es donde va.
      //
      // Y ESO HACE QUE `a` PUEDA VALER EL NUMERO DE PALABRAS, que es lo que significa "la nota
      // va despues de la ultima palabra". Medido: asi pasa en 1Cronicas 1:6, cuya nota va
      // detras de `Togarmah.`. Sin esta regla, `letras[a]` con `a` fuera de rango no pintaba
      // nada y la letra se perdia en silencio.
      final donde = a == 0 ? 0 : a - 1;
      (letras[donde] ??= <String>[]).add(n.letra);
    }

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
            // Y LA LETRA CON SU PROPIO ESTILO, porque si herudara el de la palabra --que
            // puede ser rojo si es de Jesus, o tener el subrayado del resaltado-- la letra
            // pareciera parte de la palabra. Y VA EN `textoSuave`, que es informacion
            // secundaria y no Escritura, y le basta el umbral de 4,5:1.
            for (final letra in letras[i] ?? const <String>[])
              TextSpan(
                text: letra,
                style: widget.estilo.copyWith(
                  fontSize: widget.estilo.fontSize! * 0.62,
                  height: 1.0,
                  color: context.colores.textoSuave,
                ),
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
      // Y LOS COLORES DE **AQUI**, que es el unico sitio que tiene contexto. La funcion de
      // estilo sigue siendo pura, y quien la llama es un widget.
      palabraDeJesus: context.colores.palabraDeJesus,
      textoSuave: context.colores.textoSuave,
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
    required this.esElPedido,
    required this.estiloDelResaltado,
    required this.alMarcar,
  });

  final Versiculo versiculo;
  final TextStyle estilo;

  /// El estilo con el que esta marcado, o null si no esta marcado.
  ///
  /// Y LLEGA **YA RESUELTO** y no el [Resaltado] entero, porque el versiculo solo necesita
  /// saber el color y la forma; y llega resuelto porque la busqueda del estilo por id es la
  /// que hace el view model, una vez por capitulo, y no una vez por versiculo.
  final EstiloDeResaltado? estiloDelResaltado;

  /// Tocar el numero para marcar o quitar.
  final VoidCallback alMarcar;

  /// Si este es el versiculo que se pidio en la URL.
  ///
  /// Y EL NUMERO **NO** CAMBIA. Se mantiene en su columna de 34 px para todos, porque una
  /// columna de versiculos con numeros desalineados no se puede leer como una columna. Lo
  /// que cambia es el **color** del texto, que es lo que permite ver el punto de partida
  /// sin romper la columna.
  final bool esElPedido;

  /// Pasa de la palabra al indice. Se pasa de uno a otro porque `_Versiculo` esta en medio
  /// y no sabe que hay un indice detras.
  final void Function(String numero) alVerIndice;

  /// Si las palabras de Jesus van en rojo. Tambien se pasa de uno a otro, y por lo mismo.
  final bool mostrarPalabrasDeJesus;

  @override
  Widget build(BuildContext context) {
    // Y EL VERSICULO PEDIDO SE PINTA CON UN MARGEN IZQUIERDO Y UN FONDO, y no con otro
    // color de texto. El texto de la Escritura no cambia de color: lo que se pinta es el
    // **margen** de una linea vertical, que es como se marca un pasaje en un libro
    // impreso y no le quita nada al texto. Y con el color de acento, que contrasta 7,1:1
    // con el fondo y es el mismo color de los demas enlaces.
    final estiloDelVersiculo = esElPedido
        ? estilo.copyWith(color: context.colores.acento, fontWeight: FontWeight.w500)
        : estilo;

    // Y EL FONDO DEL **RESALTADO**, y va en el `DecoratedBox` de fuera del texto y **no** en
    // el `TextSpan`. Que el color vaya por delante del texto haria la Escritura ilegible con
    // un resaltado fuerte, y un resaltado que no deja leer es un resaltado que estorba: por eso
    // va detras, y por eso el numero y el texto quedan **dentro** del `DecoratedBox`.
    //
    // Y CUANDO NO HAY NADA QUE PINTAR, **NO HAY DECORACION**. Un `BorderSide` de ancho 0 con
    // unas esquinas redondeadas no se puede pintar, y el framework avisa al pintar:
    //
    //     A hairline border like `BorderSide(width: 0.0, style: BorderStyle.solid)` can only
    //     be drawn when BorderRadius is zero or null.
    //
    // La primera version de esto ponia los cuatro `BorderSide` siempre, con `width: 0` cuando
    // no tocaba, y con `BorderRadius.circular(4)` siempre. Son las dos mitades de un mismo
    // error: un borde de ancho **cero** es una linea de pelo, y una linea de pelo con radio
    // no se dibuja. Y el fallo sale **al pintar**, que es despues de que todas las pruebas de
    // construccion hayan pasado.
    final estiloResaltado = estiloDelResaltado;
    final decoracionDelResaltado = esElPedido || estiloResaltado != null
        ? _decoracionDelResaltado(
            color: estiloResaltado == null ? null : colorDeFondo(estiloResaltado),
            // Y EL `?? Colors.transparent` Y NO UN `?:` CON NULL, porque `contorno` es
            // `Color` y no `Color?`. Un null aqui seria un borde de color desconocido, y lo
            // que se quiere es "sin contorno", que es `grosor == 0`, y eso lo decide el
            // `grosor` de abajo.
            contorno: estiloResaltado == null
                ? Colors.transparent
                : colorDeContorno(estiloResaltado) ?? Colors.transparent,
            grosor: estiloResaltado == null ? 0 : grosorDeContorno(estiloResaltado) ?? 0,
            acento: context.colores.acento,
            esElPedido: esElPedido,
          )
        : const BoxDecoration();

    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: esElPedido ? 6 : 0),
      child: DecoratedBox(
        // Y LA CLAVE, PORQUE SIN ELLA LA PRUEBA DEL FONDO NO SE PUEDE ESCRIBIR.
        //
        // Con `find.ancestor` hay que adivinar cual de los `DecoratedBox` de la fila es el
        // del resaltado, y hay varios: el del texto con los numeros del lexicon, el del
        // versiculo pedido. Adivinar da una prueba que **pasa comprobando el decorado
        // equivocado**, que es lo mismo que paso con `claveDelNumeroDeVersiculo` y el 3 de mas
        // que salia como versiculo.
        key: claveDelFondoDelResaltado,
        decoration: decoracionDelResaltado,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Y EL NUMERO ES UN **BOTON** Y EL TEXTO NO, y esa es la distincion que hace que
          // marcar no rompa seleccionar.
          //
          // Con el texto en un `Text` normal, tocarlo lo selecciona --que es lo que quiere
          // quien copia un versiculo-- y no abre la hoja. Con el numero en un boton, tocarlo
          // marca. Los dos gestos usan el dedo y van a sitios distintos, y no se pisan.
          SizedBox(
            width: 34,
            child: TextButton(
              onPressed: alMarcar,
              // Y SIN ESTILO DE BOTON. Un `TextButton` pinta fondo y tinta, y un numero de
              // versiculo con fondo al pulsarse parece un versiculo seleccionado. Se deja el
              // fondo transparente y solo se cambia el color al pulsarse, que es lo unico que
              // hace falta para que el dedo sepa donde ha tocado.
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: context.colores.textoSuave,
                padding: EdgeInsets.zero,
                minimumSize: const Size(34, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
              '${versiculo.numero}',
              // Y LA CLAVE, PORQUE SIN ELLA LAS PRUEBAS RECOGEN EL NUMERO DEL CAPITULO.
              // El numero de capitulo que ahora va antes de los versiculos tambien es un
              // `Text` con un numero entero, y la prueba que recogia "los numeros de
              // versiculo visibles" devolvia `[3, 36]` al abrir Juan 3: **un 3 de mas** que
              // es el capitulo. La prueba daba verde con 37 versiculos visibles.
              key: claveDelNumeroDeVersiculo,
              textAlign: TextAlign.right,
              style: estiloDelVersiculo.copyWith(
                fontSize: 13,
                color: context.colores.textoSuave,
                height: 1.9,
              ),
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
              esElPedido: esElPedido,
              // Y ESTOS DOS VAN AQUI Y NO EN LA LLAMADA DE ARRIBA, y el motivo es que
              // `_TextoDelVersiculo` es el que **pinta las palabras** y es quien sabe si un
              // versiculo lleva una palabra con numero de lexicon pulsable. Pasarselos por
              // el `TextSpan` haria que se tuvieran que resolver aqui, en un sitio donde no
              // hay contexto de lectura.
              estiloDelResaltado: estiloDelResaltado,
              alMarcar: alMarcar,
            ),
          ),
        ],
      ),
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
