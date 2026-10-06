// Un panel: una ventana de lectura con su modulo abierto.
//
// ============================================================================
// QUE ES UN PANEL Y POR QUE NO ES UN `LectorViewModel`
// ============================================================================
//
// Un panel es **lo que hay en una pestana**: un modulo abierto, el pasaje que se esta
// leyendo en el, y opcionalmente un comentario al lado. Es lo que Logos llama panel, y
// es la unidad que se cierra, la que ocupa memoria y la que se puede poner al lado de
// otra.
//
// Y ES UN MODELO DE DOMINIO Y NO UN VIEWMODEL, y la razon es que no lleva ni una regla:
// el id sale del modulo, el comentario es lo que se abrio al lado, y el pasaje se pide.
// Lo que decide cuando cerrar un `.amod` y quien esta delante es [PanelesViewModel], que
// es un view model de la interfaz y por lo tanto no puede estar en `domain`.
//
// Y `esComentario` **NO SE ADIVINA** por lo que el modulo traiga, igual que
// `Pasaje.traeNotas`. Se dice aqui porque quien lo abre sabe lo que ha abierto --es el
// manifiesto o es `info.type`-- y escribirlo es una pregunta que ya tiene respuesta.
// Adivinarlo por las tablas es el fallo que esta escrito en `AGENTS.md`: una Biblias
// que guarde tambien notas dejaria de distinguirse de un comentario, y el crash aparece
// en el sitio mas visible.
//
// ============================================================================
// Y EL IDENTIFICADOR ES EL DEL MODULO, Y ESO ES UNA DECISION MEDIDA
// ============================================================================
//
// Un panel se identifica **por el modulo que tiene abierto**, no con un numero. Y no es
// comodidad: es que abrir el mismo texto dos veces son 22,5 MiB de paginas SQLite
// abiertos dos veces --medido el 6 de octubre de 2026--, y en un movil de gama baja eso
// es la diferencia entre que funcione y que no.
//
// O sea que "abrir KJV2006 otra vez" **no abre un panel nuevo**: trae al frente el que
// ya hay. Y eso no es un atajo, es lo que hace que la pestana que se pulsa y la que sale
// sean siempre la misma cosa. Un contador de paneles que sube con cada pulsacion del
// boton de volver a abrir el mismo texto es un contador que mide pulsaciones, no
// ventanas.

import 'package:ab/domain/models/referencia.dart';

/// Un panel abierto: un modulo, el pasaje que se lee en el, y su comentario.
class PanelAbierto {
  const PanelAbierto({
    required this.moduloId,
    required this.referencia,
    this.comentarioId,
    this.esComentario = false,
  });

  /// El identificador del modulo, tal cual lo declara el manifiesto.
  ///
  /// Y ES LA IDENTIDAD DEL PANEL. Ver la nota de arriba: dos paneles del mismo modulo
  /// serian el mismo `.amod` abierto dos veces.
  final String moduloId;

  /// Que se esta leyendo en este panel.
  ///
  /// Y **PUEDE SER DISTINTO EN CADA PANEL**, y no es un error. En Logos los paneles
  /// pueden estar en lugares distintos --uno en Juan 3 y otro en el Salmo 119--, y
  /// obligar a que todos muestren la misma referencia seria inventar una regla que el
  /// producto no tiene. Lo que si es el principio es que cambiar de panel **no** cambia
  /// lo que hay en los demas, y por eso esto es de cada panel y no de la ventana.
  final Referencia referencia;

  /// El comentario que va al lado de este texto, o null si no hay ninguno.
  final String? comentarioId;

  /// Si lo que hay abierto en este panel es un comentario y no un texto de Biblia.
  ///
  /// Y SE DICE, NO SE ADIVINA. Ver la cabecera.
  final bool esComentario;

  /// Un panel con otro modulo.
  PanelAbierto copyWith({
    Referencia? referencia,
    String? comentarioId,
    bool quitarComentario = false,
  }) =>
      PanelAbierto(
        moduloId: moduloId,
        referencia: referencia ?? this.referencia,
        comentarioId: quitarComentario ? null : (comentarioId ?? this.comentarioId),
        esComentario: esComentario,
      );

  @override
  bool operator ==(Object other) =>
      other is PanelAbierto &&
      other.moduloId == moduloId &&
      other.referencia == referencia &&
      other.comentarioId == comentarioId &&
      other.esComentario == esComentario;

  @override
  int get hashCode => Object.hash(moduloId, referencia, comentarioId, esComentario);

  @override
  String toString() => 'panel $moduloId ${referencia.paraUrl}'
      '${comentarioId == null ? '' : ' con $comentarioId'}';
}