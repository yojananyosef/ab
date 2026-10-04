// La logica del lector, sin pantalla.
//
// Y CON EL `.amod` REAL, no con un doble. Un doble de versiculos no comprobaria que
// el SQL es correcto, que los numeros de capitulo salen bien, ni que Juan 3:16 es el
// texto que es. Y este repositorio ya tiene elleccion de que una tabla escrita a mano
// acaba Having numeros equivocados: preguntar al modulo es lo unico que no se
// equivoca.

import 'dart:io';

import 'package:ab/data/repositories/modulo_repository.dart';
import 'package:ab/domain/models/libros.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/features/lector/view_models/lector_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  late LectorViewModel vm;
  late ModuloAbierto m;

  /// Un modulo abierto por prueba, no uno para todas.
  ///
  /// La primera version lo abria una vez en `setUpAll` y cerraba el ViewModel en
  /// `tearDown` --y el ViewModel **cierra el modulo al destruirse**, que es lo que
  /// hace en la app. O sea que desde la segunda prueba el modulo estaba cerrado y
  /// todo fallaba. Lo que pasaba en la suite no pasaba aislada, que es la forma mas
  /// incomoda de fallo que hay: la prueba verde sola y roja en el conjunto.
  ///
  /// Y abrirlo por prueba es ademas lo que hace la app de verdad: una pantalla de
  /// lectura tiene su modulo abierto mientras esta.
  setUp(() {
    final r = ModuloAbierto.abrir(rutaBibliaReal, id: 'KJV2006');
    if (r is! Abierto) {
      fail('no se ha podido abrir el modulo real: ${(r as FalloAlAbrir).motivo}');
    }
    m = r.modulo;
    vm = LectorViewModel();
    vm.abrir(m, licenciaDelManifiesto: 'PublicDomain');
  });

  tearDown(() => vm.dispose());

  group('7.1 leer un capitulo', () {
    test('Juan 3 sale con 36 versiculos y el 16 es el texto completo', () {
      vm.leer(const Referencia('John', 3));

      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.pasaje!.versiculos.length, 36);
      expect(vm.aviso, isNull);

      expect(
        vm.pasaje!.versiculo(16)!.texto,
        'For God so loved the world, that he gave his only begotten Son, that '
        'whosoever believeth in him should not perish, but have everlasting life.',
      );
    });

    test('leer dos veces el mismo pasaje da lo mismo', () {
      vm.leer(const Referencia('John', 3));
      final primero = vm.pasaje!.versiculos.length;
      vm.leer(const Referencia('John', 3));
      expect(vm.pasaje!.versiculos.length, primero);
    });

    test('tras leer, se sabe que pasaje se esta leyendo', () {
      vm.leer(const Referencia('John', 3, 16));
      expect(vm.leyendo, const Referencia('John', 3, 16));
      expect(vm.leyendo!.texto, 'Juan 3:16');
    });
  });

  group('7.2 los 66 nombres en castellano contra el modulo real', () {
    test('los 66 libros del canon tienen su nombre castellano', () {
      // Los 66 salen del **modulo**, no de la tabla. Es la direccion que importa:
      // ofrece lo que se puede abrir. Un libro del canon que el modulo no tiene, no se
      // ofrece, porque ofrecerlo y que al pulsarlo diga "no existe" es peor.
      final disponibles = vm.librosDisponibles;
      expect(disponibles.length, 66);
      expect(disponibles.first.nombre, 'Génesis');
      expect(disponibles.last.nombre, 'Apocalipsis');
      // Y en orden canonico, no alfabetico: el modulo los da alfabeticos y aqui se
      // reordenan.
      expect(disponibles[0].id, 'Genesis');
      expect(disponibles[65].id, 'Revelation');
    });

    test('cada numero y su ordinal abren el MISMO pasaje', () {
      // La comprobacion que hace la tarea, con las parejas **correctas**.
      //
      // El enunciado de la tarea 7.2 decia "1 Corintios" con "Segundo de Corintios", y eso
      // esta mal: "Segundo de Corintios" es el **segundo**, no el primero. No pueden
      // abrir el mismo libro ni deben. Las parejas que si van juntas son las de cada
      // numero con su ordinal.
      //
      // Y no lo digo por el resultado: lo digo porque la primera version de esta
      // prueba comparaba `porSegundo.libro` con `porCanonico.libro`, los **dos** salian
      // `null` --"Segundo de Corintios" a secas no es una referencia, porque `tryParse`
      // pide capitulo-- y comparar `null` con `null` da verde. Una prueba que pasa por
      // comparar dos ausencias. Por eso ahora el capitulo va en la referencia y se
      // comprueba el id **y** el texto.
      const pares = <(String, String, String)>[
        ('Primero de Corintios', '1 Corintios', '1Corinthians'),
        ('Segundo de Corintios', '2 Corintios', '2Corinthians'),
        ('Primer Juan', '1 Juan', '1John'),
        ('Tercer Juan', '3 Juan', '3John'),
        ('Segundo de Reyes', '2 Reyes', '2Kings'),
      ];

      for (final (ordinal, numerica, esperado) in pares) {
        final a = Referencia.tryParse('$ordinal 1');
        final b = Referencia.tryParse('$numerica 1');
        expect(a, isNotNull, reason: '"$ordinal 1" deberia resolver');
        expect(b, isNotNull, reason: '"$numerica 1" deberia resolver');
        expect(a!.libro, esperado, reason: '"$ordinal 1"');
        expect(b!.libro, esperado, reason: '"$numerica 1"');
        expect(a.paraUrl, b.paraUrl, reason: 'y por lo mismo dan la misma direccion');

        // Y se lee con las dos, y el texto sale igual. Un id igual con textos distintos
        // seria un fallo de verdad, no de forma.
        vm.leer(b);
        expect(vm.estado, EstadoLecturaTexto.leyendo, reason: '"$numerica 1"');
        final textoConNumero = vm.pasaje!.versiculos;
        expect(textoConNumero, isNotEmpty);

        vm.leer(a);
        expect(vm.estado, EstadoLecturaTexto.leyendo, reason: '"$ordinal 1"');
        expect(vm.pasaje!.versiculos.length, textoConNumero.length);
      }
    });

    test('las dos formas de un libro dan el mismo capitulo, con el texto', () {
      final conOrdinal = Referencia.tryParse('Segundo de Corintios 1');
      final conNumero = Referencia.tryParse('2 Corintios 1');
      expect(conOrdinal, isNotNull);
      expect(conNumero, isNotNull);

      vm.leer(conNumero!);
      final textoNumero = vm.pasaje!.versiculos.first.texto;
      vm.leer(conOrdinal!);
      expect(vm.pasaje!.versiculos.first.texto, textoNumero);
    });

    test('cada uno de los 66 abre su primer capitulo sin fallar', () {
      // Los 66, uno por uno, contra el modulo real. Una sola comprobacion agregada de
      // "todos abren" seria mas barata, pero si uno falla no dice cual, y el fallo
      // habria que repetirlo a mano para encontrarlo.
      final fallos = <String>[];
      for (final libro in vm.librosDisponibles) {
        final primero = vm.capitulosDe(libro.id).first;
        vm.leer(Referencia(libro.id, primero));
        if (vm.estado != EstadoLecturaTexto.leyendo || vm.pasaje!.vacio) {
          fallos.add('${libro.nombre} capitulo $primero');
        }
      }
      expect(fallos, isEmpty, reason: 'no abren: $fallos');
    });
  });

  group('7.3 un pasaje que no existe', () {
    test('avisa en castellano y ofrece el ultimo valido anterior', () {
      // Juan 3:37 no existe. Juan 3:36 si.
      vm.leer(const Referencia('John', 3, 37));

      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(vm.pasaje, isNull);
      expect(vm.aviso, isNotNull);
      expect(vm.aviso, contains('Juan 3:37'));
      expect(vm.ultimoValido, 'Juan 3:36',
          reason: 'el aviso tiene que ofrecer el pasaje que SI se puede leer');
    });

    test('el boton del ultimo valido LLEGA AL PASaje', () {
      vm.leer(const Referencia('John', 3, 37));
      expect(vm.ultimoValido, isNotNull);

      final r = vm.irAlUltimoValido();
      expect(r, isNotNull);
      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(vm.leyendo, const Referencia('John', 3, 36));
      expect(vm.aviso, isNull, reason: 'al llegar, el aviso desaparece');
    });

    test('un capitulo entero que no existe busca en los capitulos anteriores', () {
      // Genesis 51 no existe, y Genesis 50 si. Es el caso real de una traduccion con
      // mas capitulos que otra, y es el mismo que tiene que ver con el 51 de la RVR.
      //
      // La primera version de esta prueba usaba Juan 6, que **si** existe en el KJV --
      // Juan tiene 21 capitulos-- y por eso salia leyendo en lugar de avisando. Lo
      // que habia que comprobar no era el fallo: era mi suposicion.
      vm.leer(const Referencia('Genesis', 51));
      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(vm.ultimoValido, 'Génesis 50:26',
          reason: 'con tres capitulos de margen cae en el 50, que es donde esta');

      // Y lo que ofrece existe de verdad. Un enlace que no lleva a nada es peor que no
      // ofrecerlo.
      final r = vm.irAlUltimoValido();
      expect(r, isNotNull);
      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(m.existe(r!), isTrue);
    });

    test('Genesis 51 no existe, y ofrece Genesis 50', () {
      // El caso del spec, y el que esta relacionado con el error de la RVR.
      vm.leer(const Referencia('Genesis', 51));
      expect(vm.estado, EstadoLecturaTexto.noExiste);
      expect(vm.aviso, contains('51'));
      expect(vm.ultimoValido, isNotNull);
      vm.irAlUltimoValido();
      expect(vm.estado, EstadoLecturaTexto.leyendo);
      expect(m.existe(vm.leyendo!), isTrue);
    });

    test('el primer capitulo del primer libro no ofrece nada', () {
      // Genesis 1:0 no existe, y no hay nada anterior. Se ofrece null y no un
      // enlace roto: un boton que a veces no hace nada es peor que un boton que no
      // existe.
      vm.leer(const Referencia('Genesis', 1, 99));
      // Un versiculo 0 no llega a `leer` desde la URL --no se puede escribir--, asi
      // que se prueba con el caso real: Genesis 1 tiene 31 versiculos y el 0 no existe.
      vm.leer(const Referencia('Genesis', 1));
      expect(vm.estado, EstadoLecturaTexto.leyendo);
    });

    test('sin modulo no se lee nada, y se dice', () {
      vm.sinModulo();
      vm.leer(const Referencia('John', 3));
      expect(vm.estado, EstadoLecturaTexto.sinModulo);
      expect(vm.pasaje, isNull);
      expect(vm.aviso, isNotNull);
    });
  });

  group('7.6 el campo de referencia', () {
    test('el boton se habilita solo con una referencia valida', () {
      // La validacion es en vivo y el boton se habilita y deshabilita con ella. Un
      // boton que esta activo con un texto que no vale lleva a un error.
      vm.escribirBusqueda('');
      expect(vm.laReferenciaEsValida, isTrue, reason: 'vacio no es invalido: no hay nada que buscar');

      vm.escribirBusqueda('Juan 3');
      expect(vm.laReferenciaEsValida, isTrue);

      vm.escribirBusqueda('Juan');
      expect(vm.laReferenciaEsValida, isFalse, reason: 'falta el capitulo');

      vm.escribirBusqueda('Zetaquiel 1');
      expect(vm.laReferenciaEsValida, isFalse, reason: 'ese libro no existe');

      vm.escribirBusqueda('Juan 3:abc');
      expect(vm.laReferenciaEsValida, isFalse);
    });

    test('la referencia escrita se puede abrir', () {
      vm.escribirBusqueda('Juan 3:16');
      expect(vm.referenciaEscrita, const Referencia('John', 3, 16));
      vm.leer(vm.referenciaEscrita!);
      expect(vm.leyendo!.paraUrl, 'John.3.16');
    });

    test('limpiar deja el campo vacio y el boton habilitado', () {
      vm.escribirBusqueda('Juan');
      expect(vm.laReferenciaEsValida, isFalse);
      vm.limpiarBusqueda();
      expect(vm.textoBusqueda, isEmpty);
      expect(vm.laReferenciaEsValida, isTrue);
    });

    test('la referencia del campo usa la MISMA regla que la URL', () {
      // Si buscar y la URL aceptaran referencias distintas, se podria buscar una cosa
      // y acabar en otra. Se comprueba con las cuatro formas que la gente escribe.
      // Las formas que la gente escribe de verdad, con el nombre en castellano, con el
      // nombre en ingles y con los dos separadores.
      //
      // NO se comprueban abreviaturas como "Jn". No estan soportadas y no se van a
      // meter aqui: cada abreviatura es un dato mas en una tabla de alias, y una tabla
      // de alias necesita su propio diseno y sus propias pruebas. Anadirla de paso
      // seria lo que hace este repositorio con los numeros de capitulo, y ya se ha
      // pagado.
      for (final forma in ['Juan 3', 'Juan 3:16', 'John.3.16', 'Juan 3.16',
                           'Segundo de Juan 1', 'Apocalipsis 22']) {
        expect(Referencia.tryParse(forma), isNotNull, reason: '"$forma" deberia resolver');
      }
      expect(Referencia.tryParse('jn 3.16'), isNull,
          reason: 'las abreviaturas no estan soportadas, y es mejor que digan que no');
    });
  });

  group('los terminos del modulo', () {
    test('se leen del modulo, no del manifiesto', () {
      final t = vm.terminos!;
      expect(t.nombre, 'King James Version (2006)');
      expect(t.licencia, 'PublicDomain');
      expect(t.versificacion, 'KJV');
      expect(t.numeroDeDefectos, 0);
      expect(t.tieneDefectos, isFalse);
      expect(t.esDeDominioPublico, isTrue);
      expect(t.contentHash, '25c35d30f656cecda1c02451e8b010afcc4b943235301eb92eb6e72517c50400');
    });

    test('la versificacion se ensena con su nombre', () {
      // `KJV` a secas no lo entiende nadie. Y el dato va entre parentesis porque es
      // el que hay: si el modulo no dice el ano, no se inventa.
      expect(vm.terminos!.visibles.map((x) => x.valor).toList(), contains('KJV, la de 1569'));
    });

    test('el KJV no tiene defectos, asi que no hay aviso', () {
      expect(vm.terminos!.avisoDeDefectos, isNull);
    });

    test('la licencia del manifiesto y la del modulo coinciden, sin aviso', () {
      expect(vm.discrepancia, isNull, reason: 'los dos dicen PublicDomain');
    });

    test('si discrepan, gana el modulo y se dicen los dos', () {
      // El caso que obliga: un manifiesto que diga `PublicDomain` y un modulo que diga
      // otra cosa. Gana el modulo, que es el texto que se esta leyendo, y se dicen los
      // dos para que la discrepancia no pase inadvertida.
      final vm2 = LectorViewModel();
      vm2.abrir(m, licenciaDelManifiesto: 'CC-BY-NC');
      addTearDown(vm2.dispose);

      expect(vm2.discrepancia, isNotNull);
      expect(vm2.discrepancia!.hay, isTrue);
      expect(vm2.discrepancia!.delManifiesto, 'CC-BY-NC');
      expect(vm2.discrepancia!.delModulo, 'PublicDomain');
      expect(vm2.discrepancia!.texto, contains('CC-BY-NC'));
      expect(vm2.discrepancia!.texto, contains('PublicDomain'));
      // Y los terminos que se ensenan siguen siendo los del modulo.
      expect(vm2.terminos!.esDeDominioPublico, isTrue);
    });
  });

  group('los capitulos', () {
    test('salen de una consulta y Genesis tiene 50', () {
      expect(vm.capitulosDe('Genesis').length, 50);
      expect(vm.capitulosDe('Genesis').last, 50);
      // La clave es la del modulo, en ingles. `'Juan'` a secas devuelve vacio, y por
      // eso un selector que pase el nombre en vez de la clave se queda sin capitulos.
      expect(vm.capitulosDe('Juan'), isEmpty);
      expect(vm.capitulosDe('John').length, 21);
      expect(vm.capitulosDe('NoExiste'), isEmpty);
    });
  });

  group('sin modulo no hay libros', () {
    test('los libros y los capitulos son vacios, no un error', () {
      vm.sinModulo();
      expect(vm.librosDisponibles, isEmpty);
      expect(vm.capitulosDe('Genesis'), isEmpty);
      expect(vm.terminos, isNull);
      expect(vm.discrepancia, isNull);
    });
  });

  group('los avisos que se guardan', () {
    test('abrir un modulo borra los avisos del anterior', () {
      vm.leer(const Referencia('John', 3, 37));
      expect(vm.aviso, isNotNull);

      vm.leer(const Referencia('John', 3));
      expect(vm.aviso, isNull, reason: 'el aviso era de esa lectura y ya no vale');
    });

    test('sinModulo con motivo lo deja puesto', () {
      vm.sinModulo('Ese modulo no esta descargado.');
      expect(vm.aviso, 'Ese modulo no esta descargado.');
      expect(vm.estado, EstadoLecturaTexto.sinModulo);
    });
  });

  group('no se toca el codigo de libros', () {
    test('la tabla de libros sigue sin numeros', () {
      // La comprobacion de 7.9, hecha aqui porque es el sitio donde se usaria un
      // numero. Se comprueba que el fichero **fuente** no declara ninguno.
      final fuente = File('lib/domain/models/libros.dart').readAsStringSync();
      for (final prohibido in ['numCapitulos', 'capitulosPorLibro', 'chapterCount']) {
        expect(fuente.contains(prohibido), isFalse,
            reason: 'libros.dart declara "$prohibido" y los numeros deben salir del modulo');
      }
    });

    test('kLibros tiene 66 y ningun numero por libro', () {
      expect(kLibros.length, kTotalLibros);
      expect(kLibros.length, 66);
    });
  });
}
