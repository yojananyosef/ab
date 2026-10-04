// 7.7: la columna de texto, medida y no supuesta.
//
// ============================================================================
// POR QUE ESTAS PRUEBAS MIDEN Y NO COMPARAN CON UN NUMERO
// ============================================================================
//
// La comprobacion que hace la tarea es "a 1440 px el ancho de la columna no supera
// ese limite". "Ese limite" es lo que sale de [anchoDeNoventaCaracteres], asi que
// comparar el ancho con un numero fijo --660 px, pongamos-- seria comparar una
// medida con una suposicion y daria verde siempre.
//
// ============================================================================
// Y LA MEDIDA VA EN CARACTERES, QUE ES COMO ESTA ESCRITA LA TAREA
// ============================================================================
//
// "90 caracteres por linea" es una cantidad de caracteres, no de pixeles. Y medir en
// pixeles obligaria a decidir cual es el ancho *de un caracter*, y no hay uno: la "i"
// mide 4 px a 16 de letra y la "m" mide 14. Cualquier promedio es una decision, y
// cuanto mas extremo se elija, menos parecido sera el texto que lo represente.
//
// Asi que se mide en la unidad de la tarea: **cuantos caracteres caben**. Y se
// cuentan con el ancho medio de un texto de verdad, que es lo que ocupa una linea de
// verdad.
//
// Y EL TEXTO DE LA PRUEBA NO ES EL DE LA MEDIDA, A PROPOSITO. Si se midiera con la
// misma frase de Cervantes con la que se mide el limite, la comprobacion seria
// circular: siempre daria justo, porque el limite se ha calculado con ese mismo
// promedio. Aqui se cuenta con una frase distinta --Santa Teresa, de dominio publico--
// y el resultado puede no ser exactamente 90, y por eso se comprueba una banda y no
// un numero exacto.
//
// ============================================================================
// Y SIN FUENTE DE VERDAD ESTAS PRUEBAS NO COMPRUEBAN NADA
// ============================================================================
//
// En `flutter test` todas las letras miden lo mismo, asi que el limite de 90
// caracteres sale de 1440 px y en una pantalla de 1440 px nunca llega a mandar: la
// comprobacion daria verde sin medir. Ver `support/fuente.dart`.

import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/widgets/columna_de_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';

/// Si se ha podido cargar una fuente de verdad para medir.
var _hayFuente = false;

/// La clave del hijo de dentro de la columna, para poder medirlo.
///
/// NO SE MIDE EL `ColumnaDeTexto` CON `getSize`. Su primer descendiente con render
/// object es el `LayoutBuilder`, que ocupa **todo** el hueco que le da su padre --los
/// 1440 px-- y no lo que su hijo se ha limitado a. Medirlo daba 1440 con la columna
/// limitada a 683, y la comprobacion decia que la columna se pasaba cuando lo que se
/// pasaba era la medicion. Se mide el hijo, que es lo que tiene el ancho limitado.
const Key kHijo = Key('hijo-de-la-columna');

/// El estilo del cuerpo de texto del lector, el de verdad.
///
/// Con la familia de la fuente de pruebas puesta a mano **solo aqui**, porque
/// [anchoDeNoventaCaracteres] mide el estilo que recibe y en la pantalla ese estilo
/// hereda la familia del tema. Lo que se mide es la misma funcion con un estilo real;
/// que el tema lleve la familia es otra cosa, y se comprueba en `tema_test.dart`.
TextStyle _cuerpo({double tamano = 16}) =>
    TextStyle(fontFamily: _hayFuente ? kFamiliaDePrueba : null, fontSize: tamano, height: 1.7);

/// El ancho que ocupa un texto, con el motor que lo pinta.
double _anchoDe(String texto, TextStyle estilo) {
  final pintor = TextPainter(
    text: TextSpan(text: texto, style: estilo),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = pintor.width;
  pintor.dispose();
  return w;
}

/// Cuantos caracteres de [texto] caben en [ancho].
///
/// El ancho medio de un caracter de ese texto, y el ancho que hay, dividido. Es la
/// cuenta al reves de la que hace la medida, y con un texto distinto.
double _caracteresQueCaben(String texto, TextStyle estilo, double ancho) =>
    ancho / (_anchoDe(texto, estilo) / texto.runes.length);

/// Pone la pantalla del motor de pruebas al tamano que se quiere.
///
/// Y NO BASTA CON PONER EL `MediaQueryData`. El `MediaQuery` es un dato que la
/// pantalla lee; no cambia el hueco que le da su padre. La primera version de estas
/// pruebas ponia `MediaQueryData(size: Size(1440, 900))` y la columna seguia midiendo
/// 800 px --los 800 del motor de pruebas-- y la comprobacion de que a 1440 px la
/// columna no se pasaba daba falso, porque se estaba midiendo una pantalla de 800.
///
/// Es un fallo de la prueba y no de la pantalla, y solo se ve midiendo el ancho
/// resultante: si la prueba comprobara "que no hay excepciones", pasaria con 800 px y
/// con 1440.
Future<void> _pantallaDe(WidgetTester t, Size tamano) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

/// Una cadena de exactamente [n] caracteres.
///
/// Se construye de verdad y no se escribe a mano, porque una cadena de 90 caracteres
/// escrita a mano se comprueba a ojo y no con el codigo: es facil que sean 89, y
/// entonces la comprobacion de "caben 90" mide otra cosa.
String _caracteres(int n) => List<String>.filled(n, 'a').join();

/// Otro texto en castellano, que **no** es el de la medida.
///
/// De Santa Teresa de Jesus, y de dominio publico. Existe por el motivo que esta
/// esta comentado mas arriba: si fuera el mismo, la comprobacion seria circular.
const String _otroTexto =
    'Porque ya no hay cosa que me pueda dar placer, si no es hacer servicio a Dios, '
    'que es el mayor bien que conozco, y en quien esta no cabe otra cosa';

void main() {
  setUpAll(() async {
    _hayFuente = await cargarLaFuenteDePrueba();
  });

  group('la medida', () {
    test('90 caracteres salen mas anchos que 60, y mas estrechos que 120', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      final e = _cuerpo();
      final a60 = _anchoDe(_caracteres(60), e);
      final a90 = _anchoDe(_caracteres(90), e);
      final a120 = _anchoDe(_caracteres(120), e);

      expect(a60, lessThan(a90));
      expect(a90, lessThan(a120));
      // Y en proporcion, porque los caracteres tienen el mismo ancho uno a uno. Con
      // la fuente de pruebas --donde todas miden igual-- esto tambien daria 4/3, y por
      // eso esta comprobacion **no** demuestra que la fuente sea proporcional: esa es
      // la de mas abajo, y es la que importa.
      expect(a120 / a90, closeTo(4 / 3, 0.001));
    });

    test('la medida sale de las letras y no del numero de letras', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      // ESTA ES LA QUE DEMUESTRA QUE SE ESTA MEDIENDO.
      //
      // Si dos textos del mismo numero de caracteres dieran el mismo ancho, la
      // medida estaria contando caracteres y no midiendo letras, y entonces el limite
      // de 90 caracteres no seria un limite de nada. Con una fuente proporcional, las
      // "m" miden mas que las "i", y por eso este texto mide mas.
      final e = _cuerpo();
      final conAnchas = _anchoDe(_caracteres(90).replaceAll('a', 'm'), e);
      final conEstrechas = _anchoDe(_caracteres(90).replaceAll('a', 'i'), e);
      expect(conAnchas, greaterThan(conEstrechas));

      // Y con la fuente de pruebas las dos darian igual, que es justo lo que hace
      // necesaria la fuente de pruebas.
      final dePruebas = TextStyle(fontSize: 16, height: 1.7);
      expect(
        _anchoDe(_caracteres(90).replaceAll('a', 'm'), dePruebas),
        _anchoDe(_caracteres(90).replaceAll('a', 'i'), dePruebas),
        reason: 'la fuente de pruebas no es proporcional, y por eso no sirve para medir',
      );
    });

    test('con letra mas grande, la columna mide mas', () {
      // Y esto **no** es un fallo: el limite son 90 caracteres, no 90 caracteres con
      // la letra que tenia quien escribio el codigo. Quien necesita letra grande
      // necesita una columna mas ancha para leer los mismos 90.
      final pequena = anchoDeNoventaCaracteres(_cuerpo(tamano: 16));
      final grande = anchoDeNoventaCaracteres(_cuerpo(tamano: 32));
      expect(grande, greaterThan(pequena));
      expect(grande / pequena, closeTo(2, 0.05));
    });

    test('la medida es positiva y de un tamaño razonable', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      // Un techo de 1440 px a 16 px serian 130 caracteres, mas de lo que la tarea
      // pide; un minimo de 200 px serian 27, muy pocos. Los dos limites existen para
      // que el dia que el valor se descuadre se vea que se ha descuadrado, y no que
      // "algo cambio".
      final m = anchoDeNoventaCaracteres(_cuerpo());
      expect(m, greaterThan(200));
      expect(m, lessThan(1440));
      // Y el valor concreto, que con la fuente del SDK se puede mirar. No es una
      // asercion de un numero exacto --que se descuadra con cualquier cambio de
      // fuente-- sino una banda: entre 55 y 100 caracteres equivalentemente, que es
      // lo que cabe de verdad con letra de 16.
      expect(_caracteresQueCaben(_otroTexto, _cuerpo(), m), inInclusiveRange(55, 100));
    });
  });

  group('la columna segun la pantalla', () {
    test('a 360 px manda la pantalla, no el limite de caracteres', () {
      // Un movil de 360 px con letra de 16 px: el ancho sale de restar los margenes.
      // Los caracteres que caben son unos 45 y no 90, y eso es lo que hay. La prueba
      // **no** exige 90 aqui, porque exigirlo seria pedir letra de 7 px.
      final disponible = 360 - Medidas.margenEstrecho * 2;
      final ancho = anchoDeColumnaDeTexto(anchoDisponible: disponible, estilo: _cuerpo());
      expect(ancho, disponible);
      expect(ancho, lessThan(anchoDeNoventaCaracteres(_cuerpo())));
    });

    test('a 1440 px manda el limite de caracteres, no la pantalla', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      final ancho = anchoDeColumnaDeTexto(
        anchoDisponible: 1440 - Medidas.margenAncho * 2,
        estilo: _cuerpo(),
      );
      expect(ancho, anchoDeNoventaCaracteres(_cuerpo()));
      expect(ancho, lessThan(1440 - Medidas.margenAncho * 2));
    });

    test('7.7 a 1440 px caben 90 caracteres de verdad, y no 200', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      // ESTA ES LA COMPROBACION QUE MASA DE LA TAREA.
      //
      // Con el texto de Santa Teresa, que no es el de la medida, para que no sea
      // circular. Y con un margen, porque el promedio de un texto y el promedio de
      // otro no son el mismo: lo que se comprueba es el orden de magnitud, que es lo
      // que significa "90 caracteres".
      final estilo = _cuerpo();
      final ancho = anchoDeColumnaDeTexto(
        anchoDisponible: 1440 - Medidas.margenAncho * 2,
        estilo: estilo,
      );
      final caben = _caracteresQueCaben(_otroTexto, estilo, ancho);

      expect(caben, greaterThanOrEqualTo(kCaracteresPorLinea),
          reason: 'en la columna de $ancho caben ${caben.round()} caracteres');
      expect(caben, lessThan(110),
          reason: 'si caben 110, el limite de $kCaracteresPorLinea no esta limitando');
    });

    test('con letra grande, 90 caracteres siguen cabiendo a 1440 px', () {
      if (!_hayFuente) return saltarSiNoHayFuente();
      // El limite es de caracteres, no de pixeles. Con letra al 200 por ciento la
      // columna crece, y por eso sigue cabiendo lo mismo.
      final estilo = _cuerpo(tamano: 32);
      final ancho = anchoDeColumnaDeTexto(
        anchoDisponible: 1440 - Medidas.margenAncho * 2,
        estilo: estilo,
      );
      expect(_caracteresQueCaben(_otroTexto, estilo, ancho),
          greaterThanOrEqualTo(kCaracteresPorLinea));
    });

    test('con letra grande en un movil de 360, manda la pantalla y no se sale', () {
      // Aqui no caben 90 caracteres y no se pueden meter. Lo que **no** puede pasar es
      // que la columna mida mas que la pantalla, que en un movil es texto que se sale
      // por la derecha.
      final disponible = 360 - Medidas.margenEstrecho * 2;
      final ancho = anchoDeColumnaDeTexto(
        anchoDisponible: disponible,
        estilo: _cuerpo(tamano: 28),
      );
      expect(ancho, disponible);
    });

    test('una ventana de 120 px no lanza, y da un minimo', () {
      // Una ventana de escritorio se puede reducir a 120 px. Sin el minimo, el ancho
      // sale negativo y un `ConstrainedBox` con ancho negativo lanza: una excepcion en
      // pantalla por una ventana muy estrecha.
      final ancho = anchoDeColumnaDeTexto(anchoDisponible: 10, estilo: _cuerpo());
      expect(ancho, Medidas.anchoMinimoDeColumna);
      expect(ancho, greaterThan(0));
    });

    test('la columna nunca es mas ancha que lo disponible', () {
      // Con cualquier tamano de letra y cualquier ancho de pantalla.
      for (final ancho in <double>[120, 320, 360, 480, 600, 768, 1024, 1440, 2560]) {
        for (final letra in <double>[12, 16, 20, 28, 48]) {
          final d = ancho - Medidas.margenPara(ancho) * 2;
          final resultado =
              anchoDeColumnaDeTexto(anchoDisponible: d, estilo: _cuerpo(tamano: letra));
          expect(
            resultado,
            lessThanOrEqualTo(d.clamp(Medidas.anchoMinimoDeColumna, double.infinity)),
            reason: 'pantalla de $ancho con letra $letra dio $resultado de $d',
          );
        }
      }
    });
  });

  group('la columna dibujada', () {
    testWidgets('a 1440 px la columna dibujada mide lo que dice la medida', (t) async {
      if (!_hayFuente) return saltarSiNoHayFuente();
      final estilo = _cuerpo();
      final limite = anchoDeNoventaCaracteres(estilo);
      await _pantallaDe(t, const Size(1440, 900));

      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1440, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColumnaDeTexto(
            estilo: estilo,
            hijo: const SizedBox(key: kHijo, width: double.infinity, height: 10),
          ),
        ),
      ));

      final ancho = t.getSize(find.byKey(kHijo)).width;
      expect(ancho, lessThanOrEqualTo(limite));
      expect(ancho, closeTo(limite, 0.5));
    });

    testWidgets('a 1440 px la columna esta CENTRADA, no pegada a la izquierda',
        (t) async {
      // Sin centrar, el texto de Juan se pegaria a la izquierda con 700 px de blanco a
      // la derecha, y quien lee tiene que mover la cabeza del final de una linea al
      // principio de la siguiente. Eso es lo que hace que se pierda el sitio, y no
      // tiene nada que ver con lo que se lee.
      await _pantallaDe(t, const Size(1440, 900));
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1440, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColumnaDeTexto(
            estilo: _cuerpo(),
            hijo: const SizedBox(key: kHijo, width: double.infinity, height: 10),
          ),
        ),
      ));

      final caja = t.getRect(find.byKey(kHijo));
      final margenIzquierdo = caja.left;
      final margenDerecho = 1440 - caja.right;
      expect(margenIzquierdo, closeTo(margenDerecho, 0.5),
          reason: 'izquierda $margenIzquierdo, derecha $margenDerecho');
      expect(margenIzquierdo, greaterThan(200),
          reason: 'si no hay margen a los lados, no esta centrada');
    });

    testWidgets('a 360 px la columna es la pantalla menos los margenes', (t) async {
      await _pantallaDe(t, const Size(360, 640));
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(360, 640)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColumnaDeTexto(
            estilo: _cuerpo(),
            hijo: const SizedBox(key: kHijo, width: double.infinity, height: 10),
          ),
        ),
      ));
      final ancho = t.getSize(find.byKey(kHijo)).width;
      expect(ancho, 360 - Medidas.margenEstrecho * 2);
    });
  });
}
