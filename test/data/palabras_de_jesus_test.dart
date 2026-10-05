// Las palabras de Jesus, y por que se llaman asi y no "palabras de Dios".
//
// QUE ESTA MEDIDO Y DONDE. Todo lo de aqui sale del KJV real, el fichero de 22.544.384
// bytes, con el parser de la aplicacion --no con una expresion regular-- porque el
// emparejamiento con el texto es lo que decide si una palabra queda marcada:
//
//     versiculos del KJV                        31.102
//     con columna `raw`                         31.102
//     que reciben anotaciones                   30.350   (97,60 %)
//     con palabras de Jesus                      2.015
//     palabras de Jesus                      41.284   de 835.159   (4,94 %)
//     aperturas `\\wj` en el modulo               2.038
//     versiculos con `\\wj`                       2.028
//
// Y LOS TRES NUMEROS DE `\wj` SON DISTINTOS. Hay 2.038 aperturas en 2.028 versiculos,
// porque Juan 21:15, Juan 21:16 y siete mas abren el marcador dos veces dentro del mismo
// versiculo. Y de esos 2.028, **2.015** reciben anotaciones: los 13 que faltan tienen el
// marcado descuadrado con el texto y se descartan enteros, que es la misma regla que para
// el numero del lexicon.
//
// ============================================================================
// Y EL PUNTO QUE ESTA SECCION EXISTE PARA PODER DECIR SIN DUDAR
// ============================================================================
//
// ANTES ESTA ESCRITO QUE LA PALABRA DE DIOS EN ROJO NO SE PUEDE. Es media verdad, y la
// media verdad fue: se busco una marca de habla divina --`\\divine`, `\\god`-- y no la hay.
//
// Lo que hay es `\\wj`, que en USFM es el marcador de **palabras de Jesus**, el mismo que
// usan las Biblias de letras rojas. Esta ahi, en 2.028 versiculos, y el parser no lo
// miraba.
//
// Y QUE MARCA Y QUE NO, MEDIDO POR LIBRO, que es la comprobacion que de verdad distingue:
//
//     Mateo         641     Hechos         27     2 Corintios     1
//     Lucas         584     Apocalipsis     61
//     Juan          415     1 Corintios     2
//     Marcos        284
//     Genesis         0     Salmos          0     Exodo            0
//
// Y LAS DOS FILAS DE CORINTIOS SON LA PRUEBA DE QUE EL MARCADOR DICE LO QUE DICE. En
// 1 Corintios 11:24 y 2 Corintios 12:9 son palabras de Cristo **citadas por Pablo**: si
// `\\wj` significara "dialogo", tambien las traeria; si significara "habla divina", no,
// porque Pablo no es Cristo. Y el Antiguo Testamento entero da **cero**, que es lo
// correcto y no un fallo del parser: alli el que habla es el Dios del Antiguo Testamento
// y este catalogo no lo marca.
//
// ASI QUE:
//
//   - SE PINTA EN ROJO **LO QUE DIJO JESUS**, y se dice con esas palabras.
//   - **LAS PALABRAS DE DIOS** EN GENERAL --el Dios del Antiguo Testamento hablando a
//     Moises, los profetas-- **NO ESTAN MARCADAS** en ningun sitio, y no hay de donde
//     sacarlas. Pintar de rojo un texto cuyo hablante no se sabe seria inventarse el dato.

import 'package:ab/data/services/analizador_usfm.dart';
import 'package:ab/data/services/sqlite_service.dart';
import 'package:ab/domain/models/token_de_texto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  late Sqlite sqlite;

  setUpAll(() => sqlite = Sqlite.abrir(rutaBibliaReal));
  tearDownAll(() => sqlite.cerrar());

  group('1. el marcador', () {
    test('el texto sale de `text` y no se toca', () {
      // Y LA PRIMERA COMPROBACION ES ESTA, Y NO ES LA DE LOS COLORES. Antes de leer
      // cuanto rojo hay, hay que comprobar que el texto entero sigue siendo el del
      // modulo: un lector que altera el texto que va a leer es un lector que no se puede
      // citar.
      final f = sqlite.consultar('SELECT text, raw FROM verses').first;
      final t = anotarTexto(f['text'] as String, f['raw'] as String?);

      expect(t.texto, f['text']);
    });

    test('Juan 3:16 entero es de Jesus: 25 de 25', () {
      // Y ESTE ES EL VERSICULO QUE TODO EL MUNDO CONOCE, asi que es el que hay que
      // comprobar. El marcador abre al principio y cierra al final.
      final t = _de(sqlite, 'John', 3, 16);

      expect(t.tienePalabrasDeJesus, isTrue);
      expect(t.palabrasDeJesus, 25);
      expect(t.palabras.length, 25);
    });

    test('y los cuatro siguientes no tienen ni una, porque es el narrador', () {
      // Y ESTA ES LA MITAD QUE HACE QUE EL DATO VALGA. Si `\\wj` marcara el capitulo, o
      // no marcara nada, estos cuatro habrian salido al reves: Juan 3:28 es la voz de
      // Juan el Bautista, 3:29 y 3:36 son del narrador, y 3:30 es de su padre.
      for (final v in <int>[28, 29, 30, 36]) {
        final t = _de(sqlite, 'John', 3, v);
        expect(t.tienePalabrasDeJesus, isFalse, reason: 'Juan 3:$v');
        expect(t.palabrasDeJesus, 0, reason: 'Juan 3:$v');
      }
    });

    test('Juan 3:11 es suyo entero, y el total del KJV son 2.015 versiculos', () {
      expect(_de(sqlite, 'John', 3, 11).palabrasDeJesus, 24);

      final conJesus = sqlite
          .consultar('SELECT text, raw FROM verses')
          .where((f) => _anotado(f).tienePalabrasDeJesus)
          .length;

      expect(conJesus, 2015);
    });

    test('41.284 palabras, el 4,94 % del texto', () {
      // Y EL PORCENTAJE ES LA CIFRA QUE HACE FALTA DECIR AL USUARIO. Con un 4,94 % el
      // rojo no es una pantalla en color: es una linea de cada veinte. Con el 40 % del
      // Antiguo Testamento --si estuviera marcado-- habria que pensarselo mucho mas.
      var palabras = 0, deJesus = 0;
      for (final f in sqlite.consultar('SELECT text, raw FROM verses')) {
        palabras += (f['text'] as String).split(' ').length;
        deJesus += _anotado(f).palabrasDeJesus;
      }

      expect(palabras, 835159);
      expect(deJesus, 41284);
      expect(deJesus / palabras, closeTo(0.0494, 0.0001));
    });
  });

  group('2. por libro, que es donde se ve que el marcador es el que es', () {
    test('los evangelios y las citas de Cristo', () {
      const medido = <String, int>{
        'Matthew': 641,
        'Luke': 584,
        'John': 415,
        'Mark': 284,
        'Revelation': 61,
        'Acts': 27,
        '1Corinthians': 2,
        '2Corinthians': 1,
      };

      for (final entrada in medido.entries) {
        expect(
          _deLibro(sqlite, entrada.key),
          entrada.value,
          reason: entrada.key,
        );
      }
    });

    test('el Antiguo Testamento entero da CERO, y no es un fallo del parser', () {
      // Y AQUI ESTA LA DISTINCION QUE NO SE PUEDE OCULTAR. Si estos libros dieran cero
      // porque el parser no entiende su marcado, seria un fallo mio. Dan cero porque el
      // modulo **no marca** el hablar de Dios, y eso no se puede arreglar aqui: no hay
      // dato. Y por eso lo que se pinta en rojo se llama palabras de Jesus y no palabras
      // de Dios.
      for (final libro in <String>[
        'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
        'Psalms', 'Proverbs', 'Ecclesiastes', 'Isaiah', 'Jeremiah', 'Ezekiel',
        'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Zechariah',
        'Malachi',
      ]) {
        expect(_deLibro(sqlite, libro), 0, reason: libro);
      }
    });

    test('ni una palabra suelta del Antiguo Testamento sale marcada', () {
      // Y NO SOLO "cero versiculos", sino **cero palabras**. Un contador de versiculos a
      // cero podria esconder un versiculo con la marca puesta y el emparejamiento roto,
      // que daria cero versiculos marcados y una palabra de mas en la pantalla. Con el
      // total de palabras no hay sitio donde esconderse.
      var palabras = 0;
      for (final f in sqlite.consultar(
        "SELECT text, raw FROM verses WHERE book IN ('Genesis','Psalms','Isaiah')")) {
        palabras += _anotado(f).palabrasDeJesus;
      }

      expect(palabras, 0);
    });
  });

  group('3. lo que el parser puede equivocarse', () {
    test('la marca se cierra, y despues no queda puesta', () {
      // Y EL FALLO DE LA BANDERA. Una bandera que se ponia al abrir `\\wj` y no se
      // apagaba al cerrar marcaba como de Jesus **todo lo que venia despues**: en Juan
      // 3:11 las 24 palabras de un versiculo de 24 son de Jesus, y en 3:28, que es del
      // narrador, la bandera seguia puesta y las 20 salian rojas.
      //
      // Y POR ESO LA PREGUNTA NO ES "tiene marca", sino "tiene marca Y NO LA TIENE LA
      // SIGUIENTE". Un versiculo con `\\wj` que se cierra bien es el que tiene palabras
      // rojas y ademas no se desbordan.
      final conMarca = sqlite.consultar(
        "SELECT text, raw FROM verses WHERE raw LIKE ?",
        <Object?>['%\\wj %'],
      );
      var conPalabras = 0;
      for (final f in conMarca) {
        if (_anotado(f).tienePalabrasDeJesus) conPalabras++;
      }

      // Y LOS TRES NUMEROS SON DISTINTOS Y NO SE CONFUNDEN:
      //
      //     2.038 aperturas de `\\wj`      diez versiculos las abren dos veces
      //     2.028 versiculos con `\\wj`      Juan 21:15 y 21:16, Hechos 1:4, y siete mas
      //     2.015 con palabras de Jesus     los 13 que faltan no cuadran con el texto
      //
      // La cuenta de aperturas y la de versiculos difieren en diez porque hay versiculos
      // con dos tramos de palabras de Jesus, y eso no es un fallo: es que el marcador
      // abre y cierra dentro del mismo versiculo.
      expect(conMarca.length, 2028);
      expect(conPalabras, 2015);
    });

    test('nunca mas palabras de Jesus que palabras', () {
      // Y LA COMPROBACION DE LA BANDERA, por el otro lado. Si el parser se desfasara y
      // marcara de mas, el total podria pasar de las palabras del versiculo, y eso es un
      // indice fuera de rango: una exception en pantalla de lectura.
      for (final f in sqlite.consultar('SELECT text, raw FROM verses')) {
        final t = _anotado(f);
        expect(
          t.palabrasDeJesus,
          lessThanOrEqualTo((f['text'] as String).split(' ').length),
          reason: 'con palabras: ${f["text"]}',
        );
      }
    });

    test('el comentario no tiene ni una palabra de Jesus', () {
      // Y AQUI HAY UN DATO QUE NO ESPERABA: el CLARKE **SI** tiene columna `raw`, y
      // `PRAGMA table_info` la ensena. Lo que tiene es que su `raw` es **igual** a su
      // `text` en 19.738 de 19.742 notas --el aparato USFM se guardo en la misma columna
      // sin marcas-- y ni una sola nota lleva `\\wj`.
      //
      // El caso de `raw == null` tambien tiene que entrar, porque es el que se da cuando
      // un modulo no trae marcado: una lista vacia, no una exception.
      final c = Sqlite.abrir(rutaComentarioReal);
      addTearDown(c.cerrar);

      expect(
        c.consultar('SELECT count(*) AS n FROM commentary WHERE raw = text')
            .first['n'],
        19738,
      );
      expect(
        c.consultar('SELECT count(*) AS n FROM commentary WHERE raw LIKE ?',
            <Object?>['%\\wj %']).first['n'],
        0,
      );

      var conPalabras = 0, notas = 0;
      for (final f in c.consultar('SELECT text, raw FROM commentary')) {
        notas++;
        if (anotarTexto(f['text'] as String, f['raw'] as String?).tienePalabrasDeJesus) {
          conPalabras++;
        }
      }

      expect(notas, 19742);
      expect(conPalabras, 0);
      expect(anotarTexto('Un texto cualquiera', null).tienePalabrasDeJesus, isFalse);
    });
  });
}

TextoAnotado _anotado(Map<String, Object?> fila) =>
    anotarTexto(fila['text'] as String, fila['raw'] as String?);

TextoAnotado _de(Sqlite sqlite, String libro, int capitulo, int versiculo) =>
    _anotado(sqlite.consultar(
      'SELECT text, raw FROM verses WHERE book = ? AND chapter = ? AND verse = ?',
      <Object?>[libro, capitulo, versiculo],
    ).single);

int _deLibro(Sqlite sqlite, String libro) {
  var n = 0;
  for (final f in sqlite.consultar(
      'SELECT text, raw FROM verses WHERE book = ?', <Object?>[libro])) {
    if (_anotado(f).tienePalabrasDeJesus) n++;
  }
  return n;
}
