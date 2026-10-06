// El resaltado: una referencia, un estilo, y nada mas.
//
// ============================================================================
// POR QUE ESTO NO GUARDA EL TEXTO DEL VERSICULO
// ============================================================================
//
// Es la decision que condiciona todo lo demas, y la razon es la tercera de las cinco que
// `docs/investigacion-ux.md` atribuye a Accordance: el resaltado es **por referencia y no por
// version**. Se marca en una traduccion y aparece en todas.
//
// Y SI GUARDARA EL TEXTO, pasarian cuatro cosas, y las cuatro son fallos:
//
//   1. **No saldria en la otra traduccion.** Que es justo lo que se quiere de quien lee en dos
//      versiones y compara.
//   2. **Se quedaria viejo.** El KJV se vuelve a publicar; un texto guardado en el
//      dispositivo no se actualiza y la persona ve una frase que ya no es la que esta
//      leyendo, con el mismo numero de versiculo.
//   3. **Dos versiculos con el mismo texto serian indistinguibles.** "Y dijo Dios: Sea la luz"
//      aparece en Genesis 1:3 y en Juan 8:12, y al reimportar no se sabria cual es cual.
//   4. **Seria el dato de otra persona.** El texto es del modulo y de quien lo publico; lo
//      unico que es de la persona es **que** versiculo quiere marcar.
//
// Y LO QUE SE GUARDA ES LO MAS PEQUEÑO QUE PERMITE REHACERLO: libro, capitulo, versiculo y el
// estilo. Con eso, y con el modulo abierto, el resaltado se vuelve a pintar siempre.
//
// ============================================================================
// Y EL ESTILO ES UN **ESTILO**, NO UN COLOR
// ============================================================================
//
// Es lo que hace que "amarillo" no sea una etiqueta: un estilo tiene **nombre, color,
// intensidad y forma**, y los resaltados guardan cual, no el color.
//
// Y POR QUE: si dos personas --o la misma en dos instalaciones-- marcan lo mismo con dos
// colores distintos, al reexportar tiene que salir el color **que eligio quien marco**, no el
// que tiene ese estilo en la instalacion de al lado. Por eso el estilo viaja entero en la
// exportacion, con su nombre y su color.
//
// ============================================================================
// Y LAS INTENCIONES Y FORMAS SON TRES, NO UNA CONTINUA
// ============================================================================
//
// Suave, medio y fuerte. Y tres y no "un numero de 0 a 100 %" porque un control continuo
// produce estados que no sabe nombrar quien los ve: "¿esto es 60 o 70?". Y una intensacion que
// hay que adivinar es una intensacion que no se puede elegir. Que se pueda nombrar es lo que
// hace que se pueda **buscar por estilo** despues, que es la cuarta de las cinco cosas de
// Accordance.

import 'dart:convert';

/// Cuanto se marca. Tres, y con nombre, y no un numero.
enum IntensidadDelResaltado {
  suave('Suave', 0.30),
  medio('Medio', 0.50),
  fuerte('Fuerte', 0.72);

  const IntensidadDelResaltado(this.rotulo, this.opacidad);

  final String rotulo;

  /// La opacidad del fondo, de 0 a 1.
  ///
  /// Y **SUAVE NO ES 0.15**, que es lo que pareceria lo correcto: por debajo de 0,2 un fondo de
  /// color sobre el texto no se nota y la marca se pierde. Con 0,30 se ve sin estorbar, que es
  /// justo lo que pide el requisito de que "un resaltado que no deja leer es un resaltado que
  /// estorba".
  final double opacidad;
}

/// Como se marca.
enum FormaDelResaltado {
  /// Solo el fondo. Es lo mas habitual.
  fondo('Solo fondo'),

  /// Fondo y contorno. Para quien quiere el color y que se vea donde acaba.
  fondoYContorno('Fondo y contorno'),

  /// Solo el contorno. Para texto con muchas marcas de colores distintos.
  contorno('Solo contorno');

  const FormaDelResaltado(this.rotulo);

  final String rotulo;

  /// El nombre tal cual se guarda, y no [name] del enum.
  ///
  /// Y POR QUE NO EL [name]: Dart renombra los `enum` al compilar para minificar, y un nombre
  /// de enum **no es estable** entre compilaciones. Guardar `FormaDelResaltado.fondo.name` es
  /// guardar algo que en la siguiente build puede llamarse `x2`, y un resaltado de una persona
  /// que deja de leerse es un resaltado perdido.
  String get enElAlmacenamiento => switch (this) {
        FormaDelResaltado.fondo => 'fondo',
        FormaDelResaltado.fondoYContorno => 'fondo-contorno',
        FormaDelResaltado.contorno => 'contorno',
      };

  static FormaDelResaltado leer(String? bruto) => switch (bruto) {
        'fondo-contorno' => FormaDelResaltado.fondoYContorno,
        'contorno' => FormaDelResaltado.contorno,
        _ => FormaDelResaltado.fondo,
      };
}

/// El color de un estilo, como lo guarda la persona.
///
/// Y ES UN **ARGB** Y NO UN `enum` CON UNOS POCOS, porque el nombre lo pone ella y con cinco
/// colores fijos no hay nada que nombrar. Y el color se guarda en el estilo, no en el
/// resaltado: ver la nota de [EstiloDeResaltado].
class ColorDeResaltado {
  const ColorDeResaltado(this.argb);

  /// Los cinco de partida, que son los de los cuadernos de subrayar.
  ///
  /// Y ESTOS CINCO SON UN **PUNTO DE PARTIDA**, no un tope: la persona puede poner el que
  /// quiera. Lo que no puede es no poner ninguno, porque un resaltado sin color no se ve.
  static const List<ColorDeResaltado> dePartida = <ColorDeResaltado>[
    ColorDeResaltado(0xFFFFD54F), // amarillo
    ColorDeResaltado(0xFFA5D6A7), // verde
    ColorDeResaltado(0xFF90CAF9), // azul
    ColorDeResaltado(0xFFF48FB1), // rosa
    ColorDeResaltado(0xFFFFAB91), // naranja
  ];

  final int argb;

  /// Los tres canales, que es lo que se multiplica contra el fondo.
  double get r => ((argb >> 16) & 0xFF) / 255.0;
  double get g => ((argb >> 8) & 0xFF) / 255.0;
  double get b => (argb & 0xFF) / 255.0;

  String serializar() => argb.toRadixString(16).padLeft(8, '0');

  static ColorDeResaltado leer(Object? bruto) {
    if (bruto is int) return ColorDeResaltado(bruto);
    if (bruto is String) {
      final v = int.tryParse(bruto, radix: 16);
      if (v != null) return ColorDeResaltado(v);
    }
    // Y SI NO SE PUEDE LEER, EL AMARILLO, y no un color transparente. Un resaltado sin color
    // no se ve, y un resaltado que se ve en otra pinta es menos malo que uno que ha
    // desaparecido.
    return dePartida.first;
  }

  @override
  bool operator ==(Object other) =>
      other is ColorDeResaltado && other.argb == argb;

  @override
  int get hashCode => argb.hashCode;

  @override
  String toString() => '#${serializar()}';
}

/// Un estilo: un nombre que pone la persona y una manera de marcar.
///
/// Y EL NOMBRE **SE PUEDE CAMBIAR**, y por eso es un estilo y no un color con nombre pegado.
/// Un conjunto con "amarillo", "verde"... no dice para que se marca cada uno, y el nombre que
/// de verdad significa algo --"para la predicacion del domingo"-- solo lo puede poner quien
/// marca.
class EstiloDeResaltado {
  const EstiloDeResaltado({
    required this.id,
    required this.nombre,
    required this.color,
    this.intensidad = IntensidadDelResaltado.medio,
    this.forma = FormaDelResaltado.fondo,
  });

  /// Un identificador que no cambia aunque se cambie el nombre.
  ///
  /// Y POR QUE HAY DOS COSAS --el `id` y el `nombre`-- y no una. El `nombre` lo cambia la
  /// persona; si el resaltado guardara el nombre, cambiar el nombre de un estilo dejaria a
  /// todos sus resaltados apuntando a un nombre que ya no existe. Con el `id` el resaltado
  /// apunta al estilo y el estilo ha cambiado de nombre.
  final String id;

  final String nombre;
  final ColorDeResaltado color;
  final IntensidadDelResaltado intensidad;
  final FormaDelResaltado forma;

  EstiloDeResaltado copyWith({
    String? nombre,
    ColorDeResaltado? color,
    IntensidadDelResaltado? intensidad,
    FormaDelResaltado? forma,
  }) =>
      EstiloDeResaltado(
        id: id,
        nombre: nombre ?? this.nombre,
        color: color ?? this.color,
        intensidad: intensidad ?? this.intensidad,
        forma: forma ?? this.forma,
      );

  Map<String, Object?> aJson() => <String, Object?>{
        'id': id,
        'nombre': nombre,
        'color': color.serializar(),
        'intensidad': intensidad.name,
        'forma': forma.enElAlmacenamiento,
      };

  static EstiloDeResaltado desdeJson(Map<String, Object?> j) => EstiloDeResaltado(
        id: j['id'] as String? ?? 's1',
        nombre: j['nombre'] as String? ?? 'Sin nombre',
        color: ColorDeResaltado.leer(j['color']),
        intensidad: IntensidadDelResaltado.values.firstWhere(
          (IntensidadDelResaltado i) => i.name == j['intensidad'],
          orElse: () => IntensidadDelResaltado.medio,
        ),
        forma: FormaDelResaltado.leer(j['forma'] as String?),
      );

  @override
  String toString() => 'EstiloDeResaltado($id, "$nombre")';
}

/// Un resaltado: un versiculo y el estilo con el que esta marcado.
///
/// Y ES **INMUTABLE**, con lo que poner y quitar es cambiar la lista y no un objeto. Un
/// resaltado que se puede mutar en un sitio y no en otro es un resaltado que aparece en un
/// capitulo y no en otro.
class Resaltado {
  const Resaltado({
    required this.libro,
    required this.capitulo,
    required this.versiculo,
    required this.estilo,
  });

  final String libro;
  final int capitulo;
  final int versiculo;
  final String estilo;

  /// Si este resaltado es el de [otraReferencia].
  ///
  /// Y SE COMPARA **CAMPO A CAMPO** y no con el `==` de [Referencia], porque aqui no hay
  /// version: un resaltado no es de una traduccion. Que es justo lo que lo hace "por
  /// referencia y no por version".
  bool esElDe(String otroLibro, int otroCapitulo, int otroVersiculo) =>
      libro == otroLibro &&
      capitulo == otroCapitulo &&
      versiculo == otroVersiculo;

  /// La clave con la que se guarda: `John.3.16`.
  ///
  /// Y ES LA **MISMA** FORMA QUE LA URL, y no una madeja propia. Con una madeja propia, dos
  /// sitios que guardan la referencia de manera distinta producen dos conjuntos de
  /// resaltados que no se reconocen entre si, y el sintoma es "he marcado antes y no sale".
  String get clave => '$libro.$capitulo.$versiculo';

  Map<String, Object?> aJson() => <String, Object?>{
        'libro': libro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'estilo': estilo,
      };

  static Resaltado? desdeJson(Object? bruto) {
    if (bruto is! Map<String, Object?>) return null;
    final libro = bruto['libro'];
    final capitulo = bruto['capitulo'];
    final versiculo = bruto['versiculo'];
    final estilo = bruto['estilo'];
    if (libro is! String || capitulo is! int || versiculo is! int) return null;
    if (estilo is! String || estilo.isEmpty) return null;
    return Resaltado(
      libro: libro,
      capitulo: capitulo,
      versiculo: versiculo,
      estilo: estilo,
    );
  }

  @override
  String toString() => 'Resaltado($clave, $estilo)';
}

/// Los cinco estilos de partida.
///
/// Y EL `id` ES **`amarillo`**, que es el nombre, y no un numero. Un id numerico obliga a
/// guardar la lista de estilos en algun orden y a renumerar cuando se anade uno al principio,
/// y un resaltado guardado con el numero 1 pasa a ser del estilo que antes era el 2 sin que
/// nadie toque nada. Con un id que es el nombre, anadir un estilo no mueve los demas.
const List<EstiloDeResaltado> estilosDePartida = <EstiloDeResaltado>[
  EstiloDeResaltado(
    id: 'amarillo',
    nombre: 'Amarillo',
    color: ColorDeResaltado(0xFFFFD54F),
    intensidad: IntensidadDelResaltado.suave,
  ),
  EstiloDeResaltado(
    id: 'verde',
    nombre: 'Verde',
    color: ColorDeResaltado(0xFFA5D6A7),
    intensidad: IntensidadDelResaltado.suave,
  ),
  EstiloDeResaltado(
    id: 'azul',
    nombre: 'Azul',
    color: ColorDeResaltado(0xFF90CAF9),
    intensidad: IntensidadDelResaltado.suave,
  ),
  EstiloDeResaltado(
    id: 'rosa',
    nombre: 'Rosa',
    color: ColorDeResaltado(0xFFF48FB1),
    intensidad: IntensidadDelResaltado.suave,
  ),
  EstiloDeResaltado(
    id: 'naranja',
    nombre: 'Naranja',
    color: ColorDeResaltado(0xFFFFAB91),
    intensidad: IntensidadDelResaltado.suave,
  ),
];

/// Los cinco estilos que hay guardados.
///
/// Y LLEGAN **ENTEROS** dentro del fichero exportado, con nombre, color, intensidad y forma.
/// La razon esta en la nota de [ColorDeResaltado]: si el resaltado guardara el color, al
/// reimportar en una instalacion con los estilos cambiados los resaltados saldrian en un
/// color que la persona no eligio.
String exportarResaltados(
  List<Resaltado> resaltados,
  List<EstiloDeResaltado> estilos, {
  String version = '1',
}) {
  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'formato': 'ab-resaltados/1',
        'version': version,
        'generado': DateTime.now().toUtc().toIso8601String(),
        'estilos': estilos.map((EstiloDeResaltado e) => e.aJson()).toList(),
        'resaltados': resaltados.map((Resaltado r) => r.aJson()).toList(),
      });
}

/// El resultado de leer un fichero de resaltados.
///
/// Y **NO ES UNA EXCEPCION**, y es lo mismo que ya hace `ResultadoDeGuardar` con los modulos:
/// importar es la operacion que **escribe** lo de la persona, y una operacion que escribe con
/// un fichero equivocado es la peor forma de perderlo. Un `throw` obligaria a que quien llama
/// tenga el `try`, y el que se lo coma la excepcion es quien ha perdido el trabajo.
class ResultadoDeImportar {
  const ResultadoDeImportar({
    required this.resaltados,
    required this.estilos,
    this.motivo,
  });

  /// Lo que se ha leido, o una lista vacia si no se reconoce el fichero.
  final List<Resaltado> resaltados;
  final List<EstiloDeResaltado> estilos;

  /// Por que no se ha leido, en castellano, o null si se ha leido.
  final String? motivo;

  bool get ok => motivo == null;
}

/// Lee un fichero de resaltados.
///
/// Y DEVUELVE UN RESULTADO Y NO UN `throw`, y **no cambia nada por su cuenta**: quien llama
/// decide. Que esta funcion escriba ya en el almacenamiento seria lo que hace que importar
/// un fichero equivocado se lleve por delante lo que ya estaba.
ResultadoDeImportar leerResaltados(String? texto) {
  if (texto == null || texto.trim().isEmpty) {
    return const ResultadoDeImportar(
      resaltados: <Resaltado>[],
      estilos: <EstiloDeResaltado>[],
      motivo: 'El fichero esta vacio.',
    );
  }

  Object? decodificado;
  try {
    decodificado = jsonDecode(texto);
  } on FormatException {
    decodificado = null;
  }
  if (decodificado is! Map<String, Object?>) {
    return const ResultadoDeImportar(
      resaltados: <Resaltado>[],
      estilos: <EstiloDeResaltado>[],
      motivo: 'El fichero no es un JSON.',
    );
  }

  final formato = decodificado['formato'];
  if (formato is! String || !formato.startsWith('ab-resaltados/')) {
    // Y ESTE ES EL CASO IMPORTANTE, y el que hace que la funcion **mire el `formato`**. Un
    // `jsonDecode` de un fichero que es JSON pero de otra cosa --una lista de la compra, una
    // foto en base64-- **funciona**, y sin mirar el `formato` se importaria como si fueran
    // resaltados, cada uno con lo que saliera de los campos.
    return const ResultadoDeImportar(
      resaltados: <Resaltado>[],
      estilos: <EstiloDeResaltado>[],
      motivo: 'El fichero no es de resaltados de esta aplicacion.',
    );
  }

  final estilosRaw = decodificado['estilos'];
  final estilos = <EstiloDeResaltado>[];
  if (estilosRaw is List) {
    for (final e in estilosRaw) {
      if (e is Map<String, Object?>) estilos.add(EstiloDeResaltado.desdeJson(e));
    }
  }

  final resaltadosRaw = decodificado['resaltados'];
  final resaltados = <Resaltado>[];
  if (resaltadosRaw is List) {
    for (final r in resaltadosRaw) {
      final l = Resaltado.desdeJson(r);
      // Y UNO MALO SE SALTA Y NO SE IMPORTA A MEDIAS. Un `Resaltado` con el libro en null
      // seria un resaltado que no se puede pintar en ningun capitulo, y un fichero que se
      // traga eso no dice que se ha perdido nada.
      if (l != null) resaltados.add(l);
    }
  }

  // Y SI EL FICHERO NO TRAE ESTILOS, LOS DE PARTIDA, para que un resaltado cuyo estilo no
  // esta en la lista no se quede sin pintar. Un resaltado con un estilo que no existe **se
  // ve igual**, con el primero, y por eso esto no es un fallo.
  if (estilos.isEmpty) estilos.addAll(estilosDePartida);

  return ResultadoDeImportar(resaltados: resaltados, estilos: estilos);
}