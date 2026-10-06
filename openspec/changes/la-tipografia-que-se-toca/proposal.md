# Proposal

## Why

Medido en una captura de la pantalla de lectura a 360 px, con Juan 3 abierto:

    Juan 3, 36 versiculos, ocupa **16.848 pixeles** de alto

Trece pantallas y media de scroll para 36 versiculos. Y **no es por el ancho**: es que la
columna de texto se queda en 260 px y cada versiculo sale en cinco o seis lineas, porque el
alto de linea esta escrito a `1.7` en un sitio y **no existe ningun ajuste de tamano de
letra, ni de alto de linea, ni de espaciado, ni de fondo**.

Y el documento de investigacion ya lo pedia, linea 198: **"Tipografia: todo se toca"**.

## Y LO QUE SE TRAE DE `aletheia-reader`

Asked, por el usuario, y es un repositorio suyo. Sus especificaciones estan medidas y con
motivos escritos, que es justo el criterio de este proyecto. De ahi salen:

| | |
| --- | --- |
| **tamano de letra** | 18 px por defecto, con rango |
| **alto de linea** | 1,6 por defecto, de 1,2 a 2,5 |
| **espaciado entre letras** | 0,02 em por defecto, de 0 a 0,1 em -- y esto **no** lo tiene nadie de los tres que se copian |
| **restaurar valores** | todo a los recomendados en una pulsacion |
| **migracion de preferencias** | una clave que no exista se queda en el valor recomendado y **no** pisa lo que ya habia |

Y de ahi salen tambien las tres cosas de las que **este proyecto saca ventaja sobre Logos**,
que estan en `tasks.md` como change propio:

| | Por que se gana |
| --- | --- |
| **atenuador por software** | atenua la luz sin bajar el brillo fisico del panel, que es lo que evita el parpadeo PWM. En la noche, sinvalor para quien lee |
| **linea enfocada** | una apertura de 1, 3 o 5 lineas que sigue la lectura. Una regla de leer |
| **puntos silabicos** | puntos entre silabas en texto espanol. Ni Logos, ni Accordance, ni MyBible lo tienen |

## Y LO QUE NO SE COPIA

**La tipografia descargada.** `aletheia` usa fuentes propias; aqui los bytes de tipografia son
bytes de descarga en datos moviles, y el tema no tiene ni una fuente descargada. Los ajustes
de tamano, alto de linea y espaciado se aplican sobre la fuente del sistema.

**El `\wj`-style de stuff que no aplica.** Ver las tareas: lo que depende del idioma del texto
se comprueba con el modulo que hay.

## El contraste, medido y no elegido

Tres paletas --claro, sepia y oscuro-- y las nueve combinaciones de cada una, medidas con el
algoritmo de WCAG. **Ninguna se elige a ojo** y la comprobacion vive en cada ejecucion, como ya
vivia la del rojo de las palabras de Jesus.
