// Lo que declara el catalogo.
//
// Un objeto y una lista. Sin logica, sin estado, sin mutable: es lo que se ha
// leido del manifiesto y ya.
//
// Lo que **no** hay aqui es ninguna idea de que Biblias existen. Este fichero
// no dice que el catalogo tenga dos modulos ni doscientos: dice "estos son los
// que se han declarado". Si el manifiesto llega vacio, esto es una lista vacia
// y la biblioteca avisa. No hay ningun texto de reserva.

import 'modulo.dart';

class Manifiesto {
  const Manifiesto({
    required this.formato,
    required this.version,
    required this.etiqueta,
    required this.modulos,
  });

  /// `aa-catalog/1`. Dice como interpretar el resto del fichero.
  final String formato;

  /// La version del catalogo: `v0.1.1`.
  final String version;

  /// La etiqueta del release. Puede no ser igual que `version` si el manifiesto
  /// se leyo de un sitio y la version de otro.
  final String etiqueta;

  final List<Modulo> modulos;

  bool get vacio => modulos.isEmpty;

  int get total => modulos.length;

  /// Busca un modulo por su identificador. Null si no esta.
  Modulo? porId(String id) {
    for (final m in modulos) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Los de un tipo: solo las Biblias, o solo los comentarios.
  List<Modulo> deTipo(TipoModulo t) => modulos.where((m) => m.tipo == t).toList();

  /// Los de un idioma, con el filtro de texto de la biblioteca aplicado.
  ///
  /// El filtro es aqui, en el dominio, y no en la View, por una razon concreta:
  /// la View pinta lo que le dan y no decide que se enseena. Una lista filtrada
  /// en un `build` se recalcula en cada fotograma.
  List<Modulo> filtrar({
    String? texto,
    String? idioma,
    bool soloDescargados = false,
    Set<String> descargados = const {},
  }) {
    final t = texto?.trim().toLowerCase() ?? '';
    return modulos.where((m) {
      if (t.isNotEmpty && !_coincide(m, t)) return false;
      if (idioma != null && idioma.isNotEmpty && m.idioma != idioma) return false;
      if (soloDescargados && !descargados.contains(m.id)) return false;
      return true;
    }).toList();
  }

  /// Busca por nombre, identificador, idioma y licencia a la vez.
  ///
  /// Que se pueda buscar por el idioma con solo escribir "esp" es lo que hace
  /// util el filtro cuando hay doscientos modulos, y es lo que hace STEPBible en
  /// su pantalla de instalacion.
  static bool _coincide(Modulo m, String t) =>
      m.nombre.toLowerCase().contains(t) ||
      m.id.toLowerCase().contains(t) ||
      m.idioma.toLowerCase().contains(t) ||
      m.licencia.toLowerCase().contains(t) ||
      m.tipo.enElCatalogo.contains(t);

  /// Idiomas que aparecen de verdad en el catalogo, ordenados.
  ///
  /// Se listan los que **hay**, no una lista fija de idiomas posibles: una lista
  /// fija seria exactamente el tipo de dato que no debe estar escrito en el
  /// codigo de la app.
  List<String> get idiomas {
    final vistos = <String>{for (final m in modulos) m.idioma};
    return vistos.toList()..sort();
  }
}
