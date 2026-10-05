// Una entrada del indice de palabras: un versiculo y las palabras que llevan un numero.
//
// QUE ES ESTO Y QUE NO ES.
//
// ES UN INDICE **DEL MODULO QUE ESTA ABIERTO**, y no un diccionario. La diferencia es la
// que separa esto de lo que se suele llamar indice, y hay que decirla en voz alta porque
// el nombre engana:
//
//   - Se puede contar cuantas veces sale un numero: **G2316** aparece en 1.171 versiculos
//     del KJV. Eso sale del modulo, medido, y en 15 ms.
//
//   - Se puede decir **en que versiculos** sale, y con que palabra: el indice completo.
//
//   - **NO** se puede decir que significa `G2316`. El significado esta en un diccionario
//     del griego, y ese diccionario **no esta en el `.amod`**. Medido el 5 de octubre de
//     2026: el KJV tiene dos tablas, `info` y `verses`, y las trece claves de `info` son
//     nombre, licencia, copyright, origen, version, tipo, versificacion y defectos. Ni una
//     de lexicon.
//
// Asi que este indice contesta "donde mas sale esta palabra en este texto", que es la
// pregunta con la que se trabaja un texto, y **no** "que significa esta palabra". Poner
// meanings seria inventarselos: si se escriben a mano, son de otra persona y este
// proyecto no tiene ninguna fuente de ellos; y si se sacan de internet, es un dato que no
// es del modulo y que nadie ha pedido.
import 'referencia.dart';
import 'indice_de_strong_para_la_view.dart';
class IndiceDeStrong implements IndiceDeStrongParaLaView {
  const IndiceDeStrong({required this.referencia, required this.palabras});

  /// Donde sale.
  final Referencia referencia;

  /// Las formas de la palabra en ese versiculo que llevan este numero.
  ///
  /// Y ES UNA LISTA Y NO UNA CADENA porque una palabra puede salir dos veces en el mismo
  /// versiculo con el mismo numero --y entonces sale dos veces-- y porque el indice tiene
  /// que poder decir "dos veces aqui" sin inventarse una cuenta que no existe.
  final List<String> palabras;

  /// Cuantas veces sale en este versiculo.
  @override
  int get veces => palabras.length;

  /// Donde sale, ya con el tipo que la pantalla usa.
  @override
  Referencia get referenciaParaLaView => referencia;

  /// Como se lee en una linea: `Juan 1:1, Dios`.
  String get enLinea => '${referencia.texto}, ${palabras.join(", ")}';

  @override
  String toString() => enLinea;
}
