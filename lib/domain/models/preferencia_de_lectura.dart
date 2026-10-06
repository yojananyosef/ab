// La preferencia de lectura: como se ve y como se lee el texto.
//
// ============================================================================
// POR QUE ESTA EN `domain` Y NO EN `ui`
// ============================================================================
//
// Es un **dato** con rangos y con un valor por defecto, y los dos tienen una regla que hay que
// poder comprobar sin montar una pantalla: un tamano de 4 px o un alto de linea de 9 son
// cosas que se pueden guardar si alguien manipula el almacenamiento, y la app tiene que
// saber acotarlos.
//
// Y EL PORQUE DE LOS VALORES POR DEFECTO, QUE ESTAN MEDIDOS Y NO ESCOGIDOS:
//
//   tamano de letra   18 px   El 16 px que habia aqui era el minimo de un **campo de texto**,
//                              por debajo del cual el navegador del movil hace zoom al
//                              enfocar y descuelga la pagina. El cuerpo del texto no tiene ese
//                              problema: no hay campo que enfocar. Y a 16 px, medido, Juan 3
//                              ocupa 16.848 pixeles a 360 de ancho.
//
//   alto de linea     1,6     El que estaba era 1,7, escrito en un `copyWith` del cuerpo de
//                              la vista, que es donde no se toca un valor que hay que poder
//                              cambiar. El rango llega a 2,5 porque hay quien lee con las
//                              lineas muy separadas.
//
//   espaciado         0,02 em Letras un poco mas separadas. En una columna estrecha el
//                              ojo pierde el hilo entre una y otra, y esto es lo que mas
//                              ayuda de los tres.
//
// Y DE DONDE VIENEN. De `aletheia-reader`, el otro repositorio del proyecto, donde estan
// medidos y con el motivo escrito. Se ha copiado **el criterio**, no el codigo: aqui el tema
// no tiene tipografia descargada, porque cada byte de tipografia son bytes de descarga en
// datos moviles.
//
// ============================================================================
// Y LA REGLA QUE MAS IMPORTANTE: UN CAMPO MALO NO TIRA LOS BUENOS
// ============================================================================
//
// El almacenamiento devuelve texto, y ese texto puede estar:
//   - vacio, si no se ha guardado nada
//   - con un JSON que no se puede leer, si se ha escrito a medias
//   - con un numero fuera de rango, si alguien lo ha editado
//   - con un campo que **no existe todavia**, si se ha anadido un ajuste nuevo
//
// El caso ultimo es el que mas ha roto cosas en este proyecto: al anadir un ajuste, la
// clave guardada de quien ya existed no lo tiene. Si eso se resuelve con "si no se puede
// leer, usa los de partida", el usuario pierde el tamaño de letra que si habia elegido. Asi
// que **campo a campo**: lo que se puede leer se respeta, lo que no, se sustituye.

import 'dart:convert';

/// El tema de fondo de la lectura.
enum TemaDeLectura {
  claro('claro'),
  sepia('sepia'),
  oscuro('oscuro');

  const TemaDeLectura(this.enElAlmacenamiento);

  /// El valor tal cual se escribe en el almacenamiento.
  ///
  /// Y NO ES EL [nombre] DEL ENUM, porque Dart renombra los `enum` al compilar para minificar
  /// y un `nombre` de enum **no es estable** entre compilaciones. Guardar `Theme.dark.name` en
  /// el almacenamiento es guardar algo que en la siguiente build puede ser `x2`.
  final String enElAlmacenamiento;

  /// Lee un valor guardado, o null si no es ninguno de los tres.
  ///
  /// Y DEVUELVE **NULL** Y NO "EL DE PARTIDA", porque quien llama tiene que poder distinguir
  /// "no estaba" de "estaba y era malo". Los dos acabarian en el mismo sitio, pero solo uno
  /// es un dato que se ha perdido.
  static TemaDeLectura? leer(String? bruto) {
    if (bruto == null) return null;
    for (final t in TemaDeLectura.values) {
      if (t.enElAlmacenamiento == bruto) return t;
    }
    return null;
  }
}

/// Los ajustes de lectura, con sus rangos.
///
/// Y ES **INMUTABLE** Y SE CAMBIA CON `copyWith`, porque la preferencia se pasa a varias
/// capas --el tema, la vista de lectura, el atenuador-- y un `setProperty` sobre un objeto
/// compartido haria que un cambio del atenuador repintara el texto.
class PreferenciaDeLectura {
  const PreferenciaDeLectura({
    this.tamanoDeLetra = tamanoDeLetraPorDefecto,
    this.altoDeLinea = altoDeLineaPorDefecto,
    this.espaciado = espaciadoPorDefecto,
    this.tema = TemaDeLectura.claro,
    this.atenuacion = atenuacionPorDefecto,
    this.lineaEnfocada = 0,
  });

  /// El tamano de letra, en puntos logicos, de [tamanoMinimo] a [tamanoMaximo].
  final double tamanoDeLetra;

  /// El alto de linea, multiplicador, de [altoDeLineaMinimo] a [altoDeLineaMaximo].
  final double altoDeLinea;

  /// El espaciado entre letras, en `em`, de 0 a [espaciadoMaximo].
  final double espaciado;

  final TemaDeLectura tema;

  /// La atenuacion, de [atenuacionMinima] a 1. Un 1 es "sin atenuar".
  final double atenuacion;

  /// Cuantas lineas abarca la apertura de la linea enfocada: 0 apagada, 1, 3 o 5.
  ///
  /// Y SOLO 0, 1, 3 Y 5, y no un numero libre. Una apertura de dos lineas no tiene sentido
  /// --la de dos lineas esta a caballo entre "una" y "tres" y no se lee ni de una forma ni
  /// de la otra-- y un numero libre habria que acotarlo en el guardado y en el boton.
  final int lineaEnfocada;

  // --- los rangos, en un sitio, y son parte del contrato ---

  static const double tamanoMinimo = 15;
  static const double tamanoMaximo = 26;
  static const double tamanoDeLetraPorDefecto = 18;

  static const double altoDeLineaMinimo = 1.2;
  static const double altoDeLineaMaximo = 2.5;
  static const double altoDeLineaPorDefecto = 1.6;

  static const double espaciadoMinimo = 0;
  static const double espaciadoMaximo = 0.1;
  static const double espaciadoPorDefecto = 0.02;

  static const double atenuacionMinima = 0.4;
  static const double atenuacionPorDefecto = 1;

  // --- la clave, y por que una sola ---

  /// La clave del almacenamiento.
  static const String clave = 'lectura';

  /// Los campos, en el texto guardado. Estan escritos **a mano** y no se usan como nombre.
  static const String _cTamano = 't';
  static const String _cAlto = 'a';
  static const String _cEspaciado = 'e';
  static const String _cTema = 'f';
  static const String _cAtenuacion = 'n';
  static const String _cLinea = 'l';

  /// Los ajustes recomendados.
  ///
  /// Y SON **LOS MISMOS** QUE [PreferenciaDeLectura] sin argumentos. Si se separaran, "restaurar
  /// valores" y "abrir por primera vez" darian dos cosas distintas y solo se notaria en quien
  /// restaurase sin haber tocado nada.
  static const PreferenciaDeLectura porDefecto = PreferenciaDeLectura();

  // --- acotar, que es donde se decide que se hace con lo que viene de fuera ---

  /// Acota un numero al rango. Un `null` es el valor por defecto.
  ///
  /// Y SE ACOTA Y NO SE **DESCARTA**, y la diferencia es lo que se ve: si alguien tiene el
  /// tamano en 20 y el alto de linea guardado como 0 --porque el JSON se escribio a medias--,
  /// descartar le deja los dos en los recomendados y perder el 20. Acotandole el alto a 1,2
  /// conserva el tamano.
  static double _acotar(double? valor, double min, double max, double porDefecto) {
    if (valor == null || valor.isNaN) return porDefecto;
    if (valor < min) return min;
    if (valor > max) return max;
    return valor;
  }

  /// Los valores de la linea enfocada que existen.
  static const List<int> lineasEnfocadas = <int>[0, 1, 3, 5];

  static int _acotarLinea(Object? valor) {
    if (valor is int && lineasEnfocadas.contains(valor)) return valor;
    return 0;
  }

  // --- guardar y leer ---

  /// Como se escribe en el almacenamiento.
  ///
  /// Y **TODOS LOS CAMPOS**, no solo los que han cambiado. Una preferencia guardada es una
  /// foto del ajuste completo, y guardarla entera hace que un campo que se lee mal se pueda
  /// arreglar volviendo a guardar.
  String serializar() => jsonEncode(<String, Object?>{
        _cTamano: tamanoDeLetra,
        _cAlto: altoDeLinea,
        _cEspaciado: espaciado,
        _cTema: tema.enElAlmacenamiento,
        _cAtenuacion: atenuacion,
        _cLinea: lineaEnfocada,
      });

  /// Lee un texto guardado. Un texto que no se puede leer da los valores recomendados.
  ///
  /// Y [leer] NO es [deserializar] con una excepcion: aqui **nunca** hay excepcion. Quien
  /// llama esta linea sobre un `localStorage` que no contesta, y un `throw` en un `await` de
  /// arranque cuelga la pantalla entera.
  static PreferenciaDeLectura deserializar(String? bruto) {
    if (bruto == null || bruto.isEmpty) return porDefecto;

    Map<String, Object?>? datos;
    try {
      final decodificado = jsonDecode(bruto);
      if (decodificado is Map<String, Object?>) datos = decodificado;
    } on FormatException {
      // No es JSON. Se usan los recomendados.
      datos = null;
    }
    if (datos == null) return porDefecto;

    return PreferenciaDeLectura(
      tamanoDeLetra: _acotar(
        _numero(datos[_cTamano]),
        tamanoMinimo,
        tamanoMaximo,
        tamanoDeLetraPorDefecto,
      ),
      altoDeLinea: _acotar(
        _numero(datos[_cAlto]),
        altoDeLineaMinimo,
        altoDeLineaMaximo,
        altoDeLineaPorDefecto,
      ),
      espaciado: _acotar(
        _numero(datos[_cEspaciado]),
        espaciadoMinimo,
        espaciadoMaximo,
        espaciadoPorDefecto,
      ),
      tema: TemaDeLectura.leer(datos[_cTema] as String?) ?? TemaDeLectura.claro,
      atenuacion: _acotar(
        _numero(datos[_cAtenuacion]),
        atenuacionMinima,
        1,
        atenuacionPorDefecto,
      ),
      lineaEnfocada: _acotarLinea(datos[_cLinea]),
    );
  }

  /// Un numero o null, y null si lo que hay no es un numero.
  ///
  /// Y NO HACE `double.tryParse` DE SU CADENA, porque `jsonDecode` **ya devuelve numero** para
  /// `20.5` y devuelve `String` para `"20.5"`. Un guardado a mano con `"20.5"` entre comillas
  /// se rechaza, y es lo correcto: un ajuste escrito como texto en un JSON es un dato que
  /// nadie ha escrito a proposito.
  static double? _numero(Object? valor) => valor is num ? valor.toDouble() : null;

  // --- cambiar ---

  PreferenciaDeLectura cambiarTamano(double v) => copyWith(
        tamanoDeLetra: _acotar(v, tamanoMinimo, tamanoMaximo, tamanoDeLetra),
      );

  PreferenciaDeLectura cambiarAltoDeLinea(double v) => copyWith(
        altoDeLinea: _acotar(v, altoDeLineaMinimo, altoDeLineaMaximo, altoDeLinea),
      );

  PreferenciaDeLectura cambiarEspaciado(double v) => copyWith(
        espaciado: _acotar(v, espaciadoMinimo, espaciadoMaximo, espaciado),
      );

  PreferenciaDeLectura cambiarTema(TemaDeLectura v) => copyWith(tema: v);

  PreferenciaDeLectura cambiarAtenuacion(double v) => copyWith(
        atenuacion: _acotar(v, atenuacionMinima, 1, atenuacion),
      );

  PreferenciaDeLectura cambiarLineaEnfocada(int v) =>
      copyWith(lineaEnfocada: _acotarLinea(v));

  /// A los recomendados. Lo que toca el boton de "restaurar".
  ///
  /// Y DEVUELVE [porDefecto] Y NO RECONSTRUYE LOS CAMPOS UNO A UNO, porque
  /// [porDefecto] **es** la forma de tener los recomendados. Si se escribieran aqui los
  /// numeros, habria dos listas de recomendados y se separarian el dia que se cambie uno.
  PreferenciaDeLectura restaurar() => porDefecto;

  PreferenciaDeLectura copyWith({
    double? tamanoDeLetra,
    double? altoDeLinea,
    double? espaciado,
    TemaDeLectura? tema,
    double? atenuacion,
    int? lineaEnfocada,
  }) =>
      PreferenciaDeLectura(
        tamanoDeLetra: tamanoDeLetra ?? this.tamanoDeLetra,
        altoDeLinea: altoDeLinea ?? this.altoDeLinea,
        espaciado: espaciado ?? this.espaciado,
        tema: tema ?? this.tema,
        atenuacion: atenuacion ?? this.atenuacion,
        lineaEnfocada: lineaEnfocada ?? this.lineaEnfocada,
      );

  @override
  String toString() => 'PreferenciaDeLectura(tamano: $tamanoDeLetra, '
      'alto: $altoDeLinea, espaciado: $espaciado, tema: ${tema.name}, '
      'atenuacion: $atenuacion, lineaEnfocada: $lineaEnfocada)';
}