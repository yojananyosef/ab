// La fila de un modulo en la biblioteca.
//
// UNA FILA, Y ES LA PIEZA QUE MAS SE ROMPE. Lo que hay aqui cabe en tres reglas y
// son las que hacen que una lista de estos se pueda usar:
//
//  1. **El estado tiene texto, no solo color.** El estado va en su propia linea, con
//     su palabra. El color es un aditivo: lo que distingue un estado de otro es la
//     palabra "Descargado" o "Hay version nueva", y eso lo lee quien tiene baja
//     vision, quien tiene el movil en escala de grises y quien no distingue el verde
//     del gris. Un lector de Biblia se usa mucho y se usa en sitios con poca luz,
//     que es exactamente donde un estado solo por color no se ve.
//
//  2. **El boton va abajo en pantallas estrechas, al lado en anchas.** En una fila de
//     360 px, un boton al lado del nombre obliga a que el nombre ocupe 200 px y
//     OnestWrap tres lineas para un nombre de una. Abajo, el nombre tiene todo el
//     ancho y el boton se queda con un ancho fijo.
//
//  3. **Nada que desborde.** Ni una fila con un nombre larguisimo, ni con un
//     identificador de 64 caracteres, ni con un numero de version raro. Todo lo que
//     puede ser largo, se corta. Y el `Text` va con `softWrap` en vez de una
//     `Text` sola, porque una `Text` sola en una `Row` **desborda** en cuanto el
//     texto no cabe, y eso es una excepcion en pantalla.
//
// Y UNA MAS, QUE ES LA QUE IMPORTA MAS: **el motivo por el que no se puede
// descargar va en la fila, y es distinto segun el caso.** Un modulo que no se ha
// descargado todavia y un modulo al que el navegador no le deja leer el fichero no
// son el mismo problema y no pueden decir lo mismo: el primero se arregla con
// "Descargar" y el segundo, no.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/ui/core/idiomas.dart';
import 'package:ab/ui/core/tema.dart';

import '../view_models/biblioteca_view_model.dart';

/// Por que un modulo no se puede descargar.
///
/// Va como parametro y no se deduce de los bits, porque hay dos casos que desde la
/// fila se ven iguales y no lo son: "todavia no" y "no se puede". La diferencia es
/// la accion que se ofrece, y por eso tiene que ser un dato.
enum PorQueNoSePuedeDescargar {
  /// No es un problema: simplemente no esta descargado.
  todaviaNo('Descargar'),

  /// El navegador no deja leer el fichero desde la pagina. Un reintento no lo
  /// arregla: lo unico es traer el fichero a mano.
  ///
  /// ASI QUE NO SE ENSENA NINGUN BOTON DE REINTENTAR, y se ensena el de fichero
  /// local. Poner los dos seria decir "prueba otra vez" cuando se sabe que otra vez
  /// va a ser igual.
  origenNoLegible('Abrir fichero'),

  /// No se sabe todavia. Puede ser la red, y un reintentar si sirve.
  sinConexion('Reintentar');

  const PorQueNoSePuedeDescargar(this.textoDelBoton);
  final String textoDelBoton;
}

class FilaModulo extends StatelessWidget {
  const FilaModulo({
    super.key,
    required this.fila,
    required this.porQue,
    required this.alPulsarDescargar,
    required this.alPulsarLeer,
    required this.alPulsarFicheroLocal,
  });

  final FilaDeModulo fila;

  /// Si es null, se ofrece descargar. Si no lo es, se ofrece lo que diga.
  final PorQueNoSePuedeDescargar? porQue;

  final VoidCallback alPulsarDescargar;
  final VoidCallback alPulsarLeer;
  final VoidCallback alPulsarFicheroLocal;

  @override
  Widget build(BuildContext context) {
    return Container(
      // El ancho maximo va aqui y no en la lista: asi cada fila se centra sola y
      // no hace falta un `Center` que envuelva a la lista entera.
      constraints: const BoxConstraints(maxWidth: Medidas.anchoMaximoDeFila),
      padding: const EdgeInsets.symmetric(horizontal: Medidas.margenEstrecho, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(fila: fila),
          const SizedBox(height: 8),
          _Datos(fila: fila),
          const SizedBox(height: 10),
          _Estado(fila: fila),
          if (_explicacion != null) ...[
            const SizedBox(height: 8),
            _Explicacion(texto: _explicacion!),
          ],
          const SizedBox(height: 12),
          _colocarBotones(context),
        ],
      ),
    );
  }

  /// El motivo, o null si no hay ninguno que explicar.
  ///
  /// Solo hay explicacion cuando hay algo que hacer que no sea "descargar". En los
  /// demas casos, el estado ya lo dice y una linea mas seria ruido.
  String? get _explicacion {
    if (fila.retirado) {
      return 'El catalogo ya no ofrece este modulo, pero se puede seguir leyendo.';
    }
    if (porQue == PorQueNoSePuedeDescargar.origenNoLegible) {
      return 'El servidor no permite a esta pagina leer el fichero. '
          'Se puede abrir desde el dispositivo.';
    }
    if (fila.hayVersionNueva) {
      return 'La copia de este dispositivo es de otra version. '
          'Se puede seguir leyendo, o bajar la nueva.';
    }
    return null;
  }

  /// Los botones de la fila, en orden de prioridad.
  ///
  /// SE CALCULAN TODOS JUNTOS Y LUEGO SE COLOCAN, en vez de tener un "principal" y un
  /// "secundario" fijos. La primera version tenia dos ranuras y las llenaba siempre, y
  /// con el origen bloqueado salian **dos botones para lo mismo**: un "Abrir fichero"
  /// deshabilitado y un "Fichero local" al lado. Un boton deshabilitado que dice una
  /// cosa y otro que dice otra para lo mismo es la peor combinacion posible: quien lo
  /// ve no sabe cual es el bueno.
  ///
  /// Y si solo hay un boton, se pone **solo**, sin el hueco del otro. Un hueco gris es
  /// sitio que se ve y no se puede usar.
  List<Widget> _botones() {
    final botones = <Widget>[];

    // 1. Leer, si esta en el dispositivo. Es lo que quiere el 90 por ciento de las
    //    veces que se abre esta pantalla, asi que es lo primero.
    if (fila.sePuedeLeer) {
      botones.add(FilledButton(onPressed: alPulsarLeer, child: const Text('Leer')));
    }

    // 2. Descargar, si el origen no esta bloqueado.
    //
    //    La condicion es `origenNoLegible` y no `porQue != null`, porque con el
    //    catalogo caido `porQue` es `sinConexion` y **si** tiene sentido reintentar.
    //    Bloquearse por `porQue != null` dejaria a alguien sin poder reintentar con el
    //    movil sin cobertura, que es justo cuando mas lo necesita.
    final bloqueado = porQue == PorQueNoSePuedeDescargar.origenNoLegible;
    if (!fila.sePuedeLeer && !bloqueado) {
      botones.add(
        FilledButton(
          onPressed: alPulsarDescargar,
          child: Text(porQue?.textoDelBoton ?? 'Descargar'),
        ),
      );
    }

    // 3. Fichero local. Siempre que se pueda descargar, porque hay quien lleva el
    //    modulo en un pendrive de verdad, y siempre que este bloqueado, porque es la
    //    unica via. Lo que **no** aparece es con un modulo ya descargado: ahi no hace
    //    falta y solo haria ruido.
    if (!fila.descargado) {
      botones.add(
        OutlinedButton.icon(
          onPressed: alPulsarFicheroLocal,
          icon: const Icon(Icons.folder_open_outlined, size: 20),
          label: const Text('Fichero local'),
        ),
      );
    }

    return botones;
  }

  /// Coloca los botones: apilados en movil, en linea en pantallas anchas.
  ///
  /// Apilados por debajo de [Medidas.anchoParaDosColumnas] porque dos botones en linea
  /// a 360 px son de 160 px cada uno, y a 160 px el texto "Descargar" se queda sin
  /// padding y pegado al borde.
  Widget _colocarBotones(BuildContext context) {
    final botones = _botones();
    if (botones.isEmpty) return const SizedBox.shrink();
    if (botones.length == 1) return botones.first;

    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho < Medidas.anchoParaDosColumnas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[botones.first, const SizedBox(height: 8), botones[1]],
      );
    }
    // El principal mas ancho: es el que se usa, y el que tiene el texto largo.
    return Row(
      children: <Widget>[
        Expanded(flex: 3, child: botones.first),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: botones[1]),
      ],
    );
  }
}

/// El nombre del modulo.
///
/// Con `softWrap` y sin `overflow: ellipsis` en una `Row`: el nombre de una
/// traduccion puede ser largo de verdad ("King James Version (2006)") y cortarlo a
/// "King James Ver..." quita justo la parte que distingue una de otra. En su lugar
/// se corta **por la palabra**, que siempre es mas util que por el caracter.
class _Titulo extends StatelessWidget {
  const _Titulo({required this.fila});

  final FilaDeModulo fila;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // `Flexible` dentro de una `Column` no hace nada, pero `Text` con
        // `softWrap` en una `Column` con `crossAxisAlignment: start` **si** se
        // ajusta al ancho disponible, que es lo que se quiere.
        Text(fila.titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(
          fila.id,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Tipo, idioma, licencia y tamano. Todo del manifiesto.
class _Datos extends StatelessWidget {
  const _Datos({required this.fila});

  final FilaDeModulo fila;

  @override
  Widget build(BuildContext context) {
    final m = fila.modulo;
    // Un modulo retirado no tiene de donde sacar esto, y no se inventa. Se enseena
    // solo el identificador, que ya esta en el titulo, y no una fila de guiones.
    if (m == null) {
      return Text(
        'Sin datos en el catalogo',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final partes = <String>[
      textoDeIdioma(m.idioma),
      if (fila.megabytes != null) '${fila.megabytes} MB',
      _textoDeLicencia(m.licencia),
    ];

    return Wrap(
      // `Wrap` y no `Row`: los tres datos no caben a 360 px con un nombre de una
      // linea al lado, y con `Row` el tercero se sale de la pantalla. `Wrap` los
      // baja a la linea siguiente, que es lo unico que se puede hacer en un movil.
      spacing: 14,
      runSpacing: 4,
      children: <Widget>[
        for (final p in partes)
          Text(p, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// La licencia, en castellano si se puede y en crudo si no.
  ///
  /// `PublicDomain` se traduce porque es la palabra que aparece en el 100 por ciento
  /// de los modulos de hoy, y una app en castellano que ensene "PublicDomain" en una
  /// fila pequena parece un programa que no esta acabado. Cualquier otra licencia se
  /// deja tal cual: los nombres oficiales de las Creative Commons se escriben en
  /// ingles y traducirlos seria inventar.
  static String _textoDeLicencia(String licencia) => switch (licencia) {
    'PublicDomain' => 'dominio publico',
    _ => licencia,
  };
}

/// El estado, con su palabra y su icono.
///
/// El icono y el color son un aditivo. Lo que dice el estado es [EstadoModulo.texto].
class _Estado extends StatelessWidget {
  const _Estado({required this.fila});

  final FilaDeModulo fila;

  @override
  Widget build(BuildContext context) {
    final color = switch (fila.estado) {
      EstadoModulo.descargado => Colores.acento,
      EstadoModulo.retirado => Colores.textoSuave,
      EstadoModulo.desactualizado => Colores.primario,
      EstadoModulo.descargando => Colores.primario,
      EstadoModulo.disponible => Colores.textoSuave,
    };
    final icono = switch (fila.estado) {
      EstadoModulo.descargado => Icons.check_circle_outline,
      EstadoModulo.retirado => Icons.archive_outlined,
      EstadoModulo.desactualizado => Icons.update,
      EstadoModulo.descargando => Icons.downloading_outlined,
      EstadoModulo.disponible => Icons.download_outlined,
    };

    return Row(
      children: <Widget>[
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 6),
        // `Expanded` porque el texto del estado puede ser largo ("Hay version
        // nueva") y con una `Row` sin el se sale de la pantalla a 360 px.
        Expanded(
          child: Text(
            fila.estado.texto,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

/// La explicacion. Con su icono de aviso, que tampoco es el unico portador del
/// significado: el texto esta ahi para quien no ve el icono.
class _Explicacion extends StatelessWidget {
  const _Explicacion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Icon(Icons.info_outline, size: 17, color: Colores.peligro),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colores.peligro),
          softWrap: true,
        ),
      ),
    ],
  );
}
