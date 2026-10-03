# Tasks

## 1. Repositorio

- [x] 1.1 Crear `yojananyosef/ab` como repositorio publico, verificado con `gh repo view`: `visibility` es `PUBLIC`, rama por defecto `main`. Creado en `https://github.com/yojananyosef/ab`
- [x] 1.2 Anadir `origin` y subir `main`, verificado con `git ls-remote origin`: `refs/heads/main` = `54d6932`, el mismo hash que el local
- [x] 1.3 Anadir la licencia MIT en `LICENSE` con la exclusion explicita de los textos del catalogo. Verificado: el fichero existe, no tiene caracteres no-ASCII y `README.md` lo menciona
- [x] 1.4 Publicar la v0.0.1. Verificado: `https://github.com/yojananyosef/ab/releases/tag/v0.0.1`, el tag apunta a `54d6932`, los dos archivos fuente responden 200 y el tarball abre con 153 entradas, con `pubspec.yaml`, `web/sqlite3.wasm`, `.github/workflows/ci.yml` y `LICENSE`, y **cero** entradas de build, `.dart_tool`, `.idea`, `.amod` o `catalog.json`

  **Nota sobre `latest.json`, que la tarea pedia y no se ha hecho.** En `aa`
  ese fichero sirve para invalidar la cache del manifiesto. En `ab` no tiene el
  mismo uso: no hay manifiesto que servir, y la version web ya se invalida sola
  con `version.json` y el service worker que genera Flutter. La unica cosa que
  `latest.json` haria aqui es permitir el aviso de "hay una version nueva, toca
  para actualizar" que pide la investigacion, y esa forma **no esta decidida**.
  Publicar ahora un fichero que nadie lee y cuya forma habra que cambiar seria
  fabricar un artefacto. Entra con la funcion de aviso de version nueva, con su
  forma decideda.

## 2. Version web con GitHub Pages

- [x] 2.1 Anadir `.github/workflows/ci.yml` con `flutter build web --base-href=/ab/`, `actions/upload-pages-artifact` y `actions/deploy-pages`. Verificado: run `37157453270` en GitHub Actions con los 9 pasos en `success`, y el sitio publicado
- [x] 2.2 Anadir el `404.html` que Pages necesita para los enlaces profundos. Verificado en el sitio real: `https://yojananyosef.github.io/ab/leer/KJV2006?ref=John.3.16` responde **404 con 1290 bytes**, que es nuestra copia de `index.html` y no la pagina de error de GitHub; y Chrome 154 headless encuentra `<base href="/ab/">`, `<title>AB</title>` y `<flutter-view>`, o sea, que la app arranca en esa ruta
- [x] 2.3 El motor SQLite llega al sitio. Verificado: `https://yojananyosef.github.io/ab/sqlite3.wasm` responde 200, `content-length` 750007 y **`content-type: application/wasm`**. El paso `comprobar que el motor SQLite viaja en el paquete` del workflow falla el despliegue si falta
- [x] 2.4 Medir si Pages sirve con cabeceras de origen cruzado. **Si, y con la cifra.** Con `Origin:` de otro dominio, `/ab/`, `/ab/sqlite3.wasm` y `/ab/manifest.json` responden los tres `access-control-allow-origin: *`. Escrito en `docs/investigacion/transporte-cors.md`, con el techo calculado contra la documentacion de Pages: 1 GB de sitio y 100 GB/mes de ancho de banda, unas 1.740 descargas/mes con Clarke y 4.400 con KJV
- [x] 2.5 Anadir al README la URL del sitio y que Pages es el despliegue. Verificado: el enlace responde 200

## 3. Comprobaciones finales

- [x] 3.1 `flutter analyze`, `flutter test` y `flutter build web --base-href=/ab/` en verde, en ese orden. Verificado en local y en el workflow, que corre los tres antes de desplegar
- [x] 3.2 El sitio publicado arranca en Chrome headless: 200 en la raiz y en la ruta profunda, con `<flutter-view>` presente en las dos. La consola no se puede leer con `--dump-dom`, asi que lo que queda verificado es que el arbol de Flutter se monta, no que no haya avisos
- [x] 3.3 La conclusion sobre Pages esta apoyada en peticiones con `Origin:` de verdad, no en que "Pages suele mandar cabeceras": tres ficheros, tres `ACAO: *`, con la URL y la fecha en el documento

## Lo que este change deja escrito para el siguiente

1. **`aa` necesita publicar sus assets por GitHub Pages.** Es un workflow, no un
   cambio de formato: los assets de release siguen siendo el registro inmutable.
   Hasta que eso pase, la via de descarga en navegador no funciona, y la app lo
   dice en vez de quedarse girando.
2. **`latest.json`, con su forma decidida**, para el aviso de version nueva de
   la PWA. Sin `skipWaiting()` a la fuerza, porque recargar debajo de los dedos
   de alguien que escribe una nota es perder su nota.
3. **Android, Linux y Windows sin verificar**, porque aqui no hay SDK de
   Android, ni `gtk+-3.0`, ni Windows, y no hay `sudo`. El CI solo construye
   web; no afirma nada sobre las otras tres.