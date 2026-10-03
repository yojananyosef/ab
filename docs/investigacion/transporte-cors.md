# Transporte: por que la web no puede descargar un modulo todavia

Medido el 3 de octubre de 2026 con peticiones reales y con un navegador real.
Todo lo que hay aqui son datos, no opiniones: cada afirmacion sale de una
cabecera o de un `fetch()` que dio o no dio.

Este documento existe porque **es un bloqueante de la plataforma web**, y
porque el razonamiento que `aa` uso para elegir GitHub Releases ya no se sostiene.

---

## 1. El problema

`ab` es web primero. Un navegador, por politica de seguridad, no puede leer un
recurso de otro origen sin que el servidor responda con
`Access-Control-Allow-Origin`. No hay excepcion, no hay forma de pedirlo, y
tampoco hay forma de que el servidor lo conceda si no lo tiene puesto.

Asi que "el navegador puede leer esta URL" hay que comprobarlo, no suponerlo.
La comprobacion se hizo de dos formas: con `curl` leyendo cabeceras y con
Chrome 154 headless haciendo `fetch(..., {mode: "cors"})` desde una pagina
servida en `http://127.0.0.1:8099`.

## 2. Lo medido

| URL que se quiere leer | Cabecera `ACAO` | `fetch()` en navegador |
| --- | --- | --- |
| `raw.githubusercontent.com/.../catalog.json` | `*` | **HTTP 200, se lee** |
| `raw.githubusercontent.com/.../latest.json` | `*` | **HTTP 200, se lee** |
| `api.github.com/repos/.../releases` (metadatos) | `*` | **HTTP 200, se lee** |
| `api.github.com/.../releases/assets/{id}` con `Accept: application/octet-stream` | `*` en el 302 | **BLOQUEADO** |
| `github.com/.../releases/download/v0.1.0/KJV2006_bible.amod` | ninguna | **BLOQUEADO** |
| `cdn.jsdelivr.net/gh/...@main/.../catalog.json` | `*` | se lee |
| `www.bible.com/bible/111/JHN.3.16.NIV` | ninguna | **BLOQUEADO** |

### La trampa del 302

Por `curl` con `-L`, la peticion a `api.github.com/.../assets/{id}` con
`Accept: application/octet-stream` **devuelve 200 con los 22.544.384 bytes
correctos**, y el `sha256` cuadra con el del catalogo:

```
ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9
```

Eso hace creer que la via funciona. No funciona en un navegador, y el motivo es
que la respuesta 302 **de** `api.github.com` lleva `ACAO: *`, pero la respuesta
final, servida por `release-assets.githubusercontent.com`, **no lleva ninguna**.
Una redireccion no hereda sus permisos a la respuesta final.

Medido:

```
HTTP/2 302            access-control-allow-origin: *
  location: https://release-assets.githubusercontent.com/...?se=...&sig=...
HTTP/2 200            (sin access-control-allow-origin)
```

Si alguien hubiera probado con `curl -L` y visto el sha256 correcto, habria
concluido que el transporte funciona. En el navegador no llega ni el primer
byte.

## 3. Que significa para `ab`

- El **manifiesto** se puede leer. `catalog.json` y `latest.json` estan en el
  repositorio y tanto `raw.githubusercontent.com` como `jsDelivr` los sirven con
  CORS. La biblioteca se puede pintar hoy.
- **Ningun `.amod` se puede descargar desde un navegador.** No hay ninguna ruta
  publica de GitHub que sirva un asset de release con CORS. Medido, no
  deducido.

Es decir: hoy `ab` podria mostrar el catalogo y no podria hacer nada con el. Un
lector que no puede leer no es un lector.

En nativo (Android, Linux, Windows) no hay problema: no hay politica de origen
cruzado, y `https://github.com/.../releases/download/...` se descarga
perfectamente. El bloqueo es **exclusivamente de la plataforma que va primera**.

## 4. Que habria que cambiar, y donde

Esto **no es un problema de `ab`**. Publicar en un origen que el navegador
pueda leer es trabajo de `aa`, igual que construir los modulos o decidir
licencias. `ab` no construye origenes de publicacion ni deberia saber de ellos.

La regla de `aa` dice hoy:

> No se migra el origen de publicacion. GitHub Releases con tag inmutable mas
> `latest.json` flotante es el origen hasta que el catalogo tenga unos cientos
> de modulos. Migrar a R2 es cambiar tres lineas.

**La premisa ha cambiado.** La razon de esa decision era el tamano: con unos
cientos de modulos, GitHub Releases se queda corto de ancho de banda y de
cortesia. Pero la restriccion nueva --que la web no puede leerlos-- aparece con
**dos** modulos. No hay ningun numero de modulos a partir del cual GitHub
Releases empiece a servir bien a un navegador: no lo sirve nunca.

### Opcion A: GitHub Pages. Medida, y funciona

**Es la que se ha elegido.** Y no hace falta ninguna cuenta ni proveedor de
nube.

Medido el 3 de octubre de 2026 sobre el sitio ya publicado en
`https://yojananyosef.github.io/ab/`, con una cabecera `Origin:` de un dominio
distinto:

| Fichero | `ACAO` | `Content-Type` |
| --- | --- | --- |
| `/ab/` | `*` | `text/html` |
| `/ab/sqlite3.wasm` | `*` | `application/wasm` |
| `/ab/manifest.json` | `*` | `application/json` |

GitHub Pages responde **`Access-Control-Allow-Origin: *` en todas las
respuestas, incluidos los binarios**. Eso es justo lo que GitHub Releases no
hace, y lo que hace la diferencia entre que el navegador pueda leer un `.amod` y
que no.

Como se hace: un workflow de GitHub Actions descarga los assets de la release y
los publica como sitio. Los assets de release siguen siendo el registro
inmutable con su tag, y el sitio es solo el transporte. `aa` no cambia de
formato ni de versionado: cambia de donde se sirven los bytes.

**El techo, medido contra la documentacion de Pages:**

- Sitio publicado: maximo **1 GB**. Hoy son 80 MB.
- Ancho de banda: **100 GB/mes**, y es un limite blando.

Traducido al caso real: con el comentario de Clarke, de 57.536.512 bytes,
100 GB dan unas **1.740 descargas al mes** antes de rozar el limite. Con la
Biblia de KJV, de 22.544.384 bytes, unas 4.400. Para un proyecto con unos
cientos de usuarios que leen sin conexion y descargan una vez, es de sobra. Para
un million de usuarios, no.

Asi que Pages es la respuesta correcta **hoy** y R2 es la respuesta correcta
cuando el numero de descargas lo pida. La documentacion de Pages dice
literalmente que, al pasarse de cuota, lo sensato es "make use of other GitHub
features such as releases", o sea, que Pages no es un CDN de binarios pesados.

Un detalle que hay que tener en cuenta y que es gratis: **un modulo descargado se
lee sin conexion y no se vuelve a descargar.** El ancho de banda se paga una vez
por usuario, no una vez por lectura. Es la razon por la que el limite aguanta
mucho mas de lo que parece.

### Opcion B: almacenamiento de objetos con CORS

Un bucket publico de Cloudflare R2 (o S3) con `Access-Control-Allow-Origin: *`
en los `.amod`.

- A favor: anade unas pocas lineas, Range requests de verdad y sin limite de
  peticiones por hora.
- En contra: hay que abrir una cuenta, y mientras Pages aguante sobra.
- **No verificado aqui:** no hay cuenta con la que probar un bucket.

Se queda como el paso siguiente cuando el ancho de banda de Pages deje de
aguantar, y el cambio de Pages a R2 es cambiar la URL de origen en un sitio.

### Opcion C: partir los modulos

Un `.amod` por libro, o por testamento, seria de 2 MB. Pero cambia el formato AMF
y rompe el modelo de "un modulo, un fichero". Es la decision mas limpia a largo
plazo y la mas caro de corto. No es para ahora.

### Opcion D: GitHub Pages en `aa` con los modulos en el repositorio

Descartada. Obliga a meter 80 MB en el historial de git de forma permanente, que
es justo lo que `aa` decide no hacer con `.gitignore`.

## 5. Lo que se descarta, y por que

- **Proxy propio en `ab`.** Anadir un servidor a una app que no lo tiene es
  exactamente la decision que este proyecto lleva catorce intentos evitando.
- **Pedir CORS a GitHub.** No es configurable por publicacion.
- **Meter los modulos en git "solo mientras sean pocos".** Es un umbral que se
  cruza sin avisar y deja 80 MB de historia permanente.
- **Usar `api.github.com` con `octet-stream`.** Medido: bloqueado tras la
  redireccion. Ademas son 60 peticiones por hora e IP sin autenticar, y detras
  de un CGNAT --que es lo normal en un operador movil de Latinoamerica-- eso es
  una tarifa compartida entre cientos de personas.

## 6. Efecto en el primer change de `ab`

Mientras `aa` no publique por Pages, el primer change **no puede contar**
con descargar modulos en el navegador. Si lo hiciera, entregaria algo que
compila, pasa las pruebas y no funciona: la forma mas pequena de repetir el
historial de este proyecto.

Por eso `phase-1-biblioteca` tiene las dos vias --descarga por URL y fichero
local-- y la de URL **detecta el fallo y lo dice**, en vez de quedarse girando.
Cuando `aa` publique por Pages, esa misma via empieza a funcionar sin tocar la
interfaz.

Y ya se sabe que funcionara, porque esta medido: Pages envia
`Access-Control-Allow-Origin: *` en el mismo sitio donde esta publicada la
aplicacion.

Lo que si se puede hacer y verificar mientras tanto:

- Leer el manifiesto real desde `raw.githubusercontent.com` y pintar la
  biblioteca. Medido: funciona en navegador.
- Abrir un `.amod` **local** en SQLite y leer Juan 3:16. Es lo que decide la
  arquitectura (SQLite real en WASM, no IndexedDB con SQL emulado), y se
  verifica entero sin depender de la red.
- Toda la UI de biblioteca, estados y tamanos, con datos de prueba que imiten
  el manifiesto real.
