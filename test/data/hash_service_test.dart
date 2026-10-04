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

import '../support/fixtures.dart';

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
    final fichero = File(rutaBibliaReal);

    final h = HashEnCurso();
    final flujo = fichero.openRead();
    final trozos = <int>[];
    await for (final trozo in flujo) {
      trozos.add(trozo.length);
      h.anadir(trozo);
    }
    expect(h.finalizar(), sha256Biblia);
    expect(h.bytesLeidos, tamanoBiblia);
    expect(trozos.length, greaterThan(1), reason: 'tiene que leer en varios trozos');
  });

  test('y el de 22 MB entero tambien', () {
    final bytes = File(rutaBibliaReal).readAsBytesSync();
    expect(bytes.length, tamanoBiblia);
    expect(sha256DeBytes(bytes), sha256Biblia);
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
    expect(esSha256(sha256Biblia), isTrue);
    expect(esSha256(sha256Biblia.toUpperCase()), isTrue);
    expect(esSha256('corto'), isFalse);
    expect(esSha256('z' * 64), isFalse, reason: 'la z no es hexadecimal');
    expect(esSha256(null), isFalse);
  });

  test('el hash da igual en mayusculas y en minusculas', () {
    expect(mismoHash(sha256Biblia, sha256Biblia.toUpperCase()), isTrue);
    expect(mismoHash(sha256Biblia, sha256Comentario), isFalse);
    expect(mismoHash(sha256Biblia, null), isFalse);
  });
}
