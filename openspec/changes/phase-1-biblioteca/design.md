# Design

## Context

Estado actual: repositorio con la app Flutter generada, `flutter analyze` y
`flutter test` en verde, y nada mas. No hay una sola linea de codigo de
aplicacion todavia.

Cuatro restricciones medidas que condicionan el diseno, y que estan escritas
con su salida completa en `docs/investigacion/`:

1. `docs/investigacion/sqlite-en-navegador.md` -- un `.amod` se abre en el
   navegador con SQLite compilado a WASM: los dos modulos reales de `aa`,
   `quick_check: ok`, Juan 3:16 exacto, 570 ms en total.
2. `docs/investigacion/transporte-cors.md` -- GitHub Releases no sirve para un
   navegador, pero **GitHub Pages si**. El repositorio hermano `aa` ya publica
   sus artefactos ahi y cada entrada del catalogo declara su `browserUrl`.
   Verificado con `fetch` real en Chrome headless antes de escribir este change,
   no despues.
3. El SDK es Flutter 3.47.6 / Dart 3.13.5. `package:sqlite3` 3.7.0 ya trae
   SQLite compilado por *build hooks*, sin dependencia nativa aparte.
4. En esta maquina no hay SDK de Android, ni `gtk+-3.0`, ni Windows, y no hay
   `sudo`. Android, Linux y Windows no se pueden verificar.

## Goals / Non-Goals

**Goals:**

- Que la app lea un capitulo de un `.amod` real, sin transformarlo.
- Que la integridad se compruebe en la maquina de la persona, no en el servidor
  de otro.
- Que la estructura de capas de `AGENTS.md` se cumpla de verdad, con la UI
  incapaz de hacer SQL.
- Que todo lo especificado sea comprobable con un comando, o con un navegador.

**Non-Goals:**

- Cualquier cosa que no se pueda verificar aqui (ver Context 4).
- Rendimiento por debajo de lo medido. Abrir un modulo son 0 ms y leer un
  capitulo son 0 ms. No hay nada que optimizar todavia.
- Persistencia del trabajo del usuario: en este change no hay nada escrito por
  la persona, asi que no hay nada que perder.

## Decisions

### 1. SQLite de verdad, sin formato intermedio

Se usa `package:sqlite3` y se abre el `.amod` tal cual, con
`InMemoryFileSystem` como almacen virtual.

**Alternativas descartadas:**

- *Extraer a JSON y guardarlo en IndexedDB.* Descartada: duplica el dato, crea
  un formato que hay que mantener en dos repositorios y obliga a decidir que se
  serializa. El `.amod` ya es un SQLite con sus indices.
- *`sqflite` mas `sqflite_common_ffi_web`.* Descartada: dos pilas que mantener
  para lo que `sqlite3` ya resuelve con la misma API en las dos plataformas.

**Consecuencia:** el codigo que habla con SQLite importa de
`package:sqlite3/common.dart`, y hay un `import` condicional en dos ficheros:
`sqlite_nativo.dart` (exporta `package:sqlite3/sqlite3.dart`) y
`sqlite_web.dart` (exporta `package:sqlite3/wasm.dart`). Solo esos dos ficheros
saben en que plataforma estamos. Un solo ejemplo:

- `flutter test` corre en la VM y **NOT** ejecuta el camino de WASM. Por eso hay
  ademas una comprobacion en navegador real, y por eso las dos son tareas
  distintas y las dos se ejecutan.

### 2. Sin ORM

SQL escrito a mano contra tres tablas: `info`, `verses`, `commentary`.

**Alternativa descartada:** `drift`. Aporta tipado y migraciones a cambio de
una dependencia con codigo generado. Aqui el esquema es de lectura, no migra, y
son tres tablas con nombres que el catalogo define y no esta app. El tipado que
haria falta son cuatro modelos que ya hay que escribir.

### 3. El manifiesto se lee de `raw.githubusercontent.com`

Medido: `catalog.json` y `latest.json` estan **versionados en el repositorio** y
`raw.githubusercontent.com` responde `Access-Control-Allow-Origin: *`.
`cdn.jsdelivr.net` tambien, y queda como respaldo documentado.

**Alternativa descartada:** la URL de la release que declara `latest.json`
(`github.com/.../releases/download/...`). Es correcta para nativo y no lo es
para web, por el motivo medido.

**Nota de campo:** el manifiesto se lee de `yojananyosef.github.io/aa/latest.json`
y no de `raw.githubusercontent.com`. Los dos funcionan, pero el primero es el
mismo origen que los modulos, y asi el cliente habla con **un** sitio. Los
modulos se bajan de `browserUrl`, nunca de `downloadUrl`: en nativo esta
funcionaria y en web daria `Failed to fetch`, que es el fallo mas caro que
existe, porque compila, pasa las pruebas y no funciona.

**Consecuencia:** una constante, `REPOSITORIO`, de la que se derivan las URLs.
Es configuracion de donde vive una API, no logica del catalogo: no dice que
textos hay. Se puede sobrescribir con `--dart-define=AB_ORIGEN_CATALOGO=...`
para que las pruebas no dependan de la red.

### 4. Los bytes de un modulo pueden venir de dos sitios

La interfaz de obtencion tiene dos implementaciones, porque hoy solo una
funciona en web:

- `DesdeUrl`, con peticiones por rango y progreso en bytes reales.
- `DesdeFicheroLocal`, con el selector de ficheros y arrastrar y soltar.

**Por que las dos y no una:** no es un rodeo. STEPBible tiene "Install from a
directory" y MyBible deja soltar el fichero en el directorio de datos, y los dos
lo hicieron pensando en quien no tiene internet o tiene muy poco. Es el camino
que funciona hoy en el navegador y es un camino que este mercado necesita de
verdad. Cuando `aa` publique en un origen con CORS, `DesdeUrl` empieza a
funcionar sin que cambie una linea de la interfaz.

**Y si `DesdeUrl` falla por CORS, se detecta y se dice.** La app no asume nada:
intenta leer el origen, y si el navegador no le deja, muestra en la fila del
modulo un texto en castellano que explica por que y ofrece el fichero local. Las
dos ramas tienen prueba: la del fallo, contra la URL real de GitHub; la del
exito, contra un servidor local que si envia el permiso.

### 5. El hash se calcula en trozos, no despues

Mientras llegan los bytes, cada rango pasa por el `AccumulatorSink` de
`crypto`, y el digest se compara al final.

**Por que:** calcularlo despues obliga a tener el fichero entero en memoria dos
veces, y uno de estos modulos son 57.536.512 bytes en un navegador de un
telefono de gama baja.

### 6. La tabla de libros solo tiene nombres

La app lleva los 66 nombres de libro en castellano y su clave en el modulo, y
**nada mas**. Ni capitulos por libro, ni versiculos por capitulo, ni numeros de
versiculos.

**Por que:** en `aa` la tabla de libros se escribio primero de memoria y **21 de
66 tenian un numero de versiculos equivocado**. Aqui los numeros no se
escriben: se leen del modulo abierto, con una consulta. Si el modulo tiene 36
versiculos en Juan 3, la app muestra 36. Si no existe, lo dice.

**Como se verifica:** una prueba que abre un `.amod` real, comprueba que hay 66
libros distintos y que los 66 nombres en castellano resuelven a uno existente.
No es una prueba de la tabla: es una prueba contra el modulo.

### 7. Direcciones en modo ruta, con modo hash de reserva

La ruta es la direccion. `setUrlStrategy(PathUrlStrategy())`, con la regla de
servidor que hace falta: servir el documento de entrada para toda ruta bajo la
base. Sin esa regla, un enlace profundo da 404, que es el fallo mas tonto y mas
frecuente de este tipo de aplicacion.

**Alternativa:** `HashUrlStrategy` (el que trae Flutter por defecto). Funciona en
cualquier alojamiento estatico sin tocar nada. Se queda como reserva para cuando
el despliegue no pueda dar la regla, y la especificacion acepta las dos formas
porque lo que se exige es el invariante, no la forma.

**Consecuencia:** un cambio de version o de tamano de letra usa `replaceState`,
no `pushState`. Un cambio de capitulo usa `pushState`. Sin esto, "atras" deja de
volver a donde estaba y la aplicacion se vuelve inservible al tercer uso.

### 8. El trabajo de SQLite no va todavia a un hilo aparte

En este change, abrir un modulo y leer un capitulo se miden en **0 ms**. No hay
nada que repartir.

**Por que no antes:** con `dart2js` no hay isolate de verdad, el trabajo
sincrono se ejecuta en el hilo principal y bloquearlo seria un problema real.
Aqui todavia es hipotetico: no hay ninguna consulta lenta.

**Deuda con plazo, no con suposicion:** el trabajo de SQLite pasa a isolate o a
worker en cuanto **una consulta medida** tarde mas de **50 ms**. Ese numero
sale de la medida, no de la intuicion, y el cambio de busqueda (que escanea el
modulo entero) es donde se va a tripsar. Anotado aqui para que nadie lo lea
despues como si fuera una decision permanente.

### 9. El manifiesto guardado es un respaldo, no una fuente

Se guarda el ultimo manifiesto leido con exito y se vuelve a leer en cada
arranque. Si el servidor no responde, se usa el guardado y se avisa.

**Por que:** MyBible dejo de descargar para todo el mundo el 25 de agosto de
2024 porque se regenero un JSON, y la respuesta de soporte fue "conecta un cable
USB y borra `persisted_registry.json`". Ese fichero esta en la especificacion
como requisito, no como melhoria.

### 10. El estado de un modulo se calcula, no se guarda

Los cinco estados salen de comparar tres cosas: lo que declara el manifiesto, lo
que hay en el dispositivo y el hash del manifiesto. No hay un campo `estado` en
ningun sitio.

**Por que:** un estado guardado se queda viejo, y un estado viejo es la causa
exacta del fallo de MyBible, donde al quedarse sin conexion **todo** pasaba a
"solo local", incluidos los modulos que nunca se habian descargado.

## Risks / Trade-offs

**[El modulo no se puede descargar en el navegador]** -> **Resuelto antes de
escribir este change.** `aa` publica sus artefactos en GitHub Pages y el
catalogo declara `browserUrl`; comprobado con `fetch` real en Chrome headless.
Mitigacion ya aplicada: la app tiene las dos vias y la de URL detecta si el
origen deja de ser legible, en vez de quedarse girando.

**Flutter pinta en un canvas y `flutter test` no ejecuta el motor de render**
-> Una app puede pasar todas las pruebas y no funcionar en ningun navegador. Es
lo que casi paso hoy. Mitigacion: hay una comprobacion en navegador real con
Chrome headless, y el resultado se volca al DOM para poder leerlo. Es una tarea
del change, no una recomendacion.

**El hilo principal se bloquea con SQLite en `dart2js`** -> Hoy son 0 ms
medidos. Mitigacion: umbral de 50 ms medidos para moverlo a isolate, anotado en
la decision 8.

**Almacenamiento del navegador:** un `.amod` de 57 MB tiene que caber en
IndexedDB, y algunos navegadoresSPIENTA al cuota. Mitigacion: antes de escribir,
comprobar cuota disponible y decirlo con palabras en vez de fallar en silencio.
Si resulta insuficiente, el modulo ya esta en memoria y se puede leer en esa
sesion aunque no se pueda guardar.

**Persistencia entre recargas:** guardar un `.amod` en IndexedDB es asincrono
mientras que la API de SQLite es sincrona. -> Se escribe primero en
`InMemoryFileSystem` y se vuelca a IndexedDB despues. Se verifica abriendo la
app dos veces con el mismo perfil de navegador y comprobando que la segunda vez
no vuelve a traer los bytes.

**Android, Linux y Windows sin verificar** -> No se afirman. Cada plataforma
entra en su change con su toolchain instalada, y no antes.

**Cambio de Flutter mayor dentro de seis meses** -> Los ficheros de plataforma
se regeneran con `flutter create` y se reaplican cuatro cambios manuales
(`applicationId`, `index.html`, `manifest.json`, textos). Mitigacion: estan
comentados en el `pubspec.yaml` y en el `index.html` con el motivo, para que
volver a hacerlos no obligue a volver a pensarlos.

## Migration Plan

No hay datos que migrar: la app no tiene usuario, y lo unico que aparece en
disco son modulos del catalogo, que se vuelven a obtener.

Rollback: `git revert` del change. No hay estado remoto que deshacer.

## Open Questions

Ninguna que cambie la especificacion, el enfoque o el reparto de tareas.

Queda pendiente para changes posteriores, sin bloquear este: donde se alojara la
web y si por eso ultimately conviene el modo ruta o el modo hash; y si hace
falta un hilo aparte para SQLite en el change de busqueda.