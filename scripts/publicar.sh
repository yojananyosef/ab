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
#     6. subir `build/web` a la rama `gh-pages`
#     7. comprobar que el sitio sirve el `index.html` **nuevo**
#
# EL PUNTO 7 ES EL QUE HACE VALER EL 6. Publicar y dar por hecho que ha ido es como se
# publica una build rota: `git push` no falla nunca, y el sitio puede estar sirviendo otra
# cosa. Se mira el hash del `index.html` que seSirve y se compara con el que se ha subido.
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

echo "==> 3/7  flutter build web --release"
flutter build web --release --base-href=/ --no-wasm-dry-run

# `404.html` para las rutas profundas: `/leer/KJV2006/John.3.16` no es un fichero, es una
# ruta, y GitHub Pages sirve `404.html` cuando no encuentra lo que se le pide. Sin esto,
# recargar en un enlace no se puede ni intentar.
cp build/web/index.html build/web/404.html

echo "==> 4/7  404.html copiado"

echo "==> 5/7  el motor SQLite tiene que viajar en el paquete"
test -f build/web/sqlite3.wasm
test -f build/web/index.html
test -f build/web/404.html
echo "          sqlite3.wasm: $(stat -c%s build/web/sqlite3.wasm) bytes"
echo "          ficheros: $(find build/web -type f | wc -l)"

echo "==> 6/7  subir a la rama $RAMA"
# Y CON UN INDICE QUE **NO** ES EL DE `main`. La rama `gh-pages` sale de cero con este
# indice, para que el directorio de trabajo quede limpio y el diff de lo publicado sea
# legible.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -r build/web/. "$STAGE/"
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
ESPERADO=$(sha256sum build/web/main.dart.js | cut -d' ' -f1)
URL=https://yojananyosef.github.io/ab/main.dart.js
echo "          sha256 local:  $ESPERADO"
echo "          en el sitio:  $URL"

# Y CON REINTENTOS, porque Pages tarda unos segundos en servir lo recien subido. Sin espera
# esto compara contra la build **anterior** y dice "ok" sin haber comprobado nada: es el
# fallo clasico de una comprobacion que puede pasar sin comprobar lo nuevo.
OK=no
for i in $(seq 1 12); do
  sleep 10
  REMOTO=$(curl -fsS --max-time 25 "$URL" 2>/dev/null | sha256sum | cut -d' ' -f1 || true)
  if [ -n "$REMOTO" ] && [ "$REMOTO" = "$ESPERADO" ]; then
    echo "          intento $i: coincide"
    OK=si
    break
  fi
  echo "          intento $i: aun no ($(echo "$REMOTO" | cut -c1-12))"
done

if [ "$OK" = si ]; then
  echo "==> publicado  https://yojananyosef.github.io/ab/"
else
  echo "          AVISO: el sitio no sirve todavia esta build."
  echo "          Se ha subido el contenido; lo unico que falla es la confirmacion."
  echo "          No se da por publicado sin que las dos cosas digan lo mismo."
  exit 1
fi
