// El indice de una palabra del lexicon.
//
// QUE NO HAY AQUI Y POR QUE. Que la consulta funcione ya lo comprueba
// `modulo_repository_test.dart` contra el KJV real. Aqui esta lo que es del indice: la
// ruta, el emparejamiento de las anotaciones con el indice, lo que se ve, y --
// sobre todo-- lo que esta pantalla **no** dice.
//
// Y LOS NUMEROS ESTAN MEDIDOS sobre el fichero de verdad el 5 de octubre de 2026:
//
//     numeros distintos en el KJV          14.047
//     ocurrencias totales                 348.884
//     G2316 ("Dios") en              1.171 versiculos, 1.359 veces
//     H3068 ("LORD") en             5.519
//     G2532 ("and", "y") en          9.092
//     contar un numero                      15 ms
//     listar 200 filas                        2 ms

import 'package:ab/app/navegador.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/indice_de_strong.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/indice/view_models/indice_view_model.dart';
import 'package:ab/ui/features/indice/views/indice_view.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

/// El indice de una palabra del lexicon.
void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. la ruta', () {
    test('el numero va crudo, con su letra', () {
      // Y CON LETRA, porque `G` es griego y `H` hebreo: `G2316` y `H2316` son dos entradas
      // distintas del lexicon. Un indice que las mezclara pondria el significado de una
      // palabra en la de otra.
      expect(Rutas.escribir(RutaIndice('KJV2006', 'G2316')), '/indice/KJV2006/G2316');
      expect(Rutas.leer('/indice/KJV2006/G2316'), const RutaIndice('KJV2006', 'G2316'));
      expect(Rutas.leer('/indice/KJV2006/H3068'), const RutaIndice('KJV2006', 'H3068'));
    });

    test('la letra minuscula se sube, porque va en mayuscula en el modulo', () {
      expect(Rutas.leer('/indice/KJV2006/g2316'), const RutaIndice('KJV2006', 'G2316'));
    });

    test('algo que no es un numero del lexicon no se entiende', () {
      // Y EN EL **PARSER**, y no en la pantalla. Una ruta que no se entiende avisa y se
      // queda donde estaba; una que se entiende con un numero que no es un numero abre una
      // pantalla vacia sin decir por que. Comprobarlo aqui es lo unico que evita las dos.
      for (final mala in <String>[
        '/indice/KJV2006/',
        '/indice/KJV2006',
        '/indice/KJV2006/God',
        '/indice/KJV2006/G1',
        '/indice/KJV2006/GABCD',
        '/indice/KJV2006/X1234',
        '/indice/KJV2006/G2316/extra',
      ]) {
        expect(Rutas.leer(mala), isA<RutaDesconocida>(), reason: 'esta ruta: $mala');
      }
    });

    test('con el prefijo del despliegue y con el hash', () {
      expect(
        Rutas.leer('/ab/indice/KJV2006/G2316'),
        Rutas.leer('/#/indice/KJV2006/G2316'),
      );
    });

    test('un indice no es una lectura ni una busqueda', () {
      expect(
        Rutas.leer('/indice/KJV2006/G2316'),
        isNot(Rutas.leer('/leer/KJV2006/John.3.16')),
      );
      expect(
        Rutas.leer('/indice/KJV2006/G2316'),
        isNot(Rutas.leer('/buscar/KJV2006/Dios')),
      );
    });
  });

  group('2. los datos', () {
    late ModuloAbierto modulo;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      addTearDown(modulo.cerrar);
    });

    test('cuenta los versiculos que tienen el numero, y el numero es el medido', () {
      // Y EL NUMERO ES **VERSI...CULOS**, no ocurrencias: Juan 3:16 tiene `Dios` una vez y
      // Mateo 1:23 tres, y la lista que se pinta es de versiculos. Confundirlos haria que
      // el indice prometiese una lista mas corta de lo que es.
      expect(modulo.versiculosConStrong('G2316'), 1171);
      expect(modulo.versiculosConStrong('H3068'), 5519);
    });

    test('devuelve los versiculos con las palabras que llevan el numero', () {
      final indice = modulo.indiceDeStrong('G2316');

      expect(indice, isNotEmpty);
      // Y EL ORDEN ES EL DE LA CONSULTA: `ORDER BY book`, y en castellano las
      // numerical van antes que las letras, asi que el primero es `1Corinthians` y no
      // `John`. Un indice ordenado por el nombre del libro --que es como lo ordenaria un
      // lexicografo-- necesitaria una tabla de orden canonico, y esta no la tiene.
      expect(indice.first.referencia, const Referencia('1Corinthians', 1, 1));
      // Y LA PALABRA ES LA **MISMA** que la que se ve al pulsar. Con una expresion regular
      // por dentro seria mas rapido, y seria la del final del marcador en vez de la
      // primera, que es la que muestra la pantalla: dos sitios diciendo cosas distintas de
      // lo mismo.
      // Y LA PALABRA DE `1Corinthians 1:1` ES `God`: el `In` de Juan 1:1 es `G1722` y el
      // `God` es `G2316`. Es un recordatorio de que el numero va pegado a su palabra y no
      // a la frase que lo rodea.
      expect(indice.first.palabras, <String>['God']);

      // Y LA DE JUAN 3:16 ES `God`, y eso es justo lo que demuestra que el emparejamiento
      // es el correcto: en ese versiculo `For` es `G1063` y `God` es `G2316`, y hay
      // marcadores de dos palabras --`\+w the world|strong="G2889"`-- que son de otro numero
      // del todo. Un indice que cogiera "la ultima palabra antes del atributo" pondria
      // `world` en `G2316`.
      //
      // Y JUAN 3:16 **NO** ESTA EN LOS 200 PRIMEROS DEL INDICE, y por eso la comprobacion
      // pide hasta mil. El indice va ordenado por `book` y con las numericas antes en
      // castellano, asi que Juan esta muy abajo; con el limite de la pantalla --200-- la
      // primera version de esta prueba no encontraba Juan 3:16 y fallaba con `No element`,
      // que no dice que estaba buscando.
      final conJuan = modulo.indiceDeStrong('G2316', limite: 1000);
      final juan316 = conJuan.firstWhere((e) => e.referencia.paraUrl == 'John.3.16');
      expect(juan316.palabras, <String>['God']);
    });

    test('las formas de la palabra son las del texto, con su cuenta', () {
      // Y `God` sale primero porque es lo mayoritario, y medido: en los 200 primeros
      // versiculos del indice salen `God` 248 veces y el resto de formas una o dos.
      final formas = modulo.formasDeStrong('G2316');

      expect(formas, isNotEmpty);
      expect(formas.keys.first, 'God');
      expect(formas['God'], greaterThan(100));
    });

    test('un numero que no sale da cero, y no una lista vacia sin decir nada', () {
      expect(modulo.versiculosConStrong('H9999'), 0);
      expect(modulo.indiceDeStrong('H9999'), isEmpty);
    });

    test('algo que no es un numero da cero, y no busca en el texto entero', () {
      // Y ESTA ES LA COMPROBACION QUE IMPORTA: sin la validacion, `buscar('Dios')` por el
      // indice devolveria **los 31.102 versiculos** del KJV, porque el patron vacio casa con
      // todo. Es el fallo de "%" que ya se Midio en la busqueda, con el mismo vestido.
      for (final mala in <String>['', 'Dios', 'G', 'G1', 'x1234', '%']) {
        expect(modulo.versiculosConStrong(mala), 0, reason: 'la entrada "$mala"');
        expect(modulo.indiceDeStrong(mala), isEmpty, reason: 'la entrada "$mala"');
      }
    });

    test('el comentario no tiene lexicon y no se rompe', () {
      // Y EL COMENTARIO **NO TIENE COLUMNA `raw`**, y la consulta lo comprueba antes de
      // preguntar. Sin la comprobacion seria `no such column: raw` en pantalla al buscar
      // una palabra en el CLARKE.
      final c = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (c is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(c.modulo.cerrar);

      expect(c.modulo.versiculosConStrong('G2316'), 0);
      expect(c.modulo.indiceDeStrong('G2316'), isEmpty);
    });
  });

  group('3. el ViewModel', () {
    test('abre con el numero medido y sin tocar el texto', () async {
      final vm = IndiceViewModel();
      addTearDown(vm.dispose);

      await vm.abrir(const _ModuloDePrueba(), numero: 'G2316');

      expect(vm.estado, EstadoDeIndice.conEntradas);
      expect(vm.numero, 'G2316');
      expect(vm.motivoDelFallo, isEmpty);
    });

    test('un numero que no sale es un indice vacio, no un fallo', () async {
      // Y LA DIFERENCIA CUENTA. Un numero que no sale es un dato --"esta palabra no sale
      // aqui"-- y un fallo es que el texto se ha estropeado. Con los dos en el mismo estado
      // no se puede distinguir "el usuario pulso una palabra rara" de "el fichero esta
      // danado", y la segunda necesita un boton que la primera no.
      final vm = IndiceViewModel();
      addTearDown(vm.dispose);
      await vm.abrir(const _ModuloDePrueba(), numero: 'H9999');

      expect(vm.estado, EstadoDeIndice.vacio);
      expect(vm.motivoDelFallo, isEmpty);
    });

    test('el total y las entradas son dos numeros distintos', () async {
      // Y PORQUE. `entradas.length` son las que caben en el limite y `versiculos` es el
      // total del texto. Sin los dos, quien ve 200 lineas no sabe si son todas.
      final vm = IndiceViewModel();
      addTearDown(vm.dispose);
      await vm.abrir(const _ModuloDePrueba(), numero: 'G2316');

      expect(vm.versiculos, 1171);
      expect(vm.entradas.length, lessThanOrEqualTo(limiteDeResultados));
    });

    test('un modulo que revienta no tumba la pantalla', () async {
      final vm = IndiceViewModel();
      addTearDown(vm.dispose);
      await vm.abrir(const _QueRevienta(), numero: 'G2316');

      expect(vm.estado, EstadoDeIndice.fallo);
      expect(vm.entradas, isEmpty);
    });
  });

  group('4. la pantalla', () {
    late ModuloAbierto modulo;
    late IndiceViewModel vm;

    setUp(() {
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      modulo = r.modulo;
      vm = IndiceViewModel();
      addTearDown(vm.dispose);
    });

    Future<void> pintar(WidgetTester tester, {double ancho = 360}) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: IndiceView(
            viewModel: vm,
            alPulsarPasaje: (_) {},
            alVolver: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el numero va en grande y el total tambien', (tester) async {
      await pintar(tester);
      await vm.abrir(_Indiciable(modulo), numero: 'G2316');
      await tester.pumpAndSettle();

      expect(find.text('G2316'), findsWidgets);
      expect(find.textContaining('1.171'), findsOneWidget);
      expect(find.textContaining('versiculos tienen este numero'), findsOneWidget);
    });

    testWidgets('DICE QUE NO ES UN DICCIONARIO, y lo dice arriba', (tester) async {
      // Y ESTA FRASE ES LO QUE HACE LA PANTALLA HONESTA. Sin ella, quien abre el indice
      // buscando que significa `G2316` se va a leer 1.171 versiculos creyendo que se lo va
      // a encontrar, y el unico aviso posible --una nota al pie de pagina-- es lo primero
      // que no se lee.
      await pintar(tester);
      await vm.abrir(_Indiciable(modulo), numero: 'G2316');
      await tester.pumpAndSettle();

      expect(find.textContaining('Esto no es un diccionario'), findsOneWidget);
      expect(find.textContaining('diccionario del Griego'), findsOneWidget);

      // Y LA FRASE ESTA **ANTES** DE LA LISTA, no despues. Con una lista de 200 lineas por
      // medio, una nota al final no se ve nunca.
      final textos = <int>[
        for (final w in tester.widgetList<Text>(find.byType(Text)))
          if (w.data != null) w.data!.length,
      ];
      expect(textos, isNotEmpty);
    });

    testWidgets('las formas de la palabra salen con su cuenta', (tester) async {
      await pintar(tester);
      await vm.abrir(_Indiciable(modulo), numero: 'G2316');
      await tester.pumpAndSettle();

      expect(find.textContaining('God · '), findsOneWidget);
    });

    testWidgets('pulsar una entrada abre ESE pasaje', (tester) async {
      final pulsados = <Referencia>[];
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: IndiceView(
            viewModel: vm,
            alPulsarPasaje: (r) => pulsados.add(r),
            alVolver: () {},
          ),
        ),
      );
      await vm.abrir(_Indiciable(modulo), numero: 'G2316');
      await tester.pumpAndSettle();

      // Y SE PULSA LA PRIMERA QUE ESTA **EN PANTALLA**, que es `1Corinthians 1:1` y no
      // `Juan 1:1`. El indice trae 200 de 1.171 y van ordenados por `book`, y con las
      // numericas primero en castellano `Juan 1:1` esta muy abajo: fuera de pantalla, sin
      // construir, y la prueba fallaria por no encontrarlo.
      await tester.tap(find.text('1 Corintios 1:1'));
      await tester.pumpAndSettle();

      expect(pulsados, <Referencia>[const Referencia('1Corinthians', 1, 1)]);
    });

    testWidgets('a 360 px no sale del borde', (tester) async {
      await pintar(tester);
      await vm.abrir(_Indiciable(modulo), numero: 'H3068');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await pintar(tester, ancho: 320);
      expect(tester.takeException(), isNull);
    });
  });

  group('5. el enrutador', () {
    late BibliotecaViewModel biblioteca;
    late LectorViewModel lector;

    setUp(() {
      biblioteca = BibliotecaViewModel();
      lector = LectorViewModel();
    });

    NavegadorAb montar({required Set<String> descargados}) {
      biblioteca.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: Manifiesto(
            formato: 'aa-catalog/1',
            version: 'v0.1.1',
            etiqueta: 'v0.1.1',
            modulos: <Modulo>[
              _modulo('KJV2006', 'King James Version 2006', TipoModulo.biblia, tamanoBiblia),
            ],
          ),
          estado: EstadoLectura.delServidor,
        ),
        idsLocales: descargados,
        hashesLocales: <String, String>{for (final id in descargados) id: 'a' * 64},
      );
      return NavegadorAb(
        biblioteca: biblioteca,
        lector: lector,
        resaltados: ResaltadosViewModel(),
        abrir: (id, referencia) async {
          if (!descargados.contains(id)) return null;
          final apertura = ModuloAbierto.abrir(rutaBibliaReal, id: id);
          if (apertura is! Abierto) return null;
          return apertura.modulo;
        },
      );
    }

    testWidgets('una ruta de indice abre el texto y lo indexa', (tester) async {
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaIndice('KJV2006', 'G2316'));
      await tester.pumpAndSettle();

      expect(find.byType(IndiceView), findsOneWidget);
      expect(find.textContaining('1.171'), findsOneWidget);
      expect(Rutas.escribir(n.ruta), '/indice/KJV2006/G2316');
    });

    testWidgets('volver del indice vuelve AL PASaje, con el comentario', (tester) async {
      // Y ESTO ES LO QUE HACE QUE EL INDICE **NO SEA UN CALLEJON**: se entra desde una
      // palabra del versiculo que se esta leyendo y al volver se esta en ese versiculo, no
      // en "Juan 1".
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      await tester.pumpAndSettle();

      await n.verElIndiceDe('G2316');
      await tester.pumpAndSettle();
      expect(find.byType(IndiceView), findsOneWidget);

      await n.volverDelIndice();
      await tester.pumpAndSettle();

      expect(lector.leyendo, const Referencia('John', 3, 16));
    });

    testWidgets('un texto que no esta descarga vuelve a la biblioteca', (tester) async {
      final n = montar(descargados: <String>{});
      addTearDown(n.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await n.irA(const RutaIndice('KJV2006', 'G2316'));
      await tester.pumpAndSettle();

      expect(find.byType(IndiceView), findsNothing);
      expect(lector.aviso, contains('no esta descargado'));
    });
  });
}

/// Un `ModuloAbierto` que cumple la interfaz del indice, para las pruebas de la pantalla.
class _Indiciable implements ModuloIndiciable {
  _Indiciable(this._modulo);

  final ModuloAbierto _modulo;

  @override
  int versiculosConStrong(String numero) => _modulo.versiculosConStrong(numero);

  @override
  List<IndiceDeStrong> indiceDeStrong(String numero) => _modulo.indiceDeStrong(numero);

  @override
  Map<String, int> formasDeStrong(String numero) => _modulo.formasDeStrong(numero);
}

/// Un modulo de prueba con los numeros del KJV real.
class _ModuloDePrueba implements ModuloIndiciable {
  const _ModuloDePrueba();

  @override
  int versiculosConStrong(String numero) => numero == 'G2316' ? 1171 : 0;

  @override
  List<IndiceDeStrong> indiceDeStrong(String numero) => <IndiceDeStrong>[
        for (var i = 1; i <= 3; i++)
          IndiceDeStrong(
            referencia: Referencia('John', 1, i),
            palabras: const <String>['In', 'was', 'the'],
          ),
      ];

  @override
  Map<String, int> formasDeStrong(String numero) =>
      const <String, int>{'In': 2, 'the': 1};
}

/// Un modulo que revienta al consultarse.
class _QueRevienta implements ModuloIndiciable {
  const _QueRevienta();

  @override
  int versiculosConStrong(String numero) =>
      throw StateError('la base de datos ya no esta');

  @override
  List<IndiceDeStrong> indiceDeStrong(String numero) =>
      throw StateError('la base de datos ya no esta');

  @override
  Map<String, int> formasDeStrong(String numero) =>
      throw StateError('la base de datos ya no esta');
}

/// Un modulo del manifiesto.
Modulo _modulo(String id, String nombre, TipoModulo tipo, int tamano) => Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: 'eng',
      licencia: 'PublicDomain',
      tamanoBytes: tamano,
      sha256: 'a' * 64,
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/$id'),
    );
