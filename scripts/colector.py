#!/usr/bin/env python3
"""El colector: recibe el resultado de la sonda y lo guarda.

Por que no se lee el DOM
========================

Flutter web pinta en un `canvas`: el DOM no tiene el texto que se ve. Y `--dump-dom`
de un navegador, con una aplicacion de Flutter, **se queda esperando para siempre**:

    brave-browser --headless=new --dump-dom http://127.0.0.1:8099/ > salida.html
    exit=124  salida.html con 0 bytes

Medido el 4 de octubre de 2026 con Brave 154, con y sin `--virtual-time-budget` y con
y sin `--timeout`. Con una pagina normal si funciona --se comprobo con un `file://` de
tres lineas--, asi que el problema es el motor de Flutter, que mantiene vivo el bucle de
`requestAnimationFrame` y `--dump-dom` espera a que la pagina termine de cargar.

Asi que el resultado no se lee del DOM: **lo manda la propia aplicacion** a este
servidor, con un `fetch` a pelo, y el navegador se lanza con `--screenshot`, que si
termina. Los dos caminos existen: el `<pre id="ab-sonda">` se sigue escribiendo --para
poder mirarlo con las herramientas del navegador-- y aqui llega lo que el script
comprueba.

Porque se elige este metodo y no un piloto que hable con el navegador por el protocolo de
depuracion: un piloto tendria que reimplementar el arranque, y entonces comprobaria lo
que el piloto quiere, no lo que hace la aplicacion. Aqui lo que llega es lo que ha
devuelto una consulta SQL a un `.amod` de 22.544.384 bytes.
"""

from __future__ import annotations

import argparse
import http.server
import json
import pathlib
import sys
import threading
import time

# El contador de escrituras y el candado, a nivel de modulo y no de clase.
#
# Van fuera porque `BaseHTTPRequestHandler` crea **una instancia por conexion**, y una
# clase se instancia por peticion si el navegador abre conexiones nuevas --que es lo que
# pasa. Un atributo de clase con `self.x += 1` no se escribe nunca en la clase: se crea
# uno de instancia y se tira al acabar la peticion. Ver `do_POST`.
#
# Y POR QUE UNA LISTA Y NO UN `int`: `global` con `+=` sobre un entero funciona, pero en
# un modulo con una funcion que lo lee desde otro hilo --el principal, que espera-- hace
# falta que sea una **celda** y no una constante. Una lista de un elemento es la forma
# idiomatica de tener una celda mutable sin `nonlocal`, y por eso esta aqui y no un
# contador con `global`.
CUANTAS = [0]
CANDADO = threading.Lock()

# Cuando llega una escritura marcada como la ultima.
FINAL = threading.Event()


# El POST que se espera, y el limite. El limite es **de reloj de pared**, no de reloj
# virtual: el navegador va con reloj virtual, asi que "cuanto falta" no lo sabe nadie
# desde aqui. Y es generoso porque la primera ejecucion baja 22 MiB de GitHub Pages.
LIMITE_POR_DEFECTO = 900.0


class Colector(http.server.BaseHTTPRequestHandler):
    # De donde lee, en vez de un global. Un global seria mas corto y obligaria a que el
    # servidor de ficheros se montara despues de este, que es el orden en el que no se
    # puede.
    destino: pathlib.Path | None = None
    recibido = threading.Event()

    def do_POST(self) -> None:  # noqa: N802 -- lo llama el padre
        cuerpo = self._leer_cuerpo()
        if cuerpo is None:
            # Y SI NO SE PUEDE LEER, SE DICE Y NO SE ESCRIBE NADA. Un fichero vacio
            # escrito aqui parece un resultado, y el script lo leeria como un JSON
            # vacio --que es lo que pasaba-- sin decir por que.
            print(
                "no se ha podido leer el cuerpo de la peticion",
                file=sys.stderr,
                flush=True,
            )
            self._escribir_error_simple(415, "unsupported media type")
            return


        if self.destino is not None:
            # Y SE GUARDA **CADA** ESCRITURA, con su numero, y no solo la ultima.
            #
            # La sonda escribe mas de una vez: primero cuando ha leido el pasaje, y otra
            # despues de medir el historial. Con un solo fichero, la segunda sobrescribe
            # la primera y se pierde justo lo que hace falta para entender un fallo: que
            # la primera estaba bien y la segunda no. Con un fichero por escritura se ve
            # la secuencia entera, y "antes iba bien y despues no" es un diagnostico.
            with CANDADO:
                CUANTAS[0] += 1
                n = CUANTAS[0]
                nombre = self.destino.with_name(
                    f"{self.destino.stem}.{n}{self.destino.suffix}"
                )
                nombre.write_text(cuerpo, encoding="utf-8")
            self.destino.write_text(cuerpo, encoding="utf-8")

            # Y se imprime aqui, en el servidor, y no despues leyendo el fichero. Una
            # comprobacion cuyo resultado se ve al final del script, despues de cuatro
            # minutos de descarga, no dice nada mientras se espera, que es cuando se
            # necesita.
            print(f"--- escritura numero {n} ---", flush=True)
            print(cuerpo, flush=True)

            if _marca_final(cuerpo):
                FINAL.set()

        # Y UN **200**, Y NO UN 204.
        #
        # MEDIDO EL 4 DE OCTUBRE DE 2026: con 204 el cliente de Dart abortaba la
        # peticion con "Broken pipe" al cerrarla, y el fallo parecia del navegador. Un
        # 204 no lleva cuerpo y no debe llevar `Content-Length`, y hay clientes que lo
        # toman como un error de protocolo y cierran la conexion. Un 200 con cuerpo de
        # cero bytes no tiene ninguna de las dos ambiguedades, y aqui el cuerpo no importa
        # porque la app no lee la respuesta.
        self.send_response(200)
        # Y `Access-Control-Allow-Origin`. Sin esto el navegador **manda** el `POST` --
        #un POST de texto sin preflight llega-- pero no deja **leer** la respuesta, y
        # escribe en la consola:
        #
        #     Access to fetch at 'http://127.0.0.1:8098/resultado' from origin
        #     'http://127.0.0.1:8096' has been blocked by CORS policy
        #
        # La comprobacion no se rompia por eso, porque la app no lee la respuesta. Pero
        # la consola llena de errores que no significan nada, y el dia que se mire un
        # error de red en esa consola, ese estara delante de los de verdad.
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", "0")
        self.end_headers()
        self.recibido.set()

    def _leer_cuerpo(self) -> str | None:
        """El cuerpo de la peticion, con `Content-Length` o con trozos.

        Y EL TROCEO NO ES UN ADORNO. MEDIDO EL 4 de octubre de 2026: el cliente de
        `dart:io` --y cualquier otro que no sepa el tamano de antemano-- manda
        `Transfer-Encoding: chunked` **sin** `Content-Length`. `BaseHTTPRequestHandler` no
        descodifica trozos, asi que leer `Content-Length` da 0 y el fichero se escribe
        **vacio**, sin ningun error: el script lo leia como un JSON vacio y decia
        "Unexpected end of input", que no senala ni al cliente ni al servidor.

        El navegador no tiene ese problema: `fetch` con un cuerpo de cadena manda
        `Content-Length`. O sea que esto solo lo-rompe el que viene de otro lenguaje, lo
        cual es justo el caso de la prueba, y por eso la prueba lo pilla.
        """
        codificacion = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in codificacion:
            trozos = bytearray()
            while True:
                linea = self.rfile.readline().strip()
                if not linea:
                    # Un final de linea vacio entre trozo y trozo. Si se acaba aqui, el
                    # siguiente `readline` es el tamaño del siguiente.
                    linea = self.rfile.readline().strip()
                if not linea:
                    return None
                try:
                    tamano = int(linea.split(b";")[0], 16)
                except ValueError:
                    return None
                if tamano == 0:
                    # Y HAY QUE LEERSE LA TERMINACION --un `0` y una linea vacia--, o
                    # el siguiente POST empieza por la mitad del anterior.
                    self.rfile.readline()
                    break
                trozos += self.rfile.read(tamano)
                self.rfile.readline()  # el CRLF del final del trozo
            return trozos.decode("utf-8", errors="replace")

        largo = self.headers.get("Content-Length")
        if largo is None:
            return None
        return self.rfile.read(int(largo)).decode("utf-8", errors="replace")

    def _escribir_error_simple(self, codigo: int, mensaje: str) -> None:
        self.send_response(codigo)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        # Para el `curl` de comprobacion de vida del servidor. Sin esto habria que
        # distinguir "el servidor no responde" de "la pagina no devuelve 404", que son
        # dos fallos distintos.
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"colector de la sonda\n")

    def log_message(self, *_args) -> None:
        # El servidor no imprime cada peticion. El GET de comprobacion-sale en la
        # pantalla del navegador con cada intento y son veinte lineas de ruido.
        return


def _marca_final(cuerpo: str) -> bool:
    """Si el cuerpo recibido va marcado como la ultima escritura."""
    try:
        return json.loads(cuerpo).get("final") is True
    except ValueError:
        return False


def esperar(destino: pathlib.Path, limite: float) -> tuple[bool, bool]:
    """Espera a que llegue la escritura marcada como la ultima. Devuelve (llego, final).

    Y SE ESPERA A **LA FINAL**, Y NO A "ALGUNA".

    MEDIDO EL 4 de octubre de 2026, dos veces distintas:

      - La primera version se paraba en la **primera** escritura. Las dos siguientes --
        la del historial-- llegaban a un servidor que ya no escuchaba; y como el `POST` va
        con `keepAlive`, algunas veces llegaban y otras no: la comprobacion del historial
        pasaba o no segun el dia.
      - La segunda version tenia una salida temprana que comprobaba solo "el fichero no esta
        vacio", y esa es la misma cosa que la primera: en cuanto llegaba la escritura 1 el
        fichero ya no estaba vacio, y el proceso se paraba. La prueba lo cogio
        --"Unexpected end of input" al leer un fichero a medio escribir--, que es el
        sintoma de un servidor que se apaga en mitad de una peticion.

    La condicion de parada es una sola: **el ultimo fichero es la final**. Y el plazo se
    comprueba antes de cada espera, para no pasarse.
    """
    inicio = time.monotonic()

    while True:
        restante = limite - (time.monotonic() - inicio)
        if restante <= 0:
            return False, False

        if destino.exists() and destino.stat().st_size > 0 and _es_final(destino):
            return True, True

        FINAL.wait(timeout=min(0.25, restante))


def _es_final(destino: pathlib.Path) -> bool:
    """Si la ultima escritura va marcada como la ultima.

    Y NO SE COMPRUEBA EL RESULTADO, SINO LA MARCA. Importa: una escritura con
    `"resultado": "excepcion"` tambien es la ultima, y pararse solo cuando el resultado es
    `ok` dejaria al servidor esperando el limite entero en cuanto hay un fallo --que es
    justo cuando hace falta la respuesta ya.
    """
    try:
        return json.loads(destino.read_text(encoding="utf-8")).get("final") is True
    except (ValueError, OSError):
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--destino", required=True, type=pathlib.Path)
    ap.add_argument("--puerto", type=int, default=8098)
    ap.add_argument("--limite", type=float, default=LIMITE_POR_DEFECTO)
    args = ap.parse_args()

    args.destino.parent.mkdir(parents=True, exist_ok=True)
    if args.destino.exists():
        args.destino.unlink()
    Colector.destino = args.destino

    servidor = http.server.ThreadingHTTPServer(("127.0.0.1", args.puerto), Colector)
    # En hilo y no en el hilo principal, porque el principal tiene que poder esperar con
    # `wait`, y esperando en el principal no se atiende ninguna peticion.
    hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
    hilo.start()
    print(f"colector escuchando en http://127.0.0.1:{args.puerto}/", flush=True)

    print(f"esperando el resultado hasta {args.limite:.0f} s...", flush=True)
    llego, final = esperar(args.destino, args.limite)
    servidor.shutdown()

    if not llego:
        print(
            "el colector no ha recibido nada",
            file=sys.stderr,
        )
        return 1
    if not final:
        # Y ESTE MENSAJE ES EL QUE HACE DIAGNOSTICABLE UN FALLO A MEDIAS. Sin el, un
        # `return 0` por un resultado a medias pareceria que la comprobacion ha ido bien.
        print(
            "ha llegado un resultado pero NO es el ultimo: la sonda no ha terminado. "
            f"El ultimo es {args.destino.name} y hay {CUANTAS[0]} escritura(s) en el "
            "directorio",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
