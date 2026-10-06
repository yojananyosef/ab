// El tema y las medidas de la app.
//
// ============================================================================
// LO QUE HAY AQUI Y POR QUE NO HAY MAS
// ============================================================================
//
// Un tema, tres paletas y cuatro medidas. Nada de un sistema de estilos propio, ni de un
// paquete de diseno, ni de tipografias descargadas. La razon es concreta y no es purismo:
//
// 1. La app tiene **cuatro** pantallas. Un sistema de estilos para cuatro pantallas es mas
//    codigo que las pantallas.
// 2. Cada byte de tipografia son bytes de descarga, y esta app se usa con datos moviles: cada
//    KB cuenta.
// 3. Lo que hay que comprobar es que no revienta a 360 px, y eso lo comprueban pruebas de
//    widget con medidas reales, no un `DesignSystem`.
//
// ============================================================================
// Y POR QUE HAY TRES PALETAS Y NO UNA CON UN INTERRUPTOR
// ============================================================================
//
// Medido: Juan 3 son 16.848 pixeles a 360 px de ancho. Quien lee eso de pie en el metro y
// quien lo lee en la cama a las doce de la noche tienen **problemas distintos**, y no se
// resuelven con un interruptor de claro y oscuro:
//
//   - el sepia lo pide quien lee Bibias en papel y quiere lo de papel
//   - el oscuro es lo unico legible en la cama, porque un fondo claro a las doce de la noche
//     **duele** despues de un rato
//   - el claro es el que habia, y se deja como estaba: cambiarlo por gusto no es un cambio
//
// ============================================================================
// Y LOS COLORES NO SE ELIGEN A OJOS: ESTAN MEDIDOS
// ============================================================================
//
// Medido el 5 de octubre de 2026 con el algoritmo de WCAG --canales lineales, exponente
// 2,4, y la razon `(L1 + 0,05) / (L2 + 0,05)`-- y en
// `test/ui/contraste_de_los_temas_test.dart` hay una comprobacion **viva** de las nueve
// combinaciones de cada tema:
//
//                          claro    sepia   oscuro
//     texto sobre fondo  16,96    11,81    15,17     minimo 7:1
//     texto suave         7,14     5,62     8,01     minimo 4,5:1
//     palabras de Jesus   7,33     7,15     8,23     minimo 7:1
//     acento              7,12     7,49    10,96     minimo 4,5:1
//     peligro             7,19     6,84     7,25     minimo 4,5:1
//     primario            7,19     7,78     9,60     minimo 4,5:1
//
// Y LOS UMBRALES NO SON TODOS IGUALES, y esa es la decision:
//
//   - el **rojo de las palabras de Jesus** es **texto de cuerpo**, no un adorno, con lo que
//     le toca el umbral de **7:1** y no el de 4,5. Un rojo claro de letras rojas se lee como
//     texto deshabilitado y no como Escritura
//   - el **texto suave** --el nombre del libro, las migas-- es informacion secundaria, y le
//     basta el de 4,5:1
//   - el **texto corriente** es el que mas se lee, y de sobra pasa el de 7:1 en los tres
//
// ============================================================================
// Y POR QUE EL ROJO CAMBIA EN EL OSCURO
// ============================================================================
//
// El mismo rojo sobre fondo oscuro no se ve. En el oscuro el rojo de las palabras de Jesus es
// `#F0928A`, un rojo claro, y da **8,23:1**. Y no es un rojo distinto porque si: es el mismo
// texto de cuerpo, en el color que se lee sobre ese fondo. Un color que solo funciona en un
// tema es un color que en los otros dos no se lee.
//
// Y el rojo de las palabras de Jesus **no es** el `peligro` con otro nombre. Si las dos cosas
// fueran del mismo color, un dia el aviso de error pasaria a ser del color de la Palabra de
// Cristo y nadie sabria que paso. Cada color dice una cosa.
//
// ============================================================================
// Y LOS COLORES SON DEL TEMA, NO CONSTANTES
// ============================================================================
//
// Antes `Colores.fondo` era una constante estatica y se usaba en 83 sitios. Con tres temas eso
// **no puede ser**: una constante no sabe que tema hay. Asi que los colores viajan en el
// `ThemeData` --como un `ThemeExtension`, que es lo que Material ha puesto para esto-- y se
// leen con:
//
//     context.colores.fondo
//
// Y NO CON `Theme.of(context).colorScheme.primary`, porque esa entrada del `ColorScheme` la
// elige Material a partir de un color semilla y **no es el color que eligen estos numeros**.
// Un `primary` que sale de `fromSeed` de un marron da un morado, y ningun morado esta medido.
//
// Y POR QUE UN `ThemeExtension` Y NO UN `InheritedWidget` PROPIO: el extension va **dentro** del
// `ThemeData`, con lo que `Theme.of(context)` lo trae y no hay un widget mas en el arbol. Y va
// con un `lerp`, porque `ThemeData` lo exige al animar entre temas.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';

/// Los colores de un tema.
///
/// Y NO ES UN `ColorScheme` DE MATERIAL, sino una clase con los nueve colores que esta
/// aplicacion usa de verdad. `ColorScheme` tiene cuarenta entradas y esta app necesita
/// nueve: los que no estan aqui no se pintan, y un `ColorScheme` al que se le anaden colores
/// que no se usan es una lista de cosas que se pueden quedar viejas sin que se note.
@immutable
class Colores extends ThemeExtension<Colores> {
  const Colores({
    required this.fondo,
    required this.superficie,
    required this.texto,
    required this.textoSuave,
    required this.linea,
    required this.primario,
    required this.peligro,
    required this.acento,
    required this.palabraDeJesus,
  });

  /// El claro, que es el que habia. Sus numeros estan medidos y coinciden con los que ya
  /// estaban escritos en `AGENTS.md`: 16,96:1 el texto y 7,33:1 el rojo de las palabras de
  /// Jesus.
  static const Colores claro = Colores(
    fondo: Color(0xFFFBF9F4),
    superficie: Color(0xFFFFFFFF),
    texto: Color(0xFF1A1714),
    textoSuave: Color(0xFF59544C),
    linea: Color(0xFFE2DCD2),
    primario: Color(0xFF6B4F2A),
    peligro: Color(0xFF9B2C22),
    acento: Color(0xFF2F5D50),
    palabraDeJesus: Color(0xFF992B22),
  );

  /// El sepia, que es lo de papel. Y NO ES EL CLARO CON UN TONO: los tres textos se
  /// oscurecen y el rojo se oscurece **y** se aviva, porque sobre crema un rojo de papel
  /// quemado se apaga.
  static const Colores sepia = Colores(
    fondo: Color(0xFFF3E9D2),
    superficie: Color(0xFFFBF3E0),
    texto: Color(0xFF33291A),
    textoSuave: Color(0xFF6B5840),
    linea: Color(0xFFDCC9A6),
    primario: Color(0xFF5A4220),
    peligro: Color(0xFF8C2F20),
    acento: Color(0xFF24513F),
    palabraDeJesus: Color(0xFF8F2418),
  );

  /// El oscuro, para leer en la cama.
  ///
  /// Y NO ES EL CLARO INVERTIDO. Lo invertido invierte los significantes sin mirar los
  /// contrastes y da un rojo de palabras de Jesus que no se ve. Este tiene los tres textos
  /// medidos y el rojo **claro**.
  static const Colores oscuro = Colores(
    fondo: Color(0xFF14110E),
    superficie: Color(0xFF1E1A16),
    texto: Color(0xFFEDE6DA),
    textoSuave: Color(0xFFB3A894),
    linea: Color(0xFF3A332B),
    primario: Color(0xFFD8B478),
    peligro: Color(0xFFE08A7C),
    acento: Color(0xFF8FD3BE),
    palabraDeJesus: Color(0xFFF0928A),
  );

  /// Los colores de un tema de lectura.
  ///
  /// Y ES UN `switch` Y NO UN MAPA, porque un mapa admite una clave que no esta --la clave que
  /// no-- y devuelve null, y quien lo use tiene que tratar un null que solo aparece en
  /// desarrollo. Un `switch` con el enum entero no compila si falta un caso.
  static Colores de(TemaDeLectura tema) => switch (tema) {
        TemaDeLectura.claro => Colores.claro,
        TemaDeLectura.sepia => Colores.sepia,
        TemaDeLectura.oscuro => Colores.oscuro,
      };

  /// Fondo de la pantalla.
  final Color fondo;

  /// Fondo de las tarjetas y de los campos.
  final Color superficie;

  /// Texto principal.
  final Color texto;

  /// Texto secundario: el nombre del libro, las migas, las ayudas.
  final Color textoSuave;

  /// Las lineas y los bordes.
  final Color linea;

  /// El color de los botones y de los enlaces.
  final Color primario;

  /// Rojo de aviso, y tambien de error. **Distinto** de [palabraDeJesus].
  final Color peligro;

  /// El color de acento: la marca del versiculo pedido y los enlaces al lexicon.
  final Color acento;

  /// Lo que dijo Jesus, en rojo. Texto de cuerpo: le toca el umbral de 7:1.
  final Color palabraDeJesus;

  /// Si el tema es de fondo oscuro.
  ///
  /// Y SE CALCULA DE LA LUMINANCIA Y NO SE GUARDA COMO UN BANDERA, porque una bandera y un
  /// color se separan: se cambia el color de una paleta y se olvida la bandera, y el tema se
  /// queda con los colores del claro y el brillo del oscuro.
  bool get esOscuro => fondo.computeLuminance() < 0.5;

  @override
  Colores copyWith({
    Color? fondo,
    Color? superficie,
    Color? texto,
    Color? textoSuave,
    Color? linea,
    Color? primario,
    Color? peligro,
    Color? acento,
    Color? palabraDeJesus,
  }) =>
      Colores(
        fondo: fondo ?? this.fondo,
        superficie: superficie ?? this.superficie,
        texto: texto ?? this.texto,
        textoSuave: textoSuave ?? this.textoSuave,
        linea: linea ?? this.linea,
        primario: primario ?? this.primario,
        peligro: peligro ?? this.peligro,
        acento: acento ?? this.acento,
        palabraDeJesus: palabraDeJesus ?? this.palabraDeJesus,
      );

  @override
  Colores lerp(Colores? otra, double t) {
    if (otra == null) return this;
    return Colores(
      fondo: Color.lerp(fondo, otra.fondo, t)!,
      superficie: Color.lerp(superficie, otra.superficie, t)!,
      texto: Color.lerp(texto, otra.texto, t)!,
      textoSuave: Color.lerp(textoSuave, otra.textoSuave, t)!,
      linea: Color.lerp(linea, otra.linea, t)!,
      primario: Color.lerp(primario, otra.primario, t)!,
      peligro: Color.lerp(peligro, otra.peligro, t)!,
      acento: Color.lerp(acento, otra.acento, t)!,
      palabraDeJesus: Color.lerp(palabraDeJesus, otra.palabraDeJesus, t)!,
    );
  }
}

/// Los colores del tema que hay en este `context`.
extension ColoresDeContexto on BuildContext {
  /// Los colores de la paleta activa.
  ///
  /// Y CON `!`, y no con un valor por defecto. Si aqui no hay tema --un widget medido fuera de
  /// un `MaterialApp`, o el `MaterialApp` sin la extension-- un `?? Colores.claro` devolveria el
  /// tema claro en pantalla y **no se diria nada**, que es la forma de tener un color que no es
  /// el que toca sin enterarse. Con el `!` revienta en el primer uso y dice de donde.
  Colores get colores => Theme.of(this).extension<Colores>()!;

  /// Si el tema activo es de fondo oscuro.
  bool get temaOscuro => colores.esOscuro;
}

/// El tema de la app, para la preferencia dada.
///
/// Y RECIBE LA PREFERENCIA Y NO LA BUSCA, porque un tema que va a buscar la preferencia por su
/// cuenta es un tema que depende del orden de construccion, y el orden de construccion es
/// justo lo que cambia cuando algo se lee con plazo desde `main`.
ThemeData temaDeAb([PreferenciaDeLectura? preferencia]) {
  final pref = preferencia ?? PreferenciaDeLectura.porDefecto;
  final c = Colores.de(pref.tema);

  final base = ThemeData(
    useMaterial3: true,
    brightness: c.esOscuro ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primario,
      brightness: c.esOscuro ? Brightness.dark : Brightness.light,
      surface: c.superficie,
      onSurface: c.texto,
    ),
  );

  return base.copyWith(
    // Y LA PALETA VA DENTRO DEL TEMA, que es lo que hace que `context.colores` la encuentre
    // sin ningun widget de por medio.
    extensions: <Colores>[c],
    scaffoldBackgroundColor: c.fondo,
    // Y 16 px, y no 14: por debajo de 16 el navegador del movil hace zoom al enfocar un
    // campo y descuelga la pagina. Y ESTE 16 ES FIJO Y NO VIENE DE LA PREFERENCIA, y esa es
    // la distincion que hay que tener clara: el 16 de los **campos** lo impone el navegador,
    // y el del **texto de lectura** lo elige quien lee. Si tambien el campo bajara a 15 con
    // la preferencia, escribir en el filtro haria que la pagina se descuelgue.
    textTheme: base.textTheme.apply(
      bodyColor: c.texto,
      displayColor: c.texto,
    ).copyWith(
      bodyMedium: const TextStyle(fontSize: 16, height: 1.45),
      bodyLarge: const TextStyle(fontSize: 17, height: 1.45),
      bodySmall: TextStyle(fontSize: 14, height: 1.4, color: c.textoSuave),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 13, color: c.textoSuave),
    ),
    dividerTheme: DividerThemeData(color: c.linea, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.primario, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: BorderSide(color: c.linea),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(fontSize: 15),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.texto,
      contentTextStyle: TextStyle(fontSize: 15, color: c.superficie),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// El estilo del texto de lectura, con la preferencia puesta.
///
/// Y ESTA EN UN SITIO Y NO SE ESCRIBE EN LA VISTA, porque el mismo texto se pinta en la
/// pantalla de lectura y en la de busqueda, y si cada una comparta su `TextStyle` con el
/// tamano puesto a mano, el dia que se cambie el valor por defecto una de las dos se queda con
/// el viejo.
///
/// Y LLEVA [Colores.texto] PUESTO, y no lo deja al tema, porque el texto de lectura lleva
/// tambien el tamano y el alto de linea: si se lleva un estilo propio, tiene que llevarse el
/// color, o el texto saldria en el color que el tema imponga por su cuenta.
TextStyle estiloDeLectura(TextTheme tema, PreferenciaDeLectura pref) {
  return tema.bodyMedium!.copyWith(
    fontSize: pref.tamanoDeLetra,
    height: pref.altoDeLinea,
    letterSpacing: pref.espaciado,
    color: Colores.de(pref.tema).texto,
  );
}

/// Las medidas que dependen del ancho de la pantalla.
///
/// MOBILE-FIRST: lo de abajo se aplica siempre, y lo de arriba solo cuando hay
/// sitio. Al reves --empezar por el escritorio y quitar cosas-- el resultado en un
/// movil es un `if` de mas en cada fila, y esa es la razon por la que las
/// pantallas responsive se rompen al final.
///
/// LA MEDIDA QUE IMPORTA. [anchoMaximoDeFila] es 560 px. Por encima, una fila de
/// un modulo con el boton a la derecha deja un hueco enorme en medio, y el ojo
/// pierde la relacion entre "el nombre" y "el boton". Por eso el contenido se
/// centrado con ese tope, no estirado: en una pantalla de 1440 px se lee igual de
/// bien que en una de 360, y en un movil grande no queda un desierto en medio.
class Medidas {
  const Medidas._();

  /// A partir de aqui hay sitio de sobra para poner el filtro al lado del titulo.
  static const double anchoParaDosColumnas = 600;

  /// El tope de ancho del contenido. Ver arriba el motivo.
  static const double anchoMaximoDeFila = 560;

  /// El ancho mas estrecho que puede tener la columna de texto.
  ///
  /// Existe por el caso de una ventana muy estrecha, donde el ancho disponible puede
  /// quedar por debajo de cero al restar los margenes y un `ConstrainedBox` con ancho
  /// negativo lanza. Un minimo pequeno es menos malo que una excepcion, y en una
  /// ventana de 120 px ya no hay nada que leer de todas formas.
  static const double anchoMinimoDeColumna = 120;

  /// A partir de aqui hay sitio para un panel de herramientas lateral con sus nombres.
  ///
  /// Y EL NUMERO ESTA MEDIDO, Y NO ES UN GUSTO. Mirada la captura responsive de Logos a
  /// 768 px: **no hay panel lateral**, hay una barra de iconos abajo. Y mirada la de
  /// escritorio a 1920 px, el panel con los nombres ocupa unos 200 px de 1920, un 10 %.
  ///
  /// El corte se pone en 1100 y no en 900 porque con nombres el panel mide unos 200 px y
  /// la columna de lectura no puede bajar de los 900: por debajo, el texto a 90 caracteres
  /// empieza a cortar lineas de la Escritura en sitios que no son los del final de la frase,
  /// que es lo unico que no se puede hacer con un texto.
  static const double anchoParaPanelDeHerramientas = 1100;

  /// Margen de los lados en pantallas estrechas.
  static const double margenEstrecho = 14;

  /// Margen de los lados en pantallas anchas.
  static const double margenAncho = 24;

  static double margenPara(double ancho) =>
      ancho >= anchoParaDosColumnas ? margenAncho : margenEstrecho;
}

/// Un contenedor que centra el contenido y le pone el tope de ancho.
///
/// Va en [ui/core] y no en la pantalla porque lo usan todas, y porque el tope de
/// ancho es una regla de la app y no una decision de una vista.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({super.key, required this.child, this.anchoMaximo});

  final Widget child;

  /// Por defecto [Medidas.anchoMaximoDeFila].
  final double? anchoMaximo;

  /// Y EL MARGEN VA **AQUI DENTRO** Y NO EN CADA PANTALLA, y es la razon de que la
  /// comprobacion "la barra y el cuerpo caen en la misma columna" exista: con un 14 escrito
  /// en un sitio y un `Medidas.margenPara` --que da 24 en pantallas anchas-- en otro, el
  /// filtro y la lista se separan diez pixeles, y a 1440 se ve mas que a 360.
  ///
  /// Y EL ANCHO SE MIDE **AQUI** y no se pasa, porque un `MediaQuery` dentro del `Center` mide
  /// la ventana y dentro de una fila mediria otra cosa, que es como se pierde el margen.
  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: anchoMaximo ?? Medidas.anchoMaximoDeFila,
          // Y EL MINIMO DE ANCHO, que el original no tenia. Sin el, una ventana muy estrecha
          // deja el `Padding` de los dos lados mas grande que el hueco y el contenido sale
          // con ancho negativo.
          minWidth: Medidas.anchoMinimoDeColumna,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Medidas.margenPara(ancho)),
          child: child,
        ),
      ),
    );
  }
}