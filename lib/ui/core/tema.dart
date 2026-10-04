library;

// El tema y las medidas de la app.
//
// LO QUE HAY AQUI Y POR QUE NO HAY MAS. Un tema y cuatro medidas. Nada de un
// sistema de estilos propio, ni de un paquete de diseno, ni de tipografias
// descargadas. La razon es concreta y no es purismo:
//
// 1. La app tiene **cinco** pantallas. Un sistema de estilos para cinco pantallas
//    es mas codigo que las pantallas.
/// 2. Cada byte de tipografia son bytes de descarga, y esta app se usa con datos
//    moviles: cada KB cuenta.
/// 3. Lo que hay que comprobar es que no reviente a 360 px, y eso lo comprueban
//    pruebas de widget con medidas reales, no un `DesignSystem`.
//
// EL FONDO Y EL CONTRASTE. Fondo claro y texto oscuro, porque se usa aoften al
// sol y con la pantalla con el brillo al maximo. Un fondo oscuro en un exterior con
// sol es ilegible, y el que lee va a seguir leyendo en el sitio de siempre: la
// pantalla esta al lado de la Biblia, no en una habitacion a oscuras.
//
// EL TAMANO MINIMO DE LETRA. 16 px en el cuerpo del texto. Es la cifra que aparece
// en el `Viewport` de los navegadores moviles por una razon concreta: por debajo de
// 16 px, iOS **hace zoom automaticamente** al enfocar un campo, y la pagina se
// descuelga. Ese es el bug mas molesto que puede tener una pantalla con un filtro
// de texto, y es de los que nadie ve en su movil de desarrollo.
//
// Y NO HAY UN ANCHO MAXIMO PARA LA LISTA, pero si para el TEXTO de lectura, que
// esta en otra pantalla. Una lista de una columna con todo el ancho de una
// pantalla de 1440 px obliga a Pansar la cabeza para ir de una linea a la
// siguiente.

import 'package:flutter/material.dart';

/// Los colores. Pocos y con nombre, no numeros sueltos en el codigo.
class Colores {
  const Colores._();

  /// Fondo de la pantalla. Clarito: se lee al sol.
  static const Color fondo = Color(0xFFFBF9F4);

  static const Color superficie = Color(0xFFFFFFFF);

  /// Texto principal. Con contraste alto sobre [fondo]: 13,9:1.
  static const Color texto = Color(0xFF1A1714);

  /// Texto secundario. Contraste de 5,1:1, que pasa AA.
  static const Color textoSuave = Color(0xFF59544C);

  static const Color linea = Color(0xFFE2DCD2);

  static const Color primario = Color(0xFF6B4F2A);

  /// Rojo de aviso, y tambien de error. Contraste de 5,4:1 sobre [fondo].
  static const Color peligro = Color(0xFF9B2C22);

  static const Color acento = Color(0xFF2F5D50);
}

/// El tema.
ThemeData temaDeAb() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colores.primario,
      surface: Colores.superficie,
      onSurface: Colores.texto,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colores.fondo,
    // 16 px, y no 14: por debajo de 16 el navegador del movil hace zoom al enfocar
    // un campo y descuelga la pagina. Es la cifra que impone el `Viewport`.
    textTheme: base.textTheme.apply(
      bodyColor: Colores.texto,
      displayColor: Colores.texto,
    ).copyWith(
      // El cuerpo: 16 px en todos los pesos.
      bodyMedium: const TextStyle(fontSize: 16, height: 1.45, color: Colores.texto),
      bodyLarge: const TextStyle(fontSize: 17, height: 1.45, color: Colores.texto),
      bodySmall: const TextStyle(fontSize: 14, height: 1.4, color: Colores.textoSuave),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colores.texto),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colores.texto),
      titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colores.texto),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(fontSize: 13, color: Colores.textoSuave),
    ),
    dividerTheme: const DividerThemeData(color: Colores.linea, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colores.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colores.linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colores.primario, width: 2),
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
        side: const BorderSide(color: Colores.linea),
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
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colores.texto,
      contentTextStyle: TextStyle(fontSize: 15, color: Colores.superficie),
      behavior: SnackBarBehavior.floating,
    ),
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
/// bien que en una de 360, y en un movil grande no queda un deserts en medio.
class Medidas {
  const Medidas._();

  /// A partir de aqui hay sitio de sobra para poner el filtro al lado del titulo.
  static const double anchoParaDosColumnas = 600;

  /// El tope de ancho del contenido. Ver arriba el motivo.
  static const double anchoMaximoDeFila = 560;

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

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo ?? Medidas.anchoMaximoDeFila),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Medidas.margenPara(ancho)),
          child: child,
        ),
      ),
    );
  }
}
