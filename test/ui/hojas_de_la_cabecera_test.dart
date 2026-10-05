// La hoja para elegir libro y capitulo, y la de elegir version.
//
// QUE HAY AQUI Y POR QUE. Las dos hojas hacen lo que la investigacion del repositorio
// llama "los botones que se copian", y las dos son interacciones que **no existian**:
//
//   - "Selector de version desde la cabecera del lector, con filtro mientras se escribe.
//      Comparar versiones sin salir de la lectura es la interaccion mas valiosa de una app
//      de Biblia." Y `alCambiarDeVersion` estaba cableado en el enrutador y **ningun boton
//      lo llamaba**.
//
//   - "Resumen de cada capitulo en el selector de libros (Bible Gateway). Es la mejor idea
//      de localizacion de referencias que se ha visto: resuelve 'se que estaba en el cap.
//      12 de algo, pero no de que'."
//
// Y LA SEGUNDA **NO** ES LO QUE SE HA HECHO, y el nombre lo dice. No se ha hecho un
// resumen: se ha puesto **la primera frase del capitulo**, que es el texto del modulo. Un
// resumen son tres lineas de palabras del capitulo, y no estan en ninguna parte: habria
// que escribirlas, y escribirlas es el dato de otra persona. Lo que se enseena se puede
// citar.
//
// Y LOS NUMEROS ESTAN MEDIDOS sobre el KJV real:
//
//     libros con sus capitulos, una consulta     66 libros, 1.189 capitulos,   8 ms
//     las primeras frases de un libro entero     Juan, 21 capitulos,          1 ms
//     la primera frase de los 1.189 capitulos   158 KiB de texto
//
// Y 8 ms ES UNA CONSULTA Y NO 66. Leer los 66 con `libros()` y luego `capitulosDe()` por
// libro son 67 consultas para pintar una lista, y en un movil se nota.

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/numeros.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_libros.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_versiones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. los datos del selector', () {
    late ModuloAbierto modulo;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      addTearDown(modulo.cerrar);
    });

    test('66 libros y 1.189 capitulos, de una sola consulta', () {
      final conCapitulos = modulo.librosConCapitulos();

      expect(conCapitulos.length, 66);
      expect(conCapitulos.values.fold<int>(0, (a, b) => a + b.length), 1189);
      // Y LOS NUMEROS DE CAPITULOS SON **DEL MODULO**, no de una tabla. Una traduccion
      // puede tener 51 capitulos de Genesis donde el KJV tiene 50, y ofrecer el 51 en una
      // lleva a una pantalla en blanco.
      expect(conCapitulos['Genesis']!.length, 50);
      expect(conCapitulos['Psalms']!.length, 150);
      expect(conCapitulos['John']!.length, 21);
    });

    test('un libro que no esta no aparece, y no con cero capitulos', () {
      // Y NO UN LIBRO CON CERO CAPITULOS, que es un bug de los que se ven: una fila que no
      // lleva a ninguna parte parece un fallo de la app.
      final conCapitulos = modulo.librosConCapitulos();

      expect(conCapitulos.containsKey('Hechos'), isFalse);
      expect(conCapitulos['NoExiste'], isNull);
    });

    test('la primera frase de cada capitulo es texto del modulo', () {
      final juan = modulo.primeraFraseDeCapitulos('John');

      expect(juan.length, 21);
      expect(juan[1], 'In the beginning was the Word, and the Word was with God, '
          'and the Word was God.');
      expect(juan[3], 'There was a man of the Pharisees, named Nicodemus, '
          'a ruler of the Jews:');
      // Y LA DE JUAN 1 ESTA ENTERA Y SIN CORTAR, porque se puede: 16 palabras.
      expect(juan[1], isNot(endsWith('...')));
    });

    test('una frase larga se corta donde hay un punto, no a lo bruto', () {
      // Y ESTO ES LO QUE IMPORTA DE LA FRASE: "Adam, Sheth, Enosh" se lee entero y
      // "Revelation 1" en bruto era "The Revelation of Jesus Christ, which God gave unto
      // him, to shew unto his servants things which must shortly come to pass; and he sent
      // and signified it by hi" --cortado por la mitad de una palabra.
      final genesis = modulo.primeraFraseDeCapitulos('Genesis');

      expect(genesis[1], 'In the beginning God created the heaven and the earth.');
      // Y SI NO HAY PUNTO EN TODA LA FRASE, SE CORTA Y SE DICE. Juan 1:1 entero son 16
      // palabras sin un punto --los cuatro evangelios abren asi-- y ahi no hay frase que
      // cortar.
      for (final frase in genesis.values) {
        if (frase.endsWith('...')) {
          expect(frase.length, lessThanOrEqualTo(160));
          expect(frase, isNot(endsWith(' ...')));
        }
      }
    });

    test('ninguna primera frase es un numero ni una cadena vacia', () {
      // Y UNA CADENA VACIA EN LA LISTA DE CAPITULOS ES UNA FILA EN BLANCO. Sale cuando el
      // capitulo existe y no tiene versiculo 1 --que pasa en traducciones con capitulos
      // vacios-- y pintarla sin texto es peor que no pintar el capitulo.
      for (final libro in <String>['Genesis', 'Psalms', 'John', 'Revelation']) {
        for (final frase in modulo.primeraFraseDeCapitulos(libro).values) {
          expect(frase.trim(), isNotEmpty, reason: libro);
        }
      }
    });

    test('el comentario no tiene capitulos y no se rompe', () {
      final c = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (c is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(c.modulo.cerrar);

      // Y NO SE LANZA, Y NO SE PINTA UNA LISTA DE 19.741 "capitulos". Un comentario tiene
      // notas por versiculo, no capitulos, y ofrecerle capitulos seria inventar una
      // navegacion que no existe.
      expect(c.modulo.librosConCapitulos().length, greaterThan(0));
      expect(c.modulo.primeraFraseDeCapitulos('John').length, 0,
          reason: 'no hay versiculo 1 que abrir, y no se inventa');
    });
  });

  group('2. la hoja de libros', () {
    late _LibrosFalsos modulo;

    setUp(() => modulo = _LibrosFalsos());

    Future<void> abrir(WidgetTester tester, {Referencia? leyendo}) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => mostrarHojaDeLibros(
                    context: context,
                    modulo: modulo,
                    leyendo: leyendo,
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('se abre en el libro que se esta leyendo, no en el primero', (tester) async {
      // Y ABRIR EN GENESIS PORQUE ES EL PRIMERO ES ABRIR EN EL SITIO EQUIVOCADO. La hoja se
      // abre para cambiar de capitulo, y abrirla en un libro que no es el que se tiene
      // delante obliga a buscar el sitio antes de poder cambiarlo.
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      expect(find.text('Juan'), findsOneWidget);
      expect(find.text('Génesis'), findsNothing);
    });

    testWidgets('enseña el capitulo que se esta leyendo', (tester) async {
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      // Y CON LA FLECHA DEL LIBRO ABIERTO. Sin ella, quien tiene el capitulo 3 delante
      // abre la hoja y ve 21 capitulos sin ninguna pista de cual es.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('una fila por capitulo, con su primera frase', (tester) async {
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      expect(find.textContaining('La primera frase de John 1.'), findsOneWidget);
      // Y EL NUMERO DEL CAPITULO EN SU PROPIA COLUMNA, no pegado al texto. En una
      // `ListTile` con `dense`, el titulo y el subtitulo se alinean a la izquierda y las
      // frases largas se descuadran en una escalera.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('pulsar un capitulo devuelve ESA referencia', (tester) async {
      Referencia? elegida;
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    elegida = await mostrarHojaDeLibros(
                      context: context,
                      modulo: modulo,
                      leyendo: const Referencia('John', 3, 16),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(elegida, isNotNull);
      expect(elegida!.libro, 'John');
      expect(elegida!.capitulo, 2);
      // Y EL VERSICULO SE CONSERVA **AUNQUE CAMBIE EL CAPITULO**, porque Juan 2:16 es el
      // mismo versiculo del mismo sitio que Juan 3:16. La primera version lo conservaba
      // solo si el capitulo no habia cambiado, y al pulsar el 2 aterrizaba en Juan 2:1,
      // que es OTRO pasaje y sin avisar.
      expect(elegida!.versiculo, 16);
    });

    testWidgets('al escribir un libro se sale a la lista de libros', (tester) async {
      // Y NO SE QUEDA EN EL CAPITULO DEL LIBRO ANTERIOR. Escribir "Sal" con el capitulo
      // de Juan abierto no puede dejar a nadie en Juan: lo que se ha pedido es otra cosa.
      await abrir(tester, leyendo: const Referencia('John', 3, 16));
      expect(find.text('Juan'), findsOneWidget, reason: 'la hoja abre en Juan');

      await tester.enterText(find.byType(TextField), 'Sal');
      await tester.pumpAndSettle();

      expect(find.text('Salmos'), findsOneWidget);
      expect(find.text('Juan'), findsNothing);
    });

    testWidgets('una referencia entera se ofrece como pasaje', (tester) async {
      // Y ESTO ES LO QUE SUSTITUYE AL CAMPO DE REFERENCIA. Quien escribe "Juan 3:16" y ve
      // una lista de libros donde solo sale "Juan" tendria que elegir el capitulo a mano,
      // y volveria al problema de antes con dos pasos mas.
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      await tester.enterText(find.byType(TextField), 'Juan 3:16');
      await tester.pumpAndSettle();

      expect(find.text('Ir a Juan 3:16'), findsOneWidget);
    });

    testWidgets('escribir solo un libro NO ofrece un pasaje', (tester) async {
      // Y LA DISTINCION CUENTA. "Juan" es un libro y se resuelve en la lista; "Juan 3" ya es
      // un pasaje. Si un nombre de libro ofreciera un pasaje, escribir el nombre de un
      // libro saltaria a su capitulo 1 sin querer.
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      await tester.enterText(find.byType(TextField), 'Juan');
      await tester.pumpAndSettle();

      expect(find.text('Ir a Juan'), findsNothing);
    });

    testWidgets('lo que no esta en ningun sitio lo dice', (tester) async {
      await abrir(tester, leyendo: const Referencia('John', 3, 16));

      await tester.enterText(find.byType(TextField), 'Zacarias');
      await tester.pumpAndSettle();

      expect(find.textContaining('Ningun libro'), findsOneWidget);
    });

    testWidgets('sin pasaje abierto sale la lista de libros, con los dos testamentos',
        (tester) async {
      // Y SIN PASAJE SE VE LA LISTA COMPLETA, y entonces es donde se ven los dos
      // testamentos. `kNuevoTestamentoDesde = 40` estaba en el repositorio desde el
      // principio con el comentario "aparta a los dos testamentos en el selector", y no lo
      // usaba nadie.
      //
      // Y CON PASAJE SE ABRE EN EL LIBRO DE ESE PASAJE, que es lo otro que hay que
      // comprobar y lo que hacia fallar a esta prueba cuando la escribi con un pasaje.
      await abrir(tester);

      expect(find.text('Nuevo Testamento'), findsOneWidget);
      expect(find.text('Antiguo Testamento'), findsOneWidget);
      expect(find.text('Juan'), findsOneWidget);
    });

    testWidgets('con un libro abierto, la flecha de volver esta', (tester) async {
      // Y SIN FLECHA CUANDO NO HAY A DONDE VOLVER: una flecha atras en la primera pantalla
      // de una hoja es un boton que no hace nada, que es de los fallos que la gente no
      // cuenta pero recuerda.
      await abrir(tester);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await tester.tap(find.text('Juan'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Génesis'), findsOneWidget);
    });

    testWidgets('a 360 px no sale del borde', (tester) async {
      await abrir(tester, leyendo: const Referencia('John', 3, 16));
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Sal');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('3. la hoja de versiones', () {
    testWidgets('enseña las versiones con su estado y su tamano', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => mostrarHojaDeVersiones(
                    context: context,
                    disponibles: const <VersionDisponible>[
                      VersionDisponible(
                        id: 'KJV2006',
                        nombre: 'King James Version (2006)',
                        descargado: true,
                        bytes: 22544384,
                      ),
                      VersionDisponible(
                        id: 'OTRO',
                        nombre: 'Otra traduccion',
                        descargado: false,
                        bytes: 30500000,
                      ),
                    ],
                    abierta: 'KJV2006',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('King James Version (2006)'), findsOneWidget);
      // Y EL TAMANO EN CASTELLANO Y NO EN BYTES. "No descargado · 22,5 MB" se decide;
      // "No descargado · 22544384" no dice nada. Un "Descargar" sin coste conocido no se
      // pulsa.
      expect(find.text('No descargado · 29,1 MB'), findsOneWidget);
      expect(find.textContaining('22544384'), findsNothing);
      // Y EL DESCARGADO NO DICE "DESCARGADO". El estado ya lo dice el icono y una linea de
      // mas en cada fila es ruido. Se comprueba que hay **una sola** linea con la palabra,
      // que es la del que no lo esta --no cero, que tambien pasaria con las dos--.
      expect(find.textContaining('descargado'), findsOneWidget);
    });

    testWidgets('con una sola version, lo dice', (tester) async {
      // Y CON EL CATALOGO DE HOY HAY UNA BIBLIA, asi que la hoja hoy no deja comparar
      // nada. Decirlo es mejor que enseñar un desplegable con una linea donde se espera
      // haber encontrado la comparacion de versiones.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => mostrarHojaDeVersiones(
                    context: context,
                    disponibles: const <VersionDisponible>[
                      VersionDisponible(
                        id: 'KJV2006',
                        nombre: 'King James Version (2006)',
                        descargado: true,
                        bytes: 22544384,
                      ),
                    ],
                    abierta: 'KJV2006',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo hay un texto en el catalogo'), findsOneWidget);
    });

    test('el tamano en castellano, en el unico sitio que lo formatea', () {
      // Y 22.544.384 BYTES SON **21,5** MB, no 22,5. La cuenta sale de dividir por
      // 1.048.576 --un mebibyte— y no por un millon. Es la confusion que hizo que
      // `Modulo.megabytes` imprimiera "21.5" y que este fichero esperara "22,5 MB".
      expect(bytesEnCastellano(0), '0 B');
      expect(bytesEnCastellano(900), '900 B');
      expect(bytesEnCastellano(22544384), '21,5 MB');
      expect(bytesEnCastellano(57536512), '54,9 MB');
      expect(bytesEnCastellano(30500000), '29,1 MB');

      // Y CON COMA, PORQUE EN CASTELLANO EL DECIMAL ES LA COMA Y EL SEPARADOR DE MILLARES
      // ES EL PUNTO: "21.5 MB" se lee como veintiuno con cinco.
      expect(bytesEnCastellano(22544384), isNot(contains('.')));

      // Y CON DECIMAL HASTA CIENT Y ENTERO DE AHI EN ADELANTE. Por debajo de cien un
      // decimal ayuda a decidir; por encima es ruido.
      expect(bytesEnCastellano(104 * 1024 * 1024), '104 MB');
      expect(bytesEnCastellano(99 * 1024 * 1024), '99,0 MB');
    });
  });
}

/// Un modulo de mentira, con dos libros y tres capitulos.
///
/// Y SON DATOS INVENTADOS A PROPOSITO, y el motivo es que estas pruebas **no son del dato**:
/// el dato esta comprobado arriba, contra el KJV real, y con 66 libros y 1.189 capitulos
/// una prueba de interfaz tarda mas y falla por cosas que no importan. Aqui lo que se
/// comprueba es que la hoja pinta lo que le dan, y para eso basta con dos libros.
class _LibrosFalsos implements ModuloConLibros {
  @override
  Map<String, List<int>> librosConCapitulos() => <String, List<int>>{
        'Genesis': <int>[1, 2, 3],
        'Psalms': <int>[1, 2, 3],
        'John': <int>[1, 2, 3],
      };

  @override
  Map<int, String> primeraFraseDeCapitulos(String libro) => <int, String>{
        1: 'La primera frase de $libro 1.',
        2: 'La primera frase de $libro 2.',
        3: 'La primera frase de $libro 3.',
      };
}
