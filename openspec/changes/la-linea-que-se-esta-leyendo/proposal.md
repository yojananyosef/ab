# Proposal

## Why

En la hoja de formato hay un conmutador de **«Línea enfocada»** con cuatro posiciones:
apagada, una línea, tres líneas, cinco líneas.

Se puede tocar. **Escribe la preferencia.** La preferencia se guarda, se lee y se conserva.

Y no lo miraba nadie: ni el `LectorViewModel` sabía que el campo existía, ni la vista. Un
`grep` de `lineaEnfocada` en `lib/` devuelve el modelo y la hoja de formato. Ni una vez en la
vista.

Es decir: **un interruptor que miente**. Y es la versión con cara de usuario de un fallo que
`AGENTS.md` ya documenta con `alCambiarDeVersion`:

> una función sin llamador no falla nunca

Allí era código muerto. Aquí es un botón que promete algo que no pasa, y el que lo promises
está en la pantalla de lectura, que es la que se mira todos los días.

Y no es un fallo pequeño de tiempo: es una de las ayudas de lectura que
`docs/investigacion-ux.md` señala como valiosas, y está **dentro** de un proyecto que dice
que las ayudas de dislexia son lo que diferencia un lector de otro.

---

## QUE SE HACE

Un velo del color del fondo sobre la columna de lectura, arriba y abajo, dejando una banda
clara en el centro.

## Y POR QUE UN VELO Y NO ATENUAR EL TEXTO

Porque un texto atenuado tiene un problema que no tiene arreglo: **el atenuado es el mismo
para el texto que se lee y para el que no**, y el ojo necesita ver los dos para saber qué está
leyendo. Un velo se lleva por delante el color del fondo y deja el texto intacto, así que el
contrato —15,17:1 en el oscuro— no se toca. Lo que se atenúa es la **periferia**, que es justo
lo que se quiere quitar.

Y es lo que ya se copió: en `aletheia-reader` esto es un atenuador con modulado de ancho de
pulso. En pantalla, con el texto encima, el mismo efecto se consigue con un velo continuo y
**sin parpadeo**: el PWM a velocidad de refresco se ve como parpadeo, que es peor que no
hacer nada.

## Y POR QUÉ LA BANDA ESTÁ EN EL CENTRO VERTICAL

Porque donde está el ojo ahora no se sabe; se sabe dónde está el **dedo**, que es distinto, y
en un móvil se lee a la altura de los ojos con el teléfono a media altura. Y una banda que se
moviese con el scroll tendría que ir pegada al borde de la ventana, que es justo donde no se
lee.