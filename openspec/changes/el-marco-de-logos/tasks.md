# Tasks

## 0. Lo medido, y por que esta tarea va la primera

- [x] 0.1 Las notas al pie del `.amod` real: **6.959 notas en 5.844 versiculos** (18,79 %),
      en **913 capitulos**, media **7,6** por capitulo y maximo **35** (Daniel 11). Ancla
      dentro del versiculo en **6.956 de 6.959**.
- [x] 0.2 `\x` (referencias cruzadas): **0**. `\s1`: **35**, y las 35 son la suscripcion de
      las epistolas. Por eso los enlaces azules y los epigrafes **no se pintan**.
- [x] 0.3 El corte del marco esta en `Medidas.anchoParaPanelDeHerramientas`, **1.100 px**.
- [x] 0.4 **Lo medido al escribir las pestanas**, con Roboto a 18 px y contando con la frase
      de Santa Teresa --distinta de la de Cervantes con la que se mide el tope, porque medir con
      la misma seria circular--:

          ventana   2 paneles   3 paneles   4 paneles
          1440 px     68 car.    43 car.    31 car.
          1920 px     94 car.    63 car.    45 car.
          2560 px     94 car.    89 car.    65 car.

      Y de ahi salen **tres** decisiones que no estaban escritas: el minimo de columna
      (**420 px**), el tope de **tres** (por memoria, no por distribucion) y el hecho de que
      **el limite es un ancho y no un numero de pestanas**. Ver `test/medidas/`.

## 1. El texto: las notas al pie dejan de ser Escritura

- [x] 1.1 `NotaAlPie` en `domain/models`: la letra (`a`, `b`, `c`...), el texto, y el indice
      de palabra donde va el enganche. Inmutable, sin UI.
- [x] 1.2 El parser saca `\f + \fr REF \ft TEXTO\f*` del `raw` **y separa el texto de la
      nota**, comprobando que `text` termina exactamente en `"REF TEXTO"` joined por
      espacios. Si no cuadra, **no se separa nada** y el versiculo se pinta entero.
- [x] 1.3 `Versiculo` lleva `notas` y `texto` sin ellas. **El `texto` que se pinta es el que
      queda**, y la comprobacion de que no se ha perdido ni anadido un caracter es sobre los
      **31.102 versiculos**, como ya se hace con el marcado.
- [x] 1.4 La letra se pinta pegada a la palabra que dice el `raw`. Y el `ancla` es una **cuenta
      de palabras**, no un indice: medido, en 1Cronicas 1:6 vale 10 en un texto de 10 palabras,
      que quiere decir "despues de la ultima".
- [x] 1.5 Las notas del capitulo se listan **al final**, con su letra, y **solo si hay**:
      `NotasAlPieDelCapitulo` devuelve un `SizedBox` con la lista vacia.
- [x] 1.6 Un versiculo sin notas se pinta **exactamente igual** que ahora.
- [x] 1.7 **Juan 3 no tiene ni una nota** --medido-- y sale sin lista al pie.
- [x] 1.8 **1Cronicas 1:6** deja de teachar `1.6 Riphath: or, Diphath as it is in some
      copies` dentro del versiculo.
- [x] 1.9 Las letras van `a`..`z` y luego `aa`..`ai`, que es el **maximo medido** (Daniel 11,
      35 notas). Verificado sobre los 35, y ninguna sale como `{`, `|` ni `}`.
- [x] 1.10 El emparejamiento del lexicon **sigue casando**: de los 5.844 versiculos con notas,
      el **89,4 %** reciben anotaciones. Antes de quitar el `raw` de las notas eran **0 de
      5.844**, y ese cero es un fallo silencioso: el versiculo se ve bien y solo le falta el
      lexicon.
- [x] 1.11 La lista va **entre** el capitulo y los terminos del modulo, y no en otro sitio:
      pertenece al capitulo, y los terminos son del fichero.

## 2. Los paneles: el estado

- [x] 2.1 `PanelAbierto` en `domain/models`: el modulo, la referencia y el comentario. **El
      identificador es el del modulo**, porque dos paneles del mismo `.amod` son 22,5 MiB de
      paginas SQLite abiertas dos veces, medido.
- [x] 2.2 `PanelesViewModel`: la lista de paneles, cual esta delante, y `registrar`,
      `ponerAlFrente`, `leerEn`, `ponerComentario`, `cerrar`, `cerrarTodos`.
- [x] 2.3 **Un `LectorViewModel` por panel**, y no uno compartido: un solo view model tiene
      un unico `_abierto` y un unico `_pasaje`, y con dos textos habria que alternar entre
      ellos para pintar uno y perder el scroll del otro.
- [x] 2.4 **Los ajustes salen de `LectorViewModel` a `PreferenciasDeLectura`**, y se comparten.
      Y el `lector` del enrutador pasa a ser un **getter** sobre el panel de delante, para que
      todo el enrutador siga hablando de "el lector" sin tener que cambiar cuarenta sitios.
- [x] 2.5 Cerrar un panel cierra su `.amod`: `cerrar` **avisa antes** de destruir el view model,
      para que el frame intermedio no muestre un panel con el modulo ya cerrado.
- [x] 2.6 Volver a la biblioteca cierra **todos** los paneles, no solo el de delante.

## 3. La fila de pestañas

- [x] 3.1 `FilaDePestanas`: los nombres, la `X` de cada uno y el `+`, en una fila de **40 px**.
- [x] 3.2 **Trae su propio `Material`**, porque vive **encima** de los paneles y por eso es
      hermana de los `Scaffold` y no hija de ninguno. Sin el, los botones no funcionan y el
      error dice `No Material widget found`.
- [x] 3.3 El punto de color **solo en un comentario**, y con el color de acento. En Logos cada
      recurso lleva un color que elige quien lo tiene abierto, y **no hay ningun color en el
      manifiesto que sea "el color de esta Biblia"**: poner el `primary` seria inventar uno por
      texto. Lo que si se puede distinguir sin inventar nada es el **tipo**.
- [x] 3.4 La fila **no se pinta con un solo panel**: el nombre del texto esta en la barra, y una
      fila con un solo nombre seria el mismo dato en dos sitios.
- [x] 3.5 **No hay menu de bibliotecas ni flecha para plegar**: hay un solo sitio de donde
      leer, y plegar la fila deja la ventana sin saber cuantos textos hay.
- [x] 3.6 La `X` es de **20 px**, por debajo del minimo de pulsacion, y esta escrito por que: la
      pastilla entera es el objetivo real y ya son 40 px.

## 4. Los paneles en la pantalla

- [x] 4.1 `_zonaDePaneles` en el enrutador, y no en la vista: la fila va **encima de los dos**,
      y dentro de `LectorView` cada panel pintaria la suya.
- [x] 4.2 Cada panel con **clave de modulo**, no de indice: con la clave por indice, Flutter
      reutiliza el estado del panel del indice 0 para el modulo nuevo, y los gestos de gestor
      se quedan apuntando a un `TextSpan` que ya no existe.
- [x] 4.3 **Tantas ventanas como quepan**, por `Medidas.panelesDeLecturaQueCaben`, y no por un
      numero. A 360 px el `+` **avisa y no abre**, porque abrirlo dejaria 22,5 MiB abiertos para
      un panel que nadie ve.
- [x] 4.4 Cada panel con **su scroll propio**, comprobado arrastrando uno y mirando que el otro
      no se mueve.
- [x] 4.5 La `LectorView` puede **no pintar su `AppBar`**, y el criterio es "se ve la fila de
      pestañas", no "hay dos paneles": con dos paneles a 800 px no hay fila y la barra tiene que
      seguir ahi.
- [x] 4.6 `minExtendedWidth` del `NavigationRail` es `Medidas.anchoDelPanelDeHerramientas`, y
      no un 176 escrito ahi: el ancho del panel lo necesita **quien reparte la lectura**, y con
      los dos numeros en sitios distintos el dia que la etiqueta mas larga creciera el panel se
      ensancharia y la cuenta de paneles seguiria con el numero viejo.

- [x] 4.7 **La fila de pestañas se pinta siempre que haya mas de un panel abierto, a
      cualquier anchura**. Lo cambio una captura del 6 de octubre de 2026 a 360 px con
      `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16`: se veia un panel y el segundo estaba
      abierto sin **ninguna** manera de llegar a el. Un panel invisible no existe; una
      pestana con puntos suspensivos se sabe que esta ahi.
- [x] 4.8 La fila recibe **todos** los paneles abiertos, no los que tienen columna, y el
      ancho del nombre **se reparte**: `(ancho - 48 - 40 x paneles) / paneles`, topeado en
      200. Sin el reparto la primera pastilla se comia los 360 y la segunda se escondia.

## 5. La fila de menu

- [x] 5.1 Una fila de **36 px**, bajo la cabecera del panel, y **solo cuando no hay barra**.
- [x] 5.2 Cuatro entradas: `Buscar`, `Formato`, `Comentario` y `Notas`.
- [x] 5.3 `Notas` **solo si el versiculo trae notas al pie**, medido: 5.844 de 31.102, el
      18,79 %, y Juan 3 entero no tiene ni una.
- [x] 5.4 La entrada de comentario **dice el nombre** del que hay abierto.
- [x] 5.5 `Vista`, `Herramientas`, `Compartir`, `Inicio`, `Historia`, `Articulo`,
      `Conjunto de enlaces`, `Mas informacion` e `Informacion` **no se pintan**, entrada por
      entrada y con su motivo en `specs/menu-del-panel/spec.md`.
- [x] 5.6 `hoja_de_notas.dart`: las del versiculo, agrupadas por versiculo y con su letra. Y
      **antes** de `showModalBottomSheet` se mira si hay, porque abrir una hoja y cerrarla en el
      mismo frame es un parpadeo.
- [x] 5.7 `Notas` **no se pinta en un panel de comentario**: sus notas son de otro tipo.
- [x] 5.8 La fila es **desplazable** y cada etiqueta tiene tope de **140 px** con puntos
      suspensivos. Una prueba la cazo desbordando **88 px** con la fuente cuadrada del motor
      de pruebas; en el navegador con Roboto las tres entradas ocupan **278** de 360 y caben,
      pero con el comentario abierto la tercera dice su nombre completo y se pasa. Con el
      tope, las tres se ven enteras y solo el nombre del comentario pierde el final.

## 6. La direccion

- [x] 6.1 `RutaPaneles`, con el operador **`y`** y el panel de delante el primero.
- [x] 6.2 `Rutas.leer` y `Rutas.escribir` de ida y vuelta, y con el prefijo del despliegue.
- [x] 6.3 Un panel secundario que no se puede abrir **se salta**, y no se lleva por delante el
      otro. Volver a la biblioteca entera seria romper la lectura del texto por una ventana que
      no se ha podido abrir.
- [x] 6.4 Traer un panel al frente **reescribe la direccion**, y cerrar uno **la deja con un
      panel y no con un segmento `y` vacio**, que el parser rechaza.

## 7. Lo que se deja medido, no implementado

- [ ] 7.1 Los **epigrafes** de seccion. `\s1` sale 35 veces y ninguna es un titulo de seccion.
      Sin un modulo que los traiga no hay nada que pintar. Es cosa de `aa`.
- [ ] 7.2 Las **referencias cruzadas** y el panel de ideas. `\x` sale **0**. Es cosa de `aa`.
- [ ] 7.3 La **segunda barra** de Logos con seis entradas, que solo tendria sentido para un
      panel de articulo y no para un texto.
- [x] 7.4 Las pestanas en movil van en linea y **no** en paralelo, y ya se aplica: a 360 px
      `caben` es **una** columna y las dos pestanas siguen estando.
- [x] 7.6 Los **numeros de versiculo en linea**, que en Logos van dentro del texto, **no se
      copian**, y el motivo es una promesa de este proyecto con una prueba que la nombra:
      `test/ui/marcar_versiculo_test.dart` -- "el texto se toca para seleccionar, y quien
      esta leyendo tiene que poder llevarse 'For God so loved the world'". Un numero dentro
      del texto entra en lo copiado, y un versiculo copiado con un 16 delante ya no es el
      texto del modulo. Un numero en su propia columna esta **fuera** de la seleccion, que es
      lo unico que lo hace posible.
- [ ] 7.5 **Comparar versiones con el `+` no se puede demostrar hoy**: el catalogo tiene **una**
      Biblia, KJV2006, y es la que ya esta abierta. La hoja de versiones ofrece solo Biblias --a
      proposito, un selector de version que ofrece el Comentario es un selector que ofrece
      cambiar de texto por un comentario--, asi que no hay nada que ofrecer. Las dos ventanas
      se abren **por la ruta** `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16`, que es el caso real
      de quien recibe un enlace. Mas Biblias es cosa de `aa`.

## 8. La comprobacion en navegador

- [x] 8.1 `scripts/viz/capturar.mjs` a 360 y a 1440. Y `AB_BAJAR` para bajar un modulo por
      su boton: sin el, el perfil persistente solo tenia el KJV y la captura de dos ventanas
      salia con **un** panel, que es lo correcto y no miraba nada de lo nuevo. Flutter pinta
      en un `canvas`, asi que hay que pulsar por coordenadas, como ya hacia `pulsar.mjs`.
- [x] 8.2 Capturas de `/leer/KJV2006/1Chronicles.1.6`, que **si** tiene notas al pie, y de
      Juan 3, que no tiene ninguna --medido--, para ver las dos.
- [x] 8.3 Miradas: a 1.440 px las dos columnas salen con su texto entero, con su campo, su
      fila de menu y su scroll; a 360 px una columna y **las dos pestanas**. El `+` y la
      `X` no se salen de la fila.
- [ ] 8.4 Que `comprobar-en-navegador.sh` mire que hay **dos** paneles y no uno, y no solo
      que hay pasaje. Hoy mira el pasaje, el texto, los terminos y el historial, y ninguno de
      esos campos dice cuantos paneles hay. Es lo que falta para poder afirmar que la
      comprobacion en navegador cubre las pestañas.
- [ ] 8.5 `comprobar-en-navegador.sh` vuelve a pasar entero. Se corrigio una comprobacion
      rota de antes de este change --pedia `versiculosEnElPasaje == 1` y la aplicacion trae
      **21**, `verse >= ?`, medido-- y queda por ejecutarla de punta a punta.