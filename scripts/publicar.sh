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
PREFIJO=$(grep -o 'base href="[^"]*"' build/web/index.html | head -1)
case "$PREFIJO" in
  *href="/ab/"*) echo "          prefijo: $PREFIJO, correcto para /ab/" ;;
  *) echo "AVISO: el paquete declara $PREFIJO y deberia declarar /ab/."
     echo "        En GitHub Pages los recursos se buscarian en la raiz de github.io,"
     echo "        que no es este repositorio. No se publica."
     exit 1 ;;
esac
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
git push --force "$ORIGEN" "HEAD:refs/heads/$RAMA"

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
