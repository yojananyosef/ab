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
/// ============================================================================
/// Y EL BOTON **NO** VA DEBAJO, Y ESTO CAMBIO AL MEDIR, NO POR GUSTO
/// ============================================================================
///
/// Medido en una captura de la pantalla de lectura a 360 px, con 22,5 MB del modulo ya
/// descargados yJuan 3:16 abierto en el KJV:
///
///     barra de arriba (dos lineas)                     56 px
///     campo "Ir a"                                     34 px
///     hueco                                            14 px
///     boton "Buscar" de 48 px, en su propia fila       48 px
///     hueco                                            14 px
///     titulo del capitulo, que **repetia** la barra    40 px
///     --------------------------------------------------------
///     cromo antes del primer versiculo                206 px
///     el versiculo                                     122 px
///     los terminos del modulo                          268 px
///
/// De 760 px de alto: **el versiculo es el 16 %** de la pantalla y los terminos el **35 %**.
///
/// Y EL BOTON DEBAJO ERA UNA DECISION ANTERIOR, CON SU MOTIVO, Y EL MOTIVO SE MIDIO:
///
///     "El boton va **debajo** del campo y no al lado. A 360 px, con el teclado abierto,
///     quedan unos 360 px de alto: campo y boton en fila dejan al boton con la mitad del
///     ancho y el texto se corta a los 12 caracteres."
///
/// El texto se corta a los 12 caracteres porque el campo se queda con la mitad del ancho.
/// **Eso se arregla dando al campo todo el ancho y poniendo el boton DENTRO**, como icono
/// de sufijo, que es donde lo pone Material y donde lo pone el resto. El campo entero para
/// "Juan 3:16" y el boton al lado derecho del campo, no debajo.
///
/// Y NO ES SOLO CUATRO PIXELES: son **62 px de alto** de los 760, un 8 % de la pantalla, y
/// un boton de 48 px de alto que esta deshabilitado el 99 % del tiempo porque no hay nada
/// escrito. Un control de medio palmo que casi nunca se puede pulsar, en la parte de arriba
/// de la pantalla, es el sitio mas caro de la pantalla para lo menos util.
///
/// Y EL TECLADO **NO** ES EL ARGUMENTO. Con el boton como icono de sufijo, el `Ir` del
/// teclado --`textInputAction: TextInputAction.search`, que ya estaba-- hace lo mismo, y
/// hace falta sin ningun boton en pantalla.
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
            hintText: 'Ir a: Juan 3:16',
            // Y **SIN** TEXTO DE AYUDA, Y SOLO EL DE ERROR.
            //
            // Antes habia las dos cosas a la vez: "No se entiende. Escribe el libro y el
            // capitulo, como "Juan 3:16"." encima de "Falta el capitulo. Por ejemplo,
            // "Juan 3"." Son dos frases que dicen lo mismo en 16 px de alto, y en una fila
            // de cabecera eso son 32 px de la pantalla por repetir un motivo.
            //
            // Y EL DE ERROR **TAMBIEN** SE ACORTA, porque dice lo mismo con menos:
            // "Falta el capitulo. Por ejemplo, "Juan 3"." son 38 caracteres y en 330 px de
            // campo salen en dos lineas. Con una linea --"Falta el capitulo."-- el motivo
            // sigue estando y el ejemplo se lleva al `Semantics`, que es lo que lee el
            // lector de pantalla.
            //
            // Y EL ANTERIOR MOTIVO DE LAS TRES LINEAS, que era "el campo vivia en el
            // cuerpo y tenia sitio", dejo de ser cierto cuando el campo subio a la
            // cabecera. Un motivo que se queda escrito sin que su cosa cambie es un motivo
            // que ya no explica nada.
            helperText: null,
            helperMaxLines: 1,
            errorText: esValido ? null : _motivoDeNoEntenderse(control.text),
            // Y EL SUFIJO **ES EL BOTON**, y no un "borrar" con el "ir" al lado. Con texto
            // escrito se ofrecen los dos, porque borrar sin poder ir no sirve de nada y
            // dos iconos de 40 px en un campo de 330 caben de sobra.
            suffixIcon: hayTexto
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Borrar',
                        icon: const Icon(Icons.close),
                        onPressed: alLimpiar,
                      ),
                      // Y EL BOTON DE IR, QUE ESTA DESHABILITADO SI NO HAY NADA ESCRITO.
                      // Un boton deshabilitado dentro del campo no empuja el texto: se ve
                      // gris y no hace nada, que es justo lo que tiene que hacer.
                      IconButton.filled(
                        tooltip: 'Ir a este pasaje',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: esValido ? alBuscar : null,
                      ),
                    ],
                  )
                : null,
            border: const OutlineInputBorder(),
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
      return 'Falta el capitulo.';
    }
    return 'No hay ningun texto con esa referencia.';
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
/// Las flechas de capitulo.
///
/// ============================================================================
/// Y ESTO YA **NO** DICE EL PASAJE, Y ANTES SI, Y ESO ERA UN ERROR MEDIDO
/// ============================================================================
///
/// Antes era una fila con una flecha de volver, el pasaje en grande en el centro y dos
/// flechas de capitulo. Medido en una captura a 360 px: la fila ocupaba **40 px** y
/// **repetia literalmente lo que ya decia la barra de arriba**, que desde el change de la
/// cabecera es "Juan 3:16" en su propia linea.
///
/// Dos veces el mismo dato, 40 px, en la parte de arriba de la pantalla, por encima del
/// primer versiculo. Y la flecha de volver tambien estaba duplicada: la barra ya tiene la
/// suya.
///
/// Y QUEDAN LAS DOS FLECHAS Y NO EL TITULO, porque el titulo no hace falta --esta ahi
/// arriba-- y las flechas si: leer seguido es el uso mas frecuente de un lector de Biblia
/// y ellas son un gesto de un dedo.
///
/// Y AL DERECHA Y NO CENTRADAS, porque con el titulo fuera las dos flechas centradas
/// quedan en mitad de la pantalla, que es donde esta el texto, y parece un boton suelto en
/// medio del versiculo.
class FlechasDeCapitulo extends StatelessWidget {
  const FlechasDeCapitulo({
    super.key,
    required this.hayAnterior,
    required this.haySiguiente,
    required this.alAnterior,
    required this.alSiguiente,
  });

  final bool hayAnterior;
  final bool haySiguiente;
  final VoidCallback alAnterior;
  final VoidCallback alSiguiente;

  @override
  Widget build(BuildContext context) {
    // Y `visualDensity: compact` PORQUE VAN EN LA FILA DEL CAMPO. Con la densidad
    // normal, dos `IconButton` de 48 pxNextracted con el campo de 34 px obligan a que el
    // campo crezca para poder alinearse al centro, y el campo es el que importa.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Capitulo anterior',
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
          onPressed: hayAnterior ? alAnterior : null,
        ),
        IconButton(
          tooltip: 'Capitulo siguiente',
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
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
