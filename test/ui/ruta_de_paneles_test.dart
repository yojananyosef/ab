// La ruta con dos ventanas, y lo que no se entiende.
//
// ============================================================================
// POR QUE ESTA EN UN FICHERO APARTE Y NO EN `comentario_al_lado_test.dart`
// ============================================================================
//
// `/leer/KJV2006/John.3.16/con/CLARKE` es **una** ventana con el comentario dentro. Y
// `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16` son **dos**. Son dos rutas distintas y no una
// con un parametro de mas, y la razon esta escrita en `rutas.dart`: `con` es un comentario
// **dentro** del panel, que se lee debajo de cada versiculo, y `y` es **otro panel**, con su
// columna y su referencia.
//
// Y SI NO SE PUDIERAN EXPRESAR LAS DOS CON UN PARAMETRO, TENDRIAMOS QUE ELEGIR UNA, Y LA
// ELECCION SERIA PERDER ALGO: con `con` no hay dos columnas, y con `y` no hay un comentario
// debajo del texto. En Logos estan las dos.

import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1. una ventana', () {
    test('sin comentario es la de siempre', () {
      final r = Rutas.leer('/leer/KJV2006/John.3.16');
      expect(r, const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      expect(Rutas.escribir(r), '/leer/KJV2006/John.3.16');
    });

    test('con comentario va en un segmento con', () {
      final r = Rutas.leer('/leer/KJV2006/John.3.16/con/CLARKE');
      expect(
        r,
        const RutaLectura('KJV2006', Referencia('John', 3, 16), 'CLARKE'),
      );
      expect(Rutas.escribir(r), '/leer/KJV2006/John.3.16/con/CLARKE');
    });
  });

  group('2. dos ventanas', () {
    test('el `y` separa las ventanas y el primero es el de delante', () {
      final r = Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16');

      expect(r, isA<RutaPaneles>());
      final paneles = r as RutaPaneles;
      expect(paneles.principal.modulo, 'KJV2006');
      expect(paneles.principal.referencia, const Referencia('John', 3, 16));
      expect(paneles.resto, hasLength(1));
      expect(paneles.resto.single.modulo, 'CLARKE');
      expect(paneles.resto.single.referencia, const Referencia('John', 3, 16));
    });

    test('se escribe igual que se lee, y por tanto recargar conserva las ventanas', () {
      const direccion = '/leer/KJV2006/John.3.16/y/CLARKE/John.3.16';
      expect(Rutas.escribir(Rutas.leer(direccion)), direccion);
    });

    test('con el de delante siendo el comentario, el orden se invierte', () {
      // Y ES LA REGLA DEL SPEC DE PESTANAS, y no una curiosidad: "cuando hay dos paneles y
      // el de delante es el CLARKE, la direccion lleva el identificador del de delante". Sin
      // esto, traer una pestana al frente no cambiaria la barra de direcciones y quien
      // copiara la direccion mandaria a otra ventana.
      const direccion = '/leer/CLARKE/John.3.16/y/KJV2006/John.3.16';
      final paneles = Rutas.leer(direccion) as RutaPaneles;
      expect(paneles.principal.modulo, 'CLARKE');
      expect(paneles.resto.single.modulo, 'KJV2006');
      expect(Rutas.escribir(paneles), direccion);
    });

    test('tres ventanas se leen y se escriben enteras', () {
      const direccion =
          '/leer/KJV2006/John.3.16/y/CLARKE/John.3.16/y/RVR60/John.3.16';
      final paneles = Rutas.leer(direccion) as RutaPaneles;
      expect(paneles.resto, hasLength(2));
      expect(paneles.resto[1].modulo, 'RVR60');
      expect(Rutas.escribir(paneles), direccion);
    });

    test('las ventanas pueden estar en pasajes distintos', () {
      // Y NO ES UNA EXCEPCION: en Logos los paneles pueden estar en sitios distintos --uno en
      // Juan 3 y otro en el Salmo 119--, y ambos se ven. Obligar a que todos muestren la
      // misma referencia seria inventar una regla que el producto no tiene.
      //
      // Y EL LIBRO VA EN **LA CLAVE DEL MODULO** --`Psalms`, no `Salmos`-- por el mismo
      // motivo que en el resto de las rutas: la direccion la resuelve el modulo, y si dijera
      // "Salmos" habria que traducirla al abrir. Medido en el `.amod` real: los 66 libros se
      // guardan en ingles.
      final paneles = Rutas.leer(
        '/leer/KJV2006/John.3.16/y/CLARKE/Psalms.119.1',
      ) as RutaPaneles;
      expect(paneles.principal.referencia, const Referencia('John', 3, 16));
      expect(paneles.resto.single.referencia, const Referencia('Psalms', 119, 1));
      expect(Rutas.escribir(paneles),
          '/leer/KJV2006/John.3.16/y/CLARKE/Psalms.119.1');
    });

    test('el de delante puede llevar comentario y el otro no', () {
      final paneles = Rutas.leer(
        '/leer/KJV2006/John.3.16/con/CLARKE/y/OTRO/John.3.16',
      ) as RutaPaneles;
      expect(paneles.principal.comentario, 'CLARKE');
      expect(paneles.resto.single.comentario, isNull);
      expect(Rutas.escribir(paneles),
          '/leer/KJV2006/John.3.16/con/CLARKE/y/OTRO/John.3.16');
    });

    test('con el prefijo del despliegue tambien', () {
      final paneles = Rutas.leer(
        '/ab/leer/KJV2006/John.3.16/y/CLARKE/John.3.16',
      ) as RutaPaneles;
      expect(paneles.resto.single.modulo, 'CLARKE');
      // Y LO QUE SE ESCRIBE **NO LLEVA EL PREFIJO**, como con las demas: lo pone el `base
      // href` al compilar, y escribirlo aqui seria duplicarlo.
      expect(Rutas.escribir(paneles), '/leer/KJV2006/John.3.16/y/CLARKE/John.3.16');
    });
  });

  group('3. lo que no se entiende', () {
    test('un `y` sin modulo ni pasaje', () {
      expect(Rutas.leer('/leer/KJV2006/John.3.16/y'), isA<RutaDesconocida>());
      expect(Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE'), isA<RutaDesconocida>());
      expect(Rutas.leer('/leer/KJV2006/John.3.16/y/'), isA<RutaDesconocida>());
    });

    test('un segmento suelto que no es `y` ni `con`', () {
      // Y ESTE **NO** ES UN ERROR DE SINTESIS, es una comprobacion de que el parser decide
      // por el **operador**. `/leer/A/John.3.16/junto/B/John.3.16` esta escrita en
      // castellano y no se entiende, porque el operador es `y` y no "junto". Aceptarla
      // seria inventar una segunda sintaxis para lo mismo, y entonces las dos Written de
      // la barra darian rutas distintas para la misma ventana.
      expect(Rutas.leer('/leer/KJV2006/John.3.16/junto/CLARKE/John.3.16'),
          isA<RutaDesconocida>());
      expect(Rutas.leer('/leer/KJV2006/John.3.16/CLARKE'),
          isA<RutaDesconocida>());
    });

    test('un comentario en una ventana secundaria', () {
      // Y ESTO SE RECHAZA A PROPOSITO. Un panel con comentario lleva el suyo en el `con`, y
      // permitir un segundo haria que hubiera dos sitios donde decir lo mismo y el parser
      // tendria que decidir cual gana. Rechazarlo es lo que hace que la sintaxis no pueda
      // decir dos cosas distintas con la misma palabra.
      expect(
        Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/John.3.16/con/CLARKE'),
        isA<RutaDesconocida>(),
      );
    });

    test('una ventana sin pasaje legible', () {
      expect(Rutas.leer('/leer/KJV2006/John.3.16/y/CLARKE/no-es-un-pasaje'),
          isA<RutaDesconocida>());
      expect(Rutas.leer('/leer/KJV2006/John.3.16/y//John.3.16'),
          isA<RutaDesconocida>());
    });

    test('una ruta que no se entiende **no cambia de tipo**, y eso se comprueba', () {
      // Y NO SE CONVIERTE EN RUTA DE PANELES CON CERO PANELES. Una ruta de ventanas con
      // ninguna ventana valida seria una pantalla de pestanas vacia, que es el peor sitio
      // donde aterrizar un enlace roto.
      final r = Rutas.leer('/leer/KJV2006/John.3.16/y');
      expect(r, isA<RutaDesconocida>());
      expect(r, isNot(isA<RutaPaneles>()));
    });
  });

  group('4. el operador, y por que `y`', () {
    test('`y` es una palabra que se entiende sin conocer la sintaxis', () {
      // Y NO ES UNA CAPRICHO. El operador de una direccion que se copia y se manda tiene que
      // ser algo que se entienda **leyendo la direccion**, y `y` es el conjuncion de "este
      // texto **y** este otro". Con un simbolo habria que saber cual es, y con `junto`
      // habria que saber que se escribe entero.
      //
      // Y LA COMPROBACION ES **ESTRUCTURAL**, no de texto: que la direccion con `y` se
      // lea como dos ventanas y que la misma con otra palabra no se entienda. Asi, si
      // alguien cambia el operador, la comprobacion falla.
      expect(Rutas.leer('/leer/A/John.3.16/y/B/John.3.16'), isA<RutaPaneles>());
      expect(Rutas.leer('/leer/A/John.3.16/Y/B/John.3.16'), isA<RutaDesconocida>(),
          reason: 'la palabra es en minusculas, como todos los segmentos de esta ruta');
    });
  });
}