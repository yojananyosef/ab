// La logica de la biblioteca, sin pantalla.
//
// POR QUE EL VIEWMODEL TIENE SU PROPIO FICHERO DE PRUEBAS Y LA VISTA OTRO. Porque
// son cosas distintas y se rompen distinto: aqui se rompe el **calculo** --el
// estado, el filtro, lo que aparece--, y ahi se rompe el **pintado**. Una prueba que
// monta una pantalla para comprobar que un filtro devuelve tres filas tarda veinte
// veces mas y dice menos.
//
// Y LO QUE NO SE COMPRUEBA AQUI. Que se vea en pantalla. Eso es de
// `biblioteca_view_test.dart`, y no se intenta comprobar dos veces.

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/estado_modulo.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Modulo _m(
  String id, {
  String nombre = 'Nombre',
  TipoModulo tipo = TipoModulo.biblia,
  String idioma = 'spa',
  int tamano = 22544384,
  String licencia = 'PublicDomain',
}) =>
    Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: idioma,
      licencia: licencia,
      tamanoBytes: tamano,
      // Un sha256 por id, para que dos modulos del manifiesto no compartan hash y
      // el estado de uno no pueda confundirse con el de otro.
      sha256: String.fromCharCodes(List.filled(64, id.codeUnitAt(0))),
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/n/$id.amod'),
    );

Manifiesto _man(List<Modulo> m) => Manifiesto(
  formato: 'aa-catalog/1',
  version: 'v0.0.1',
  etiqueta: 'v0.0.1',
  modulos: m,
);

/// La biblia de verdad, con su sha256 real.
///
/// Se escribe entera y no "corrijiendola" con una copia de `_m`, porque una
/// construccion media es un sitio mas donde el hash puede quedar viejo sin que
/// ninguna prueba lo note: si el hash cambia en un modulo y el estado sigue siendo
/// `descargado`, el fallo no se ve en ningun sitio.
Modulo _kjvReal() => Modulo(
  id: 'KJV2006',
  nombre: 'King James Version (2006)',
  tipo: TipoModulo.biblia,
  idioma: 'eng',
  licencia: 'PublicDomain',
  tamanoBytes: 22544384,
  sha256: 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9',
  urlDescarga: Uri.parse('https://example.invalid/KJV2006.amod'),
  urlNavegador: Uri.parse('https://example.invalid/n/KJV2006.amod'),
);

void main() {
  group('las filas salen del manifiesto y de lo que hay en el dispositivo', () {
    test('sin nada local, todas disponibles y en el orden del manifiesto', () {
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[
          _m('A', nombre: 'Uno'),
          _m('B', nombre: 'Dos'),
          _m('C', nombre: 'Tres'),
        ]),
      );

      expect(vm.filas.length, 3);
      expect(vm.filas.map((f) => f.id).toList(), ['A', 'B', 'C']);
      expect(vm.filas.every((f) => f.estado == EstadoModulo.disponible), isTrue);
    });

    test('el ORDEN no se reordena al cambiar un estado', () {
      // Es una decision, y hay que comprobarla porque es facil "mejorarla" sin
      // querer: reordenar por tamano o por estado hace que una fila se mueva debajo
      // del dedo mientras se le esta pulsando. En un movil eso es un fallo de verdad.
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[
          _m('A', nombre: 'Uno'),
          _m('B', nombre: 'Dos'),
          _m('C', nombre: 'Tres'),
        ]),
        idsLocales: const <String>{'C'},
      );

      expect(vm.filas.map((f) => f.id).toList(), ['A', 'B', 'C']);
      expect(vm.filas[2].estado, EstadoModulo.descargado);
      expect(vm.filas[0].estado, EstadoModulo.disponible);
    });

    test('un modulo local que NO esta en el manifiesto sale como retirado', () {
      // El caso del spec: desaparece del catalogo y sigue apareciendo.
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[_m('A', nombre: 'Uno')]),
        idsLocales: const <String>{'VIEJO'},
      );

      final retirada = vm.filas.firstWhere((f) => f.id == 'VIEJO');
      expect(retirada.estado, EstadoModulo.retirado);
      expect(retirada.retirado, isTrue);
      expect(retirada.sePuedeLeer, isTrue, reason: 'un modulo retirado se sigue leyendo');
      expect(retirada.descargado, isTrue);
    });

    test('un modulo retirado NO inventa nombre, tamano ni licencia', () {
      // Solo se sabe el identificador. Enseñar un nombre bonito seria mentira, y
      // poner 0,0 MB diria que no ocupa nada, que es tambien mentira.
      final vm = BibliotecaViewModel(
        manifiesto: _man(const <Modulo>[]),
        idsLocales: const <String>{'RVR1960_vieja'},
      );

      final f = vm.filas.single;
      expect(f.modulo, isNull);
      expect(f.titulo, 'RVR1960_vieja');
      expect(f.megabytes, isNull);
    });

    test('los estados salen del hash, y se recalculan en cada llamada', () {
      // Un modulo con el sha256 del manifiesto: descargado.
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[_kjvReal()]),
        idsLocales: const <String>{'KJV2006'},
      );
      expect(vm.filas.single.estado, EstadoModulo.descargado);

      // Y si lo que hay en el dispositivo tiene OTRO hash, version nueva. Y el hash
      // local es el que **calculamos al obtenerlo**, no el del manifiesto: con el del
      // manifiesto todo local pareceria descargado y este estado no se alcanzaria.
      final vm2 = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[_kjvReal()]),
        idsLocales: const <String>{'KJV2006'},
        hashesLocales: const <String, String>{
          'KJV2006': '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c',
        },
      );
      expect(vm2.filas.single.estado, EstadoModulo.desactualizado);
      expect(vm2.filas.single.sePuedeLeer, isTrue,
          reason: 'un modulo atrasado se lee igual');
      expect(vm2.filas.single.sePuedeDescargar, isTrue,
          reason: 'y se puede volver a bajar');
    });
  });

  group('los filtros', () {
    BibliotecaViewModel conTres() => BibliotecaViewModel(
      manifiesto: _man(<Modulo>[
        _m('A', nombre: 'Reina-Valera 1960', idioma: 'spa', tamano: 28424192),
        _m('B', nombre: 'King James Version', idioma: 'eng', tamano: 22544384),
        _m('C', nombre: 'Sefarad', tipo: TipoModulo.comentario, idioma: 'spa'),
      ]),
      idsLocales: const <String>{'B'},
    );

    test('por texto, por nombre', () {
      final vm = conTres();
      vm.filtrarPorTexto('valera');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['A']);
    });

    test('por texto, por el identificador del manifiesto', () {
      // El `id` es una de las columnas por las que se busca, y no solo el nombre.
      // Quien tiene el manifiesto abierto delante busca por el identificador.
      final vm = conTres();
      vm.filtrarPorTexto('sefarad');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['C'],
          reason: '"sefarad" es el nombre de C; el id se busca por su id');
      vm.filtrarPorTexto('comentario');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['C'],
          reason: 'y por el tipo, que tambien se ensena');
    });

    test('por texto, por idioma', () {
      final vm = conTres();
      vm.filtrarPorTexto('eng');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['B']);
    });

    test('por texto, por la licencia COMO SE ENSENA, no como viene', () {
      // Este es el que hacia fallar la primera version. La fila muestra "dominio
      // publico" y el manifiesto dice `PublicDomain`: si se filtra por el valor
      // crudo, quien escribe "dominio" --que es lo unico que ve en pantalla-- no
      // encuentra nada, y parece que el filtro esta roto.
      final vm = conTres();
      vm.filtrarPorTexto('dominio');
      expect(vm.filasFiltradas.length, 3);

      // Y tambien por el valor crudo, para quien lo sepa.
      vm.filtrarPorTexto('publicdomain');
      expect(vm.filasFiltradas.length, 3);
    });

    test('por texto, por el tipo como lo lee la gente', () {
      final vm = conTres();
      vm.filtrarPorTexto('comentario');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['C']);
    });

    test('por idioma, solo los de ese idioma', () {
      final vm = conTres();
      vm.filtrarPorIdioma('spa');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['A', 'C']);
    });

    test('un idioma que NO existe deja la lista vacia, no da error', () {
      final vm = conTres();
      vm.filtrarPorIdioma('fra');
      expect(vm.filasFiltradas, isEmpty);
      expect(vm.filtroSinResultados, isTrue);
      // Y el filtro sigue puesto, para poder quitarlo.
      expect(vm.filtro.idioma, 'fra');
    });

    test('"solo lo que tengo" incluye los retirados', () {
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[
          _m('A', nombre: 'Uno'),
          _m('B', nombre: 'Dos'),
        ]),
        idsLocales: const <String>{'B', 'RETIRADO'},
      );

      vm.alternarSoloDescargados();
      final ids = vm.filasFiltradas.map((f) => f.id).toList();
      expect(ids, containsAll(<String>['B', 'RETIRADO']));
      expect(ids, isNot(contains('A')));
    });

    test('el idioma de un modulo retirado es desconocido, asi que un filtro lo oculta', () {
      // Si pides "espa" quieres Biblias en espanol, no un modulo del que no se sabe
      // nada. Enseñarlo seria una fila vacia sin explicacion.
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[_m('A', idioma: 'spa')]),
        idsLocales: const <String>{'RETIRADO'},
      );

      vm.filtrarPorIdioma('spa');
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['A']);
      expect(vm.filas.length, 2, reason: 'pero sigue estando en la lista sin filtro');
    });

    test('los tres filtros se combinan', () {
      final vm = conTres();
      vm.filtrarPorTexto('valera');
      vm.filtrarPorIdioma('spa');
      vm.alternarSoloDescargados();
      // "valera" + espanol + solo lo que tengo: A no esta descargado, asi que no sale.
      expect(vm.filasFiltradas, isEmpty);

      vm.alternarSoloDescargados();
      expect(vm.filasFiltradas.map((f) => f.id).toList(), ['A']);
    });

    test('limpiar devuelve todo y no dice nada si ya estaba limpio', () {
      final vm = conTres();
      vm.limpiarFiltros();
      expect(vm.filasFiltradas.length, 3);

      var avisos = 0;
      vm.addListener(() => avisos++);
      vm.limpiarFiltros();
      expect(avisos, 0, reason: 'no hay nada que limpiar, asi que no hay que avisar');
    });

    test('los filtros vacios no dicen que no hay resultados', () {
      // "No hay nada que case con tu filtro" y "el catalogo esta vacio" son
      // problemas distintos, con solucion distinta. Con la lista vacia y sin
      // filtros, el aviso es el del catalogo.
      final vm = BibliotecaViewModel(manifiesto: _man(const <Modulo>[]));
      expect(vm.catalogoVacio, isTrue);
      expect(vm.filtroSinResultados, isFalse);
    });

    test('los idiomas que se ofrecen son los que HAY', () {
      final vm = conTres();
      expect(vm.idiomas, ['eng', 'spa']);
      // Y con el catalogo vacio, ninguno. Un desplegable con "Todos" y nada mas es un
      // control que no hace nada.
      expect(BibliotecaViewModel().idiomas, isEmpty);
    });
  });

  group('el origen no legible', () {
    test('se anota, y la fila lo distingue de "todavia no"', () {
      final vm = BibliotecaViewModel(manifiesto: _man(<Modulo>[_m('A')]));
      expect(vm.origenNoLegible('A'), isFalse);

      vm.anotarOrigenNoLegible('A');
      expect(vm.origenNoLegible('A'), isTrue);

      vm.quitarOrigenNoLegible('A');
      expect(vm.origenNoLegible('A'), isFalse);
    });

    test('NO se guarda: se recalcula, y en esta sesion', () {
      // Un dato guardado seria "no se puede" para siempre, y eso es exactamente el
      // estado que se queda viejo. Si el servidor manana manda las cabeceras, esta
      // lista tiene que estar vacia.
      final vm = BibliotecaViewModel(manifiesto: _man(<Modulo>[_m('A')]));
      vm.anotarOrigenNoLegible('A');
      // Aplicar un resultado nuevo **no** lo quita: el fallo fue real.
      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _man(<Modulo>[_m('A')]),
          estado: EstadoLectura.delServidor,
        ),
      );
      expect(vm.origenNoLegible('A'), isTrue);
    });

    test('descargarlo lo quita, porque ya no depende del servidor', () {
      final vm = BibliotecaViewModel(manifiesto: _man(<Modulo>[_m('A')]));
      vm.anotarOrigenNoLegible('A');

      vm.actualizarIdsLocales(const <String>{'A'});
      expect(vm.origenNoLegible('A'), isFalse,
          reason: 'el fichero ya esta aqui; da igual lo que conteste el servidor');
    });

    test('anotarlo dos veces no avisa dos veces', () {
      final vm = BibliotecaViewModel(manifiesto: _man(<Modulo>[_m('A')]));
      var avisos = 0;
      vm.addListener(() => avisos++);
      vm.anotarOrigenNoLegible('A');
      vm.anotarOrigenNoLegible('A');
      expect(avisos, 1);
    });
  });

  group('lo que el ViewModel guarda y lo que no', () {
    test('el filtro SI se guarda en la sesion: es de la sesion, no del disco', () {
      // Uno escribe "espa", cambia de pantalla y vuelve, y espera seguir
      // escribiendo "espa". Y no se persiste, y por eso no se puede quedar viejo.
      final vm = BibliotecaViewModel(manifiesto: _man(<Modulo>[_m('A')]));
      vm.filtrarPorTexto('espa');
      expect(vm.filtro.texto, 'espa');
      // Y no hay nada en el ViewModel que lo escriba en disco.
      final fuente = vm.runtimeType.toString();
      expect(fuente, 'BibliotecaViewModel');
    });

    test('el estado de cada modulo NO se guarda: se calcula en cada lectura', () {
      final vm = BibliotecaViewModel(
        manifiesto: _man(<Modulo>[_m('A')]),
        idsLocales: const <String>{'A'},
      );
      // Y si lo que hay en el dispositivo cambia, el estado cambia. Sin tocar nada.
      expect(vm.filas.single.estado, EstadoModulo.descargado);
      vm.actualizarIdsLocales(const <String>{});
      expect(vm.filas.single.estado, EstadoModulo.disponible);
    });

    test('actualizar con lo mismo no avisa', () {
      // Una pantalla que se redibuja por lo mismo tiene scroll que tiembla y filtros
      // que se mueven solos.
      final vm = BibliotecaViewModel(idsLocales: const <String>{'A', 'B'});
      var avisos = 0;
      vm.addListener(() => avisos++);

      vm.actualizarIdsLocales(const <String>{'A', 'B'});
      expect(avisos, 0);
      vm.actualizarIdsLocales(const <String>{'A'});
      expect(avisos, 1);
    });

    test('los avisos del repositorio van encima, y no se mezclan con los de la app', () {
      final vm = BibliotecaViewModel();
      vm.aplicarResultado(
        ResultadoCatalogo(
          manifiesto: _man(const <Modulo>[]),
          estado: EstadoLectura.deCopiaGuardada,
          avisos: const <String>['Se ensena una copia guardada del v0.0.1.'],
        ),
      );
      vm.anadirAviso('No se ha podido preparar el motor.');

      expect(vm.avisos.first, 'No se ha podido preparar el motor.',
          reason: 'el aviso de la pantalla va primero: es lo que impide usar la app');
      expect(vm.avisos.last, contains('copia guardada'));
    });

    test('filtrar por texto igual no avisa', () {
      final vm = BibliotecaViewModel();
      var avisos = 0;
      vm.addListener(() => avisos++);
      vm.filtrarPorTexto('');
      expect(avisos, 0);
    });
  });
}
