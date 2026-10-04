// Los terminos de un modulo, y las reglas que hay que cumplir al ensenarlos.
//
// ESTO NO ES UN ADORNO. Es una **obligacion de la licencia**, y el repositorio
// hermano ya decidio que cada `.amod` declare en su tabla `info` su `copyright`, su
// `attribution`, su `license`, su `license_evidence`, sus `defects` y su
// `content_hash`. Los declara porque la app tiene que ensenarlos, y si no, el
// trabajo de declararlos no sirve de nada.
//
// Y AQUI ESTA LA RAZON DE QUE SEAN UNA CLASE Y NO SEIS `String`. Porque tienen
// **reglas**, y las reglas se pueden comprobar:
//
//  1. Se ensenan **sin abrir ningun menu**. No en un "acerca de" al que hay que
//     llegar. YouVersion los pone junto al pasaje porque la atribucion es una
//     obligacion, y un boton que hay que buscar convierte una obligacion en una
//     opcion.
//  2. Cuando el manifiesto y el modulo **discrepan**, gana el **modulo**. El manifiesto
//     es un puntero; el modulo es el texto que se esta leyendo. Y se dice que
//     discrepan, con los dos valores.
//  3. Si `defects_count` es mayor que cero, se avisa **de cuantos** versiculos vienen
//     incompletos. Un lector que no lo dice esta ensenando texto incompleto sin
//     avisar, y quien lo esta leyendo no tiene forma de saberlo.
//
// LA REGLA 3 TIENE UN CASO REAL Y NO ES TEORICO. Una traduccion puede llegar sin
// algunos versiculos. El KJV de `aa` declara cero, y por eso el caso de un modulo
// con defecto necesita otro modulo; la prueba lo construye a proposito, con un
// `defects_count` de 3, y comprueba que se avisa de **tres** y no de "hay problemas".

import 'package:ab/domain/models/modulo.dart';

/// Los terminos de un modulo, tal como los declara su tabla `info`.
class Terminos {
  const Terminos({
    required this.id,
    required this.nombre,
    required this.licencia,
    required this.licenciaEvidencia,
    required this.copyright,
    required this.atribucion,
    required this.defectos,
    required this.numeroDeDefectos,
    required this.versificacion,
    required this.contentHash,
    required this.esquema,
  });

  /// Lee los terminos de un modulo abierto.
  ///
  /// Todo lo que falta se queda como cadena **vacia**, nunca como null. Un `null` en
  /// un campo de terminos obliga a cada sitio que lo pinta a mirar, y uno se olvidara
  /// una vez. Una cadena vacia se pinta como lo que es --que el modulo no lo
  /// declara-- y se dice explicitamente en vez de dejar un hueco.
  /// [leerTexto] y [leerEntero] van separados porque el modulo los tiene separados.
  ///
  /// Y van separados tambien por el motivo de siempre: si `infoEntero` devolviera
  /// texto, un `defects_count` de "tres" no tendria que ser cero en silencio.
  factory Terminos.desdeModulo(
    String? Function(String clave) leerTexto,
    int? Function(String clave) leerEntero,
  ) {
    int? entero(String clave) => leerEntero(clave);

    return Terminos(
      id: leerTexto('id') ?? '',
      nombre: leerTexto('name') ?? '',
      licencia: leerTexto('license') ?? '',
      licenciaEvidencia: leerTexto('license_evidence') ?? '',
      copyright: leerTexto('copyright') ?? '',
      atribucion: leerTexto('attribution') ?? '',
      defectos: leerTexto('defects') ?? '',
      numeroDeDefectos: entero('defects_count') ?? 0,
      versificacion: leerTexto('versification') ?? '',
      contentHash: leerTexto('content_hash') ?? '',
      esquema: entero('schema_version') ?? 0,
    );
  }

  final String id;
  final String nombre;
  final String licencia;
  final String licenciaEvidencia;
  final String copyright;

  /// Quien hay que nombrar. Es lo unico que **no** se puede resumir.
  final String atribucion;

  final String defectos;

  /// Cuantos versiculos vienen incompletos. 0 significa que el modulo dice que
  /// ninguno.
  final int numeroDeDefectos;

  final String versificacion;
  final String contentHash;
  final int esquema;

  /// Si el modulo declara que le faltan versiculos.
  bool get tieneDefectos => numeroDeDefectos > 0;

  /// Si se puede usar tal cual, sin más que la atribucion.
  ///
  /// Se calcula con lo que **declara el modulo**, no con lo que declara el
  /// manifiesto, porque quien publica es el modulo.
  bool get esDeDominioPublico => licencia.toUpperCase() == 'PUBLICDOMAIN';

  /// Los terminos tal como se ensenan, en el orden en que se muestran.
  ///
  /// El orden es el de la ficha de la app, y es el que va primero el nombre, luego la
  /// licencia, luego la evidencia, luego la atribucion y el copyright. El nombre va
  /// primero porque es lo que responde "¿que estoy leyendo?", y la licencia es lo
  /// que responde "¿puedo usarlo?", que es la segunda pregunta.
  List<TerminoVisible> get visibles => <TerminoVisible>[
        if (nombre.isNotEmpty) TerminoVisible('Texto', nombre),
        if (licencia.isNotEmpty) TerminoVisible('Licencia', _licenciaLegible()),
        if (licenciaEvidencia.isNotEmpty)
          TerminoVisible('Evidencia de dominio publico', licenciaEvidencia),
        if (atribucion.isNotEmpty) TerminoVisible('Atribucion', atribucion),
        if (copyright.isNotEmpty) TerminoVisible('Copyright', copyright),
        if (versificacion.isNotEmpty)
          TerminoVisible('Versificacion', _versificacionLegible()),
      ];

  /// La licencia como la entiende la gente.
  ///
  /// Traducir **solo** `PublicDomain`, y solo cuando es exactamente eso. Cualquier
  /// otra licencia se deja tal cual: los nombres oficiales de las Creative Commons se
  /// escriben en ingles, y traducirlos seria inventar una licencia que no es la que
  /// declara el modulo.
  String _licenciaLegible() => esDeDominioPublico ? 'dominio publico' : licencia;

  /// La versificacion con su nombre, que es lo que la gente entiende.
  ///
  /// El KJV real declara `KJV` y nadie sabe lo que es eso. "KJV (1569)" quiere decir
  /// algo para quien ha leido una Biblia en ingles, y es el nombre de esa
  /// versificacion. Se ensena **tal cual** entre parentesis, porque es el dato que hay:
  /// si el modulo no dice el ano, no se inventa.
  String _versificacionLegible() => switch (versificacion) {
        'KJV' => 'KJV, la de 1569',
        'US' => 'versificacion estadounidense',
        'TR' => 'versificacion tradicional',
        _ => versificacion,
      };

  /// El aviso de defectos, o null si no hay.
  ///
  /// El numero va en el texto y no solo el icono: "3 versiculos incompletos" permite
  /// decidir, y un triángulo amarillo no.
  String? get avisoDeDefectos {
    if (!tieneDefectos) return null;
    final plural = numeroDeDefectos == 1;
    final base = plural
        ? 'Este texto tiene 1 versiculo incompleto.'
        : 'Este texto tiene $numeroDeDefectos versiculos incompletos.';
    if (defectos.trim().isEmpty) return '$base La fuente no explica cuales.';
    return '$base La fuente dice: $defectos';
  }
}

/// Un termino y su etiqueta, para pintar.
class TerminoVisible {
  const TerminoVisible(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;
}

/// Un termino tal como lo declara un modulo, comparado con el del manifiesto.
class DiscrepanciaDeLicencia {
  const DiscrepanciaDeLicencia({required this.delManifiesto, required this.delModulo});

  /// Lo que dice `catalog.json`.
  final String delManifiesto;

  /// Lo que dice la tabla `info` del modulo.
  final String delModulo;

  /// Si hay discrepancia de verdad. Case y espacios no cuentan.
  bool get hay => _normaliza(delManifiesto) != _normaliza(delModulo);

  /// El texto que se ensena.
  ///
  /// GANA EL MODULO, y se dice por que. El manifiesto es un indice: puede estar
  /// equivocado, o desfasado, o describiendo otra cosa. El modulo es el texto que se
  /// esta leyendo, y el que va a citar quien cite. Si el manifiesto dice
  /// `PublicDomain` y el modulo dice `CC-BY-NC`, lo que se esta leyendo es
  /// `CC-BY-NC`, y decir otra cosa seria falso.
  String get texto => 'El indice dice "$delManifiesto" y el texto dice "$delModulo". '
      'Manda el texto, que es lo que se esta leyendo.';

  /// Lo mismo para la atribucion, que tambien puede discrepanar.
  static String avisoDeAtribucion({required String? delManifiesto, required String delModulo}) {
    if (delManifiesto == null || delManifiesto.trim().isEmpty) return '';
    if (_normaliza(delManifiesto) == _normaliza(delModulo)) return '';
    return 'El indice nombra "$delManifiesto" y el texto nombra "$delModulo". '
        'Manda el texto, que es lo que se esta leyendo.';
  }

  static String _normaliza(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Compara la licencia del manifiesto con la del modulo.
///
/// Devuelve null si no discrepan, y la discrepancia si discrepan. Null en vez de un
/// `bool` porque lo que se pinta es el texto, y tener que construirlo en la pantalla
/// es un sitio mas donde se puede olvidar.
DiscrepanciaDeLicencia? compararLicencias({
  required String delManifiesto,
  required String delModulo,
}) {
  final d = DiscrepanciaDeLicencia(delManifiesto: delManifiesto, delModulo: delModulo);
  return d.hay ? d : null;
}

/// La licencia de un modulo del manifiesto, para compararla.
///
/// Va aqui y no en la vista porque comparar es una regla, y la regla no depende de
/// donde se pinte.
String licenciaDeModulo(Modulo m) => m.licencia;
