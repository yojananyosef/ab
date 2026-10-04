// El selector de archivos del navegador.
//
// Uno de los dos ficheros que saben en que plataforma estamos. Si anades un
// metodo aqui, anadelo tambien en `selector_de_archivos_nativo.dart`, o el codigo
// que funciona en una plataforma no compilara en la otra.
//
// QUE HACE. Crea un `<input type="file">` invisible, lo pulsa, y espera. Es lo
// unico que el navegador ofrece, y funciona en todos: es lo que hay detras de
// cualquier boton "abrir archivo" de cualquier web.
//
// Y "ARRASTRAR Y SOLTAR". No hay codigo aparte porque el `<input type=file>` ya
// acepta que se suelte un fichero encima de la ventana: el navegador abre el
// mismo dialogo. Por eso la API tiene una sola operacion en las dos plataformas y
// quien llama no tiene que ofrecer dos botones que hacen lo mismo.
//
// LO UNICO QUE NO SE PUEDE HACER, Y POR QUE NO SE INTENTA: cambiar el texto del
// boton que el navegador pone. Sale en el idioma del navegador y de la pagina, no
// en el de la app. Una app en castellano con un boton en ingles se nota; pero
// sustituirlo por texto plano rompe la accesibilidad del boton y el arrastrar y
// soltar, que es justo lo que se queria. Se deja el del navegador y se pone el
// nombre de la app encima, que si es castellano.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'selector_de_archivos.dart';

class SelectorWeb implements SelectorDeArchivos {
  SelectorWeb();

  @override
  List<String>? get filtroSugerido => const ['.amod'];

  web.HTMLInputElement? _input;

  @override
  Future<ResultadoDeElegir> elegir() async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      // El `accept` es una **sugerencia** para el dialogo del navegador, no un
      // filtro que se pueda forzar: con `multiple` puesto, un fichero con otra
      // extension se puede elegir igual. Es una ayuda para quien ya sabe lo que
      // busca y no un muro para quien no lo sabe.
      ..accept = '.amod'
      // Sin `multiple`: esta app procesa un `.amod` cada vez, porque cada uno son
      // 22 o 57 MiB y bajarlos todos a la vez sin querer deja el movil sin
      // memoria. Admitirlo y luego decir que no seria peor.
      ..multiple = false
      ..style.display = 'none';

    _input = input;
    web.document.body?.append(input);

    try {
      input.click();
      // `click()` es sincrono y el navegador no da ninguna promesa: el `change`
      // llega cuando la persona elija, o nunca llega si cierra el dialogo. Por eso
      // se hace `complete` desde el `change`, y el cierre sin elegir lo trata el
      // temporizador. Y la razon de que haga falta ese temporizador esta escrita
      // mas abajo, porque no es un remate.
      return await _esperar(input);
    } finally {
      // El elemento se quita siempre. Si se deja, cada vez que se abre el selector
      // se acumula un `<input>` en el cuerpo de la pagina, y en una app que se usa
      // a diario eso acaba siendo cientos de nodos que nadie sabe por que estan.
      input.remove();
      _input = null;
    }
  }

  /// Espera a que haya fichero, o a que se de por cancelado.
  ///
  /// EL PROBLEMA DE VERDAD, Y POR QUE HAY UN TEMPORIZADOR. El navegador **no
  /// avisa** de que el dialogo se ha cerrado sin elegir. No hay ningun evento para
  /// eso: `change` solo se dispara si hay un fichero. Sin temporizador, la app
  /// espera para siempre con un "cargando" en pantalla y quien queria cancelar se
  /// queda colgado sin poder hacer nada, y tiene que recargar.
  ///
  /// Por eso se sondea `files.length`: si el dialogo se ha cerrado sin elegir, el
  /// `input` sigue ahi con la lista vacia y eso ya es la respuesta. Y por eso el
  /// temporizador es corto, 300 ms, y se repite: corto porque cancelar es la accion
  /// frecuente y hacer esperar medio segundo se nota; y repetido porque 300 ms no
  /// cubren el tiempo que tarda alguien en decidir, y si solo se mirara una vez se
  /// declararia cancelado a quien estaba pensando.
  ///
  /// El limite son 3 minutos. Un minuto y medio pensando si abrir un fichero esta
  /// bien; tres minutos sin decidir ya no es pensar, es que se ha ido.
  Future<ResultadoDeElegir> _esperar(web.HTMLInputElement input) async {
    final listo = Completer<ResultadoDeElegir>();
    var terminado = false;

    void responder(ResultadoDeElegir r) {
      if (terminado) return;
      terminado = true;
      listo.complete(r);
    }

    void alCambiar(web.Event _) {
      final ficheros = input.files;
      if (ficheros == null || ficheros.length == 0) return;
      final f = ficheros.item(0);
      if (f == null) return;
      // La lectura es asincrona y el `change` no, asi que se encadena. Se hace
      // con `then` y no con `await` porque el manejador tiene que ser sincrono.
      f.arrayBuffer().toDart.then(
        (buffer) => responder(
          ResultadoDeElegir.elegido(
            ArchivoElegido(nombre: f.name, bytes: buffer.toDart.asUint8List()),
          ),
        ),
        onError: (_) => responder(
          const ResultadoDeElegir.fallido('No se ha podido leer el fichero elegido.'),
        ),
      );
    }

    input.addEventListener('change', alCambiar.toJS);
    // ignore: unnecessary_statements

    const limite = Duration(minutes: 3);
    var waited = Duration.zero;
    const paso = Duration(milliseconds: 300);
    Timer.periodic(paso, (t) {
      if (terminado) {
        t.cancel();
        return;
      }
      waited += paso;
      if (input.files != null && input.files!.length > 0) return;
      // El `change` ya habra respondido si habia fichero. Si no lo hay y ha pasado
      // un rato, la persona ha cerrado el dialogo.
      if (waited > paso) {
        t.cancel();
        input.removeEventListener('change', alCambiar.toJS);
        responder(const ResultadoDeElegir.cancelado());
      }
      if (waited >= limite) {
        t.cancel();
        input.removeEventListener('change', alCambiar.toJS);
        responder(const ResultadoDeElegir.fallido('El selector ha tardado demasiado.'));
      }
    });

    return listo.future;
  }

  @override
  void dispose() {
    _input?.remove();
    _input = null;
  }
}

/// La implementacion de este fichero. La llama `crearSelector()` del otro.
SelectorDeArchivos crearSelector() => SelectorWeb();
