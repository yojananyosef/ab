// Que el texto que se ve **carry** los colores de la paleta.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y EL OTRO NO LO CAZA
// ============================================================================
//
// `contraste_de_los_temas_test.dart` mide **los nueve colores de cada paleta** contra los
// demas, y los numeros estan bien: el texto del oscuro da 15,17:1 sobre su fondo. Ese fichero
// pasaba con la aplicacion **rota**.
//
// Y LA RAZON DE QUE PASARA, QUE ES LA QUE HACE ESTE FICHERO NECESARIO:
//
//     textTheme: base.textTheme.apply(bodyColor: c.texto, displayColor: c.texto).copyWith(
//       bodyMedium:  const TextStyle(fontSize: 16, height: 1.45),
//       titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
//       ...
//     )
//
// El `.copyWith` **sustituye** el `TextStyle` entero, no le cambia el tamano. Y un
// `TextStyle` con la letra `color` a null **no tiene color**: no es "el color del tema", es
// "el que venga de fuera". Asi que el `.apply()` de la linea de arriba --que es lo que pone
// el color-- se **tira entero** para seis de los estilos, y esos seis salen a buscar el
// color a la cadena de `DefaultTextStyle`.
//
// Y MEDIDO EN PANTALLA, en la biblioteca con el tema oscuro:
//
//     bodyMedium      #1A1714 sobre #14110E      1,05:1
//     titleMedium     #1A1714 sobre #14110E      1,05:1
//
// Y **#1A1714 es el texto del tema CLARO** --`Colores.claro.texto`--, con el fondo del oscuro.
// Es decir: el texto de una pantalla oscura salia con **el color del tema claro**, y por eso
// se veian negros los titulos, los nombres de los modulos y las etiquetas de los filtros.
// Antes de arreglar el `copyWith` el color medido era **#000000**, negro puro: la cadena de
// `DefaultTextStyle` de Material. Los dos son ilegibles; el segundo es el de la forma
// anterior de escribirlo.
//
// Y ELLA NO FALLA, Y ESO ES LO QUE LA HACE PEOR: no hay excepcion, no hay `overflow`, no hay
//WAYS. Un `Text` de 20 px con el color equivocado se pinta **perfecto**. Un titulo ilegible
// no falla, y por eso solo se ve mirando.
//
// La comprobacion de que un texto es legible midiendo su tamano es incompleta: hay que medir
// tambien **de que color sale de verdad**, que es lo que hace este fichero.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/ui/core/tema.dart';

import 'contraste_de_los_temas_test.dart' show contraste, luminancia;

void main() {
  // Y LOS SEIS ESTILOS QUE EL `copyWith` DEJA SIN COLOR. Los tres que **no** se listan --
  // `bodySmall`, `labelSmall` y los que llevan `color:` explicito-- los pones bien a mano y
  // por eso no se rompen. Y no es una lista de los que "importan": es la lista de los que
  // el `copyWith` **reemplaza**, que es una lista que se lee del codigo y no del criterio.
  const estilosSinColorPuesto = <String>[
    'bodyMedium',
    'bodyLarge',
    'titleLarge',
    'titleMedium',
    'titleSmall',
    'labelLarge',
  ];

  group('1. el tema lleva sus propios colores al texto', () {
    for (final nombre in estilosSinColorPuesto) {
      testWidgets('el $nombre sale con el color de la paleta, en los tres temas',
          (WidgetTester t) async {
        for (final tema in TemaDeLectura.values) {
          final color = await _colorRealDe(t, tema, nombre);
          final c = Colores.de(tema);

          // Y LA COMPARACION ES CONTRA **UN FONDO**, y no "es el color de la paleta". Lo
          // segundo pasaria con un color equivocado que casara con el de otro tema, y lo
          // que importa es que se lea: contraste contra el fondo **y** contra la superficie,
          // porque un modulo esta sobre el fondo y un campo de texto sobre la superficie.
          expect(
            contraste(color, c.fondo),
            greaterThanOrEqualTo(4.5),
            reason: '$nombre en $tema sale #${color.toARGB32().toRadixString(16)} '
                'sobre el fondo #${c.fondo.toARGB32().toRadixString(16)}: '
                '${contraste(color, c.fondo).toStringAsFixed(2)}:1',
          );
          expect(
            contraste(color, c.superficie),
            greaterThanOrEqualTo(4.5),
            reason: '$nombre en $tema sobre la superficie: '
                '${contraste(color, c.superficie).toStringAsFixed(2)}:1',
          );
        }
      });
    }
  });

  group('2. y en el oscuro no sale el color del claro', () {
    testWidgets('ningun texto sale con el color de otro tema', (WidgetTester t) async {
      // Y LA COMPROBACION DEL **COLOR CRUZADO**, que es la que hace el dano. Medir
      // "contraste >= 4,5" ya lo caza, y esta es la que dice **por que**: si el texto del
      // oscuro saliera con el color del claro, el fallo se leeria como un numero raro y
      // habria que ir a buscar el codigo del tema para entenderlo.
      for (final nombre in estilosSinColorPuesto) {
        final oscuro = await _colorRealDe(t, TemaDeLectura.oscuro, nombre);
        final claro = await _colorRealDe(t, TemaDeLectura.claro, nombre);

        expect(
          luminancia(oscuro),
          greaterThan(luminancia(claro)),
          reason: 'el $nombre del oscuro (${oscuro.toARGB32().toRadixString(16)}) tiene '
              'que ser **mas claro** que el del claro '
              '(${claro.toARGB32().toRadixString(16)}), no igual',
        );
      }
    });
  });

  group('3. y el rojo de las palabras de Jesus sigue siendo texto', () {
    testWidgets('la palabra de Jesus no es el primario ni el peligro', (WidgetTester t) async {
      // Y ESTA ES LA QUE IMPORTA DE ESTAS TRES, porque el rojo **es** texto de cuerpo y
      // necesita 7:1. Con el tema claro el rojo da 7,33:1 sobre el fondo; si un dia el
      // `copyWith` lo cascara, esta prueba se pone roja con el numero al lado.
      for (final tema in TemaDeLectura.values) {
        final c = Colores.de(tema);
        expect(
          contraste(c.palabraDeJesus, c.fondo),
          greaterThanOrEqualTo(7.0),
          reason: 'el rojo de $tema da '
              '${contraste(c.palabraDeJesus, c.fondo).toStringAsFixed(2)}:1 y es '
              '**texto de cuerpo**: necesita 7:1',
        );
      }
    });
  });
}

/// El color con el que se pinta de verdad un `Text` con ese estilo del tema.
///
/// ============================================================================
/// POR QUE HAY QUE **RESOLVER** EL ESTILO Y NO LEER EL DEL TEMA
/// ============================================================================
///
/// Porque el fallo es justo ese: el `TextStyle` del `textTheme` **no tiene color**, y lo que
/// se ve en pantalla es lo que sale de la cadena de `DefaultTextStyle` de Material. Leer
/// `textTheme.titleMedium!.color` daria `null` --que ya es un aviso-- pero no daria el color
/// equivocado, y lo que hay que comprobar es el equivocado.
///
/// Y LA RESOLUCION ES LA MISMA QUE HACE FLUTTER: `DefaultTextStyle.of(context).style`
/// combinado con el estilo del `Text`. Un `Text` no trae el color; lo hereda. Aqui se
/// combina igual que en `Text.build`, y por eso el numero que sale es el que se ve.
Future<Color> _colorRealDe(
  WidgetTester t,
  TemaDeLectura tema,
  String nombreDelEstilo,
) async {
  final clave = ValueKey<String>('$tema-$nombreDelEstilo');
  late Color color;

  await t.pumpWidget(MaterialApp(
    theme: temaDeAb(PreferenciaDeLectura.porDefecto.copyWith(tema: tema)),
    // ========================================================================
    // Y LA ANIMACION A CERO, QUE NO ES COSMETICA: ES LO QUE HACE ESTA PRUEBA
    // ========================================================================
    //
    // Medido: con la animacion puesta, los tres temas dan **el mismo color**:
    //
    //     claro    ESTILO ff1a1714
    //     sepia    ESTILO ff1a1714
    //     oscuro   ESTILO ff1a1714
    //
    // Y NO ES UN FALLO DE `temaDeAb`, que sin `MaterialApp` da tres colores distintos. Es
    // `AnimatedTheme`: al cambiar de tema **interpola**, y `ThemeData.lerp` tambien interpola
    // el `textTheme`. Un solo `pumpWidget` es el **primer fotograma** de esa transicion, que
    // esta en t = 0, y en t = 0 el dato sigue siendo **el de antes**.
    //
    // Y ESO ES UNA TRAMPA SERIA PARA CUALQUIER PRUEBA DE ESTA CLASE, porque el widget existe,
    // el color no es null y el color es el correcto... del tema anterior. Una prueba que
    // comprobara "el color cambia con el tema" pasaria sin comprobar nada: el de los tres
    // seria el primero, siempre.
    themeAnimationDuration: Duration.zero,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext contexto) {
          final estilos = Theme.of(contexto).textTheme;
          final estilo = switch (nombreDelEstilo) {
            'bodyMedium' => estilos.bodyMedium,
            'bodyLarge' => estilos.bodyLarge,
            'titleLarge' => estilos.titleLarge,
            'titleMedium' => estilos.titleMedium,
            'titleSmall' => estilos.titleSmall,
            'labelLarge' => estilos.labelLarge,
            _ => null,
          };
          // Y SE METE UN `Text` DE VERDAD, y no se lee el mapa del tema: lo que se quiere es
          // el color **final**, con toda la cadena de herencia ya aplicada.
          return Text(
            'Medida',
            key: clave,
            style: estilo,
          );
        },
      ),
    ),
  ));

  color = t.widget<Text>(find.byKey(clave)).style?.color ??
      _porDefecto(t, find.byKey(clave));
  return color;
}

/// El color que le llega al `Text` desde el `DefaultTextStyle` de su contexto.
Color _porDefecto(WidgetTester t, Finder clave) {
  final elemento = t.element(clave);
  return DefaultTextStyle.of(elemento).style.color ?? const Color(0xFF000000);
}
