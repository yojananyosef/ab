# Tasks

## 1. El widget

- [x] 1.1 `LineaEnfocada`, con `lineas`, `altoDeLinea` y `hijo`
- [x] 1.2 `isScrollControlled` no aplica aqui: lo que faltaba era que la apertura **no creciese**
      y se mide en 5.4
- [x] 1.3 `lineas == 0` sale **sin velo**, y no con una banda de alto cero; verificado
- [x] 1.4 Dos velos --arriba y abajo-- con un `LayoutBuilder`; verificado que hay **dos** con 1,
      3 y 5
- [x] 1.5 `_Velo` con `IgnorePointer`, y verificado que hay dos `IgnorePointer` con `ColoredBox`
      dentro: sin eso se come la seleccion del texto
- [x] 1.6 El color es `colores.fondo` con opacidad, y **no** un gris; verificado en los tres
      temas que sus tres canales son los del fondo
- [x] 1.7 Opacidad **0,62** en oscuro y **0,58** en claro, y no el 0,86 del atenuador de
      pantalla: aqui el velo se ve contra **quince lineas de texto**, y con 0,86 lo que hay al
      lado de la apertura queda ilegible
- [x] 1.8 `claveDelVeloDeArriba` y `claveDelVeloDeAbajo`, **dos** y no una: son hermanos en el
      mismo `Stack`, y con la misma clave los dos `find.byKey` devuelve uno solo

## 2. El cableado, que era lo que faltaba

- [x] 2.1 `LineaEnfocada` envuelve la columna de lectura en `_cuerpo`
- [x] 2.2 El alto de linea sale de `estiloVersiculo`, que ya tiene el tamano y el alto
      multiplicados; `_altoDeUnaLinea` hace `fontSize * height`
- [x] 2.3 Y NO se vuelve a multiplicar en otro sitio, que es lo que paso con el margen de la
      fila y esta en `AGENTS.md`

## 3. Las pruebas

- [x] 3.1 `test/ui/linea_enfocada_test.dart`, 7 pruebas
- [x] 3.2 La preferencia se pone con `vm.cambiarPreferencia`, que es el camino real del
      conmutador, y **antes** de montar: ponerla con la pantalla viva necesitaria comprobar que
      la vista se repinta, y una prueba que no lo comprueba pasaria con el bug entero
- [x] 3.3 Y se mide el **color de los canales** contra el fondo del tema, en los tres
- [x] 3.4 Y el invariante de la banda, y **no** un alto escrito: medido, con la tipografia de
      partida el alto de una linea sale en **65,8 px** y no en 18 por 1,6, porque
      `estiloDeLectura` calcula el tamano **para el ancho de la columna** y el ancho de una
      columna a 360 px en una prueba no es el de una pantalla real. Escribi 86,4 y la prueba
      fallaba con un numero que no era ni el bueno ni el malo

## 4. Lo que se ha encontrado de paso

- [x] 4.1 Un `TYPE ERROR` de un cast sale de **adelantar** la prueba:
      `type 'IgnorePointer' is not a subtype of type 'ColoredBox'`, porque la clave va en el
      `IgnorePointer`. Es la segunda vez que pasa, despues del `find.ancestor` del fondo del
      resaltado: un `as` convierte un "esta en otro sitio" en un fallo que no lo dice
- [x] 4.2 Una clave repetida entre hermanos no avisa: con la misma clave en los dos velos,
      `find.byKey` devolvia uno solo y el hueco salia **negativo**

## 5. Comprobado

- [x] 5.1 782 en verde, `flutter analyze` sin avisos
- [x] 5.2 Change valido con `--strict`

## 6. Lo que queda

- [ ] 6.1 **Que la banda siga al texto y no se quede en el centro.** Ahora la banda esta en el
      centro vertical de la columna y no se mueve con el scroll, que es lo que permite no
      llamarla "la linea que se esta leyendo" y si "una ventana". Sigue siendo una ayuda real
      --quita la periferia--, pero el nombre pide mas.
- [ ] 6.2 Un deslizador para elegir **cuantas** lineas, en vez de cuatro botones fijos. Con 1, 3
      y 5 hay tres saltos y quien lee con 20 px de letra quiere cuatro, no cinco.
- [ ] 6.3 Comprobarlo en el navegador a 360 px, que es el suelo duro del proyecto, y en los tres
      temas
- [ ] 6.4 El atenuador con PWM de `aletheia-reader` **no** se ha copiado: aqui el velo es
      continuo. Con el texto encima, un PWM a velocidad de refresco se ve como parpadeo. Esta
      escrito en la propuesta, y queda como decision cerrada, no como tarea.