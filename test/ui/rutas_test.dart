// La direccion: lo que se entiende y lo que no.
//
// ESTAS PRUEBAS NO NECESITAN NAVEGADOR. `Rutas` son funciones puras y por eso se
// comprueban todas aqui, en la maquina de Dart, sin montar nada. Lo que **no** se
// puede comprobar aqui es que el navegador haga lo que le pedimos --el `pushState`,
// el `replaceState`-- y eso se comprueba con Chrome de verdad en el grupo 8.
//
// Y SE COMPRUEBAN LAS FORMAS QUE LLEGAN DE VERDAD, INCLUIDAS LAS FEAS. Una ruta
// `/ab/leer/KJV2006/John.3.16` solo llega si el despliegue esta en `/ab/`, y una
// `/#/leer/...` solo llega si se cayo la estrategia de barra. Comprobar solo la
// forma bonita seria comprobar la mitad.

import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('7.4 leer una ruta de direccion', () {
    test('la biblioteca es la barra', () {
      expect(Rutas.leer('/'), const RutaBiblioteca());
      expect(Rutas.leer(''), const RutaBiblioteca());
      expect(Rutas.leer('   '), const RutaBiblioteca());
    });

    test('con estrategia de barra, sin prefijo', () {
      final r = Rutas.leer('/leer/KJV2006/John.3.16');
      expect(r, isA<RutaLectura>());
      expect((r as RutaLectura).modulo, 'KJV2006');
      expect(r.referencia, const Referencia('John', 3, 16));
    });

    test('con prefijo de despliegue, que es como esta el sitio publicado', () {
      // Esta es la forma real en `<https://.../ab/leer/KJV2006/John.3.16>`, y es la
      // que se rompe si el prefijo se busca con `startsWith('/leer/')` en vez de con
      // la ultima aparicion. La primera version de estas pruebas solo tenia la forma
      // sin prefijo, y por eso el enlace profundo del sitio publicado no abria nada
      // y no se enteraba nadie hasta que se abria a mano.
      final r = Rutas.leer('/ab/leer/KJV2006/John.3');
      expect(r, isA<RutaLectura>());
      expect((r as RutaLectura).modulo, 'KJV2006');
      expect(r.referencia, const Referencia('John', 3));
    });

    test('con estrategia de hash, con y sin prefijo', () {
      for (final d in <String>[
        '#/leer/KJV2006/John.3.16',
        '/#/leer/KJV2006/John.3.16',
        '/ab/#/leer/KJV2006/John.3.16',
      ]) {
        final r = Rutas.leer(d);
        expect(r, isA<RutaLectura>(), reason: '"$d" deberia ser una ruta de lectura');
        expect((r as RutaLectura).modulo, 'KJV2006', reason: '"$d"');
      }
    });

    test('sin barra inicial tambien se entiende', () {
      final r = Rutas.leer('leer/KJV2006/John.3.16');
      expect(r, isA<RutaLectura>());
    });

    test('un capitulo entero no lleva versiculo', () {
      final r = Rutas.leer('/leer/KJV2006/John.3') as RutaLectura;
      expect(r.referencia.versiculo, isNull);
      expect(r.referencia.capitulo, 3);
    });

    test('`index.html` es la biblioteca, no una ruta desconocida', () {
      // Es lo que sirve GitHub Pages en la raiz, y tratarlo como desconocido haria
      // que la aplicacion no arrancara en su propia direccion.
      expect(Rutas.leer('/index.html'), const RutaBiblioteca());
      expect(Rutas.leer('/ab/index.html'), const RutaBiblioteca());
    });
  });

  group('lo que no se entiende', () {
    test('una ruta que no es de lectura no es la biblioteca', () {
      // Y esto importa: si lo que no se entiende se tratara como biblioteca, un
      // enlace roto abriria la aplicacion sin decir nada. Distinguir las dos cosas es
      // lo que permite avisar.
      expect(Rutas.leer('/lo-que-sea'), isA<RutaDesconocida>());
      expect(Rutas.leer('/otra/cosa/mas'), isA<RutaDesconocida>());
    });

    test('un pasaje que no se entiende no es una ruta de lectura', () {
      // Si saliera `RutaLectura` con una referencia inventada, el lector abriria un
      // modulo para leer "Zetaquiel 3", y el aviso seria de otra cosa.
      final casos = <String>[
        '/leer/KJV2006/Zetaquiel.3',
        '/leer/KJV2006/John.abc',
        '/leer/KJV2006/John',
        '/leer/KJV2006/',
        '/leer/',
        '/leer',
        '/leer/KJV2006/John.3.16/extra',
      ];
      for (final d in casos) {
        expect(Rutas.leer(d), isA<RutaDesconocida>(), reason: '"$d" no deberia ser lectura');
      }
    });

    test('un modulo vacio no es una ruta de lectura', () {
      expect(Rutas.leer('/leer//John.3'), isA<RutaDesconocida>());
    });

    test('la ruta desconocida guarda el texto que no se entendio', () {
      // Para poder decir "el enlace X no vale" en vez de "el enlace no vale".
      final r = Rutas.leer('/lo-que-sea') as RutaDesconocida;
      expect(r.texto, '/lo-que-sea');
    });
  });

  group('7.4 escribir una ruta', () {
    test('lo que se escribe es lo que se lee', () {
      // Ida y vuelta. Un `toString` que no coincide con lo que se lee es un fallo
      // silencioso: la ruta se escribe bien, se ve bien en la barra, y al recargar no
      // se reconoce.
      const rutas = <Ruta>[
        RutaBiblioteca(),
        RutaLectura('KJV2006', Referencia('John', 3)),
        RutaLectura('KJV2006', Referencia('John', 3, 16)),
        RutaLectura('CLARKE_commentary', Referencia('Genesis', 1)),
        RutaLectura('1Corinthians', Referencia('1Corinthians', 13, 4)),
      ];
      for (final r in rutas) {
        final escrita = Rutas.escribir(r);
        final leida = Rutas.leer(escrita);
        expect(leida, r, reason: '"$escrita" no vuelve a ser lo mismo');
      }
    });

    test('la biblioteca se escribe como la barra', () {
      expect(Rutas.escribir(const RutaBiblioteca()), '/');
      expect(Rutas.escribir(const RutaBiblioteca()), Rutas.biblioteca);
    });

    test('la ruta del lector lleva el modulo y el pasaje', () {
      expect(
        Rutas.escribir(const RutaLectura('KJV2006', Referencia('John', 3, 16))),
        '/leer/KJV2006/John.3.16',
      );
    });

    test('un modulo con barra en el nombre va codificado', () {
      // Un identificador de modulo podria venir de otro sitio --un manifiesto hecho a
      // mano-- y si trae una barra, sin codificar, la ruta apuntaria a otro sitio.
      final escrita = Rutas.escribir(
        const RutaLectura('con/barra', Referencia('John', 3)),
      );
      expect(escrita, contains('con%2Fbarra'));
      // Y vuelve a leerse igual, que es lo que importa.
      expect(Rutas.leer(escrita), const RutaLectura('con/barra', Referencia('John', 3)));
    });
  });

  group('la ruta inicial', () {
    test('sin direccion, en la maquina de Dart, es la biblioteca', () {
      // No es lo que pasa en el navegador --alli llega la barra-- pero es lo que hay
      // que comprobar en una prueba, y tener que decirlo evita que alguien se sorprenda
      // de que aqui no abra Juan 3.
      expect(rutaInicial('/'), const RutaBiblioteca());
      expect(rutaInicial('/leer/KJV2006/John.3'), isA<RutaLectura>());
    });
  });
}
