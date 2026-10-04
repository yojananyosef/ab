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

  /// De que tabla se lee el contenido de un modulo de este tipo.
  ///
  /// Y ES EL NOMBRE **LITERAL** DE LA TABLA DEL `.amod`, y no un alias. Se escribe en
  /// las consultas con interpolacion, asi que esto solo puede ser un dato de un `switch`
  /// cerrado y nunca algo ledo del fichero. Medido sobre los dos `.amod` reales el 4 de
  /// octubre de 2026:
  ///
  ///     KJV2006   ->  'verses'
  ///     CLARKE    ->  'commentary'
  ///
  /// Y POR QUE AQUI Y NO EN CADA CONSULTA: es lo unico que hace que el mismo codigo lea
  /// las dos tablas. Con el nombre escrito a mano en las consultas habria un `if` por
  /// consulta --y hay ocho--, y ocho sitios donde olvidarse es un crash esperando. Con
  /// esta propiedad, el nombre se escribe **una vez**.
  ///
  /// Null para [desconocido], y por eso `ModuloAbierto.abrir` no deja abrir un modulo de
  /// ese tipo: sin tabla no hay nada que leer, y el refusal esta en un sitio y no en
  /// ocho.
  String? get tablaDeContenido => switch (this) {
    TipoDeContenido.biblia => 'verses',
    TipoDeContenido.comentario => 'commentary',
    TipoDeContenido.desconocido => null,
  };

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
