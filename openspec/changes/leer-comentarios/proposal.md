# Proposal

## Why

El comentario de Adam Clarke esta descargado en el sitio desde el 4 de octubre de 2026 y
**no se puede abrir**. La app leia la tabla `verses` de todo lo que se descargaba, y un
comentario tiene tabla `commentary`. El modulo se bajaba entero, se guardaba bien, y
reventaba al abrir con `SqliteException(1): no such table: verses`.

Mientras tanto hay **19.742 notas** ahi, sobre 66 libros, que son el segundo motivo por el
que alguien instala un lector de Biblia: no solo el texto, sino lo que se ha escrito
sobre el.

El arreglo de ayer --que el tipo de contenido se lea del modulo-- dejo el comentario
identificado y no mas. Este change es lo que falta: que se lea.

## What this change does

- **`Nota`** en el dominio: versiculo, `seq` y texto. Una clase propia y no un
  `Versiculo`, porque un versiculo es la Sagrada Escritura y se pinta como tal, y una nota
  no.
- **`Pasaje` lleva las dos cosas** --`versiculos` y `notas`-- y nunca las dos a la vez,
  porque un modulo es una cosa o la otra. Dos listas en vez de una de "fragmentos", para
  que perder el texto y perder una nota no sean el mismo bug.
- **La tabla sale del tipo.** `TipoDeContenido.tablaDeContenido` devuelve `verses` o
  `commentary`, y las ocho consultas usan esa propiedad. El nombre de la tabla no esta
  escrito a mano en ningun sitio, y hay una prueba que lo comprueba leyendo el fichero.
- **La pantalla pinta las notas distinto**, y no es estilo: cuerpo mas pequeno, barra
  vertical, etiqueta de color y el numero del versiculo al que se refiere. Un comentario
  pegado al texto con el mismo formato hace que Adam Clarke parezca citar la Biblia
  cuando en realidad estaba escribiendo sobre ella.
- **Cada versiculo con nota sale con sus notas debajo**, y no todas en un muro. Treinta y
  dos notas seguidas sin decir a que versiculo corresponde cada una no se entienden.
- **La navegacion es la misma**, y sale del modulo: los libros y capitulos que el
  comentario tiene, y el selector de versiculos ofrece los que **tienen nota**.

## Lo que sale de aqui, y no es poco

Dos cosas encontradas midiendo, no leyendo:

1. **`count(DISTINCT verse)` no cuenta versiculos.** Sobre el KJV real da **176**, no
   31.102: `verse` es el numero dentro del capitulo, y en todo el modulo solo hay 176
   numeros distintos. Lo que cuenta versiculos es contar la terna de libro, capitulo y
   versiculo.
2. **El CLARKE publicado tiene una fila repetida.** 19.742 notas en 19.741 pasajes:
   Mateo 23:13 tiene dos, y son **el mismo texto**, 2.709 caracteres cada una. Y
   `info.defects_count` dice `0`, con lo cual esta mintiendo.

## What this change does NOT do

- **No pone el comentario junto a la Biblia.** Esto se lee comentario a comentario:
  `/leer/CLARKE/John.3.16` abre las notas de Juan 3:16. Poner las dos Biblias en pantalla a
  la vez es otro change, porque son dos modulos abiertos y la ruta tiene que decirlo.
- **No repara la fila repetida**, que esta en el repositorio hermano y es cosa de `aa`.
  Aqui solo se quitan al leer, y se dice por que en `AGENTS.md`.

## Y el siguiente: al lado del texto

Esto deja el comentario **suelto**, que es un diccionario con huesos. Ponerlo al lado del
versiculo es el change `leer-el-comentario-junto`, que es donde esto se vuelve util de
verdad.
