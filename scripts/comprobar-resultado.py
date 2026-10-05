#!/usr/bin/env python3
"""Comprobar el resultado de la sonda.

Por que un fichero y no dentro del script de shell
==================================================

Porque las reglas que se comprueban son reglas de **logica**, no de shell: cuentas, textos
enteros y comparaciones de un numero con otro. En bash eso se hace con `test` y `=`, que
son comparaciones de cadenas, y comparar 22544384 con 22544384 como cadenas no es
comparar numeros: `"22544384" > "22544385"` es falso, pero `"99999999" < "22544384"` tambien
es falso, porque compara el primer caracter.

Y el texto de Juan 3:16 son 137 caracteres con acentos y parentesis. En bash, comparar eso
con `[ ]` obliga a cuidar comillas y escapes, y el fallo de una comilla de mas es un
"no" en vez de un error: la comprobacion falla sin decir por que.

Por eso: **el shell lanza y recoge, Python razona**. Y el shell imprime siempre lo que
recoge, para que un fallo se pueda leer sin abrir ficheros.

Que se comprueba, y por que
==========================

8.1  Que hay un `resultado` y dice algo. Un resultado ausente es el fallo que hace que
     una comprobacion pase sin comprobar nada.

8.2  Juan 3:16 con el texto **entero**, y Juan 3 con 36 versiculos en pantalla. El texto
     entero es lo que distingue a una aplicacion que lee de verdad de una que pinta un
     ejemplo, y por eso va escrito entero en el shell y no construido aqui.

8.4  Que el manifiesto es del origen real, de la etiqueta publicada, y que los dos
     modulos salen con el tamano que dice `catalog.json`. Sin comprobar los tamanos, un
     manifiesto de una version vieja pasaria: el formato no ha cambiado en `v0.1.1`, asi
     que el tamano es lo que delata que es otro.

7.5  Que `history.length` crece al cambiar de capitulo y NO al cambiar de version. Es lo
     unico que se puede comprobar en el navegador y en ningun otro sitio.

8.3  Que en un perfil limpio se baja el modulo entero y que en el segundo, con el mismo
     perfil, se bajan 0 bytes.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

# Cuantos versiculos tiene Juan 3 en el KJV. Se comprueba en el navegador y tambien en
# `lector_view_model_test.dart`, y esta duplicado a proposito: si el texto del modulo
# cambia y no cambian los dos sitios, los dos fallan, que es lo que tiene que pasar. Una
# constante compartida en `lib/` seria lo contrario: cambiaria con el texto y ninguna de
# las dos comprobaciones se enteraria.
JUAN3 = 36


class Comprobacion:
    def __init__(self, etiqueta: str) -> None:
        self.etiqueta = etiqueta
        self.fallos: list[str] = []
        self.notas: list[str] = []

    def exigir(self, condicion: bool, motivo: str) -> None:
        if not condicion:
            self.fallos.append(motivo)

    def nota(self, texto: str) -> None:
        self.notas.append(texto)

    def imprimir(self) -> None:
        # Y LOS FALLOS ANTES QUE LOS "OK", y los "ok" solo si no hay fallos. La primera
        # version imprimia las dos listas y salia con codigo 1, de modo que un fallo
        # ensenaba "ok: Juan 3:16 leido de un .amod real" **debajo** de "el texto del
        # versiculo 16 no es el de Juan 3:16". Dos lineas que se contradicen, y la que
        # dice "ok" es la que se lee ultimo.
        if self.fallos:
            print(f"FALLO ({self.etiqueta}):", file=sys.stderr)
            for f in self.fallos:
                print(f"  - {f}", file=sys.stderr)
            sys.exit(1)
        for n in self.notas:
            print(f"    ok: {n}")


def leer(path: str) -> dict:
    p = pathlib.Path(path)
    if not p.exists() or p.stat().st_size == 0:
        print(f"no hay resultado en {path}", file=sys.stderr)
        sys.exit(1)
    return json.loads(p.read_text(encoding="utf-8"))


def comprobar_pasaje(c: Comprobacion, d: dict, juan316: str) -> None:
    """8.2 y 8.4: el texto, el capitulo, los terminos y el manifiesto."""
    c.exigir(
        d.get("resultado") == "ok",
        f"resultado: {d.get('resultado')!r} / motivo: {d.get('motivo')!r}",
    )
    c.exigir(
        d.get("pasaje") == d.get("pasajeEsperado") == "John.3.16",
        f"el pasaje es {d.get('pasaje')!r} y se pedia {d.get('pasajeEsperado')!r}",
    )
    c.exigir(
        d.get("texto") == juan316,
        "el texto del versiculo 16 no es el de Juan 3:16:\n"
        f"      esperado: {juan316!r}\n"
        f"      obtenido: {d.get('texto')!r}",
    )
    # Y EL VERSICULO PEDIDO TRAE UNO, porque es un versiculo. Y ESO NO ES QUE JUAN 3
    # TENGA UN: es que se ha pedido uno. Por eso el numero de verdad del capitulo va en
    # `capituloEntero`, y es el que se comprueba contra 36.
    #
    # La primera version de esta comprobacion miraba `versiculosEnElCapitulo` y pedia 36,
    # con lo que fallaba siempre con "Juan 3 sale con 1 versiculos". El nombre del campo
    # era el equivocado y por eso la sonda ahora manda los dos.
    c.exigir(
        d.get("versiculosEnElPasaje") == 1,
        f"el pasaje pedido trae {d.get('versiculosEnElPasaje')} versiculos y, siendo un "
        f"versiculo, deberia traer 1",
    )
    cap = d.get("capituloEntero") or {}
    c.exigir(
        cap.get("libro") == "John" and cap.get("capitulo") == 3,
        f"el capitulo entero se pidio de {cap.get('libro')} {cap.get('capitulo')}, no de Juan 3",
    )
    c.exigir(
        cap.get("versiculos") == JUAN3,
        f"Juan 3 sale con {cap.get('versiculos')} versiculos en el navegador, no {JUAN3}",
    )
    c.exigir(
        d.get("titulo") == "Juan 3:16",
        f"el titulo es {d.get('titulo')!r}, no 'Juan 3:16'",
    )
    c.exigir(
        d.get("modulo") == "KJV2006",
        f"el modulo abierto es {d.get('modulo')!r}, no KJV2006",
    )
    c.nota(
        f"Juan 3:16 leido de un .amod real, y Juan 3 sale con "
        f"{cap.get('versiculos')} versiculos"
    )

    # Y los terminos. Salieron de la tabla `info` del `.amod`, no del manifiesto: es la
    # unica comprobacion de que la tabla `info` se lee de verdad y no de memoria.
    t = d.get("terminos") or {}
    c.exigir(t.get("licencia") == "PublicDomain",
             f"la licencia leida del modulo es {t.get('licencia')!r}")
    # Y EN MINUSCULAS LOS DOS LADOS, porque el texto real es `eBible.org` con mayuscula y
    # la busqueda es sin distincion. La primera version comparaba `"ebible.org" in
    # "eBible.org (eng-kjv2006). Dominio publico."`, que es falso en Python, y decia que
    # la atribucion no estaba cuando estaba ahi entera.
    c.exigir("ebible.org" in (t.get("atribucion") or "").lower(),
             f"la atribucion leida del modulo es {t.get('atribucion')!r}")
    c.exigir(t.get("versificacion") == "KJV",
             f"la versificacion leida del modulo es {t.get('versificacion')!r}")
    c.exigir(t.get("defectos") == 0,
             f"el KJV declara {t.get('defectos')} defectos y deberia declarar 0")
    c.exigir(t.get("discrepancia") is None,
             f"el manifiesto y el modulo discrepan de licencia: {t.get('discrepancia')!r}. "
             f"Con el KJV publicado no deberían")
    c.nota("terminos leidos de la tabla `info` del modulo, sin discrepancia con el indice")

    # 8.4: el manifiesto.
    cat = d.get("catalogo") or {}
    c.exigir(
        cat.get("etiqueta") == c.etiqueta_esperada,
        f"la etiqueta del catalogo es {cat.get('etiqueta')!r} y lo publicado es "
        f"{c.etiqueta_esperada!r}",
    )
    # Y DE QUE VIENE EL MANIFIESTO, QUE NO ES LO MISMO QUE DE DONDE SE BUSCA.
    #
    # `origen` es la direccion --en la comprobacion local, el proxy--, y `estado` es si
    # lo que se enseena vino del servidor o de una copia guardada. Lo que comprueba la
    # 8.4 es lo segundo: un manifiesto de una copia guardada es de ayer, por muy bien que
    # se haya leido.
    #
    # Y NO SE COMPRUEBA CON LOS AVISOS, y hay que decirlo porque es lo que se hizo la
    # primera vez y fallaba siempre: los avisos incluyen los de la descarga --"Bajando
    # KJV2006: 50 por ciento"--, y despues de una descarga **siempre** hay alguno.
    c.exigir(
        cat.get("estado") == "delServidor",
        f"el manifiesto vino como {cat.get('estado')!r} y deberia venir del servidor: una "
        f"copia guardada es el manifiesto de un dia anterior",
    )
    c.nota(f"manifiesto del servidor, etiqueta {cat.get('etiqueta')}")
    modulos = {m["id"]: m for m in cat.get("modulos", [])}
    # Y EL ID DEL COMENTARIO ES `CLARKE`, NO `CLARKE_commentary`. El **nombre del
    # fichero** es `CLARKE_commentary.amod` y el `id` del manifiesto es `CLARKE`. La
    # primera version busco el nombre del fichero y por eso decia que el modulo ocupaba
    # `None` bytes, cuando el manifiesto lo tiene ahi con los 57.536.512. Es la misma
    # confusion que se quiere evitar en el codigo --la clave del modulo es suya--, y aqui
    # se ha cayendo justo en ella.
    for ident, esperado in (
        ("KJV2006", c.bytes_kjv),
        ("CLARKE", c.bytes_clarke),
    ):
        obtenido = modulos.get(ident, {}).get("bytes")
        c.exigir(
            obtenido == esperado,
            f"{ident} ocupa {obtenido} bytes y el catalogo publicado dice {esperado}",
        )
    c.exigir(
        "KJV2006" in (cat.get("idsLocales") or []),
        f"despues de leer, KJV2006 no esta en el dispositivo: {cat.get('idsLocales')!r}",
    )
    c.nota(
        f"{len(modulos)} modulos con el tamano que dice el catalogo publicado, leidos "
        f"de {cat.get('origen')}"
    )


def comprobar_pareja(c: Comprobacion, d: dict, juan316: str) -> None:
    """El versiculo con el comentario al lado.

    Y SON DOS COMPROBACIONES Y NO UNA, porque son dos modulos y cada uno puede fallar por
    su cuenta. Lo que se mira aqui es que esten **los dos**: el versiculo entero del
    KJV2006 y una nota del CLARKE debajo.
    """
    c.exigir(
        d.get("resultado") == "ok",
        f"resultado: {d.get('resultado')!r} / motivo: {d.get('motivo')!r}",
    )
    # Y EL TEXTO DE LA BIBLIA SIGUE SIENDO EL DE JUAN 3:16. Es la parte que se puede
    # romper por ir a por el comentario: abrir un segundo `.amod` de 57 MiB y volver a
    # pintar puede tragarse el texto que ya estaba.
    c.exigir(
        d.get("texto") == juan316,
        "el versiculo no se lee entero al poner el comentario al lado:\n"
        f"      esperado: {juan316!r}\n"
        f"      obtenido: {d.get('texto')!r}",
    )
    c.exigir(
        d.get("modulo") == "KJV2006",
        f"el texto abierto es {d.get('modulo')!r}, no KJV2006",
    )
    c.exigir(
        d.get("comentario") == "CLARKE",
        f"el comentario abierto es {d.get('comentario')!r}, no CLARKE",
    )
    # Y LA NOTA DE JUAN 3:16 EMPIEZA POR LO QUE EMPIEZA. Medido sobre el fichero real:
    # "For God so loved the world - Such a love as that which induced God to give his
    # only begotten son to die for the world could not be described".
    nota = d.get("notasAlLadoTexto") or ""
    c.exigir(
        nota.startswith("For God so loved the world - Such a love as that"),
        f"la nota de Juan 3:16 no empieza como deberia: {nota[:80]!r}",
    )
    # Y EL NUMERO: Juan 3:16 tiene **una** nota en el CLARKE, no tres. Esto se escribio
    # mal una vez --midiendo la clave primaria en vez de contando filas-- y por eso el
    # numero va comprobado aqui, en el navegador, contra el fichero real.
    c.exigir(
        d.get("notasAlLadoDelPasaje") == 1,
        f"Juan 3:16 trae {d.get('notasAlLadoDelPasaje')} notas al lado y trae una",
    )
    # Y JUAN 3 TIENE 32 CON NOTA DE 36 QUE TIENE TEXTO, medido.
    c.exigir(
        d.get("versiculosConNotaAlLadoEnElCapitulo") == 32,
        f"Juan 3 sale con {d.get('versiculosConNotaAlLadoEnElCapitulo')} versiculos con "
        f"nota en el comentario, y son 32 de 36",
    )
    c.exigir(
        not d.get("motivoDelComentario"),
        f"hay un aviso del comentario que no deberia: {d.get('motivoDelComentario')!r}",
    )


def comprobar_historial(c: Comprobacion, d: dict) -> None:
    """7.5 en el navegador: `history.length`."""
    h = d.get("historial") or {}
    if not h.get("medido"):
        c.exigir(False, f"el historial no se ha podido medir: {h.get('motivo')!r}")
        return

    antes = h["antes"]
    tras_cap = h["trasCambioDeCapitulo"]
    tras_ajuste = h["trasCambioDeAjuste"]
    tras_otro = h["trasOtroCambioDeCapitulo"]

    c.exigir(
        isinstance(antes, int),
        f"el historial antes de medir es {antes!r}, no un numero. Sin `history` no se "
        f"puede comprobar la 7.5, y eso hay que verlo",
    )
    if not isinstance(antes, int):
        return

    c.exigir(
        tras_cap == antes + 1,
        f"cambiar de capitulo deberia anadir una entrada al historial: {antes} -> "
        f"{tras_cap}. Sin eso, 'atras' no volveria al capitulo anterior",
    )
    c.exigir(
        tras_ajuste == tras_cap,
        f"cambiar un ajuste NO deberia tocar el historial: {tras_cap} -> {tras_ajuste}. "
        f"Sin eso, 'atras' desharia el ajuste, que es justo lo que no debe pasar",
    )
    c.exigir(
        tras_otro == tras_cap + 1,
        f"el segundo cambio de capitulo deberia anadir otra entrada: {tras_cap} -> "
        f"{tras_otro}",
    )
    c.nota(
        f"historial {antes} -> {tras_cap} (capitulo, pushState) -> {tras_ajuste} "
        f"(ajuste, replaceState) -> {tras_otro} (capitulo otra vez)"
    )


def comprobar_descarga(c: Comprobacion, d: dict, bytes_kjv: int, limpio: bool) -> None:
    """8.3."""
    bajos = d.get("bytesDescargados")
    if limpio:
        c.exigir(
            bajos == bytes_kjv,
            f"en un perfil limpio se han bajado {bajos} bytes y el modulo ocupa "
            f"{bytes_kjv}. Con 0 bytes seria que el texto estaba en el almacenamiento y "
            f"la comprobacion no habria descargado nada",
        )
        c.nota(f"bajados {bajos} bytes en un perfil limpio")
    else:
        c.exigir(
            bajos == 0,
            f"en la segunda ejecucion se han bajado {bajos} bytes y deberian ser 0: el "
            f"modulo de {bytes_kjv} bytes estaba en el almacenamiento del perfil",
        )
        c.nota("0 bytes bajados: el modulo salio del almacenamiento del navegador")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--primera", default="")
    ap.add_argument("--segunda", default="")
    ap.add_argument("--pareja", default="")
    ap.add_argument("--juan316", required=True)
    ap.add_argument("--etiqueta", required=True)
    ap.add_argument("--bytes-kjv", type=int, required=True)
    ap.add_argument("--bytes-clarke", type=int, required=True)
    ap.add_argument("--perfil-limpio", action="store_true")
    args = ap.parse_args()

    c = Comprobacion("pareja" if args.pareja else ("primera" if args.primera else "segunda"))
    c.etiqueta_esperada = args.etiqueta
    c.bytes_kjv = args.bytes_kjv
    c.bytes_clarke = args.bytes_clarke

    if args.primera:
        d = leer(args.primera)
        comprobar_pasaje(c, d, args.juan316)
        comprobar_historial(c, d)
        comprobar_descarga(c, d, args.bytes_kjv, limpio=True)
    if args.segunda:
        d = leer(args.segunda)
        # De la segunda ejecucion se comprueba lo minimo --que el texto sale y que no
        # se baja nada--. Volver a comprobar el manifiesto y el historial aqui seria
        # medir otra vez lo mismo y tapar el dato de la 8.3, que es lo unico que la
        # segunda aporta.
        comprobar_pasaje(c, d, args.juan316)
        comprobar_descarga(c, d, args.bytes_kjv, limpio=False)
    if args.pareja:
        d = leer(args.pareja)
        # Y DEL KJV SOLO SE COMPRUEBA QUE **NO** SE VUELVE A BAJAR: la tercera ejecucion
        # reutiliza el perfil de las dos primeras, asi que el texto sale del
        # almacenamiento. Lo que tiene que bajar es el CLARKE, que es lo nuevo.
        comprobar_pareja(c, d, args.juan316)
        comprobar_historial(c, d)
        # Y LA TERCERA EJECUCION BAJA **SOLO** EL CLARKE. Reutiliza el perfil de las dos
        # primeras, asi que el KJV2006 sale del almacenamiento del navegador y lo unico
        # que se baja son los 57 MiB del comentario. Y por eso la comprobacion es "son
        # los del CLARKE" y no "son 0": son 0 solo si el comentario tambien estaba.
        bajos = d.get("bytesDescargados")
        c.exigir(
            bajos == args.bytes_clarke,
            f"en la tercera ejecucion se han bajado {bajos} bytes y deberian ser los "
            f"{args.bytes_clarke} del comentario: el texto de {args.bytes_kjv} estaba "
            f"en el perfil",
        )
        c.nota(f"bajados {bajos} bytes del comentario, y el texto venia del perfil")

    c.imprimir()
    return 0


if __name__ == "__main__":
    sys.exit(main())
