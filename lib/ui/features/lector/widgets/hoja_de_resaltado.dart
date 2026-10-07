// Marcar un versiculo: la hoja de estilos y el fondo en el texto.
//
// ============================================================================
// POR QUE UN **NUMERO** Y UNA **FRASE CORTA**, Y NO UN MENU
// ============================================================================
//
// Es el **primer** nivel de los tres de interaccion con el texto que el documento de
// investigacion atribuye a Accordance, y el primero es el que tiene que funcionar solo: un
// toque da la eleccion. Los otros dos --selector de herramienta y busqueda en toda la
// biblioteca-- son opcionales y este change no los toca.
//
// Y LA FRASE CORTA ES DE CINCO ESTILOS, PORQUE SON CINCO. Con veinte estilos habria que
// buscar; con cinco, se tocan. Y son los de los cuadernos de subrayar, que es donde se ha
// criado la costumbre.
//
// ============================================================================
// Y SOLO EL NUMERO DEL VERSICULO ES PULSABLE, Y ESO ES LO IMPORTANTE
// ============================================================================
//
// El **texto** no se puede tocar para marcar, y no por comodidad: se toca para **seleccionar y
// copiar**, que es lo que hace todo el mundo con un texto. Un toque en el texto que no
// selecciona es un fallo de escritura, y quien esta leyendo tiene que poder seleccionar
// "For God so loved the world" para llevarselo.
//
// Y ASI EL NUMERO, que ahi no hay nada que hacer con el dedo. Es la misma logica que el numero
// de versiculo en columna: un numero es un sitio, y un sitio es un destino.
//
// ============================================================================
// Y UN SOLO TOQUE Y YA ESTA PUESTO
// ============================================================================
//
// Tocar el numero abre la hoja; tocar un estilo **marca y cierra**. Un boton mas de "Marcar" en
// la hoja seria un paso que no hace falta: elegir el estilo **es** elegir marcar. Marcar es una
// accion de un paso, y por eso la hoja se cierra al elegir.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/resaltado.dart';
import 'package:ab/ui/core/tema.dart';

/// Lo que se elige en la hoja de estilos.
///
/// Y SON **TRES COSAS** Y NO UNA, y no por gusto: elegir un estilo, quitarlo y cerrar sin
/// hacer nada son tres salidas, y con un `EstiloDeResaltado?` las dos ultimas son **el mismo
/// `null`**.
///
/// Y ESO ES UN BUG, NO UNA SIMPLIFICACION. Con un `null` no se puede distinguir "he cerrado sin
/// querer" de "he pulsado quitar", y quien cierra la hoja sin querer **se quita el resaltado
/// que tenia**. Que es el peor fallo posible de esta pantalla: un toque de mas te borra el
/// trabajo, y ni te entera.
class EleccionDeResaltado {
  const EleccionDeResaltado.quitar() : estilo = null, quita = true;

  const EleccionDeResaltado.este(this.estilo) : quita = false;

  /// El estilo elegido, o null si se ha pedido quitar.
  final EstiloDeResaltado? estilo;

  /// Si se ha pedido quitar el resaltado.
  final bool quita;
}

/// Abre la hoja de estilos para marcar un versiculo.
///
/// Y DEVUELVE **NULL** SI SE HA CERRADO SIN ELEGIR NADA, que es distinto de haber pedido
/// quitar. Ver [EleccionDeResaltado].
///
/// Y NO SE ESCRIBE EN EL ALMACENAMIENTO AQUI, y es lo que hace que la hoja se pueda probar
/// entera sin un almacen: quien llama es el que marca.
Future<EleccionDeResaltado?> elegirEstilo(
  BuildContext contexto, {
  required List<EstiloDeResaltado> estilos,
  required String? estiloActual,
  bool hayResaltado = false,
}) {
  return showModalBottomSheet<EleccionDeResaltado>(
    context: contexto,
    showDragHandle: true,
    // ========================================================================
    // Y `isScrollControlled`, QUE ES LO QUE HACE QUE LA HOJA **CREZCA**
    // ========================================================================
    //
    // MEDIDO EL 6 DE OCTUBRE DE 2026, con la hoja ya dentro de un `SingleChildScrollView`:
    //
    //     ventana de  900 px   la hoja mide   145 px
    //     ventana de 1200 px   la hoja mide   145 px
    //
    // Los **mismos 145 px** en las dos. Y con `isScrollControlled: false` --lo de por
    // defecto-- el alto maximo de la hoja es una fraccion de la pantalla, pero aqui el
    // contenido es un `SingleChildScrollView`, que **no pide** su alto natural: lo pide
    // infinito y se conforma con lo que le den. Con lo que le dan son 145 px, y el titulo
    // mas el subtitulo se llenan y **los cinco estilos quedan debajo del pliegue**.
    //
    // O sea: el `SingleChildScrollView` arreglo el `RenderFlex overflowed by 216 pixels` y
    // **tapo** el sintoma, pero dejo la hoja inservible: los estilos no se ven y con el dedo
    // no se llega. Es el fallo de tapar una excepcion sin mirar lo que hay debajo, que ya
    // esta escrito en `AGENTS.md`.
    //
    // Con `isScrollControlled: true` la hoja pide su alto natural, y el `maxHeight` del
    // `ConstrainedBox` de abajo es lo que la impide comerse la pantalla entera en una ventana
    // baja: cinco estilos mas el boton de quitar son unos 380 px, que en 640 px de alto no
    // caben y en 1200 si.
    isScrollControlled: true,
    builder: (BuildContext contexto) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(contexto).height * 0.8,
        ),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenAncho,
          0,
          Medidas.margenAncho,
          Medidas.margenAncho,
        ),
        // ========================================================================
        // Y SE DESPLAZA, PORQUE A 360 x 640 NO CABE. MEDIDO
        // ========================================================================
        //
        // Con cinco estilos salen cinco filas de 52 px mas el titulo, el subtitulo y el boton
        // de quitar: unos 340 px. En una ventana de 640 px de alto, la hoja tiene 288 px, y se
        // desbordan **216**:
        //
        //     A RenderFlex overflowed by 216 pixels on the bottom.
        //
        // Y NO ES SOLO UN CASO DE PRUEBA: 640 px de alto es lo que queda con el teclado
        // abierto, en vertical en un telefono pequeno, y en horizontal en cualquiera. Y un
        // `RenderFlex` desbordado en produccion **solo** sale el cartel deamarillo y negro:
        // los estilos que no caben no se ven y no hay forma de llegar a ellos.
        //
        // Y UN `SingleChildScrollView` Y NO UN `Expanded` CON ALTURA FIJA, porque la hoja
        // tiene que ser **alta** cuando puede y **desplazable** cuando no, no siempre
        // desplazable: una hoja que sale con el alto minimo y un hueco de 300 px debajo es
        // una hoja que parece un error.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            Text('Marcar este versiculo',
                style: Theme.of(contexto).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              hayResaltado
                  ? 'Ya esta marcado. Elige otro estilo para cambiarlo.'
                  : 'Elige un estilo. El nombre lo puedes cambiar luego.',
              style: Theme.of(contexto)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: contexto.colores.textoSuave),
            ),
            const SizedBox(height: 16),
            for (final e in estilos)
              _FilaDeEstilo(
                estilo: e,
                elegido: e.id == estiloActual,
                alPulsar: () =>
                    Navigator.of(contexto).pop(EleccionDeResaltado.este(e)),
              ),
            const SizedBox(height: 8),
            if (hayResaltado)
              // Y "QUITAR" SOLO CUANDO LO HAY, y no siempre. Un "Quitar" en un versiculo que no
              // esta marcado es un boton que no hace nada, y en la pantalla de leer Juan 3
              // eso es un boton de mas en la parte de arriba.
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(contexto).pop(const EleccionDeResaltado.quitar()),
                icon: const Icon(Icons.format_color_reset),
                label: const Text('Quitar el resaltado'),
              ),
            ],
          ),
        ),
        ),
      ),
    ),
  );
}

/// Una fila: el color, el nombre, y como queda.
class _FilaDeEstilo extends StatelessWidget {
  const _FilaDeEstilo({
    required this.estilo,
    required this.elegido,
    required this.alPulsar,
  });

  final EstiloDeResaltado estilo;
  final bool elegido;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: elegido ? c.primario : c.linea,
              width: elegido ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              // Y LA MUESTRA DEL ESTILO, con **el color y la intensidad** de verdad, y no solo
              // el color: dos personas pueden usar el mismo color con distinta intensidad y son
              // estilos distintos. Y el borde sale cuando la forma lo pide, que es lo que
              // distingue "fondo y contorno" de "solo fondo".
              _MuestraDelEstilo(estilo: estilo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(estilo.nombre,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              Text(
                estilo.forma.rotulo,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textoSuave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Como se ve un estilo: el fondo, el contorno y las iniciales de las letras.
///
/// Y LAS TRES COSAS A LA VEZ, porque son las tres que distinguen un estilo de otro y verlas
/// separadas obliga a recordarlas.
class _MuestraDelEstilo extends StatelessWidget {
  const _MuestraDelEstilo({required this.estilo});

  final EstiloDeResaltado estilo;

  @override
  Widget build(BuildContext context) {
    final c = estilo.color;
    final fondo = Color.fromARGB(
      estilo.forma == FormaDelResaltado.contorno ? 0 : 255,
      (c.r * 255).round(),
      (c.g * 255).round(),
      (c.b * 255).round(),
    );

    return Container(
      width: 56,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Color.fromARGB(
            estilo.forma == FormaDelResaltado.fondo ? 0 : 255,
            (c.r * 255).round(),
            (c.g * 255).round(),
            (c.b * 255).round(),
          ),
          width: estilo.forma == FormaDelResaltado.fondo ? 0 : 2,
        ),
      ),
      child: Text(
        'Aa',
        style: TextStyle(
          fontSize: 15,
          // Y EL TEXTO DE LA MUESTRA ES EL **COLOR DE TEXTO** Y NO UNO CUALQUIERA, porque
          // si no, un resaltado de un color claro lleva encima un texto oscuro que no es el
          // de la pagina y se ve que es de otro sitio.
          color: context.colores.texto,
        ),
      ),
    );
  }
}

/// El fondo de un versiculo marcado.
///
/// Y SE CALCULA **AHI**, con el color y la intensidad del estilo, y no se pinta un `Color`
/// guardado: si el color se guardara, cambiar el color de un estilo dejaria a todos sus
/// resaltados con el color viejo, que es justo el motivo de que el estilo se guarde entero.
Color colorDeFondo(EstiloDeResaltado estilo) {
  final c = estilo.color;
  return Color.fromARGB(
    (255 * estilo.intensidad.opacidad).round(),
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
  );
}

/// El color del contorno de un versiculo marcado, si su forma lo tiene.
Color? colorDeContorno(EstiloDeResaltado estilo) =>
    estilo.forma == FormaDelResaltado.fondo
        ? null
        : Color.fromARGB(255, (estilo.color.r * 255).round(),
            (estilo.color.g * 255).round(), (estilo.color.b * 255).round());

/// La anchura del contorno, si lo hay.
double? grosorDeContorno(EstiloDeResaltado estilo) =>
    estilo.forma == FormaDelResaltado.fondo ? null : 2;