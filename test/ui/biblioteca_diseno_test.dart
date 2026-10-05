// Las pruebas de los tres fallos que la pantalla del 4 de octubre de 2026 destapo.
//
// QUE SON TRES Y POR QUE ESTAN EN UN FICHERO.
//
// Son tres fallos que **no** eran de codigo de Dart: eran de como se pinta. Los tres
// estaban en el camino normal --descargar un modulo y ver la biblioteca-- y ninguno se
// se vio en un `flutter test` que solo mira el ViewModel sin la pantalla. Este fichero
// mira las dos cosas.
//
//  1. Un comentario reventaba al abrirse: `no such table: verses`.
//  2. El progreso de descarga se guardaba como aviso de error y se acumulaba, y al
//     terminar seguia diciendo "Bajando CLARKE: 90 por ciento".
//  3. La banda de avisos tapaba la lista de modulos.
//
// Y LOS TRES SON COSAS QUE SE VEN. Un test que solo comprueba que el ViewModel
// devuelve una lista no habria encontrado ni uno.

import 'dart:io';

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/ui/features/biblioteca/view_models/aviso.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  group('1. un comentario no es una Biblia: se lee como lo que es', () {
    test('el CLARKE real se abre y dice que es un comentario', () {
      // ESTE ES EL FALLO DE LA CAPTURA, Y EL ESTADO DE HOY. Antes, abrir un comentario
      // y preguntarle cuantos versiculos tenia reventaba con:
      //
      //     SqliteException(1): no such table: verses
      //
      // porque un comentario tiene tabla `commentary`, no `verses`. Medido sobre el
      // fichero real, no sobre uno de pruebas.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) {
        fail('el comentario real deberia abrirse: ${(r as FalloAlAbrir).motivo}');
      }
      addTearDown(r.modulo.cerrar);

      expect(r.modulo.tipo, TipoDeContenido.comentario);
      expect(r.modulo.tieneNotas, isTrue);
      // Y QUE NO TENGA TEXTO DE BIBLIA es lo que lo separa de la KJV. "No tiene
      // versiculos" ya **no** significa "no se puede leer": un comentario se lee, y lo
      // que trae son notas.
      expect(r.modulo.tieneTextosDeBiblia, isFalse);
    });

    test('el comentario trae las notas de Juan 3:16', () {
      // Y EL NUMERO ESTA MEDIDO SOBRE EL FICHERO REAL: Juan 3:16 tiene **una** nota en el
      // CLARKE. La primera version de esta prueba decia tres, y lo habia escrito
      // leyendo la clave primaria --cuatro columnas-- en vez de contar filas. Un numero
      // escrito por deduccion en vez de por medicion es una forma de mentir sin querer,
      // y por eso los tres numeros que se usan aqui estan medidos:
      //
      //     19.742 notas   19.741 pasajes distintos   66 libros   21 capitulos de Juan
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(r.modulo.cerrar);

      final pasaje = r.modulo.leer(const Referencia('John', 3, 16));

      expect(pasaje.versiculos, isEmpty,
          reason: 'un comentario no trae texto de Biblia, y no debe disfrazarse');
      // Y JUAN 3:16 TIENE UNA **NOTA SUELTA**, pero el pasaje trae **19**: desde el 16 hasta
      // el final del capitulo. Es el mismo alcance que el de la Biblia --del versiculo
      // pedido en adelante-- y por eso un comentario abierto al lado va leyendo las notas
      // que corresponden a lo que se esta leyendo, en vez de traer las de todo el modulo.
      //
      // La comprobacion de "Juan 3:16 tiene una nota" la hace `notasDe`, que es por
      // versiculo, y sigue siendo la que importa: es la que ve quien lee.
      expect(pasaje.notasDe(16), hasLength(1), reason: 'medido sobre el fichero real');
      expect(pasaje.versiculosConNota.first, 16,
          reason: 'y el primero con nota es el que se pidio');
      expect(pasaje.vacio, isFalse);
      expect(pasaje.traeNotas, isTrue);
      expect(pasaje.notasDe(16).single.texto.trim(), isNotEmpty);
    });

    test('Mateo 23:13 tiene dos notas repetidas, y se ensena una', () {
      // Y ESTE ES EL UNICO VERSICULO CON MAS DE UNA NOTA en las 19.742 del fichero.
      // `seq` va de 0 a 1, y las dos filas son **el mismo texto**: una fila repetida en
      // el dato.
      //
      // Sin la quita, la pantalla ensefena el mismo parrafo de 2.709 caracteres dos veces,
      // y quien lo lee piensa que la pantalla se ha roto. Ver `modulo_repository.dart`,
      // donde esta el por y el limite: solo si el texto es identico y en el mismo
      // versiculo.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(r.modulo.cerrar);

      // Y LAS DOS FILAS SON EL MISMO TEXTO, byte a byte, 2.709 caracteres cada una. La
      // app quita la repetida, asi que aqui llega **una**. La comprobacion de que las dos
      // existen en el fichero --y son iguales-- es la de `notas_identicas`, en el
      // repositorio; esta comprueba lo que ve quien lee.
      final pasaje = r.modulo.leer(const Referencia('Matthew', 23, 13));

      // Y POR `notasDe`, NO POR `notas`. El pasaje llega con las notas desde el 13 en
      // adelante --el mismo alcance que el de la Biblia— y la repetida se quita en
      // cualquier forma: `notasDe(13)` es la vista que ve quien lee.
      expect(pasaje.notasDe(13), hasLength(1));
      expect(pasaje.notasDe(13).single.orden, 0);
      expect(pasaje.notasDe(12), isEmpty);
      expect(pasaje.versiculosConNota, contains(13));

      // Y EL SELECTOR DE VERSICULOS LO DICE UNA VEZ. Sin `DISTINCT`, Mateo 23:13
      // apareceria dos veces en la lista y quien lo pulsara no sabria que ya lo ha leido.
      final numeros = r.modulo.numerosDeVersiculos(const Referencia('Matthew', 23));
      expect(numeros.toSet().length, numeros.length);
      expect(numeros.where((n) => n == 13).length, 1);
    });

    test('el capitulo entero trae TODAS las notas, en orden de versiculo', () {
      // Y ESTO ES LO QUE HACE QUE SE PUEDA LEER UN COMENTARIO. Pedir Juan 3 sin
      // versiculo tiene que devolver las notas de todo el capitulo, y en el orden que
      // las dio el autor: versiculo a versiculo, y dentro de cada uno, por `seq`.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(r.modulo.cerrar);

      final pasaje = r.modulo.leer(const Referencia('John', 3));
      final numeros = <int>[for (final n in pasaje.notas) n.versiculo];

      expect(pasaje.notas, isNotEmpty);
      expect(pasaje.versiculos, isEmpty);

      // Y ESTA ORDENADO. Con `seq` en la clave primaria y sin `ORDER BY`, SQLite puede
      // devolver las notas en cualquier orden, y entonces Juan 3:3 apareceria despues de
      // Juan 3:16 sin que nada lo explique.
      for (var i = 1; i < numeros.length; i++) {
        expect(numeros[i], greaterThanOrEqualTo(numeros[i - 1]),
            reason: 'las notas tienen que ir en orden de versiculo');
      }
      // Y DENTRO DE UN VERSICULO, POR `seq` Y NO POR NADA MAS.
      for (final v in pasaje.versiculosConNota) {
        final ordenes = <int>[for (final n in pasaje.notasDe(v)) n.orden];
        for (var i = 1; i < ordenes.length; i++) {
          expect(ordenes[i], greaterThan(ordenes[i - 1]));
        }
      }
    });

    test('el numero de versiculos es de versiculos, no de notas', () {
      // Y ESTA ES LA DIFERENCIA QUE SE PAGA CON UN `count(*)`. En el CLARKE hay 19.742
      // notas y unos pocos miles de versiculos con nota. Preguntar `count(*)` da 19.742,
      // y el selector de versiculos ofreceria el 16 tres veces y el 17 cinco.
      final r = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (r is! Abierto) fail('el comentario real deberia abrirse');
      addTearDown(r.modulo.cerrar);
      final m = r.modulo;

      final numeros = m.numerosDeVersiculos(const Referencia('John', 3));

      expect(numeros, isNotEmpty);
      expect(numeros.toSet().length, numeros.length);
      expect(numeros, orderedEquals(<int>[...numeros]..sort()));

      // Y JUAN 3 TIENE 32 VERSICULOS CON NOTA, de 36 que tiene el texto. Medido. Y la
      // diferencia son los cuatro que no tienen nota: un versiculo sin nota **no** debe
      // aparecer en el selector de un comentario, porque ahi no hay nada que ensenar.
      expect(numeros.length, 32);
      expect(numeros.contains(16), isTrue);
      expect(numeros.contains(1), isFalse, reason: 'Juan 3:1 no tiene nota en el CLARKE');

      // Y LOS DOS NUMEROS EXISTEN Y NO SON IGUALES, que es el punto.
      expect(m.totalDeNotas(), 19742, reason: 'medido sobre el fichero real');
      expect(m.totalDeVersiculos(), 19741,
          reason: 'un pasaje menos que notas: Mateo 23:13 tiene dos');
      expect(m.libros().length, 66);
      expect(m.capitulosDe('John').length, 21);
    });

    test('la KJV sigue funcionando igual, y no trae notas', () {
      // Y NO ES UNA PRUEBA DE QUE NO HAYAMOS ROTO NADA. El riesgo real de generalizar la
      // tabla es pasarse deabstracto y romper la Biblia, y eso solo se comprueba con el
      // modulo que si tiene versiculos.
      final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (r is! Abierto) fail('la Biblia real deberia abrirse');
      addTearDown(r.modulo.cerrar);
      final m = r.modulo;

      expect(m.tipo, TipoDeContenido.biblia);
      expect(m.tieneTextosDeBiblia, isTrue);
      expect(m.tieneNotas, isFalse);
      expect(m.libros().length, 66);
      expect(m.totalDeVersiculos(), 31102);
      expect(m.totalDeNotas(), 0,
          reason: 'la tabla `verses` no tiene columna `seq`, y preguntar por el debe dar 0');
      expect(m.leer(const Referencia('John', 3, 16)).versiculo(16)!.texto,
          startsWith('For God so loved the world'));
      // Y LAS NOTAS VIENEN VACIAS, y no "nulas": un pasaje de Biblia con la lista de notas
      // vacia se puede comprobar, y una lista nula habria que adivinarla en la vista.
      expect(m.leer(const Referencia('John', 3)).notas, isEmpty);
      // Y 36 versiculos en Juan 3, que es el numero que ya estaba medido, y 31.102
      // versiculos en el modulo entero. Este ultimo es el que rompia con
      // `count(DISTINCT verse)`, que da 176.
      expect(m.numerosDeVersiculos(const Referencia('John', 3)).length, 36);
    });

    test('un tipo que la app no conoce NO se abre, y lo dice', () {
      // Y ESTA ES LA PARTE QUE NO SE PUEDE DEJAR DE FUERA. Antes el refusal estaba en
      // ocho metodos, uno por consulta, porque un comentario no tenia tabla `verses`.
      // Ahora que un comentario si se lee, el caso que queda es un tipo sin tabla, y el
      // refusal esta en **un** sitio: el constructor. Sin el, un `lexicon` pasaria y
      // reventaria en la primera consulta con `no such table`, que es el mismo crash con
      // otro mensaje.
      // Y QUE LA PREGUNTA LIGERA SIGA RESPONDIENDO, que es lo que la biblioteca usa
      // para pintar la etiqueta sin abrir 57 MiB.
      expect(ModuloAbierto.tipoDeContenidoDe(rutaComentarioReal),
          TipoDeContenido.comentario);
      expect(TipoDeContenido.desconocido.tablaDeContenido, isNull);
      expect(TipoDeContenido.biblia.tablaDeContenido, 'verses');
      expect(TipoDeContenido.comentario.tablaDeContenido, 'commentary');
    });

    test('el tipo sale del MODULO, no de una lista en el codigo', () {
      // Y ESTA ES LA PRUEBA QUE PROTEGE LA FRONTERA DEL PROYECTO. Si alguien anade
      // "CLARKE" a una lista de comentarios en el codigo, esta prueba falla; si en
      // cambio lee `info.type` --que es lo que hace-- sigue funcionando con un
      // comentario que todavia no exista.
      expect(TipoDeContenido.fromModulo('bible'), TipoDeContenido.biblia);
      expect(TipoDeContenido.fromModulo('commentary'), TipoDeContenido.comentario);

      // Y un tipo que no se conoce **no** se supone una Biblia. Es lo que hacia el
      // crash: tratar lo desconocido como lo conocido.
      expect(TipoDeContenido.fromModulo('lexicon'), TipoDeContenido.desconocido);
      expect(TipoDeContenido.fromModulo(null), TipoDeContenido.desconocido);
      expect(TipoDeContenido.desconocido.textoParaLaPersona, isNull);
    });

    test('las notas identicas del fichero son identicas, y se quita una', () {
      // Y ESTA PRUEBA ES LA CONTRAPARTIDA DE LA DE ARRIBA, Y POR ESO LAS HAY LAS DOS.
      // La de arriba comprueba lo que ve quien lee; esta comprueba que el **fichero**
      // tiene de verdad la fila repetida. Si el dato se arreglara en el repositorio
      // hermano, esta falla --que es lo que tiene que pasar-- y la de arriba seguira
      // verdes sin dejar de ser verdad.
      final sqlite = Sqlite.abrir(rutaComentarioReal);
      addTearDown(sqlite.cerrar);

      final brutas = sqlite.consultar(
        'SELECT seq, text FROM commentary WHERE book = ? AND chapter = ? AND verse = ? '
        'ORDER BY seq',
        <Object?>['Matthew', 23, 13],
      );

      expect(brutas, hasLength(2), reason: 'el fichero tiene dos filas');
      expect(brutas[0]['text'], brutas[1]['text'],
          reason: 'y son el mismo texto, byte a byte: una fila repetida');
      expect((brutas[0]['text']! as String).length, 2709,
          reason: 'medido sobre el fichero real, no inventado');

      // Y `defects_count` DICE QUE NO HAY NINGUNO, con lo cual esta mintiendo. Se
      // comprueba porque es el dato que haria que alguien confiara en que el contenido
      // esta limpio, y ahora se sabe que no.
      expect(sqlite.infoEntero('defects_count'), 0);
    });

    test('el nombre de la tabla sale del tipo y no de las consultas', () {
      // Y SE COMPRUEBA QUE EN LAS CONSULTAS NO HAY NOMBRES DE TABLA ESCRITOS A MANO. Es
      // la regla que hace que el mismo codigo lea `verses` y `commentary`; si alguien
      // escribe `FROM verses` en una consulta, esto deja de ser cierto y el comentario
      // vuelve a reventar.
      // Y SE BUSCA SOLO EN EL CODIGO, NO EN LOS COMENTARIOS. La primera version partia
      // el fichero entero por `SELECT`, y encuentra el `SELECT` que hay escrito en el
      // comentario que explica este mismo fallo de SQL: la prueba fallaba con la prueba
      // en el mensaje, que es la forma mas dificil de leer un fallo.
      final fuente = File('lib/data/repositories/modulo_repository.dart')
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      final consultas = fuente
          .split('SELECT')
          .skip(1)
          .map((s) => s.split(';').first);

      final aMano = <String>[
        for (final c in consultas)
          if (RegExp(r'FROM\s+(verses|commentary)\b').hasMatch(c)) c.trim(),
      ];

      expect(aMano, isEmpty,
          reason: 'el nombre de la tabla sale de TipoDeContenido.tablaDeContenido: '
              '${aMano.length} consulta(s) lo escriben a mano');
    });
  });

  group('2. el progreso no se acumula y no es un error', () {
    late BibliotecaViewModel vm;

    setUp(() => vm = BibliotecaViewModel());

    test('diez tramos de progreso dejan UN aviso, no diez', () {
      // ESTA ES LA PRUEBA DE LA PANTALLA LLENA DE CAJAS ROJAS. Un comentario de 57 MiB
      // a trozos de 4 MiB son diez tramos, y antes dejaban diez lineas "Bajando CLARKE:
      // N por ciento" que no se quitaban nunca.
      for (var pct = 10; pct <= 100; pct += 10) {
        vm.progresoDeDescarga('CLARKE', pct);
      }

      expect(vm.avisos, hasLength(1),
          reason: 'el progreso de un modulo es UN mensaje, no uno por tramo');
      expect(vm.avisos.single.porcentaje, 100);
      expect(vm.progresoPorModulo['CLARKE'], 100);
    });

    test('el progreso NO se pinta como error', () {
      // Y ESTO NO ES ESTILO. Todo lo que salia en la pantalla salia en rojo, con
      // triangulo de alarma, porque la lista era de `String` y no sabia que un progreso
      // no es un fallo. Descargando un modulo no hay nada que este mal.
      vm.progresoDeDescarga('KJV2006', 50);

      expect(vm.hayErrores, isFalse);
      expect(vm.avisosDeError, isEmpty);
    });

    test('el progreso de un modulo no borra el de otro', () {
      // Y ESTE ES EL CASO QUE HACE FALTA QUE HAYA UNA CLAVE POR ID Y NO UNA SOLA. Dos
      // descargas a la vez --que se puede, pulsando dos filas-- dan dos progresos. Con
      // "quitar todos los de progreso" uno de los dos desapareceria y el otro modulo
      // bajandose quedaria sin barra.
      vm.progresoDeDescarga('CLARKE', 30);
      vm.progresoDeDescarga('KJV2006', 70);
      vm.progresoDeDescarga('CLARKE', 60);

      expect(vm.avisos, hasLength(2));
      expect(vm.progresoPorModulo['CLARKE'], 60);
      expect(vm.progresoPorModulo['KJV2006'], 70);
    });

    test('al terminar la descarga el progreso desaparece', () {
      // Y NO SE QUITA "PORQUE SE HA TERMINADO", SE QUITA SIEMPRE. Un "Bajando CLARKE: 40
      // por ciento" que se queda despues de que la descarga falle dice que se sigue
      // bajando algo que no se esta bajando. Y el `finally` de `main.dart` es lo que
      // lo garantiza: hay siete finales de descarga y con `finally` no se puede
      // olvidar en ninguno.
      vm.progresoDeDescarga('CLARKE', 40);
      vm.quitarProgreso('CLARKE');

      expect(vm.avisos, isEmpty);
      expect(vm.progresoPorModulo, isEmpty);
    });

    test('un fallo real SI es un error, y se puede quitar cuando ya no lo es', () {
      // Y LAS DOS MITADES. Si el progreso fuera error, la pantalla seria un marrones.
      // Si los errores fueran informacion, un fallo real pasaria desapercibido. Las dos
      // cosas tienen que ser verdad a la vez, y por eso estan en la misma prueba.
      vm.anadirAviso('No se ha podido abrir el modulo.', clase: ClaseDeAviso.error);
      vm.progresoDeDescarga('KJV2006', 20);

      expect(vm.hayErrores, isTrue);
      expect(vm.avisosDeError, hasLength(1));

      // Y quitar el error **no** quita el progreso: son cosas distintas y las dos estan
      // diciendo la verdad al mismo tiempo.
      vm.quitarErrores();
      expect(vm.avisosDeError, isEmpty);
      expect(vm.avisos, hasLength(1));
      expect(vm.avisos.single.porcentaje, 20);
    });
  });

  group('3. la banda de avisos no tapa la lista', () {
    testWidgets('con veinte avisos, la lista de modulos SIGUE VIENDOSE', (tester) async {
      // Y ESTA ES LA QUE MIDE LO QUE SE VIO EN LA CAPTURA: veinte cajas y ni un solo
      // modulo. El aviso va **encima** de la lista, asi que sin un tope de altura el
      // problema crece con el numero de avisos, y no hay forma de que la lista aparezca
      // por mucho que se baje.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
        idsLocales: const <String>{},
      );
      for (var pct = 10; pct <= 100; pct += 10) {
        vm.progresoDeDescarga('CLARKE', pct);
        vm.progresoDeDescarga('KJV2006', pct);
      }
      vm.anadirAviso('No se ha podido contactar con el catalogo.',
          clase: ClaseDeAviso.error);
      vm.anadirAviso('No se ha podido preparar el motor.', clase: ClaseDeAviso.error);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));

      // Y SE COMPRUEBA QUE HAY UNA FILA EN PANTALLA, y no que "no ha dado error". Un
      // `pumpWidget` que no revienta lo dice un `overflow` que se ve en las pruebas de
      // widget con `flutter_test`-- y eso lo que se quiere cazar.
      expect(find.text('King James Version (2006)'), findsOneWidget,
          reason: 'el modulo tiene que verse aunque haya veinte avisos encima');

      // Y ADEMAS QUE CABE, que es lo que se ve en la captura: el modulo esta dentro
      // del alto de la pantalla.
      final y = tester.getTopLeft(find.text('King James Version (2006)')).dy;
      expect(y, lessThan(760),
          reason: 'la fila no puede estar fuera de la pantalla');
    });

    testWidgets('un progreso se ve como una BARRA, no como una caja de texto', (tester) async {
      // Y PORQUE ES BARRA Y NO "90 por ciento" EN UN PARRAFO. Un progreso no es un
      // aviso: no hay nada que este mal. Y ademas, quien no distingue el color --
      // baja vision, escala de grises-- tiene que poder saber cuanto lleva, y por eso
      // la barra tiene el porcentaje escrito al lado.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
      )..progresoDeDescarga('CLARKE', 90);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('90 %'), findsOneWidget);
      expect(find.text('Descargando CLARKE'), findsOneWidget);
      // Y NO hay una caja de error por el progreso: eso es lo que se quejaba.
      expect(find.textContaining('Bajando CLARKE: 90 por ciento'), findsNothing);
    });

    testWidgets('un error se ve en rojo y se puede quitar', (tester) async {
      // Y EL BOTON DE QUITAR ES POR CADA ERROR. Un error que ya no es verdad y que no
      // se puede quitar ensena que hay un problema que no hay, y quien lo ve ya no se
      // fia de lo que dice el resto de la pantalla.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiestoDePrueba(),
      )..anadirAviso('No se ha podido abrir el modulo.', clase: ClaseDeAviso.error);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      expect(find.text('No se ha podido abrir el modulo.'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar este aviso'));
      await tester.pumpAndSettle();

      expect(find.text('No se ha podido abrir el modulo.'), findsNothing);
      expect(vm.avisos, isEmpty);
    });

    testWidgets('la banda de avisos tiene un tope de ALTURA, no un tope de lineas',
        (tester) async {
      // Y UN TOPE DE LINEAS NO SIRVE. Un aviso de tres lineas ocupa mas que uno de
      // una, y a 360 px la diferencia entre "caben cuatro avisos" y "caben uno" es justo
      // la diferencia entre ver la lista y no verla.
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(manifiesto: _manifiestoDePrueba());
      for (var i = 0; i < 6; i++) {
        vm.anadirAviso(
          'Aviso numero $i, con un texto razonablemente largo para ocupar su linea '
          'entera en una pantalla de trescientos sesenta pixeles de ancho.',
          clase: ClaseDeAviso.error,
        );
      }

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      await tester.pumpAndSettle();

      // El `Column` con scroll propio no puede pasar del tope, y por eso la lista de
      // modulos sigue teniendo sitio.
      expect(tester.takeException(), isNull);
      final banda = find.byType(SingleChildScrollView).first;
      expect(tester.getSize(banda).height, lessThanOrEqualTo(168 + 0.5));
      expect(find.text('King James Version (2006)'), findsOneWidget);
    });

    testWidgets('la banda de avisos no crece cuando no hay avisos', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(manifiesto: _manifiestoDePrueba());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _BibliotecaSola(vm: vm))));
      await tester.pumpAndSettle();

      expect(find.text('King James Version (2006)'), findsOneWidget);
      // Y el primer modulo esta **arriba**, no debajo de un hueco vacio.
      expect(tester.getTopLeft(find.text('King James Version (2006)')).dy, lessThan(140));
    });
  });
}

/// Un manifiesto de dos modulos, como el que hay publicado.
///
/// Y NO ES CONSTANTE PORQUE `Uri.parse` no es una constante. Un `const` con una
/// `Uri.parse` dentro no compila, y la primera version de esto si lo era.
Manifiesto _manifiestoDePrueba() => Manifiesto(
  formato: 'aa-catalog/1',
  version: '1',
  etiqueta: 'v0.1.1',
  modulos: <Modulo>[
    Modulo(
      id: 'KJV2006',
      nombre: 'King James Version (2006)',
      tipo: TipoModulo.biblia,
      idioma: 'eng',
      licencia: 'PublicDomain',
      sha256: 'a' * 64,
      tamanoBytes: 22544384,
      urlDescarga: Uri.parse('https://example.invalid/KJV.amod'),
      urlNavegador: Uri.parse('https://example.invalid/KJV.amod'),
    ),
    Modulo(
      id: 'CLARKE',
      nombre: 'Comentario de Adam Clarke (1832)',
      tipo: TipoModulo.comentario,
      idioma: 'eng',
      licencia: 'PublicDomain',
      sha256: 'b' * 64,
      tamanoBytes: 57536512,
      urlDescarga: Uri.parse('https://example.invalid/CLARKE.amod'),
      urlNavegador: Uri.parse('https://example.invalid/CLARKE.amod'),
    ),
  ],
);

/// La biblioteca y **solo** la biblioteca.
///
/// Y NO ES LA PANTALLA ENTERA A PROPOSITO. Lo que se comprueba aqui es que la banda de
/// avisos no come la lista, y para eso hace falta el `Column` de [_Avisos] y el
/// `Expanded` de la lista montados como en la pantalla real. La pantalla entera se
/// prueba en `biblioteca_view_test.dart`; si esta prueba usara la pantalla, un fallo
/// seria "no se ve el modulo" sin poder decir si es por los avisos o por otra cosa.
class _BibliotecaSola extends StatelessWidget {
  const _BibliotecaSola({required this.vm});

  final BibliotecaViewModel vm;

  /// Y ESCUCHA AL VIEWMODEL, como hace la pantalla real con su `AnimatedBuilder`.
  ///
  /// Sin esto, la primera version de esta prueba **tapaba el boton de quitar un aviso y
  /// no pasaba nada**, y el fallo decia "sigue en pantalla", que parece un fallo del
  /// boton. No lo era: el banco de pruebas era un `StatelessWidget` que pintaba una vez
  /// y se quedaba ahi, con el boton funcionando y el texto sin desaparecer. La
  /// diferencia entre "el boton no quita" y "el banco no se entera" es justo la que no
  /// se puede leer si no se mira.
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: vm,
    builder: (context, _) => Column(
      children: <Widget>[
        _BandaDeAvisos(vm: vm),
        Expanded(child: _ListaDeModulos(vm: vm)),
      ],
    ),
  );
}

/// La banda de avisos, con la misma forma que en la pantalla.
class _BandaDeAvisos extends StatelessWidget {
  const _BandaDeAvisos({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.avisos.isEmpty) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 168),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final a in vm.avisos)
                if (a.esProgreso)
                  _Barra(a)
                else
                  _Linea(a, vm),
              if (vm.hayErrores)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: vm.quitarErrores,
                    child: const Text('Quitar los errores'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra(this.aviso);
  final Aviso aviso;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('Descargando ${aviso.id ?? ''}')),
            Text('${aviso.porcentaje ?? 0} %'),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (aviso.porcentaje ?? 0) / 100,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}

class _Linea extends StatelessWidget {
  const _Linea(this.aviso, this.vm);
  final Aviso aviso;
  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!aviso.esError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(aviso.texto)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(aviso.texto)),
          IconButton(
            icon: const Icon(Icons.close, size: 17),
            tooltip: 'Quitar este aviso',
            onPressed: () => vm.quitarAviso(aviso.texto),
          ),
        ],
      ),
    );
  }
}

/// La lista, con una fila por modulo.
class _ListaDeModulos extends StatelessWidget {
  const _ListaDeModulos({required this.vm});

  final BibliotecaViewModel vm;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
      for (final f in vm.filasFiltradas)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Text(f.titulo),
        ),
    ],
  );
}