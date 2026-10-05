// Un modulo abierto, y lo que se le puede preguntar.
//
// UN MODULO ABIERTO ES SOLO LECTURA Y SE ABRE UNA VEZ. Se comprueba con
// `PRAGMA quick_check` al abrirlo, y si no esta entero **no se abre**: leer un
// `.amod` descargado a medias da versiculos vacios y silenciosos, que es la forma
// mas facil de crea que la Biblia esta danada cuando lo que esta
// danado es la descarga.
//
// LO QUE HACE ESTA CLASE Y LO QUE NO. Pregunta al modulo. No decide nada, no
// busca por nombre de libro en castellano --eso lo hace el dominio-- y no guarda
// nada entre llamadas. Es la capa mas boring del proyecto a proposito: lo boring es
// lo que no falla.
//
// LOS NUMEROS SALEN DE AQUI, NUNCA DE UNA TABLA. Ni capitulos, ni versiculos por
// libro, ni nada. Se le pregunta al modulo con una consulta, y el motivo esta
// medido en el repositorio hermano: su tabla de libros se escribio primero de
// memoria y **21 de 66 tenia un numero de versiculos equivocado**. Genesis ofrece
// 50 capitulos y un 51 es exactamente el error de la RVR, que se leeria con la tabla
// de este proyecto en vez de con la del modulo.

import 'package:ab/data/services/sqlite_service.dart';
import 'package:ab/data/services/analizador_usfm.dart';
import 'package:ab/domain/models/indice_de_strong.dart';
import 'package:ab/domain/models/nota.dart';
import 'package:ab/domain/models/pasaje.dart';
import 'package:ab/domain/models/resultado_de_busqueda.dart';
import 'package:ab/domain/models/tipo_de_contenido.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/token_de_texto.dart';
import 'package:ab/domain/models/versiculo.dart';

/// Un modulo abierto y listo para leer.
class ModuloAbierto {
  ModuloAbierto._(this._sqlite, this.id, this.ruta, this._tipo);

  final Sqlite _sqlite;

  /// Que clase de contenido es, segun el propio modulo.
  final TipoDeContenido _tipo;

  /// El identificador del manifiesto, no el que declara la tabla `info`. Puede que
  /// sean distintos, y el del manifiesto es el que la biblioteca usa.
  final String id;

  /// Por donde se abrio. Se ensena en los terminos: quien esta leyendo puede
  /// necesitar saber de donde salio el texto.
  final String ruta;

  /// Abre el modulo, o devuelve el motivo por el que no se puede.
  ///
  /// Se comprueba la integridad **antes** de devolver nada, y el motivo va en el
  /// error. Un `null` aqui seria un fallo que el que llama tendria que adivinar.
  static ResultadoDeAbrir abrir(String ruta, {required String id}) {
    late final Sqlite sqlite;
    try {
      sqlite = Sqlite.abrir(ruta);
    } catch (e) {
      return FalloAlAbrir('No se ha podido abrir el modulo: $e');
    }

    try {
      final check = sqlite.comprobacionRapida();
      if (check != 'ok') {
        sqlite.cerrar();
        return FalloAlAbrir(
          'El modulo esta incompleto o danado ($check). Conviene borrarlo y bajarlo '
          'otra vez.',
        );
      }
    } catch (e) {
      sqlite.cerrar();
      return FalloAlAbrir('No se ha podido comprobar el modulo: $e');
    }

    // La `schema_version` se comprueba aqui y no en la pantalla, porque es el unico
    // sitio donde hay algo que hacer si no cuadra: negarse a abrir.
    //
    // Y el `minReaderVersion` **no** se comprueba aqui: esa tabla no lo tiene. Vive
    // en `catalog.json`, y lo comprueba quien tiene el manifiesto. Ver `AGENTS.md`.
    final version = sqlite.infoEntero('schema_version');
    if (version == null) {
      sqlite.cerrar();
      return FalloAlAbrir(
        'El modulo no dice que version del formato usa, y sin eso no se puede saber '
        'si se entiende.',
      );
    }

    // QUE ES EL MODULO, SE PREGUNTA ANTES DE DEVOLVER NADA.
    //
    // MEDIDO EL 4 DE OCTUBRE DE 2026 con el CLARKE real: abrirlo y preguntarle cuantos
    // versiculos tiene reventaba con
    //
    //     SqliteException(1): no such table: verses
    //
    // porque un comentario **no tiene tabla `verses`**: tiene `commentary`. Las dos
    // estan medidas, en los `.amod` de verdad:
    //
    //     KJV2006   ->  ['info', 'verses']
    //     CLARKE    ->  ['info', 'commentary']
    //
    // La appiatreatment toda consulta de `verses` a todos los modulos, y el catalogo
    // publica las dos clases. O sea que el comentario se podia descargar, se guardaba,
    // y era **imposible de abrir**: reventaba al abrir. Y no lo detectaba ninguna de
    // las 338 pruebas, porque todas las que abren un modulo usan el KJV.
    //
    // Y NO SE COMPRUEBA LA TABLA, SINO LO QUE DICE EL MODULO. Se podria hacer
    // `SELECT name FROM sqlite_master` y mirar que tablas hay, y seria mirar la
    // **implementacion** del modulo en vez de lo que el modulo **declara**. El propio
    // `.amod` dice que es, en su tabla `info`, en la clave `type`: `bible` o
    // `commentary`. Se pregunta eso, y el que dice que es lo que se le hace caso.
    final tipo = sqlite.info('type');
    if (tipo == null) {
      sqlite.cerrar();
      return FalloAlAbrir(
        'El modulo no dice que tipo de contenido es, y sin eso no se puede saber si '
        'se entiende.',
      );
    }

    final contenido = TipoDeContenido.fromModulo(tipo);

    // Y UN TIPO QUE NO SE CONOCE NO SE ABRE, y es aqui y no en cada consulta.
    //
    // Antes el refusal estaba en ocho metodos, uno por consulta, y era el unico sitio
    // donde no se podia olvidar porque todos decian lo mismo. Ahora que un comentario
    // **si** se lee, el caso que queda es el tipo desconocido, y no hay ocho sino **uno**:
    // la tabla de la que se lee sale del tipo, y un tipo sin tabla no tiene nada que
    // leer. Un solo sitio es un sitio que se puede comprobar.
    if (contenido.tablaDeContenido == null) {
      sqlite.cerrar();
      return FalloAlAbrir(
        'El modulo declara que su contenido es de tipo "$tipo", que esta app no sabe '
        'leer. Se ha descargado bien; lo que no se puede es enseñarlo.',
      );
    }

    return Abierto(ModuloAbierto._(sqlite, id, ruta, contenido));
  }

  void cerrar() => _sqlite.cerrar();

  /// Que clase de contenido declara un modulo, **sin abrirlo del todo**.
  ///
  /// Y LA DIFERENCIA CON [ModuloAbierto.abrir] ES EL MOTIVO DE QUE EXISTA ESTA
  /// FUNCION. Abrir hace `PRAGMA quick_check` sobre el fichero entero --son 57 MiB en un
  /// comentario--, y la biblioteca solo quiere **una etiqueta** para cada fila. Preguntar
  /// lo que es un modulo no necesita comprobar que el modulo este entero: si el
  /// fichero esta a medias, su tabla `info` no estara, y eso es un `null` que la
  /// pantalla dira como "no se sabe".
  ///
  /// Y SE DEVUELVE NULL Y NO "biblia" POR SI FALLA. Un `try`/`catch` que devuelve
  /// `null` a proposito: este metodo es una **pregunta**, y una pregunta que no se
  /// puede responder tiene que poder decir que no, no contestar lo que parece.
  ///
  /// Y NO SE ABRE PARA NADA MAS. Sigue siendo una excepcion lo que pase si luego se
  /// pide un versiculo: esto solo lee `info.type`.
  static TipoDeContenido? tipoDeContenidoDe(String ruta) {
    Sqlite? sqlite;
    try {
      sqlite = Sqlite.abrir(ruta);
      final declarado = sqlite.info('type');
      return declarado == null ? null : TipoDeContenido.fromModulo(declarado);
    } catch (_) {
      return null;
    } finally {
      sqlite?.cerrar();
    }
  }

  // --- los terminos ---

  /// Un campo de la tabla `info`.
  String? info(String clave) => _sqlite.info(clave);

  /// Que clase de contenido es este modulo, segun el propio modulo.
  TipoDeContenido get tipo => _tipo;

  /// De que tabla se lee el contenido.
  ///
  /// Y LA RESOLUCION ESTA EN EL CONSTRUCTOR Y NO EN CADA CONSULTA. El nombre de la
  /// tabla no se escribe ni una vez en las consultas: sale de aqui, del tipo que declara
  /// el propio modulo. Es lo unico que hace que el mismo codigo sirva para una Biblia --
  /// tabla `verses`, un texto por versiculo-- y para un comentario --tabla `commentary`,
  /// varias notas por versiculo-- sin un `if` en cada consulta.
  ///
  /// Y NO PUEDE SER NULL. `abrir` no deja pasar un modulo cuyo tipo no tiene tabla, y
  /// por eso el `!` de abajo no puede saltar: es una comprobacion del constructor de
  /// hecha una vez y que no se vuelve a hacer.
  String get _tabla => _tablaDeContenido!;

  /// El nombre de la tabla de contenido, tal cual lo usa el `.amod`.
  ///
  /// Y ES EL **NOMBRE DE LA TABLA** Y NO UN ALIAS. Se escribe en la consulta con
  /// interpolacion, y eso seria una inyeccion de SQL si el valor viniera de fuera. Aqui
  /// no puede venir: sale de un `switch` cerrado sobre un enum, y no de un dato leido del
  /// fichero. Si algun dia esto pasara a leer el nombre de la tabla de `info`, deja de
  /// ser valido y hay que mettrelo en la lista blanca de `sqlite_service.dart`.
  String? get _tablaDeContenido => _tipo.tablaDeContenido;

  /// Si este modulo trae texto de Biblia.
  ///
  /// Y NO SE USA PARA PODER LEER. Un comentario tambien se lee; lo que no trae es
  /// **texto de Biblia**. Confundir "no tiene versiculos" con "no se puede leer" fue
  /// exactamente el fallo que dejo el comentario imposible de abrir.
  bool get tieneTextosDeBiblia => _tipo == TipoDeContenido.biblia;

  /// Si este modulo trae notas de comentario.
  bool get tieneNotas => _tipo == TipoDeContenido.comentario;

  /// Un campo entero de la tabla `info`, o null si no esta o no es un numero.
  ///
  /// Null y no cero: `defects_count` ausente y `defects_count` de cero son cosas
  /// distintas, y la primera significa "el modulo no lo dice" mientras que la segunda
  /// significa "el modulo dice que no tiene ninguno". Con la primera no se puede
  /// afirmar que el texto este completo.
  int? infoEntero(String clave) => _sqlite.infoEntero(clave);

  // --- los libros ---

  /// Los libros que este modulo tiene, **en orden alfabetico**.
  ///
  /// En orden alfabetico y no en orden canonico, y es a proposito: el modulo guarda
  /// `book` como texto sin indice, asi que el orden canonico no lo declara nadie. Se
  /// reordena con la tabla de libros del dominio, que si lo sabe.
  List<String> libros() => _sqlite
      .consultar('SELECT DISTINCT book FROM $_tabla ORDER BY book')
      .map((f) => f['book'] as String)
      .toList();

  /// Cuantos versiculos tiene un libro.
  ///
  /// Y ES `count(DISTINCT verse)` Y NO `count(*)`. En una Biblia son lo mismo, porque
  /// hay un texto por versiculo. En un comentario **no**: Juan 3:16 tiene tres notas, y
  /// `count(*)` diria que Juan tiene mas versiculos de los que tiene. El numero que
  /// importa es de quantos versiculos hay nota.
  int? versiculosDe(String libro) => _sqlite.valor(
    'SELECT count(DISTINCT verse) FROM $_tabla WHERE book = ?',
    [libro],
  ) as int?;

  /// Los capitulos que tiene un libro, en orden.
  ///
  /// ESTA ES LA CONSULTA QUE SUSTITUYE A UNA TABLA DE NUMEROS. Y por eso devuelve
  /// una lista y no un total: un total no sabe si el libro tiene un hueco, y un hueco
  /// en una traduccion es informacion real. La RVR, por ejemplo, tiene libros con un
  /// capitulo vacio, y ofrecer "capitulo 51" en uno de ellos lleva a una pantalla en
  /// blanco.
  List<int> capitulosDe(String libro) => _sqlite
      .consultar(
        'SELECT DISTINCT chapter FROM $_tabla WHERE book = ? ORDER BY chapter',
        [libro],
      )
      .map((f) => f['chapter'] as int)
      .toList();

  /// Los libros del modulo con sus capitulos, de una vez.
  ///
  /// Y ES UNA CONSULTA Y NO 66. Leer los 66 libros con un `libros()` y luego un
  /// `capitulosDe()` por libro son 67 consultas para pintar una lista; esta es una y son
  /// 21 ms en el KJV real. Y la diferencia se ve en el movil, que es donde se abre esto.
  ///
  /// Y EL RESULTADO VIENE EN ORDEN DE LA BASE, y se reordena en la interfaz con la tabla
  /// de libros del dominio, que si sabe el orden canonico. Aqui `book` es texto sin
  /// indice, asi que `ORDER BY book` pone `1Corinthians` antes que `John` --y una lista
  /// de libros en orden alfabetico no es una lista de libros de la Biblia.
  Map<String, List<int>> librosConCapitulos() {
    final salida = <String, List<int>>{};
    for (final f in _sqlite.consultar(
      'SELECT book, chapter FROM $_tabla GROUP BY book, chapter ORDER BY book, chapter',
    )) {
      (salida[f['book'] as String] ??= <int>[]).add(f['chapter'] as int);
    }
    return salida;
  }

  /// La primera frase de cada capitulo de un libro.
  ///
  /// Y LA PRIMERA FRASE, NO UN RESUMEN, y el nombre lo dice para que no haya que
  /// recordarlo. Un resumen de capitulo es lo que hace Bible Gateway y es la mejor idea de
  /// localizacion de referencias que se ha visto: resuelve "se que estaba en el capitulo
  /// 12 de algo, pero no de que". Un resumen de verdad son las palabras del capitulo en
  /// tres lineas, y eso **no esta en el modulo**: habria que escribirlo, y escribirlo es
  /// el dato de otra persona.
  ///
  /// Lo que si esta es el texto, y la primera frase es una preview honesta: "Adam, Sheth,
  /// Enosh" es de donde empieza el capitulo, y eso ya quita la mitad de la duda. Se medira
  /// sobre el fichero real en `test/data/`.
  ///
  /// Y DEVUELVE UN MAPA Y NO UNA LISTA, porque se pregunta por un capitulo concreto y un
  /// mapa se responde en O(1) sin recorrer los 21.
  Map<int, String> primeraFraseDeCapitulos(String libro) {
    final salida = <int, String>{};
    for (final f in _sqlite.consultar(
      'SELECT chapter, text FROM $_tabla WHERE book = ? AND verse = 1 ORDER BY chapter',
      [libro],
    )) {
      salida[f['chapter'] as int] = _primeraFrase(f['text'] as String);
    }
    return salida;
  }

  /// Las primeras palabras de un texto, hasta donde se puede leer una frase entera.
  ///
  /// Y CORTA EN UNA FRASE Y NO EN UN NUMERO DE CARACTERES, y por eso hay una comprobacion
  /// de que sea larga. Cortar en 120 caracteres parte frases por la mitad y deja el final
  /// colgando: "...y dijo a". Cortar donde hay un punto deja algo que se lee.
  ///
  /// Y SI NO HAY PUNTO EN LA FRASE ENTERA, se corta en 160 caracteres con puntos suspensivos,
  /// que es lo unico honesto cuando la frase no acaba. Juan 1:1 entero son 17 palabras sin
  /// un solo punto --los cuatro evangelios abrian asi-- y ahi no hay frase que cortar.
  String _primeraFrase(String texto) {
    final limite = texto.indexOf('. ');
    if (limite > 0 && limite <= 200) {
      return texto.substring(0, limite + 1);
    }
    if (texto.length <= 160) return texto;
    return '${texto.substring(0, 157).trimRight()}...';
  }

  /// El numero de capitulos, o null si el libro no esta.
  ///
  /// Null y no 0: "no lo tiene" y "tiene ninguno" son cosas distintas, y un 0
  /// llevaria a pintar un libro con cero capitulos, que es un bug de los que se ven.
  int? numeroDeCapitulos(String libro) {
    final lista = capitulosDe(libro);
    return lista.isEmpty ? null : lista.length;
  }

  // --- los versiculos ---

  /// Lo que hay en un capitulo, o en un solo versiculo.
  ///
  /// Y SON DOS COSAS DISTINTAS EN UN SOLO METODO, Y NO UN METODO CON UN `if`. Un
  /// `if (esComentario)` aqui meteria en el mismo return el texto de la Sagrada
  /// Escritura y el de un teologo de 1832, que es justo la confusion que este change
  /// viene a quitar. Aqui se separa: el texto va en `versiculos` y la nota va en `notas`,
  /// y el `switch` es sobre el **tipo**, que es un dato, no sobre una conjetura.
  ///
  /// Con [Referencia.versiculo] nulo son todas las del capitulo. Con versiculo, uno
  /// solo. Y si no existe ninguno, un pasaje vacio --no null--, porque la pantalla
  /// tiene que poder pintar "aqui no hay nada" y eso es un resultado, no un fallo.
  ///
  /// El texto sale del campo `text`, que ya viene limpio, en las dos tablas. El campo
  /// `raw` con marcas USFM --`\+w Dios|strong="G2316"`-- se consume **en otro sitio**,
  /// cuando se pinte la palabra de Dios en rojo. Aqui el texto se pasa tal cual: un
  /// lector que altera el texto que va a leer es un lector que no se puede citar, y eso
  /// vale igual para un versiculo que para una nota.
  Pasaje leer(Referencia referencia) {
    // Y LA CONSULTA SE MONTA ENTERA Y NO A TROZOS CON INTERPOLACION CONDICIONAL. La
    // primera version hacia `'... WHERE book = ? AND chapter = ?'
    // '${tieneNotas ? ', seq' : ''}'`, que es un `, seq` pegado **despues** del `?` y no
    // en la lista de columnas: `SELECT verse, text FROM commentary WHERE book = ? AND
    // chapter = ?, seq ORDER BY verse`, y SQLite contesta `near ",": syntax error`.
    //
    // El fallo es instructivo porque **parecia** funcionar: en `_exigirVersiculos` el
    // `tieneNotas` era siempre falso, asi que la rama del comentario no se ejecutaba
    // nunca y no habia forma de verlo.
    // Y LA COLUMNA `raw` TAMBIEN, y solo cuando el modulo tiene las dos. Traerla siempre
    // seria el doble de bytes de la lectura por unas marcas que el comentario no tiene
    // --medido: sus 19.742 notas tienen `raw == text`, sin una barra-- y el comentario no
    // se pinta palabra a palabra porque son suyas, no del texto.
    final conRaw = tieneTextosDeBiblia;
    final seleccion = tieneNotas
        ? 'SELECT verse, seq, text FROM $_tabla'
        : conRaw
            ? 'SELECT verse, text, raw FROM $_tabla'
            : 'SELECT verse, text FROM $_tabla';
    final orden = tieneNotas ? ' ORDER BY verse, seq' : ' ORDER BY verse';
    // ============================================================================
    // Y UN VERSICULO **NO** FILTRA: TRAE EL CAPITULO ENTERO Y MARCA CUAL ES EL QUE SE
    // PIDIO. Y ESTO SE CAMBIO AL MEDIR, Y EL MOTIVO ES QUE LA PANTALLA NO ENSENABA NADA.
    // ============================================================================
    //
    // Medido en una captura de la pantalla de lectura a 360 px, con Juan 3:16 abierto en
    // el KJV y el modulo entero ya descargado:
    //
    //     barra de arriba                          56 px
    //     cromo antes del versiculo               206 px
    //     el versiculo 16, que es todo el texto    122 px
    //     los terminos del modulo                  268 px
    //     ---------------------------------------------------------
    //     de 760 px: el versiculo es el **16 %** de la pantalla
    //
    // Un lector de Biblia que al abrir Juan 3:16 ensefna **un versiculo y tres lineas de
    // terminos** no esta enseñando la Biblia. Y el problema no es el diseno de la pantalla:
    // es que el dato que llega es un versiculo, y no hay nada mas que pintar.
    //
    // Y LO QUE DICEN LOS TRES QUE SE COPIAN:
    //
    //   - YouVersion, de `docs/investigacion-ux.md`: "la URL canonica por pasaje...
    //     que ademas **selecciona** el primer versiculo del rango al abrirse". Selecciona,
    //     no acota.
    //
    //   - MyBible, del mismo documento: "it allows you to put any place of a book into the
    //     center of your screen and study it in its immediate context". **Su contexto
    //     inmediato**, que es el capitulo.
    //
    //   - Y el mismo documento, de Accordance: la ambiguedad de versificacion "se muestra,
    //     no se tapa... resolviendo mostrando los paneles en paralelo en vez de dejar un
    //     numero en blanco". Un versiculo suelto no deja ver si los de al lado cuentan igual.
    //
    // Y EL FILTRO **NO SE PIERDE**: `Pasaje.versiculoPedido` dice cual es, y la vista lo
    // marca. Un enlace a Juan 3:16 sigue abriendo Juan 3 con el 16 destacado, que es lo
    // que pedia el enlace.
    //
    // Y EL COSTE, MEDIDO SOBRE EL KJV REAL con el `raw` de los Strongincluded y todo:
    //
    //     Juan 3:16      21 versiculos    2.338 caracteres     5,1 ms
    //     Juan 3         36 versiculos    3.969 caracteres     5,0 ms
    //     Genesis 1      31 versiculos    4.994 caracteres     2,5 ms
    //     Apocalipsis 22 21 versiculos    2.880 caracteres     1,3 ms
    //     Salmos 119    176 versiculos   14.116 caracteres     9,6 ms
    //     el comentario, Juan 3:16     19 notas                    0,26 ms
    //
    // Y EL QUE MANDA ES EL `raw`, no el texto: casi todo ese tiempo es el analizador USFM
    // emparejando las anotaciones con las palabras, y por eso dos capitulos con casi los
    // mismos caracteres --Juan 3:16 con 2.338 y Apocalipsis 22 con 2.880-- cuestan 5,1 y
    // 1,3 ms.
    //
    // SALMOS 119 ES EL PEOR CASO Y SIGUE SIENDO BARATO: 176 versiculos y 9,6 ms. Y lo que
    // se nota de ese capitulo no es el tiempo, es que hay que desplazarse mucho: es el
    // unico de la Biblia que no cabe en una pantalla ni en diez.
    final filas = _sqlite.consultar(
      referencia.versiculo == null
          ? '$seleccion WHERE book = ? AND chapter = ?$orden'
          : // Y CUANDO HAY VERSICULO, `verse >= ?` Y NO `verse = ?`. Con `=` sale un
            // versiculo; con `>=` sale el capitulo desde el pedido, que es lo que se lee:
            // uno no abre Juan 3:16 para ver Juan 3:1, sino para leer desde ahi.
            '$seleccion WHERE book = ? AND chapter = ? AND verse >= ?$orden',
      <Object?>[
        referencia.libro,
        referencia.capitulo,
        if (referencia.versiculo != null) referencia.versiculo!,
      ],
    );

    return Pasaje(
      referencia: referencia,
      titulo: referencia.texto,
      versiculoPedido: referencia.versiculo,
      versiculos: tieneNotas
          ? const <Versiculo>[]
          : <Versiculo>[
              for (final f in filas)
                Versiculo(
                  f['verse'] as int,
                  f['text'] as String,
                  anotaciones: conRaw
                      ? anotarTexto(
                          f['text'] as String,
                          f['raw'] as String?,
                        ).anotaciones
                      : const <AnotacionDePalabra>[],
                ),
            ],
      // Y LAS NOTAS IDENTICAS SE QUITAN, Y ESTO ES UNA EXCEPCION MEDIDA.
      //
      // El CLARKE publicado tiene 19.742 notas en 19.741 pasajes: **un** versiculo con dos
      // notas, Mateo 23:13, y las dos son **el mismo texto**, byte a byte, 2.709
      // caracteres cada una. Medido el 4 de octubre de 2026 con `length()` y con
      // `=` sobre el fichero real.
      //
      // Es decir: el modulo tiene una fila repetida. Y `info.defects_count` dice `0`, con
      // lo cual esta **mintiendo**; el defecto no esta declarado. Ver `AGENTS.md`.
      //
      // Que se quite en la app y no en el modulo es deliberado, y por dos razones. Una: la
      // app es de solo lectura y no toca el `.amod`. Dos: un lector que ensena el mismo
      // parrafo de 2.709 caracteres dos veces seguidas parece roto, y quien lo ve no
      // puede saber que la culpa es del dato.
      //
      // Y SOLO SE QUITA CUANDO EL TEXTO ES **IDENTICO** Y EN EL **MISMO VERSICULO**. Un
      // comentario que de verdad repita una frase en dos versiculos distintos, o dos
      // notas parecidas que no sean iguales, se ensenan las dos: quitar contenido porque
      // se parece a otro es peor que ensenarlo de mas.
      notas: tieneNotas
          ? <Nota>[
              for (final f in filas)
                if (!_repetidaDeInmediato(filas, f))
                  Nota(
                    versiculo: f['verse'] as int,
                    orden: f['seq'] as int,
                    texto: f['text'] as String,
                  ),
            ]
          : const <Nota>[],
    );
  }

  /// Si esta fila es la repeticion inmediata de la anterior, con el mismo texto.
  ///
  /// Y "inmediata" Y NO "la anterior del mismo versiculo" porque las filas llegan
  /// ordenadas por `verse, seq`: dos notas identicas del mismo versiculo son contiguas, y
  /// dos notas identicas de versiculos **distintos** --que pueden existir-- no se tocan,
  /// porque son dos cosas que el autor escribio en dos sitios.
  static bool _repetidaDeInmediato(
    List<Map<String, Object?>> filas,
    Map<String, Object?> fila,
  ) {
    final i = filas.indexOf(fila);
    if (i <= 0) return false;
    final anterior = filas[i - 1];
    return anterior['verse'] == fila['verse'] && anterior['text'] == fila['text'];
  }

  /// Si ese pasaje existe en este modulo.
  bool existe(Referencia referencia) {
    final n = _sqlite.valor(
      'SELECT count(*) FROM $_tabla WHERE book = ? AND chapter = ?'
      '${referencia.versiculo == null ? '' : ' AND verse = ?'}',
      <Object?>[
        referencia.libro,
        referencia.capitulo,
        if (referencia.versiculo != null) referencia.versiculo,
      ],
    ) as int?;
    return (n ?? 0) > 0;
  }

  /// Que versiculos hay en un capitulo, sin el texto.
  ///
  /// Va aparte de [leer] porque la biblioteca y el selector de capitulos la necesitan
  /// sin el texto: traer 3.119 versiculos de Juan para pintar una lista de numeros
  /// es tirar la memoria para pintar una fila.
  ///
  /// Y `DISTINCT` PORQUE EN UN COMENTARIO HAY VARIAS NOTAS POR VERSICULO. Sin el, el
  /// selector de Juan 3 ofreceria el 16 tres veces, que es como se ve que no se ha
  /// tenido en cuenta que la clave primaria son cuatro columnas.
  List<int> numerosDeVersiculos(Referencia referencia) => _sqlite
      .consultar(
        'SELECT DISTINCT verse FROM $_tabla WHERE book = ? AND chapter = ? ORDER BY verse',
        <Object?>[referencia.libro, referencia.capitulo],
      )
      .map((f) => f['verse'] as int)
      .toList();

  /// Cuantos versiculos tienen contenido en este modulo.
  ///
  /// Y NO ES `count(DISTINCT verse)`, QUE ES LO QUE PARECE Y ESTA MEDIDO QUE FALLA.
  /// Sobre el KJV real, el 4 de octubre de 2026:
  ///
  ///     SELECT count(DISTINCT verse) FROM verses   ->  176
  ///
  /// No 31.102. Porque `verse` es el numero **dentro del capitulo**, y en todo el modulo
  /// solo hay 176 numeros distintos. Es un numero cierto y no es el que se quiere.
  ///
  /// Lo que cuenta versiculos es contar **pasajes**, que son la terna de libro, capitulo
  /// y versiculo. En el KJV da 31.102; en el CLARKE da 19.741, que son los versiculos que
  /// tienen al menos una nota --una menos que las 19.742 notas, porque Mateo 23:13 tiene
  /// dos--, y ese es exactamente el numero que el selector de versiculos tiene que
  /// ofrecer.
  int totalDeVersiculos() => _sqlite.valor(
        'SELECT count(*) FROM (SELECT DISTINCT book, chapter, verse FROM $_tabla)',
      ) as int? ?? 0;

  /// Cuantas notas de comentario tiene este modulo en total.
  ///
  /// Y EN UN MODULO DE BIBLIA ES 0, Y NO UN ERROR. La tabla `verses` no tiene columna
  /// `seq`, asi que la consulta no se puede hacer; y el numero de filas de una tabla
  /// que no guarda notas **si** es cero. Se comprueba el tipo antes de preguntar, que es
  /// un `switch` sobre un dato y no una excepcion de SQL.
  int totalDeNotas() => tieneNotas
      ? _sqlite.valor('SELECT count(*) FROM $_tabla') as int? ?? 0
      : 0;

  /// Cuantos versiculos de este modulo tienen el numero [numero].
  ///
  /// Y SON **VERSI...CULOS**, y no ocurrencias: Juan 3:16 tiene `Dios` una vez y Mateo 1:23
  /// tres, y la lista que se pinta es de versiculos. Medido el 5 de octubre de 2026 sobre el
  /// KJV real: `G2316` sale en 1.171 versiculos y 1.359 veces en total, y son dos numeros
  /// distintos. Confundirlos haria que el indice prometiese una lista mas corta de lo que
  /// es.
  ///
  /// Y LA CONSULTA ES UN `LIKE` Y NO UN INDICE, y no hace falta indice. Medido: 15 ms en
  /// el KJV entero y 15 ms en el CLARKE. Montar un indice FTS5 para esto seria mas lento
  /// que el indice.
  int versiculosConStrong(String numero) {
    final limpio = _numeroDeStrong(numero);
    if (limpio == null) return 0;
    return _sqlite.valor(
          'SELECT count(*) FROM $_tabla WHERE raw LIKE ?',
          <Object?>['%strong="$limpio"%'],
        ) as int? ??
        0;
  }

  /// Los versiculos que tienen el numero [numero], con las palabras que lo llevan.
  ///
  /// Y SE ANALIZA CADA UNO CON [anotarTexto] Y NO CON UNA REGEX SUELTA, y es lo unico que
  /// garantiza que lo que dice el indice es **la misma palabra** que la que se ve al
  /// pulsar. Con una expresion regular por dentro seria mas rapido, y la palabra del indice
  /// seria la del final del marcador en vez de la primera, que es la que muestra la
  /// pantalla: dos sitios que dicen cosas distintas de lo mismo.
  List<IndiceDeStrong> indiceDeStrong(String numero, {int limite = limiteDeResultados}) {
    final limpio = _numeroDeStrong(numero);
    if (limpio == null) return const <IndiceDeStrong>[];

    final filas = _sqlite.consultar(
      'SELECT book, chapter, verse, text, raw FROM $_tabla WHERE raw LIKE ? '
      'ORDER BY book, chapter, verse LIMIT ?',
      <Object?>['%strong="$limpio"%', limite],
    );

    return <IndiceDeStrong>[
      for (final f in filas)
        () {
          final anotado = anotarTexto(f['text'] as String, f['raw'] as String?);
          final palabras = anotado.palabras;
          final dondeVaElNumero = <int>[
            for (var i = 0; i < anotado.anotaciones.length; i++)
              if (anotado.anotaciones[i].strong == limpio) i,
          ];
          // Y SI NO SE ENCUENTRA LA PALBRA, LA ENTRADA **NO SE INVENTA**: se queda solo
          // el versiculo, sin palabra. Pasa cuando el marcado y el texto no casan, que es
          // el 2,4% de los versiculos del KJV. Con la palabra inventada seria peor que
          // sin entrada.
          return IndiceDeStrong(
            referencia: Referencia(
              f['book'] as String,
              f['chapter'] as int,
              f['verse'] as int,
            ),
            palabras: <String>[
              for (final i in dondeVaElNumero)
                if (i < palabras.length) _sinPuntuacion(palabras[i]),
            ],
          );
        }(),
    ];
  }

  /// Las formas distintas de la palabra, y cuantas veces sale cada una en lo indeksado.
  ///
  /// Y SE CUENTA SOBRE LO QUE SE ENSENA Y NO SOBRE TODO EL MODULO, porque es lo que se
  /// puede ver: si el indice trae 200 de 1.171, decir "y 971 mas" es verdad y decir
  /// "`God` sale 248 veces" contaria sobre los 1.171, que no se ven.
  Map<String, int> formasDeStrong(String numero, {int limite = limiteDeResultados}) {
    final cuenta = <String, int>{};
    for (final entrada in indiceDeStrong(numero, limite: limite)) {
      for (final palabra in entrada.palabras) {
        cuenta[palabra] = (cuenta[palabra] ?? 0) + 1;
      }
    }
    return cuenta;
  }

  /// El numero del lexicon tal cual lo usa el modulo, o null si no lo es.
  ///
  /// Y `G` O `H` Y CUATRO O MAS DIGITOS. `G1` no es una entrada del lexicon, y aceptarlo
  /// seria poner un numero inventado al lado de una palabra.
  String? _numeroDeStrong(String numero) {
    final limpio = numero.trim().toUpperCase();
    if (limpio.length < 4) return null;
    if (limpio[0] != 'G' && limpio[0] != 'H') return null;
    for (var i = 1; i < limpio.length; i++) {
      final u = limpio.codeUnitAt(i);
      if (u < 0x30 || u > 0x39) return null;
    }
    return limpio;
  }

  /// La palabra del indice sin la puntuacion que en el texto va pegada.
  String _sinPuntuacion(String palabra) => palabra.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

  /// Busca una palabra en todo el modulo y devuelve los resultados con su extracto.
  ///
  /// `LIKE` y no `MATCH`: el modulo no tiene indice de texto completo, y montarlo
  /// costaria mas que la busqueda. Medido el 5 de octubre de 2026 sobre los ficheros
  /// reales, con la consulta tal cual esta:
  ///
  ///     KJV2006  "God"          4.140 coincidencias,   6,0 ms
  ///     CLARKE   "propitiation"    15 coincidencias,  22,7 ms
  ///
  /// 23 milisegundos con 19.742 notas y 57 MiB. No hace falta indice.
  ///
  /// Y **EL EXTRACTO VIENE EN LA MISMA CONSULTA**, y no se trae el versiculo entero ni se
  /// pregunta despues. Con un limite de 200, preguntando despues serian 200 consultas
  /// mas; y trayendo el versiculo entero serian 200 lineas de hasta 405 caracteres para
  /// ensefiar 120.
  ///
  /// Y EL **TOTAL** TAMBIEN EN LA MISMA. Con un `limit`, `total` es lo que distingue "no
  /// hay" de "hay 4.140 y te ensefino 200": sin el, quien busca "God" ve una lista
  /// parecida a la de "propitiation" y no tiene forma de saber que le faltan 3.940.
  BusquedaEnElModulo buscar(String palabra, {int limite = limiteDeResultados}) {
    final limpia = palabra.trim();

    // Y UNA PALABRA DE UNA LETRA NO BUSCA. Medido: "a" sale en 28.407 de los 31.102
    // versiculos del KJV, y son 200 lineas de las que 29.907 no estan. No es una
    // proteccion: es que la respuesta no sirve para nada. Por eso `vacia` lleva la palabra
    // vacia, para que la pantalla pueda decir "busca al menos dos letras" en vez de "no
    // hay resultados".
    if (limpia.length < 2) return BusquedaEnElModulo.vacia;

    // Y EL `%` Y EL `_` DEL PATRON SE ESCAPAN, porque si no, buscar "a_b" devuelve
    // cualquier cosa y quien busca una palabra con guion recibe una lista de miles de
    // resultados sin entender por que. El comodin se quita en vez de escaparse con
    // `ESCAPE`, y se quita porque `%` y `_` **no son palabras**: una palabra de texto no
    // lleva un signo de porcentaje en medio.
    final patron = '%${limpia.replaceAll('%', '').replaceAll('_', '')}%';
    if (patron == '%%') return BusquedaEnElModulo.vacia;

    final total = _sqlite.valor(
          'SELECT count(*) FROM (SELECT DISTINCT book, chapter, verse FROM $_tabla '
          'WHERE text LIKE ?)',
          <Object?>[patron],
        ) as int? ??
        0;

    return BusquedaEnElModulo(
      palabra: limpia,
      total: total,
      resultados: <ResultadoDeBusqueda>[
        for (final f in _sqlite.consultar(
          'SELECT DISTINCT book, chapter, verse FROM $_tabla WHERE text LIKE ? '
          'ORDER BY book, chapter, verse LIMIT ?',
          <Object?>[patron, limite],
        ))
          ResultadoDeBusqueda(
            referencia: Referencia(
              f['book'] as String,
              f['chapter'] as int,
              f['verse'] as int,
            ),
            palabra: limpia,
            extracto: _extracto(f['book'] as String, f['chapter'] as int, f['verse'] as int, limpia),
          ),
      ],
    );
  }

  /// El trozo de texto de alrededor de la coincidencia.
  ///
  /// Y UNA CONSULTA POR RESULTADO, que es lo que hay que decir en voz alta. La primera
  /// version trajo el versiculo entero en la misma consulta del `LIKE` y lo recortó en
  /// Dart; asi son 200 consultas de `instr`/`substr`, y son 200 veces 200 caracteres
  /// leidos, lo que en el CLARKE son 6 MiB. Medido por debajo de los 200 ms, asi que
  /// entra: la alternativa --un `GROUP_CONCAT` con todo dentro-- es mas rapida y hace
  /// que un error de sintaxis en una linea se lleve el resultado entero.
  ///
  /// Y `instr` CON `lower()` EN LOS DOS LADOS, porque `instr` **si distingue mayusculas** y
  /// `LIKE` **no**. Sin el `lower`, buscar "god" en el KJV --que escribe "God" en cada
  /// mayuscula-- encontraria el versiculo y luego el recorte no encontraria la palabra
  /// dentro, y el resultado apareceria con el extracto centrado donde no toca.
  String _extracto(String libro, int capitulo, int versiculo, String palabra) {
    final v = _sqlite.valor(
      'SELECT substr(text, max(1, instr(lower(text), lower(?)) - $contextoDelExtracto), '
      '$largoDelExtracto) FROM $_tabla WHERE book = ? AND chapter = ? AND verse = ?',
      <Object?>[palabra, libro, capitulo, versiculo],
    ) as String?;
    return v ?? '';
  }
}

/// El resultado de abrir un modulo: abierto, o el motivo por el que no.
sealed class ResultadoDeAbrir {
  const ResultadoDeAbrir();
}

class Abierto extends ResultadoDeAbrir {
  const Abierto(this.modulo);
  final ModuloAbierto modulo;
}

class FalloAlAbrir extends ResultadoDeAbrir {
  const FalloAlAbrir(this.motivo);
  final String motivo;
}
