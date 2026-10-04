// Elegir un fichero del dispositivo.
//
// Que la UI no sepa como se elige un fichero, igual que no sabe como se abre un
// SQLite. Esto devuelve **bytes y nombre**, y nada mas.
//
// POR QUE DOS IMPLEMENTACIONES Y NO UNA. En nativo se usa el selector del
// sistema, que es lo que la gente espera: el dialogo de su propio sistema
// operativo, con el que ya sabe moverse. En el navegador hay que hacerlo con un
// `<input type="file">`, que es lo que el navegador pone delante de uno si no hay
// otra manera.
//
// Y POR QUE EN WEB NO HAY "ARRASTRAR Y SOLTAR" SEPARADO: el `<input type=file>`
// ya acepta soltar un fichero encima de la ventana. Es exactamente el mismo
// dialogo. La API es una sola en las dos plataformas y quien llama no elige.
//
// LO QUE NO HACE, Y ES LO IMPORTANTE: **no mira dentro del fichero**. Solo lee
// bytes. Reconocer un modulo es otra cosa, en `ReconocerModuloLocal`, y es donde
// se comprueba el hash contra el manifiesto. Que aqui no se mire nada del
// contenido es lo que evita que un fichero de 57 MiB se lea dos veces.

import 'selector_de_archivos_nativo.dart'
    if (dart.library.js_interop) 'selector_de_archivos_web.dart'
    as impl;

/// Un fichero que la persona ha elegido.
class ArchivoElegido {
  const ArchivoElegido({required this.nombre, required this.bytes});

  final String nombre;

  /// Los bytes, tal cual. Sin decodificar: un `.amod` son bytes, y convertirlo a
  /// texto con la codificacion que toque es una forma de corromperlo.
  final List<int> bytes;
}

/// El resultado de pedir un fichero.
///
/// "Ha cancelado" es un resultado de primera clase con su propio constructor, y no
/// una excepcion ni un null suelto. La razon es concreta: cancelar es el caso
/// **normal**, no un fallo, y en un movil abrir el selector y echarse atras es lo
/// que hace la mitad de la gente la primera vez. Si cancelar fuera un error, cada
/// sitio que llama tendria que distinguirlo por otra via, y casi todos lo harian
/// mal acabando enseñando "no se ha podido abrir el fichero" a quien solo queria
/// cambiar de idea.
class ResultadoDeElegir {
  /// La persona ha elegido un fichero.
  const ResultadoDeElegir.elegido(this.archivo) : motivo = null;

  /// La persona ha cerrado sin elegir. **No es un error.**
  const ResultadoDeElegir.cancelado() : archivo = null, motivo = null;

  /// No se ha podido ni leer ni elegir.
  const ResultadoDeElegir.fallido(this.motivo) : archivo = null;

  final ArchivoElegido? archivo;

  /// Texto para la pantalla. Null si se leyo o si se cancelo.
  final String? motivo;

  bool get elegido => archivo != null;
  bool get cancelado => archivo == null && motivo == null;
  bool get fallido => motivo != null;
}

/// Lo que la UI llama. Sin estado y sin dependencias, para que se pueda probar
/// con un doble y no hace falta montar nada.
abstract class SelectorDeArchivos {
  /// Abre el selector y espera. Devuelve cancelado si la persona no elige nada.
  Future<ResultadoDeElegir> elegir();

  /// El filtro de extensiones que se sugiere. Null para no filtrar.
  ///
  /// Se sugiere y no se impone, a proposito: en algunos sistemas el filtro
  /// esconde ficheros que la persona quiere y no puede llegar a ellos. Y un filtro
  /// que esconde ficheros hace que la gente piense que la app ha perdido su
  /// Biblia.
  List<String>? get filtroSugerido;

  /// Cierra lo que haya abierto. Quien lo crea, lo cierra.
  void dispose();
}

/// La implementacion de verdad, segun la plataforma.
///
/// Un solo punto de entrada y dos ficheros mas, porque hay exactamente dos formas
/// de elegir un fichero segun donde se corra: el dialogo del sistema o el del
/// navegador. Si aparece una tercera, se anade aqui y no en ningun otro sitio.
SelectorDeArchivos crearSelectorDeArchivos() => impl.crearSelector();
