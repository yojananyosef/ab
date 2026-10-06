// La pantalla de biblioteca: la lista de lo que se puede leer.
//
// QUE HAY Y QUE NO HAY EN UNA VISTA. Solo pinta. No lee ficheros, no hace
// peticiones, no calcula el estado de nada: eso es del ViewModel. Si aqui hay un
// `if (modulo.tamanoBytes > 0)` es un bug de arquitectura, aunque compile.
//
// LO QUE SE ENSENA Y EN QUE ORDEN, Y POR QUE. Primero el aviso de "estoy usando una
// copia guardada", porque es lo que cambia lo que uno ve y no puede deducir. Despues
// el titulo, el filtro, la lista, y al final el vacio con su explicacion.
//
// Un aviso de la pantalla va **encima** de la lista y no en un `SnackBar`. Un
// `SnackBar` se va solo a los cuatro segundos, y un aviso que dice "estoy usando una
// copia del catalogo del martes" no puede desaparecer solo: es la diferencia entre
// ver la lista de hoy y la de hace una semana.
//
// LA BANDA DE AVISOS NO PUEDE COMERSE LA LISTA. Medido el 4 de octubre de 2026: veinte
// cajas de aviso se comian la pantalla entera y la lista de modulos no se veia. Ver
// `_Avisos`: la banda tiene un tope de altura con scroll propio, el progreso de cada
// modulo es una barra que **reemplaza** a la anterior en vez de acumularse, y solo lo
// que de verdad fallo se pinta como error.
//
// Y VACIO NO ES LO MISMO QUE ERROR. "No hay nada en el catalogo" es un problema del
// servidor. "No hay nada que case con lo que has escrito" es un problema de lo que
// ha escrito la persona, y la solucion es quitar el filtro. Ensenar un error
// vermelho para lo segundo es como se hace que alguien piense que la app se
// ha roto cuando lo unico que ha puesto es una letra de mas.

import 'package:flutter/material.dart';

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/core/idiomas.dart';
import 'package:ab/ui/core/tema.dart';

import '../view_models/aviso.dart';
import '../view_models/biblioteca_view_model.dart';
import '../widgets/fila_modulo.dart';

class BibliotecaView extends StatefulWidget {
  const BibliotecaView({
    super.key,
    required this.viewModel,
    required this.alPulsarLeer,
    required this.alPulsarDescargar,
    required this.alPulsarFicheroLocal,
    required this.alReintentar,
  });

  final BibliotecaViewModel viewModel;

  /// Los tres callbacks llegan de fuera porque **descargar** y **abrir un fichero**
  /// son cosas que hacen varias pantallas y necesitan el motor de obtencion y el
  /// selector de archivos. La vista no los tiene y no los pide.
  final void Function(String id) alPulsarLeer;
  final void Function(String id) alPulsarDescargar;
  final void Function(String id) alPulsarFicheroLocal;
  final VoidCallback alReintentar;

  @override
  State<BibliotecaView> createState() => _BibliotecaViewState();
}

class _BibliotecaViewState extends State<BibliotecaView> {
  /// Bajar el primer texto que se pueda bajar.
  ///
  /// Y POR QUE SE QUITA EL FILTRO AQUI Y NO DENTRO DEL BOTON: `limpiarFiltros` es estado de
  /// la pantalla, y el boton solo sabe que hay que pulsar una vez. Ponerlo en el boton
  /// obligaria a que `_CajaDelMotivo` recibiera el `viewModel`, que es justo lo que esta
  /// Pantalla no tiene: el `viewModel` lo tiene **la** pantalla que la contiene.
  ///
  /// Y ADEMAS SE OLVIDA EL MOTIVO, porque en cuanto hay una descarga en marcha el motivo
  /// "no tienes ningun texto" es a medias, y el aviso de progreso --que esta justo debajo-- ya
  /// esta diciendo lo que esta pasando. Dejar los dos son dos verdades a la vez.
  void _bajarElPrimero() {
    final vm = widget.viewModel;
    vm.limpiarFiltros();
    final id = _primerTextoParaBajar(vm);
    if (id != null) widget.alPulsarDescargar(id);
  }

  late final TextEditingController _controlFiltro = TextEditingController(
    text: widget.viewModel.filtro.texto,
  );

  @override
  void dispose() {
    _controlFiltro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) => Scaffold(
        appBar: _BarraSuperior(vm: vm),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _Avisos(vm: vm, alPulsarBajar: _bajarElPrimero),
              Expanded(
                child: RefreshIndicator(
                  // Tirar para recargar es lo que hace todo el mundo en un movil, y
                  // es el gesto que la gente prueba sin que nadie se lo ensene. Por
                  // eso esta en la pantalla y no solo en un boton.
                  onRefresh: () async => widget.alReintentar(),
                  child: _Cuerpo(vm: vm, controlFiltro: _controlFiltro, acciones: _Acciones(widget)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La barra de arriba: el titulo, alineado con el contenido.
///
/// Y EL TITULO VA DENTRO DE UN `ContenidoCentrado`, Y NO EN EL `title` DEL `AppBar`.
/// Medido el 4 de octubre de 2026 a 1900 px de ancho: el contenido se centraba en una
/// columna de 560 --la lista, los filtros, los avisos-- y el titulo se quedaba clavado
/// en la esquina izquierda, a 1345 pixeles de distancia de lo que titula. Parece una
/// pantalla hecha de dos.
///
/// Y NO SE USA UN `titleSpacing` NI UN `AppBar` con `flexibleSpace`: el `AppBar` alinea
/// su `title` con el `leading` y no con el cuerpo, y no hay forma de que coincidan con
/// el `Center` + `ConstrainedBox` del cuerpo. La unica forma de que las dos cosas esten
/// donde deben es **poner el mismo contenedor en los dos sitios**.
class _BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const _BarraSuperior({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: context.colores.fondo,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
    title: ContenidoCentrado(
      // Y LA COLUMNA SE CENTRA Y EL TEXTO SE PEGA A LA IZQUIERDA DENTRO DE ELLA. Son
      // dos cosas distintas, y por eso el `Align` va **dentro** del `ContenidoCentrado` y
      // no como una opcion suya.
      //
      // La primera version paso `alignment: centerStart` al `ContenidoCentrado`, y con
      // eso el titulo salia a 24 pixeles mientras el contenido salia a 128: el
      // `centerStart` movia la **columna** entera a la izquierda, no el texto dentro de
      // la columna. Medido en la prueba a 768 px.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'Biblioteca',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
    // Y SIN `actions`. Medido el 4 de octubre de 2026: con un boton de recarga al
    // derecha, el boton caia en el borde de la ventana a 1900 px y el titulo en la
    // esquina, con el contenido en medio. Ademas el gesto de tirar para recargar ya
    // esta, y en movil se llega antes asi.
  );
}

/// Los avisos: los del repositorio mas los de la pantalla.
///
/// LO QUE SE CAMBIA Y POR QUE, MEDIDO EL 4 DE OCTUBRE DE 2026. Antes esto era un
/// `Column` de cajas, una por aviso, **encima** de la lista. Con los veinte mensajes
/// que deja descargar dos modulos, las cajas se comian la pantalla entera y la lista de
/// modulos --que es para lo que esta la pantalla-- no se veia. Ademas:
///
///   - Todo salia en **rojo**, porque la lista era de `String` y no sabia que un
///     "Bajando X: 90 por ciento" no es un error.
///   - Los de "Bajando X: N por ciento" se **acumulaban**, uno por cada diez por ciento,
///     y no se quitaban al terminar.
///
/// AHORA SON TRES COSAS DISTINTAS, en una banda que ocupa lo justo:
///
///  1. **Los errores**, arriba, y solo ellos. Con un boton para quitarlos cuando ya no
///     son verdad.
///  2. **Los avisos de informacion**, debajo, sin icono de alarma: "se esta usando
///     una copia del catalogo del martes" no es un fallo y no puede verse como uno.
///  3. **Los progresos de descarga**, que no son avisos sino **barras** en su propia
///     fila. Y como el ViewModel los reemplaza por clave, hay **una** barra por modulo
///     bajandose, no diez lineas.
///
/// Y LA BANDA TIENE UN TOPE DE ALTURA Y SCROLL PROPIO. Eveno que seSolvera la barra
/// crece, no puede comerse la lista: la lista es lo principal y los avisos son
/// contexto. Con veinte avisos se ven los primeros y hay mas, y en una pantalla de
/// 360 px caben cuatro.
class _Avisos extends StatelessWidget {
  const _Avisos({required this.vm, required this.alPulsarBajar});

  final BibliotecaViewModel vm;

  /// Bajar el primer texto que se pueda bajar, que es lo que da sentido al motivo.
  final VoidCallback alPulsarBajar;

  /// Cuanto puede crecer la banda antes de tener scroll propio.
  ///
  /// Un tope pequeno a proposito: si los avisos ocupan media pantalla, el fallo
  /// original vuelve por otra ruta. Y es un tope de **altura**, no de numero de
  /// avisos, porque un aviso de tres lineas y uno de una ocupan distinto.
  static const double _altoMaximo = 168;

  @override
  Widget build(BuildContext context) {
    // Y EL MOTIVO CUENTA COMO CONTENIDO DE LA BANDA, y no es un widget aparte en otro
    // sitio. La banda es la unica parte de la pantalla que **esta pensada** para decir
    // "aqui tienes algo que saber", con su sitio, su scroll y su separacion de la lista.
    // Un `Column` con el motivo por delante de la banda dejaria el texto descolocado del
    // resto, que es justo lo que `AGENTS.md` prohibe con la barra y el cuerpo.
    if (vm.avisos.isEmpty && vm.motivoDeLaVisita == null) {
      return const SizedBox.shrink();
    }

    return ContenidoCentrado(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _altoMaximo),
        child: SingleChildScrollView(
          // Con scroll propio y sin fisica de "nunca", porque tira hacia arriba
          // produce un aviso de rebote en una caja de texto, que en un movil se lee
          // como un fallo.
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Y EL MOTIVO **PRIMERO**, antes de los avisos del repositorio, y en su
              // propia caja y no como un aviso mas. Es lo que ha traido a la persona hasta
              // aqui, y por encima queda lo que le ha pasado al descargar.
              if (vm.motivoDeLaVisita != null)
                _CajaDelMotivo(
                  motivo: vm.motivoDeLaVisita!,
                  // Y EL PRIMERO **QUE SE PUEDA BAJAR**, y no el primero de la lista: con el
                  // filtro "solo lo que tengo" puesto, el primero de la lista es uno que
                  // ya esta aqui y "Bajar el primero" no bajaria nada. Un boton que no hace
                  // nada por el estado de un filtro que no se ve desde el boton es un boton
                  // roto.
                  alPulsarBajar: alPulsarBajar,
                ),
              for (final aviso in vm.avisos)
                if (aviso.esProgreso)
                  _BarraDeProgreso(aviso: aviso)
                else
                  _LineaAviso(aviso: aviso, alQuitar: () => vm.quitarAviso(aviso.texto)),
              if (vm.hayErrores)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: vm.quitarErrores,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Quitar los errores'),
                    style: TextButton.styleFrom(foregroundColor: context.colores.peligro),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un aviso que no es de progreso: una linea de texto con su icono.
///
/// Y UNA CAJA CON BORDE Y FONDO SOLO SI ES UN ERROR. Un aviso de informacion es texto
/// con un icono al lado, sin caja: una caja alrededor de "se esta usando una copia
/// guardada" lo convierte en visualmente en un fallo, que es exactamente el problema
/// que se esta arreglando.
/// El motivo por el que se esta en la biblioteca, y lo que hay que hacer al respecto.
///
/// ============================================================================
/// POR QUE TIENE UN **BOTON** Y NO ES UN AVISO MAS
/// ============================================================================
///
/// Porque un aviso dice lo que ha pasado y un motivo dice **lo que hay que hacer**, y un
/// texto que dice "no tienes ninguna Biblia descargada" sin mas es un callejon sin salida: la
/// biblioteca esta **debajo**, en la misma pantalla, y quien lo lee tiene que bajar hasta
/// ella. Con el boton al lado, lo que se pide es un toque.
///
/// Y EL BOTON DICE "Bajar el primero" Y NO "Instalar", por dos motivos que salen de ahi:
///
///   - **Instalar** es una palabra de tienda, y esto no es una tienda. Lo que hay es un
///     `.amod` en un catalogo que alguien ha publicado.
///   - Y **"el primero"** es concreto: quien no tiene ninguna Biblia no quiere el
///     catalogo entero, quiere la primera. Un boton que lleva ahi --que esta justo debajo
///     y con el filtro puesto-- es un boton que hace el trabajo.
/// Bajar el primer texto que se pueda bajar.
///
/// Y SE QUITA EL FILTRO PRIMERO, y no es cosmetico: con el filtro "solo lo que tengo"
/// puesto, el primer texto de la lista es uno que **ya esta aqui**, y "Bajar el primero"
/// no bajaria nada. Un boton que no hace nada por el estado de un filtro que el boton no
/// ensena es un boton roto.
///
/// Y ENTRE LOS DESCARGABLES, UNA **BIBLIA** SI LA HAY. El motivo de este boton es el de
/// "no tienes ningun texto abierto", y lo que hace falta para poder leer es una Biblia: un
/// comentario sin texto al lado no se puede leer. Si no hay ninguna Biblia en el catalogo --
/// que con este catalogo no pasa, pero el catalogo lo pone otro-- se baja el primero que
/// haya, porque un boton que no hace nada es peor que uno que baja lo que sea.
String? _primerTextoParaBajar(BibliotecaViewModel vm) {
  final descargables = vm.filas.where((FilaDeModulo f) => f.sePuedeDescargar).toList();
  if (descargables.isEmpty) return null;
  return descargables
      .firstWhere(
        (FilaDeModulo f) => f.modulo?.tipo == TipoModulo.biblia,
        orElse: () => descargables.first,
      )
      .id;
}

class _CajaDelMotivo extends StatelessWidget {
  const _CajaDelMotivo({
    required this.motivo,
    required this.alPulsarBajar,
  });

  final String motivo;

  /// Bajar el primer texto que hay, que es lo que vuelve util este motivo.
  ///
  /// Y VIENE DE FUERA, como los otros tres de la pantalla, y por el motivo que ya esta
  /// escrito en el constructor: **descargar** es cosa de quien tiene el motor de obtencion,
  /// y la vista no lo tiene y no lo pide. Ponerlo aqui seria meter la descarga en la vista.
  final VoidCallback alPulsarBajar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(10),
        // Y UNA REGLA A LA IZQUIERDA EN VEZ DE UN `Border.all`, y no un fondo de color. El
        // motivo no es un error: es "aqui tienes algo que saber", y un fondo de aviso en
        // rojo por abrir una aplicacion vacia es gritar donde no pasa nada. La regla dice
        // "esto es para ti" sin gritar.
        border: Border(
          left: BorderSide(color: c.primario, width: 3),
          top: BorderSide(color: c.linea),
          right: BorderSide(color: c.linea),
          bottom: BorderSide(color: c.linea),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            motivo,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: c.texto),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: alPulsarBajar,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Bajar el primero'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaAviso extends StatelessWidget {
  const _LineaAviso({required this.aviso, required this.alQuitar});

  final Aviso aviso;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final color = aviso.esError ? context.colores.peligro : context.colores.textoSuave;

    if (!aviso.esError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, size: 17, color: context.colores.textoSuave),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aviso.texto,
                style: Theme.of(context).textTheme.bodySmall,
                softWrap: true,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: context.colores.peligro.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colores.peligro.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, size: 19, color: context.colores.peligro),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aviso.texto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
                softWrap: true,
              ),
            ),
            // Y EL BOTON DE QUITAR EL ERROR INDIVIDUAL. Un error que ya no es verdad
            // --"no se ha podido abrir" cuando ya se ha abierto-- y que no se puede
            // quitar ensena que hay un problema que no hay.
            IconButton(
              icon: const Icon(Icons.close, size: 17),
              // Sin `tooltip` este boton no tiene nombre, y quien va con lector de
              // pantalla solo oiria "boton".
              tooltip: 'Quitar este aviso',
              onPressed: alQuitar,
              visualDensity: VisualDensity.compact,
              color: context.colores.peligro,
            ),
          ],
        ),
      ),
    );
  }
}

/// El progreso de una descarga: una barra, no una caja de texto.
///
/// Y NO ES UNA CAJA ROJA CON "90 por ciento". Un progreso no es un aviso: no hay nada
/// que este mal, y una barra lo dice de un vistazo y sin ocupar cinco lineas.
///
/// Y LA BARRA TIENE ETIQUETA CON EL PORCENTAJE Y NO SOLO COLOR, por la misma razon que
/// los estados de la fila: quien tiene baja vision, o el movil en escala de grises, o
/// simplemente no distingue el color, tiene que poder saber cuanto lleva.
class _BarraDeProgreso extends StatelessWidget {
  const _BarraDeProgreso({required this.aviso});

  final Aviso aviso;

  @override
  Widget build(BuildContext context) {
    final pct = (aviso.porcentaje ?? 0).clamp(0, 100) / 100;
    final nombre = aviso.id ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        label: 'Descargando $nombre, $aviso.porcentaje por ciento',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.downloading_outlined, size: 17, color: context.colores.acento),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Descargando $nombre',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${aviso.porcentaje ?? 0} %',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colores.texto,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: context.colores.linea,
                valueColor: AlwaysStoppedAnimation<Color>(context.colores.acento),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El cuerpo: filtro y lista, o el vacio con su explicacion.
class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.vm,
    required this.controlFiltro,
    required this.acciones,
  });

  final BibliotecaViewModel vm;
  final TextEditingController controlFiltro;
  final _Acciones acciones;

  @override
  Widget build(BuildContext context) {
    // El filtro va **siempre**, incluso con la lista vacia. Es como se quita un
    // filtro que ha dejado la lista vacia, y si desaparece con ella no hay forma
    // de quitarlo: habria que recargar la pagina.
    return ListView(
      // `AlwaysScrollableScrollPhysics` para que el `RefreshIndicator` funcione
      // tambien con la lista vacia. Sin esto, tirar para recargar en una lista
      // vacia no hace nada y parece que la app esta colgada.
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        _Filtros(vm: vm, control: controlFiltro),
        ..._listaOCuerpoVacio(context),
        const SizedBox(height: 28),
      ],
    );
  }

  List<Widget> _listaOCuerpoVacio(BuildContext context) {
    if (vm.filasFiltradas.isEmpty) return <Widget>[_Vacio(vm: vm)];

    return <Widget>[
      for (final fila in vm.filasFiltradas)
        _Fila(fila: fila, vm: vm, acciones: acciones),
    ];
  }
}

/// Los filtros: texto, idioma y "solo lo que tengo".
class _Filtros extends StatelessWidget {
  const _Filtros({required this.vm, required this.control});

  final BibliotecaViewModel vm;
  final TextEditingController control;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final texto = _CampoTexto(vm: vm, control: control);
    final selectores = _Selectores(vm: vm);

    return ContenidoCentrado(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        // En ancho hay sitio de sobra para el campo y los selectores en la misma
        // linea. En estrecho, uno debajo de otro. **Empieza por el caso estrecho**:
        // al reves, el movil se queda con un `if` de mas en cada fila, y por ahi es
        // por donde las pantallas responsive se rompen.
        //
        // Y `texto` y `selectores` se usan en **una sola rama** cada uno. La primera
        // version de este bloque tenia el campo como primer hijo del `Column` sin
        // condicion, y ademas lo ponia en el `else`: en un movil se veian **dos**
        // campos de busqueda, y `enterText` fallaba porque no sabia cual pulsar. Lo
        // se vio al escribir la prueba, no al mirar la pantalla.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (ancho >= Medidas.anchoParaDosColumnas)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: texto),
                  const SizedBox(width: 12),
                  // `Flexible`, y no el `Wrap` suelto. Un `Wrap` dentro de una `Row`
                  // toma su **ancho intrinseco**, que es la suma de sus hijos en una
                  // sola linea, y esa suma no depende del ancho de la pantalla: en un
                  // portatil de 1440 px se salia por la derecha 176 pixeles. Con
                  // `Flexible` el `Wrap` recibe un ancho acotado y baja los selectores
                  // de linea, que es justo lo que sabe hacer.
                  Flexible(flex: 2, child: selectores),
                ],
              )
            else ...<Widget>[
              texto,
              const SizedBox(height: 10),
              selectores,
            ],
          ],
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({required this.vm, required this.control});

  final BibliotecaViewModel vm;
  final TextEditingController control;

  @override
  Widget build(BuildContext context) => TextField(
    controller: control,
    onChanged: vm.filtrarPorTexto,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Buscar por nombre, idioma o licencia',
      prefixIcon: const Icon(Icons.search, size: 21),
      suffixIcon: vm.filtro.texto.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close, size: 19),
              // Sin `tooltip` no hay nombre accesible, y el boton solo tiene un
              // icono: quien va con lector de pantalla oiria "boton".
              tooltip: 'Quitar la busqueda',
              onPressed: () {
                control.clear();
                vm.filtrarPorTexto('');
              },
            ),
    ),
  );
}

class _Selectores extends StatelessWidget {
  const _Selectores({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idiomas = vm.idiomas;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        // El desplegable de idiomas solo aparece si hay alguno. Con el catalogo
        // vacio, un desplegable con "Todos" es un control que no hace nada.
        if (idiomas.isNotEmpty)
          _Desplegable(
            valor: vm.filtro.idioma,
            etiqueta: vm.filtro.idioma == null
                ? 'Todos los idiomas'
                : textoDeIdioma(vm.filtro.idioma!),
            opciones: <String?>[null, ...idiomas],
            textoDe: (v) => v == null ? 'Todos los idiomas' : textoDeIdioma(v),
            alCambiar: vm.filtrarPorIdioma,
            etiquetaAccesible: 'Filtrar por idioma',
          ),
        _BotonSoloDescargados(vm: vm),
      ],
    );
  }
}

/// El boton de "solo lo que tengo".
///
/// Un `FilterChip` y no un `Switch`: un interruptor ocupa sitio y no dice de que
/// filtra. Un chip con su texto encendido dice "solo lo que tengo" y se apaga solo.
class _BotonSoloDescargados extends StatelessWidget {
  const _BotonSoloDescargados({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) => FilterChip(
    selected: vm.filtro.soloDescargados,
    onSelected: (_) => vm.alternarSoloDescargados(),
    label: const Text('Solo lo que tengo'),
    showCheckmark: true,
  );
}

/// El desplegable, a mano.
///
/// Un `DropdownButton` de Material sale con una flecha y un `padding` que a 360 px
/// empuja el texto a la segunda linea, y el `menuMaxHeight` por defecto en un
/// `PopupMenuButton` corta la lista de idiomas sin avisar. Este es un `PopupMenu`
/// con las dos cosas puestas, y son cuatro lineas.
class _Desplegable extends StatelessWidget {
  const _Desplegable({
    required this.valor,
    required this.etiqueta,
    required this.opciones,
    required this.textoDe,
    required this.alCambiar,
    required this.etiquetaAccesible,
  });

  final String? valor;
  final String etiqueta;
  final List<String?> opciones;
  final String Function(String?) textoDe;
  final void Function(String?) alCambiar;
  final String etiquetaAccesible;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String?>(
    onSelected: alCambiar,
    // Sin esto, en un movil con muchos idiomas la lista se sale por arriba de la
    // pantalla y el primero no se ve.
    constraints: const BoxConstraints(maxHeight: 320),
    tooltip: etiquetaAccesible,
    itemBuilder: (context) => <PopupMenuEntry<String?>>[
      for (final o in opciones)
        PopupMenuItem<String?>(
          value: o,
          height: 48,
          child: Row(
            children: <Widget>[
              if (o == valor) const Icon(Icons.check, size: 19) else const SizedBox(width: 19),
              const SizedBox(width: 8),
              Flexible(child: Text(textoDe(o), softWrap: false, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
    ],
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colores.linea),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.translate, size: 19, color: context.colores.textoSuave),
          const SizedBox(width: 8),
          // Sin `Flexible` esto revienta a 360 px con un idioma de nombre largo.
          Flexible(
            child: Text(
              etiqueta,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 22, color: context.colores.textoSuave),
        ],
      ),
    ),
  );
}

/// Una fila, con su separador.
class _Fila extends StatelessWidget {
  const _Fila({required this.fila, required this.vm, required this.acciones});

  final FilaDeModulo fila;
  final BibliotecaViewModel vm;
  final _Acciones acciones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FilaModulo(
          // La clave es el id **con** el estado. Sin el estado en la clave, dos
          // filas con el mismo id en la misma lista --una descargada y otra
          // desactualizada, que puede pasar si el manifiesto cambia mientras se
          // mira-- se reciclan una a otra y Flutter avisa de indices duplicados.
          key: ValueKey<String>('${fila.id}/${fila.estado.name}'),
          fila: fila,
          porQue: _porQueNoSePuede(fila, vm),
          alPulsarDescargar: () => acciones.descargar(fila.id),
          alPulsarLeer: () => acciones.leer(fila.id),
          alPulsarFicheroLocal: () => acciones.ficheroLocal(fila.id),
        ),
        const Divider(height: 1),
      ],
    );
  }

  /// Cuando no se puede descargar, por que. Y hay **tres** motivos distintos.
  ///
  /// El orden importa: se mira primero si el navegador deja leerlo, porque es el
  /// unico caso en el que reintentar no sirve y la unica salida es el fichero local.
  /// Si se mirara el ultimo, un modulo con el origen bloqueado y sin red sale como
  /// "reintentar" y la persona reintenta para siempre.
  static PorQueNoSePuedeDescargar? _porQueNoSePuede(FilaDeModulo f, BibliotecaViewModel vm) {
    // Si ya esta en el dispositivo, no hay nada que impedir: se lee.
    if (f.sePuedeLeer) return null;

    // El navegador no lo deja leer. Un reintento no lo arregla.
    if (vm.origenNoLegible(f.id)) return PorQueNoSePuedeDescargar.origenNoLegible;

    if (f.sePuedeDescargar) return null;

    // No se puede ni descargar ni leer. Se mira por que se fallo la lectura del
    // catalogo, porque de eso depende si reintentar sirve.
    return switch (vm.estadoLectura) {
      // El catalogo no se pudo leer: reintentar **si** puede servir, y es lo unico
      // que se puede hacer.
      EstadoLectura.sinConexion => PorQueNoSePuedeDescargar.sinConexion,
      EstadoLectura.hashIncorrecto => PorQueNoSePuedeDescargar.sinConexion,
      EstadoLectura.ilegible => PorQueNoSePuedeDescargar.sinConexion,
      // El catalogo si se leyo. Entonces no se puede descargar por una razon que
      // no se sabe todavia, y se ofrece la accion normal.
      EstadoLectura.delServidor => PorQueNoSePuedeDescargar.todaviaNo,
      EstadoLectura.deCopiaGuardada => PorQueNoSePuedeDescargar.todaviaNo,
    };
  }
}

/// El cuerpo vacio. Y hay tres, no uno.
class _Vacio extends StatelessWidget {
  const _Vacio({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.filtroSinResultados) return _VacioConFiltro(vm: vm);
    if (vm.catalogoVacio) return _VacioSinCatalogo(vm: vm);
    // Con filas pero ninguna filtrada no puede pasar: `filasFiltradas` es o la
    // lista entera o una sublista. Aun asi se ensenar algo en vez de una pantalla en
    // blanco, porque una pantalla en blanco no dice nada de por que esta ahi.
    return _VacioSinCatalogo(vm: vm);
  }
}

/// "No hay nada que case con tu filtro", con el boton para quitarlo.
class _VacioConFiltro extends StatelessWidget {
  const _VacioConFiltro({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) => _CajaVacio(
    icono: Icons.search_off,
    titulo: 'Nada coincide con la busqueda',
    texto: 'Prueba con menos palabras, o quita el filtro de idioma.',
    accion: TextButton.icon(
      onPressed: vm.limpiarFiltros,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 19),
      label: const Text('Quitar los filtros'),
    ),
  );
}

/// "No hay nada en el catalogo", con el boton de reintentar.
class _VacioSinCatalogo extends StatelessWidget {
  const _VacioSinCatalogo({required this.vm});

  /// Null cuando no se sabe por que esta vacio.
  final BibliotecaViewModel? vm;

  @override
  Widget build(BuildContext context) {
    final hayAvisos = vm?.avisos.isNotEmpty ?? false;
    return _CajaVacio(
      icono: Icons.menu_book_outlined,
      titulo: 'No hay ningun modulo',
      texto: hayAvisos
          ? 'No se ha podido leer el catalogo. Se explica arriba.'
          : 'El catalogo no declara ningun modulo todavia. Puede que no haya '
              'salido ninguna version todavia.',
    );
  }
}

class _CajaVacio extends StatelessWidget {
  const _CajaVacio({required this.icono, required this.titulo, required this.texto, this.accion});

  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenEstrecho, vertical: 42),
    child: Column(
      children: <Widget>[
        Icon(icono, size: 44, color: context.colores.textoSuave),
        const SizedBox(height: 14),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        if (accion != null) ...<Widget>[const SizedBox(height: 12), accion!],
      ],
    ),
  );
}

/// Los tres acciones de una fila, agrupadas.
///
/// Van juntas en una clase y no sueltas por la pantalla porque atraviesan tres
/// niveles --la pantalla, el cuerpo, la fila-- y en tres `Widget` sueltos se acaba
/// forgetting uno y dejando un boton que no hace nada. Que es exactamente lo que
/// paso la primera vez.
///
/// Y son `void Function(String id)`: la fila sabe **que** modulo, y no **como** se
/// descarga. Descargar necesita el motor de obtencion, que vive en el
/// composition root; la vista no lo tiene y no lo pide.
class _Acciones {
  const _Acciones(this._vista);

  final BibliotecaView _vista;

  /// Leer un texto, y **olvidar el motivo** de por que se estaba en la biblioteca.
  ///
  /// Y AQUI, Y NO EN EL ENRUTADOR, porque el motivo es estado de **esta** pantalla: el
  /// enrutador no sabe que hay un motivo quesdividir. Y se olvida aqui porque en cuanto hay
  /// un texto abierto, decir "no tienes ninguna Biblia" es **falso**, y un texto en pantalla
  /// que no se corresponde con lo que se ve es la peor forma de avisar.
  void leer(String id) {
    _vista.viewModel.olvidarElMotivo();
    _vista.alPulsarLeer(id);
  }
  void descargar(String id) => _vista.alPulsarDescargar(id);
  void ficheroLocal(String id) => _vista.alPulsarFicheroLocal(id);
}
