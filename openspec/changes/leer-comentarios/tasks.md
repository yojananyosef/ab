# Tasks

## 1. El dominio

- [x] 1.1 Anadir `Nota` con `versiculo`, `orden` y `texto`, y **no** como un `Versiculo`; verificar que un versiculo y una nota no son intercambiables
- [x] 1.2 Anadir `notas` a `Pasaje`, con `vacio` y `total` que cubran los dos; verificar que un pasaje de comentario con notas **no** se pinta como vacio
- [x] 1.3 Anadir `traeNotas`, `notasDe(versiculo)` y `versiculosConNota`; verificar que se deducen de las listas y **NOT** de un parametro que se pueda contradecir
- [x] 1.4 Anadir `tablaDeContenido` a `TipoDeContenido`, con `null` para el tipo desconocido

## 2. Los datos

- [x] 2.1 Que las ocho consultas usen la tabla del tipo y **NOT** un nombre escrito a mano; verificar con una prueba que lee el fichero
- [x] 2.2 `leer` devuelve versiculos o notas segun el tipo, en listas separadas; verificar que un comentario **NOT** devuelve texto de Biblia
- [x] 2.3 `numerosDeVersiculos` con `DISTINCT`, porque hay un versiculo con dos notas; verificar que el selector no lo ofrece dos veces
- [x] 2.4 `totalDeVersiculos` contando **pasajes** y no numeros de versiculo; verificar que el KJV da 31.102 y no 176
- [x] 2.5 `totalDeNotas`, que en una Biblia da 0 y no revienta; verificar que la tabla `verses` no tiene `seq`
- [x] 2.6 Quitar las notas repetidas del mismo versiculo con el **mismo texto**, y solo esas; verificar que se quita la de Mateo 23:13 y no se toca ninguna mas
- [x] 2.7 `buscar` tambien busca en un comentario; verificar que devuelve los mismos tres campos en las dos tablas

## 3. La pantalla

- [x] 3.1 Un `if` sobre el pasaje, y **NOT** uno por fragmento; verificar que una nota y un versiculo no se pueden pintar con el mismo formato
- [x] 3.2 Las notas se agrupan por versiculo, con su numero y con un separador; verificar que dos notas del mismo versiculo no se separan y dos de distintos si
- [x] 3.3 Cuerpo mas pequeno que el de los versiculos, con barra vertical; verificar midiendo los dos tamanos y no por opinion
- [x] 3.4 Nombre accesible de cada nota, con el versiculo al que se refiere
- [x] 3.5 Que un versiculo sin nota diga que no existe y **NOT** ensene un hueco con su numero; verificar el texto exacto que sale

## 4. La biblioteca

- [x] 4.1 El aviso de descarga de un comentario dice cuantas notas tiene y que esta listo para leer; verificar que ya no dice "falta la pantalla"
- [x] 4.2 Que el nombre de la tabla salga tambien aqui del tipo, y no escrito a mano; verificar que no queda ninguno

## 5. Comprobarlo

- [x] 5.1 Pruebas con el CLARKE y el KJV **reales**, no inventados; verificar que los tres numeros --19.742 notas, 19.741 pasajes, 66 libros-- estan medidos
- [x] 5.2 Pruebas de la vista a 360 px; verificar que una nota de 405 caracteres y otra de 2.709 no salen del borde
- [x] 5.3 `flutter analyze` sin avisos y `flutter test` en verde
- [x] 5.4 Dejar en `AGENTS.md` el `count(DISTINCT verse)` que da 176, y la fila repetida que `defects_count` no declara
