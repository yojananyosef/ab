// Un versiculo: su numero y su texto.
//
// Inmutable y sin metodos de UI. La View decide como se pinta; esto solo lleva
// el dato. Un widget con `if (v.texto.length > 40)` es un widget con logica de
// negocio dentro, y por eso la regla es que aqui no haya nada de eso.

class Versiculo {
  const Versiculo(this.numero, this.texto);

  /// Numero dentro del capitulo. Empieza en 1.
  final int numero;

  /// El texto tal cual lo trae el modulo. **No se toca aqui.**
  ///
  /// Ni se normaliza, ni se corrigen mayusculas, ni se cambian comillas. Un
  /// lector que altera el texto que va a leer es un lector que no se puede
  /// citar, y citar mal la Escritura es el fallo mas grave de esta categoria.
  ///
  /// Lo que si se hace, mas adelante y en otro sitio, es CONSUMIR el marcado:
  /// el modulo guarda un `raw` con marcas USFM como `\\+w Dios|strong="G2316"`,
  /// y de ahi sale la palabra de Dios en rojo. El texto plano sale del campo
  /// `text`, que ya viene limpio.
  final String texto;

  @override
  String toString() => '$numero $texto';

  @override
  bool operator ==(Object other) => other is Versiculo && other.numero == numero && other.texto == texto;

  @override
  int get hashCode => Object.hash(numero, texto);
}
