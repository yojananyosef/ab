# Tasks

## 1. Las fuentes

- [x] 1.1 Las tres del repo hermano, **OFL 1.1**, que permite redistribuir
- [x] 1.2 La licencia de cada una al lado, en `assets/fuentes/`, y **probado**: una prueba
      comprueba que los tres ficheros existen, que no estan vacios y que las tres licencias
      dicen «SIL Open Font License»
- [x] 1.3 Una prueba que mira `pubspec.yaml` de verdad, y no una constante: comprobar que hay
      tres fuentes no es que el enum tenga tres, es que los tres `.ttf` estan con el nombre que
      dice el enum

## 2. La preferencia

- [x] 2.1 `TipografiaDeLectura` con las tres y la cuarta, que es `null` y no `''`
- [x] 2.2 Se guarda la **familia**, y no un indice
- [x] 2.3 `desdeFamilia` **devuelve** la del sistema si el nombre no se conoce, y no lanza
- [x] 2.4 El motivo de 2.3 esta en el codigo: un fichero de ajustes es dato de la persona, y
      perder cinco ajustes por un nombre de fuente es el fallo peor posible
- [x] 2.5 Y una prueba con el nombre **cambiado a mano**, que es lo que haria un fichero
      editado, que comprueba que los otros cinco ajustes siguen ahi

## 3. Que llegue al texto

- [x] 3.1 `fontFamily` en `estiloDeLectura`, y **no** en cada `Text`: si el nombre se escribiera
      en dos sitios, un dia divergen, que es lo que paso con el margen de la fila
- [x] 3.2 `_Tipografia` en la hoja de formato, con un `DropdownButton` y no un `SegmentedButton`:
      son cuatro opciones con nombre largo y motivo, y `SegmentedButton` parte las lineas y deja
      la fila con tres alturas
- [x] 3.3 El motivo de la elegida, **debajo** del desplegable: dentro de cada opcion habria que
      abrir el desplegable para leerlo, y la hoja se cierra al elegir

## 4. **PENDIENTE Y SIN RESOLVER**, escrito aqui para que no se pierda

- [ ] 4.1 **NO SE HA COMPROBADO QUE LA FUENTE LLEGUE AL VERSICULO QUE SE PINTA.** Es la ultima
      milla y es la que importa: hay **dos** sitios donde la fuente se puede perder sin que nada
      falle --que la hoja guarde pero `estiloDeLectura` no la ponga, o que la ponga pero la
      columna no use `estiloDeLectura`-- y los dos darian verde con una prueba que mirase solo la
      preferencia.
- [ ] 4.2 Se escribio esa prueba y **no se ha conseguido que pase**. Lo que se sabe: la
      preferencia llega a `estiloDeLectura` --comprobado por separado: devuelve `Literata`--, y
      el texto del versiculo **no** sale con ella. Se han descartado dos finders erroneos y el
      tercero seguia dando `null`, y no ha quedado margen para aislar donde se pierde.
- [ ] 4.3 Y POR ESO **NO SE HA DEJADO LA PRUEBA EN EL REPOSITORIO**, ni verde ni en rojo. Una
      prueba en rojo rompe la garantia de que la suite esta verde, y una prueba debilitada --
      «que no lance», «que sea una de las tres»-- pasa sin comprobar lo nuevo, que es lo que
      `AGENTS.md` llama la comprobacion que puede pasar sin comprobar.
- [ ] 4.4 **Lo que si esta comprobado**, en 11 pruebas: que las cuatro sobreviven a guardar y
      leer, que la de partida es la del sistema, que un nombre desconocido **no** rompe los otros
      cinco ajustes, que ninguna familia se repite, que cada una tiene motivo, que los nombres
      son los del repo hermano, y que los tres ficheros y las tres licencias estan en el disco
- [ ] 4.5 **No comprobado en el navegador.** Que Flutter pinte con una fuente empaquetada en un
      lienzo, no en el DOM, no lo ha visto ninguna prueba de Dart.
- [ ] 4.6 **Literata es una fuente variable** --ejes `opsz` y `wght`-- y se declara con un solo
      fichero. El `fontWeight` de los titulos puede no hacer nada, que es un fallo que sale en
      pantalla y no en el analizador, y no se ha medido.
