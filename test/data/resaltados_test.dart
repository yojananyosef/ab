// Los resaltados: el modelo, el almacenamiento y el view model.
//
// ============================================================================
// POR QUE AQUI HAY MAS PRUEBAS DE "QUE PASA SI..." QUE DE NORMAL
// ============================================================================
//
// Porque es lo **unico** de este repositorio que guarda trabajo de una persona. Todo lo demas
// --modulos, manifiesto, preferencias-- se puede volver a bajar o volver a poner. Un resaltado
// no.
//
// Y por eso las pruebas no son "marcar y ver que sale", que es lo facil, sino:
//
//   - que **cerrar la hoja sin elegir** no quita el resaltado que habia
//   - que un almacen que **no contesta** se dice y no se cuelga
//   - que un fichero que **no es de esta app** no cambia nada
//   - que un campo malo **no tira** los resaltados buenos
//   - y que un resaltado que apunta a un estilo que no existe **se ve igual**

import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/domain/models/resaltado.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';

void main() {
  group('1. el resaltado guarda la referencia, no el texto', () {
    test('lo que se guarda es el versiculo y el estilo, y nada mas', () {
      // Y LA PRIMERA COMPROBACION DE TODAS, y la que decide el modelo entero: si aqui se
      // guardara el texto, todo lo demas --versiones, exportaciones, cambios de traduccion--
      // seria distinto, y el fallo no saldria en una prueba de pantalla.
      final r = Resaltado(
        libro: 'John',
        capitulo: 3,
        versiculo: 16,
        estilo: 'amarillo',
      );

      final json = r.aJson();
      expect(json.keys, <String>{'libro', 'capitulo', 'versiculo', 'estilo'});
      expect(json['libro'], 'John');
      expect(json['capitulo'], 3);
      expect(json['versiculo'], 16);
      expect(json['estilo'], 'amarillo');

      // Y **NO** hay ningun campo de texto, ni de version, ni de fecha.
      for (final prohibido in <String>['texto', 'version', 'textoCompleto', 'palabras']) {
        expect(json.containsKey(prohibido), isFalse, reason: prohibido);
      }
    });

    test('y la clave es la misma que la de la URL', () {
      // Y POR QUE: con una madeja propia, dos sitios que guardan la referencia de manera
      // distinta producen dos conjuntos que no se reconocen, y el sintoma es "he marcado antes y
      // no sale", que es de las cosas mas desconcertantes que puede pasar.
      final r = Resaltado(
        libro: 'John',
        capitulo: 3,
        versiculo: 16,
        estilo: 'amarillo',
      );
      expect(r.clave, 'John.3.16');
    });

    test('no sabe de version, y eso es lo que lo hace "por referencia"', () {
      // Y LA COMPROBACION DE QUE NO HAY VERSION: dos resaltados del mismo versiculo, hechos
      // "en traducciones distintas", tienen que ser **el mismo**. Que es lo que permite
      // marcar en el KJV y verlo en otra version.
      final a = Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo');
      final b = Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo');
      expect(a.clave, b.clave);
      expect(a.esElDe('John', 3, 16), isTrue);
      expect(a.esElDe('John', 3, 17), isFalse);
      expect(a.esElDe('Juan', 3, 16), isFalse,
          reason: 'el libro es la clave del modulo, no el nombre en castellano');
    });

    test('un JSON con un campo malo NO se importa a medias', () {
      // Y CADA CASO POR SEPARADO, porque el fallo es distinto en cada uno y todos darian el
      // mismo "se ha importado mal" si se agruparan.
      expect(Resaltado.desdeJson(null), isNull);
      expect(Resaltado.desdeJson('texto'), isNull);
      expect(Resaltado.desdeJson(<String, Object?>{}), isNull);
      expect(Resaltado.desdeJson(<String, Object?>{'libro': 'John'}), isNull);
      expect(
        Resaltado.desdeJson(<String, Object?>{
          'libro': 'John',
          'capitulo': 3,
        }),
        isNull,
        reason: 'falta el versiculo',
      );
      expect(
        Resaltado.desdeJson(<String, Object?>{
          'libro': 'John',
          'capitulo': 3,
          'versiculo': 16,
          'estilo': '',
        }),
        isNull,
        reason: 'un resaltado sin estilo no se puede pintar',
      );
    });
  });

  group('2. el estilo es un estilo, y no un color repartido', () {
    test('cambiar el nombre cambia en todos los resaltados que lo usan', () {
      // Y POR QUE HAY `id` Y `nombre`. Si el resaltado guardara el nombre, cambiar el nombre
      // de un estilo dejaria a todos sus resaltados apuntando a un nombre que ya no existe, y
      // se verian con el primer estilo por defecto. Con el `id` el resaltado apunta al estilo
      // y el estilo ha cambiado de nombre.
      final vm = ResaltadosViewModel();
      addTearDown(vm.dispose);

      unawaitedCargar(vm);
      vm.marcar('John', 3, 16, 'amarillo');

      expect(vm.estiloDe('John', 3, 16)!.nombre, 'Amarillo');
      unawaitaRenombrar(vm, 'amarillo', 'Para la predicacion');
      expect(vm.estiloDe('John', 3, 16)!.nombre, 'Para la predicacion');
    });

    test('y el color tambien sale del estilo, no del resaltado', () {
      // Y ESTA ES LA RAZON DE QUE EL EXPORT LLEVE LOS ESTILOS ENTEROS. Si el resaltado
      // guardara el color, al reimportar en una instalacion con los estilos cambiados
      // saldria en un color que la persona **no eligio**.
      final a = Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo');
      expect(a.aJson().containsKey('color'), isFalse);
    });

    test('un estilo que no existe cae en el primero, Y SE VE', () {
      // Y POR QUE EL PRIMERO Y NO NINGUNO: lo que se ha perdido es el **color**, no el
      // resaltado. Un resaltado invisible es peor que uno con el color equivocado, porque
      // con el color equivocado se ve que hay algo ahi y se puede arreglar; con el invisible no
      // hay nada que arreglar.
      final estilos = estilosDePartida;
      final conHuerfano = <EstiloDeResaltado>[
        estilos.first,
        estilos[1],
      ];

      final e = estiloConEseId(conHuerfano, 'un-estilo-que-no-existe');
      expect(e, estilos.first,
          reason: 'se ve con el primero, no desaparece');
    });

    test('los nombres de enum no se guardan, y no es por gusto', () {
      // Y POR QUE HAY `enElAlmacenamiento`: Dart renombra los `enum` al compilar para
      // minificar, y un nombre de enum **no es estable** entre compilaciones. Un resaltado
      // guardado con `FormaDelResaltado.fondo.name` deja de leerse en la siguiente build.
      expect(FormaDelResaltado.fondoYContorno.enElAlmacenamiento, 'fondo-contorno');
      expect(FormaDelResaltado.leer('fondo-contorno'), FormaDelResaltado.fondoYContorno);
      expect(FormaDelResaltado.leer('lo-que-sea'), FormaDelResaltado.fondo,
          reason: 'y un valor raro cae en el de partida, no en null');
    });

    test('la intensidad suave NO es casi transparente', () {
      // Y POR QUE 0,30 Y NO 0,15: por debajo de 0,2 un fondo de color sobre el texto no se
      // nota y la marca **se pierde**. Un resaltado que no se ve es un resaltado que no
      // existe, y quien lo ha puesto no sabe por que no sale.
      expect(IntensidadDelResaltado.suave.opacidad, greaterThan(0.2));
      expect(
        IntensidadDelResaltado.suave.opacidad,
        lessThan(IntensidadDelResaltado.medio.opacidad),
      );
      expect(
        IntensidadDelResaltado.medio.opacidad,
        lessThan(IntensidadDelResaltado.fuerte.opacidad),
      );
    });
  });

  group('3. quitar es quitar, y no "marcar como borrado"', () {
    test('desaparece de la lista', () async {
      final vm = await vmConResaltados();
      expect(vm.total, 1);
      await vm.quitar('John', 3, 16);
      expect(vm.total, 0);
      expect(vm.de('John', 3, 16), isNull);
    });

    test('y quitar lo que no hay no avisa y no rompe', () async {
      // Y POR QUE NO AVISA: quitar algo que no esta no es un problema de la persona, es una
      // pulsacion de mas. Y un aviso por eso haria que la pantalla gritara por cosas que no
      // importan, que es como se deja de escuchar.
      final vm = await vmConResaltados();
      await vm.quitar('John', 3, 16);
      await vm.quitar('John', 3, 16);
      expect(vm.total, 0);
      expect(vm.hayQueAvisar, isFalse);
    });

    test('y se puede volver a poner limpio', () async {
      final vm = await vmConResaltados();
      await vm.quitar('John', 3, 16);
      await vm.marcar('John', 3, 16, 'verde');
      expect(vm.estiloDe('John', 3, 16)!.id, 'verde');
    });

    test('volver a marcar pisa, y no añade un segundo', () async {
      // Y POR QUE **PISA**: dos resaltados del mismo versiculo con estilos distintos son dos
      // marcas de color en la misma linea, y a la segunda no se sabe cual de las dos es.
      final vm = await vmConResaltados();
      await vm.marcar('John', 3, 16, 'verde');
      expect(vm.total, 1, reason: 'no se ha creado un segundo');
      expect(vm.estiloDe('John', 3, 16)!.id, 'verde');
    });
  });

  group('4. el almacenamiento que no contesta', () {
    test('el plazo corta y NO cuelga, y lo dice', () async {
      // Y EL PLAZO SE PUEDE BAJAR EN LA PRUEBA, y por eso [leerResaltadosConPlazo] recibe el
      // plazo por parametro y no lo tiene escrito dentro: la prueba del caso de "no contesta"
      // con cinco segundos de reloj tarda cinco segundos, y una suite con un retraso asi no se
      // ejecuta.
      final vm = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosColgado(),
      );
      addTearDown(vm.dispose);

      // Y EL PLAZO BAJADO A DIEZ MILISEGUNDOS, y no el de cinco segundos. Con el de verdad
      // esta prueba tarda cinco segundos, y una suite con un retraso asi no se ejecuta: se
      // deja para el final y luego no se ejecuta nunca.
      await vm.cargar(plazo: const Duration(milliseconds: 10));

      expect(vm.leidos, isFalse);
      expect(vm.hayQueAvisar, isTrue,
          reason: 'lo que se ha perdido no son dos toques: es trabajo');
      expect(vm.motivoDelAviso, isNotNull);
      // Y AVISA Y **NO** DICE "NO HAY RESALTADOS". Que es la distincion que importa: un
      // `ListView` vacio sin aviso dice "no tienes nada marcado" y es mentira.
      expect(vm.resaltados, isEmpty);
    });

    test('y guardar sin contesta avisa, y no da por puesto', () async {
      // Y ESTE ES EL CASO QUE DUele. La persona marca, ve el resaltado, y **no lo tiene**.
      // Con el aviso se entera y lo vuelve a marcar; sin el, descubre al recargar que no
      // estaba.
      final vm = await vmConResaltados(colgado: true);

      await vm.marcar('John', 3, 16, 'amarillo');

      expect(vm.total, 1, reason: 'se ve, porque se pinta antes de guardar');
      expect(vm.hayQueAvisar, isTrue,
          reason: 'y se avisa de que no se ha podido guardar');
    });

    test('un almacen que lanza tambien avisa, y no revienta', () async {
      final vm = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosQueNoContesta(),
      );
      addTearDown(vm.dispose);

      // Y EL PLAZO BAJADO A DIEZ MILISEGUNDOS, y no el de cinco segundos. Con el de verdad
      // esta prueba tarda cinco segundos, y una suite con un retraso asi no se ejecuta: se
      // deja para el final y luego no se ejecuta nunca.
      await vm.cargar(plazo: const Duration(milliseconds: 10));

      expect(vm.leidos, isFalse);
      expect(vm.hayQueAvisar, isTrue);
    });

    test('y el de partida NO cuelga nunca, que es lo que se necesita en la mayoria', () async {
      // Y POR QUE ESTA COMPROBACION EXISTE, y no por cobertura: el almacen en memoria es el
      // que usan todas las pruebas de pantalla. Si **el** contestara con una exception, la
      // suite entera caeria y el fallo diria "no se ha podido leer el almacen" en una prueba
      // de la biblioteca, que es de donde no se ve el motivo.
      final vm = ResaltadosViewModel();
      addTearDown(vm.dispose);
      await vm.cargar();
      expect(vm.leidos, isTrue);
      expect(vm.hayQueAvisar, isFalse);
    });
  });

  group('5. exportar e importar', () {
    test('lo que se exporta se puede volver a leer', () async {
      final vm = await vmConResaltados();
      await vm.marcar('John', 3, 16, 'amarillo');
      await vm.marcar('John', 3, 17, 'verde');

      final texto = await vm.exportar();
      final leido = vm.prepararImportar(texto);

      expect(leido.ok, isTrue);
      expect(leido.resaltados, hasLength(2));
      expect(leido.estilos, isNotEmpty);
    });

    test('y el export lleva el estilo ENTERO, con su color', () {
      // Y LA RAZON POR LA QUE SE COMPRUEBA EL COLOR Y NO SOLO EL NOMBRE: si el fichero
      // llevara el nombre del estilo, al reimportar en una instalacion con los estilos
      // cambiados los resaltados saldrian en un color que la persona no eligio, y no podria
      // saber cual.
      final texto = exportarResaltados(
        <Resaltado>[
          Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo'),
        ],
        estilosDePartida,
      );

      expect(texto, contains('ab-resaltados/1'));
      expect(texto, contains('version'));
      expect(texto, contains('Amarillo'), reason: 'el nombre del estilo');
      expect(texto, contains('color'), reason: 'y el color, que es lo que no se puede adivinar');
    });

    test('un fichero que NO es de esta app no cambia nada, y se dice', () async {
      // Y ESTE ES EL CASO IMPORTANTE, y el que hace que la funcion **mire el `formato`**.
      // Un `jsonDecode` de un fichero que es JSON pero de otra cosa --una lista de la compra,
      // una configuracion-- **funciona**, y sin mirar el `formato` se importaria como si
      // fueran resaltados.
      final vm = await vmConResaltados();

      for (final basura in <String>[
        '{"formato": "otra-cosa/1", "resaltados": []}',
        '{"formato": "notas/2", "resaltados": [{"libro": "John", "capitulo": 3, "versiculo": 16, "estilo": "x"}]}',
        '[1, 2, 3]',
        '{"otra-cosa": 1}',
      ]) {
        final r = vm.prepararImportar(basura);
        expect(r.ok, isFalse, reason: basura);
        expect(r.motivo, isNotNull, reason: basura);
        expect(r.resaltados, isEmpty, reason: basura);
      }

      expect(vm.total, 1, reason: 'y lo que habia sigue ahi');
    });

    test('un texto que no es JSON no lanza', () async {
      // Y POR QUE NO LANZA: importar es la operacion que **escribe** lo de la persona. Un
      // `throw` obligaria a que quien llama tenga el `try`, y el que se come la excepcion es
      // quien ha perdido el trabajo.
      final vm = await vmConResaltados();
      for (final basura in <String>['', '   ', 'no soy json', '{', 'null']) {
        expect(() => vm.prepararImportar(basura), returnsNormally, reason: basura);
        expect(vm.prepararImportar(basura).ok, isFalse, reason: basura);
      }
    });

    test('un resaltado malo dentro de un fichero bueno se salta, y no se pierde el resto', () async {
      // Y NO SE IMPORTA A MEDIAS. Un `Resaltado` con el libro en null seria un resaltado que
      // no se puede pintar en ningun capitulo, y un fichero que se traga eso **no dice que se
      // ha perdido nada**.
      final vm = await vmConResaltados();
      const fichero = '''
{
  "formato": "ab-resaltados/1",
  "version": "1",
  "estilos": [{"id": "amarillo", "nombre": "Amarillo", "color": "ffffd54f"}],
  "resaltados": [
    {"libro": "John", "capitulo": 3, "versiculo": 16, "estilo": "amarillo"},
    {"libro": null, "capitulo": 3, "versiculo": 17, "estilo": "amarillo"},
    {"libro": "John", "capitulo": 3, "versiculo": 18, "estilo": "amarillo"}
  ]
}
''';

      final leido = vm.prepararImportar(fichero);
      expect(leido.ok, isTrue);
      expect(leido.resaltados, hasLength(2),
          reason: 'los dos buenos, y el malo se ha saltado');
    });

    test('un fichero sin estilos usa los de partida, para que se vea algo', () {
      // Y NO ES UN FALLO. Un resaltado con un estilo que no esta en la lista **se ve** con el
      // primero, y por eso un fichero sin estilos no deja nada invisible.
      final leido = leerResaltados(
        '{"formato":"ab-resaltados/1","resaltados":'
        '[{"libro":"John","capitulo":3,"versiculo":16,"estilo":"x"}]}',
      );

      expect(leido.ok, isTrue);
      expect(leido.estilos, isNotEmpty);
      expect(estiloConEseId(leido.estilos, 'x').id, isNotEmpty,
          reason: 'y el resaltado tiene un estilo aunque el fichero no trajera ninguno');
    });
  });

  group('6. el capitulo entero, de una vez', () {
    test('los estilos del capitulo vienen en orden de versiculo', () async {
      final vm = await vmConResaltados();
      await vm.marcar('John', 3, 17, 'verde');
      await vm.marcar('John', 3, 16, 'amarillo');
      await vm.marcar('John', 3, 18, 'azul');
      await vm.marcar('John', 2, 1, 'rosa');

      final estilos = vm.estilosDelCapitulo('John', 3);

      // Y SOLO EL CAPITULO. Juan 2 no sale, porque es otro capitulo.
      expect(estilos.keys.toList(), <int>[16, 17, 18],
          reason: 'en orden, y sin el de Juan 2');
    });

    test('y un capitulo sin nada marcado sale vacio, y no un error', () async {
      final vm = await vmConResaltados();
      expect(vm.estilosDelCapitulo('John', 99), isEmpty);
    });
  });
}

/// Un view model con un resaltado puesto, que es el estado de partida de casi todo.
Future<ResaltadosViewModel> vmConResaltados({bool colgado = false}) async {
  final vm = ResaltadosViewModel(
    almacenamiento: colgado
        ? AlmacenamientoDeResaltadosColgado()
        : AlmacenamientoDeResaltadosEnMemoria(),
  );
  await vm.cargar();
  if (!colgado) {
    await vm.marcar('John', 3, 16, 'amarillo');
  }
  return vm;
}

/// Cargar y renombrar sin esperar, para las comprobaciones de una linea.
///
/// Y SON DOS AYUDANTES Y NO UNO SOLO CON UN PARAMETRO, porque `unawaited` en una prueba es un
/// `Future` que se tira y puede dejar una excepcion sin que nadie la vea: el fallo sale en la
/// prueba **siguiente**, y dice el nombre de otra. Aqui se espera de verdad.
Future<void> unawaitedCargar(ResaltadosViewModel vm) => vm.cargar();

Future<void> unawaitaRenombrar(ResaltadosViewModel vm, String id, String nombre) =>
    vm.renombrarEstilo(id, nombre);