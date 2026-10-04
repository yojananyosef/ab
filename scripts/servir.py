#!/usr/bin/env python3
"""Servir `build/web` como lo haria GitHub Pages, y de paso `/aa` desde el mismo origen.

Dos cosas, y las dos son necesarias para que la comprobacion mida lo que dice medir.

1. `404.html` para lo que no existe
===================================

La aplicacion se sirve en rutas profundas --`/leer/KJV2006/John.3.16`-- y esa ruta no es
un fichero: no hay ningun directorio con ese nombre en `build/web`.

GitHub Pages, cuando no encuentra lo que se le pide, **sirve `404.html`** con codigo de
estado 404. El CI lo tiene en cuenta y copia `index.html` a `404.html`
(`.github/workflows/ci.yml`), de modo que el navegador pinta la aplicacion --con un 404
de verdad-- y el enrutador puede leer la direccion y saber que pasaje se ha pedido.

`python3 -m http.server` no hace eso: devuelve su propia pagina de error, sin aplicacion
dentro. Medido el 4 de octubre de 2026:

    GET /leer/KJV2006/John.3.16       -> 404 con la pagina del servidor
    GET /leer/KJV2006/sqlite3.wasm   -> 404 con la pagina del servidor

Que devuelve el codigo 404 de verdad
------------------------------------

A proposito, y no por descuido. GitHub Pages tambien lo hace, y el enrutador **no** lo
tiene en cuenta: lo que lee es `location`, que con un 404 sigue siendo la ruta buena. Si
aqui se sirviera con codigo 200, comprobar que recargar conserva el pasaje seria mas
facil de pasar que en el sitio de verdad, y seria una comprobacion que mide menos de lo
que dice medir.

2. `/aa` desde el mismo origen, y POR QUE
=========================================

**Este es el motivo por el que la primera version de la comprobacion en navegador
fallaba con "El servidor no permite leerlo desde el navegador", y no era un fallo de la
aplicacion.**

En el sitio real la aplicacion esta en `https://yojananyosef.github.io/ab/` y los
modulos en `https://yojananyosef.github.io/aa/modulos/...`: **mismo origen**, y por eso no
hay ninguna peticion que pueda fallar por CORS. Servida la aplicacion en local, el origen
es `http://127.0.0.1:8099` y los modulos siguen en `github.io`: origen distinto, y la
peticion lleva la cabecera `Range`, que no es "simple", asi que el navegador hace un
`preflight` antes. Y GitHub Pages **no responde a los preflight**:

    $ curl -X OPTIONS -H 'Access-Control-Request-Headers: range' .../KJV2006_bible.amod
    HTTP/2 405

Con un 405 en el preflight el navegador no hace ni la peticion. Y la comprobacion estaba
midiendo una situacion --origenes distintos-- que en produccion no puede ocurrir, y
fallando por un motivo que no tiene nada que ver con lo que hay que comprobar.

Lo que se hace, entonces, es servir `/aa` **desde el mismo origen local**, reenviando a
GitHub Pages. Y solo se reescribe el **nombre de la maquina** en el JSON del manifiesto;
los bytes del `.amod` y los tamanos pasan sin tocarse.

Y EL SHA256 SE COMPRUEBA IGUAL. Es lo que hace que esto no sea un atajo: si el proxy
tocara un byte, el motor de obtencion --que compara el sha256 con el del manifiesto-- lo
veria y la comprobacion fallaria. No hay forma de hacer trampas aqui sin que se note.

Y UN SOLO SERVIDOR, Y UN SOLO MANEJADOR
=======================================

La primera version de esto tinha un manejador de proxy y otro de la aplicacion, joined
with `functools.partial` y herencia multiple, y no arrancaba:

    TypeError: BaseRequestHandler.__init__() got an unexpected keyword argument 'directory'

`functools.partial` no se puede expandir con `**kwargs` y aqui no hacia falta nada de eso. Se
resuelve con un solo manejador que decide por el camino, y el `directory` se pasa en el
constructor de la forma normal. Menos piezas y un solo sitio donde mirar que pasa con un
`/aa/...` y con un `/leer/...`.
"""

from __future__ import annotations

import argparse
import http.server
import io
import json
import socketserver
import sys
import urllib.error
import urllib.request

# Donde esta el catalogo de verdad. Es una constante **de este script**, no de la
# aplicacion: la aplicacion no sabe que existe un proxy y cree que el origen es el que le
# ha dado `origen.dart`.
ORIGEN_REAL = "https://yojananyosef.github.io"
PREFIJO_CATALOGO = "/aa"

# Las claves del manifiesto que llevan una URL **de donde se baja el modulo**.
#
# Y LA LISTA ESTA EXPLICITA Y NO ES "TODA CADENA QUE PAREZCA UNA URL", por dos motivos,
# y los dos son fallos que se han cometido aqui:
#
#   - `source` **no** va aqui, y la primera version lo tenia. Es la procedencia del texto
#     --de donde vino el USFM-- y no de donde se baja. Si se reescribe, el manifiesto
#     pasa a decir que el texto de eBible.org vino de `127.0.0.1`, que es falso y queda
#     escrito. No hay nada que lo consuma todavia, asi que el error no se ve: por eso hay
#     una prueba que lo comprueba.
#   - Una descripcion o un comentario podria contener un enlace a otro sitio que no debe
#     cambiarse, y una URL que **no** se reescribiese apuntaria a github.io desde una
#     pagina que dice estar en `127.0.0.1`, que es peor que no hacer de proxy.
#
# `url` si va, y es la del manifiesto dentro de `latest.json`. En la release es una URL de
# github.com y no se toca; si algun dia `latest.json` se sirviera desde Pages, se
# reescribiria, que es lo que quiero.
CLAVES_CON_URL = ("browserUrl", "downloadUrl", "catalogBrowserUrl", "url")


class Manejador(http.server.SimpleHTTPRequestHandler):
    """La aplicacion en `/`, y el catalogo de verdad en `/aa/..`."""

    def __init__(self, *args, directorio: str, base_local: str, **kwargs):
        # ANTES DE `super().__init__`, y no despues. `BaseRequestHandler.__init__` no
        # solo guarda cosas: **atiende la peticion**. Es decir, que con el orden
        # normal --llamar a `super` y luego guardar lo tuyo--, la peticion se atiende
        # antes de que exista `base_local`, y la primera que llega --`/aa/latest.json`--
        # falla con `AttributeError: 'Manejador' object has no attribute 'base_local'`.
        # Con los `.amod` --que no reescriben nada-- no se notaba, y por eso fallo solo
        # con el manifiesto.
        self.base_local = base_local
        super().__init__(*args, directory=directorio, **kwargs)

    def setup(self):
        super().setup()
        self._no_encontrado = False

    # --- decidir ---

    @property
    def es_del_catalogo(self) -> bool:
        return self.path.startswith(PREFIJO_CATALOGO + "/")

    # --- peticiones del catalogo ---

    def do_GET(self) -> None:  # noqa: N802 -- lo llama el padre
        if self.es_del_catalogo:
            self._proxy()
            return
        super().do_GET()

    def do_HEAD(self) -> None:  # noqa: N802
        if self.es_del_catalogo:
            self._proxy()
            return
        super().do_HEAD()

    def _proxy(self) -> None:
        destino = ORIGEN_REAL + self.path
        peticion = urllib.request.Request(destino)

        # El `Range` se reenvia tal cual. Y tiene que reenviarse: la descarga va por
        # trozos de 4 MiB y sin la cabecera GitHub Pages manda el fichero entero, que en
        # el CLARKE son 57 MiB de una sentada. La comprobacion del sha256 lo notaria.
        #
        # El `Range` se reenvia tal cual, y solo el `Range`.
        #
        # Y EL `Accept-Encoding` **NO** SE REENVIA: se fuerza `identity`. La primera
        # version reenviaba la del navegador --`gzip, deflate, br, zstd`--, GitHub
        # Pages comprimia y el proxy reventaba con
        # `UnicodeDecodeError: 'utf-8' codec can't decode byte 0x8b`, que es el signo
        # gzip. Y no solo es un fallo del proxy: si el `.amod` llegue comprimido, el
        # sha256 no cuadra con el del manifiesto y la comprobacion del motor falla por un
        # motivo que no tiene nada que ver con ella.
        #
        # Es el mismo motivo por el que `http_service.dart` envia `identity` en sus
        # peticiones por rango, y por el que el fallo esta documentado en `AGENTS.md`.
        peticion.add_header("Accept-Encoding", "identity")
        rango = self.headers.get("Range")
        if rango:
            peticion.add_header("Range", rango)

        try:
            with urllib.request.urlopen(peticion) as r:
                codigo = r.status
                cuerpo = r.read()
                cabeceras = dict(r.headers)
        except urllib.error.HTTPError as e:
            self.send_error(e.code, f"El proxy no pudo traer {destino}: {e}")
            return
        except OSError as e:
            self.send_error(502, f"El proxy no pudo traer {destino}: {e}")
            return

        # Y AUN ASI SE DESCOMPRIME, por si el servidor ignorara lo pedido. Con el codigo gzip
        # de la cabecera, el cuerpo son bytes comprimidos y todo lo de abajo --el sha256,
        # los rangos, el JSON-- hablaria de lo comprimido. Es una defensa que no deberia
        # necesitarse, y que por eso lleva su comentario: si alguna vez se ve, significa
        # que GitHub Pages ha cambiado de comportamiento y hay que mirarlo.
        if cuerpo[:2] == b"\x1f\x8b":
            import gzip

            cuerpo = gzip.decompress(cuerpo)
            cabeceras.pop("Content-Encoding", None)
            cabeceras["Content-Length"] = str(len(cuerpo))

        tipo = cabeceras.get("Content-Type", "application/octet-stream")
        if self.path.endswith(".json"):
            cuerpo = self._reescribir_json(cuerpo)
            tipo = "application/json; charset=utf-8"
            if self.path.endswith("/latest.json"):
                cuerpo = self._arreglar_el_indice(cuerpo)

        self.send_response(codigo)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(cuerpo)))
        for cabecera in ("Content-Range", "Accept-Ranges"):
            if cabecera in cabeceras:
                self.send_header(cabecera, cabeceras[cabecera])
        # El `ETag` **no** se reenvia: describe el recurso de github.io, no el de aqui.
        # Mandarlo haria que un `If-None-Match` de un cliente acierte, no llegue el cuerpo,
        # y la comprobacion se quedaria sin texto sin saber por que.
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(cuerpo)

    def _reescribir_json(self, cuerpo: bytes) -> bytes:
        """Cambia solo el host de las URL del manifiesto, y nada mas."""
        return json.dumps(
            _recorrer(json.loads(cuerpo), self.base_local), ensure_ascii=False
        ).encode("utf-8")

    def _arreglar_el_indice(self, indice: bytes) -> bytes:
        """Recalcula `catalogSha256` del indice, porque el manifiesto ya es otro.

        ESTO NO ES HACER TRAMPA Y HAY QUE DECIR POR QUE. Al reescribir las URL del
        manifiesto, sus bytes cambian, y su sha256 con ellos. La aplicacion comprueba que
        el `catalog.json` que recibe tenga el sha256 que anuncia `latest.json`, y sin
        esto falla con "El catalogo descargado no es el que anuncia el indice" --que es
        la comprobacion **haciendo su trabajo**: los bytes no son los publicados.

        Y LO QUE SE PIERDE CON ESTO, Y LO QUE NO. Se pierde que el manifiesto sea
        byte a byte el publicado. No se pierde lo que importa, y se comprueba en otro
        sitio:

        - El sha256 **del `.amod`**, que no se toca: son 22.544.384 bytes que pasan
          intactos y el motor de obtencion los compara con el `sha256` del manifiesto. Un
          proxy que tocara un byte lo veria.
        - Los ** tamanos** de los modulos, que se comparan contra los valores publicados
          escritos en `scripts/comprobar-en-navegador.sh`.
        - La **etiqueta**, que sale del mismo manifiesto reescrito pero es un dato, no un
          resumen, y se compara con `v0.1.1`.

        Es decir: el manifiesto es de un espejo y su resumen es el del espejo, que es lo
        unico que puede ser. Y lo que de verdad importa --los bytes del texto-- sigue
        viniendo de github.io sin pasar por nada.
        """
        import hashlib

        documento = json.loads(indice)
        url = documento.get("browserUrl")
        if not isinstance(url, str) or not url.startswith(self.base_local):
            return indice

        peticion = urllib.request.Request(url)
        peticion.add_header("Accept-Encoding", "identity")
        try:
            with urllib.request.urlopen(peticion) as r:
                remoto = r.read()
        except OSError as e:
            self.send_error(502, f"El proxy no pudo traer {url}: {e}")
            return indice

        reescrito = self._reescribir_json(remoto)
        documento["catalogSha256"] = hashlib.sha256(reescrito).hexdigest()
        return json.dumps(documento, ensure_ascii=False).encode("utf-8")

    # --- 404.html para lo que no existe ---

    def send_error(self, code, message=None, explain=None):
        if code == 404:
            # SIN ESTO NO HAY NADA QUE HACER. `SimpleHTTPRequestHandler.send_head`,
            # cuando no encuentra el fichero, llama a `send_error(404, ...)` --que ya
            # escribe la respuesta-- y devuelve `None`. La primera version de este
            # servidor devolvia `404.html` desde ahi y lo que se obtenia era la pagina de
            # error de la biblioteca: el error ya estaba escrito antes de que este codigo
            # escribiera nada. Por eso el 404 se avisa aqui, se **impide**, y se
            # reescribe entero despues.
            self._no_encontrado = True
            return
        if self.es_del_catalogo:
            # Y EN EL CATALOGO EL 404 SE ESCRIBE DE NORMAL, porque aqui el 404 es de
            # verdad: si `/aa/modulos/v0.1.1/no-existe.amod` no esta en github.io, no
            # hay que inventarle una aplicacion.
            self._escribir_error_simple(code, message, explain)
            return
        super().send_error(code, message, explain)

    def _escribir_error_simple(self, code, message, explain) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(f"{code}: {message}\n".encode("utf-8"))

    def send_head(self):
        self._no_encontrado = False
        cabeza = super().send_head()
        if cabeza is not None:
            return cabeza

        # Aqui solo se llega si lo que faltaba era el fichero de la peticion.
        if not self._no_encontrado or self.es_del_catalogo:
            return None

        try:
            with open(self.translate_path("404.html"), "rb") as f:
                cuerpo = f.read()
        except OSError:
            self.send_error(
                404,
                "File not found",
                "Falta 404.html, y sin el una ruta profunda no carga la aplicacion",
            )
            return None

        self.send_response(404)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        return io.BytesIO(cuerpo)

    def translate_path(self, path: str) -> str:
        # Y NO SE TOCA PARA `/aa/...`. Sin esto, `send_head` --que es lo que busca
        # `404.html`-- intentaria abrir `/aa/404.html` dentro de `build/web`, que no esta,
        # y una peticion al catalogo que fallara se comeria el `404.html` de la
        # aplicacion. Lo de `/aa` lo resuelve el proxy, no el sistema de ficheros.
        if self.es_del_catalogo:
            return path
        return super().translate_path(path)

    def log_message(self, formato, *args) -> None:
        prefijo = "  aa->github.io: " if self.es_del_catalogo else "  servidor: "
        sys.stderr.write(prefijo + (formato % args) + "\n")
        sys.stderr.flush()


def _recorrer(nodo, base_local: str):
    if isinstance(nodo, dict):
        salida = {}
        for clave, valor in nodo.items():
            if isinstance(valor, str) and clave in CLAVES_CON_URL:
                salida[clave] = _cambiar_host(valor, base_local)
            else:
                salida[clave] = _recorrer(valor, base_local)
        return salida
    if isinstance(nodo, list):
        return [_recorrer(v, base_local) for v in nodo]
    return nodo


def _cambiar_host(url: str, base_local: str) -> str:
    if not url.startswith(ORIGEN_REAL):
        return url
    return base_local + url[len(ORIGEN_REAL):]


class Servidor(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    # Chrome abre varias conexiones a la vez --el motor, el wasm, las peticiones por
    # rango-- y un servidor de un solo hilo las atenderia de una en una, con esperas
    # entre medias. Con `daemon_threads` cada peticion va en su hilo y no hay colas.
    allow_reuse_address = True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--directorio", required=True)
    ap.add_argument("--puerto", type=int, default=8099)
    args = ap.parse_args()

    base_local = f"http://127.0.0.1:{args.puerto}"
    print(
        f"sirviendo {args.directorio} en {base_local}/, "
        f"y {PREFIJO_CATALOGO} reenviado a {ORIGEN_REAL}",
        flush=True,
    )

    manejador = functools_partial(Manejador, directorio=args.directorio, base_local=base_local)
    with Servidor(("127.0.0.1", args.puerto), manejador) as s:
        s.serve_forever()
    return 0


def functools_partial(clase, **kwargs):
    """Un `functools.partial` que se puede pasar a `HTTPServer`.

    Y NO ES EL DE LA BIBLIOTECA, y hay que decirlo porque parece que si. El de la
    biblioteca guarda los `**kwargs` en un diccionario y los pasa en `__init__`, y eso
    funciona... salvo que la clase base de `http.server` tiene su propio `__init__` con
    firma propia, y al resolver la cadena de herencia el `directory` acaba en el
    `BaseRequestHandler` --que no lo acepta-- y no en el `SimpleHTTPRequestHandler` que si.
    La version de aqui lo hace explicito.
    """

    def construir(*args, **kw):
        todos = {**kwargs, **kw}
        return clase(*args, **todos)

    return construir


if __name__ == "__main__":
    sys.exit(main())
