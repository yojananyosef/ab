// Traer un modulo y comprobarlo.
//
// ESTE ES EL CORAZON DEL PROYECTO, asi que las reglas estan aqui y no en otro
// sitio:
//
// 1. **El hash se comprueba antes de abrir.** Un `.amod` con un byte cambiado
//    abre perfectamente y da versiculos casi correctos. Nadie se enteraria. Por
//    eso, si el hash no cuadra, no se devuelve nada utilizable.
//
// 2. **El hash se calcula mientras llegan los bytes**, no despues. Un modulo son
//    57.536.512 bytes; hashearlo al final obliga a tenerlos dos veces en memoria.
//
// 3. **Reintentos acotados.** Tres y se para. Un progreso que no acaba es peor
//    que un error: la gente no sabe si esta descargando o colgada.
//
// 4. **Cancelable entre trozos y trozo.** Notar que se ha parado es la diferencia
//    entre "tarda" y "esta colgado".
//
// 5. **El progreso son bytes, no porcentaje inventado.** Se mide contra
//    `sizeBytes` del catalogo, que es un numero real.
//
// 6. **Origen no legible y origen caido son cosas distintas.** El primero
//    necesita un espejo o un fichero local; el segundo, reintentar. Tratarlos
//    igual es lo que hace que una app diga "error de red" cuando el problema es
//    que el servidor no manda cabeceras de origen cruzado, que es un problema que
//    reintentar no arregla nunca.

import 'dart:async';
import 'dart:typed_data';

import 'package:ab/data/services/hash_service.dart';
import 'package:ab/data/services/http_service.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/domain/use_cases/resultado_obtencion.dart';

/// Lo que emite la obtencion: o como va, o como ha terminado.
///
/// Un `Stream<Progreso>` con el resultado aparte obliga a llevar dos caminos y a
/// poder quedarse con uno a medias. Aqui hay un solo camino, y el compilador
/// comprueba que termina en un resultado.
sealed class EventoObtencion {
  const EventoObtencion();
}

/// Como va la descarga, en bytes de verdad.
class Progreso extends EventoObtencion {
  const Progreso({required this.recibidos, this.total, this.fase});

  final int recibidos;

  /// Los bytes que dice el manifiesto. Null mientras no se sepa.
  final int? total;

  /// Texto de lo que esta pasando, para la pantalla.
  final String? fase;

  /// De 0 a 1, o null si aun no se sabe el total.
  ///
  /// Null y no 0: un "0 por ciento" sobre una barra vacia dice "no ha empezado",
  /// y aqui si ha empezado.
  double? get fraccion => total == null || total == 0 ? null : recibidos / total!;
}

/// La obtencion ha terminado, de una manera o de otra.
class Terminada extends EventoObtencion {
  const Terminada(this.resultado);
  final ResultadoObtencion resultado;
}

/// Pide cancelar una descarga en curso. Se pasa al empezar y se guarda.
class Cancelar {
  bool _pedido = false;

  bool get pedido => _pedido;

  void pedir() => _pedido = true;
}

/// El motor de la obtencion. Sin estado: se le pasa un modulo y devuelve un
/// resultado.
class ObtenerModulo {
  ObtenerModulo({
    required HttpService http,
    /// Cuantos bytes en cada peticion. 1 MiB es un punto razonable: por debajo
    /// hay demasiadas peticiones y por encima se pierde granularidad del
    /// progreso y de la cancelacion.
    this.tamanoTrozo = 1 << 20,
    this.intentosMaximos = 3,
  }) : _cliente = http;

  final HttpService _cliente;
  final int tamanoTrozo;
  final int intentosMaximos;

  /// Trae el modulo.
  ///
  /// [hashEsperado] es el del manifiesto. [hashEnDispositivo] es el que tiene lo
  /// que ya esta en el dispositivo, para poder devolver el viejo en vez de tirar
  /// lo que la persona ya se habia bajado.
  ///
  /// [usarUrlDeNavegador] decide cual de las dos URLs se usa. **En el navegador
  /// tiene que ser true**, porque `downloadUrl` es la release de GitHub y no
  /// responde con cabeceras de origen cruzado: usarla ahi da `Failed to fetch`
  /// mientras compila y pasa las pruebas. En nativo las dos funcionan.
  Stream<EventoObtencion> obtener(
    Modulo modulo, {
    required String hashEsperado,
    String? hashEnDispositivo,
    required bool usarUrlDeNavegador,
    Cancelar? cancelar,
  }) async* {
    final cancelacion = cancelar ?? Cancelar();
    final url = usarUrlDeNavegador ? modulo.urlNavegador : modulo.urlDescarga;
    var total = modulo.tamanoBytes;

    // Si el servidor dice que no deja leerlo desde el navegador, no tiene sentido
    // reintentar: volvera a pasar lo mismo. Se dice una vez y se para.
    if (usarUrlDeNavegador && await noDejaLeerDesdeNavegador(url)) {
      yield const Progreso(recibidos: 0, fase: 'Comprobando si el servidor deja leerlo');
      yield const Terminada(OrigenNoLegible());
      return;
    }

    // EL ACUMULADOR: un `Uint8List` del tamano exacto, UNA vez. Y aqui hay tres
    // versiones descartadas, todas medidas en la prueba de memoria de este
    // fichero. El motivo de escribirlas es que cualquiera de las tres parece
    // razonable y solo una aguanta.
    //
    // 1. `[...acumulado, ...trozo]`. Copia lo acumulado entero en cada trozo: con
    //    N trozos se copian N bytes de media. Y el operador de dispersion crea una
    //    `List<int>` **encajada**, un puntero por byte en vez de un byte: con un
    //    modulo de 57.536.512 bytes son 57 millones de punteros de golpe.
    //
    // 2. `BytesBuilder(copy: false)`. Guarda bytes de verdad y no copia al
    //    entregar, pero **crece duplicando**, y mientras crece tiene el bufer viejo
    //    y el nuevo a la vez. Medido bajando el KJV real: el pico subiu 43,3 MiB
    //    para un modulo de 21,5 MiB, o sea mas del doble. Con un comentario de
    //    57 MB, mas de 115 MiB de golpe, y en un movil de gama baja eso es lo que
    //    hace que el sistema mate el proceso -- sin dar ningun error, que es lo
    //    peor: aparece como "la app se cierra sola".
    //
    // 3. Esta: un `Uint8List(total)`. El manifiesto dice el tamano, asi que se
    //    reserva una vez la cantidad exacta, se escribe cada trozo en su sitio con
    //    `setRange`, y al final se entrega **sin copiar**. Una sola reserva, cero
    //    crecidas, cero copias.
    final hash = HashEnCurso();
    var recibidos = 0;

    for (var intento = 1; intento <= intentosMaximos; intento++) {
      try {
        final acumulado = Uint8List(total);
        // Cuando el servidor ignora el `Range` y contesta 200 con el fichero
        // entero, lo que manda no cabe en el hueco previsto. En ese caso se usa
        // su bytes tal cual y se abandona el nuestro: no se copia de mas un
        // fichero de 57 MB para luego recortarlo.
        Uint8List? enteroDelServidor;

        hash.reiniciar();
        recibidos = 0;

        // Si el fallo es de los que se arreglan esperando, se marca aqui para
        // salir del bucle de trozos y reintentar el modulo entero. Antes esto no
        // existia y un solo parpadeo de red terminaba la descarga sin reintentar
        // nada, que es lo contrario de lo que dice la regla de "tres intentos".
        var reintentable = false;

        while (recibidos < total) {
          if (cancelacion.pedido) {
            yield Terminada(const Cancelado());
            return;
          }

          final hasta = (recibidos + tamanoTrozo - 1) < total
              ? recibidos + tamanoTrozo - 1
              : total - 1;
          final r = await _cliente.rango(url, recibidos, hasta);

          if (r == null) {
            // No se sabe ni que ha pasado: la peticion no ha llegado a salir, o
            // se ha cortado. Reintentable, porque un fallo de red no se arregla
            // con reintentos pero desde luego no se empeora por probarlos.
            reintentable = true;
            break;
          }
          if (r.codigo == 416) {
            // El servidor dice que el rango no existe: ya se ha bajado todo, o el
            // fichero es mas corto de lo que decia el catalogo. Lo segundo es un
            // fallo del catalogo y reintentar no lo arregla, asi que NO se
            // reintenta. En cuanto, porque repetir tres veces lo mismo solo hace
            // que la espera sea mas larga.
            break;
          }
          if (!r.ok) {
            // Un 5xx es del servidor y a menudo es pasajero: se reintenta. Un 4xx
            // es peticion mala y no se arregla repetirla: un 404 es que el
            // fichero no esta, y un 403 es que no hay permiso. Distinguirlos es lo
            // que evita que un 404 tarde quince segundos en decir que no.
            reintentable = r.codigo >= 500;
            break;
          }
          // Un 200 con el fichero entero tambien vale: hay CDN que ignoran el
          // `Range` y contestan 200 con todo. Se acepta, y el total se ajusta al
          // tamano real recibido, que es la unica forma de que la comprobacion
          // de hash signifique algo.
          if (r.codigo == 200) {
            enteroDelServidor = r.cuerpo;
            hash.reiniciar();
            hash.anadir(r.cuerpo);
            recibidos = r.cuerpo.length;
            total = recibidos;
            break;
          }

          // Si el servidor devuelve MAS bytes de los pedidos, no caben en el hueco
          // reservado. Es un servidor roto o una respuesta envenenada, y en los
          // dos casos lo correcto es no aceptarla: `setRange` reventaria y el
          // error no diria nada del problema real.
          if (recibidos + r.cuerpo.length > total) {
            reintentable = false;
            break;
          }

          acumulado.setRange(recibidos, recibidos + r.cuerpo.length, r.cuerpo);
          hash.anadir(r.cuerpo);
          recibidos += r.cuerpo.length;

          yield Progreso(recibidos: recibidos, total: total);
        }

        if (cancelacion.pedido) {
          yield Terminada(const Cancelado());
          return;
        }

        // Fallo pasajero y quedan intentos: se espera un poco y se vuelve a
        // empezar. Se comprueba **antes** de finalizar el hash, porque
        // `finalizar` no se puede deshacer y el intento siguiente necesita un
        // hash limpio.
        if (reintentable && recibidos < total && intento < intentosMaximos) {
          yield Progreso(
            recibidos: recibidos,
            total: total,
            fase: 'Se ha parado en ${_mib(recibidos)} de ${_mib(total)}. '
                'Reintento $intento de $intentosMaximos.',
          );
          await _cliente.esperar(Duration(milliseconds: 400 * intento));
          continue;
        }

        // ---- Aqui se comprueba el hash. Antes de devolver nada. ----
        final obtenido = hash.finalizar();

        if (reintentable && recibidos < total) {
          // Se han agotado los intentos y lo que se ha bajado no esta completo.
          // `OrigenCaido` y no `DescargaIncompleta`: la diferencia le dice a la
          // persona si tiene sentido reintentar mas tarde o si hay algo que
          // cambiar. Un corte de red es lo primero; un 416 es lo segundo.
          yield Terminada(
            OrigenCaido(intentos: intento, ultimoError: null),
          );
          return;
        }

        if (recibidos < total) {
          yield Terminada(DescargaIncompleta(recibidos: recibidos, esperados: total));
          return;
        }

        // Los bytes, sin copiar. Si el servidor ha mandado el fichero entero, son
        // los suyos; si no, es el bufer reservado con los trozos ya en su sitio.
        final bytes = enteroDelServidor ?? acumulado;

        if (!mismoHash(hashEsperado, obtenido)) {
          if (hashEnDispositivo != null && mismoHash(hashEnDispositivo, obtenido)) {
            yield Terminada(HayVersionNueva(bytes));
            return;
          }
          yield Terminada(HashIncorrecto(esperado: hashEsperado, obtenido: obtenido));
          return;
        }

        yield Terminada(Obtenido(bytes: bytes, bytesTotales: total));
        return;
      } catch (e) {
        if (intento == intentosMaximos) {
          yield Terminada(OrigenCaido(intentos: intento, ultimoError: e));
          return;
        }
        await _cliente.esperar(Duration(milliseconds: 400 * intento));
      }
    }

  }

  /// Comprueba si el origen responde a una peticion de otro origen.
  ///
  /// Se hace una peticion de UN byte en vez de una de rango: si esa ya falla por
  /// permisos, la de rango tambien va a fallar, y no se baja nada por el camino.
  ///
  /// Y SE LLAMA [noDejaLeerDesdeNavegador] Y NO CON GUION BAJO PORQUE NO ES PRIVADO.
  /// La comprobacion de que una peticion **sin** `access-control-allow-origin` no es un
  /// "no deja leer" se hace desde una prueba, y si el metodo fuera privado no habria
  /// manera de probarla sin subirla entera por el `obtener`. Con el metodo publico se
  /// pregunta directamente y se responde con el codigo que ha dado la red.
  Future<bool> noDejaLeerDesdeNavegador(Uri url) async {
    // ============================================================================
    // ESTA COMPROBACION ESTABA MAL, Y ROMPIA LA DESCARGA EN EL CASO NORMAL
    // ============================================================================
    //
    // La primera version miraba si la respuesta traia `access-control-allow-origin` y,
    // si no, decia que el servidor no dejaba leerlo desde el navegador. Descubrio asi la
    // diferencia entre la release de GitHub --que no manda esa cabecera-- y GitHub Pages
    // --que si--, y en el caso de la release acertaba.
    //
    // Pero en **este** despliegue la aplicacion esta en
    // `https://yojananyosef.github.io/ab/` y los modulos en
    // `https://yojananyosef.github.io/aa/modulos/...`: **mismo origen**. Y una peticion
    // de mismo origen no lleva `access-control-allow-origin` ni falta que lleve, porque
    // no hay nada que autorizar. O sea que la comprobacion decia "no deja leerlo" justo
    // en el despliegue donde la descarga funciona, y la aplicacion se negaba a bajar el
    // texto y decia "abre un fichero local".
    //
    // MEDIDO EL 4 DE OCTUBRE DE 2026, al montar la comprobacion en navegador del grupo 8.
    // Y no en una maquina rara ni en un caso limite: en el caso normal, con el navegador
    // real y el despliegue real.
    //
    // ============================================================================
    // Y AHORA QUE SE PREGUNTA
    // ============================================================================
    //
    // Se hace **la peticion y se mira lo que contesto**, que es la unica pregunta que
    // sabe responder la red:
    //
    //   - Si el navegador puede leerla, contesta con su cuerpo y con un 2xx.
    //   - Si no puede --porque el servidor no manda la cabecera y el origen es distinto--,
    //     el navegador **no entrega nada**: la peticion falla y `rango` devuelve null.
    //
    // O sea que la cabecera no hace falta mirarla. Y antes era peor en las dos
    // direcciones: si la cabecera faltaba y la peticion **si** habia llegado, decia que no
    // se podia leer; y si la peticion no habia llegado --`r == null`-- decia que si se
    // podia, y se ponia a descargar 22 MiB que no iba a funcionar.
    try {
      final r = await _cliente.rango(url, 0, 0);

      // Un null significa que la peticion ni siquiera llego a salir, o que el navegador la
      // bloqueo. De las dos maneras no se puede decir *por que* desde aqui, asi que se
      // responde que no: la descarga de verdad va a intentarlo y su error
      // --`OrigenCaido`-- es el que sabe de que se trata.
      if (r == null) return false;

      // Y UN 200 O UN 206 ES LO NORMAL. El 206 es el de un rango, que es lo que se ha
      // pedido; y el 416 --"rango no valido"-- tambien vale, porque significa que el
      // servidor ha entendido la peticion y ha contestado.
      return r.codigo != 200 && r.codigo != 206 && r.codigo != 416;
    } catch (_) {
      return false;
    }
  }
}

/// Bytes en MiB con un decimal, para el texto del progreso.
///
/// Redondear a MiB y no a KB es a proposito: durante una descarga de 57 MB, un
/// numero que cambia cada medio segundo no dice nada, y uno que cambia cada
/// medio MiB se lee como "va".
String _mib(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
