# Proposal

## Why

`docs/investigacion-ux.md` dice, en "Los botones que se copian":

> "Selector de version desde la cabecera del lector, con filtro mientras se escribe.
> Comparar versiones sin salir de la lectura es la interaccion mas valiosa de una app de
> Biblia."

Y **no existia**. `alCambiarDeVersion` estaba cableado en el enrutador desde el principio
--con su `replaceState` y su comentario sobre por que-- y **ningun boton lo llamaba**. La
interaccion mas valiosa de la categoria era inalcanzable.

Y la segunda que lista el mismo documento:

> "Resumen de cada capitulo en el selector de libros (Bible Gateway). Es la mejor idea de
> localizacion de referencias que se ha visto: resuelve 'se que estaba en el cap. 12 de
> algo, pero no de que'."

Tampoco existia un selector de libros. Para pasar de Juan a Josue habia que escribir
"Josue 1": sesenta y seis libros, mil ciento ochenta y nueve capitulos y un teclado.

## Y LA MEDICION QUE DICE QUE ESTA MAL LA ORDEN

Medido a **360 px**, con la cabecera de dos lineas recien anadida y el boton de comentario
como boton con texto:

    hueco que le quedaba al titulo      13,9 pixeles
    palabra "Comentario" sola          110 pixeles
    con icono, el boton                 48 pixeles

Trece pixeles. "Juan 3:16" no cabe en trece pixeles, y el nombre de la version tampoco. Lo
que se veia era un titulo recortado en seco y un `overflow` de 6 pixeles en cada linea.

**Y NO LO HABRIA VISTO NADIE LEYENDO EL CODIGO**: tres widgets correctos, cada uno en su
sitio, que juntos no dejan sitio. El `overflow` lo delata el renderizado, y el titulo de 13
pixeles **no desborda nunca**: se recorta entero y no hay exception. Por eso hay una prueba
que mide el ancho del titulo y no que compruebe que no desborda.

## Que se hace

1. **El titulo de la barra pasa a ser la cabecera**: el pasaje en una linea y el nombre de
   la version debajo. Cada una abre su selector. Y **no hay icono de ninguno de los dos**:
   se ahorra un boton en vez de anadir uno.
2. **Selector de libros y capitulos** con filtro que acepta un nombre o una referencia
   entera, y la **primera frase** de cada capitulo.
3. **Selector de version** con filtro, estado de descarga y tamano.
4. El boton de comentario pasa a ser icono, que es lo que le deja sitio al titulo.

## Y lo que NO es un resumen de capitulo

El nombre de la investigacion es "resumen", y lo que hay **no es un resumen**.

Medido: `verse = 1` en el KJV da 31.102 filas, y son en su mayoria Genealogias, Salmos y
Proverbios, donde la primera frase **no** dice nada del capitulo. Juan 3 y Romanos 1 si la
dicen, porque empiezan con un sustantivo propio. Es un indice de referencia, no un indice
tematico, y decirlo de otra forma seria vender algo que no es.

Y no se puede hacer mejor sin un lexicon, que **no esta en el modulo**: medido el 5 de
octubre de 2026, el KJV tiene dos tablas, `info` y `verses`, y ninguna de las trece claves
de `info` es de lexicon.

## Lo que sigue sin poder

**Traducciones en paralelo.** El catalogo declara **una** Biblia, `KJV2006`. Sin una segunda
que poner al lado no hay nada que alinear, y `ab` no construye modulos. En el repositorio
hermano esta medido por que no hay una segunda: no hay fuente de RVR1909 que sea a la vez
completa, KJV-compatible y de dominio publico.

Los dos selectores se hacen **igualmente**, porque son la funcion que hace falta en cuanto
haya una segunda version, y porque un selector que solo aparece con dos elementos es un
selector que nunca se ha visto.
