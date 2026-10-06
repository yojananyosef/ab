// Un versiculo: su numero y su texto.
//
import 'nota_al_pie.dart';
import 'token_de_texto.dart';

// Inmutable y sin metodos de UI. La View decide como se pinta; esto solo lleva
// el dato. Un widget con `if (v.texto.length > 40)` es un widget con logica de
// negocio dentro, y por eso la regla es que aqui no haya nada de eso.

class Versiculo {
  const Versiculo(
    this.numero,
    this.texto, {
    this.anotaciones = const <AnotacionDePalabra>[],
    this.notas = const <NotaAlPie>[],
  });

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
  /// y de ahi sale el numero del lexicon y la marca `\\wj`, que es la de las palabras
  /// de Jesus. El texto plano sale del campo `text`, que ya viene limpio.
  ///
  /// Y CON UNA EXCEPCION, QUE ES LA UNICA VEZ QUE SE TOCA ESTE TEXTO: las **notas al pie**.
  /// El `text` las traia pegadas al final --medido, en 5.844 versiculos-- y aqui ya no
  /// estan; van en [notas]. No se quita nada mas, y que no se quite nada mas lo comprueba
  /// `test/data/notas_al_pie_test.dart` sobre los **31.102 versiculos** del fichero real.
  final String texto;

  /// Lo que el modulo marco de cada palabra, en el mismo orden que las palabras de [texto].
  ///
  /// Y VA **ADEMAS** DEL TEXTO Y NO DENTRO. Es la misma regla de todo este repositorio --
  /// el texto se pasa tal cual-- y aqui tiene una forma especialmente clara: [texto] es el
  /// del modulo, byte a byte, y esto es una capa al lado que se puede quitar sin tocarlo.
  ///
  /// Y SIEMPRE HAY UNA ANOTACION POR PALABRA O NO HAY NINGUNA. Una lista a medias --con
  /// anotaciones hasta la palabra doce y sin nada despues-- pondria el numero del lexicon
  /// de la palabra trece en la doce, y eso no se ve hasta que alguien lo busca.
  final List<AnotacionDePalabra> anotaciones;

  /// Las notas al pie de este versiculo, con la letra que les toca en el capitulo.
  ///
  /// Y VAN EN [notas] Y NO DENTRO DE [texto], y es la misma regla que [anotaciones] con la
  /// diferencia de que aqui lo que va **al lado** es texto que estaba **dentro**. Medido el
  /// 6 de octubre de 2026 sobre el KJV real: 6.959 notas en 5.844 versiculos, y la columna
  /// `text` las traia pegadas al final, asi que se estaban pintando como si fueran
  /// Escritura. Ver `nota_al_pie.dart`.
  ///
  /// Y LA LISTA ESTA **VACIA** CUANDO NO HAY, y no tiene un null: 29.258 de los 31.102
  /// versiculos del KJV no traen ni una nota, y ese es el caso normal.
  final List<NotaAlPie> notas;

  /// Las palabras que puso el traductor, no el modulo.
  ///
  /// Y MEDIDO: 41.692 marcas en el KJV, sobre 31.102 versiculos. Y Juan 3:16 no tiene
  /// ni una, porque es texto que la traduccion no toco.
  List<String> palabrasAnadidas() => <String>[
        for (var i = 0; i < anotaciones.length; i++)
          if (anotaciones[i].esAnadido && i < palabras.length) palabras[i],
      ];

  /// Cuantas palabras de este versiculo dijo Jesus.
  ///
  /// Y MEDIDO: Juan 3:16 da 25 de 25 y Juan 3:29 da 0 de 32. Y en el Antiguo Testamento
  /// **siempre** da 0, porque alli el modulo no marca nada. Un 0 aqui no es un fallo del
  /// que se pueda quejar uno, es la respuesta correcta para la mitad del canon.
  int palabrasDeJesus() =>
      anotaciones.where((a) => a.esPalabraDeJesus).length;

  /// Si el modulo marco alguna palabra como dicha por Jesus.
  bool get tienePalabrasDeJesus =>
      anotaciones.any((a) => a.esPalabraDeJesus);

  /// [texto] partido en palabras, con la puntuacion donde estaba.
  ///
  /// Y NO SE USA PARA PINTAR, sino para poder preguntar "la palabra 7" y para ensenar
  /// cuales son las anadidas. Para pintar, [texto] entero.
  List<String> get palabras => texto.split(' ');

  @override
  String toString() => '$numero $texto';

  @override
  bool operator ==(Object other) => other is Versiculo && other.numero == numero && other.texto == texto;

  @override
  int get hashCode => Object.hash(numero, texto);
}
