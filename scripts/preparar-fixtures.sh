#!/usr/bin/env bash
# Descargar los modulos REALES que usan las pruebas, y comprobar que son los de
# verdad.
#
# POR QUE ESTE SCRIPT Y NO COMMITEAR LOS FICHEROS. Un `.amod` son 22 MiB y 57 MiB.
# Meterlos en el repositorio duplicaria el contenido --que es justo lo que este
# repositorio no hace-- y ademas los fijaria a una version, con lo que las
# pruebas dejarian de comprobar lo que se publica hoy.
#
# Y POR QUE NO HAY UN "SI NO ESTA, SALTARSE". Una prueba que se salta no verifica
# nada, y una suite donde media parte se salta en el sitio donde mas importa es
# una suite que da verde sin comprobar. Aqui no hay dos ramas: o el modulo esta y
# su hash cuadra, o el comando falla y el grupo entero falla.
#
# QUE COMPRUEBA, EN ORDEN:
#
#  1. Que el indice (`latest.json`) se puede leer.
#  2. Que el manifiesto (`catalog.json`) **cuadra con el hash que anuncia el
#     indice**. Es la misma comprobacion que hace la app, y por el mismo motivo: un
#     manifiesto que no cuadra podria declarar un sha256 equivocado para un
#     modulo, y entonces las pruebas estarian comprobando un fichero que nadie ha
#     verificado.
#  3. Que cada `.amod` descargado **cuadra con el sha256 de su entrada**. Si no
#     cuadra, se borra lo descargado y se falla: dejar un fichero a medio bajar
#     seria la manera de que la siguiente ejecucion cyan en un sitio distinto.
#
# DE DONDE VIENEN. Del **sitio de GitHub Pages**, no de la release. Es el mismo
# origen que usa la app en el navegador, y por eso este script ejercita el camino
# de verdad en vez de un camino paralelo. Ver `docs/investigacion/transporte-cors.md`.

set -euo pipefail

ORIGEN="${AB_ORIGEN_CATALOGO:-https://yojananyosef.github.io/aa}"
DESTINO="${AB_FIXTURES:-test/fixtures}"
SOLO="${1:-}"

# Los hashes de verdad, medidos. Se comparan con los que declara el manifiesto
# publicado, y ademas con estos, para que un manifiesto alterado que se llevase
# bien un modulo nuestro no pase: son dos comprobaciones independientes y por eso
# el fallo es visible.
declare -A HASH_ESPERADO=(
  [KJV2006_bible.amod]=ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9
  [CLARKE_commentary.amod]=3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c
)

log() { printf '%s\n' "$*" >&2; }

fallar() {
  log "FALLO: $*"
  exit 1
}

mkdir -p "$DESTINO"

# --- 1. el indice -----------------------------------------------------------
log "==> indice en $ORIGEN/latest.json"
INDICE="$DESTINO/latest_real.json"
curl -fsSL --retry 3 --retry-delay 2 "$ORIGEN/latest.json" -o "$INDICE" \
  || fallar "no se ha podido leer $ORIGEN/latest.json"

# Sin python ni jq: el indice tiene una forma fija y conocida, y las pruebas de
# este repositorio no depended de jq. Si algun dia se anaden campos, esto se
# quieta de aqui y no de ningun otro sitio.
leer_campo() {
  # $1 = nombre del campo. Lee de la ENTRADA ESTANDAR, no de un fichero: se usa
  # como `leer_campo tag < fichero`, y el guion es lo que le dice a `sed` que lea de
  # ahi. La primera version pasaba "$1" como nombre de fichero, o sea que buscaba
  # un fichero llamado `browserUrl`, y el error era un "no existe" que no
  # señalaba la causa.
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" - | head -1
}

URL_MANIFIESTO="$(leer_campo browserUrl < "$INDICE")"
HASH_MANIFIESTO="$(leer_campo catalogSha256 < "$INDICE")"
ETIQUETA="$(leer_campo tag < "$INDICE")"

[ -n "$URL_MANIFIESTO" ] || fallar "el indice no declara browserUrl"
[ -n "$HASH_MANIFIESTO" ] || fallar "el indice no declara catalogSha256"
[ -n "$ETIQUETA" ] || fallar "el indice no declara tag"
log "    release $ETIQUETA"

# --- 2. el manifiesto, con su hash ------------------------------------------
log "==> manifiesto en $URL_MANIFIESTO"
MANIFIESTO="$DESTINO/catalog_real.json"
curl -fsSL --retry 3 --retry-delay 2 "$URL_MANIFIESTO" -o "$MANIFIESTO" \
  || fallar "no se ha podido leer $URL_MANIFIESTO"

OBTENIDO="$(sha256sum "$MANIFIESTO" | cut -d' ' -f1)"
if [ "$OBTENIDO" != "$HASH_MANIFIESTO" ]; then
  rm -f "$MANIFIESTO"
  fallar "el manifiesto no es el que anuncia el indice.
    esperado: $HASH_MANIFIESTO
    obtenido: $OBTENIDO"
fi
log "    hash del manifiesto: ok"

# --- 3. los modulos ---------------------------------------------------------
# El manifiesto se lee aqui con `sed` porque en un runner no hay ni python ni jq
# garantizados, y porque leerlo a mano obliga a que el nombre de cada campo salga
# en un sitio y no repartido por el codigo.
leer_browser_url() {
  # La URL se usa **tal cual**, sin quitarle el esquema ni el host ni nada. La
  # primera version le quitaba el esquema y el host y luego volvia a ponerselos
  # delante de "$ORIGEN", y como el origen ya trae el prefijo `/aa` salia una URL
  # con `/aa/aa/` y un 404. Usarla entera es ademas lo correcto: es la direccion
  # que declara el catalogo, sin reescribirla.
  sed -n 's/.*"browserUrl"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFIESTO"
}

leer_sha256() {
  sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFIESTO"
}

i=0
mapfile -t RUTAS < <(leer_browser_url)
mapfile -t HASHES < <(leer_sha256)
[ "${#RUTAS[@]}" -eq "${#HASHES[@]}" ] \
  || fallar "el manifiesto declara ${#RUTAS[@]} URLs y ${#HASHES[@]} hashes: no se puede emparejar"

for i in "${!RUTAS[@]}"; do
  ruta="${RUTAS[$i]}"
  esperado="${HASHES[$i]}"
  nombre="$(basename "$ruta")"
  destino="$DESTINO/$nombre"

  if [ -n "$SOLO" ] && [ "$SOLO" != "$nombre" ]; then
    log "==> $nombre: omitido por peticion"
    continue
  fi

  # Si ya esta y cuadra, no se vuelve a bajar. En un runner nuevo siempre hay que
  # bajarlos, pero en local esto hace que la suite no descargue 80 MiB cada vez.
  if [ -f "$destino" ]; then
    actual="$(sha256sum "$destino" | cut -d' ' -f1)"
    if [ "$actual" = "$esperado" ]; then
      log "==> $nombre: ya esta y cuadra"
      continue
    fi
    log "==> $nombre: esta pero no cuadra, se vuelve a bajar"
    rm -f "$destino"
  fi

  log "==> bajando $nombre desde $ruta"
  # Un fichero temporal y `mv` al final: si la descarga se corta a la mitad, queda
  # un `.parcial` y no un `.amod` truncado con nombre de bueno. Un modulo truncado
  # en el fixture seria un fallo que aparece en una prueba que no lo busca.
  curl -fsSL --retry 3 --retry-delay 2 "$ruta" -o "$destino.parcial" \
    || { rm -f "$destino.parcial"; fallar "no se ha podido bajar $ruta"; }

  actual="$(sha256sum "$destino.parcial" | cut -d' ' -f1)"
  if [ "$actual" != "$esperado" ]; then
    rm -f "$destino.parcial"
    fallar "el modulo descargado no es el que declara el manifiesto.
      modulo:   $nombre
      esperado: $esperado
      obtenido: $actual"
  fi

  # Segunda comprobacion, independiente del manifiesto. Si alguien alterase el
  # manifiesto para que cuadrase con un fichero nuestro, esta linea lo dira.
  if [ -n "${HASH_ESPERADO[$nombre]:-}" ] && [ "${HASH_ESPERADO[$nombre]}" != "$actual" ]; then
    rm -f "$destino.parcial"
    fall "el modulo no es el que se conocia de verdad.
      modulo:   $nombre
      esperado: ${HASH_ESPERADO[$nombre]}
      obtenido: $actual"
  fi

  mv "$destino.parcial" "$destino"
  log "    $nombre: $(stat -c%s "$destino") bytes, hash ok"
done

log ""
log "FIXTURES LISTOS en $DESTINO:"
for f in "$DESTINO"/*.amod; do
  [ -e "$f" ] || continue
  log "  $(basename "$f")  $(stat -c%s "$f") bytes  $(sha256sum "$f" | cut -c1-16)..."
done
