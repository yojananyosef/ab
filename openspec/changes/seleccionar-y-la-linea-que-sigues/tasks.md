# Tasks

## 1. Seleccionar, que no existia

- [x] 1.1 `SelectionArea` alrededor de **toda** la columna, y no uno por versiculo
- [x] 1.2 Y el numero del versiculo, que esta **dentro**, sigue abreciendo la hoja: con la
      region puesta se comprueba con el dedo, no con el view model
- [x] 1.3 Y que la region abarque la columna y no el campo de buscar, que tambien tiene una

## 2. El indice a la pulsacion larga

- [x] 2.1 `TapGestureRecognizer` -> `LongPressGestureRecognizer` en las palabras con numero
- [x] 2.2 Que no quede ningun `TapGestureRecognizer` en las palabras del texto, y la prueba lo
      mira en los `TextSpan` de los `RichText` de la columna, no en toda la pantalla: la barra
      de arriba tiene botones con su propio reconocedor de toque
- [x] 2.3 Que la pulsacion larga abra el indice, que es un gesto de lectura

## 3. La banda, que se salia de la columna

- [x] 3.1 `bandaReal`: si la banda es mas alta que la columna, la banda **es** la columna
- [x] 3.2 Y los dos velos se reparten lo que sobra, con el alto de la columna medido por
      `claveDeLaColumnaEnfocada` y no por la clave de un velo: medir la columna con la clave de
      un velo da el alto de **un** velo y lo compara consigo mismo, que siempre cuadra

## 4. Pruebas

- [x] 4.1 `test/ui/seleccionar_texto_test.dart`, 6 pruebas
- [x] 4.2 `test/ui/hoja_alta_test.dart`, 5 pruebas, **incluido el marco a 1440 px**
- [x] 4.3 `test/ui/linea_enfocada_test.dart`, 9 pruebas, con la seccion 3 de la banda
- [x] 4.4 `montarLector` acepta `dentroDelMarco`, que es como se ve **de verdad** a 1440 px:
      sin marco ninguna prueba mide lo que se ve en el navegador
- [x] 4.5 795 en verde, `flutter analyze` sin avisos

## 5. Comprobado en el navegador, el 6 de octubre de 2026

- [x] 5.1 **Seleccionar funciona**: arrastrando sobre Juan 1:1 queda seleccionado
      «In the beginning was the Word» y la aplicacion **no** cambia de sitio. Antes ese mismo
      arrastre se iba al indice.
- [x] 5.2 La hoja de estilos se abre al tocar el numero del versiculo, y se ven el titulo y el
      subtitulo
- [x] 5.3 Sin errores de pagina

## 6. **PENDIENTE Y SIN RESOLVER**, escrito aqui para que no se pierda

- [ ] 6.1 **La hoja de estilos a 1440 px.** Con el paquete nuevo y el servidor correcto, medido
      en el navegador a 1440 x 900, la hoja mide **unos 140 px** y los cinco estilos quedan
      **debajo del pliegue**: se ven el titulo y el subtitulo y nada mas.
- [ ] 6.2 **No se ha podido reproducir en Dart.** Con cinco pruebas que lo miran a 360, a 768 y
      a 1440 de ancho, con la ventana a 640, a 900 y a 1200 de alto, y **dentro del marco de
      estudio** --que es como se ve de verdad a 1440 px-- los cinco estilos caben en todos los
      casos. O sea: el fallo es **del navegador** y esta prueba no lo caza.
- [ ] 6.3 La unica diferencia que queda entre la prueba y el navegador es el `useRootNavigator`
      de por defecto: la hoja se abre desde el `context` de la vista de lectura, que a 1440 px
      esta dentro del marco, y podria estar midiéndose --o colocándose-- contra otro
      `MediaQuery` o contra otro `Navigator`. **No se ha comprobado**, y no se da por
      arreglado.
- [ ] 6.4 La banda **sigue en el centro vertical** y no se mueve con el scroll. La seccion 3
      arregla que se saliera de la columna, que es otra cosa: una ventana fija no es «la linea
      que se esta leyendo». Sigue escrito en `la-linea-que-se-esta-leyendo/tasks.md`, 6.1.
- [ ] 6.5 Copiar lo seleccionado no se ha comprobado: necesita `selectionControls` y el
      portapapeles, y en el navegador pasa por la API del sistema.
