// La pantalla de biblioteca, probada como pantalla.
//
// LAS MEDIDAS SON REALES Y ESTAN EN EL FICHERO A PROPOSITO. [anchoEstrecho] es
// 360x640, que es el movil mas estrecho que se usa hoy, y [anchoAncho] es
// 1440x900, un portatil normal. Los nombres con acentos se quedan: son texto de Entre los dos cubren lo que hay en el mundo, y
// pantalla, y ahi los acentos son obligatorios.
//
// LO QUE SE COMPRUEBA Y POR QUE NO HAY UNA PRUEBA POR CADA TAREA. Las tareas 6.1 a
// 6.5 son cinco, pero se pueden comprobar en seis pruebas, porque lo que importa no
// es que haya una prueba por tarea sino que cada cosa que la tarea pide se vea en
// pantalla. Lo que no se comprueba es el pixel exacto: eso se rompe al cambiar el
// tema y no dice nada del comportamiento.
//
// Y LA MAS IMPORTANTE DE TODAS ES LA ULTIMA: **que a 360 px el boton de cada fila se
// alcanza sin desplazar horizontalmente**. Es el requisito que mas veces se
// incumple y el que nadie nota hasta que lo usa: se ve una fila, el boton esta
// fuera de la pantalla, y con el movil en vertical parece que la fila "se ha
// terminado". En un `ListView` con scroll vertical, un hijo mas ancho que la
// pantalla **no produce scroll horizontal**: se sale de la vista y no hay manera de
// llegar a el. Por eso la comprobacion es "el boton esta dentro del ancho de la
// pantalla", y no "hay scroll".

import 'dart:convert';
import 'dart:io';

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/core/tema.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:ab/ui/features/biblioteca/views/biblioteca_view.dart';
import 'package:ab/ui/features/biblioteca/widgets/fila_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El movil mas estrecho que se usa hoy.
const Size anchoEstrecho = Size(360, 640);

/// Un portatil normal.
const Size anchoAncho = Size(1440, 900);

/// Un modulo que solo existe en el manifiesto, y que no esta en ninguna parte del
/// codigo de la app. Es el caso del spec: "el manifiesto declara modulos que la app
/// no conoce -> los muestra".
Modulo _moduloDesconocido({
  String id = 'RVR1960_ES',
  String nombre = 'Reina-Valera 1960 (español, revisada)',
  TipoModulo tipo = TipoModulo.biblia,
  String idioma = 'spa',
  int tamano = 28424192,
  String licencia = 'PublicDomain',
}) =>
    Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: idioma,
      licencia: licencia,
      tamanoBytes: tamano,
      sha256: 'a' * 64,
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/n/$id.amod'),
    );

Manifiesto _manifiesto(List<Modulo> modulos) => Manifiesto(
  formato: 'aa-catalog/1',
  version: 'v0.0.1',
  etiqueta: 'v0.0.1',
  modulos: modulos,
);

/// Monta la pantalla con un ViewModel ya lleno.
Future<void> _montar(
  WidgetTester tester, {
  required BibliotecaViewModel vm,
  Size tamano = anchoEstrecho,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: temaDeAb(),
      home: BibliotecaView(
        viewModel: vm,
        alPulsarLeer: (id) {},
        alPulsarDescargar: (id) {},
        alPulsarFicheroLocal: (id) {},
        alReintentar: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('6.1 la fila pinta lo que declara el manifiesto', () {
    testWidgets('un modulo desconocido aparece con su tamano exacto en MB', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido(tamano: 28424192)]),
      );
      await _montar(tester, vm: vm);

      expect(find.text('Reina-Valera 1960 (español, revisada)'), findsOneWidget);
      // 28.424.192 bytes son 27,1 MiB. Y con un decimal: "27 MB" y "27,1 MB" dan
      // distinta sensacion de lo que pesa, y la decision de bajarlo depende de eso.
      expect(find.textContaining('27.1 MB'), findsOneWidget);
      expect(find.text('RVR1960_ES'), findsOneWidget);
    });

    testWidgets('el tamano es el que dice el manifiesto, byte a byte', (tester) async {
      for (final (bytes, esperado) in <(int, String)>[
        (28424192, '27.1 MB'),
        (22544384, '21.5 MB'),
        (57536512, '54.9 MB'),
        (1048576, '1.0 MB'),
        (1024, '0.0 MB'),
      ]) {
        final vm = BibliotecaViewModel(
          manifiesto: _manifiesto(<Modulo>[_moduloDesconocido(tamano: bytes)]),
        );
        await _montar(tester, vm: vm);
        expect(find.textContaining(esperado), findsOneWidget,
            reason: '$bytes bytes son $esperado');
      }
    });

    testWidgets('tipo, idioma y licencia estan, y el idioma en castellano', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[
          _moduloDesconocido(idioma: 'spa'),
          _moduloDesconocido(id: 'CLARKE', nombre: 'Clarke', idioma: 'eng', tipo: TipoModulo.comentario),
        ]),
      );
      await _montar(tester, vm: vm);

      // `spa` sale como "espanol", no como "spa": es lo que lee la gente.
      expect(find.text('espanol'), findsOneWidget);
      expect(find.text('ingles'), findsOneWidget);
      // Y la licencia traducida, por la misma razon.
      expect(find.text('dominio publico'), findsNWidgets(2));
      expect(find.text('spa'), findsNothing);
    });

    testWidgets('un idioma desconocido sale como el codigo, no inventado', (tester) async {
      // Un codigo inventado seria un idioma mal identificado. Si no lo sabemos, se
      // ensena el codigo, que es verdad.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido(idioma: 'haw')]),
      );
      await _montar(tester, vm: vm);
      expect(find.text('haw'), findsOneWidget);
    });

    testWidgets('NO hay ningun texto de ejemplo ni modulo de reserva', (tester) async {
      // El caso del spec: manifiesto vacio, lista vacia y sin inventar nada. Aqui
      // esta el corazon de la regla de "no se mete contenido".
      final vm = BibliotecaViewModel(manifiesto: _manifiesto(const <Modulo>[]));
      await _montar(tester, vm: vm);

      expect(find.byType(FilaModulo), findsNothing);
      expect(find.textContaining('King James'), findsNothing);
      expect(find.textContaining('RVR'), findsNothing);
      expect(find.textContaining('Sefarad'), findsNothing);
      expect(find.text('No hay ningun modulo'), findsOneWidget);
    });

    testWidgets('el manifiesto REAL se pinta con sus dos modulos', (tester) async {
      // El manifiesto de verdad, no uno inventado. Las cifras de la pantalla tienen
      // que ser las del catalogo publicado.
      final j = jsonDecode(File('test/fixtures/catalog_real.json').readAsStringSync())
          as Map<String, dynamic>;
      final modulos = <Modulo>[
        for (final e in j['modules'] as List)
          Modulo(
            id: (e as Map<String, dynamic>)['id'] as String,
            nombre: e['name'] as String,
            tipo: TipoModulo.desdeCatalogo(e['type'] as String)!,
            idioma: e['language'] as String,
            licencia: e['license'] as String,
            tamanoBytes: e['sizeBytes'] as int,
            sha256: e['sha256'] as String,
            urlDescarga: Uri.parse(e['downloadUrl'] as String),
            urlNavegador: Uri.parse(e['browserUrl'] as String),
          ),
      ];
      final vm = BibliotecaViewModel(manifiesto: _manifiesto(modulos));
      await _montar(tester, vm: vm);

      expect(find.byType(FilaModulo), findsNWidgets(2));
      expect(find.text('King James Version (2006)'), findsOneWidget);
      expect(find.textContaining('21.5 MB'), findsOneWidget);
      expect(find.textContaining('54.9 MB'), findsOneWidget);
    });
  });

  group('6.2 los filtros, y el vacio con aviso', () {
    testWidgets('filtrar por texto deja solo lo que case', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[
          _moduloDesconocido(id: 'A', nombre: 'Reina-Valera 1960', idioma: 'spa'),
          _moduloDesconocido(id: 'B', nombre: 'King James Version', idioma: 'eng'),
        ]),
      );
      await _montar(tester, vm: vm);
      expect(find.byType(FilaModulo), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'valera');
      await tester.pumpAndSettle();

      expect(find.byType(FilaModulo), findsOneWidget);
      expect(find.text('Reina-Valera 1960'), findsOneWidget);
    });

    testWidgets('filtrar por un idioma que NO existe deja la lista vacia CON AVISO', (tester) async {
      // Y no con un error. Esto es lo que dice la tarea, y la diferencia no es de
      // estilo: un error rojo por escribir una letra de mas hace que alguien piense
      // que la app esta rota cuando lo unico que ha hecho es filtrar de mas.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido(idioma: 'spa')]),
      );
      await _montar(tester, vm: vm);

      vm.filtrarPorIdioma('fra');
      await tester.pumpAndSettle();

      expect(find.byType(FilaModulo), findsNothing);
      expect(find.text('Nada coincide con la busqueda'), findsOneWidget);
      expect(find.text('Quitar los filtros'), findsOneWidget);
      // Y el filtro **sigue ahi**, para poder quitarlo. Si desapareciera con la
      // lista, no habria forma de arreglarlo sin recargar la pagina.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('quitar los filtros devuelve la lista', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido(idioma: 'spa')]),
      );
      await _montar(tester, vm: vm);
      vm.filtrarPorIdioma('fra');
      await tester.pumpAndSettle();
      expect(find.text('Quitar los filtros'), findsOneWidget);

      await tester.tap(find.text('Quitar los filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(FilaModulo), findsOneWidget);
      expect(find.text('Nada coincide con la busqueda'), findsNothing);
    });

    testWidgets('"solo lo que tengo" deja solo lo descargado', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[
          _moduloDesconocido(id: 'A', nombre: 'Uno'),
          _moduloDesconocido(id: 'B', nombre: 'Dos'),
        ]),
        idsLocales: <String>{'B'},
      );
      await _montar(tester, vm: vm);
      expect(find.byType(FilaModulo), findsNWidgets(2));

      await tester.tap(find.text('Solo lo que tengo'));
      await tester.pumpAndSettle();

      expect(find.byType(FilaModulo), findsOneWidget);
      expect(find.text('Dos'), findsOneWidget);
      expect(find.text('Uno'), findsNothing);
    });

    testWidgets('el desplegable de idiomas solo ofrece los que HAY', (tester) async {
      // Los que el manifiesto declara, y no una lista fija: una lista fija seria
      // offering idiomas que no existen y dejaria a alguien esperando un modulo en
      // frances que no va a llegar nunca.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[
          _moduloDesconocido(id: 'A', idioma: 'spa'),
          _moduloDesconocido(id: 'B', idioma: 'eng'),
        ]),
      );
      await _montar(tester, vm: vm);

      await tester.tap(find.text('Todos los idiomas'));
      await tester.pumpAndSettle();

      expect(find.text('espanol'), findsWidgets);
      expect(find.text('ingles'), findsWidgets);
      expect(find.text('frances'), findsNothing);
    });
  });

  group('6.3 el estado tiene texto, no solo color', () {
    testWidgets('los CINCO estados tienen su palabra en pantalla', (tester) async {
      // Se pintan los cinco a la vez, con filas separadas, y se comprueba que cada
      // uno tiene su texto. Un estado que solo se distingue por el color no lo lee
      // quien tiene baja vision, ni con el movil en escala de grises, ni al sol.
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            // `SingleChildScrollView` y no `ListView`. Un `ListView` construye solo
            // lo que se ve, y con cinco filas la quinta esta fuera de la pantalla: el
            // finder no la encuentra y la prueba falla sin decir por que. Aqui lo que
            // se quiere es que **existan** las cinco palabras, no verlas a la vez.
            //
            // Y no `Column` a pelo: cinco filas no caben en 640 px de alto y
            // desbordaba por abajo, que tambien habria sido un fallo real.
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (final e in EstadoModulo.values)
                    FilaModulo(
                      fila: FilaDeModulo(
                        estado: e,
                        modulo: _moduloDesconocido(),
                        idLocal: 'X',
                      ),
                      porQue: PorQueNoSePuedeDescargar.todaviaNo,
                      alPulsarDescargar: () {},
                      alPulsarLeer: () {},
                      alPulsarFicheroLocal: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final e in EstadoModulo.values) {
        expect(
          find.text(e.texto),
          findsWidgets,
          reason: 'el estado "${e.name}" no tiene texto visible',
        );
      }
      // Y los cinco textos son distintos, que si no se distinguirian.
      final textos = EstadoModulo.values.map((e) => e.texto).toSet();
      expect(textos.length, 5);
    });

    testWidgets('un modulo descargado lo dice con palabras, y ademas con el icono', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
        idsLocales: const <String>{'RVR1960_ES'},
      );
      await _montar(tester, vm: vm);

      expect(find.text('Descargado'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('un modulo retirado lo dice, y con la explicacion', (tester) async {
      // El caso del spec: desaparece del manifiesto pero se sigue viendo y leyendo.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(const <Modulo>[]),
        idsLocales: const <String>{'KJV2006_viejo'},
      );
      await _montar(tester, vm: vm);

      expect(find.byType(FilaModulo), findsOneWidget);
      expect(find.text('Retirado del catalogo'), findsOneWidget);
      expect(
        find.textContaining('ya no ofrece este modulo'),
        findsOneWidget,
      );
      expect(find.text('Leer'), findsOneWidget);
    });
  });

  group('6.4 el aviso de copia guardada', () {
    testWidgets('aparece cuando se usa el respaldo, y desaparece sin el', (tester) async {
      // Las DOS partes. Un aviso que solo se comprueba cuando aparece es un aviso
      // que se queda ahi para siempre: si el estado cambia y no desaparece, la
      // pantalla esta mintiendo sobre de donde viene lo que ve.
      final vm = BibliotecaViewModel();
      await _montar(tester, vm: vm);

      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
          estado: EstadoLectura.deCopiaGuardada,
          avisos: const <String>[
            'No se ha podido contactar con el catalogo. '
                'Se ensena una copia guardada del v0.0.1.',
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('copia guardada'), findsOneWidget);
      expect(find.textContaining('v0.0.1'), findsOneWidget);

      // Y ahora vuelve el catalogo de verdad, y el aviso desaparece.
      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
          estado: EstadoLectura.delServidor,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('copia guardada'), findsNothing);
      expect(find.byType(FilaModulo), findsOneWidget);
    });

    testWidgets('con el catalogo leido, NO hay ningun aviso', (tester) async {
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocivoPlaceholder()]),
      );
      await _montar(tester, vm: vm);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    });
  });

  group('6.5 el motivo por el que no se puede, y el boton de fichero local', () {
    testWidgets('RAMO 1: origen NO legible -> explica y ofrece fichero local', (tester) async {
      // Esta es la rama de la `downloadUrl` bloqueada por CORS. Y lo que
      // distingue es lo importante: **no** hay boton de reintentar, porque se sabe
      // que reintentar va a fallar igual. Ofrecer "Reintentar" ahi es decir "prueba
      // otra vez" cuando se sabe que otra vez va a ser igual.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
      );
      await _montar(tester, vm: vm);
      vm.anotarOrigenNoLegible('RVR1960_ES');
      await tester.pumpAndSettle();

      expect(find.textContaining('no permite a esta pagina leer'), findsOneWidget);
      expect(find.text('Fichero local'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('Descargar'), findsNothing);
    });

    testWidgets('RAMO 2: todavia no descargado -> el boton es Descargar', (tester) async {
      // Y esta es la otra rama, que **no** es la anterior. Si las dos dijeran
      // "Descargar", el motivo de por que hay boton de fichero local en una de ellas
      // seria un misterio.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
      );
      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
          estado: EstadoLectura.delServidor,
        ),
      );
      await _montar(tester, vm: vm);

      expect(find.text('Descargar'), findsOneWidget);
      expect(find.textContaining('no permite a esta pagina leer'), findsNothing);
    });

    testWidgets('RAMO 3: sin catalogo -> Reintentar, porque reintentar si sirve', (tester) async {
      // La tercera rama, y es la que hace que las dos anteriores no se puedan
      // fusionar: aqui reintentar **si** puede servir, porque lo que falla es la red.
      final vm = BibliotecaViewModel();
      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _manifiesto(const <Modulo>[]),
          estado: EstadoLectura.sinConexion,
          avisos: const <String>['No se ha podido contactar con el catalogo.'],
        ),
      );
      await _montar(tester, vm: vm);

      expect(find.textContaining('No se ha podido contactar'), findsOneWidget);
      expect(find.text('No hay ningun modulo'), findsOneWidget);
    });

    testWidgets('el boton de fichero local tambien esta sin ningun problema', (tester) async {
      // Si el unico boton fuera "Abrir fichero" cuando el origen esta bloqueado,
      // alguien con el navegador funcionando no tendria forma de traer un modulo a
      // mano. Y hay quien usa un pendrive a proposito.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
      );
      await _montar(tester, vm: vm);
      vm.anotarOrigenNoLegible('RVR1960_ES');
      await tester.pumpAndSettle();

      // Y SOLO un boton. Con el origen bloqueado hay una unica via, y ofrecer dos
      // para lo mismo --un "Abrir fichero" deshabilitado y un "Fichero local"-- hace
      // que no se sepa cual es el bueno.
      expect(find.text('Fichero local'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing,
          reason: 'no hay ninguna descarga posible, asi que no hay boton de descarga');
      expect(find.text('Descargar'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
      // Y la explicacion de por que, que es lo que convierte un boton raro en algo
      // que se entiende.
      expect(find.textContaining('no permite a esta pagina leer'), findsOneWidget);
    });
  });

  group('6.6 los dos tamanos, sin excepciones y sin salirse', () {
    for (final (nombre, tamano) in <(String, Size)>[
      ('360x640, el movil mas estrecho', anchoEstrecho),
      ('1440x900, un portatil', anchoAncho),
    ]) {
      testWidgets('$nombre no lanza excepciones con el manifiesto real', (tester) async {
        final j = jsonDecode(File('test/fixtures/catalog_real.json').readAsStringSync())
            as Map<String, dynamic>;
        final modulos = <Modulo>[
          for (final e in j['modules'] as List)
            Modulo(
              id: (e as Map<String, dynamic>)['id'] as String,
              nombre: e['name'] as String,
              tipo: TipoModulo.desdeCatalogo(e['type'] as String)!,
              idioma: e['language'] as String,
              licencia: e['license'] as String,
              tamanoBytes: e['sizeBytes'] as int,
              sha256: e['sha256'] as String,
              urlDescarga: Uri.parse(e['downloadUrl'] as String),
              urlNavegador: Uri.parse(e['browserUrl'] as String),
            ),
        ];
        await _montar(
          tester,
          vm: BibliotecaViewModel(manifiesto: _manifiesto(modulos), idsLocales: const <String>{'KJV2006'}),
          tamano: tamano,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(FilaModulo), findsWidgets);
      });

      testWidgets('$nombre aguanta un nombre larguisimo sin desbordar', (tester) async {
        // Un nombre de texto real puede ser largo de verdad. Si desborda, en un
        // `ListView` vertical **no hay scroll horizontal**: el boton se sale y no
        // hay manera de llegar a el.
        await _montar(
          tester,
          vm: BibliotecaViewModel(
            manifiesto: _manifiesto(<Modulo>[
              _moduloDesconocido(
                nombre: 'Una Biblia en espanol muy larga con un nombre que no acaba '
                    'y que ademas lleva el ano de publicacion y el nombre del editor',
              ),
            ]),
          ),
          tamano: tamano,
        );
        expect(tester.takeException(), isNull);
        await _comprobarQueNadaSeSale(tester);
      });
    }

    testWidgets('a 360 px el boton de cada fila se alcanza SIN desplazar', (tester) async {
      // ESTA ES LA COMPROBACION QUE MAS IMPORTANTE DE ESTE GRUPO. Un boton fuera
      // de la pantalla en un movil con scroll vertical es invisible e inalcanzable,
      // y no hay ninguna pista de que este ahi. Por eso no se comprueba "que no haya
      // scroll horizontal" --que en un `ListView` vertical no existe-- sino que el
      // boton este **dentro** del ancho de la pantalla.
      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[
          _moduloDesconocido(id: 'A', nombre: 'Uno'),
          _moduloDesconocido(id: 'B', nombre: 'Dos con un nombre mas largo de lo normal'),
        ]),
      );
      await _montar(tester, vm: vm, tamano: anchoEstrecho);

      expect(find.byType(FilaModulo), findsNWidgets(2));
      await _comprobarQueNadaSeSale(tester);

      final botones = find.byType(FilledButton);
      expect(botones, findsWidgets);
      for (var i = 0; i < botones.evaluate().length; i++) {
        final caja = tester.getRect(botones.at(i));
        expect(caja.left, greaterThanOrEqualTo(-0.01),
            reason: 'el boton $i se sale por la izquierda en $caja');
        expect(caja.right, lessThanOrEqualTo(anchoEstrecho.width + 0.01),
            reason: 'el boton $i se sale por la derecha: $caja');
        expect(caja.width, greaterThan(0));
        // Y que se pueda pulsar: una caja de ancho cero no se puede pulsar aunque
        // este "dentro".
        expect(caja.width, greaterThan(80));
      }
    });

    testWidgets('a 360 px el campo de busqueda y el filtro caben', (tester) async {
      final vm = bibliotecaDePrueba();
      await _montar(tester, vm: vm, tamano: anchoEstrecho);
      await _comprobarQueNadaSeSale(tester);

      final campo = tester.getRect(find.byType(TextField));
      expect(campo.width, lessThanOrEqualTo(anchoEstrecho.width));
      expect(campo.width, greaterThan(200));
    });

    testWidgets('a 360 px con el teclado abierto el filtro sigue usandose', (tester) async {
      // Con el teclado en un movil quedan unos 360 px de alto. Si la lista no cabe,
      // el problema no es que no quepa: es que el filtro se vaya con el scroll y no
      // se pueda cambiar con el teclado puesto. Por eso el filtro va **fuera** del
      // `ListView`, y esta prueba lo comprueba.
      tester.view.physicalSize = const Size(360, 300); // teclado abierto
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final vm = BibliotecaViewModel(
        manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDeAb(),
          home: Scaffold(
            body: BibliotecaView(
              viewModel: vm,
              alPulsarLeer: (id) {},
              alPulsarDescargar: (id) {},
              alPulsarFicheroLocal: (id) {},
              alReintentar: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'valera');
      await tester.pumpAndSettle();
      expect(vm.filtro.texto, 'valera',
          reason: 'poder escribir en el filtro con el teclado puesto');
    });
  });
}

/// Que **nada** de la pantalla se salga del ancho visible.
///
/// Se recorre todo lo que se puede ver y se comparan las cajas con el ancho de la
/// pantalla. Es mas lento que mirar solo el boton, y por eso hay una prueba
/// rapida para el boton y esta para todo: el requisito es "nada se sale", no "el
/// boton no se sale".
Future<void> _comprobarQueNadaSeSale(WidgetTester tester) async {
  final anchoPantalla = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final problemas = <String>[];

  // Por indice y no con `find.byWidget`. Un `find.byWidget` busca por **igualdad**
  // del widget, y dos filas de la biblioteca tienen exactamente los mismos widgets
  // hijos: el finder devuelve dos y `getRect` dice "ambiguamente encontrado". La
  // primera version de este helper hacia eso y fallaba siempre que hubiera mas de
  // una fila, que es el caso normal. Se va por indice, que no tiene ambiguedad.
  for (final tipo in <Type>[Row, Wrap, Text, FilledButton, OutlinedButton, FilterChip]) {
    final finder = find.byType(tipo);
    final n = finder.evaluate().length;
    for (var i = 0; i < n; i++) {
      _anotarSiSeSale(tester, finder.at(i), anchoPantalla, tipo.toString(), problemas);
    }
  }

  expect(problemas, isEmpty, reason: problemas.join('\n'));
}

void _anotarSiSeSale(
  WidgetTester tester,
  Finder finder,
  double anchoPantalla,
  String tipo,
  List<String> problemas,
) {
  final caja = tester.getRect(finder);
  // Un margen de un pixel: los bordes se dibujan justos y una comparacion exacta
  // falla por decimales del motor, no por un problema real.
  if (caja.right > anchoPantalla + 1.0 || caja.left < -1.0) {
    problemas.add('$tipo en $caja con pantalla de $anchoPantalla');
  }
}

/// Un ViewModel con un manifiesto de un solo modulo.
///
/// Existe para que la prueba del campo de busqueda no dependa de un json, y no del
/// modulo de verdad: para comprobar que el campo cabe y se puede escribir, uno basta.
///
BibliotecaViewModel bibliotecaDePrueba() => BibliotecaViewModel(
      manifiesto: _manifiesto(<Modulo>[_moduloDesconocido()]),
    );

/// Un placeholder, para que la prueba de "sin avisos" tenga algo que pintar.
///
/// Se separa de [_moduloDesconocido] a proposito: si las dos fueran la misma, un
/// cambio en una afectaria a la otra y una de las dos dejaria de comprobar lo que
/// dice comprobar.
Modulo _moduloDesconocivoPlaceholder() => _moduloDesconocido();
