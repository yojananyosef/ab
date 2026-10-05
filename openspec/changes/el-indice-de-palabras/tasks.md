# Tasks

## 1. La ruta

- [x] 1.1 `/indice/{modulo}/{numero}`, con el numero **crudo** y con su letra; verificar que `G2316` y `H2316` son rutas distintas
- [x] 1.2 La letra minuscula se sube, porque en el modulo va en mayuscula; verificar
- [x] 1.3 Un numero que no es del lexicon **no se entiende**, y se comprueba en el parser; verificar que `/indice/KJV2006/God`, `G1` y `X1234` son rutas desconocidas
- [x] 1.4 Con prefijo del despliegue y con el hash; verificar

## 2. Los datos

- [x] 2.1 Contar **versiculos** y no ocurrencias; verificar que `G2316` da 1.171 y no 1.359
- [x] 2.2 Las palabras salen de `anotarTexto` y no de una expresion regular aparte; verificar que son las mismas que se ven al pulsar
- [x] 2.3 Las escrituras con su cuenta, sobre lo que se ensena; verificar que `God` sale primera
- [x] 2.4 Un numero que no sale da **cero**, no una lista vacia sin decir nada; verificar
- [x] 2.5 Algo que no es un numero da cero y **no busca en el texto entero**; verificar que `Dios` y `%` no devuelven 31.102
- [x] 2.6 El comentario no tiene columna `raw` y no revienta; verificar

## 3. El ViewModel

- [x] 3.1 Tres estados: cargando, con entradas, vacio y fallo; verificar que **vacio** y **fallo** son distintos
- [x] 3.2 El total y las entradas son dos numeros; verificar
- [x] 3.3 Un modulo que revienta no tumba la pantalla; verificar

## 4. La pantalla

- [x] 4.1 El numero va en grande y el total con el separador de millares; verificar `1.171`
- [x] 4.2 **Dice que no es un diccionario**, antes de la lista; verificar
- [x] 4.3 Las escrituras con su cuenta, y si hay mas de doce se dice cuantas; verificar
- [x] 4.4 Pulsar una entrada abre ese pasaje; verificar
- [x] 4.5 A 320 y 360 px no sale del borde; verificar

## 5. El lector

- [x] 5.1 Las palabras **con numero** son pulsables y las que no, no; verificar
- [x] 5.2 Un `StatefulWidget` por los **gestores de gesto**, y `dispose`; verificar que se cierran al cambiar de versiculo
- [x] 5.3 Una palabra pulsable **no lleva estilo**, y lo dice el cursor; verificar
- [x] 5.4 Si es del traductor **y** tiene lexicon, el subrayado gana; verificar

## 6. El enrutador

- [x] 6.1 La ruta abre el texto si hace falta; verificar
- [x] 6.2 Volver del indice vuelve **al pasaje**, no a Juan 1; verificar
- [x] 6.3 Es `replaceState` al abrir y `pushState` al volver; verificar por que

## 7. Comprobarlo

- [x] 7.1 `flutter analyze` limpio y `flutter test` en verde
- [x] 7.2 En `AGENTS.md`: que no hay lexicon en el modulo, y los 14.047 numeros
