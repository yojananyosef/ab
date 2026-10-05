# Proposal

## Why

Una captura de `ab` al lado de una de Logos, a la misma tarea —leer Juan 1— y contando
las cosasestructurales:

| | Logos | `ab` antes de este change |
| --- | --- | --- |
| panel de herramientas a la izquierda | 9 herramientas + acciones rapidas | **no existia** |
| pestanas por panel (`RVR60`, `JFB`) | si, es el eje de la organizacion | **no existia** |
| paneles lado a lado con scroll propio | 2 | **no existia** |
| fila de menu por panel | si | **no existia** |
| segunda barra (`Contenido`, `Historia`, `Articulo`) | si | **no existia** |
| migas de pan sobre el texto | si | **no existia** |
| numero de capitulo grande y epigrafes | si | **no existia** |
| numeros de versiculo en linea | si | columna a la izquierda |
| panel de ideas a la derecha, que sigue el scroll | si | **no existia** |
| barra inferior en pantalla estrecha, con `Ir a` abajo | si | el campo en medio del cuerpo |

De doce cosas, `ab` tenia **una**: el texto con su numeracion. Y el documento de
investigacionya lo pedia —«en paralelo, sin limites, y sin que estorbe», linea 184, y el
panel de ideas, linea 314— y se estaba cumpliendo como una lista de botones
independientes sobre un `ListView` con una barra de Material.

## Y EL FALLO NO ERA EL DISENO: ERA EL METODO

Se hicieron nueve changes, cada uno probado, y varios verificados **con capturas**. Pero las
capturas eran de la aplicacion propia: decian «no desborda» y «el versiculo sale», nunca «se
parece a lo que te Comparisonaron». La herramienta que faltaba se uso para lo facil: faltaba
poner la captura al lado de la de Logos y recorrer **la misma lista**.

Por eso este spec empieza por la lista y no por el codigo, y por eso la lista es un requisito
comprobable y no una descripcion.

## Lo que NO se copia, y por que

**Los enlaces azules a otros pasajes y las referencias cruzadas.** Mirado el `.amod` el 5 de
octubre de 2026: dos tablas, `info` y `verses(book, chapter, verse, text, raw)`. **No hay
tabla de referencias cruzadas.** El panel de ideas de Logos se alimenta de esa. Con los datos
actuales no se pueden pintar sin inventar un indice, que seria el dato de otra persona.
Limite real, no pereza.

**La tintoreria comercial**: tienda, entrenos, compartir a la nube de Logos. El proyectoya
tiene escrito que no hay cuentas, ni compras, ni anuncios. No es una carencia: es una
decision y no se deshace.

## Y LO QUE QUEDA FUERA, A PROPOSITO

Los paneles multiples necesitan el modelo de estado, que es un segundo change: hoy
`LectorViewModel` tiene **un** pasaje. Este change monta el marco y deja el sitio medido;
los paneles multiples entran despues sobre ese marco.
