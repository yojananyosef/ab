// La hoja de formato: donde se tocan los ajustes de lectura.
//
// ============================================================================
// POR QUE ESTA HOJA Y NO UN MENU LATERAL
// ============================================================================
//
// En Logos, la fila de menu del panel tiene `Inicio`, `Busqueda`, `Notas`, **`Formato`**,
// `Vista`, `Herramientas`, `Compartir`. Y en este proyecto `Formato` **no se puso** cuando se
// copio la distribucion, por una razon que esta escrita en el spec: un elemento de barra que
// no lleva a ninguna parte es ruido con apariencia de producto.
//
// Y aqui ya hay algo detras. Asi que esta hoja es lo que hace que `Formato` sea honesto, y no
// una etiqueta: si se anade el boton, tiene que abrir esto.
//
// Y ES UNA **HOJA**, Y NO UN MENU, y en pantalla estrecha no cabe otra cosa. El menu lateral
// tiene que ir pegado al borde y a 320 px se come la columna entera. Y la hoja se puede
// cerrar con el dedo por debajo, que es lo que se hace en un movil.
//
// ============================================================================
// Y EL ORDEN DE DENTRO NO ES EL QUE SE PONE, ES EL QUE SE USA
// ============================================================================
//
// Tamano de letra, alto de linea, espaciado --los tres que se tocan deslizando-- y despues un
// separador y lo que se elige tocando: el fondo, la atenuacion, la linea enfocada, y al
// final el boton de devolverlo todo a los recomendados.
//
// El separador no es decoracion: dice que lo de arriba se ajusta en caliente mientras se lee
// y lo de abajo son decisiones que se notan de golpe.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/core/tema.dart';

/// Abre la hoja de formato.
///
/// Y DEVUELVE UN `FUTURE` QUE NO HAY QUE ESPERAR, y no devuelve la preferencia: quien la
/// cambia es el view model, y el view model guarda. Una hoja que devuelve un valor y quien
/// llama lo guarda tiene **dos** caminos para guardar, que es el mismo problema que la
/// preferencia se creo para evitar.
Future<void> abrirHojaDeFormato(
  BuildContext contexto, {
  required PreferenciaDeLectura preferencia,
  required void Function(PreferenciaDeLectura nueva) alCambiar,
  required VoidCallback alRestaurar,
}) {
  return showModalBottomSheet<void>(
    context: contexto,
    isScrollControlled: true,
    // Y `showDragHandle`, que es la barra de arriba de la hoja. Sin ella hay que adivinar que
    // la hoja se cierra tirando de ella.
    showDragHandle: true,
    builder: (BuildContext contexto) => _HojaDeFormato(
      preferencia: preferencia,
      alCambiar: alCambiar,
      alRestaurar: alRestaurar,
    ),
  );
}

class _HojaDeFormato extends StatefulWidget {
  const _HojaDeFormato({
    required this.preferencia,
    required this.alCambiar,
    required this.alRestaurar,
  });

  final PreferenciaDeLectura preferencia;
  final void Function(PreferenciaDeLectura nueva) alCambiar;
  final VoidCallback alRestaurar;

  @override
  State<_HojaDeFormato> createState() => _HojaDeFormatoState();
}

class _HojaDeFormatoState extends State<_HojaDeFormato> {
  // Y SE COPIA LA PREFERENCIA AL ABRIR, y no se lee del view model en cada `build`.
  //
  // Y EL MOTIVO NO ES "copiar para no tocar el view model", que es lo que parece: es que el
  // view model **notifica**, y un deslizador notifica en cada pixel. Si la hoja se rebuceara
  // con la notificacion, se cerraria o saltaria mientras se arrastra, porque la hoja la
  // reconstruye el `showModalBottomSheet`.
  //
  // Con la copia, cada movimiento del deslizador pinta la hoja y **la preferencia se guarda
  // al soltar**, no en cada pixel: escribir en un `localStorage` por pixel de arrastre es
  // escribir el almacenamiento cientos de veces en un segundo.
  late PreferenciaDeLectura _borrador = widget.preferencia;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;

    return SafeArea(
      // Y EL TECLADO, Y UN `MAX HEIGHT`. Con el teclado abierto en un movil de 640 px quedan
      // unos 360, y la hoja con tres deslizadores mas el fondo mas el boton necesita mas de
      // 600. Sin tope, el boton de "restaurar" queda **debajo del teclado** y no se ve, que
      // es la forma de tener un boton que no se puede pulsar.
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            Medidas.margenAncho,
            0,
            Medidas.margenAncho,
            Medidas.margenAncho,
          ),
          children: <Widget>[
            Text('Formato de lectura',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Lo que se toca deslizando se ve al instante. Lo que eliges tocando, en el '
              'fondo y en la luz, se nota de golpe.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.textoSuave),
            ),
            const SizedBox(height: 16),

            // ==========================================================================
            // Y UNA **VISTA PREVIA** ARRIBA, Y NO UNA MUESTRA POR CADA DESLIZADOR
            // ==========================================================================
            //
            // La primera version tenia un texto de ejemplo junto a cada deslizador, y eran
            // **tres textos iguales** en la misma pantalla. Que ademas rompia las pruebas, que
            // con `find.text(muestra)`ytu 발견aban tres widgets y el `.single` reventaba --
            // pero lo que importa es que tres textos iguales no IDEOGRAPHIZAN nada: hay que
            // mirar tres veces el mismo sitio para ver un cambio.
            //
            // Con **una** vista previa arriba, los tres deslizadores de abajo mueven **la
            // misma**, y se ve de un vistazo: subes el tamano y ves que pasa en las tres cosas
            // a la vez.
            _VistaPrevia(preferencia: _borrador),
            const SizedBox(height: 12),

            _Deslizador(
              etiqueta: 'Tamano de letra',
              valor: _borrador.tamanoDeLetra,
              minimo: PreferenciaDeLectura.tamanoMinimo,
              maximo: PreferenciaDeLectura.tamanoMaximo,
              pasos: (PreferenciaDeLectura.tamanoMaximo -
                      PreferenciaDeLectura.tamanoMinimo)
                      .round() -
                  1,
              seEscribe: (v) => '${v.round()} px',
              // Y LA MUESTRA, que es la parte que hace util el deslizador: sin ver el texto
              // con el tamano nuevo, hay que imaginarselo, y el ajuste se hace a ojo con el
              // numero y no con lo que se lee.
              alCambiar: (double v) => setState(
                () => _borrador = _borrador.cambiarTamano(v),
              ),
              alSoltar: (double v) => widget.alCambiar(_borrador.cambiarTamano(v)),
            ),

            _Deslizador(
              etiqueta: 'Alto de linea',
              valor: _borrador.altoDeLinea,
              minimo: PreferenciaDeLectura.altoDeLineaMinimo,
              maximo: PreferenciaDeLectura.altoDeLineaMaximo,
              pasos: 13,
              seEscribe: (v) => v.toStringAsFixed(1),
              alCambiar: (double v) => setState(
                () => _borrador = _borrador.cambiarAltoDeLinea(v),
              ),
              alSoltar: (double v) => widget.alCambiar(_borrador.cambiarAltoDeLinea(v)),
            ),

            _Deslizador(
              etiqueta: 'Espaciado entre letras',
              valor: _borrador.espaciado,
              minimo: PreferenciaDeLectura.espaciadoMinimo,
              maximo: PreferenciaDeLectura.espaciadoMaximo,
              // Y CON 50 PASOS Y NO CON DECIMALES. Un `Slider` no lleva decimales, y con
              // `divisions: 10` el espaciado solo podria ser 0, 0,01, 0,02... que es un rango
              // de cinco pasos utiles para un ajuste que va de 0 a 0,1. Con 50 hay medio paso
              // de centesima, que es lo que se nota.
              pasos: 50,
              seEscribe: (v) => '${v.toStringAsFixed(2)} em',
              alCambiar: (double v) => setState(
                () => _borrador = _borrador.cambiarEspaciado(v),
              ),
              alSoltar: (double v) => widget.alCambiar(_borrador.cambiarEspaciado(v)),
            ),

            const _Separador(),

            Text('Fondo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _Fundos(
              elegido: _borrador.tema,
              alElegir: (TemaDeLectura t) {
                setState(() => _borrador = _borrador.cambiarTema(t));
                widget.alCambiar(_borrador);
              },
            ),

            const SizedBox(height: 20),
            _Deslizador(
              etiqueta: 'Atenuar la luz',
              valor: _borrador.atenuacion,
              minimo: PreferenciaDeLectura.atenuacionMinima,
              maximo: 1,
              pasos: 12,
              seEscribe: (v) => v >= 0.99 ? 'sin atenuar' : '${(v * 100).round()} %',
              // Y LA AYUDA DE POR QUE ESTO EXISTE, en una linea. Sin ella parece un filtro
              // de foto, y no se sabe que es para la noche.
              ayuda: 'Un velo sobre la pantalla. Util de noche, y no baja el brillo del '
                  'panel, que es lo que hace parpadear algunos.',
              alCambiar: (double v) => setState(
                () => _borrador = _borrador.cambiarAtenuacion(v),
              ),
              alSoltar: (double v) => widget.alCambiar(_borrador.cambiarAtenuacion(v)),
            ),

            const SizedBox(height: 8),
            _LineaEnfocada(
              elegido: _borrador.lineaEnfocada,
              alElegir: (int l) {
                setState(() => _borrador = _borrador.cambiarLineaEnfocada(l));
                widget.alCambiar(_borrador);
              },
            ),

            const _Separador(),

            OutlinedButton.icon(
              onPressed: () {
                setState(() => _borrador = PreferenciaDeLectura.porDefecto);
                widget.alRestaurar();
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restaurar valores'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Un deslizador con su etiqueta, su numero y su ayuda.
class _Deslizador extends StatelessWidget {
  const _Deslizador({
    required this.etiqueta,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.pasos,
    required this.seEscribe,
    required this.alCambiar,
    required this.alSoltar,
    this.ayuda,
  });

  final String etiqueta;
  final double valor;
  final double minimo;
  final double maximo;
  final int pasos;
  final String Function(double) seEscribe;
  final ValueChanged<double> alCambiar;
  final ValueChanged<double> alSoltar;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(etiqueta)),
            Text(
              seEscribe(valor),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.acento),
            ),
          ],
        ),
        Slider(
          value: valor.clamp(minimo, maximo),
          min: minimo,
          max: maximo,
          divisions: pasos,
          label: seEscribe(valor),
          onChanged: alCambiar,
          onChangeEnd: alSoltar,
        ),
        if (ayuda != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ayuda!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.textoSuave),
            ),
          ),
      ],
    );
  }
}

/// El texto de ejemplo, con los tres ajustes puestos.
///
/// Y ES UN **JUZO REAL** del capitulo, y no "Lorem ipsum" ni "Texto de ejemplo". Con "Texto de
/// ejemplo" el tamano no se puede juzgar: son dos palabras cortas y no se ve ni donde se
/// cortan las lineas ni si las letras se pegan. Con un versiculo de verdad se ve.
///
/// Y LLEVA LOS TRES AJUSTES A LA VEZ, porque se cambian a la vez.
class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.preferencia});

  final PreferenciaDeLectura preferencia;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colores.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'En el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios.',
          style: estiloDeLectura(Theme.of(context).textTheme, preferencia),
        ),
      ),
    );
  }
}

/// Los tres fondos, como se eligen tocando.
class _Fundos extends StatelessWidget {
  const _Fundos({required this.elegido, required this.alElegir});

  final TemaDeLectura elegido;
  final ValueChanged<TemaDeLectura> alElegir;

  static const Map<TemaDeLectura, String> _rotulos = <TemaDeLectura, String>{
    TemaDeLectura.claro: 'Claro',
    TemaDeLectura.sepia: 'Sepia',
    TemaDeLectura.oscuro: 'Oscuro',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final t in TemaDeLectura.values)
          // Y LA MUESTRA DEL FONDO **ES** SU FONDO, no una captura suya ni un icono. Con el
          // fondo puesto en la tarjeta, el que se elige es el que se ve, y no hay que
          // acordarse de como se llamaba.
          InkWell(
            onTap: () => alElegir(t),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 96,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colores.de(t).fondo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: t == elegido
                      ? context.colores.primario
                      : context.colores.linea,
                  width: t == elegido ? 2 : 1,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colores.de(t).texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _rotulos[t]!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colores.de(t).textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// La linea enfocada: apagada, o de 1, 3 o 5 lineas.
class _LineaEnfocada extends StatelessWidget {
  const _LineaEnfocada({required this.elegido, required this.alElegir});

  final int elegido;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Linea enfocada', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Una apertura sobre la linea que se esta leyendo. Apagada por defecto.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.colores.textoSuave),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final n in PreferenciaDeLectura.lineasEnfocadas)
              ChoiceChip(
                label: Text(n == 0 ? 'Apagada' : '$n lineas'),
                selected: n == elegido,
                onSelected: (_) => alElegir(n),
              ),
          ],
        ),
      ],
    );
  }
}

/// El separador que dice "lo de aqui arriba se desliza, lo de abajo se elige".
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Divider(color: context.colores.linea),
      );
}