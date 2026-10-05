// Leer el versiculo CON el comentario al lado.
//
// QUE NO HAY AQUI Y POR QUE. La pantalla de comentario **suelto** --sin texto al lado--
// la comprueba `lector_de_comentario_test.dart`. Aqui solo esta lo nuevo: los dos modulos
// abiertos a la vez y las notas debajo del versiculo.
//
// Y LOS NUMEROS VIENEN DE LOS `.amod` REALES, medidos el 4 de octubre de 2026:
// 31.102 versiculos en el KJV, 19.742 notas en el CLARKE, Juan 3 con 36 versiculos con
// texto y 32 con nota, y Juan 3:1 **sin** nota.

import 'package:ab/app/navegador.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:ab/ui/features/lector/views/lector_view.dart';
import 'package:ab/ui/features/lector/widgets/hoja_de_comentarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fuente.dart';
import '../support/fixtures.dart';

void main() {
  setUpAll(cargarLaFuenteDePrueba);

  // --- la ruta ---

  group('1. la ruta lleva el comentario', () {
    test('sin comentario, la ruta es la de siempre', () {
      final r = Rutas.leer('/leer/KJV2006/John.3.16');

      expect(r, isA<RutaLectura>());
      expect((r as RutaLectura).modulo, 'KJV2006');
      expect(r.referencia, const Referencia('John', 3, 16));
      expect(r.comentario, isNull);
    });

    test('con comentario, el segmento va detras del pasaje', () {
      // Y VA DETRAS, y no antes, porque es lo que se anade a algo. Ademas asi el
      // pasaje --que es la parte que el modulo resuelve-- se puede copiar de un sitio a
      // otro sin depender de que delante haya algo.
      final r = Rutas.leer('/leer/KJV2006/John.3.16/con/CLARKE');

      expect(r, isA<RutaLectura>());
      expect((r as RutaLectura).comentario, 'CLARKE');
      expect(r.modulo, 'KJV2006');
      expect(r.referencia, const Referencia('John', 3, 16));
    });

    test('la ida y la vuelta cuadran en los dos sentidos', () {
      // Y ESTA ES LA PRUEBA DE LA QUE DEPENDE PODER COMPARTIR. Si escribir no devolviera
      // exactamente lo que leer entiende, un enlace copiado de la barra de direcciones
      // abriria otra cosa, yseria el fallo mas dificil de ver: todo funciona y el enlace
      // va a otra parte.
      for (final direccion in <String>[
        '/leer/KJV2006/John.3.16',
        '/leer/KJV2006/John.3.16/con/CLARKE',
        '/leer/CLARKE/Matthew.23',
        '/leer/CLARKE/Matthew.23/con/KJV2006',
      ]) {
        expect(Rutas.escribir(Rutas.leer(direccion)), direccion,
            reason: 'la ruta "$direccion" no vuelve a ser ella misma');
      }
    });

    test('dos rutas que solo difieren en el comentario NO son iguales', () {
      // Y ESTO ES LO QUE HACE QUE EL ENRUTADOR NO CONFUNDA "cambiar el comentario" con
      // "seguir en el mismo sitio". Con igualdad por modulo y referencia, poner y quitar
      // el comentario serian la misma ruta y no se ejecutaria nada.
      final a = Rutas.leer('/leer/KJV2006/John.3.16') as RutaLectura;
      final b = Rutas.leer('/leer/KJV2006/John.3.16/con/CLARKE') as RutaLectura;

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(a, Rutas.leer('/leer/KJV2006/John.3.16'));
    });

    test('un "con" sin comentario, o con uno de mas, no se entiende', () {
      // Y NO ES "abrir sin comentario": es una ruta que no se entiende. La diferencia es
      // que una ruta mal escrita **avisa** en vez de abrir en silencio lo que parece que
      // se ha pedido, que es la forma de que un enlace con un segmento de mas parezca un
      // enlace bueno.
      for (final mala in <String>[
        '/leer/KJV2006/John.3.16/con',
        '/leer/KJV2006/John.3.16/con/',
        '/leer/KJV2006/John.3.16/CLARKE',
        '/leer/KJV2006/John.3.16/ver/CLARKE',
        '/leer/KJV2006/John.3.16/con/CLARKE/extra',
      ]) {
        expect(Rutas.leer(mala), isA<RutaDesconocida>(), reason: 'esta ruta: $mala');
      }
    });

    test('el despliegue con prefijo sigue funcionando', () {
      // Y CON PREFIJO Y CON RESERVA EN EL HASH, porque son las dos formas en que llega
      // una ruta al sitio publicado: `/ab/leer/...` y `/#/leer/...`.
      final conPrefijo = Rutas.leer('/ab/leer/KJV2006/John.3.16/con/CLARKE');
      final conHash = Rutas.leer('/#/leer/KJV2006/John.3.16/con/CLARKE');

      expect(conPrefijo, isA<RutaLectura>());
      expect((conPrefijo as RutaLectura).comentario, 'CLARKE');
      expect(conHash, conPrefijo);
    });
  });

  // --- el ViewModel ---

  group('2. el ViewModel lleva dos modulos', () {
    late ModuloAbierto biblia;
    late ModuloAbierto comentario;

    setUp(() {
      final a = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      final b = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (a is! Abierto || b is! Abierto) fail('los modulos reales no abren');
      biblia = a.modulo;
      comentario = b.modulo;
      addTearDown(biblia.cerrar);
      addTearDown(comentario.cerrar);
    });

    test('sin comentario no hay notas, y no es un fallo', () {
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));

      // Y ESTO ES EL CASO NORMAL: `/leer/KJV2006/John.3.16` a secas. Lo que se abre es
      // Juan 3:16 del KJV, entero, y no hay nada al lado. Que `notasDe` devuelva una
      // lista vacia y no una excepcion es lo que hace que la pantalla pueda preguntar
      // siempre sin preguntar antes.
      expect(vm.tieneComentario, isFalse);
      expect(vm.idDelComentario, isNull);
      expect(vm.notasDe(16), isEmpty);
      expect(vm.tieneNotasDe(16), isFalse);
      expect(vm.versiculosConNota, isEmpty);
      expect(vm.motivoDelComentario, isNull);
      expect(vm.estado, EstadoLecturaTexto.leyendo);
    });

    test('con comentario, las notas salen de el y no del texto', () {
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);

      // Y EL TEXTO **NO CAMBIA**. El mismo versiculo, el mismo estado, las mismas
      // palabras: lo que se anade es al lado, y si al anadirlo cambiara el texto habria
      // que volver a leerlo.
      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.pasaje!.versiculo(16)!.texto, startsWith('For God so loved the world'));

      // Y LA NOTA ES LA DEL COMENTARIO, que es lo que no esta en ningun otro sitio.
      expect(vm.idDelComentario, 'CLARKE');
      expect(vm.tieneComentario, isTrue);
      expect(vm.notasDe(16), hasLength(1));
      expect(vm.notasDe(16).single.texto, startsWith('For God so loved the world - Such a love'));
    });

    test('el capitulo entero trae las notas de todo el capitulo', () {
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);

      // 32 de 36: cuatro versiculos de Juan 3 no tienen nota. Y el selector tiene que
      // ofrecer 32, no 36, porque ofrecer los otros cuatro lleva a cuatro pantallas
      // vacias.
      expect(vm.versiculosConNota, hasLength(32));
      expect(vm.versiculosConNota, contains(16));
      expect(vm.versiculosConNota, isNot(contains(1)));
      expect(vm.tieneNotasDe(1), isFalse);
    });

    test('QUE EL COMENTARIO NO TENGA NOTA NO HACE FALLAR LA LECTURA', () {
      // Y ESTA ES LA REGLA DEL CHANGE, y la mas importante. Juan 3:1 no tiene nota en el
      // CLARKE --medido--, y leer Juan 3:1 del KJV con el CLARKE al lado tiene que
      // ensenar el versiculo.
      //
      // La primera version pedia las notas antes de comprobar si el comentario tenia el
      // pasaje, y devolvia un pasaje "vacio" que el lector tomaba por "no existe": el
      // texto desaparecia por culpa de un extra.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 1));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);

      expect(vm.estado, EstadoLecturaTexto.leyendo, reason: 'el versiculo se lee igual');
      expect(vm.aviso, isNull);
      expect(vm.pasaje!.versiculo(1), isNotNull);
      expect(vm.pasaje!.versiculo(1)!.texto, isNotEmpty);
      expect(vm.notasDe(1), isEmpty);
      expect(vm.motivoDelComentario, isNull,
          reason: 'que no haya nota no es un fallo que haya que avisar');
    });

    test('al pasar de capitulo se vuelven a leer las notas', () {
      // Y ESTE FALLO ESTA MEDIDO, no inventado. Ir de Juan 3 a Juan 5 con el CLARKE al
      // lado dejaba las 32 notas de Juan 3 encima de Juan 5, que tiene 43. Juan 5
      // ensenaba el comentario de otro pasaje sin decir nada.
      //
      // Y POR QUE NO SE ABRE OTRA VEZ EL MODULO. Reabrir son 57 MiB y un
      // `PRAGMA quick_check` para volver a traer las mismas notas, y lo que hace falta es
      // volver a **leerlas**. Son dos cosas, y aqui solo se hace la segunda.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);
      expect(vm.totalDeNotas, 32, reason: 'Juan 3 tiene 32 notas, medido');

      vm.leer(const Referencia('John', 5));
      vm.refrescarNotas();

      expect(vm.totalDeNotas, 43, reason: 'Juan 5 tiene 43 notas, medido');
      expect(vm.versiculosConNota, isNot(equals(vm.versiculosConNota.reversed.toList())),
          reason: 'y no son las de Juan 3 con otro nombre');
    });

    test('un comentario que revienta al consultarse NO tumba el texto', () {
      // Y SE COMPRUEBA CON UN MODULO CERRADO, que es un fallo real y reproducible: un
      // `.amod` que se cambia por fuera mientras la aplicacion esta abierta. Un
      // comentario que revienta es un extra roto; el texto que se estaba leyendo sigue
      // siendo el texto.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));

      vm.abrirComentario(comentario, licenciaDelManifiesto: null);
      comentario.cerrar(); // el fichero ya no esta disponible

      // Y SE CAMBIA DE VERSICULO, porque con el mismo no habria consulta que hiciese:
      // `refrescarNotas` no vuelve a pedir lo que ya tiene, que es lo que evita que se
      // turned con `leer` en un bucle. Sin este cambio la prueba pasaria sin comprobar
      // nada.
      vm.leer(const Referencia('John', 3, 15));
      vm.refrescarNotas();

      expect(vm.estado, EstadoLecturaTexto.leyendo, reason: 'el versiculo sigue ahi');
      expect(vm.pasaje!.versiculo(15), isNotNull);
      expect(vm.notasDe(15), isEmpty);
      // Y LA EXCEPCION SE HA COMIDO EL `try` de `_leerNotas` en vez de salir por la
      // ventana: sin el, `leer` lanzaria y la pantalla se caeria entera. Que la prueba
      // llegue aqui sin lanzar ya lo dice.
    });

    test('abrir otro texto se lleva el comentario por delante', () {
      // Y NO SE OLVIDA: es que dejar al lado del Juan 3:16 de una traduccion las notas
      // del Juan 3:16 de otra es el peor sitio donde puede estar un comentario, porque
      // parece que va del versiculo.
      //
      // Y SE ABRE **OTRA** BIBLIA, no la misma otra vez. `abrir` cierra lo que hubiera
      // abierto --es lo que evita tener 79 MiB abiertos-- y cerrar una instancia y
      // volver a meter la misma es usar una base de datos ya cerrada. En la aplicacion
      // no pasa: quien llama abre un modulo nuevo cada vez. Aqui se abre otro de verdad
      // para que la prueba sea la de "cambiar de texto" y no la de "usar algo cerrado".
      final otro = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      if (otro is! Abierto) fail('la otra Biblia no abre');
      addTearDown(otro.modulo.cerrar);

      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);
      expect(vm.tieneComentario, isTrue);

      vm.abrir(otro.modulo, licenciaDelManifiesto: null);

      expect(vm.tieneComentario, isFalse);
      expect(vm.notasDe(16), isEmpty);
    });

    test('quitar el comentario deja el texto como estaba', () {
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));
      vm.abrirComentario(comentario, licenciaDelManifiesto: null);

      vm.cerrarComentario();

      expect(vm.tieneComentario, isFalse);
      expect(vm.notasDe(16), isEmpty);
      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.pasaje!.versiculo(16), isNotNull);
    });

    test('un comentario que no abre deja el texto leido y lo avisa', () {
      // Y ESTE ES EL CASO DE UN ENLACE COMPARTIDO, y es el que mas va a pasar: el
      // comentario pesa 57 MiB y no lo tiene todo el mundo ni en el movil. Quien recibe
      // `/leer/KJV2006/John.3.16/con/CLARKE` sin el CLARKE tiene Juan 3:16 entero y la
      // razon de que al lado no hay nada. **No** un error.
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));

      vm.comentarioNoDisponible('CLARKE', 'El comentario CLARKE no esta descargado.');

      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.pasaje!.versiculo(16), isNotNull);
      expect(vm.tieneComentario, isFalse);
      expect(vm.notasDe(16), isEmpty);
      expect(vm.motivoDelComentario, contains('CLARKE'));
    });

    test('un texto de Biblia pedido como comentario se avisa y no se finge', () {
      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));

      vm.abrirComentario(biblia, licenciaDelManifiesto: null);

      expect(vm.motivoDelComentario, contains('no un comentario'));
      expect(vm.notasDe(16), isEmpty);
      expect(vm.estado, EstadoLecturaTexto.leyendo,
          reason: 'poner un texto al lado no rompe la lectura');
    });
  });

  // --- la pantalla ---

  group('3. la pantalla pone la nota debajo de su versiculo', () {
    late ModuloAbierto biblia;
    late ModuloAbierto comentario;

    setUp(() {
      final a = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
      final b = ModuloAbierto.abrir(rutaComentarioReal, id: 'CLARKE');
      if (a is! Abierto || b is! Abierto) fail('los modulos reales no abren');
      biblia = a.modulo;
      comentario = b.modulo;
      addTearDown(biblia.cerrar);
      addTearDown(comentario.cerrar);
    });

    Future<LectorViewModel> montar(
      WidgetTester tester, {
      required Referencia referencia,
      bool conComentario = true,
      double ancho = 360,
    }) async {
      tester.view.physicalSize = Size(ancho, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(referencia);
      if (conComentario) vm.abrirComentario(comentario, licenciaDelManifiesto: null);

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: LectorView(
            viewModel: vm,
            alVolver: () {},
            alPulsarPasaje: vm.leer,
            alPedirComentario: () {},
            alVerIndice: (_) {},
            alAlternarPalabrasDeJesus: () {},
            alCambiarDeVersion: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return vm;
    }

    testWidgets('el versiculo sale y DESPUES su nota', (tester) async {
      await montar(tester, referencia: const Referencia('John', 3, 16));

      expect(find.textContaining('For God so loved the world,'), findsOneWidget);
      expect(find.textContaining('Such a love as that which induced'), findsOneWidget);

      // Y **EN ESE ORDEN**, y no solo "estan los dos". Poner las notas todas al final
      // del capitulo tambien las ensena, y obliga a ir y volver del versiculo a la nota
      // y de la nota al versiculo.
      final orden = <double>[
        if (tester.any(find.textContaining('Such a love as that which induced')))
          tester.getTopLeft(find.textContaining('Such a love as that which induced')).dy,
        if (tester.any(find.textContaining('For God so loved the world,')))
          tester.getTopLeft(find.textContaining('For God so loved the world,')).dy,
      ];
      expect(orden[0], greaterThan(orden[1]),
          reason: 'la nota va debajo de su versiculo, no encima');
    });

    testWidgets('un versiculo SIN nota no deja hueco ni separacion', (tester) async {
      // Y ESTO ES LO QUE HACE QUE LA COLA NO PAREZA MAQUETADA. Juan 3 tiene cuatro
      // versiculos sin nota --**medido**: el 1, el 7, el 24 y el 28--, y Juan 3:2 si
      // tiene, con sus 2.103 caracteres. Si cada versiculo sin nota dejara su sitio
      // vacio, el capitulo empezaria con un hueco antes de la primera nota y pareceria
      // que el texto empieza a medias.
      final vm = await montar(tester, referencia: const Referencia('John', 3));
      expect(vm.notasDe(1), isEmpty);
      expect(vm.notasDe(7), isEmpty);
      // Y EL SIGUIENTE SI TIENE, que es la comprobacion que de verdad importa: la
      // pantalla tiene que poner la del 2 y no saltarsela porque el 1 no tenia ninguna.
      expect(vm.notasDe(2), hasLength(1));

      // Y SE MIDE CUANTAS ETIQUETAS DE NOTA HAY, y no si hay un `Divider`: hay `Divider`
      // en otras partes de la pantalla --los terminos, el campo-- y buscarlos todos no
      // dice nada de las notas. Lo que se quiere decir es que hay **una etiqueta por
      // versiculo con nota y ni una mas**, y Juan 3 tiene 32 de 36.
      final etiquetas = find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).border != null,
      );
      expect(etiquetas, findsNWidgets(vm.versiculosConNota.length));
      expect(vm.versiculosConNota, hasLength(32));
    });

    testWidgets('el boton dice el nombre del comentario abierto', (tester) async {
      await montar(tester, referencia: const Referencia('John', 3, 16));
      expect(find.widgetWithText(TextButton, 'CLARKE'), findsOneWidget);
    });

    testWidgets('sin comentario, el boton dice lo que hay que hacer', (tester) async {
      // Y NO UN ICONO APAGADO. Un control sin etiqueta en la barra es un control que no
      // se ve, y lo unico que hay que ofrecer a quien no ha puesto ningun comentario es
      // la manera de ponerlo.
      await montar(tester, referencia: const Referencia('John', 3, 16), conComentario: false);
      expect(find.widgetWithText(TextButton, 'Comentario'), findsOneWidget);
    });

    testWidgets('el aviso del comentario tiene un boton para quitarlo', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = LectorViewModel();
      addTearDown(vm.dispose);
      vm.abrir(biblia, licenciaDelManifiesto: null);
      vm.leer(const Referencia('John', 3, 16));
      vm.comentarioNoDisponible(
        'CLARKE',
        'El comentario CLARKE no esta descargado en este dispositivo.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: LectorView(
            viewModel: vm,
            alVolver: () {},
            alPulsarPasaje: vm.leer,
            alPedirComentario: () {},
            alVerIndice: (_) {},
            alAlternarPalabrasDeJesus: () {},
            alCambiarDeVersion: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no esta descargado'), findsOneWidget);
      // Y EL TEXTO SIGUE ESTANDO. Un enlace compartido a un movil sin el comentario
      // tiene que ensefiar Juan 3:16, que es el 90% de lo que pedia quien compartio.
      expect(find.textContaining('For God so loved the world'), findsWidgets);
      expect(vm.estado, EstadoLecturaTexto.leyendo);
    });

    testWidgets('a 360 px un versiculo con su nota cabe', (tester) async {
      // Y CON LA NOTA LARGA DE VERDAD. La nota de Juan 3:16 son 405 caracteres y la de
      // Mateo 23:13 son 2.709; una maqueta que aguanta un texto corto y desborda con uno
      // largo no aguanta ni el primero de los dos.
      for (final ancho in <double>[320, 360, 768, 1440]) {
        final vm = await montar(
          tester,
          referencia: const Referencia('John', 3, 16),
          ancho: ancho,
        );
        expect(tester.takeException(), isNull, reason: 'a $ancho px no puede desbordar');
        expect(vm.notasDe(16), isNotEmpty, reason: 'y tiene que haber leido la nota');
      }
    });
  });

  // --- la hoja ---

  group('4. la hoja de comentarios', () {
    testWidgets('devuelve el identificador, y "" para quitar', (tester) async {
      String? elegido;

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  elegido = await mostrarHojaDeComentarios(
                    context: context,
                    actuales: const <ComentarioDisponible>[
                      ComentarioDisponible(id: 'CLARKE', nombre: 'Comentario de Adam Clarke'),
                    ],
                    abierto: 'CLARKE',
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Y LA LISTA DICE EL NOMBRE Y NO EL IDENTIFICADOR. "CLARKE" solo no le dice nada a
      // quien lee; "Comentario de Adam Clarke" si, y el identificador va debajo porque es
      // lo que hace falta para escribir un enlace.
      expect(find.text('Comentario de Adam Clarke'), findsOneWidget);
      expect(find.text('CLARKE'), findsWidgets);
      expect(find.byIcon(Icons.check), findsOneWidget, reason: 'marca el que esta abierto');
      expect(find.text('Quitar el comentario'), findsOneWidget);

      await tester.tap(find.text('Comentario de Adam Clarke'));
      await tester.pumpAndSettle();
      expect(elegido, 'CLARKE');
    });

    testWidgets('sin comentarios descargados, dice donde se bajan', (tester) async {
      // Y NO DICE "no hay comentarios", que suena a que la app esta vacia o rota. No hay
      // ninguno porque pesa 57 MiB cada uno y no todo el mundo los descarga, y la
      // respuesta util es donde.
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => mostrarHojaDeComentarios(
                  context: context,
                  actuales: const <ComentarioDisponible>[],
                  abierto: null,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('biblioteca'), findsOneWidget);
      expect(find.text('Quitar el comentario'), findsNothing,
          reason: 'no hay nada abierto que quitar');
    });

    testWidgets('cerrar sin elegir NO quita el comentario', (tester) async {
      // Y ESTA ES LA DISTINCION QUE HACE FALTA ENTRE TRES COSAS: elegir uno, quitarlo y
      // no hacer nada. Con un solo valor de vuelta, cerrar la hoja tocando fuera
      // quitaria el comentario que se estaba leyendo, y abrir una hoja a caballo seria
      // una forma de perder lo que se leia.
      String? elegido = 'sin tocar';

      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  elegido = await mostrarHojaDeComentarios(
                    context: context,
                    actuales: const <ComentarioDisponible>[
                      ComentarioDisponible(id: 'CLARKE', nombre: 'Comentario de Adam Clarke'),
                    ],
                    abierto: 'CLARKE',
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20)); // fuera de la hoja
      await tester.pumpAndSettle();

      expect(elegido, isNull, reason: 'cerrar sin elegir es "no he cambiado nada"');
    });
  });

  // --- el enrutador ---

  group('5. el enrutador', () {
    late BibliotecaViewModel biblioteca;
    late LectorViewModel lector;
    late List<String> abiertos;

    setUp(() {
      biblioteca = BibliotecaViewModel();
      lector = LectorViewModel();
      abiertos = <String>[];
      // Y NO SE DESCARGA EL LECTOR AQUI, porque `NavegadorAb.dispose` ya lo hace y
      // descargar dos veces el mismo `ChangeNotifier` lanza
      // `A LectorViewModel was used after being disposed`. Y sale como fallo de la
      // prueba cuando lo que esta mal es el doble `dispose`, que es lo unico que no se
      // ve leyendo el mensaje.
    });

    /// Un enrutador con los dos modulos reales detras, y un manifiesto que dice
    /// que el CLARKE es un comentario.
    ///
    /// Y [descargados] es lo que hay **en el almacenamiento**, y [aLaBaja] lo que se
    /// puede bajar, que son cosas distintas: un modulo puede estar en el catalogo y no
    /// aqui, y es el caso normal con el comentario de 57 MiB.
    ///
    /// Y EL MANIFIESTO TIENE QUE DECIRLO, porque el enrutador no pregunta al commentary
    /// si es comentario: pregunta **al manifiesto**, que es lo que el catalogo publico. Y
    /// por eso el identificador `CLARKE` no aparece en el codigo de la app ni una vez:
    /// aqui es un dato del manifiesto, como lo es de verdad.
    List<String>? bajados;
    late void Function(String) aLaBaja;

    NavegadorAb montar({
      required Set<String> descargados,
      bool puedeDescargar = false,
    }) {
      biblioteca.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: Manifiesto(
            formato: 'aa-catalog/1',
            version: 'v0.1.1',
            etiqueta: 'v0.1.1',
            modulos: <Modulo>[
              _modulo('KJV2006', 'King James Version 2006', TipoModulo.biblia, tamanoBiblia),
              _modulo(
                'CLARKE',
                'Comentario de Adam Clarke',
                TipoModulo.comentario,
                tamanoComentario,
              ),
            ],
          ),
          estado: EstadoLectura.delServidor,
        ),
        idsLocales: descargados,
        hashesLocales: <String, String>{
          for (final id in descargados) id: 'a' * 64,
        },
      );

      bajados = <String>[];
      aLaBaja = (id) => bajados!.add(id);

      return NavegadorAb(
        biblioteca: biblioteca,
        lector: lector,
        descargar: puedeDescargar ? aLaBaja : null,
        abrir: (id, referencia) async {
          final ruta = id == 'CLARKE' ? rutaComentarioReal : rutaBibliaReal;
          final apertura = ModuloAbierto.abrir(ruta, id: id);
          if (apertura is! Abierto) return null;
          abiertos.add(id);
          return apertura.modulo;
        },
      );
    }

    Future<void> montarEnPantalla(
      WidgetTester tester,
      NavegadorAb n,
    ) async {
      await tester.pumpWidget(MaterialApp.router(
        theme: temaDeAb(),
        routerDelegate: n,
        routeInformationParser: const AnalizadorDeRuta(),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('una ruta con comentario lo descarga y lo abre', (tester) async {
      // Y ESTE ES EL CASO PRINCIPAL: alguien comparte Juan 3:16 con el CLARKE al lado y
      // quien lo recibe lo lee asi.
      final n = montar(descargados: <String>{'KJV2006', 'CLARKE'});
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();

      expect(lector.estado, EstadoLecturaTexto.leyendo);
      expect(lector.idDelModulo, 'KJV2006');
      expect(lector.idDelComentario, 'CLARKE');
      expect(lector.notasDe(16), hasLength(1));
      expect(abiertos, <String>['KJV2006', 'CLARKE']);

      // Y LA URL DICE LAS DOS COSAS. Es lo que se copia y lo que se manda, y si la
      // pantalla dice "con CLARKE" y la URL no, el enlace no lleva lo que se ve.
      expect(Rutas.escribir(n.ruta), '/leer/KJV2006/John.3.16/con/CLARKE');
    });

    testWidgets('si el comentario no esta descargado, el texto se lee igual',
        (tester) async {
      // Y ESTA ES LA REGLA DEL ENLACE COMPARTIDO. El CLARKE pesa 57 MiB: es normal que
      // quien recibe el enlace no lo tenga. Lo que no puede pasar es que el texto
      // desaparezca por eso, porque el texto es lo que se pidio y el comentario es lo
      // que se anadio.
      final n = montar(descargados: <String>{'KJV2006'});
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();

      expect(lector.estado, EstadoLecturaTexto.leyendo);
      expect(lector.pasaje!.versiculo(16)!.texto, startsWith('For God so loved'));
      expect(lector.idDelComentario, isNull);
      expect(lector.motivoDelComentario, contains('no esta descargado'));
      expect(abiertos, <String>['KJV2006'],
          reason: 'no se intenta abrir lo que no esta');
    });

    testWidgets('pasar de capitulo no vuelve a abrir ningun modulo', (tester) async {
      // Y ESTO ES LO QUE HACE QUE SEA USABLE. Sin esto, cada capitulo con el comentario
      // al lado releeria 22 MiB y 57 MiB del almacenamiento y volveria a pasarles
      // `PRAGMA quick_check` a los dos, y quien lee con el comentario abierto acabaria
      // por quitarlo.
      final n = montar(descargados: <String>{'KJV2006', 'CLARKE'});
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();
      final trasAbrir = List<String>.of(abiertos);

      for (final capitulo in <int>[4, 5]) {
        await n.irA(RutaLectura('KJV2006', Referencia('John', capitulo), 'CLARKE'));
        await tester.pumpAndSettle();
      }

      // Y LAS NOTAS **CAMBIAN** con el capitulo, que es la otra mitad de lo mismo: si se
      // quedaran las de Juan 3, Juan 5 ensenaria el comentario de otro pasaje sin decir
      // nada, que es peor que no ensenar ninguno.
      //
      // Y LOS NUMEROS ESTAN MEDIDOS: Juan 4 tiene 45 y Juan 5 tiene 43 versiculos con nota.
      // Y Juan 5:1 **no** tiene nota --tampoco Juan 3:1--, asi que comprobar por el 1
      // seria comprobar un caso que no existe.
      expect(lector.versiculosConNota, isNot(equals(<int>[])));
      expect(lector.totalDeNotas, 43, reason: 'las notas de Juan 5, no las de Juan 3');
      expect(abiertos, trasAbrir, reason: 'no se vuelve a abrir ningun modulo');
    });

    testWidgets('si no esta descargado, se OFRECE bajarlo y se baja', (tester) async {
      // Y ESTE ES EL FALLO QUE ENCONTRO LA COMPROBACION EN NAVEGADOR, y no lo encontro
      // ninguna prueba de Dart. Con `/leer/KJV2006/John.3.16/con/CLARKE` en un perfil
      // donde el CLARKE no estaba, la app decia que no estaba descargado y se paraba ahi:
      // 0 bytes bajados y Juan 3:16 sin nada al lado.
      //
      // O sea, que un enlace con un comentario no servia de nada: quien lo recibia no
      // tenia forma de conseguir el comentario sin dejar de estar leyendo.
      final n = montar(descargados: <String>{'KJV2006'}, puedeDescargar: true);
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();

      // Y EL TEXTO ESTA ENTERO, que es lo que no puede romperse.
      expect(lector.estado, EstadoLecturaTexto.leyendo);

      // Y HAY UN BOTON CON EL TAMANO, que es lo que se decide pulsar.
      final boton = find.widgetWithText(TextButton, 'Descargar, 54.9');
      expect(boton, findsOneWidget);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(bajados, <String>['CLARKE']);
    });

    testWidgets('terminada la descarga, el comentario se abre solo', (tester) async {
      // Y LA SEGUNDA MITAD DE LO MISMO, y es la que no se puede hacer a mano. El boton
      // llama a quien baja --la biblioteca--, y quien baja avisa cuando termina. Entre
      // esas dos cosas no hay nadie: quien pide una descarga es la biblioteca y quien
      // aplica una ruta es el enrutador, asi que sin esta escucha quien lo pidio se
      // queda con el texto y el comentario a medio bajar.
      final n = montar(descargados: <String>{'KJV2006'}, puedeDescargar: true);
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();
      expect(lector.idDelComentario, isNull);

      // Y ESTO ES LO QUE PASA AL TERMINAR: la biblioteca actualiza lo que hay.
      biblioteca.actualizarIdsLocales(
        <String>{'KJV2006', 'CLARKE'},
        hashes: <String, String>{'KJV2006': 'a' * 64, 'CLARKE': 'b' * 64},
      );
      await tester.pumpAndSettle();

      expect(lector.idDelComentario, 'CLARKE');
      expect(lector.notasDe(16), hasLength(1));
      expect(lector.estado, EstadoLecturaTexto.leyendo);
      expect(lector.motivoDelComentario, isNull);
      // Y LA URL NO CAMBIA. El comentario no es un sitio nuevo: es el mismo pasaje con
      // algo al lado, y quien copie la direccion tiene que poder mandarla.
      expect(Rutas.escribir(n.ruta), '/leer/KJV2006/John.3.16/con/CLARKE');
    });

    testWidgets('NO se ofrece bajar lo que el catalogo no tiene', (tester) async {
      // Y PORQUE ES UNA RUTA QUE NO SE ENTIENDE PERO NO UN ERROR. Un enlace de otro
      // despliegue puede pedir un comentario que aqui no existe, y un boton de "Descargar"
      // que no descarga es peor que no tenerlo.
      final n = montar(descargados: <String>{'KJV2006'}, puedeDescargar: true);
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'NOEXISTE'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Descargar, 54.9'), findsNothing);
      expect(find.textContaining('no esta descargado'), findsOneWidget);
      expect(lector.estado, EstadoLecturaTexto.leyendo);
    });

    testWidgets('volver a la biblioteca cierra los dos modulos', (tester) async {
      // Y LOS DOS, no solo el texto. Volver a la biblioteca con el CLARKE abierto son
      // 57 MiB de paginas SQLite que no vuelven solas en un movil de gama baja, y quien
      // esta en la biblioteca no esta leyendo.
      final n = montar(descargados: <String>{'KJV2006', 'CLARKE'});
      addTearDown(n.dispose);

      await montarEnPantalla(tester, n);
      await n.irA(const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'));
      await tester.pumpAndSettle();
      expect(lector.tieneComentario, isTrue);

      await n.irAHome();
      await tester.pumpAndSettle();

      expect(lector.tieneComentario, isFalse);
      expect(lector.idDelModulo, isNull);
    });
  });
}

/// Un modulo del manifiesto, como lo declara el catalogo.
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
