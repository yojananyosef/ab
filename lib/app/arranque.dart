// El arranque: que se ve en pantalla nada mas abrir la app.
//
// POR QUE ESTO ES UN FICHERO Y NO TRES LINEAS EN `main.dart`. Porque tiene una
// **garantia** que hay que poder comprobar: el catalogo se ensena **aunque el
// almacenamiento no conteste**. Y una garantia que solo se puede comprobar leyendo
// el codigo no es una garantia.
//
// EL FALLO QUE LA PROVOCO. Medido en Chrome 154 headless el 4 de octubre de 2026:
//
//     fetch https://yojananyosef.github.io/aa/latest.json  ->  HTTP 200, tag v0.1.1
//     indexedDB.open('ab', 1)                             ->  nunca resuelve
//
// Ni `onsuccess`, ni `onerror`, ni `onblocked`. Nada. Se queda esperando para
// siempre.
//
// Y el efecto en la app era el peor posible: la biblioteca se quedaba **vacia** con
// el texto "El catalogo no declara ningun modulo todavia", que es mentira. El
// catalogo declara dos. Lo que no contestaba era el almacenamiento del navegador, y
// el aviso ni siquiera salia, porque `aplicarResultado` estaba despues del `await`
// que no volvia.
//
// Es el modo de fallo de MyBible en otro traje: no un error, sino una pantalla
// tranquila que dice algo falso. Y por eso el arreglo no es "poner un reintento":
// es **no depender** de una cosa para ensenar otra.
//
// LAS TRES REGLAS DEL ORDEN, Y CADA UNA CORRIGE UN FALLO CONCRETO:
//
//  1. **El catalogo primero.** Es lo unico que se necesita para ensenar la lista, y
//     no tiene nada que ver con el almacenamiento. Leyendolo despues, un
//     almacenamiento lento o muerto deja la biblioteca en blanco.
//
//  2. **El almacenamiento despues, y con plazo.** Cada lectura tiene un plazo. Sin
//     el, `await` esperando un evento que no llega cuelga la pantalla entera.
//
//  3. **Lo que falla se dice, y se dice verdad.** Un aviso por cada cosa que no se
//     pudo saber, y nunca la conclusion de "no hay nada" a partir de un fallo.

import 'dart:async';

import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/data/services/almacenamiento_de_modulos.dart';
import 'package:ab/ui/features/biblioteca/view_models/biblioteca_view_model.dart';

/// El resultado del arranque, para probarlo sin montar una pantalla.
class ResultadoDelArranque {
  const ResultadoDelArranque({
    required this.estadoDelCatalogo,
    required this.hayIdsLocales,
    required this.hayHashesLocales,
    this.avisos = const <String>[],
  });

  final EstadoLectura estadoDelCatalogo;

  /// Si se llego a saber que modulos hay en el dispositivo.
  final bool hayIdsLocales;

  /// Si se llego a saber sus hashes. Sin esto no se puede distinguir "descargado" de
  /// "hay version nueva", y solo eso.
  final bool hayHashesLocales;

  final List<String> avisos;

  /// Se ha pintado **algo** sobre el catalogo: o su lista, o por que no se pudo leer.
  ///
  /// Esta es la garantia, y es la que hay que comprobar: si es false, la pantalla
  /// esta enseñando que el catalogo esta vacio sin haberlo leido, que es mentira.
  bool get sabeLoQuePasa => estadoDelCatalogo != EstadoLectura.sinConexion;
}

/// Que plazo se le da al almacenamiento.
///
/// CORTO Y DELIBERADO. Cinco segundos es mucho para una base de datos local del
/// navegador: si en cinco segundos no ha contestado, no va a contestar. Y el coste de
/// esperar mas es que la gente ve una pantalla vacia durante mas tiempo, y a los
/// cinco ya ha decidido que la app no funciona.
///
/// Y no es "reintentar": es dejar de esperar. Reintentar una `open` que no va a
/// terminar deja el `Future` viejo colgado para siempre, que es justo el fallo que
/// esta commenting evita con el `_Future` guardado.
const Duration plazoDelAlmacenamiento = Duration(seconds: 5);

/// Arranca la biblioteca.
///
/// Sin estado y sin excepciones: devuelve un [ResultadoDelArranque] con lo que haya
/// podido averiguar, y el resto son avisos. Que no lance es lo que permite que la
/// app **siempre** pinta algo.
Future<ResultadoDelArranque> arrancarBiblioteca({
  /// Como se lee el catalogo. Una **funcion**, y no el repositorio entero.
  ///
  /// Es lo unico que hace falta aqui, y poner el repositorio obligaria a las
  /// pruebas a implementar su superficie completa --cinco miembros, tres de ellos
  /// propiedades-- para ejercitar una sola cosa. Con una funcion, el doble son tres
  /// lineas y lo que se prueba es el arranque, no el repositorio.
  required Future<ResultadoCatalogo> Function() leerCatalogo,
  required AlmacenamientoDeModulos almacenamiento,
  required BibliotecaViewModel vista,
  /// Avisos que ya se saben antes de empezar, por ejemplo que el motor de lectura no
  /// se pudo preparar. Van **primero**: si el motor no arranco, es lo mas importante
  /// que se puede decir, y no debe quedar el quinto en la lista.
  List<String> avisosPrevios = const <String>[],
  /// El plazo del almacenamiento. Se puede acortar en las pruebas para no esperar
  /// cinco segundos a cada una.
  Duration plazo = plazoDelAlmacenamiento,
}) async {
  final avisos = <String>[];

  // --- 1. El catalogo. Primero, y solo esto. ---
  vista.marcarCargando(true);

  ResultadoCatalogo resultado;
  try {
    resultado = await leerCatalogo();
  } catch (e) {
    // Que `leer()` no lance es un contrato del repositorio, pero un `catch` aqui
    // cuesta tres lineas y evita que un fallo suyo deje la app sin pintar nada.
    avisos.add('No se ha podido leer el catalogo: $e');
    vista.anadirAviso(avisos.last);
    vista.marcarCargando(false);
    return ResultadoDelArranque(
      estadoDelCatalogo: EstadoLectura.sinConexion,
      hayIdsLocales: false,
      hayHashesLocales: false,
      avisos: avisos,
    );
  }

  // Se aplica **ya**, antes de tocar el almacenamiento. A partir de aqui la pantalla
  // tiene la lista aunque todo lo demas falle.
  //
  // Y los avisos previos van **despues**, no antes. `aplicarResultado` **reemplaza**
  // la lista de avisos por los del repositorio, y poniendo los previos antes
  // desaparecerian: se perdia el aviso de "el motor no ha arrancado", que es el mas
  // importante de todos. Se comprobo mirando la pantalla, no el codigo.
  vista.aplicarResultado(resultado);
  for (final a in avisosPrevios) {
    avisos.insert(0, a);
    vista.anadirAviso(a);
  }

  // --- 2. El almacenamiento. Con plazo, y sin que su fallo tape lo anterior. ---
  var hayIds = false;
  var hayHashes = false;

  try {
    final ids = await conPlazo(
      almacenamiento.ids().then((v) => v.toSet()),
      plazo: plazo,
      mensaje: 'la lista de lo descargado',
    );
    vista.actualizarIdsLocales(ids);
    hayIds = true;
  } on TimeoutException {
    // ESTE ES EL AVISO QUE FALtaba. Sin el, la app se quedaba muda: la biblioteca
    // se veia vacia sin decir por que, y el unico texto era "el catalogo no declara
    // ningun modulo", que era mentira.
    avisos.add(
      'El navegador no ha contestado al almacenamiento, asi que no se puede saber '
      'que modulos tienes ya. Se puede leer lo que se baje ahora.',
    );
    vista.anadirAviso(avisos.last);
  } catch (e) {
    avisos.add(
      'No se ha podido leer que modulos tienes ya: $e. '
      'Se puede leer lo que se baje ahora.',
    );
    vista.anadirAviso(avisos.last);
  }

  // Los ids que hay de verdad, para comprobar despues que los hashes los cubren.
  final idsQueHay = <String>{...vista.idsLocales};

  // Y los hashes **solo si lo anterior salio**. Sin saber que modulos hay, saber de
  // que version son es informacion que no se puede usar: el indice de hashes es una
  // lista con las mismas claves que el de ids.
  //
  // Y no es solo ruido que se evita. En la practica los dos fallan **juntos**, porque
  // van al mismo almacen: si el navegador no contesto a `ids`, no va a contestar a
  // `idsConHash`. Preguntar dos veces es pedir el mismo fallo dos veces y ensenar dos
  // avisos donde bastaba uno.
  if (hayIds) {
    try {
      final hashes = await conPlazo(
        almacenamiento.idsConHash(),
        plazo: plazo,
        mensaje: 'las versiones de lo descargado',
      );
      vista.actualizarIdsLocales(idsQueHay, hashes: hashes);

      // "Tener los hashes" no es que la llamada haya funcionado: es que **cubren a
      // los modulos que hay**. Un indice vacio con un modulo descargado quiere decir
      // que el indice se perdio, no que no haya nada que mirar. Y esa es una
      // situacion real: el indice se escribe al guardar, y un modulo escrito por
      // una version anterior no lo tiene.
      final sinCubrir = idsQueHay.where((i) => !hashes.containsKey(i)).toList();
      hayHashes = sinCubrir.isEmpty;
      final cuantos = sinCubrir.length;
      if (!hayHashes) {
        avisos.add(
          'Hay $cuantos modulos descargados cuya version no se ha podido '
          'comprobar. Se ven como descargados.',
        );
        vista.anadirAviso(avisos.last);
      }
    } on TimeoutException {
      // Sin hashes no se puede distinguir "descargado" de "hay version nueva". No es
      // grave --se ven como descargados-- pero se dice, porque quien tenga un modulo
      // atrasado merece saberlo.
      avisos.add(
        'No se ha podido comprobar que version tienen los modulos ya descargados.',
      );
      vista.anadirAviso(avisos.last);
    } catch (e) {
      avisos.add('No se ha podido comprobar la version de lo descargado: $e');
      vista.anadirAviso(avisos.last);
    }
  }

  vista.marcarCargando(false);
  return ResultadoDelArranque(
    estadoDelCatalogo: resultado.estado,
    hayIdsLocales: hayIds,
    hayHashesLocales: hayHashes,
    avisos: avisos,
  );
}

/// Espera [futuro], y si no llega en [plazo] lanza [TimeoutException].
///
/// Se usa `Future.any` y **no** un `.timeout()` a secas, porque `timeout` deja el
/// `Future` original colgado y su excepcion sin manejar: en Dart eso produce un
/// "unhandled exception" en la consola mucho despues, sin relacion con nada que se
/// este viendo. Aqui el futuro perdedor se ignora a proposito, y el comentario dice
/// por que.
Future<T> conPlazo<T>(
  Future<T> futuro, {
  Duration plazo = plazoDelAlmacenamiento,
  required String mensaje,
}) {
  final reloj = Future<T>.delayed(plazo, () {
    throw TimeoutException('no ha contestado: $mensaje', plazo);
  });
  // El perdedor se marca como ya manejado: su excepcion, si la hay, ya no importa
  // porque hemos decidido seguir sin el.
  return Future.any<T>(<Future<T>>[futuro, reloj]).whenComplete(() {
      futuro.then<void>((_) {}, onError: (_, _) {});
  });
}

/// Un arranque que no ha comprobado nada.
///
/// Y SOLO SE USA CUANDO LA PANTALLA NO ESTA MONTADA, que es un caso real: el `State` se
/// puede desmontar mientras el `await` del arranque sigue vivo, y entonces `_cargar` no
/// tiene a quien aplicar el resultado. Antes devolvia un `void` y no hacia falta
/// ningun valor; ahora devuelve el resultado, y ese caso necesita uno.
///
/// Y QUE DIGA `sinConexion` Y NO `hashIncorrecto` O CUALQUIER OTRA COSA: `sinConexion`
/// es el estado que hace que la biblioteca **no afirme** nada sobre el catalogo, que es
/// exactamente lo que corresponde a un arranque que no llego a mirar.
ResultadoDelArranque arranqueVacio() => const ResultadoDelArranque(
      estadoDelCatalogo: EstadoLectura.sinConexion,
      hayIdsLocales: false,
      hayHashesLocales: false,
      avisos: <String>[],
    );
