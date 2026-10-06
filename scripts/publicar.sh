#!/usr/bin/env bash
# Publicar la web sin depender de GitHub Actions.
#
# ============================================================================
# POR QUE ESTE FICHERO EXISTE Y NO ES "LO MISMO QUE EL CI"
# ============================================================================
#
# Medido el 5 de octubre de 2026. GitHub Actions estaba en `major_outage` --confirmado tres
# veces con un minuto de separacion en `githubstatus.com/api/v2/components.json`-- y el
# despliegue de `ab` estaba en manos suyas:
#
#     The job was not acquired by Runner of type hosted even after multiple attempts
#
# Que el **sitio entero** dependiera de que Actions tuviera corredores de sobra no es una
# decision que se tome a proposito: es lo que pasa cuando el unico sitio donde compilar
# Flutter es una maquina de GitHub.
#
# Y LA RESPUESTA NO ES ESPERAR. Aqui esta Flutter, el `.amod` esta descargado, las
# comprobaciones se ejecutan y las capturas salen. Lo unico que faltaba era **subir** el
# resultado, y subir un directorio a una rama es lo mas simple que hay.
#
# ============================================================================
# QUE HACE, Y EN QUE ORDEN
# ============================================================================
#
# Las mismas comprobaciones que hace el CI, en el mismo orden, porque una publicacion que
# no comprueba nada antes de subir es como se rompe el sitio:
#
#     1. `flutter analyze`                     sin avisos
#     2. las pruebas, si estan las fixtures    verde, o no se publica
#     3. `flutter build web --release`
#     4. `404.html`                            copia de `index.html`, para las rutas profundas
#     5. `sqlite3.wasm` presente               sin el, la app arranca y falla al abrir
#     6. subir `build/web` a la rama `gh-pages`, con una marca de publicacion
#     7. comprobar que el sitio sirve **esa** marca
#
# EL PUNTO 7 ES EL QUE HACE VALER EL 6. Publicar y dar por hecho que ha ido es como se
# publica una build rota: `git push` no falla nunca y el sitio puede estar sirviendo otra
# cosa. Se lee del sitio un fichero que **solo existe si se ha publicado esto**.
#
# Y POR QUE NO BASTA COMPARAR EL SHA DEL `main.dart.js`, QUE ES LO QUE SE HIZO PRIMERO.
#
# La primera version comparaba el sha256 del `main.dart.js` local con el que servia el
# sitio. Dio **coincidir en el primer intento** -- y era mentira: el despliegue anterior era
# del commit `d09d162` y desde entonces lo unico que habia cambiado eran el workflow y un
# script, que **no entran en el paquete Dart**. El compilador produce el mismo
# `main.dart.js` byte a byte, los sha son iguales y la comprobacion no ha mirado el sitio.
#
# Es el mismo fallo que ya esta escrito en `AGENTS.md`: **una comprobacion que puede pasar
# sin comprobar lo nuevo es peor que no comprobar**, porque da verde. Y aqui era peor: la
# comprobacion de la publicacion, que es la que dice si el sitio esta al dia, era la que
# podia dar verde sin publicar.
#
# Asi que ahora se escribe `publicado.txt` con el commit y la hora, y **eso** es lo que se
# lee del sitio. Si el sitio no lo tiene, no se ha publicado, aunque el `git push` haya
# dicho que si.
#
# ============================================================================
# Y QUE PASA CON EL CI
# ============================================================================
#
# El CI **sigue** haciendo `analyze`, pruebas y build: seguir verificando en una maquina
# que no es la nuestra es lo unico que aporta. Lo que se le quita es **desplegar**, porque
# desplegar es lo que depende deActions. Y la diferencia se documenta, para que no parezca
# que se ha quitado un paso sin querer.

set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/.local/opt/flutter/bin:$PATH"
# El `/tmp` de esta maquina es un tmpfs de 3,7 GB y el compilador de Flutter escribe ahi el
# `.dill`. Si se llena, `flutter test` **se queda colgado sin decir nada**. Ver `AGENTS.md`.
export TMPDIR=/home/j/.tmp

RAMA=gh-pages
ORIGEN=https://github.com/yojananyosef/ab.git

echo "==> 1/7  flutter analyze"
flutter analyze

# Las pruebas solo si hay fixtures. Sin ellos `flutter test` falla con un mensaje que ya
# dice que script ejecutar, asi que no se salta en silencio: se avisa de que esta
# publicacion se ha hecho **sin** verificar.
if [ -f test/fixtures/KJV2006_bible.amod ]; then
  echo "==> 2/7  flutter test"
  flutter test --timeout 300s
else
  echo "==> 2/7  SALTADO: no estan las fixtures. bash scripts/preparar-fixtures.sh"
  echo "          Se publica SIN verificar con pruebas. Eso es peor que no publicar."
  exit 1
fi

# Y CON `--base-href=/ab/`, Y NO CON `/`.
#
# El sitio se sirve en `https://<usuario>.github.io/ab/`, y con `/` el paquete busca sus
# recursos **en la raiz** --`https://<usuario>.github.io/main.dart.js`--, que no existe: es
# otro repositorio. La app arranca y luego no encuentra ni el motor SQLite, que es el peor
# sitio posible para descubrirlo.
#
# La primera version de este script usaba `--base-href=/`, copiado del comando que se usa
# para **servir en local** con `scripts/servir.py` en la raiz. En local `/` es lo correcto; en
# GitHub Pages no lo es, y la diferencia es el prefijo del repositorio. El script se
# comprueba en los dos sitios distintos y por eso los dos necesitan el flag distinto.
echo "==> 3/7  flutter build web --release"
flutter build web --release --base-href=/ab/ --no-wasm-dry-run

# `404.html` para las rutas profundas: `/leer/KJV2006/John.3.16` no es un fichero, es una
# ruta, y GitHub Pages sirve `404.html` cuando no encuentra lo que se le pide. Sin esto,
# recargar en un enlace no se puede ni intentar.
cp build/web/index.html build/web/404.html

echo "==> 4/7  404.html copiado"

echo "==> 5/7  el motor SQLite tiene que viajar en el paquete"
test -f build/web/sqlite3.wasm
test -f build/web/index.html
test -f build/web/404.html

# Y QUE EL PREFIJO SEA EL DE ESE REPOSITORIO. Sin esta comprobacion, un `--base-href=/`
# --que es lo correcto para servir en local-- sube un paquete que en GitHub Pages busca sus
# recursos en la raiz de `github.io`, que es otro sitio. La app arranca y falla al abrir el
# primer texto, y desde fuera parece que el despliegue salio bien porque devuelve 200.
# Y LA COMPROBACION ES UN **`grep -q`** Y NO UN `case`, y hay un motivo que cuesta una
# tarde si no se sabe.
#
# La primera version hacia:
#
#     PREFIJO=$(grep -o 'base href="[^"]*"' build/web/index.html | head -1)
#     case "$PREFIJO" in
#       *href="/ab/"*) ... ;;
#       *) AVISO ;;
#     esac
#
# Y **fallaba con un paquete correcto**: decia "el paquete declara base href="/ab/" y
# deberia declarar /ab/" sobre un paquete que si lo declaraba.
#
# La razon es que **las comillas dentro del patron de un `case` son caracteres de comilla**,
# no comillas literales. El shell se las come al leer el patron, y lo que queda por
# comprobar es `*href=/ab/*` --sin comillas-- contra la cadena `base href="/ab/"`, que si
# las tiene. Y falla.
#
# Lo que mas engaña es que el patron **parece** el correcto y el valor **parece** el
# correcto, y el mensaje de error imprime los dos. Con `case *href=/ab/*` --sin comillas-- la
# comprobacion da NO con `href="/ab/"` y SI con `href=/ab/`, que es el otro fallo posible del
# mismo patron.
#
# Asi que se comprueba con `grep -q` sobre el fichero entero, con las comillas dentro de una
# cadena de comillas simples, donde si son literales.
if grep -q '<base href="/ab/">' build/web/index.html; then
  echo "          prefijo: /ab/, correcto para este repositorio"
else
  echo "AVISO: el paquete no declara <base href=\"/ab/\">."
  echo "        Lo declara:"
  grep -o '<base href="[^"]*"' build/web/index.html | head -1 | sed 's/^/          /'
  echo "        En GitHub Pages los recursos se buscarian en la raiz de github.io, que no"
  echo "        es este repositorio, y la app arrancaria sin encontrar sqlite3.wasm."
  echo "        No se publica."
  exit 1
fi
echo "          sqlite3.wasm: $(stat -c%s build/web/sqlite3.wasm) bytes"
echo "          ficheros: $(find build/web -type f | wc -l)"

echo "==> 6/7  subir a la rama $RAMA"
# Y CON UN INDICE QUE **NO** ES EL DE `main`. La rama `gh-pages` sale de cero con este
# indice, para que el directorio de trabajo quede limpio y el diff de lo publicado sea
# legible.
#
# Y `STAGE` SE DECLARA **ANTES** DE USARLO. La primera version de esta parte escribia la
# marca de publicacion antes de crear el directorio, y con `set -u` --que esta puesto-- el
# script se para aqui:
#
#     scripts/publicar.sh: linea 112: STAGE: variable sin asignar
#
# El fallo es de orden de lineas y no de logica, y sale tarde: despues de cuatro minutos de
# pruebas y de compilar. Por eso el mensaje de la linea 112 es util y no es ruido.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -r build/web/. "$STAGE/"

# Y LA MARCA DE PUBLICACION, que es lo que el paso 7 comprueba.
cat > "$STAGE/publicado.txt" <<FIN
publicado desde local
commit  $(git rev-parse HEAD)
corto   $(git rev-parse --short HEAD)
cuando  $(date -u '+%Y-%m-%dT%H:%M:%SZ')
rama    $RAMA
FIN
cat "$STAGE/publicado.txt"

cat > "$STAGE/.nojekyll" <<'FIN'
GitHub Pages sirve este directorio con Jekyll si encuentra un `_config.yml` o cualquier
fichero que empiece por `_`. Los ficheros de Flutter --`assets/`, `main.dart.js`,
`sqlite3.wasm`-- no tienen por que empezar asi, pero el dia que uno se llame `_algo` el
sitio dejaria de servirlo sin avisar. Este fichero, que esta vacio, apaga Jekyll.
FIN
rm -rf "$STAGE/.git"

git -C "$STAGE" init -q
git -C "$STAGE" add -A
git -C "$STAGE" -c user.email=yojananyosef@users.noreply.github.com \
  -c user.name=yojananyosef commit -q -m "publicado desde local: $(git rev-parse --short HEAD)"

# Y ANTES DE SUBIR, QUE LO QUE HAY EN EL DIRECTORIO **SEA EL PAQUETE**.
#
# No es una comprobacion de estilo: el fallo de al lado fue exactamente que se subio `main`
# en vez del build, y esta es la comprobacion que lo habria parado.
echo "          indice: $(ls -A "$STAGE" | tr '\n' ' ')"
test -f "$STAGE/index.html"
test -f "$STAGE/main.dart.js"
test -f "$STAGE/sqlite3.wasm"
test -f "$STAGE/publicado.txt"
test -f "$STAGE/404.html"

# Y EL `git -C` EN EL `push`, Y ESTE ES EL FALLO.
#
# La primera version hacia:
#
#     git push --force "$ORIGEN" "HEAD:refs/heads/$RAMA"
#
# **Sin `-C "$STAGE"`.** Y `HEAD`, sin repositorio al que aplicarse, se resuelve en el
# directorio de trabajo --`/home/j/ab`--, o sea que subio **`main` a la rama `gh-pages`**:
# el codigo fuente del proyecto, no la web. Y el repositorio es publico, asi que la rama
# `gh-pages` era una copia publica de `main` sin ninguna relacion con el sitio.
#
# Los tres comandos anteriores si llevaban `-C "$STAGE"`, asi que el `add` y el `commit`
# hacian lo correcto y el contenido estaba ahi. Solo el `push` se|Referia a otro sitio, y por
# eso `git ls-tree origin/gh-pages` teachingeba `AGENTS.md`, `lib/`, `android/`.
#
# Y POR QUE NO LO VIO EL PASO 7: la primera vez dio "coincide" por el fallo del sha igual,
# y las siguientes died "sin marca" -- porque `publicado.txt` no existia en la rama, que era
# otra cosa. **Las dos respuestas eran la verdad**: la primera por casualidad y la segunda
# por el motivo correcto.
# =============================================================================
# Y EL `http.postBuffer`, Y LOS TRES INTENTOS, MEDIDO EL 6 DE OCTUBRE DE 2026
# =============================================================================
#
# La publicacion del 6 de octubre fallo en **este** `push`, con el remoto diciendo:
#
#     error: RPC fallo; HTTP 408 curl 22 The requested URL returned error: 408
#     send-pack: unexpected disconnect while reading sideband packet
#     fatal: el remoto se colgo de manera inesperada
#
# Un 408 es un **tiempo de espera agotado**, y es transitorio. Y este paquete son 41 ficheros
# con dos grandes --`main.dart.js` de 2,7 MB y `sqlite3.wasm` de 750 KB-- que se suben
# **enteros en cada publicacion**, porque el repositorio del escenario se crea de cero a
# proposito. Es decir: cada publicacion manda varios megas por HTTP, y un solo intento es
# una apuesta a que la conexion aguanta.
#
# Y LO QUE PASABA DESPUES, QUE ES LO PEOR: el `push` fallo, el script **siguio** --porque
# solo lleva `set -u` y no `set -e`-- y se paro en el paso 6 sin llegar al 7. Lo que no
# hizo, y es lo importante, es **dar por publicado**: la comprobacion del paso 7 no llego a
# correr, asi que no llego a decir "ok" por accidente. Un fallo ruidoso.
#
# `http.postBuffer` se pone alto porque el valor por defecto --1 MB-- hace que git mande el
# paquete a base de trozos y con una peticion de control por cada uno. Con 500 MB lo manda
# en una peticion, que es justo lo que GitHub acepta sin cortar.
SUBIDO=no
for intento in 1 2 3; do
  if git -C "$STAGE" -c http.postBuffer=524288000 push --force "$ORIGEN" \
       "HEAD:refs/heads/$RAMA"; then
    SUBIDO=si
    break
  fi
  echo "          intento $intento: el push ha fallado; se espera y se repite"
  sleep 20
done

# Y SI TRES VECES NO, SE PARA AQUI Y NO SE SIGUE. Un paso 7 sobre un push que no ha ido
# compara el sitio contra un commit que no esta ahi, y solo puede dar una de dos respostas
# malas: "el sitio no sirve esta publicacion" --que es verdad-- o, si el marcador viejo
# coincidiera por casualidad, "ok" sin haber subido nada. Lo segundo es la clase de fallo
# que `AGENTS.md` prohibe: **una comprobacion que puede pasar sin comprobar lo nuevo**.
if [ "$SUBIDO" != si ]; then
  echo "          ERROR: el contenido NO se ha subido a la rama $RAMA."
  echo "          No se sigue: el paso 7 compararia el sitio contra un commit que"
  echo "          no esta subido, y no puede decir la verdad."
  exit 1
fi

echo "==> 7/7  comprobar que el sitio sirve ESTE build"
# Y LA COMPROBACION ES DE CONTENIDO Y NO DE CODIGO. Un `curl` que devuelve 200 con la pagina
# de error de GitHub --que tambien es 200-- no dice nada. Se compara el **sha256** del
# `main.dart.js` servido con el del que se ha subido, que solo pueden ser iguales si lo que
# esta en el sitio es esta build.
MARCA=$(git rev-parse HEAD)
URL=https://yojananyosef.github.io/ab/publicado.txt
echo "          commit local: $MARCA"
echo "          en el sitio:  $URL"

# Y CON REINTENTOS, porque Pages tarda unos segundos en servir lo recien subido. Sin espera
# esto compara contra la build **anterior** y dice "ok" sin haber comprobado nada: es el
# fallo clasico de una comprobacion que puede pasar sin comprobar lo nuevo.
OK=no
for i in $(seq 1 12); do
  sleep 10
  REMOTO=$(curl -fsS --max-time 25 "$URL" 2>/dev/null | tr -d '\r' || true)
  # Y SE COMPARA EL **COMMIT** Y NO EL FICHERO ENTERO. La marca lleva la hora, asi que el
  # fichero entero seria distinto en cada publicacion aunque el commit fuera el mismo, y
  # entonces compararlo entero solo diria "hay algo ahi".
  if echo "$REMOTO" | grep -q "commit  $MARCA"; then
    echo "          intento $i: el sitio sirve ESTA publicacion"
    OK=si
    break
  fi
  echo "          intento $i: aun no ($(echo "$REMOTO" | grep -m1 commit || echo 'sin marca'))"
done

if [ "$OK" = si ]; then
  echo "==> publicado  https://yojananyosef.github.io/ab/"
else
  echo "          AVISO: el sitio NO sirve esta publicacion."
  echo "          Se ha subido el contenido a la rama $RAMA; lo que falla es la"
  echo "          confirmacion. Y eso significa una de dos cosas:"
  echo "            - Pages aun no lo ha servido, y hay que esperar;"
  echo "            - la fuente de Pages **no** es la rama $RAMA, y hay que fijarla:"
  echo "                gh api -X PUT repos/yojananyosef/ab/pages \\"
  echo "                  -f source[branch]=$RAMA -f source[path]=/"
  echo "          En los dos casos el sitio **no** esta actualizado. No se da por publicado."
  exit 1
fi
