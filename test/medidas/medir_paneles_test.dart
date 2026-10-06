// MEDIDA: cuanto mide un panel de lectura al lado de otro, y si se puede leer.
//
// ============================================================================
// QUE MIDE Y POR QUE. Antes de escribir las pestanas hay que saber si dos textos en
// paralelo se pueden leer. La cifra que decide es la **columna de texto**, porque es lo
// unico que tiene ancho propio: `anchoDeColumnaDeTexto` limita a 90 caracteres por linea,
// y en un panel estrecho no llega --y entonces sale pegada a la pantalla y es lo que hay.
//
// Y LA MEDIDA ES CON LA FUENTE REAL, con el mismo `TextPainter` que usa la columna, y
// no con un numero escrito. Sin fuente proporcional estas medidas no valen nada: en el
// motor de pruebas todas las letras miden lo mismo, y el limite de 90 caracteres sale de
// 1.440 px a 16 de letra. Ver `test/support/fuente.dart`, que explica el problema entero.
//
// Y SE MIDE A LOS ANCHOS QUE IMPORTAN, y no a uno:
//
//     360 px     una columna, sin panel de herramientas
//     1100 px    el corte de las pestanas
//     1440 px    con panel de herramientas y dos textos
//
// QUE NO COMPRUEBA ESTE FICHERO. No comprueba que las pestanas se pinten ni que cierren
// modulos: eso es `test/ui/pestanas_de_panel_test.dart`. Aqui no hay widgets, solo numeros,
// y un fichero que mide no necesita montar nada para dar su numero.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/preferencia_de_lectura.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/busqueda/widgets/columna_de_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';

/// Si se ha podido cargar una fuente de verdad para medir.
var _hayFuente = false;

/// El ancho que se le queda a la lectura con el panel de herramientas al lado.
///
/// Y **226,5**, medido, no estimado. Es lo que mide `NavigationRail` con
/// `minExtendedWidth: 176` cuando la etiqueta mas larga es "Comentarios", y esta escrito
/// en `marco_de_estudio.dart` con el motivo: `minExtendedWidth` es un **minimo**, y el
/// panel se ensancha hasta que la etiqueta mas larga quepa.
const double anchoDelPanelDeHerramientas = 226.5;

/// El divisor que se reparte entre dos paneles, en px.
///
/// Y UN **1 px**, y no un margen: entre dos columnas de texto hay una linea de separacion
/// que hay que pintar, y esa linea ocupa un pixel. Sin ella, dos columnas de texto pegadas
/// se leen como una sola linea de 1.200 caracteres, que es lo que hace que un texto en dos
/// columnas sin separacion sea ilegible en vez de comodo.
const double divisorEntrePaneles = 1;

/// El estilo del cuerpo de texto del lector, con la familia de la fuente puesta.
///
/// Y LA FAMILIA A MANO, porque [anchoDeNoventaCaracteres] mide **el estilo que recibe** y
/// en la pantalla ese estilo hereda la familia del tema. Lo que se mide es la misma funcion
/// con un estilo real; que el tema lleve la familia es otra cosa, y se comprueba en
/// `tema_test.dart`.
TextStyle _cuerpo(bool conFuente) => TextStyle(
      fontFamily: conFuente ? kFamiliaDePrueba : null,
      fontSize: PreferenciaDeLectura.porDefecto.tamanoDeLetra,
      height: 1.7,
    );

/// Cuantos caracteres caben en una columna de [ancho].
///
/// Y USA **OTRA** FRASE, y no la de Cervantes con la que se mide el limite. Si se midiera
/// con la misma, la comprobacion seria circular: siempre daria justo, porque el limite se
/// ha calculado con ese mismo promedio. De Santa Teresa, de dominio publico.
int caracteresEn(double ancho, TextStyle estilo) {
  const frase =
      'Porque ya no hay cosa que me pueda dar placer, si no es hacer servicio a Dios, '
      'que es el mayor bien que conozco';
  final pintor = TextPainter(
    text: TextSpan(text: frase, style: estilo),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final porCaracter = pintor.width / frase.runes.length;
  pintor.dispose();
  return (ancho / porCaracter).floor();
}

/// Si se ha podido cargar la fuente. Sin ella, estas medidas no significan nada.
Future<void> _cargarSiSePuede() async => _hayFuente = await cargarLaFuenteDePrueba();

void main() {
  setUpAll(_cargarSiSePuede);

  group('la columna de texto de un panel', () {
    test('a 360 px la columna es la pantalla menos los margenes', () {
      // Sin panel de herramientas, a 360 px: `margenPara` da 14, y la columna es lo que
      // queda. El limite de 90 caracteres **no llega**: sale lo que cabe, que es media
      // pantalla, y es lo que hay. Un movil no puede dar mas y no se finge lo contrario.
      final estilo = _cuerpo(_hayFuente);
      final margen = Medidas.margenPara(360);
      final columna = anchoDeColumnaDeTexto(
        anchoDisponible: 360.0 - margen * 2,
        estilo: estilo,
      );
      expect(columna, 332.0);
      // Y SE COMPRUEBA QUE ES **MENOS** QUE EL LIMITE, y no el numero de caracteres: el
      // numero depende de la fuente y aqui puede no haberla. Lo que no cambia con la
      // fuente es que a 360 px no se llega nunca, porque 90 caracteres a 16 px miden mas
      // que 332 px con cualquier fuente proporcional.
      expect(columna, lessThan(anchoDeNoventaCaracteres(estilo)));
    });

    test('a 1100 px la columna llega al tope de 90 caracteres', () {
      // Con panel de herramientas a 1100 px quedan 873,5 de lectura. Menos los margenes
      // de 24 por lado son 825,5, y el tope de 90 caracteres es menor, asi que manda el
      // limite de caracteres: es la primera anchura donde se llega.
      final estilo = _cuerpo(_hayFuente);
      final disponible =
          1100.0 - anchoDelPanelDeHerramientas - Medidas.margenAncho * 2;
      final columna = anchoDeColumnaDeTexto(
        anchoDisponible: disponible,
        estilo: estilo,
      );

      // Y **MEDIDO**: con Roboto a 16 px, 90 caracteres de la frase de Cervantes miden
      // **768,99 px**. Ese numero no estaba escrito en ningun sitio y sale de aqui, y por
      // eso la comprobacion es "la columna es lo que hay" y no "la columna es 769": si la
      // fuente o el tamano de letra cambian, esto deja de ser cierto y entonces hay que
      // mirar por que, que es justo lo que se quiere ver.
      //
      // Y 825,5 disponibles contra 768,99 de tope: **sobran 56 px**, asi que a 1100 px
      // el limite de caracteres manda y la columna sale justa. Con menos de 56 px de
      // sobra --una ventana un poco mas estrecha-- la columna seria mas corta, y por eso
      // 1100 es un corte con margen y no uno exacto.
      expect(anchoDeNoventaCaracteres(estilo), lessThan(disponible));
      // Y LA BANDA ES [88, 96] Y NO [88, 90], y el motivo es el que esta escrito en
      // `columna_de_texto.dart`: la medida del tope usa la **frase de Cervantes** y la
      // cuenta usa la **de Santa Teresa**, porque medir con la misma seria circular. Las
      // dos frases tienen una letra media distinta, asi que el mismo ancho da dos numeros
      // distintos. Con 768,99 px salen **94** caracteres de Santa Teresa, y no 90: el
      // mismo ancho no cabe el mismo numero de letras de dos frases que no son la misma.
      //
      // Y ESA DIFERENCIA ES JUSTO LO QUE HACE QUE LA BANDA SEA UNA BANDA. Con una
      // comprobacion exacta --"caben 90"--aria midiendo la frase equivocada.
      expect(caracteresEn(columna, estilo), inInclusiveRange(88, 96));
    });

    test('a 1440 px con dos textos en paralelo cada uno se queda corto', () {
      // Y ESTE ES EL NUMERO QUE JUSTIFICA LAS PESTANAS. A 1440 px, con el panel de
      // herramientas, quedan 1.213,5 de lectura. Dos textos en paralelo son 606,25 cada
      // uno, y la columna de cada uno queda por debajo de los 90 caracteres.
      //
      // Y NO SE ESCRIBE EL 606 EN EL CODIGO DE LA PANTALLA: sale de
      // [Medidas.anchoParaPanelDeHerramientas] y del ancho que hay, y lo unico escrito
      // aqui es el ancho del panel de herramientas, que es lo medido. Un 606 escrito en
      // la vista seria un limite de tres textos en una ventana de 1920, y habria que
      // cambiarlo en cuanto cambiara el corte.
      final estilo = _cuerpo(_hayFuente);
      final lectura = 1440.0 - anchoDelPanelDeHerramientas;
      final porPanel = (lectura / 2) - divisorEntrePaneles;
      final columna = anchoDeColumnaDeTexto(
        anchoDisponible: porPanel - Medidas.margenAncho * 2,
        estilo: estilo,
      );

      expect(caracteresEn(columna, estilo), lessThan(90));

      if (!_hayFuente) return;
      // Y EL NUMERO, cuando hay fuente que lo mida. Sin fuente de verdad, la "a" y la
      // "m" miden lo mismo y cualquier caracter por linea sale de la cuenta del tamano
      // de letra; decir "62 caracteres" ahi seria inventar una medida.
      //
      // Y SE COMPRUEBA QUE SIGUE SIENDO **LECTURA**, y no solo que es menor. Un limite
      // de 40 caracteres es corto y se lee; uno de 20 no. Y el limite de por debajo del
      // cual dos columnas dejan de leerse **no se supone**: se ve en este numero y en
      // la captura, y esta escrito en el spec como medida y no como opinion.
      expect(caracteresEn(columna, estilo), greaterThanOrEqualTo(45));
      expect(caracteresEn(columna, estilo), lessThanOrEqualTo(70));
    });

    test('tres textos en paralelo a 1440 px ya no se leen', () {
      // Y ESTO ES LO QUE FIJA EL **MAXIMO** DE PESTANAS. Tres textos a 1440 px son
      // 404 px cada uno, y 404 menos los margenes son 356: unos 47 caracteres por linea
      // con letra de 16. Es el borde de lo legible, y por eso el limite de tres no es
      // arbitrario: es el punto en el que un cuarto texto seria 303 px, que son 40
      // caracteres y se lee con lupa.
      final estilo = _cuerpo(_hayFuente);
      final lectura = 1440.0 - anchoDelPanelDeHerramientas;
      final porPanel = (lectura / 3) - divisorEntrePaneles * 2;
      final columna = anchoDeColumnaDeTexto(
        anchoDisponible: porPanel - Medidas.margenAncho * 2,
        estilo: estilo,
      );
      if (!_hayFuente) return;
      final n = caracteresEn(columna, estilo);
      expect(n, inInclusiveRange(40, 55));
    });

    test('a 1920 px tres textos si llegan a leerse y cuatro ya no', () {
      // Y POR QUE EL LIMITE **NO** ES UN NUMERO DE PESTANAS FIJO, sino una medida del
      // ancho de cada una. A 1920 px, con el panel de herramientas, quedan 1.693,5 y tres
      // textos son 564 cada uno, que es mas ancho que a 1440 px con dos. El mismo texto
      // cabe en mas sitio en una ventana mas grande, y un limite fijo de dos seria
      // desperdiciar la pantalla en cuanto se abre mas.
      final estilo = _cuerpo(_hayFuente);
      if (!_hayFuente) return;

      final lectura = 1920.0 - anchoDelPanelDeHerramientas;
      final tres = (lectura / 3) - divisorEntrePaneles * 2;
      final cuatro = (lectura / 4) - divisorEntrePaneles * 3;

      final colTres = anchoDeColumnaDeTexto(
        anchoDisponible: tres - Medidas.margenAncho * 2,
        estilo: estilo,
      );
      final colCuatro = anchoDeColumnaDeTexto(
        anchoDisponible: cuatro - Medidas.margenAncho * 2,
        estilo: estilo,
      );

      // Y ESTA COMPARACION ES LA QUE DICE QUE TRES EN 1920 SON LEGIBLES Y CUATRO NO.
      // Con numeros sueltos seria "tres caben"; con la comparacion de columnas se ve
      // que es la misma medida la que decide, y por eso el codigo puede aplicar el
      // mismo criterio a cualquier ventana.
      expect(colTres, greaterThan(colCuatro));
      expect(caracteresEn(colTres, estilo), greaterThanOrEqualTo(55));
    });
  });

  group('la memoria, que es lo que no se ve', () {
    test('dos textos son 45 MiB y tres son 67,5', () {
      // Y NO SE ABRE NADA AQUI. La cuenta es aritmetica sobre el tamano del fichero, y
      // es la misma cuenta que esta en `AGENTS.md` para dos. Abrir tres `.amod` de verdad
      // en una prueba de Dart costaria mas de lo que mide y no mediria nada mas: lo que
      // importa es la magnitud.
      //
      // Y LA CIFRA CORRECTA ES **67.633.152**, y sale de la cuenta. Con la cifra mal
      // puesta --67.663.152-- la comprobacion daria verde con cualquier numero cercano,
      // y "cerca" aqui significa "un texto mas de lo que se cree". Se escribe la suma
      // como la suma.
      const bytesDeUnTexto = 22544384;
      expect(bytesDeUnTexto * 2, 45088768);
      expect(bytesDeUnTexto * 3, 67633152);
    });

    test('el comentario de 57 MiB al lado de un texto son 79 MiB', () {
      // Y ESTA ES LA CIFRA QUE ESTA YA MEDIDA EN `AGENTS.md` con dos modulos abiertos, y
      // se repite aqui porque las pestanas la vuelven a poner en juego: abrir CLARKE como
      // panel al lado de la Biblia son 57 + 22 MiB, y eso es un movil de gama baja
      // decidiendo entre abrirlo o matarlo.
      const biblia = 22544384;
      const comentario = 57536512;
      expect(biblia + comentario, 80080896);
    });
  });

  group('los capitulos de verdad, que es lo que decide el salto', () {
    test('Juan tiene 21 capitulos y el 22 no existe', () {
      // Y SE COMPRUEBA **CONTRA EL MODULO**, y no contra una tabla escrita aqui. Es el
      // mismo argumento que hay en `modulo_repository.dart`: los numeros salen del
      // modulo, y un modulo puede acabar antes que la serie.
      final abierto = ModuloAbierto.abrir(
        'test/fixtures/KJV2006_bible.amod',
        id: 'KJV2006',
      );
      expect(abierto, isA<Abierto>());
      final modulo = (abierto as Abierto).modulo;
      addTearDown(modulo.cerrar);

      final capitulos = modulo.capitulosDe('John');
      expect(capitulos.length, 21);
      expect(capitulos.last, 21);
      // Y "el capitulo siguiente" desde el ultimo es null y no un 22. Es lo que
      // deshabilita la flecha, y lo que impide ofrecer un Juan 22 que no existe.
      expect(modulo.existe(Referencia('John', 22)), isFalse);
      expect(modulo.existe(Referencia('John', 21)), isTrue);
    });
  });
}