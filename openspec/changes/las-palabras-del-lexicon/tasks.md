# Tasks

## 1. El dominio

- [x] 1.1 `AnotacionDePalabra` con `strong` y `esAnadido`, y **no** con texto; verificar que el texto no esta duplicado en la anotacion
- [x] 1.2 `TextoAnotado` con el texto **de la columna del modulo** y las anotaciones; verificar que el texto es un parametro y no un resultado
- [x] 1.3 `Versiculo` lleva las anotaciones **al lado** del texto y no dentro; verificar que `texto` no ha cambiado
- [x] 1.4 `tieneAnotaciones` (hay lista) y `tieneAlgoQuePintar` (hay algo que ensefiar) por separado; verificar que difieren

## 2. El analizador

- [x] 2.1 Recorrer el marcado con una **pila** de marcas abiertas, y no con un interruptor; verificar que `\wj` y `\nd` anidados no se descuadran
- [x] 2.2 `NOMBRE` abre y `NOMBRE*` cierra, con la estrella **dentro** del nombre; verificar que `\+w*` es un cierre y no una apertura
- [x] 2.3 El `strong` va **detras** de la palabra, asi que se asigna antes de cerrar el trozo; verificar que `Dios` lleva `G2316` y no el espacio de al lado
- [x] 2.4 Una anotacion por **palabra**, no por marca, porque la marca envuelve frases; verificar que Juan 3:16 da 25 de 25
- [x] 2.5 La puntuacion pegada a la palabra no es una palabra; verificar que `life.` es una y no dos
- [x] 2.6 Un numero del lexicon con forma rara no se acepta; verificar que `G1` y `ABCD` no lo son
- [x] 2.7 Un `\` suelto, un `*` suelto y un atributo de otro tipo no rompen el analisis; verificar los tres
- [x] 2.8 `anotarTexto` es publico para poder mirar las palabras sin el texto al lado; verificar que hay una prueba que lo usa

## 3. Los datos

- [x] 3.1 La columna `raw` se trae solo en un modulo de Biblia, y no en un comentario; verificar que el comentario no lee una columna que no tiene
- [x] 3.2 `Versiculo.anotaciones` sale del `raw` y el texto de la columna `text`; verificar que no se reconstruye

## 4. La pantalla

- [x] 4.1 Sin anotaciones se pinta con `Text` de toda la vida; verificar que el comentario sigue por el camino viejo
- [x] 4.2 Con anotaciones se pinta con `Text.rich` y **el texto sale del mismo sitio**; verificar que lo pintado es identico al del modulo
- [x] 4.3 Las palabras del traductor van **subrayadas**, no de otro color; verificar que son dos en 1 Cronicas 1:19 y ninguna en Juan 3:16
- [x] 4.4 El lexicon **no se pinta**; verificar que no hay ningun numero en pantalla

## 5. Comprobarlo

- [x] 5.1 Los 31.102 versiculos salen con el texto del modulo, sin un caracter de mas
- [x] 5.2 La cobertura va en una constante con nombre y es 97,60%
- [x] 5.3 Juan 3:16 no tiene ni una palabra del traductor, y eso es lo que hace comprobable la cifra
- [x] 5.4 `split(' ').join(' ') == texto` con mas de 500 versiculos de verdad
- [x] 5.5 `flutter analyze` limpio y `flutter test` en verde
- [x] 5.6 En `AGENTS.md`: que no hay marca de palabra divina, y las cuatro reglas del aparato de variantes
