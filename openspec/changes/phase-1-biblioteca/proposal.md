# Proposal

## Why

`ab` es un repositorio con cuatro commits y una app que no lee nada. El
catalogo de `aa` esta publicado y verificado desde hace meses, con dos modulos
reales, y la app todavia no lo ha abierto ni una vez. Este change es el
vertical minimo que cierra esa distancia: desde una URL de pasaje hasta el
versiculo en pantalla.

No se propone antes de tiempo porque dos cosas de la arquitectura estaban sin
medir, y estan medidas:

1. **Un `.amod` se abre en el navegador.** `flutter build web` servido en local
   y launching en Chrome 154 headless abre los dos modulos reales de `aa`
   (22.544.384 y 57.536.512 bytes), `PRAGMA quick_check` da `ok` en los dos,
   Juan 3:16 sale exacto, y todo en **570 ms**. Detalle en
   `docs/investigacion/sqlite-en-navegador.md`.
2. **Un `.amod` no se puede descargar desde el navegador.** Ni `releases/download`
   ni la API de assets de GitHub devuelven `Access-Control-Allow-Origin` en la
   respuesta final. El manifiesto si se lee. Detalle en
   `docs/investigacion/transporte-cors.md`.

El punto 2 es un bloqueante de la plataforma que va primera, y es trabajo de
`aa`, no de `ab`. Por eso este change **no puede depender de el**: ademas de
tener un camino que hoy falla con un mensaje honesto, tiene el camino que hoy
si funciona, que es abrir un fichero local.

## What Changes

- La app lee el manifiesto real del catalogo (`catalog.json` via
  `latest.json`), verifica el `catalogSha256` que declara, y pinta la biblioteca.
- **La app no contiene ninguna lista de textos.** Lo que hay disponible se lee
  del manifiesto en tiempo de ejecucion. Si el manifiesto declarase mil modulos,
  la app los mostraria; si declarase ninguno, mostraria una biblioteca vacia y
  un aviso. No hay forma de hardcodear una Biblia porque no hay donde
  hardcodearla.
- Un modulo se puede obtener de dos maneras: **descargando de la URL que declara
  el manifiesto**, con progreso y descargas por rango, o **abriendo un fichero
  local** que la persona elija o arrastre.
- Si el origen de la URL no sirve CORS, la app lo detecta y lo dice con
  palabras, en castellano, en la propia fila del modulo, y ofrece el fichero
  local. No se queda girando, no inventa un error generico, no hides el problema.
- Antes de abrir nada se comprueba el `sha256` del `.amod` contra el que declara
  el manifiesto. Si no cuadra, no se abre y se dice cual era el hash esperado y
  cual se obtuvo.
- El modulo se abre **en modo solo lectura**. Un `.amod` abierto en escritura
  cambia su cabecera y su `sha256` deja de cuadrar con el del catalogo.
- Lector de un capitulo, con los versiculos numerados y tocables, y una **URL
  canonica por pasaje** de la forma `/leer/<id-modulo>?ref=<LIBRO>.<CAP>.<V>`.
- Movil primero y responsive: la misma pantalla sirve a 360 px y a 1440 px.

**No es un cambio de comportamiento rompiente**: la app no tiene
comportamiento todavia.

## Capabilities

### New Capabilities

- `catalogo`: leer el manifiesto del catalogo, verificar su integridad y
  exponer la lista de modulos con su estado, su tamano y su licencia. Incluye
  la regla de que la app no conoce de antemano que textos existen.
- `obtencion-modulo`: traer los bytes de un `.amod` desde una URL o desde un
  fichero local, con progreso real, reintentos acotados, comprobacion de
  `sha256` y estado terminal de fallo. Incluye el comportamiento cuando el
  origen no es legible desde el navegador.
- `lector`: abrir un modulo verificado en modo solo lectura y mostrar capitulos
  y versiculos, con navegacion por URL y comportamiento declarado a 360 px y a
  1440 px.

### Modified Capabilities

Ninguna. `openspec/specs/` esta vacio: este es el primer change.

## Impact

### Codigo

Estructura de capas de `AGENTS.md`, sin excepciones:

```
lib/
|- data/
|  |- models/            ModuloCatalogo, Manifiesto, OrigenModulo
|  |- services/          Http, Hash, Sqlite, Fichero
|  `- repositories/      CatalogoRepository, ModuloRepository
|- domain/
|  |- models/            Modulo, Pasaje, Versiculo, Referencia
|  `- use_cases/         ObtenerCatalogo, AbrirModulo, LeerCapitulo
`- ui/
   |- core/              Tema, tipografia, tamano de lectura
   `- features/
      |- biblioteca/    view_models/ + views/
      `- lector/        view_models/ + views/

La UI no hace SQL ni lee ficheros. Un `ViewModel` pide a un `use_case`, y el
`use_case` va a un `Repository`, que es lo unico que sabe que hay un SQLite.

### Dependencias

Anadidas en el commit anterior, ya medidas: `sqlite3` 3.7.0 (WASM en web, FFI
en nativo), `http`, `crypto`, `typed_data`, `web`.

### Configuracion

Una constante: el repositorio del catalogo, de la que se derivan las URLs del
manifiesto. Se puede sobrescribir con `--dart-define` para no depender de
GitHub en pruebas. Es **configuracion de donde vive una API**, no logica del
catalogo: no dice que Biblias hay, solo donde se pregunta.

###Fuera de alcance (explicito)

- **Notas, resaltados y marcadores.** Es el change siguiente, y es el sistema de
  Accordance entero. Aqui no se escribe ni una nota.
- **Comentarios en pantalla.** `CLARKE` estara en la biblioteca y se podra
  abrir, pero no se mostrara su texto junto al versiculo hasta el change
  siguiente.
- **Busqueda**, ni por palabra ni semantica.
- **Traducciones en paralelo.**
- **Audio.** Ni de narracion ni de lectura en voz alta.
- **Cuentas, compras, publicidad, telemetria.** No existen y no se anaden.
- **Sincronizacion y copia de seguridad.** La regla de `AGENTS.md` sigue
  valiendo y no hay nada todavia que sincronizar.
- **Android, Linux y Windows: no se compila nada.** En esta maquina no hay SDK
  de Android, ni `gtk+-3.0`, ni Windows, y no se puede instalar sin `sudo`. Por
  la regla de `config.yaml` --cada tarea verificable-- no se incluyen. El codigo
  se escribe sin APIs de web, pero **afirmar que funciona en esas plataformas
  sin compilarlo seria exactamente el fallo que este proyecto lleva catorce
  intentos pagando**. Cada plataforma entra en su propio change, con su
  toolchain.
- **iOS**, siempre.
- **El cambio de `aa` que hace falta para que la web pueda descargar.** Es un
  change aparte en el repositorio hermano, con su propio debate. Este change
  funciona sin el, y mejora solo en cuanto el otro aterrice.

### Como se comprueba

| Que | Como |
| --- | --- |
| Analisis | `flutter analyze` sin avisos |
| Pruebas | `flutter test` en verde, con un test por escenario WHEN/THEN |
| En navegador de verdad | `flutter build web`, servido en local, y Chrome headless leyendo el resultado |
| En movil y en escritorio | tests de widget a 360x640 y a 1440x900, sin excepciones y con el contenido visible |
| El hash | un `.amod` real alterado un byte, y se comprueba que la app lo rechaza |

El navegador importa: `flutter test` no ejecuta el motor de render de Flutter,
que pinta en un canvas. Una app que solo pasa `flutter test` puede no funcionar
en ningun navegador.