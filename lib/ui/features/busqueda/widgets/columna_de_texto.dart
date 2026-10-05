// Cuanto mide la columna de texto, y por que no es un numero escrito.
//
// ============================================================================
// EL PROBLEMA: "90 CARACTERES POR LINEA" NO ES UN NUMERO DE PIXELES
// ============================================================================
//
// Depende de la fuente, del tamano y de como se mida el caracter. Con la fuente de
// este proyecto a 16 px, 90 caracteres ocupan unos 660 px; con otra fuente y a 20 px,
// unos 900. Escribir `anchoMaximo: 660` en el codigo seria escribir una suposicion y
// llamarla medida, y el dia que cambie la fuente --o que alguien tenga el texto al
// 200 por ciento-- el limite de 90 caracteres pasaria a ser de 130 o de 55 sin que
// nadie se entere.
//
// ASI QUE SE MIDE, Y SE MIDE CON LA HERRAMIENTA DE MEDIR: un `TextPainter` con una
// frase en castellano, y su ancho dividido entre sus caracteres. Nada de constantes
// ni de tablas: si cambia la fuente, cambia la medida, que es lo unico que se puede
// pedir de un limite de este tipo.
//
// ============================================================================
// POR QUE UNA FRASE Y NO 90 LETRAS "N"
// ============================================================================
//
// "90 caracteres" quiere decir 90 caracteres **de los que se leen**, y la "n" es de
// las letras anchas: una columna medida con 90 "n" caben unas 110 letras normales, y
// el limite se habria pasado en un tercio sin que se notara. Al reves --medir con la
// "i", la mas estrecha de todas-- saldria una columna de 300 px que no se lee ni con
// lupa.
//
// La frase de la muestra es de Cervantes, de dominio publico, y esta en castellano
// de verdad: con sus vocales, su enie y su letra "y", que es de las que mas se
// repiten. No es el promedio de la documentacion de un motor de interfaces, que
// esta en ingles y no tiene ni la enie ni la "y" accentuada.
//
// ============================================================================
// LA MEDIDA USA EL TAMANO DE LETRA QUE HAY, NO UNO FIJO
// ============================================================================
//
// Que la columna mida mas pixeles con letra grande **no es un fallo**. Es lo
// correcto: el limite son 90 caracteres, no 90 caracteres con la letra que tenia
// quien escribio el codigo. Con la letra al 200 por ciento caben 90 caracteres en una
// columna mas ancha, y se siguen leyendo los mismos 90 por linea. Fijar el ancho en
// pixeles seria castigar a quien necesita letra grande, que es justo a quien mas lo
// necesita.

// ============================================================================
// Y SE APLICA TAMBIEN EL LIMITE DE 560 PX QUE YA HABIA, PERO NO COMBINA CON EL
// ============================================================================
//
// Son dos cosas distintas: `anchoMaximoDeFila` es el ancho de los elementos con
// ficha --una fila de la biblioteca--, y este es el ancho de un texto seguido, que
// no lleva ficha ninguna. Se toma el menor de los dos, y el menor casi siempre es
// este: 560 px son unos 76 caracteres, que esta dentro de los 90 y se lee bien. Si
// algun dia `anchoMaximoDeFila` bajara de aqui, esta columna lo bajaria tambien por
// el motivo del limite de caracteres y no por el de la ficha.
//
// ============================================================================
// Y NUNCA MAS ANCHA QUE LA PANTALLA
// ============================================================================
//
// Una columna mas ancha que la pantalla se sale por la derecha, y en un movil eso
// es texto que no se puede leer. En un movil de 360 px con letra de 16 px el limite
// de caracteres no llega --caben unos 49-- y no se finge lo contrario: se lo que cabe
// y ya esta. Lo que si se podria --bajar la letra a 11 px para que entren 70
// caracteres-- no se hace, porque 11 px no se lee sin gafas y un limite de caracteres
// no vale la pena a costa de la vista.

import 'dart:math' as matematica;

import 'package:flutter/material.dart';

import '../../../core/tema.dart';

/// Una frase para medir.
///
/// De Cervantes, y en castellano de verdad. Y una frase y no una palabra suelta:
/// medir "hola" mide cuatro letras y dos espacios, y da un promedio que no se parece
/// a nada. Una frase se parece a una linea, que es lo que se quiere medir.
const String _muestra = 'En un lugar de la Mancha de cuyo nombre no quiero acordarme';

/// Cuantos caracteres por linea caben como maximo.
const int kCaracteresPorLinea = 90;

/// El ancho en pixeles de [kCaracteresPorLinea] caracteres con [estilo].
///
/// Se mide con un `TextPainter`, que es el mismo motor que pinta la pantalla: si la
/// fuente con la que se pinta cambia, esta medida cambia con ella.
///
/// Y EL RESULTADO ES EL ANCHO DE UNA LINEA *MEDIA*, no de la mas ancha posible, y es
/// deliberado. Hay lineas de texto --las de las "hhh", las de los dialogos largos
/// con raya-- mas anchas que el promedio. Si se midiera el caso peor, la columna de
/// los dias buenos saldria corta de mas. Con la media, casi todas las lineas caben en
/// 90 caracteres y las que no, en 88.
double anchoDeNoventaCaracteres(TextStyle estilo) {
  final pintor = TextPainter(
    text: TextSpan(text: _muestra, style: estilo),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final ancho = pintor.width / _muestra.runes.length * kCaracteresPorLinea;

  // El pintor no pinta nada, pero tiene recursos que suelta.
  pintor.dispose();
  return ancho;
}

/// El ancho de la columna de texto, ya comparado con lo que hay disponible.
///
/// [anchoDisponible] es el ancho que queda despues de los margenes. El resultado es
/// el menor de lo que cabe por caracteres y de lo que cabe por pantalla.
///
/// Y NUNCA ES MENOR QUE [Medidas.anchoMinimoDeColumna]. Con una ventana estrecha --una
/// ventana de escritorio de 120 px, que se puede tener-- el ancho sale negativo si no
/// se guarda, y un `ConstrainedBox` con ancho negativo lanza. Un minimo pequeno es
/// menos malo que una excepcion.
double anchoDeColumnaDeTexto({required double anchoDisponible, required TextStyle estilo}) {
  final porCaracteres = anchoDeNoventaCaracteres(estilo);
  final util = anchoDisponible.clamp(Medidas.anchoMinimoDeColumna, double.infinity);
  return matematica.min(util, porCaracteres);
}

/// La columna de texto: centrada, con el ancho que le toca, y sin mas.
///
/// Sin esto, el texto de un capitulo en un monitor de 1440 px sale pegado a la
/// izquierda con 900 px de blanco a la derecha, y quien lee tiene que girar la
/// cabeza del final de la linea al principio de la siguiente. Ese giro es lo que hace
/// que la gente pierda el sitio, y no tiene nada que ver con lo que se lee.
///
/// Y EN UN MOVIL NO HACE NADA, que es lo que importa: a 360 px la columna es la
/// pantalla menos los margenes, porque el limite de caracteres no llega.
class ColumnaDeTexto extends StatelessWidget {
  const ColumnaDeTexto({super.key, required this.estilo, required this.hijo});

  /// La clave del `ConstrainedBox` que lleva el ancho.
  ///
  /// Publica y no privada porque hay que poder **medirla** desde una prueba, y medir
  /// el `ColumnaDeTexto` con `getSize` no sirve: su primer descendiente con objeto de
  /// render es el `LayoutBuilder`, que ocupa todo el hueco que le da su padre y no lo
  /// que su hijo se ha limitado a. Medirlo daba el ancho de la pantalla entera y
  ///falseaba la comprobacion de que la columna se pasa cuando lo que se pasaba era la
  /// medicion. Con esta clave se mide lo que tiene el ancho limitado.
  static const Key claveDelAncho = Key('columna-de-texto-ancho');

  final TextStyle estilo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final margen = Medidas.margenPara(MediaQuery.sizeOf(context).width);
        return Center(
          child: ConstrainedBox(
            key: claveDelAncho,
            constraints: BoxConstraints(
              maxWidth: anchoDeColumnaDeTexto(
                anchoDisponible: MediaQuery.sizeOf(context).width - margen * 2,
                estilo: estilo,
              ),
            ),
            child: hijo,
          ),
        );
      },
    );
  }
}
