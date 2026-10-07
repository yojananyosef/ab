# Tasks

## 1. Que la banda siga al raton

- [x] 1.1 `MouseRegion` con `onHover`, y **no** `Listener`: `onHover` observa el raton y no se
      come el evento, asi que el texto de debajo sigue seleccionandose
- [x] 1.2 `_centro` a `null` es el **centro de la columna**, y no un 0: con el raton fuera, un 0
      pegaria la banda al borde de arriba
- [x] 1.3 Y se queda donde se quedo al salir el raton, que si no tiembla

## 2. Fijarla

- [x] 2.1 Flechas arriba y abajo mueven **una linea** y **fijan**
- [x] 2.2 Espacio alterna el bloqueo
- [x] 2.3 Con el dedo **no** se mueve: el arrastre es scrollear

## 3. Las flechas no se comen el campo de texto

- [x] 3.1 Se escucha en `HardwareKeyboard` y no con `Shortcuts`: `Shortcuts` es un `Focus`, y en
      la pantalla de lectura el foco esta en el campo «Ir a: Juan 3:16», con lo que las flechas
      no llegarian nunca. El original escucha en `window`, que es lo mismo
- [x] 3.2 Y se **devuelve `false`** antes de coger la tecla cuando el foco es un campo, y no
      «cogerla y soltarla»: soltar despues no evita que llegue
- [x] 3.3 Y la guarda mira el **widget** del nodo de foco, no su tipo: en Flutter el foco de un
      `TextField` lo tiene un nodo interno cuyo contexto **no** es el `EditableText`

## 4. La forma de la banda

- [x] 4.1 Margen de 16 px con varias lineas y de 8 con una, copiado del original
- [x] 4.2 Se acota a la columna, y **no** se recorta el numero de lineas
- [x] 4.3 `StackFit.expand`, **QUE HA RESULTADO SER NECESARIO**

## 5. Lo que ha salido al hacerlo

- [x] 5.1 **La columna se salia de su hueco.** Un `Stack` sin `fit` da la altura que le da al
      hijo, y el hijo es el `ListView` del capitulo entero --Juan 3 son 16.848 pixeles--, con
      lo que el `Stack` se sale de su hueco y el texto de mas tapa los terminos del modulo
- [x] 5.2 Y **ninguna prueba lo vea**: las que hay miden los velos **relativos entre si**, y eso
      sale bien con el `Stack` desbordado. Lo que lo delata es medir la columna contra su propia
      caja, que es lo que hace ahora la prueba del raton
- [x] 5.3 `claveDeLaColumnaEnfocada`, porque medir la columna con la clave de un velo da el alto
      de **un** velo y lo compara consigo mismo, que siempre cuadra

## 6. Las pruebas

- [x] 6.1 `test/ui/linea_enfocada_test.dart`, 15 pruebas: la banda sigue al raton, se queda al
      salir, las flechas mueven y **fijan**, y las flechas no se comen el campo
- [x] 6.2 Y todo el grupo 4 mide el **alto del velo de arriba**, que es relativo a la columna, y
      no el centro de la banda, que son tres coordenadas **globales**: con el `LayoutBuilder`
      dando 440 px y la caja a 551, el centro daba un numero que no era ni el bueno ni el malo
- [x] 6.3 811 en verde, `flutter analyze` sin avisos

## 7. **PENDIENTE Y SIN RESOLVER**

- [ ] 7.1 **La banda sigue sin seguir al texto al scrollear.** Lo que hay es: con el raton la
      sigue, y con el dedo esta en el centro, que es donde se lee. Lo que **no** hay es que se
      mueva con el desplazamiento, y eso es otra cosa distinta: «sigue al cursor» y «sigue al
      texto» son dos preguntas y solo la primera esta contestada.
- [ ] 7.2 **No comprobado en el navegador.** Todo esto esta probado en pruebas de widget, con
      un raton de prueba. Que un `MouseRegion` reciba los eventos en el navegador de verdad
      --sobre un lienzo, no sobre el DOM-- no se ha visto, y es el mismo sitio donde
      `scripts/comprobar-en-navegador.sh` ha encontrado fallos que ninguna prueba de Dart ve.
- [ ] 7.3 El pulsado con el dedo, en el original, **fija** la banda al arrastrar en vertical y
      ademas pasa el toque al texto de debajo. Aqui no: con el dedo la banda no se mueve. Es una
      decision y no un olvido, y esta en 1.3 del spec, pero quien prefiera el gesto del original
      no lo tiene.
