# Tasks

## 1. Los datos

- [x] 1.1 `librosConCapitulos()`, **una consulta** y no 66; verificar que da 66 libros y 1.189 capitulos en 8 ms
- [x] 1.2 Los numeros de capitulo son **del modulo**; verificar que Genesis da 50 y no 51
- [x] 1.3 Un libro que no esta no sale con cero capitulos; verificar
- [x] 1.4 `primeraFraseDeCapitulos(libro)`; verificar que Juan son 21 y en 1 ms
- [x] 1.5 La frase se corta **donde hay un punto**, no a un numero de caracteres; verificar
- [x] 1.6 Si no hay punto en toda la frase, se corta y se dice con puntos suspensivos; verificar
- [x] 1.7 Ninguna primera frase es cadena vacia; verificar
- [x] 1.8 El comentario no tiene capitulos y no revienta; verificar

## 2. La hoja de libros

- [x] 2.1 Se abre en el libro que se esta leyendo, no en el primero; verificar
- [x] 2.2 Enseña el capitulo que se esta leyendo; verificar
- [x] 2.3 Una fila por capitulo con su primera frase y el numero en su propia columna; verificar
- [x] 2.4 Pulsar un capitulo devuelve ESA referencia, y **conserva el versiculo en el mismo libro**; verificar
- [x] 2.5 El filtro acepta un nombre, un alias o la clave de modulo; verificar
- [x] 2.6 El filtro acepta una **referencia entera** y la ofrece como pasaje; verificar
- [x] 2.7 Escribir solo un libro **no** ofrece un pasaje; verificar
- [x] 2.8 Al escribir se sale a la lista de libros; verificar
- [x] 2.9 Lo que no esta en ningun sitio lo dice; verificar
- [x] 2.10 Los dos testamentos se separan, con la constante que ya existia; verificar
- [x] 2.11 La flecha de volver solo cuando hay a donde volver; verificar
- [x] 2.12 A 360 px no sale del borde; verificar

## 3. La hoja de versiones

- [x] 3.1 Enseña estado y tamano; verificar
- [x] 3.2 Con una sola version **lo dice**, en vez de ensenar un desplegable vacio; verificar
- [x] 3.3 Solo Biblias: un selector de version que ofrece comentarios es otra pantalla; verificar
- [x] 3.4 El filtro busca por nombre y por identificador; verificar

## 4. La cabecera

- [x] 4.1 El titulo de la barra es la cabecera: pasaje y version en dos lineas; verificar
- [x] 4.2 **Sin icono de ninguno de los dos**: se ahorra un boton; verificar
- [x] 4.3 El pasaje abre los libros y la version abre las versiones; verificar
- [x] 4.4 Las dos tienen `Semantics(button: true)` y etiqueta; verificar
- [x] 4.5 Sin manifiesto, una linea y sin hueco; verificar
- [x] 4.6 El boton de comentario pasa a icono, que es lo que le da sitio al titulo; verificar
- [x] 4.7 **El titulo tiene ancho a 360 y a 320**, medido y no "no desborda"; verificar
- [x] 4.8 La version abierta se busca en la lista preparada, no en el manifiesto; verificar

## 5. El numero del tamano

- [x] 5.1 Un **solo** formateador, en `numeros.dart`; verificar
- [x] 5.2 `Modulo.megabytes` **fuera**: devolvia `"21.5"` con punto y estaba en tres sitios; verificar
- [x] 5.3 Con **coma**, que en castellano es el decimal; verificar
- [x] 5.4 Con la unidad dentro: "Descargar, 54,9 MB" y no "Descargar, 54.9"; verificar
- [x] 5.5 Con decimal hasta cien y entero de ahi en adelante; verificar

## 6. Lo que hay que decir

- [x] 6.1 En `AGENTS.md`: los 13,9 pixeles y los 110 del boton
- [x] 6.2 Que el `overflow` no delata un titulo de 13 pixeles
- [x] 6.3 Que el primer versiculo **no** es un indice tematico, con las cuentas
- [x] 6.4 Que un selector que solo aparece con dos elementos es un selector que no se ha visto
