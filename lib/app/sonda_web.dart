// La sonda en web: escribir el resultado en un elemento del DOM.
//
// Flutter web pinta en un `canvas`: el DOM no tiene el texto que se ve, solo una foto.
// Por eso una comprobacion en navegador tiene que pedirle a la aplicacion que escriba
// lo que ha leido, y lo que se escribe es un `<pre>` con un `id` conocido, que es lo unico
// que `--dump-dom` puede leer de una manera fiable.
//
// Y VA CON `package:web`, Y NO CON `dart:html`. `package:web` es la interfaz moderna, es
// la que ya usan el almacenamiento de modulos y el selector de archivos de este
// repositorio, y `dart:html` esta deprecado desde Dart 3. Using deprecated API en el
// repositorio que se Review es justo el fallo que se quiere evitar.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Escribe [texto] en el elemento con el id [id], creandolo si no esta.
///
/// Y SE SUSTITUYE, no se anade. Si se anadiera, una segunda escritura dejaria dos
/// resultados en el documento y el que se lee seria el primero --el de un estado
/// anterior--, que es peor que no escribir nada: es escribir un resultado que ya no
/// es verdad.
///
/// Y SE CREA SI NO ESTA, porque el documento de una aplicacion Flutter no tiene nada
/// donde escribir. Se anade al `body`, y si no hay `body` --un documento minimo-- se
/// anade al `documentElement` en su lugar, que es lo unico que siempre existe.
void escribirEnElMarcador(String id, String texto) {
  final documento = web.document;
  var marcador = documento.getElementById(id);

  if (marcador == null) {
    final pre = documento.createElement('pre') as web.HTMLPreElement
      ..id = id
      ..style.display = 'none';
    (documento.body ?? documento.documentElement)?.append(pre);
    marcador = pre;
  }

  marcador.textContent = texto;
}

/// Envia el resultado a [url], sin esperar respuesta.
///
/// ESTE SEGUNDO CAMINO EXISTE PORQUE `--dump-dom` NO FUNCIONA CON UNA APLICACION DE
/// FLUTTER. Medido en esta maquina con Brave 154 el 4 de octubre de 2026:
///
///     brave-browser --headless=new --dump-dom http://127.0.0.1:8099/ > salida.html
///     exit=124  salida.html con 0 bytes
///
/// Se queda esperando hasta que le matan el proceso, con y sin
/// `--virtual-time-budget`, y con y sin `--timeout`. Y no es raro: el motor de Flutter
/// mantiene vivo el bucle de `requestAnimationFrame`, y `--dump-dom` espera a que la
/// pagina termine de cargar, que con ese bucle no ocurre nunca. Con una pagina normal si
/// funciona --se comprobo con un `file://` de tres lineas--, asi que el problema es
/// especifico de Flutter.
///
/// Que siga colgado **no es un problema de la sonda**: el DOM si recibe el `<pre>`, que
/// es lo que pedia la tarea 8.1. Es que nadie lo puede leer de fuera. Asi que el
/// resultado se manda **tambien** a un sitio que si se puede leer: un `fetch` a un
/// servidor local que lo imprime. Y se sigue escribiendo en el DOM, para que se pueda
/// mirar con las herramientas del navegador.
///
/// Y CON `keepAlive: true`, y no por gusto. Al terminar el reloj virtual el navegador
/// tira la pagina, y un `fetch` normal a veces no llega a salir. Con `keepAlive` el
/// navegador lo manda **aunque se este cerrando**, que es justo el caso de aqui.
///
/// Y EL ERROR SE IGNORA A CONSCIENTE. Si no hay colector, o esta caido, o el navegador
/// no puede, la comprobacion no se cae por eso: lo que importa es el resultado, y esta
/// escrito en el DOM y en la consola. Tirar la aplicacion porque no se pudo avisar a un
/// script seria lo contrario de robusto.
void notificarPorHttp(String url, String texto) {
  try {
    // `fetch` y no un `XMLHttpRequest`: el `fetch` es el que tiene `keepalive`, que es
    // justo lo que necesita esta llamada, y el `XMLHttpRequest` sincrono esta
    // despreciado.
    //
    // Y `RequestInit` y no un mapa: en `package:web` los parametros de una llamada se
    // pasan en una clase con nombre, y un mapa "a pelo" no existe.
    web.window.fetch(
      url.toJS,
      web.RequestInit(
        method: 'POST',
        body: texto.toJS,
        keepalive: true,
      ),
    );
  } catch (_) {
    // Sin colector, o con el navegador en un estado raro: no es un fallo de la app.
  }
}

/// Cuantas entradas tiene el historial del navegador.
///
/// Null fuera del navegador. Y null en vez de cero: "no hay historial" y "hay cero
/// entradas" no son lo mismo, y con un cero la comprobacion creeria que hamidalgo ha
/// quitado entradas cuando lo que ha pasado es que no habia donde mirar.
int? longitudDelHistorial() => web.window.history.length;
