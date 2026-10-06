// El contraste de los tres temas, comprobado en cada ejecucion.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y NO ES UN NUMERO ESCRITO EN UN COMENTARIO
// ============================================================================
//
// Los nueve colores de cada tema estan medidos, y los numeros estan escritos en
// `lib/ui/core/tema.dart`. Aqui se **comprueban**, y esa es la parte que importa:
//
//   - si alguien cambia un color a mano y lo deja en 4:1, esta prueba se pone roja
//   - si el umbral de un color esta mal --porque se ha copiado de otro-- se ve aqui
//   - y si el algoritmo de WCAG se implementa mal, **las dos cosas** fallan a la vez y el
//     fallo dice que el contraste no cumple, que es un sintoma de lo contrario
//
// Que es lo que paso con la primera medicion: un `pow` escrito a mano en un fichero suelto
// daba **6,05:1** para el rojo de las palabras de Jesus donde el valor bueno es **7,33**, y
// si se hubiera escrito ese 6,05 en el comentario del tema, el repositorio habria pasado
// meses con un numero que no era el del contraste real. Los numeros de `AGENTS.md` eran los
// buenos y la herramienta la que mentia.
//
// ============================================================================
// Y POR QUE LOS UMBRALES NO SON TODOS 7:1
// ============================================================================
//
// Porque el umbral depende de lo que el color **es**, y ponerlos todos iguales seria no
// decidir nada:
//
//   - **texto de cuerpo** --el texto corriente y el rojo de las palabras de Jesus-- necesita
//     7:1, que es el AAA de texto normal. El rojo es texto de cuerpo y no un adorno: un rojo
//     claro de letras rojas se lee como texto deshabilitado y no como Escritura
//   - **texto suave** --el nombre del libro, las migas-- es informacion secundaria y le basta
//     4,5:1, que es el AA de texto normal
//   - **acento, peligro y primario** --enlaces, avisos y botones-- tambien 4,5:1

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/core/tema.dart';

/// El canal de un color, linealizado.
///
/// Y LA REGLA EXACTA DEL WCAG 2.1, que es la que dice el estandar y no una aproximacion:
///
///     c / 255    <= 0,03928   ->   c / 12,92
///     c / 255    >  0,03928   ->   ((c / 255 + 0,055) / 1,055) ^ 2,4
///
/// El 0,03928 es el **punto de la curva**, y no se puede escribir como 0,04 aunque el numero
/// "bonito" sea 0,04: con 0,04, el canal 10 --que es `10/255 = 0,0392`-- cae en la rama
/// lineal, y el estandar lo pone en la curva. El error es pequeno en un canal y se multiplica
/// en la luminancia, que es una suma ponderada de tres.
// Y ESTA ES **PUBLICA** Y NO PRIVADA, y no por comodidad de un fichero vecino: el algoritmo
// de WCAG tiene que estar en **un** sitio. Duplicarlo en un segundo fichero de pruebas es la
// forma de que las dos copias midan cosas distintas, que es lo que paso con el `pow` escrito
// a mano que daba 6,05 donde el valor bueno es 7,33.
double canal(double byte) {
  final v = byte / 255.0;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// La luminancia relativa, la de WCAG.
///
/// Y LOS TRES PESOS SON **0,2126, 0,7152 y 0,0722**, y no `0,299, 0,587, 0,114`, que son los
/// de la television y los que todo el mundo escribe por costumbre. Con los de television el
/// azul pesa un 40 % menos y el rojo un 24 % mas, y en un tema donde el rojo de las palabras
/// de Jesus es el color que mas hay que mirar, el error sale justo ahi.
double luminancia(Color c) {
  final r = canal(c.r * 255.0);
  final g = canal(c.g * 255.0);
  final b = canal(c.b * 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// El contraste entre dos colores, de 1 a 21.
double contraste(Color a, Color b) {
  final la = luminancia(a);
  final lb = luminancia(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// El AAA de texto normal.
const double aaa = 7.0;

/// El AA de texto normal.
const double aa = 4.5;

void main() {
  group('el contraste de los tres temas', () {
    /// Los nueve colores de un tema, con su nombre y el umbral que le toca.
    ///
    /// Y EL LISTADO ESTA AQUI Y NO SE DEDUCE, porque el umbral **depende de lo que el color
    /// es** y eso no se puede calcular: un algoritmo no sabe si un rojo es un aviso o la
    /// Palabra de Cristo. Lo que si se calcula es el ratio, y se compara con el umbral que
    /// la lista dice.
    void comprobar(
      Colores c,
      String tema, {
      required Map<String, double> umbrales,
    }) {
      // Y CADA COLOR CONTRA **LOS DOS** FONDOS, y no solo contra el principal. Un color
      // puede pasar AAA en el fondo de la pantalla y fallar en una tarjeta, y las tarjetas
      // estan en las hojas de versiones, de libros y de comentarios.
      for (final entrada in <MapEntry<String, MapEntry<Color, double>>>[
        MapEntry('fondo', MapEntry(c.fondo, umbrales['texto']!)),
        MapEntry('superficie', MapEntry(c.superficie, umbrales['texto']!)),
      ]) {
        expect(
          contraste(c.texto, entrada.value.key),
          greaterThanOrEqualTo(entrada.value.value),
          reason: 'texto sobre ${entrada.key} del tema $tema',
        );
      }

      expect(
        contraste(c.textoSuave, c.fondo),
        greaterThanOrEqualTo(aa),
        reason: 'texto suave del tema $tema',
      );
      expect(
        contraste(c.textoSuave, c.superficie),
        greaterThanOrEqualTo(aa),
        reason: 'texto suave sobre superficie del tema $tema',
      );
      expect(
        contraste(c.acento, c.fondo),
        greaterThanOrEqualTo(aa),
        reason: 'acento del tema $tema',
      );
      expect(
        contraste(c.acento, c.superficie),
        greaterThanOrEqualTo(aa),
        reason: 'acento sobre superficie del tema $tema',
      );
      expect(
        contraste(c.peligro, c.fondo),
        greaterThanOrEqualTo(aa),
        reason: 'peligro del tema $tema',
      );
      expect(
        contraste(c.peligro, c.superficie),
        greaterThanOrEqualTo(aa),
        reason: 'peligro sobre superficie del tema $tema',
      );
      expect(
        contraste(c.primario, c.fondo),
        greaterThanOrEqualTo(aa),
        reason: 'primario del tema $tema',
      );
    }

    /// Y EL ROJO DE LAS PALABRAS DE JESUS TIENE **SU PROPIA** COMPROBACION, con 7:1, porque
    /// es texto de cuerpo. Y va por separado del grupo de los otros por eso mismo: si estuviera
    /// con los de 4,5:1, el rojo de las palabras de Jesus podria bajar a 5:1 y esta prueba
    /// seguiria en verde.
    void comprobarLasPalabrasDeJesus(Colores c, String tema) {
      for (final (nombre, fondo) in <(String, Color)>[
        ('fondo', c.fondo),
        ('superficie', c.superficie),
      ]) {
        expect(
          contraste(c.palabraDeJesus, fondo),
          greaterThanOrEqualTo(aaa),
          reason: 'palabras de Jesus sobre $nombre del tema $tema',
        );
      }
    }

    test('el claro, que es el que habia', () {
      const c = Colores.claro;
      comprobar(c, 'claro', umbrales: <String, double>{'texto': aaa});
      comprobarLasPalabrasDeJesus(c, 'claro');

      // Y LOS NUMEROS EXACTOS DEL CLARO, porque son los que estaban escritos en `AGENTS.md`
      // antes de que este fichero existiera, y el cambio **no** los puede mover. Son una
      // cadena: si el claro se mueve, el que decia 16,96:1 deja de ser verdad.
      expect(contraste(c.texto, c.fondo), closeTo(16.96, 0.01));
      expect(contraste(c.palabraDeJesus, c.fondo), closeTo(7.33, 0.01));
      expect(contraste(c.palabraDeJesus, c.superficie), closeTo(7.71, 0.01));
    });

    test('el sepia, que es lo de papel', () {
      const c = Colores.sepia;
      comprobar(c, 'sepia', umbrales: <String, double>{'texto': aaa});
      comprobarLasPalabrasDeJesus(c, 'sepia');

      expect(contraste(c.texto, c.fondo), closeTo(11.81, 0.01));
      expect(contraste(c.palabraDeJesus, c.fondo), closeTo(7.15, 0.01));
    });

    test('el oscuro, que no es el claro invertido', () {
      const c = Colores.oscuro;
      comprobar(c, 'oscuro', umbrales: <String, double>{'texto': aaa});
      comprobarLasPalabrasDeJesus(c, 'oscuro');

      expect(contraste(c.texto, c.fondo), closeTo(15.17, 0.01));
      expect(contraste(c.palabraDeJesus, c.fondo), closeTo(8.23, 0.01));

      // Y LO QUE HACE DE ESTE TEMA UN TEMA Y NO UN INVERTIDO: **los tres textos son
      // claros**. Lo invertido da un texto casi blanco y un rojo casi negro, y un rojo casi
      // negro sobre fondo casi negro no se ve. Aqui el rojo de las palabras de Jesus es
      // **claro**, y es un color distinto al del claro a proposito.
      expect(c.palabraDeJesus.computeLuminance(),
          greaterThan(c.palabraDeJesus == Colores.claro.palabraDeJesus
              ? 0
              : 0.2),
          reason: 'el rojo del oscuro es claro');
      expect(c.palabraDeJesus, isNot(Colores.claro.palabraDeJesus),
          reason: 'y no es el mismo rojo, porque el mismo no se ve');
    });

    test('cada tema tiene sus nueve colores, y ninguno es el de otro', () {
      // Y ESTO NO ES COSMETICO. Si dos temas compartieran un color por un descuido --el
      // `primario` del sepia copiado del claro-- las comprobaciones de arriba **no se
      // enterarian**: compararían el color contra el otro fondo y darian verde, y el color
      // estaria mal en un tema y bien en el otro.
      final temas = <TemaDeLectura, Colores>{
        for (final t in TemaDeLectura.values) t: Colores.de(t),
      };
      for (final a in temas.entries) {
        for (final b in temas.entries) {
          if (a.key == b.key) continue;
          expect(a.value.fondo, isNot(b.value.fondo), reason: '${a.key} y ${b.key}');
          expect(a.value.texto, isNot(b.value.texto), reason: '${a.key} y ${b.key}');
        }
      }
    });

    test('el rojo de las palabras de Jesus no es el de peligro, en ninguno', () {
      // Y EN NINGUNO, que es donde se separan. Si fueran el mismo, un dia el aviso de error
      // pasaria a ser del color de la Palabra de Cristo y nadie sabria que paso.
      for (final t in TemaDeLectura.values) {
        final c = Colores.de(t);
        expect(c.palabraDeJesus, isNot(c.peligro), reason: t.name);
      }
    });

    test('esOscuro dice la verdad en los tres', () {
      // Y SE CALCULA DE LA LUMINANCIA, no de una bandera, y esta comprobacion es la que
      // avisa si algun dia alguien guarda una bandera que se separa del color.
      expect(Colores.claro.esOscuro, isFalse);
      expect(Colores.sepia.esOscuro, isFalse);
      expect(Colores.oscuro.esOscuro, isTrue);
    });

    test('los tres temas caben en el ThemeData y llevan la paleta dentro', () {
      // Y LA PALETA VA DENTRO DEL TEMA, que es lo que hace que `context.colores` la encuentre.
      // Sin esto, `context.colores` daria un null y reventaria en el primer uso, que es un
      // fallo que aparece en pantalla y no en un `build`.
      for (final t in TemaDeLectura.values) {
        final tema = temaDeAb(PreferenciaDeLectura.porDefecto.cambiarTema(t));
        expect(tema.extension<Colores>(), isNotNull, reason: t.name);
        expect(tema.extension<Colores>(), Colores.de(t), reason: t.name);
      }
    });

    test('el tema por defecto es el claro, y el de partida tambien', () {
      expect(temaDeAb().extension<Colores>(), Colores.claro);
      expect(PreferenciaDeLectura.porDefecto.tema, TemaDeLectura.claro);
      // Y QUE `temaDeAb()` SIN PARAMETRO ES EL CLARO, y no un `null` que alguien tenga que
      // tratar: es el que usan todas las pruebas que montan la pantalla sin preferencia.
      expect(temaDeAb().scaffoldBackgroundColor, Colores.claro.fondo);
    });

    test('el fondo del scaffold es el fondo de la paleta, en los tres', () {
      // Y ESTA ES LA COMPROBACION QUE HACE QUE EL TEMA SE VEA. Un `ThemeData` con la paleta
      // en las `extensions` y sin poner el fondo en `scaffoldBackgroundColor` deja el
      // `ColorScheme` de Material mandando, y la pantalla sale con el color semilla.
      for (final t in TemaDeLectura.values) {
        final tema = temaDeAb(PreferenciaDeLectura.porDefecto.cambiarTema(t));
        expect(tema.scaffoldBackgroundColor, Colores.de(t).fondo, reason: t.name);
      }
    });
  });
}