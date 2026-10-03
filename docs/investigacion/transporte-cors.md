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

### Opcion A: almacenamiento de objetos con CORS

Un bucket publico de Cloudflare R2 (o S3, o el equivalente) con
`Access-Control-Allow-Origin: *` en los `.amod`. GitHub Releases se queda como
registro inmutable con su tag, y el bucket es solo el transporte.

- A favor: coincide con lo que `aa` ya dijo que haria; anade unas pocas lineas;
  anade Range requests de verdad y sin limite de peticiones por hora.
- En contra: hay que crear el bucket y pagar (R2 no cobra por salida y cobra
  por GB guardado, centsimos al mes para este catalogo).
- **No verificado aqui:** no hay cuenta con la que probar un bucket. Que R2
  permita `ACAO` en un bucket publico esta documentado, pero conviene probarlo
  antes de dar el change por bueno.

### Opcion B: GitHub Pages

`https://<user>.github.io/<repo>/...` responde con `ACAO: *` -- medido en la
pagina de Flutter. Pero obliga a que los `.amod` esten **en el repositorio**, y
hoy son 80 MB que `aa` gitignora a proposito. Meter 80 MB en el historial de
git es una decision con consecuencias permanentes, y no compensa mientras haya
una opcion A.

### Opcion C: partir los modulos

Un `.amod` por libro, o por testamento, seria de 2 MB y cabria en cualquier
sitio. Pero cambia el formato AMF y rompe el modelo de "un modulo, un
fichero". Es la decision mas limpia a largo plazo y la mas caro de corto. No es
para ahora.

## 5. Lo que se descarta, y por que

- **Proxy propio en `ab`.** Anadir un servidor a una app que no lo tiene es
  exactamente la decision que este proyecto lleva catorce intentos evitando.
- **Pedir CORS a GitHub.** No es configurable porPublicacion.
- **Meter los modulos en git "solo mientras sean pocos".** Es un umbral que se
  cruza sin avisar y deja 80 MB de historia permanente.
- **Usar `api.github.com` con `octet-stream`.** Medido: bloqueado adespues de la
  redireccion. Ademas son 60 peticiones por hora e IP sin autenticar, y detras
  de un CGNAT --que es lo normal en un operador movil de Latinoamerica-- eso es
  una tarifa compartida entre cientos de personas.

## 6. While reating el primer change de `ab`

Mientras no haya un origen con CORS, el primer change **no puede incluir
descarga de modulos**. Si se incluye, entrega algo que compila, pasa las
pruebas y no funciona en el navegador: la forma mas pequena de repetir el
historial de este proyecto.

Lo que si se puede hacer y verificar:

- Leer el manifiesto real desde `raw.githubusercontent.com` y pintar la
  biblioteca. Medido: funciona en navegador.
- Abrir un `.amod` **local** en SQLite y leer Juan 3:16. Es lo que decide la
  arquitectura (SQLite real en WASM, no IndexedDB con SQL emulado), y se
  verifica entero sin depender de la red.
- Toda la UI de biblioteca, estados y tamanos, con datos de prueba que
  imiten el manifiesto real.

Y la descarga entra en el change siguiente, cuando `aa` publique donde el
navegador pueda leer.