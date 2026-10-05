// Un pasaje: una referencia y lo que hay en ella.
//
// EL NOMBRE `Pasaje` Y NO `Capitulo` porque un pasaje puede ser un capitulo entero o un
// solo versiculo. Quien llama decide el alcance.
//
// Y UN PASAJE LLEVA **DOS** COSAS QUE NO SON LO MISMO: `versiculos`, que es la Sagrada
// Escritura, y `notas`, que es el comentario de alguien. Nunca las dos a la vez, porque
// un modulo es una cosa o la otra --`info.type` lo dice-- y un pasaje viene de un solo
// modulo.
//
// POR QUE NO ES UNA LISTA UNICA DE "COSAS". Medido el 4 de octubre de 2026: una
// `List<Fragmento>` comun seria mas corta de escribir, y haria que perder el texto de
// Juan 3:16 y perder una nota de Juan 3:16 fueran **el mismo bug**. Con dos listas, el
// compilador avisa de que se ha usado `versiculos` en un pasaje de comentario, y el
// fallo sale antes de que haya forma de verlo en pantalla.
//
// Y QUE `vacio` SEA "NO HAY NADA DE NINGUN TIPO" Y NO "NO HAY VERSICULOS". Con la
// segunda, un pasaje de comentario con notas se pinta como vacio, que es el fallo que
// haria que la pantalla del lector encenase "este pasaje esta vacio en esta traduccion"
// encima de las notas de Juan 3.

import 'nota.dart';
import 'referencia.dart';
import 'versiculo.dart';

class Pasaje {
  const Pasaje({
    required this.referencia,
    required this.versiculos,
    required this.titulo,
    this.notas = const <Nota>[],
    this.versiculoPedido,
  });

  /// Donde se ha leido. Sirve para el titulo de la pantalla y para la URL.
  final Referencia referencia;

  /// Los versiculos, en orden. **Solo** en un modulo de Biblia.
  ///
  /// El modulo los devuelve asi y aqui no se reordena.
  final List<Versiculo> versiculos;

  /// Las notas de comentario, en orden. **Solo** en un modulo de comentario.
  ///
  /// En orden de versiculo y, dentro de cada versiculo, por `seq`. El modulo las
  /// devuelve asi y aqui no se reordena: el orden en que las escribio el autor es
  /// informacion, y reordenar por longitud o por longitud de palabra seria inventar una
  /// jerarquia que no existe.
  final List<Nota> notas;

  /// Nombre legible: `Juan 3`. Lo pone quien lee, no se deduce aqui, para que la View
  /// no tenga que preguntar nada.
  final String titulo;

  /// El versiculo **que se pidio**, o null si se pidio el capitulo entero.
  ///
  /// Y NO SE ADIVINA. Con `verse >= ?` en la consulta, `Juan 3:16` trae los versiculos
  /// 16 al 36 y `Juan 3` trae del 1 al 36, y son **la misma lista**. Lo unico que las
  /// distingue es esto: cual de los dos pidio quien esta leyendo. Y lo necesita la vista
  /// para marcar el que se pidio, porque un enlace a Juan 3:16 tiene que abrir Juan 3 con
  /// el 16 destacado y no abrir Juan 3:1.
  ///
  /// Y ESTO ES LO QUE SE PIDIO, NO LO QUE ESTA EN PANTALLA. El nombre lo dice porque son
  /// dos cosas distintas y confundirlas haria que el enlace a un versiculo abriera el
  /// capitulo sin decir nada de donde salio.
  final int? versiculoPedido;

  /// Si [numero] es el versiculo que se pidio.
  bool esElPedido(int numero) =>
      versiculoPedido != null && versiculoPedido == numero;

  /// Si no hay nada que ensenar, del tipo que sea.
  bool get vacio => versiculos.isEmpty && notas.isEmpty;

  /// Cuanto hay en pantalla: versiculos o notas.
  ///
  /// Y NO ES "CUANTOS VERSICULOS", porque en un comentario lo que se cuenta son notas.
  /// El nombre lo dice para que no se pueda usar por error donde toca el otro.
  int get total => versiculos.length + notas.length;

  /// Si este pasaje trae texto de Biblia o comentario.
  ///
  /// Y SE DEDUCE DE LO QUE TRAE Y NO DE UN PARAMETRO. Un `bool esComentario` en el
  /// constructor es un dato mas que se puede contradecir: basta con pasar
  /// `esComentario: true` con versiculos, y la pantalla pinta versiculos como si fueran
  /// notas. Leyendolo de las listas, esa combinacion no se puede escribir.
  bool get traeNotas => notas.isNotEmpty;

  /// El versiculo `n`, o null si el pasaje no lo tiene.
  ///
  /// Null y no una excepcion porque se llama desde un enlace que puede venir de
  /// cualquier parte, con cualquier versiculo escrito.
  Versiculo? versiculo(int n) {
    for (final v in versiculos) {
      if (v.numero == n) return v;
    }
    return null;
  }

  /// Las notas del versiculo `n`, en orden.
  ///
  /// Y EXISTE PORQUE LA PANTALLA LAS NECESITA SEPARADAS: para ensenar el versiculo con
  /// su comentario debajo, y no las notas de Juan 3:1 pegadas a las de Juan 3:2. Recorrer
  /// la lista entera en la View por cada versiculo es trabajo de la vista, y es el
  /// trabajo que este metodo hace una vez.
  List<Nota> notasDe(int versiculo) =>
      <Nota>[for (final n in notas) if (n.versiculo == versiculo) n];

  /// Los numeros de versiculo que tienen al menos una nota, en orden.
  ///
  /// Y NO ES IGUAL QUE [numerosDeVersiculo], que son los que tienen **texto**. En un
  /// comentario no todos los versiculos tienen nota, y la diferencia es la que hace que
  /// el selector de versiculos ofrezca lo que hay y no lo que deberia haber.
  List<int> get versiculosConNota {
    final salida = <int>[];
    for (final n in notas) {
      if (salida.isEmpty || salida.last != n.versiculo) salida.add(n.versiculo);
    }
    return salida;
  }

  /// Un pasaje vacio para cuando la referencia no existe en ese texto.
  ///
  /// Es un caso de primera clase, no una excepcion: en una biblioteca con distintas
  /// versificaciones, pedir Juan 3:36 en un texto que no lo tiene es normal, y la
  /// pantalla tiene que poder ensenarlo.
  factory Pasaje.vacio(Referencia r, {required String titulo}) =>
      Pasaje(referencia: r, versiculos: const <Versiculo>[], titulo: titulo);
}