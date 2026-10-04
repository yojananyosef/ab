// El campo donde se escribe a donde ir.
//
// QUE SE ESCRIBE Y QUE SE ACEPTA. Un campo, y acepta lo que la gente escribe de
// verdad: "Juan 3", "Juan 3:16", "3:16", "John.3.16", "Segundo de Corintios 13". Y
// **la misma regla** que usa la direccion, la de `Referencia.tryParse`, sin una
// segunda copia. Dos reglas de verdad son dos reglas que se separan: alguien las
// arregla una y no la otra, y aparece un texto que se busca de una forma y se abre
// de otra.
//
// Y LA VALIDACION ES EN VIVO, NO AL PULSAR. Que el boton se ponga gris mientras se
// escribe "Juan 3:" es lo que evita que alguien pulse con la referencia a medias y
// land en un sitio que no quiere. Un boton que esta activo y lleva a un error es
// peor que un boton que no existe.
//
// ============================================================================
// Y POR QUE NO HAY UN MENU DE LIBROS, CAPITULOS Y VERSICULOS
// ============================================================================
//
// Se podria hacer con tres listas desplegables, y es lo que hacen casi todos. Se
// escribe a pelo porque quien esta leyendo Juan 3 y quiere ir a Juan 5:17 no quiere
// tres pulsaciones y una ruleta para acabar en un sitio que ya conoce. El menu queda
// para cuando se sepa que el campo no sirve --y entonces se ofrece, no antes--.
//
// ESO NO IMPIDE QUE HAYA UN SELECTOR. Lo que hay aqui es **el campo**, y en un
// cambio posterior se le anade un boton que abre el arbol de los 66 libros con los
// capitulos que el modulo tiene, porque esa consulta sale de una consulta al modulo
// y por eso puede ser real y no una suposicion. Ver la tarea 7.8.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/referencia.dart';

import '../../../core/tema.dart';

/// El campo de referencia y su boton.
///
/// El boton va **debajo** del campo y no al lado, y no es una decision de estetica.
/// A 360 px, con el teclado abierto, quedan unos 360 px de alto: campo y boton en
/// fila dejan al boton con la mitad del ancho y el texto se corta a los 12
/// caracteres justo cuando se esta escribiendo "Juan 3:16". En fila vertical el boton
/// ocupa todo el ancho y se llega con el pulgar, que es donde esta el pulgar.
class CampoDeReferencia extends StatelessWidget {
  const CampoDeReferencia({
    super.key,
    required this.control,
    required this.alEscribir,
    required this.alBuscar,
    required this.alLimpiar,
    required this.esValido,
    required this.hayTexto,
  });

  final TextEditingController control;

  /// Cada tecla. Es lo que hace la validacion **en vivo**.
  final ValueChanged<String> alEscribir;

  /// Pulsar buscar. Solo se llama si [esValido].
  final VoidCallback alBuscar;

  final VoidCallback alLimpiar;

  /// Si lo escrito se puede abrir. While false, el boton esta deshabilitado.
  final bool esValido;

  /// Si hay algo escrito. While false, no se ensena el boton de limpiar.
  final bool hayTexto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: control,
          onChanged: alEscribir,
          onSubmitted: esValido ? (_) => alBuscar() : null,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          // El teclado numerico con el capitulo y el versiculo. Es una comodidad
          // pequena que no cuesta nada y que en un movil se nota.
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Ir a',
            hintText: 'Juan 3:16',
            helperText: esValido
                ? null
                : 'No se entiende. Escribe el libro y el capitulo, como "Juan 3:16".',
            helperMaxLines: 3,
            errorText: esValido ? null : _motivoDeNoEntenderse(control.text),
            suffixIcon: hayTexto
                ? IconButton(
                    tooltip: 'Borrar',
                    icon: const Icon(Icons.close),
                    onPressed: alLimpiar,
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        // Un boton alto. 48 px es el minimo que el framework considera pulsable con
        // el dedo, y por debajo la gente falla la pulsacion sin darse cuenta.
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: esValido && hayTexto ? alBuscar : null,
            child: const Text('Buscar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  /// Por que no se entiende, en castellano y en concreto.
  ///
  /// "Entrada no valida" no le dice nada a nadie. Y tiene que ser concreto porque hay
  /// tres fallos distintos que se distinguen a ojo --que no exista el libro, que falte
  /// el capitulo, que el capitulo no sea un numero-- y quien lo escribe sabe cual es
  /// sin que se lo digan.
  ///
  /// Y SI NO SE DICE NADA, SE DICE "No se entiende". Un campo rojo sin motivo parece
  /// un fallo de la aplicacion, y no lo es: es que lo escrito no es una referencia.
  static String? _motivoDeNoEntenderse(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    if (Referencia.tryParse(t) != null) return null;

    // Sin ningun numero no hay capitulo: casi siempre es que se ha escrito el libro
    // solo, que es lo mas comun y lo que mas se equivoca uno.
    if (!RegExp(r'\d').hasMatch(t)) {
      return 'Falta el capitulo. Por ejemplo, "$t 3".';
    }
    return 'No hay ningun texto con esa referencia. Prueba con "Juan 3:16".';
  }
}

/// El titulo del pasaje: "Juan 3", con flechas de capitulo al lado.
///
/// Y EL TITULO VA EN CASTELLANO Y LA URL EN LA CLAVE DEL MODULO, y no es una
/// contradiccion: lo que se ve lo entiende quien lee, y lo que va en la direccion lo
/// resuelve el modulo. Si la direccion dijera "Juan", habria que traducirla al abrir.
///
/// Y LAS FLECHAS NO SABEN CUANTOS CAPITULOS HAY, Y ESO ES LO IMPORTANTE. Se
/// deshabilitan preguntando: el boton de "capitulo siguiente" se apaga en el ultimo
/// capitulo **que el modulo tiene**, y no en el ultimo que la serie tiene. El KJV
/// acaba en Juan 21 y la RVR tambien, pero una traduccion puede acabar antes, y un
/// boton que lleva a un capitulo que no existe es un boton roto que se pulsa sin
/// querer.
///
/// Y NO HAY UN BOTON DE "CAPITULO ANTERIOR" EN EL PRIMERO NI DE "SIGUIENTE" EN EL
/// ULTIMO. Un boton deshabilitado se ve, y se ve para decir "no hay mas", que es
/// informacion. Un boton que desaparece deja a quien lo busca sin respuesta.
class TituloDelPasaje extends StatelessWidget {
  const TituloDelPasaje({
    super.key,
    required this.referencia,
    required this.hayAnterior,
    required this.haySiguiente,
    required this.alAnterior,
    required this.alSiguiente,
    required this.alVolver,
  });

  final Referencia referencia;
  final bool hayAnterior;
  final bool haySiguiente;
  final VoidCallback alAnterior;
  final VoidCallback alSiguiente;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Volver a la biblioteca',
          icon: const Icon(Icons.arrow_back),
          onPressed: alVolver,
        ),
        Expanded(
          child: Text(
            referencia.texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            // Una linea, con puntos. Un titulo de tres lineas empuja el versiculo 1
            // fuera de la pantalla, que en un movil es la primera linea que se lee.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Capitulo anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: hayAnterior ? alAnterior : null,
        ),
        IconButton(
          tooltip: 'Capitulo siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: haySiguiente ? alSiguiente : null,
        ),
      ],
    );
  }
}

/// El pie de la pantalla de lectura.
///
/// Va **abajo**, no en un menu. Y no es una decision de donde colocar las cosas: es
/// la obligacion de licencia del repositorio hermano, y una obligacion que hay que
/// buscar no cumple. Ver `terminos_del_modulo.dart`, que es donde esta el
/// razonamiento entero.
///
/// Y EN UN MOVIL NO TAPA NADA. Va en el propio scroll, al final del capitulo. Un pie
/// fijo taparia texto, que es la peor cosa que puede hacer un pie.
class PieDeLectura extends StatelessWidget {
  const PieDeLectura({super.key, required this.hijo});

  final Widget hijo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 40),
        child: hijo,
      );
}

/// El borde del contenido de lectura, para que el texto no quede pegado al borde.
///
/// No es cosmetica: a 360 px sin margen, el numero de versiculo queda en el borde de
/// la pantalla y el pulgar lo tapa al desplazarse.
class MargenDeLectura extends StatelessWidget {
  const MargenDeLectura({super.key, required this.hijo});

  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Medidas.margenPara(ancho)),
      child: hijo,
    );
  }
}
