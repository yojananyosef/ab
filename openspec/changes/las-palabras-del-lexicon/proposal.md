# Proposal

## Why

El `.amod` guarda dos columnas: `text`, que es el texto plano, y `raw`, que es el mismo
texto con marcado USFM. Desde la fase 1 la app lee **`text`** y tira **`raw`**, y lo que
ahi hay se estaba dejando en la mesa.

Y lo que hay, medido sobre el KJV entero el 5 de octubre de 2026:

    marcas \w (palabra con lexicon)      630.866
    marcas \+w (lo mismo, en parrafos)     72.386
    marcas \add (texto del traductor)      41.692
    marcas \nd (sin divisor)               13.740
    versiculos con aparato de variantes   5.844
    marcas distintas en todo el modulo    10

El segundo motivo por el que se instala un lector de Biblia, despues del texto, es saber
**que palabras puso el traductor y cuales estan en el original**. En un texto de 1611 esa
distincion es informacion de primera clase, y esta en el fichero, gratis, desde el primer
dia.

## Y lo que este change NO hace, y hay que decirlo antes

LA PALABRA DE DIOS EN ROJO NO SE PUEDE CON ESTOS MODULOS.

Se ha buscado una marca de habla divina en los 31.102 versiculos del KJV y **no esta**. Lo
que hay son los numeros del lexicon y los `\add`. Pintar de rojo lo que uno no sabe que es
la Palabra seria inventarse el dato, y este dato es la Escritura. Ver `AGENTS.md`.

Lo que si sale del `raw`, y sale de verdad:

- **El numero del lexicon de cada palabra.** `Dios` es `G2316` en Juan 3:16. Con letra,
  porque `G` es griego y `H` hebreo, y sin ella dos entradas distintas serian el mismo
  numero.
- **Que palabras puso el traductor.** `\add`, 41.692 marcas. Juan 3:16 no tiene ni una: es
  texto que el KJV no toco.

## La decision que sostiene el resto

EL TEXTO SE PINTA DESDE LA COLUMNA `text` DEL MODULO, NUNCA DESDE EL `raw`.

Las dos columnas dicen lo mismo y dan la misma Biblia, pero no con los mismos caracteres:
en el KJV hay 5.844 versiculos cuyo `raw` tiene un `+` que `text` no tiene, 13.740 marcas
`\nd` y notas al pie cuyo numero va en una columna y no en la otra. Reconstruir `text` desde
`raw` obliga a aprender una regla por caso.

Se intento. Salieron tres versiones, y la tercera se rindio con el aparato de variantes de
las cronicas, que necesita cuatro reglas distintas segun el versiculo. Una regla por caso
es escribir el texto del modulo sin saber que se esta escribiendo.

Asi que el texto es el que dice el modulo y lo que sale del `raw` son **anotaciones**. Y si
el marcado no casa con el texto --las palabras no cuadran-- **no hay anotaciones**: se
descartan y el texto se queda solo. Es preferible un versiculo sin lexicon a un versiculo
con el numero de la palabra de al lado.

## Y el texto no se comprueba con un ejemplo

Que lo pintado es identico a lo del modulo es una trivialidad a proposito: el texto viene de
la columna y no se reconstruye, y la comprobacion es que eso no se rompa. La que **si** hay
que medir es la cobertura: **97,60 %** de los versiculos del KJV reciben anotaciones, y el
2,40 % restante son los del aparato de variantes. Ese numero va en una constante con
nombre, para que si el catalogo publica otra Biblia y baja la cobertura se vea.
