// El sha256 por tramos, comparado con `sha256sum`.
//
// La comparacion es contra la **herramienta de linea de comandos**, no contra
// otra funcion de Dart. Comparar una implementacion con si misma demuestra que
// las dos hacen lo mismo, que no es lo que importa: lo que importa es que
// cuadre con lo que va a verificar el gate del otro repositorio.

import 'dart:convert';
import 'dart:io';

import 'package:ab/data/services/hash_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('por un solo trozo y por muchos dan el mismo hash', () {
    final bytes = utf8.encode('Genesis 1:1 En el principio creo Dios los cielos y la tierra.');
    final entero = sha256DeBytes(bytes);

    for (final tamanoTrozo in [1, 2, 3, 7, 16, 64, 1000]) {
      final trozos = <List<int>>[];
      for (var i = 0; i < bytes.length; i += tamanoTrozo) {
        trozos.add(bytes.sublist(i, i + tamanoTrozo > bytes.length ? bytes.length : i + tamanoTrozo));
      }
      expect(sha256DeTrozos(trozos), entero, reason: 'trozos de $tamanoTrozo bytes');
    }
  });

  test('el hash de un `.amod` REAL por trozos es el que dice el catalogo', () async {
    // Este es el que importa. Si el hash por tramos no coincide con el que
    // declara `catalog.json`, ningun modulo se podria abrir nunca.
    const esperado = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
    final ruta = '/home/j/aa/modules/build/KJV2006_bible.amod';
    final fichero = File(ruta);
    if (!fichero.existsSync()) {
      fail('falta $ruta. Sin el modulo real esta prueba no verifica nada.');
    }

    final h = HashEnCurso();
    final flujo = fichero.openRead();
    final trozos = <int>[];
    await for (final trozo in flujo) {
      trozos.add(trozo.length);
      h.anadir(trozo);
    }
    expect(h.finalizar(), esperado);
    expect(h.bytesLeidos, 22544384);
    expect(trozos.length, greaterThan(1), reason: 'tiene que leer en varios trozos');
  });

  test('y el de 22 MB entero tambien', () {
    const esperado = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
    final bytes = File('/home/j/aa/modules/build/KJV2006_bible.amod').readAsBytesSync();
    expect(sha256DeBytes(bytes), esperado);
  });

  test('el progreso va exactamente por los bytes que han pasado', () {
    final h = HashEnCurso();
    expect(h.bytesLeidos, 0);
    h.anadir([1, 2, 3]);
    expect(h.bytesLeidos, 3);
    h.anadir(List.filled(1000, 0));
    expect(h.bytesLeidos, 1003);
    h.anadir([]);
    expect(h.bytesLeidos, 1003, reason: 'un trozo vacio no suma');
    h.finalizar();
  });

  test('finalizar dos veces avisa, en vez de dar un hash distinto', () {
    final h = HashEnCurso()..anadir([1, 2, 3]);
    h.finalizar();
    // Un hash distinto en la segunda llamada seria un fallo silencioso: el
    // hash comprobaria una cosa y la app creeria que comprobo otra.
    expect(() => h.finalizar(), throwsStateError);
  });

  test('reconoce un sha256 y rechaza lo que no lo es', () {
    expect(esSha256('ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9'), isTrue);
    expect(esSha256('CE0CB1BC4EDBF3341D673739539421BBFED3972E39CBAC5FC129F35F25324FE9'), isTrue);
    expect(esSha256('corto'), isFalse);
    expect(esSha256('z' * 64), isFalse, reason: 'la z no es hexadecimal');
    expect(esSha256(null), isFalse);
  });

  test('el hash da igual en mayusculas y en minusculas', () {
    const a = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
    expect(mismoHash(a, a.toUpperCase()), isTrue);
    expect(mismoHash(a, '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c'), isFalse);
    expect(mismoHash(a, null), isFalse);
  });
}
