// El velo de atenuacion.
//
// ============================================================================
// POR QUE UN VELO Y NO BAJAR EL BRILLO
// ============================================================================
//
// En web y en movil la aplicacion **no puede** bajar el brillo del panel: no hay API para
// eso, y la que hay en algunos moviles es de una sola app y con permiso. Lo que **si** se
// puede es poner un velo negro encima.
//
// Y ESO ES LO QUE HACE `aletheia-reader`, con el motivo escrito ahi: bajar el brillo del
// panel por software a pantalla completa es lo que hace parpadear los paneles con modulacion
// de anchura de pulso, y ese parpadeo --que no se ve, se nota-- es lo que hace que OLED duela
// a quien lo tiene por las noches. Un velo no produce modulacion de anchura de pulso: es un
// negro fijo.
//
// Y DE DONDE VIENE LA IDEA, ademas. Es de ahi, y tambien el matiz de que el velo va
// **por debajo de las hojas y de los menus**: un atenuador que se atenua a si mismo al abrir
// un menu es un atenuador roto, porque el menu es justo lo que hay que leer con el brillo
// bajo.
//
// ============================================================================
// Y POR QUE VA HECHO COMO UN WIDGET Y NO COMO UN `ColorFiltered`
// ============================================================================
//
// Porque `ColorFiltered` tambien baja el contraste del texto --multiplica los canales por el
// mismo factor--, y un texto al 60 % de un 16,96:1 da un 10,2:1, que sigue bien, pero uno al
// 40 % da 6,8:1 y **deja de cumplir AAA**. Con un velo negro encima, el contraste del texto
// baja igual, que es inevitable: no hay forma de atenuar la luz sin bajar el contraste del
// texto que hay delante.
//
// Y POR QUE AUN ASI SE HACE. El umbral de 7:1 es para leer con luz de dia. A las doce de la
// noche en la cama, un fondo a pleno blanco es el problema y 6:1 es aceptable. Y el velo
// tiene un tope del **60 %** --una atenuacion del 40 %--, con lo que el peor caso es 0,4 y
// el texto se queda en el 6,8:1, que es AA grande. Atravesar el AAA de dia a proposito para
// poder leer de noche es un intercambio, y por eso el tope es un tope y no "hasta donde
//.aguas".

import 'package:flutter/material.dart';

/// El velo, si hay atenuacion puesta.
class VeloDeAtenuacion extends StatelessWidget {
  const VeloDeAtenuacion({super.key, required this.atenuacion});

  /// De 0,4 a 1. Un 1 es "sin atenuar".
  final double atenuacion;

  @override
  Widget build(BuildContext context) {
    // Y SIN FILTRO DE INTERACCION, Y PORQUE NO ES UN BOTON: es un velo. Con
    // `IgnorePointer` no se puede pulsar a traves --lo que es lo que haria un `ModalBarrier`
    // sin motivo--, y con el el contenido de debajo sigue funcionando.
    if (atenuacion >= 0.99) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 1 - atenuacion),
      ),
    );
  }
}

/// Envuelve [hijo] con el velo encima.
///
/// Y EN UNA `Stack` Y NO CON UN `ColorFiltered`, por lo que dice el comentario de la clase:
/// el velo tiene que ser **encima**, y por encima de todo lo que no sea una hoja.
class ConVeloDeAtenuacion extends StatelessWidget {
  const ConVeloDeAtenuacion({
    super.key,
    required this.atenuacion,
    required this.hijo,
  });

  final double atenuacion;
  final Widget hijo;

  @override
  Widget build(BuildContext context) => Stack(
        // Y `Alignment.topLeft` Y NO `AlignmentDirectional.topStart`, y este widget es la
        // razon de que eso sea una distincion y no una manIa: el velo va **encima** del
        // `MaterialApp`, que es lo que hace que las hojas se pinten encima, y por encima del
        // `MaterialApp` **no hay `Directionality`**, porque lo introduce el `MaterialApp`:
        //
        //     No Directionality widget found.
        //     Stack widgets require a Directionality widget ancestor
        //
        // Un `Stack` sin `alignment` usa `AlignmentDirectional.topStart`, que necesita la
        // direccion de texto. Y como aqui no hay direccion, revienta **al construir la app**,
        // en el arranque, antes de que se vea nada.
        alignment: Alignment.topLeft,
        children: <Widget>[
          hijo,
          Positioned.fill(child: VeloDeAtenuacion(atenuacion: atenuacion)),
        ],
      );
}
