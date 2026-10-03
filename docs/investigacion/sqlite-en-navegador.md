# SQLite en el navegador: medido, no supuesto

La pregunta era una y condicionaba la arquitectura entera: **puede un lector
respuesta depende la arquitectura entera. Si la respuesta es "no", hay que
inventarse un formato, extraer a JSON y guardar en otro sitio, y todo lo demas
se decide distinto.

La respuesta es si. Y se midio en un navegador, no en un `flutter test`.

---

## 1. Como se midio

Con un Dart web plano (`dart compile js`, sin Flutter), `package:sqlite3` 3.7.0
y su `sqlite3.wasm`, servido por `python3 -m http.server` en
`http://127.0.0.1:8098`, y launching en **Chrome for Testing 154.0.8037.92
headless** con `--dump-dom`. La salida se escribe en el DOM para poder leerla.

Los dos ficheros son los **reales publicados por `aa`**, no de prueba:

| Fichero | Bytes | `sha256` |
| --- | --- | --- |
| `KJV2006_bible.amod` | 22.544.384 | `ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9` |
| `CLARKE_commentary.amod` | 57.536.512 | `3df25f8286231c344fb8f47ce74a697b40b4cfeffce0dc311ac7aa5f19c1608c` |

## 2. Lo que devolvio el navegador

```
userAgent: HeadlessChrome/154.0.8037.92
sqlite3 (WASM): libVersion 3.53.4, sourceId 2026-07-24, number 3053004

KJV2006_bible.amod: HTTP 200, 22544384 bytes en 54 ms
  cabecera: "SQLite format 3"
  info.id=KJV2006 type=bible license=PublicDomain
  quick_check: ok
  versiculos: 31102
  Juan 3 en 1.0 ms, 36 versiculos
  Juan 3:16 = "For God so loved the world, that he gave his only begotten Son,
   that whosoever believeth in him should not perish, but have everlasting life."

CLARKE_commentary.amod: HTTP 200, 57536512 bytes en 39 ms
  cabecera: "SQLite format 3"
  info.id=CLARKE type=commentary license=PublicDomain
  quick_check: ok
  notas: 19742
  Juan 3:16 -> 1 nota(s)
  nota 0 = "For God so loved the world - Such a love as that which induced God
   to give his only begotten son to die for the world could not be described..."
```

Los tres numeros que importan:

- **31.102 versiculos.** Es el total canonico de KJV, el mismo que verifica el
  catalogo. El navegador esta leyendo el fichero entero, no un indice.
- **`quick_check: ok`** en los dos. No hay corruption ni ficheros truncados.
- **Juan 3 en 1,0 ms**, con 36 versiculos. No hace falta indice invertido.

## 3. Que queda demostrado

1. **El `.amod` se abre tal cual en el navegador.** Es un SQLite de verdad,
   cabecera `SQLite format 3`, sin transformar. El fichero que hay en disco es
   el fichero que se abre.
2. **Un `.amod` es exactamente el formato que usa MyBible.** Su documentacion
   publica dice, textual, que sus modulos son "SQLite databases" con una tabla
   `info` de pares nombre/valor, y que en un PC "can be opened and edited using
   freely available SQLite browsers". El formato de `aa` eligio lo mismo. No es
   una coincidencia: es lo que ya se usa en este genero.
3. **Los indices que trae el modulo sirven.** `WITHOUT ROWID` con clave primaria
   `(book, chapter, verse)` da el indice de prefijo, y por eso leer un capitulo
   entero es de milisegundos.
4. **El tamano no es un problema ahora.** 57 MB abiertos y consultados en el
   navegador sin problema. El limite real de memoria del navegador esta muy por
   encima.

## 4. Lo mismo, dentro de Flutter

Lo anterior fue con Dart web plano. Faltaba la comprobacion de dentro de
Flutter, donde la compilacion es otra, el recurso se sirve como fichero estatico
y ademas el resultado no se puede leer del DOM porque Flutter pinta en un
canvas.

El spike puso el resultado en el DOM a proposito, con `package:web`, unicamente
para poder leerlo desde fuera con `--dump-dom`. `sqlite3.wasm` se copio a
`web/` y `flutter build web` lo llevo a `build/web/` sin configuracion extra.

Salida de Chrome 154 headless sobre `flutter build web` servido en local:

```
sqlite3: 3.53.4 (10 ms)
KJV2006_bible.amod: 22544384 bytes en 10 ms
  abierto en 0 ms
  quick_check: ok
  versiculos: 31102
  Juan 3:16 = For God so loved the world, that he gave his only begotten Son,
   that whosoever believeth in him should not perish, but have everlasting life.
CLARKE_commentary.amod: 57536512 bytes en 550 ms
  abierto en 0 ms
  quick_check: ok
  notas: 19742
FIN en 570 ms
```

**80 MB de modulos reales, abiertos y consultados en 570 ms.** Abrirlos es
gratis; lo que cuesta es traerlos, y por eso el bloqueo de transporte pesa
tanto.

Nota: `flutter build web` avisa de que la compilacion a `wasm` (dart2wasm, no
dart2js) tambien funciona. Con `dart2js` esta todo en el hilo principal, que es
lo que hay que vigilar cuando se lea un capitulo de verdad.

## 5. Lo que NO queda demostrado, y hay que medir aparte

- **Persistir entre recargas.** Aqui el fichero vivio en un sistema de ficheros
  virtuales **en memoria** (`InMemoryFileSystem`), escrito desde los bytes
  descargados. Falta `IndexedDbFileSystem` u OPFS para que sobreviva a cerrar la
  pestana, y medir cuanto tarda con 22 MB.
- **No bloquear la interfaz.** El `sqlite3` de este paquete es sincrono y, en
  `dart2js`, corre en el hilo principal. Abrir son 0 ms y leer un capitulo son
  0 ms, asi que hoy no se nota, pero en cuanto haya busqueda sobre el modulo
  entero habra que medirlo y probablemente moverlo a un worker.
- **Sin conexion.** Ni siquiera se ha probado: los bytes vienen de un servidor
  local. El comportamiento offline es otro change.
- **Escritura.** Solo lectura. Y tiene que seguir siendo solo lectura: un
  modulo descargado se abre en modo solo lectura. Si algo lo abre en escritura,
  la cabecera cambia y su `sha256` deja de cuadrar con el del catalogo.

## 6. La consecuencia

La arquitectura web queda fijada:

- No hay formato intermedio. No hay JSON. No hay "aplicar transformaciones" al
  modulo.
- La app **abre el mismo fichero que el catalogo publico**, con `sha256`
  comprobado antes de abrir.
- El bloqueo que queda no es de codigo: es de **transporte**. Ver
  `transporte-cors.md`.

Y una decision de diseno que sale de aqui: el modulo se puede abrir desde un
**fichero local**, no solo descargado. Lo hacen STEPBible ("Install from a
directory", pensado para quien no tiene internet) y MyBible (soltar el fichero
en el directorio de datos). Es el unico camino que funciona hoy, y para buena
parte del mercado es el que mas importa.