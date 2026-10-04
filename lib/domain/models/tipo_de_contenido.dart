// Que clase de contenido tiene un modulo, y por que lo declara el modulo.
//
// ESTO NO ES LOGICA DEL CATALOGO, Y LA DIFERENCIA ES IMPORTANTE. La app no decide que
// un modulo es un comentario: lo **lee** de la tabla `info` del propio `.amod`, en la
// clave `type`. Si esta app tuviera una lista de "estos son comentarios", seria el
// mismo fallo que tener una lista de textos en el codigo, y con mas consecuencias: un
// comentario nuevo --uno que todavia no existe-- se abriria como si fuera una Biblia.
//
// LA MEDIDA. En los dos `.amod` reales que hay, medido el 4 de octubre de 2026:
//
//     KJV2006   info.type = 'bible'       tablas: ['info', 'verses']
//     CLARKE    info.type = 'commentary'   tablas: ['info', 'commentary']
//
// O sea que un comentario **no tiene tabla `verses`**, y cualquier consulta a
// `verses` sobre el revienta con `SqliteException(1): no such table: verses`.
//
// POR QUE NO SE MIRA `sqlite_master` EN VEZ DEL TIPO DECLARADO. Se podria: se abre el
// modulo y se pregunta que tablas tiene. Seria mas directo, y es peor. `sqlite_master`
// es la **implementacion**: si manana el comentario pasa a guardar tambien sus
// referencias en `verses`, esta comprobacion dejaria de pasar la pantalla de lectura
//(del comentario todavia no se lee), sin que nadie haya cambiado nada. Preguntar por
// `info.type` es preguntar **que es esto**, y eso es lo que decide que se puede hacer
// con el.
//
// Y POR QUE HAY UN VALOR `desconocido`. Porque el campo puede faltar, y en ese caso
// lo honesto es no saberlo y decirlo --lo hace `ModuloAbierto.abrir`, que se niega a
// abrir-- y no adivinar. Un enum sin este valor obliga a que el `switch` de todas
// partes tenga que inventar algo, y lo que inventa siempre es "es una Biblia", que es
// la suposicion que causa el crash.

/// Que clase de contenido declara un modulo en su tabla `info`.
///
/// Los nombres son los del `.amod`, en ingles, porque son **lo que dice el fichero**.
/// Traducirlos aqui crearia un sitio mas donde el nombre de la app y el del modulo
/// pueden dejar de coincidir, y un modulo con `type` desconocido se abriria como si
/// nada.
enum TipoDeContenido {
  /// Una Biblia: tabla `verses`, con `book`, `chapter`, `verse` y `text`.
  biblia('bible'),

  /// Un comentario: tabla `commentary`. **No tiene versiculos**, y por eso no se puede
  /// abrir en la pantalla de lectura.
  comentario('commentary'),

  /// Lo que el modulo declara no es ni una cosa ni la otra.
  ///
  /// No se trabaja con el: `ModuloAbierto.abrir` no deja abrir un modulo asi, y lo
  /// dice con el nombre que ha encontrado. Es preferible a tratar un tipo
  /// desconocido como si fuera una Biblia, que es lo que hacia el crash.
  desconocido('desconocido');

  const TipoDeContenido(this.nombreEnElModulo);

  /// El valor tal cual lo escribe el `.amod` en `info.type`.
  final String nombreEnElModulo;

  /// Como lo lee la app, o null si el modulo declara otra cosa.
  ///
  /// Null y no [desconocido]: aqui la pregunta es "de esto conozco el significado", y
  /// la respuesta para un tipo que no se conoce es **no saberlo**, no "desconocerlo".
  String? get textoParaLaPersona => switch (this) {
    TipoDeContenido.biblia => 'Biblia',
    TipoDeContenido.comentario => 'Comentario',
    TipoDeContenido.desconocido => null,
  };

  /// Que clase de contenido es, segun lo que dice el modulo.
  ///
  /// Y ES UN `factory` Y NO UN `fromNombre`, porque "no conozco este tipo" tiene que
  /// ser una **decision** --volver a [desconocido]-- y no un `null` que hay que
  /// acordarse de mirar. Un `fromNombre` que devuelve null obliga a cada sitio a
  /// comprobar, y hay cinco consultas que dependen de esto.
  factory TipoDeContenido.fromModulo(String? declarado) => switch (declarado) {
    'bible' => TipoDeContenido.biblia,
    'commentary' => TipoDeContenido.comentario,
    _ => TipoDeContenido.desconocido,
  };
}

/// La peticion no tiene sentido para este tipo de modulo.
///
/// Y VA POR SEPARADO DE `FalloAlAbrir`, Y ESTA SEPARACION ES LO IMPORTANTE.
///
/// `FalloAlAbrir` es "**el modulo esta mal**: no se ha podido abrir, o esta danado, o
/// no lo entiendo". Esta excepcion es "**el modulo esta bien y lo que pides no
/// aplica**: has abierto un comentario y me pides sus versiculos". Son cosas
/// distintas, y tratarlas igual tiene dos efectos malos:
///
///  1. Un comentario se anuncia como "modulo danado" cuando se pide leer, y eso es
///     mentira: se ha descargado bien y esta entero.
///  2. La app no puede distinguir "hay que bajarlo otra vez" --que es lo que se
///     ofrece con un modulo danado-- de "este modulo no tiene esta pantalla", que no
///     se arregla bajandolo otra vez.
///
/// Y POR QUE ES EXCEPCION Y NO UN RESULTADO. `ModuloAbierto` devuelve
/// `ResultadoDeAbrir` para todo lo que pasa al **abrir**, que son fallos de archivos
/// y de formato. Estas consultas ya son correctas: son validas en un modulo de otro
/// tipo. Devolverlas dentro de un resultado obligaria a que **cada** consulta de las
/// ocho comprobara el resultado, y una comprobacion que se puede olvidar en ocho sitios
/// es una que se va a olvidar. La excepcion hace que el olvido sea un fallo de
/// compilacion... en cuanto alguien escribe un test.
class NoEsUnaBiblia implements Exception {
  const NoEsUnaBiblia(this.tipo, this.queSePedian);

  final TipoDeContenido tipo;

  /// Que se estaba intentando hacer, en castellano y en minuscula.
  ///
  /// Va en el mensaje porque el mensaje lo va a leer alguien: "no se pueden pedir
  /// [esto]" dice mas que un `UnsupportedError` con el nombre del metodo.
  final String queSePedian;

  /// El mensaje, para la pantalla.
  ///
  /// Y DICE QUE SE PUEDE ABRIR, y no solo que no. El comentario se ha descargado
  /// entero y esta bien: lo que no hay todavia es una pantalla para leerlo. Decirlo
  /// evita que quien lo ha descargado piense que ha hecho algo mal.
  String get mensaje => switch (tipo) {
    TipoDeContenido.biblia => 'Este modulo es una Biblia y no deberia llegar aqui.',
    TipoDeContenido.comentario =>
      'Este modulo es un comentario, no una Biblia: no tiene versiculos, asi que no se '
          'puede leer todavia en la pantalla de lectura. El fichero esta entero y se '
          'ha descargado bien.',
    TipoDeContenido.desconocido =>
      'Este modulo declara un tipo de contenido que la app no conoce, asi que no se '
          'puede leer.',
  };

  @override
  String toString() => 'NoEsUnaBiblia(${tipo.nombreEnElModulo}): $mensaje';
}