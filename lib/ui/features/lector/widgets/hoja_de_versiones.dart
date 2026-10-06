// La hoja con las versiones del texto que se pueden leer.
//
// ============================================================================
// POR QUE ESTA HOJA Y POR QUE ES LO MAS IMPORTANTE DE LA CABECERA
// ============================================================================
//
// De `docs/investigacion-ux.md`, seccion "Los botones que se copian":
//
//   "Selector de version desde la cabecera del lector, con filtro mientras se escribe.
//   Comparar versiones sin salir de la lectura es la interaccion mas valiosa de una app
//   de Biblia."
//
// Y HASTA HACE UN RATO NO EXISTIA, con la funcion cableada y sin llamar. `alCambiarDeVersion`
// estaba en el `LectorView` desde el principio, el enrutador lo atendia, y **ningun boton
// lo llamaba**: la interaccion mas valiosa de la categoria era inalcanzable.
//
// Y ESTA EN LA CABECERA Y NO EN UN MENU, porque un menu de versiones encima del texto es un
// menu encima de lo que se quiere leer, y encima de la mitad inferior de la pantalla, que
// en un movil es justo donde esta el versiculo que se ha pulsado. Es una hoja.
//
// ============================================================================
// Y SE VE EL ESTADO DE CADA UNA, QUE NO ES LO MISMO QUE VER EL NOMBRE
// ============================================================================
//
// Con el catalogo de hoy hay **una** Biblia, asi que esta hoja hoy no deja comparar nada.
// Eso no es un motivo para no hacerla: es la funcion que hace falta en cuanto haya una
// segunda version, y es la que hace que el boton de la cabecera signifique algo.
//
// Y NO SE ADORNAN LOS DATOS. El tamano viene del manifiesto y se ensena con el separador
// de millares de `numeros.dart`, porque "22544384" en un boton no es un tamano, es un
// volcado. Y una version que no esta descargada **lo dice**, con su tamano, en vez de
// aparecer igual que las otras: un "Descargar" sin coste conocido no se pulsa, y uno que
// dice 22,5 MB se decide.

import 'package:flutter/material.dart';

import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/tema.dart';

/// Una version de texto, tal como la nombra el manifiesto.
class VersionDisponible {
  const VersionDisponible({
    required this.id,
    required this.nombre,
    required this.descargado,
    required this.bytes,
  });

  /// El identificador, tal cual lo declara el manifiesto. Es lo que va en la ruta.
  final String id;

  /// El nombre, para que se lea como lo que es y no como un identificador.
  final String nombre;

  /// Si ya esta en este dispositivo.
  final bool descargado;

  /// Cuanto ocupa, tal como lo declara el manifiesto.
  final int bytes;

  /// Lo que va debajo del nombre: el identificador si no es lo mismo, y el estado.
  ///
  /// Y EL ESTADO SOLO SI DICE ALGO. Un modulo descargado no necesita una linea que diga
  /// "descargado": lo dice el tick, y una linea de mas en cada fila es ruido.
  String? get detalle => descargado
      ? (nombre == id ? null : id)
      : 'No descargado · ${bytesEnCastellano(bytes)}';
}

/// Pide una version. Devuelve su identificador, o null si se cierra sin elegir.
Future<String?> mostrarHojaDeVersiones({
  required BuildContext context,
  required List<VersionDisponible> disponibles,
  required String? abierta,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _HojaDeVersiones(
      disponibles: disponibles,
      abierta: abierta,
    ),
  );
}

class _HojaDeVersiones extends StatefulWidget {
  const _HojaDeVersiones({required this.disponibles, required this.abierta});

  final List<VersionDisponible> disponibles;
  final String? abierta;

  @override
  State<_HojaDeVersiones> createState() => _HojaDeVersionesState();
}

class _HojaDeVersionesState extends State<_HojaDeVersiones> {
  final TextEditingController _control = TextEditingController();
  String _texto = '';

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final limpio = _texto.trim().toLowerCase();

    // Y EL FILTRO ES SOBRE LO QUE SE HA ESCRITO, con el identificador tambien. Con una
    // sola version el filtro no hace nada, y con veinte "--" hara falta buscar por lo que
    // pone el manifiesto, que es `KJV2006` y no "King James Version".
    final lista = limpio.isEmpty
        ? widget.disponibles
        : widget.disponibles
            .where((v) =>
                v.nombre.toLowerCase().contains(limpio) ||
                v.id.toLowerCase().contains(limpio))
            .toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.fromLTRB(Medidas.margenEstrecho, 0, Medidas.margenEstrecho, 8),
            child: Text('Version del texto', style: t.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenEstrecho,
              0,
              Medidas.margenEstrecho,
              4,
            ),
            child: TextField(
              controller: _control,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: 'Buscar una version',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _texto = v),
            ),
          ),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Medidas.margenAncho),
              child: Text(
                'Ninguna version se llama "$_texto" en este catalogo.',
                style: t.textTheme.bodyMedium?.copyWith(color: context.colores.textoSuave),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Medidas.margenAncho),
              children: <Widget>[
                for (final v in lista)
                  ListTile(
                    leading: Icon(
                      v.descargado ? Icons.menu_book : Icons.download_outlined,
                      color: v.descargado ? context.colores.acento : context.colores.textoSuave,
                    ),
                    title: Text(v.nombre),
                    subtitle: v.detalle == null
                        ? null
                        : Text(v.detalle!, style: t.textTheme.bodySmall),
                    trailing: v.id == widget.abierta
                        ? Icon(Icons.check, color: context.colores.acento)
                        : null,
                    onTap: () => Navigator.of(context).pop(v.id),
                  ),
                if (widget.disponibles.length == 1 && limpio.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.margenEstrecho,
                      12,
                      Medidas.margenEstrecho,
                      Medidas.margenAncho,
                    ),
                    child: Text(
                      'Solo hay un texto en el catalogo. Comparar versiones aparece '
                      'cuando haya mas de uno.',
                      style: t.textTheme.bodySmall?.copyWith(color: context.colores.textoSuave),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}