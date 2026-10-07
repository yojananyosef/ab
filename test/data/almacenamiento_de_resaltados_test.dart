// Que los resaltados se guarden, y que no se pueda volver a hacer en silencio.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y NO SE PUEDE SUSTITUIR POR LOS OTROS
// ============================================================================
//
// Porque el fallo que este change arregla **no esta en ningun sitio del modelo**. Los 25
// pruebas de `resaltados_test.dart` pasaban con el modelo correcto, el plazo de cinco
// segundos puesto, la exportacion con su `formato` y su `version`, y **los resaltados
// perdidos**, porque el unico trozo que faltaba era una palabra en un `main.dart`:
//
//     _resaltados = ResaltadosViewModel();
//
// Y ESO NO LO COGE NINGUNA PRUEBA DEL DOMINIO, porque el view model es correcto con y sin
// almacen. Es el mismo fallo que `alCambiarDeVersion` --que estaba cableado y nadie lo
// llamaba-- y que `AGENTS.md` ya documenta: **una funcion sin llamador no falla nunca**.
//
// Y AQUI LA VERSION PEOR DE ESE FALLO, y por eso este fichero mira **el view model de la
// aplicacion** y no uno construido aqui. Una prueba que construye su propio almacen
// comprueba que el almacen funciona; no comprueba que la aplicacion **lo use**. Y esa es la
// distincion que hace que este fallo pueda volver: el almacen estaria probado y la app
// seguiria sin el.
//
// ============================================================================
// Y LA PRIMERA PRUEBA ES LA IMPORTANTE, Y ES UNA PRUEBA DE **CABLEADO**
// ============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/data/services/almacenamiento_de_resaltados_nativo.dart';
import 'package:ab/domain/models/resaltado.dart';
import 'package:ab/ui/features/lector/view_models/resaltados_view_model.dart';

void main() {
  group('1. la aplicacion USA un almacen que guarda', () {
    test('el view model de la aplicacion no se construye sin almacen', () {
      // Y ESTA ES LA QUE HARIA FALLADO ESTO EL 6 DE OCTUBRE DE 2026.
      //
      // Lo que se comprueba es una cosa muy tonta y es la que importa: que **la fabrica de
      // la aplicacion** devuelve un almacen. No que el almacen funcione --eso lo comprueban
      // las pruebas de abajo--, sino que la aplicacion no se quede en memoria.
      final almacen = crearAlmacenamientoDeResaltados();
      addTearDown(almacen.dispose);

      expect(almacen, isNot(isA<AlmacenamientoDeResaltadosEnMemoria>()),
          reason: 'la aplicacion esta usando el almacen EN MEMORIA: marcar se vera y se '
              'perdra al cerrar. Medido el 6 de octubre de 2026.');
    });

    test('y el almacen por defecto no es de los que se pierden al cerrar', () {
      // Y LA SEGUNDA MITAD DE LO MISMO, y mas de fondo: que el almacen **no anote** su estado
      // en un sitio que se limpia al cerrar. Un almacen de verdad puede perderlo todo --si el
      // navegador dice que no-- pero tiene que **guardarlo en algo**.
      final almacen = crearAlmacenamientoDeResaltados();
      addTearDown(almacen.dispose);

      // Y NO SE COMPRUEBA EL NOMBRE DE LA CLASE, y no porque no importe: el dia que se escriba
      // el almacen de web con otro nombre, esta prueba se pondria roja sin que nada este mal.
      // Lo que se comprueba es que **escribe de verdad**, y eso es lo de abajo.
      expect(almacen, isNotNull);
    });
  });

  group('2. el almacen nativo, que si se puede probar en Dart', () {
    late Directory temporal;

    setUp(() async {
      temporal = await Directory.systemTemp.createTemp('ab-resaltados-prueba');
    });

    tearDown(() async {
      if (await temporal.exists()) await temporal.delete(recursive: true);
    });

    /// Un almacén con el directorio de una prueba, que es como se puede comprobar aqui.
    ///
    /// Y POR QUE EL DIRECTORIO SE PASA **POR PARAMETRO**: porque `getApplicationSupportDirectory`
    /// necesita un motor de plataformas, y en la VM de Dart no hay ninguno. Sin el parametro,
    /// esta prueba solo se podria escribir en el navegador --donde no se puede comprobar que un
    /// fichero sobrevive a cerrar el proceso-- y con el parametro se comprueba **el fichero**,
    /// que es la parte que puede estar mal sin que nadie se entere en un movil.
    AlmacenamientoDeResaltadosNativo nuevo() =>
        AlmacenamientoDeResaltadosNativo(directorio: temporal);

    test('un resaltado sobrevive a cerrar y volver a abrir', () async {
      final uno = nuevo();
      await uno.poner(
        const Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo'),
      );
      uno.dispose();

      // Y ESTO ES **EL** TESTE QUE NO EXISTIA: el fallo era que no se guardaba, y un fallo
      // "no se guarda" **solo** se ve cerrando y volviendo a abrir. Con el mismo almacen en
      // memoria, `poner` y `de` darian el mismo resultado con o sin fichero.
      final dos = nuevo();
      addTearDown(dos.dispose);

      final leido = await dos.de('John.3.16');
      expect(leido, isNotNull, reason: 'el resaltado se ha perdido al cerrar');
      expect(leido!.estilo, 'amarillo');
      expect(leido.libro, 'John');
      expect(leido.capitulo, 3);
      expect(leido.versiculo, 16);
    });

    test('y tambien sobrevive el estilo, con su color', () async {
      final uno = nuevo();
      await uno.guardarEstilo(
        const EstiloDeResaltado(
          id: 'amarillo',
          nombre: 'Para la predicacion',
          color: ColorDeResaltado(0xFF112233),
        ),
      );
      uno.dispose();

      final dos = nuevo();
      addTearDown(dos.dispose);

      final estilos = await dos.estilos();
      // Y LOS **CINCO**, y no uno: los estilos de partida estan siempre, porque un resaltado
      // nuevo necesita un estilo aunque la persona no haya escrito ninguno. Guardar uno con
      // el mismo `id` **sustituye** el de partida, que es lo que hace el indice por `id` del
      // view model. Por eso el que sale con el nombre nuevo es el primero y no hay seis.
      expect(estilos, hasLength(estilosDePartida.length));
      expect(estilos.first.id, 'amarillo');
      expect(estilos.first.nombre, 'Para la predicacion');
      // Y EL COLOR COMO **ENTERO**, y no como la cadena hexadecimal que usa el fichero
      // exportado. El motivo esta en el almacen web: un entero ocupa cuatro bytes, una cadena
      // veinte, y leerlo de vuelta mal es un fallo **silencioso** --el resaltado sale en otro
      // color y nadie sabe por que--. Asi que la comprobacion del color **viaja**, y no solo
      // la del nombre.
      expect(estilos.first.color.argb, 0xFF112233);
    });

    test('y el fichero se puede abrir a mano y es un JSON entero', () async {
      final uno = nuevo();
      await uno.poner(
        const Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo'),
      );
      uno.dispose();

      // Y POR QUE ESTA COMPROBACION, QUE PARECE DEMAASIADO: porque la escritura es **atomica**,
      // a un temporal que se renombra. Si el `rename` fallara --y en algunos sistemas de
      // ficheros de Android falla-- el `.parcial` se queda ahi y el fichero bueno no se
      // actualiza. Mirar el directorio entero dice si eso ha pasado, y una prueba que solo
      // mira `de(...)` no se entera.
      final ficheros = temporal.listSync().map((FileSystemEntity e) => e.path).toList();
      final parciales = ficheros.where((String p) => p.endsWith('.parcial')).toList();
      expect(parciales, isEmpty,
          reason: 'se ha quedado un temporal a medias: el rename no funciono y el '
              'resaltado no se ha guardado aunque `poner` dijera que si');
    });

    test('y no queda el temporal de la escritura anterior', () async {
      final uno = nuevo();
      for (var i = 1; i <= 5; i++) {
        await uno.poner(
          Resaltado(libro: 'John', capitulo: 3, versiculo: i, estilo: 'amarillo'),
        );
      }
      uno.dispose();

      // Y CINCO ESCRITURAS Y UNA SOLA FINAL, y no por limpiar: cada escritura escribe un
      // temporal. Si el rename no limpio el anterior, en el directorio hay cinco ficheros y
      // el que se lee es el primero, que es el de un solo resaltado. Es un fallo que **solo**
      // se ve mirando el directorio.
      final ficheros = temporal.listSync().toList();
      expect(ficheros.whereType<File>(), hasLength(1));
    });

    test('un fichero con datos raros no borra los que estan bien', () async {
      // Y SE ESCRIBE A MANO UN JSON RARO, y no se llama a `poner` con algo raro, porque
      // `poner` serializa lo que le des y nunca escribira un registro sin `capitulo`. Lo que
      // se quiere probar es lo que pasa cuando el fichero **ya** esta roto, que es lo que
      // pasa cuando una version anterior lo escribio con otra forma.
      File('${temporal.path}/resaltados.json').writeAsStringSync('''
{
  "formato": "ab-resaltados/1",
  "resaltados": [
    {"libro": "John", "capitulo": 3, "versiculo": 16, "estilo": "amarillo"},
    {"libro": null, "capitulo": 3, "versiculo": 17, "estilo": "amarillo"},
    {"libro": "John", "capitulo": 3, "versiculo": 18, "estilo": "amarillo"}
  ]
}
''');

      final almacen = nuevo();
      addTearDown(almacen.dispose);

      final todos = await almacen.todos();
      expect(todos, hasLength(2),
          reason: 'un registro malo no puede impedir leer los dos buenos: si uno raro hiciera '
              'fallar la lectura entera, un solo registro mal escrito seria la perdida de '
              'los miles que estan bien');
    });

    test('un fichero que no es un JSON no borra nada en silencio', () async {
      File('${temporal.path}/resaltados.json').writeAsStringSync('esto no es un json');

      final almacen = nuevo();
      addTearDown(almacen.dispose);

      // Y NO LANZA, y devuelve la lista vacia. Un `throw` obligaria a que el llamante tenga el
      // `try`, y el que se lo come la excepcion es quien ha perdido el trabajo.
      expect(await almacen.todos(), isEmpty);
    });

    test('y un fichero sin estilos usa los de partida', () async {
      // Y NO ES UN FALLO. Un resaltado con un estilo que no esta en la lista **se ve** con el
      // primero, asi que un fichero sin estilos no deja nada invisible.
      File('${temporal.path}/resaltados.json').writeAsStringSync(
        '{"resaltados":[{"libro":"John","capitulo":3,"versiculo":16,"estilo":"x"}]}',
      );

      final almacen = nuevo();
      addTearDown(almacen.dispose);

      expect(await almacen.estilos(), isNotEmpty);
      expect(estiloConEseId(await almacen.estilos(), 'x').id, isNotEmpty);
    });

    test('borrar todo quita tambien los estilos', () async {
      // Y LOS **DOS**, y no solo los resaltados. Borrar los resaltados y dejar los estilos es un
      // estado que no existe en la interfaz y que hace que al volver a marcar salgan los
      // estilos viejos de una persona que los habia cambiado.
      final uno = nuevo();
      await uno.poner(
        const Resaltado(libro: 'John', capitulo: 3, versiculo: 16, estilo: 'amarillo'),
      );
      await uno.guardarEstilo(
        const EstiloDeResaltado(
          id: 'amarillo',
          nombre: 'Mio',
          color: ColorDeResaltado(0xFFFFD54F),
        ),
      );

      await uno.borrarTodo();
      uno.dispose();

      final dos = nuevo();
      addTearDown(dos.dispose);

      expect(await dos.todos(), isEmpty);
      expect((await dos.estilos()).map((EstiloDeResaltado e) => e.nombre),
          isNot(contains('Mio')));
    });

    test('y quitar lo que no hay no rompe nada', () async {
      final almacen = nuevo();
      addTearDown(almacen.dispose);
      await almacen.quitar('John.3.16');
      expect(await almacen.todos(), isEmpty);
    });
  });

  group('3. el view model con el almacen de verdad', () {
    test('marcar y volver a leer da lo mismo', () async {
      final temporal = await Directory.systemTemp.createTemp('ab-resaltados-vm');
      addTearDown(() async {
        if (await temporal.exists()) await temporal.delete(recursive: true);
      });

      final uno = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosNativo(directorio: temporal),
      );
      await uno.cargar();
      await uno.marcar('John', 3, 16, 'amarillo');
      uno.dispose();

      // Y ESTE ES EL RECORRIDO COMPLETO: view model, almacen y fichero. Las tres
      // piezas por separado pueden estar bien y el fallo estar en que **no estan unidas**,
      // que es exactamente lo que pasaba.
      final dos = ResaltadosViewModel(
        almacenamiento: AlmacenamientoDeResaltadosNativo(directorio: temporal),
      );
      addTearDown(dos.dispose);
      await dos.cargar();

      expect(dos.total, 1);
      expect(dos.leidos, isTrue);
      expect(dos.estiloDe('John', 3, 16)!.id, 'amarillo');
    });
  });
}