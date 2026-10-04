library;

// Reconocer un `.amod` que llega de fuera.
//
// POR QUE EXISTE. La gente tiene ficheros de Biblia en sitios donde esta app no
// llega: una memoria USB en una iglesia, un pendrive que se pasaron de uno a otro,
// una copia que alguien le mando por correo. Y el proyecto tiene una regla que se
// cumple entera: **lo que no esta en el catalogo no se abre**. No porque el
// repositorio hermano no lo haya visto, sino porque nadie ha podido comprobar de
// donde sale.
//
// Y aqui hay que tener cuidado con la tentacion facil, que seria abrirlo y ya
// esta. Un `.amod` es un SQLite, y un SQLite con un byte cambiado en un texto
// abre **perfecto** y da versiculos casi correctos. Nadie se enteraria. Por eso
// lo que se hace es:
///
///  1. Calcular su sha256.
///  2. Buscar ese hash en el manifiesto.
///  3. Solo si esta ahi, abrirlo. Y si esta, es porque el gate del catalogo lo
///     vio, lo valido y lo publico.
///
/// Y si no esta, se dice **cual** es su sha256. Porque ahi hay dos finales
// posibles y quien lo ha traido necesita distinguirlos: o el fichero es de otro
// sitio y hay que pedirlo ahi, o es una version distinta de algo que si esta en el
// catalogo. Sin el hash no se puede saber cual de los dos, y sin poder
// distinguirlo la unica respuesta posible es "no", que es justo lo que hace que la
// gente deje de intentarlo.

import 'dart:convert';

import 'package:ab/data/services/hash_service.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';

/// Un fichero que alguien ha elegido, con su hash ya calculado.
class ArchivoLocal {
  ArchivoLocal({required this.nombre, required this.bytes})
    : sha256 = sha256DeBytes(bytes);

  /// Como lo llama la persona. Se ensena, y no es el nombre del modulo: son cosas
  /// distintas y aqui solo se sabe el nombre del fichero.
  final String nombre;

  final List<int> bytes;

  /// Calculado aqui, en el momento de leerlo. **No** se lee de ningun sitio: si
  /// el manifiesto lo dijera, un manifiesto alterado haria que un fichero
  /// cualquiera pasara por bueno.
  final String sha256;

  int get tamanoBytes => bytes.length;
}

/// Lo que ha resultado de mirar un fichero.
sealed class Reconocimiento {
  const Reconocimiento();
}

/// Es un modulo del catalogo, con su hash intacto. Se puede abrir.
class EsDelCatalogo extends Reconocimiento {
  const EsDelCatalogo(this.modulo, this.archivo);

  /// El modulo del manifiesto que le corresponde.
  final Modulo modulo;

  final ArchivoLocal archivo;
}

/// Es un modulo del catalogo, pero de una **version distinta**: su hash es el de
/// otro modulo que ya no esta, o es anterior al que anuncia el manifiesto.
///
/// Se distingue de [EsDelCatalogo] a proposito. Si el hash no esta en el
/// manifiesto actual, puede que el fichero sea perfectly bueno y lo que este
/// viejo sea el catalogo. Decir "no se reconoce" en ese caso seria mentir.
class EsDeVersionDistinta extends Reconocimiento {
  const EsDeVersionDistinta({required this.archivo, required this.hashEnCatalogo});

  final ArchivoLocal archivo;

  /// El hash que el manifiesto anuncia para ese identificador, si lo anuncia.
  /// Null cuando el hash del fichero no corresponde a ningun modulo del
  /// catalogo, actual ni anterior.
  final String? hashEnCatalogo;

  /// Lo que se le dice a la persona. Nunca "error".
  String get texto => hashEnCatalogo == null
      ? 'Este fichero tiene un contenido que el catalogo no reconoce.\n'
          'Su sha256 es:\n$sha256DelFichero'
      : 'Este fichero es una version distinta de la que anuncia el catalogo.\n'
          'Su sha256 es:\n$sha256DelFichero\n'
          'La que se anuncia es:\n$hashEnCatalogo';

  String get sha256DelFichero => archivo.sha256;
}

/// No es un modulo del catalogo. No se abre, y se dice por que.
///
/// Dos motivos distintos, porque las dos respuestas son distintas: uno se
/// arregla seeking en el catalogo y el otro no se arregla.
class NoEsDelCatalogo extends Reconocimiento {
  const NoEsDelCatalogo(this.archivo, {required this.motivo});

  final ArchivoLocal archivo;

  /// Que se ensena tal cual.
  final String motivo;

  String get texto => '$motivo\n\nSu sha256 es:\n${archivo.sha256}';
}

/// Un fichero que ni siquiera es un SQLite. Se comprueba antes de nada, porque
/// abrir un fichero que no es una base de datos produce un error que no dice
/// nada de por que.
class NoEsUnaBaseDeDatos extends Reconocimiento {
  const NoEsUnaBaseDeDatos(this.archivo, {required this.motivo});

  final ArchivoLocal archivo;
  final String motivo;

  String get texto => '$motivo\n\n'
      'Un modulo empieza con la palabra "SQLite format 3".\n'
      'Su sha256 es:\n${archivo.sha256}';
}

/// Mira ficheros locales contra el manifiesto.
///
/// Sin estado y sin dependencias: se le pasa el manifiesto y devuelve una
/// respuesta. Que sea una funcion pura es lo que permite comprobarla sin montar
/// una app ni tocar disco.
class ReconocerModuloLocal {
  const ReconocerModuloLocal();

  /// Los 16 bytes con los que empieza todo fichero SQLite. Esta es la unica
  /// comprobacion de "esto es una base de datos" que se puede hacer sin abrirla,
  /// y abrirla para comprobarlo es justo lo que no se quiere hacer con un
  /// fichero que puede ser cualquier cosa.
  static final List<int> cabeceraSqlite = 'SQLite format 3'.codeUnits;

  /// Que ha resultado de mirar [archivo] en [manifiesto].
  ///
  /// El orden de las comprobaciones es el que importa. Primero que sea una base
  /// de datos, luego el hash. Al reves, un fichero que no es un modulo se
  /// reportaria como "no esta en el catalogo", que es un diagnostico equivocado:
  /// haria que la persona buscara en el catalogo un fichero que no es un modulo
  /// de ningun tipo.
  Reconocimiento reconocer(ArchivoLocal archivo, Manifiesto manifiesto) {
    if (archivo.bytes.length < cabeceraSqlite.length) {
      return NoEsUnaBaseDeDatos(archivo, motivo: 'El fichero esta vacio o es demasiado pequeno.');
    }
    for (var i = 0; i < cabeceraSqlite.length; i++) {
      if (archivo.bytes[i] != cabeceraSqlite[i]) {
        return NoEsUnaBaseDeDatos(
          archivo,
          motivo: 'El fichero no empieza como un modulo.',
        );
      }
    }

    // El camino feliz: el hash esta en el manifiesto.
    for (final m in manifiesto.modulos) {
      if (mismoHash(m.sha256, archivo.sha256)) return EsDelCatalogo(m, archivo);
    }

    // No esta completo, pero puede ser una version anterior de algo que si esta.
    // Se busca por el identificador que declara el **modulo**, y no por el nombre
    // del fichero: el nombre lo pone quien copia y no significa nada.
    final idDeclarado = _idDeclarado(archivo);
    if (idDeclarado != null) {
      final enCatalogo = manifiesto.porId(idDeclarado);
      if (enCatalogo != null) {
        return EsDeVersionDistinta(archivo: archivo, hashEnCatalogo: enCatalogo.sha256);
      }
    }

    return NoEsDelCatalogo(
      archivo,
      motivo: 'Su contenido no esta en el catalogo, asi que no se puede comprobar '
          'de donde viene.',
    );
  }

  /// El `id` que el propio modulo declara en su tabla `info`.
  ///
  /// SE BUSCA EN LOS BYTES SIN ABRIR LA BASE DE DATOS, y esa es la parte que
  /// importa. El orden es: primero el hash, y solo si el hash **no** esta en el
  /// manifiesto se llega aqui. Es decir, esta funcion solo se consulta cuando el
  /// fichero ya ha resultado desconocido --justo cuando no se debe abrir--, asi
  /// que abrirlo para "solo leer el nombre" no llega a plantearse. Ese argumento
  /// es el que precede a todos los fallos de seguridad, y aqui es que no se
  /// necesita.
  ///
  /// Y ADEMAS NO HACE FALTA. El identificador esta en el fichero como texto plano
  /// dentro de la tabla `info`, que vive en las primeras paginas.
  ///
  /// COMO SE BUSCA, Y QUE NO ES. Es una heuristica sobre el formato en disco de
  /// SQLite, **no** un analizador: se busca la palabra `id` seguida de un
  /// identificador. Medido sobre los dos modulos reales, funciona:
  ///
  ///     KJV2006_bible.amod      -> KJV2006
  ///     CLARKE_commentary.amod  -> CLARKE
  ///
  /// Y se declara que es una heuristica porque puede fallar. Si falla, el
  /// resultado es que el modulo no se reconoce, que es un fallo que se ve y que no
  /// rompe nada. Si en cambio diera un id equivocado, lo unico que pasaria es que
  /// se compararia contra el modulo equivocado del manifiesto y no coincidirian
  /// los hashes, que es el mismo final. Ninguno de los dos finales abre nada.
  ///
  /// Solo se mira el principio. Leer 22 MiB para buscar una cadena seria una
  /// manera elegante de agotar la memoria, y la tabla `info` esta en la pagina 1:
  /// en el KJV real esta en el byte 8166.
  String? _idDeclarado(ArchivoLocal archivo) {
    const ventana = 1 << 16;
    final trozo = archivo.bytes.length < ventana ? archivo.bytes : archivo.bytes.sublist(0, ventana);
    // `allowMalformed` porque el fichero es binario: hay paginas de SQLite con
    // bytes que no son texto valido, y que eso no se pueda decodificar no es motivo
    // para decir que el modulo no se reconoce.
    final texto = utf8.decode(trozo, allowMalformed: true);
    // El `(?<![A-Za-z0-9_])` de delante evita que case con el final de otra
    // palabra, como en `versiculo` o en `defect`.
    final m = RegExp(r'(?<![A-Za-z0-9_])id([A-Za-z0-9_]{2,64})').firstMatch(texto);
    return m?.group(1);
  }
}
