// Los estados de un modulo, y sobre todo: que SE CALCULAN y no se guardan.
//
// El caso que motiva esto es de MyBible y esta documentado: al quedarse sin
// conexion, su app **reclasificaba todos los modulos** como "solo local",
// incluidos los que nunca se habian descargado. Un estado guardado se queda
// viejo, y un estado viejo hace que la app mienta sin querer.
//
// Aqui no hay almacenamiento, ViewModel ni widget: solo una funcion pura. Es lo
// unico que hace falta para que se pueda comprobar sin montar nada.

import 'dart:io';

import 'package:ab/domain/models/estado_modulo.dart';
import 'package:flutter_test/flutter_test.dart';

const String _hash = 'ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9';
const String _otroHash = '3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c';

EstadoModulo calcular({
  String hash = _hash,
  EstadoEnDispositivo enDispositivo = const EstadoEnDispositivo.ausente(),
  bool descargando = false,
  bool enCatalogo = true,
}) => calcularEstado(
  sha256DelCatalogo: hash,
  enDispositivo: enDispositivo,
  descargando: descargando,
  estaEnElCatalogo: enCatalogo,
);

void main() {
  test('no esta en el dispositivo y esta en el catalogo: disponible', () {
    expect(calcular(), EstadoModulo.disponible);
  });

  test('esta en el dispositivo con el hash que dice el catalogo: descargado', () {
    expect(
      calcular(enDispositivo: EstadoEnDispositivo.presente(_hash)),
      EstadoModulo.descargado,
    );
  });

  test('esta en el dispositivo con OTRO hash: desactualizado, y sigue leyendose', () {
    // El estado NO es un error. El modulo viejo se lee igual, y por eso no se
    // retira ni se marca como roto: solo se dice que hay version nueva.
    final e = calcular(enDispositivo: EstadoEnDispositivo.presente(_otroHash));
    expect(e, EstadoModulo.desactualizado);
  });

  test('esta descargandose: descargando, gana a todo lo demas', () {
    // Aunque este en el dispositivo con el hash viejo, mientras se descarga el
    // estado es "descargando". Un progreso que se pisa con el estado final
    // hace que la barra desaparezca a mitad.
    expect(
      calcular(
        enDispositivo: EstadoEnDispositivo.presente(_otroHash),
        descargando: true,
      ),
      EstadoModulo.descargando,
    );
  });

  test('esta en el dispositivo y el catalogo lo retiro: retirado, y se lee', () {
    final e = calcular(
      enDispositivo: EstadoEnDispositivo.presente(_hash),
      enCatalogo: false,
    );
    expect(e, EstadoModulo.retirado);
  });

  test('NO existe el estado "solo local", y no se puede llegar a el', () {
    // Lo que no se ha descargado no se ha descargado. MyBible tenia ese estado
    // y lo usaba mal: al quedarse sin conexion, todo pasaba a ser "solo local",
    // y eso se lee como "no lo puedo volver a bajar" sobre modulos que nunca
    // estuvieron aqui. Aqui solo hay cinco estados y ninguno dice eso.
    expect(EstadoModulo.values.length, 5);
    final nombres = EstadoModulo.values.map((e) => e.name).toList();
    expect(nombres, isNot(contains('soloLocal')));
    expect(nombres, contains('retirado'));
  });

  test('un modulo ausente del dispositivo nunca sale "retirado"', () {
    // Aunque el manifiesto no lo declare, si no esta en el dispositivo no hay
    // nada que retirar: no se ensena en la biblioteca.
    expect(calcular(enCatalogo: false), EstadoModulo.disponible);
  });

  test('la misma entrada da SIEMPRE el mismo estado', () {
    // Que la funcion sea pura es lo que hace que esto sea comprobable: mismos
    // datos, mismo estado, sin montar una app ni un almacenamiento.
    final entradas = <(EstadoEnDispositivo, bool, bool)>[
      (const EstadoEnDispositivo.ausente(), false, true),
      (EstadoEnDispositivo.presente(_hash), false, true),
      (EstadoEnDispositivo.presente(_otroHash), false, true),
      (EstadoEnDispositivo.presente(_hash), false, false),
      (const EstadoEnDispositivo.ausente(), true, true),
    ];
    for (final (dispositivo, descargando, enCatalogo) in entradas) {
      final primero = calcular(
        enDispositivo: dispositivo,
        descargando: descargando,
        enCatalogo: enCatalogo,
      );
      for (var i = 0; i < 5; i++) {
        final otro = calcular(
          enDispositivo: dispositivo,
          descargando: descargando,
          enCatalogo: enCatalogo,
        );
        expect(otro, primero, reason: 'el estado cambio entre dos llamadas iguales');
      }
    }
  });

  test('cada estado tiene texto, no solo color', () {
    // Un estado que solo se distingue por el color no lo lee quien tiene baja
    // vision, ni con el movil en escala de grises.
    for (final e in EstadoModulo.values) {
      expect(e.texto.trim(), isNotEmpty);
    }
    final textos = EstadoModulo.values.map((e) => e.texto).toList();
    expect(textos.toSet().length, textos.length, reason: 'dos estados con el mismo texto');
  });

  test('NO hay nada que persista el estado', () {
    // La forma mas directa de comprobarlo: en el dominio no hay ningun sitio
    // donde un estado pueda guardarse. Ni campo, ni metodo, ni serializacion.
    final r = Process.runSync('grep', [
      '-rnE',
      r'^[^/*]*\b(guardarEstado|persistirEstado|estadoGuardado|fromJson|toJson)\b',
      'lib/domain/',
    ]);
    expect((r.stdout as String).trim(), isEmpty,
        reason: 'el estado no se guarda; si aparece algo asi, se ha colado '
            'un sitio donde si se puede quedar viejo');
  });
}
