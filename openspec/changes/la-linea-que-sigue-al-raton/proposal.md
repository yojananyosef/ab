# Proposal

## Why

La banda de la apertura estaba **fija en el centro vertical** de la columna, y no se movia.

Eso es exactamente lo que se ha dicho de ella:

> no me sirve una linea fija que no se mueva

Y el motivo de que se implementara fija esta escrito en su propia propuesta, que dice que la banda se
queda «quieta y no llama la atencion». La razon era buena --con el dedo no se sabe donde esta
mirando nadie-- y la conclusion estaba mal: con el raton a la vista **si** se sabe.

## QUE HACE EL ORIGINAL

Copiado de `aletheia-reader`, `components/reader/LineFocusOverlay.tsx`, que es donde esta el
mismo conmutador. Las cuatro cosas que importan:

1. **Sigue al raton.** `mousemove` -> `setWindowCenterY(clampY(e.clientY))`.
2. **Se bloquea** al arrastrar en vertical, con las flechas, y el espacio alterna el bloqueo.
   O sea: el raton la mueve **hasta que uno la fije**.
3. **Se recorta** para que se vea entera.
4. **La abertura tiene un margen**: `lineas * linea + (lineas > 1 ? 16 : 8)`. Sin el, la banda
   queda pegada a la linea de arriba y a la de abajo y el texto de al lado se ve **cortado** en
   vez de atenuado.

## Y CON EL DEDO QUE PASA

AlCursor no se ve. Y el equivalente de «donde estoy leyendo» con el dedo es el centro vertical,
porque es ahi donde esta la cabeza con el telefono a media altura. Y al arrastrar el dedo esta
**scrolleando**, que es lo unico que hace el dedo en un texto: si la banda lo sigue, no se puede
leer.

O sea: con raton la banda sigue al raton y con dedo se queda en el centro, que ya es donde se
esta leyendo. No es que una sea menos: son las dos respuestas a la misma pregunta.

## Y LO QUE HA SALIDO AL HACERLO

**La columna se salia de su hueco.** Un `Stack` sin `fit` da a sus hijos sueltos la altura que
le den, y el hijo es el `ListView` del capitulo entero: Juan 3 son 16.848 pixeles. Con `fit:
loose` el `Stack` mide lo que mide su hijo y **se sale**. Y no lo habia visto ninguna prueba,
porque las que hay miden los velos **relativos entre si**, y eso sale bien con el `Stack`
desbordado. Lo que lo delata es medir la columna contra su propia caja:

    el centro de la columna   375,5
    el centro de la banda     319,9   ->   440 / 2

Dos numeros que describen dos widgets distintos.

**Y las flechas no llegaban.** Con `Shortcuts` --que es un `Focus`-- una tecla solo llega si el
foco esta ahi, y en la pantalla de lectura el foco esta en el campo «Ir a: Juan 3:16». El
original escucha en `window`, que es lo mismo que escuchar en `HardwareKeyboard`, y por eso las
flechas funcionan sin tener que hacer clic antes en el texto: que es lo que nadie va a
descubrir.
