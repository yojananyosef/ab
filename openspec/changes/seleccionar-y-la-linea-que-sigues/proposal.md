# Proposal

## Why

Dos fallos los ha dicho quien usa la aplicacion, y los dos son de los que no se ven leyendo
el codigo.

**1. No se puede seleccionar el texto.** Un `grep` de `SelectionArea`, `SelectableRegion` y
`SelectableText` en **toda** la aplicacion no devuelve nada.

Y no falla: el texto se pinta, se lee, se marca por su numero y se copia con el atajo del
teclado del navegador. Un `Text` normal **parece** seleccionable porque en el navegador se puede
sombrear con el cursor, y eso es el `user-select` del CSS, que no es seleccion de Flutter. Con
el dedo no hay atajo.

Y en el codigo de la columna, treinta lineas mas abajo de donde se decide, hay un comentario
que dice:

> tocarlo lo selecciona --que es lo que quiere quien copia un versiculo--

Es decir: el comentario describe una capacidad que no estaba implementada, y quien lo lea
creera que seleccionar funciona.

**2. Tocar una palabra se lleva la seleccion.** El indice se abria con un
`TapGestureRecognizer` **sobre** el texto. El toque es el gesto que pide el dedo, asi que el
framework lo resuelve para el que gana, y el que gana no es el de seleccionar.

Y medido sobre el KJV: el lexicon tiene **348.884 ocurrencias en 31.102 versiculos**, o sea
que casi todas las palabras tienen numero. Tocar el texto es casi siempre abrir el indice, y
seleccionar es casi nunca posible.

No son dos fallos: son uno. Un fallo de gesto, visto desde los dos lados.

**3. Y un tercero, encontrado de paso.** La banda de la linea enfocada se quedaba **fija
arriba y sin hacer nada**. Y no era que no siguiera al scroll, que es lo que parecere leyendo
el sintoma: con cinco lineas pedidas y una columna baja la banda sale mas alta que la columna,
`porArriba` sale **negativo**, el `clamp` lo deja en 0, y los dos velos miden cero: la
apertura desaparece en vez de abrirse.

---

## QUE SE HACE

1. Un `SelectionArea` alrededor de **toda** la columna, y no uno por versiculo, para que se
   pueda seleccionar a caballo de dos versiculos, que es justo lo que se copia.
2. El indice se abre con **pulsacion larga**, que es el gesto libre de la seleccion.
3. La banda se acota a la altura de la columna.

## Y POR QUE UN SOLO `SelectionArea`

Porque con uno por versiculo no se puede seleccionar a caballo de dos: «...en el principio... /
...creo la tierra» es una frase y esta partida en dos versiculos. Y `SelectableText` no acepta
`TextSpan` con reconocedores, asi que la region tiene que ir **alrededor** de la columna.

## Y POR QUE EL INDICE PASA A LA PULSACION LARGA

Porque la pulsacion larga **ya era** el gesto de seleccionar. Lo que se hace es decidir, de
los dos gestos que ya existian, cual de los dos **nombra** el indice --que es una accion de
lectura-- y cual selecciona. No se pierde ningun gesto: los dos existian, y solo estaban
peleando.

## Y LO QUE SIGUE SIN ESTAR RESUELTO

La hoja de estilos a 1440 px en el navegador: mide unos 140 px y deja los cinco estilos debajo
del pliegue. **No** se ha podido reproducir en Dart, ni a 360, ni a 768, ni a 1440, ni dentro
del marco de estudio. Esta escrito en el `tasks.md` sin dar por arreglado.
