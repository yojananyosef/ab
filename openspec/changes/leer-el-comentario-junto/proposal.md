# Proposal

## Why

Ayer el CLARKE dejo de reventar al abrir y sus 19.742 notas se leen. Pero se leen
**solas**: `/leer/CLARKE/John.3.16` abre las notas de Juan 3:16 sin el texto al lado.

Y el texto al lado es el motivo por el que se instala un lector de Biblia. Un
comentario sin el versiculo es un diccionario: obliga a buscar el pasaje en otro sitio,
en otro dispositivo, y a recordar el numero. Es el uso que Justus Lieber, y despues
Accorde, tenian en mente: **el versiculo y lo que se ha escrito sobre el, en la misma
columna y a la vez**.

Ademas, quien lee el comentario con el texto delante puede ver que el texto es de 1832
y no de hoy, que es justo la distincion que la pantalla de ayer respeta y que en una
columnaaret seule no se puede hacer.

## What this change does

- **`RutaLectura` lleva un segundo identificador**: `comentario`. La ruta pasa a ser
  `/leer/KJV2006/John.3.16/con/CLARKE`, y sigue siendo una frase que se puede copiar y
  mandar: "lee el KJV2006 en Juan 3:16, con el CLARKE". Sin el, un enlace no dice con que
  se esta leyendo, y la URL es la fuente de la verdad en este proyecto.
- **El lector lleva dos modulos abiertos**, el texto y el comentario, y pinta cada
  versiculo con **sus** notas debajo. Se reutiliza el widget de nota del change anterior:
  mismo cuerpo, misma barra, mismo color, porque es la misma distincion.
- **Un boton en la barra** para elegir comentario y para quitarlo. La lista sale del
  manifiesto y de lo que hay descargado, y **no** de una lista de comentarios escrita en
  el codigo.
- **La sonda** comprueba tambien este caso, y el script de navegador tiene una segunda
  ejecucion para el.

## Y por que el segmento es `/con/` y no un parametro de consulta

Un parametro `?con=CLARKE` seria lo habitual, y aqui no se usa por dos motivos medidos en
este mismo proyecto:

1. **La ruta es lo que se copia y se manda.** Con dos mecanismos --ruta y consulta-- hay
   que decidir cual de los dos gana cuando discrepan, y no hay regla que no haya que
   inventar. Con uno solo no hay pregunta.
2. **`Rutas` ya corta por barras** porque el despliegue añade un prefijo que no se puede
   adivinar. Anadir la consulta obliga a tocar el analisis entero para tambien mirar el
   `?`, y eso es mas codigo para una frase que ya cabe en la ruta.

Un segmento mas, y el identificador del comentario va **detras** del pasaje, que es donde
va lo que se le anade a algo.

## What this change does NOT do

- **No es el panel de resalte de Accorde.** No hay columna lateral, ni las palabras
  resaltadas, ni el desplazamiento sincronizado. Aqui las notas van **debajo** del
  versiculo, que es lo que cabe en una columna y en un movil de 360 px. El panel lateral
  es otro change, y necesita el resaltado.
- **No toca los terminos.** Cada modulo tiene los suyos y salen al final de la lectura.
  Verlo es cosa de este change o del siguiente, segun como quede.
