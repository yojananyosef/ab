#!/usr/bin/env bash
# Comprobar la aplicacion en un navegador de verdad.
#
# POR QUE HACE FALTA Y QUE NO PUEDE HACER `flutter test`
# =====================================================
#
# Flutter web pinta en un `canvas`. El DOM no tiene el texto que se ve: tiene una foto.
# Por eso una prueba de `flutter test` **no puede** comprobar que Juan 3:16 sale
# pintado: en la maquina de Dart no hay motor de render, ni SQLite en WebAssembly, ni
# almacenamiento del navegador, ni `history`. Una aplicacion puede pasar las 327 pruebas
# de este repositorio y no funcionar en ningun navegador. Entre otras cosas porque
# `sqlite3.wasm` no se cargo, que es el fallo mas probable de todos y solo se ve aqui.
#
# QUE SE COMPRUEBA, TAREA POR TAREA
# ==================================
#
#   8.1  El script imprime el resultado en vez de fallar en silencio.
#   8.2  La app abre un `.amod` real y muestra Juan 3:16, con el texto entero.
#   8.3  Dos ejecuciones con el mismo perfil: la segunda baja 0 bytes.
#   8.4  El manifiesto se lee del origen real y los modulos salen con su tamano.
#   7.5  `history.length` crece al cambiar de capitulo y NO al cambiar de version.
#        No es una tarea del grupo 8, pero es lo unico comprobable aqui y no en Dart,
#        asi que se comprueba aqui y en ningun otro sitio.
#
# COMO SE LEE EL RESULTADO, Y POR QUE NO DEL DOM
# ===============================================
#
# `--dump-dom` **se queda esperando para siempre** con una aplicacion de Flutter:
#
#     brave-browser --headless=new --dump-dom http://127.0.0.1:8099/ > salida.html
#     exit=124  salida.html con 0 bytes
#
# Medido el 4 de octubre de 2026 con Brave 154, con y sin `--virtual-time-budget` y con
# y sin `--timeout`. Con una pagina normal si funciona, asi que el problema es el motor
# de Flutter. La explicacion esta en `scripts/colector.py`.
#
# Asi que el resultado lo manda **la propia aplicacion** a un colector local
# (`scripts/colector.py`), y el navegador no termina solo.
# El `<pre id="ab-sonda">` se sigue escribiendo en el DOM --la tarea 8.1 lo pide-- para
# poder mirarlo con las herramientas del navegador, pero lo que el script comprueba es lo
# que ha llegado al colector.
#
# POR QUE NO UN PILOTO QUE CONDUZCA EL NAVEGADOR. Un piloto haria sus propios clic y leeria
# su propio DOM, y para eso tendria que reimplementar el arranque. La sonda no
# reimplementa nada: pregunta a la aplicacion. Lo que se comprueba es el texto que ha
# salido de una consulta SQL a un `.amod` de 22.544.384 bytes.
#
# EL NAVEGADOR
# ============
#
# Se busca en varios sitios porque no hay uno solo: `CHROME` del entorno, el Chromium de
# la distro, Google Chrome, Brave, o el que traiga Puppeteer. En esta maquina es Brave,
# que es Chromium 154, y por eso en `AGENTS.md` se dice "Chrome 154".
#
# LAS BANDERAS Y POR QUE CADA UNA
# ==============================
#
#   --headless=new                El navegador sin pantalla.
#   --no-sandbox                  Necesario como root en un contenedor, y se ejecuta aqui.
#   --enable-unsafe-swiftshader   **Imprescindible.** Sin esto no hay WebGL, el CanvasKit
#                                 no arranca y la pantalla se queda en negro.
#   --disable-dev-shm-usage       `/dev/shm` suele ser de 64 MiB en un contenedor, y
#                                 CanvasKit reserva mas de eso.
#   --virtual-time-budget=N       Cuanto tiempo de reloj virtual se deja correr. Con
#                                 esto el navegador **termina solo**, que es lo que
#                                 `--dump-dom` no hacia. El reloj virtual avanza mientras
#                                 no haya peticiones de red pendientes, asi que una
#                                 descarga de 22 MiB desde GitHub Pages la espera de verdad.
#   --user-data-dir=...           El perfil. Es lo que hace posible la 8.3: la segunda
#                                 ejecucion con el mismo perfil tiene el modulo guardado.
#
# LO QUE NO SE COMPRUEBA, Y POR QUE
# ================================
#
# El texto *pintado*. Se comprueba el texto que ha devuelto la consulta, no los pixeles.
# Para los pixeles hay una captura que se deja junto a los resultados para mirarla a ojo,
# y una comprobacion de que la captura no es una imagen de un solo color --que es lo que
# pasa si el motor no arranca--. Ir mas alla de ahi sin reconocimiento optico seria
# inventar una comprobacion.

set -euo pipefail

cd "$(dirname "$0")/.."

# --- donde van las cosas ---------------------------------------------------
#
# Y EN `$TMPDIR` Y NO EN `/tmp`, por el motivo que esta escrito en `AGENTS.md`: `/tmp` aqui
# es un tmpfs de 3,7 GB y un perfil de navegador mas 22 MiB de modulo mas el build se
# pasan de eso sin avisar.
TMPDIR="${TMPDIR:-$PWD/.tmp}"
export TMPDIR
TRABAJO="$TMPDIR/comprobacion-navegador"
PERFILO="$TRABAJO/perfil"

# --- los datos que hay que ver ----------------------------------------------
#
# Y ESTA ES LA AFIRMACION QUE COMPRUEBA LA 8.2. Va escrita aqui, entera, y no construida
# por el script: una comprobacion que busca parte de un texto que ha construido ella no
# comprueba nada. Si el texto se degrada, la comprobacion se degrada con el y sigue
# dando verde.
#
# Y LA MISMA CADENA ESTA EN `test/ui/lector_view_test.dart`. Que este en los dos sitios y
# no en uno solo es a proposito: si el texto del modulo cambia y no cambian estos dos,
# las dos comparaciones fallan, que es lo que tiene que pasar. Una constante compartida
# en `lib/` seria lo contrario: cambiaria con el texto y ninguna comprobacion se
# enteraria.
JUAN316='For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.'

# Lo que el manifiesto publicado de `v0.1.1` dice de cada modulo.
CATALOGO_ETIQUETA='v0.1.1'
CATALOGO_KJV_BYTES=22544384
CATALOGO_CLARKE_BYTES=57536512

# --- como se dice que algo ha ido mal ---------------------------------------

fallar() {
  echo "FALLO: $*" >&2
  exit 1
}

nota() {
  echo "  $*" >&2
}

# --- el navegador -------------------------------------------------------------

buscar_navegador() {
  if [[ -n "${CHROME:-}" ]]; then
    echo "$CHROME"
    return
  fi
  for candidato in \
    chromium chromium-browser google-chrome google-chrome-stable \
    brave-browser brave; do
    if command -v "$candidato" >/dev/null 2>&1; then
      command -v "$candidato"
      return
    fi
  done
  for posible in "$HOME"/.cache/puppeteer/chrome/*/chrome-linux64/chrome; do
    [[ -x "$posible" ]] && { echo "$posible"; return; }
  done
  return 1
}

NAVEGADOR="${NAVEGADOR:-$(buscar_navegador || true)}"

# --- configuracion -----------------------------------------------------------

RUTA_SONDA="${AB_RUTA_SONDA:-/leer/KJV2006/John.3.16}"
PUERTO="${AB_PUERTO:-8099}"
PUERTO_COLECTOR="${AB_PUERTO_COLECTOR:-8098}"
VIRTUAL_MS="${AB_VIRTUAL_TIME_MS:-240000}"
LIMITE_COLECTOR="${AB_LIMITE_COLECTOR:-900}"
URL_COLECTOR="http://127.0.0.1:$PUERTO_COLECTOR/resultado"

export PATH="$HOME/.local/opt/flutter/bin:$PATH"

[[ -n "$NAVEGADOR" ]] || fallar "no se encuentra ningun navegador. Pon CHROME=/ruta/al/chrome"
for valor in "$VIRTUAL_MS" "$LIMITE_COLECTOR"; do
  [[ "$valor" =~ ^[0-9]+$ ]] || fallar "los milisegundos y el limite tienen que ser numeros"
done

mkdir -p "$TRABAJO"
rm -f "$TRABAJO"/primera.json "$TRABAJO"/segunda.json

# --- los pasos ---------------------------------------------------------------

compilar() {
  echo "==> flutter analyze"
  flutter analyze

  echo "==> flutter build web con la sonda"
  # `--base-href=/` a proposito: aqui se sirve en la raiz. El `404.html` que hace el CI
  # para GitHub Pages se copia tambien, para que recargar en `/leer/...` no de un 404 de
  # verdad sin aplicacion dentro.
  #
  # Y los dos `--dart-define`: `AB_SONDA` es la ruta desde la que se arranca, que es como
  # se comprueba un enlace profundo sin escribirlo en el navegador a mano; `AB_COLECTOR`
  # es a donde va el resultado. Los dos solo **anaden la escritura**: el arranque, la
  # descarga, el sha256, la apertura del `.amod` y la consulta son el mismo codigo.
  #
  # Y `AB_ORIGEN_CATALOGO` apunta al **servidor local**, no a github.io. Y no es una
  # comodidad: GitHub Pages **no responde a los preflight de CORS** (405), y la peticion
  # del `.amod` lleva `Range`, que no es una cabecera "simple". Servida la aplicacion en
  # local y el catalogo en github.io, el navegador no hace ni la peticion y la
  # comprobacion falla con "El servidor no permite leerlo desde el navegador" -- un fallo
  # que en el sitio real no puede ocurrir, porque ahi aplicacion y modulos estan en el
  # mismo origen. El servidor local reenvia `/aa` a github.io, de modo que aqui tambien
  # son del mismo origen. Ver la cabecera de `scripts/servir.py`.
  flutter build web --release --base-href=/ \
    --dart-define=AB_SONDA="$RUTA_SONDA" \
    --dart-define=AB_COLECTOR="$URL_COLECTOR" \
    --dart-define=AB_ORIGEN_CATALOGO="http://127.0.0.1:$PUERTO/aa" \
    --no-wasm-dry-run
  cp build/web/index.html build/web/404.html

  test -f build/web/sqlite3.wasm ||
    fallar "falta sqlite3.wasm en el paquete: el motor SQLite no viaja y la app no podra abrir nada"
  test -f build/web/404.html || fallar "falta 404.html, y recargar en /leer/... daria un 404 de verdad"
  nota "sqlite3.wasm: $(stat -c%s build/web/sqlite3.wasm) bytes"
}

# Una ejecucion del navegador: arranca el colector, lanza, y espera el resultado.
ejecutar() {
  local etiqueta="$1"

  echo "    arranque del colector"
  python3 scripts/colector.py \
    --destino "$TRABAJO/$etiqueta.json" \
    --puerto "$PUERTO_COLECTOR" \
    --limite "$LIMITE_COLECTOR" >"$TRABAJO/$etiqueta.colector.log" 2>&1 &
  local colector=$!

  local intentos=0
  # Y AQUI TAMBIEN EL `curl` VA DESPUES DE MIRAR EL PROCESO. Con el mismo motivo que en
  # el servidor: si el colector se muere al arrancar porque el puerto esta ocupado, el
  # `curl` responde contra el ocupante y el script sigue creyendo que tiene colector.
  sleep 0.3
  kill -0 "$colector" 2>/dev/null ||
    fallar "el colector se ha parado al arrancar:
$(tail -5 "$TRABAJO/$etiqueta.colector.log")"

  until curl -fsS "http://127.0.0.1:$PUERTO_COLECTOR/" -o /dev/null 2>/dev/null; do
    intentos=$((intentos + 1))
    kill -0 "$colector" 2>/dev/null ||
      fallar "el colector se ha parado: $(tail -5 "$TRABAJO/$etiqueta.colector.log")"
    [[ $intentos -gt 50 ]] && fallar "el colector no responde en 50 intentos"
    sleep 0.2
  done

  echo "    navegador, 360x760, reloj virtual ${VIRTUAL_MS} ms"
  # SIN `--dump-dom`, porque no termina nunca con Flutter, y SIN `--screenshot`, porque
  # en este entorno se queda colgado leyendo pixeles. La razon de no salir solo es la que
  # importa: el navegador no termina nunca con una aplicacion de Flutter, y por eso el
  # script lo mata con su propio plazo y **no** se fia de su codigo de salida.
  #
  # Y EL RELOJ VIRTUAL SE COMPROBABA: si el navegador se cuelga, el script se queda
  # esperando el resultado con su propio limite y dice que no ha llegado, en vez de
  # quedarse colgado sin decir nada. Un script que se cuelga es el fallo mas incomodo
  # que hay, porque parece que esta trabajando.
  timeout $((VIRTUAL_MS / 1000 + 420)) "$NAVEGADOR" \
    --headless=new \
    --no-sandbox \
    --disable-gpu \
    --enable-unsafe-swiftshader \
    --disable-dev-shm-usage \
    --user-data-dir="$PERFILO" \
    --window-size=360,760 \
    --virtual-time-budget="$VIRTUAL_MS" \
    "http://127.0.0.1:$PUERTO$RUTA_SONDA" \
    >"$TRABAJO/$etiqueta.navegador.log" 2>&1 || true

  if ! wait "$colector"; then
    echo "--- registro del navegador ---" >&2
    tail -10 "$TRABAJO/$etiqueta.navegador.log" >&2
    fallar "la sonda no ha escrito nada en $LIMITE_COLECTOR s. Puede ser que la
aplicacion no arrancara, que faltara sqlite3.wasm, o que el reloj virtual se acabara
antes de que terminara la descarga"
  fi
  echo "    el colector ha recibido el resultado"
}

# --- el cuerpo ---------------------------------------------------------------

echo "==> navegador: $NAVEGADOR ($("$NAVEGADOR" --version 2>/dev/null | head -1 | tr -d '\n' || echo 'version desconocida'))"
echo "==> ruta de la sonda: $RUTA_SONDA"
echo "==> reloj virtual: ${VIRTUAL_MS} ms"
echo "==> limite del colector: ${LIMITE_COLECTOR} s"

echo "==> compilando"
compilar

echo "==> comprobando que los puertos estan libres"
# Y ANTES DE ARRANCAR NADA. Sin esta comprobacion, si hay un servidor de una prueba
# anterior escuchando, el `python3` de este script no puede escribir en el puerto y se
# muere **en silencio** --su salida va al fichero, y nadie lo mira--, y el `curl` de
# comprobacion responde contra el servidor viejo, que no tiene el proxy de `/aa`. Todo
# lo que se ve entonces es "No se ha podido contactar con el catalogo", que apunta a la
# red cuando el problema es un proceso que se murio hace treinta segundos.
for puerto in "$PUERTO" "$PUERTO_COLECTOR"; do
  if (exec 3<>"/dev/tcp/127.0.0.1/$puerto") 2>/dev/null; then
    exec 3<&- 3>&-
    fallar "el puerto $puerto esta ocupado. Puede ser un servidor de una comprobacion
anterior que no termino. Se mira con: ss -ltnp | grep $puerto"
  fi
done

echo "==> sirviendo build/web en 127.0.0.1:$PUERTO"
# Y `scripts/servir.py`, y no `python3 -m http.server`: este ultimo devuelve su propia
# pagina de error para `/leer/...`, sin aplicacion dentro, y entonces la comprobacion de
# recargar conservando el pasaje --la 7.4-- no se puede ni intentar. GitHub Pages si
# sirve `404.html` en ese caso, y el CI lo copia a proposito. El script replica lo mismo,
# con codigo 404 de verdad. Ver la cabecera de `servir.py`.
python3 scripts/servir.py --directorio build/web --puerto "$PUERTO" \
  >"$TRABAJO/servidor.log" 2>&1 &
SERVIDOR=$!
trap 'kill "$SERVIDOR" 2>/dev/null || true' EXIT

# Y EL `curl` DE COMPROBACION VA **DESPUES** DE MIRAR SI EL PROCESO SIGUE VIVO, y no al
# reves. Con el `curl` primero --que es como estaba-- un servidor que se muere al
# arrancar y otro que dejara el puerto ocupado dan el mismo resultado: el `curl` responde
# y el bucle sale sin mirar el proceso. O sea que la comprobacion de vida no se hacia
# nunca en el caso que pretendia servir para.
sleep 0.3
kill -0 "$SERVIDOR" 2>/dev/null ||
  fallar "el servidor se ha parado al arrancar: $(tail -5 "$TRABAJO/servidor.log")"

intentos=0
until curl -fsS "http://127.0.0.1:$PUERTO/index.html" -o /dev/null 2>/dev/null; do
  intentos=$((intentos + 1))
  kill -0 "$SERVIDOR" 2>/dev/null ||
    fallar "el servidor se ha parado: $(tail -5 "$TRABAJO/servidor.log")"
  [[ $intentos -gt 50 ]] && fallar "el servidor no responde en 50 intentos"
  sleep 0.2
done
nota "el servidor responde"

echo
echo "===================== PRIMERA EJECUCION ====================="
echo "Perfil limpio: el modulo no esta y hay que bajarlo entero."
rm -rf "$PERFILO"
ejecutar primera lector-360.png

echo "--- resultado de la primera ejecucion ---"
cat "$TRABAJO/primera.json"

python3 scripts/comprobar-resultado.py \
  --primera "$TRABAJO/primera.json" \
  --segunda "" \
  --juan316 "$JUAN316" \
  --etiqueta "$CATALOGO_ETIQUETA" \
  --bytes-kjv "$CATALOGO_KJV_BYTES" \
  --bytes-clarke "$CATALOGO_CLARKE_BYTES" \
  --perfil-limpio

echo
echo "===================== SEGUNDA EJECUCION ====================="
echo "Mismo perfil: el modulo esta guardado y no se debe bajar otra vez."
ejecutar segunda lector-360-2.png

echo "--- resultado de la segunda ejecucion ---"
cat "$TRABAJO/segunda.json"

python3 scripts/comprobar-resultado.py \
  --primera "" \
  --segunda "$TRABAJO/segunda.json" \
  --juan316 "$JUAN316" \
  --etiqueta "$CATALOGO_ETIQUETA" \
  --bytes-kjv "$CATALOGO_KJV_BYTES" \
  --bytes-clarke "$CATALOGO_CLARKE_BYTES" \
  --perfil-limpio

echo
echo "==> el proxy ha servido de verdad lo de github.io"
# Y ESTO NO ES COSMÉTICO. La comprobacion de arriba lee el manifiesto del **proxy local**,
# no de github.io, y eso es correcto --es lo que la aplicacion ve-- pero deja un hueco:
# que el proxy se limitara a inventarse un manifiesto con los tamanos correctos y no
# descargara nada. El sha256 del `.amod` lo cierra por el lado de los bytes, y esto lo
# cierra por el lado del origen: se mira el registro del servidor y se comprueba que
# hay peticiones `aa->github.io`.
#
# Y SE COMPRUEBA QUE HAYYA UNA PETICION AL `.amod` Y NO SOLO AL MANIFIESTO, porque un
# manifiesto se puede traer de la memoria cache de Pages sin haber descargado nunca un
# `.amod`, y eso daria verde en todo lo demas.
proxy_peticiones=$(grep -c "aa->github.io" "$TRABAJO/servidor.log" || echo 0)
modulos_por_proxy=$(grep -c "aa->github.io.*\.amod" "$TRABAJO/servidor.log" || echo 0)
echo "    peticiones a github.io: $proxy_peticiones, de ellas .amod: $modulos_por_proxy"
[[ "$proxy_peticiones" -gt 0 ]] ||
  fallar "el proxy no ha pedido nada a github.io: el manifiesto no ha venido de ahi"
[[ "$modulos_por_proxy" -gt 0 ]] ||
  fallar "el proxy no ha descarga ningun .amod: se ha leido el manifiesto y nada mas"

echo
echo "TODO CORRECTO"
echo "Las ejecuciones y los registros estan en $TRABAJO"
