// La hoja con los comentarios que hay para poner al lado del texto.
//
// Y ES UNA HOJA Y NO UN MENU, y no por el tamano de la lista. Es una hoja porque se
// elige **una** cosa de una lista corta y luego se vuelve a leer: una hoja se cierra
// sola al elegir, y un menu se queda abierto encima del texto. Un menu encima del texto
// es un menu encima de lo que se queria leer, y encima de la mitad inferior de la
// pantalla, que en un movil es justo donde esta el versiculo que se ha pulsado.
//
// Y LA LISTA LA PASA QUIEN ABRE LA HOJA, y no se pide aqui. Una hoja que se documenta
// sola --"que comentarios hay"-- tiene que saber del manifiesto y del almacenamiento, y
// eso no lo sabe un widget. Aqui solo se pinta lo que le dan y se devuelve lo que se
// pulsa, que es lo unico que tiene que saber.
//
// Y DEVOLVER NULL Y "QUITAR" SON COSAS DISTINTAS, y por eso hay un elemento mas en la
// lista en vez de un boton aparte arriba. `null` es "no he cambiado nada": el usuario
// pulso fuera, le dio a la flecha, o no queria nada. Una cadena **vacia** es "quita el
// comentario". Con un solo valor de vuelta, cerrar la hoja sin querer por fuera
// quitaria el comentario, y abrir una hoja tocando a caballo seria una forma de
// perder lo que se estaba leyendo.

import 'package:flutter/material.dart';

import 'package:ab/ui/core/tema.dart';

/// Un comentario que se puede poner al lado, tal como lo nombra el manifiesto.
class ComentarioDisponible {
  const ComentarioDisponible({required this.id, required this.nombre});

  /// El identificador, tal cual lo declara el manifiesto. Es lo que va en la ruta.
  final String id;

  /// El nombre, para que se lea como lo que es y no como un identificador.
  ///
  /// Y ES LO QUE SE ENSENA Y NO EL `id`. La ruta lleva el `id` porque la ruta la
  /// resuelve una maquina, pero en pantalla "CLARKE" solo no dice nada: lo que dice es
  /// "el Comentario de Adam Clarke, que son cuatro tomos de 1832".
  final String nombre;

  /// Lo que sale en la hoja: el nombre, y el identificador debajo si no son lo mismo.
  ///
  /// Y EL IDENTIFICADOR SOLO SI DIFIEREN DEL NOMBRE. Un "CLARKE" pequeno bajo "Comentario
  /// de Adam Clarke" es ruido para quien lee, y en cambio es justo lo que hace falta
  /// para quien quiere saber que identificador poner en un enlace.
  String get subtitulo => nombre == id ? '' : id;
}

/// Pide un comentario. Devuelve su identificador, `''` para quitarlo, o null para nada.
///
/// Y **ES UN `Future` Y NO UN CALLBACK** porque quien la llama tiene que esperar antes de
/// tocar la ruta. Con un `void Function(void Function(String))` habia que guardar el
/// `BuildContext` a mano para cerrarla despues, y un `context` usado cuando el widget ya
/// no existe es el aviso de `use_build_context_synchronously`, que aparece en todos los
/// sitios y no dice nada de cual es el problema.
///
/// Y `showModalBottomSheet` YA SE ENCARGA DE `use_build_context_synchronously`: el aviso
/// sale cuando se usa el contexto **despues** de awaited, y aqui el await esta dentro de
/// el framework, no despues.
Future<String?> mostrarHojaDeComentarios({
  required BuildContext context,
  required List<ComentarioDisponible> actuales,
  required String? abierto,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // Y `isScrollControlled` A MEDIAS, no al maximo, porque el alto lo pone `Flexible` y
    // el contenido. Con el maximo, una hoja con dos elementos ocupa media pantalla y
    // tapa justo el texto que se quiere mirar mientras se elige.
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _HojaDeComentarios(actuales: actuales, abierto: abierto),
  );
}

/// La hoja.
class _HojaDeComentarios extends StatelessWidget {
  const _HojaDeComentarios({required this.actuales, required this.abierto});

  final List<ComentarioDisponible> actuales;
  final String? abierto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Medidas.margenAncho, 0, Medidas.margenAncho, 8),
            child: Text(
              'Comentario al lado del texto',
              style: t.textTheme.titleMedium,
            ),
          ),
          // Y EXPLICADO **ANTES** DE LA LISTA, y no despues. Quitar un comentario tiene
          // un boton y se ve solo; ponerlo uno nuevo son cuatro toques y una decision, y
          // sin esta frase el gesto parece que sea abrir el comentario en otra
          // pantalla, que es lo que haria si el boton no hiciera nada.
          Padding(
            padding: const EdgeInsets.fromLTRB(Medidas.margenAncho, 0, Medidas.margenAncho, 12),
            child: Text(
              'Las notas se ensenan debajo de cada versiculo, en el mismo texto.',
              style: t.textTheme.bodySmall?.copyWith(color: context.colores.textoSuave),
            ),
          ),

          // Y LA LISTA VACIA DICE UNA COSA Y NO "no hay comentarios". Que no haya
          // ninguno es lo normal para quien no ha descargado nada de 57 MiB, y la
          // respuesta util es donde se baja.
          if (actuales.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Medidas.margenAncho, 0, Medidas.margenAncho, Medidas.margenAncho),
              child: Text(
                'No hay ningun comentario descargado. Se bajan en la biblioteca.',
                style: t.textTheme.bodyMedium?.copyWith(color: context.colores.textoSuave),
              ),
            ),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: <Widget>[
                if (abierto != null)
                  ListTile(
                    leading: Icon(Icons.close, color: context.colores.textoSuave),
                    title: const Text('Quitar el comentario'),
                    subtitle: Text(
                      'Ahora mismo hay $abierto al lado',
                      style: t.textTheme.bodySmall,
                    ),
                    onTap: () => Navigator.of(context).pop(''),
                  ),
                for (final c in actuales)
                  ListTile(
                    leading: Icon(
                      c.id == abierto ? Icons.comment : Icons.comment_outlined,
                      color: c.id == abierto ? context.colores.acento : context.colores.textoSuave,
                    ),
                    title: Text(c.nombre),
                    subtitle: c.subtitulo.isEmpty
                        ? null
                        : Text(c.subtitulo, style: t.textTheme.bodySmall),
                    // Y MARCA EL ABIERTO CON UN TICK Y NO SOLO CON EL COLOR DEL ICONO.
                    // El color lo distingue el que ya sabe que hay uno; el tick lo
                    // distingue el que esta mirando la lista para elegir, que es justo el
                    // que no lo sabe.
                    trailing: c.id == abierto
                        ? Icon(Icons.check, color: context.colores.acento)
                        : null,
                    onTap: () => Navigator.of(context).pop(c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
