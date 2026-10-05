# Proposal

## Why

`ModuloAbierto.buscar()` lleva escrito desde la fase 1 y **no lo llama nadie**. Es una
consulta `LIKE` sobre la tabla del modulo, y en el KJV hay 31.102 versiculos: un lector de
palabra ahora mismo no puede buscar nada.

Y buscar es lo primero que pide quien tiene un texto publico en el navegador y no sabe si
lo tiene. Sin esto, la unica forma de saber si la KJV trae "propitiacion" es recorrer 66
libros.

Ademas hay una razon de **alcance**: con el comentario al lado ya se puede leer, y un
comentario de 19.742 notas es buscable. "propitiacion" en el CLARKE son decenas de
resultados y son los que de verdad justifican un buscador.

## Que se busca y como

Y POR MODULO Y NO SOBRE TODA LA BIBLIA, y esto es una decision y no una limitacion. Una
busqueda que atraviesa varios modulos necesita saber **cual** se busca antes de empezar, y
sin esa pregunta no hay un sitio donde escribir "propitiacion". Ademas los modulos pueden
declarar versificaciones distintas y sus textos estan guardados en idiomas distintos:
mezclarlos en una lista es una decision editorial que este proyecto todavia no ha tomado.

Asi que la busqueda es del **modulo abierto**, y la ruta lo dice:

    /buscar/KJV2006/propitiacion

## Que este change NO hace

- **No busca en el catalogo entero.** Ver arriba: es una decision que requiere saber cual.
- **No pagina.** Sale con un limite de 200 y dice cuantos hay en total. Paginar es otro
  change, y un limite que dice "hay 412" es mejor que un scrolls infinito que no acaba.
- **No resalta la palabra buscada todavia**, aunque los datos estan ahi para hacerlo: la
  posicion de la coincidencia la trae la consulta. Es lo primero que se anade despues.

## Y lo que no se va a inventar

`LIKE` **no** entiende de palabras: busca el texto entero, asi que "pro" encuentra
"propitiacion". Con los numeros del Strong que ya trae el modulo, un dia se hara bien, y
hasta entonces el resultado es un filtro en bruto. Decirlo en la pantalla es mejor que
dejar que quien busca piense que el motor es mas listo de lo que es.
