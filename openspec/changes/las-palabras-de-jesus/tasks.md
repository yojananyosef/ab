# Tasks

## 1. El marcador

- [x] 1.1 `esPalabraDeJesus` en `AnotacionDePalabra`; verificar
- [x] 1.2 `\wj` se lee de la **pila**, no de una bandera; verificar que Juan 3:28 no sale rojo
- [x] 1.3 Juan 3:16 da 25 de 25 y Juan 3:29 da 0 de 32; verificar
- [x] 1.4 2.015 versiculos, 41.284 palabras, 4,94 %; verificar
- [x] 1.5 Los tres numeros de `\wj` se distinguen: 2.038 aperturas, 2.028 versiculos, 2.015 con anotaciones; verificar
- [x] 1.6 Por libro, con los evangelios y las dos citas de Cristo en Corinto; verificar
- [x] 1.7 Los 21 libros del Antiguo Testamento dan **cero palabras**; verificar
- [x] 1.8 Nunca mas palabras de Jesus que palabras; verificar
- [x] 1.9 El comentario no tiene ni una, y `raw == null` tampoco revienta; verificar

## 2. El color

- [x] 2.1 `Colores.palabraDeJesus`, y **no** `peligro` con otro nombre; verificar
- [x] 2.2 Contraste de 7,33:1 sobre el fondo y 7,71:1 sobre la superficie; verificar
- [x] 2.3 La comprobacion del contraste **viva en cada ejecucion**, no con un numero escrito; verificar

## 3. La tabla de estilos

- [x] 3.1 `estiloDePalabra` es una funcion pura, fuera del widget; verificar
- [x] 3.2 Sin marcas, estilo `null` y no el estilo base; verificar
- [x] 3.3 Del traductor: subrayado y el color del cuerpo; verificar
- [x] 3.4 De Jesus: rojo y sin subrayado; verificar
- [x] 3.5 **Las dos**: las dos marcas, no una; verificar
- [x] 3.6 Con el interruptor apagado el rojo se va y el subrayado se queda; verificar
- [x] 3.7 El tamano de la letra no cambia; verificar

## 4. El interruptor

- [x] 4.1 De partida puesto, sin preguntar; verificar
- [x] 4.2 Alterna y avisa a quien escucha; verificar
- [x] 4.3 Se guarda como `si` o `no`, legible de un vistazo; verificar
- [x] 4.4 Al reabrir se lee lo guardado; verificar
- [x] 4.5 Sin almacenamiento funciona igual y solo no guarda; verificar
- [x] 4.6 Un almacenamiento que no contesta **no rompe la lectura**; verificar
- [x] 4.7 El icono dice el estado, en el color y en el `tooltip`; verificar

## 5. En pantalla

- [x] 5.1 El texto es exactamente el del modulo, con el color puesto; verificar
- [x] 5.2 Juan 3:16 sale entero en rojo, sus 25 palabras y en su orden; verificar
- [x] 5.3 Juan 3:29 y Salmos 23:1 no tienen ni una palabra en rojo; verificar
- [x] 5.4 Con el interruptor quitado no hay rojo y el texto es el mismo; verificar
- [x] 5.5 A 320, 360 y 414 px no sale del borde, con un boton mas en la barra; verificar

## 6. Lo que hay que decir

- [x] 6.1 En `AGENTS.md`: que la seccion anterior estaba mal, y por que
- [x] 6.2 Por que son palabras de Jesus y no de Dios, con la tabla de los 21 libros
- [x] 6.3 Por que el marcador es de fiar: las dos citas de Corinto
- [x] 6.4 Que `\wj` marca y no resuelve, con Juan 3:28 y 3:29 al lado
- [x] 6.5 Que el contraste se mide y que la comprobacion esta viva
- [x] 6.6 Que cero palabras son a la vez `\add` y `\wj`, y por que la funcion es pura
- [x] 6.7 Que una preferencia sin plazo cuelga la pantalla
