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
import 'package:ab/domain/models/pasaje.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/domain/models/versiculo.dart';

/// Un modulo abierto y listo para leer.
class ModuloAbierto {
  ModuloAbierto._(this._sqlite, this.id, this.ruta);

  final Sqlite _sqlite;

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

    return Abierto(ModuloAbierto._(sqlite, id, ruta));
  }

  void cerrar() => _sqlite.cerrar();

  // --- los terminos ---

  /// Un campo de la tabla `info`.
  String? info(String clave) => _sqlite.info(clave);

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
  List<String> libros() =>
      _sqlite.consultar('SELECT DISTINCT book FROM verses ORDER BY book')
          .map((f) => f['book'] as String)
          .toList();

  /// Cuantos versiculos tiene un libro.
  int? versiculosDe(String libro) =>
      _sqlite.valor('SELECT count(*) FROM verses WHERE book = ?', [libro]) as int?;

  /// Los capitulos que tiene un libro, en orden.
  ///
  /// ESTA ES LA CONSULTA QUE SUSTITUYE A UNA TABLA DE NUMEROS. Y por eso devuelve
  /// una lista y no un total: un total no sabe si el libro tiene un hueco, y un hueco
  /// en una traduccion es informacion real. La RVR, por ejemplo, tiene libros con un
  /// capitulo vacio, y ofrecer "capitulo 51" en uno de ellos lleva a una pantalla en
  /// blanco.
  List<int> capitulosDe(String libro) => _sqlite
      .consultar(
        'SELECT DISTINCT chapter FROM verses WHERE book = ? ORDER BY chapter',
        [libro],
      )
      .map((f) => f['chapter'] as int)
      .toList();

  /// El numero de capitulos, o null si el libro no esta.
  ///
  /// Null y no 0: "no lo tiene" y "tiene ninguno" son cosas distintas, y un 0
  /// llevaria a pintar un libro con cero capitulos, que es un bug de los que se ven.
  int? numeroDeCapitulos(String libro) {
    final lista = capitulosDe(libro);
    return lista.isEmpty ? null : lista.length;
  }

  // --- los versiculos ---

  /// Los versiculos de un capitulo, o de un solo versiculo.
  ///
  /// Con [Referencia.versiculo] nulo son todos los del capitulo. Con versiculo, uno
  /// solo. Y si no existe ninguno, un pasaje vacio --no null--, porque la pantalla
  /// tiene que poder pintar "aqui no hay nada" y eso es un resultado, no un fallo.
  ///
  /// El texto sale del campo `text`, que ya viene limpio. El campo `raw` con marcas
  /// USFM --`\+w Dios|strong="G2316"`-- se consume **en otro sitio**, cuando se pinte
  /// la palabra de Dios en rojo. Aqui el texto se pasa tal cual: un lector que altera
  /// el texto que va a leer es un lector que no se puede citar.
  Pasaje leer(Referencia referencia) {
    final filas = referencia.versiculo == null
        ? _sqlite.consultar(
            'SELECT verse, text FROM verses WHERE book = ? AND chapter = ? ORDER BY verse',
            [referencia.libro, referencia.capitulo],
          )
        : _sqlite.consultar(
            'SELECT verse, text FROM verses WHERE book = ? AND chapter = ? AND verse = ?',
            [referencia.libro, referencia.capitulo, referencia.versiculo],
          );

    return Pasaje(
      referencia: referencia,
      titulo: referencia.texto,
      versiculos: <Versiculo>[
        for (final f in filas) Versiculo(f['verse'] as int, f['text'] as String),
      ],
    );
  }

  /// Si ese pasaje existe en este modulo.
  bool existe(Referencia referencia) {
    final n = _sqlite.valor(
      'SELECT count(*) FROM verses WHERE book = ? AND chapter = ?'
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
  List<int> numerosDeVersiculos(Referencia referencia) => _sqlite
      .consultar(
        'SELECT verse FROM verses WHERE book = ? AND chapter = ? ORDER BY verse',
        [referencia.libro, referencia.capitulo],
      )
      .map((f) => f['verse'] as int)
      .toList();

  /// Cuantos versiculos tiene un modulo en total.
  int totalDeVersiculos() => _sqlite.valor('SELECT count(*) FROM verses') as int? ?? 0;

  /// Buscar una palabra en todo el modulo.
  ///
  /// `LIKE` y no `MATCH`: el modulo no tiene indice de texto completo, y montarlo
  /// costaria mas que el busqueda. Con miles de versiculos es lento, y esa lentitud
  /// se nota en la pantalla: por eso la busqueda va en su propio change, con su
  /// propia medida, y no aqui a medias.
  ///
  /// El `%` y el `_` del patron se escapan, porque si no, buscar "a_b" devuelve
  /// cualquier cosa y quien busca una palabra con guion recibe una lista de miles de
  /// resultados sin entender por que.
  List<Referencia> buscar(String palabra, {int limite = 200}) {
    final limpia = palabra.trim();
    if (limpia.length < 2) return const <Referencia>[];
    final patron = '%${limpia.replaceAll('%', '').replaceAll('_', '')}%';

    return <Referencia>[
      for (final f in _sqlite.consultar(
        'SELECT book, chapter, verse FROM verses WHERE text LIKE ? LIMIT ?',
        [patron, limite],
      ))
        Referencia(f['book'] as String, f['chapter'] as int, f['verse'] as int),
    ];
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
