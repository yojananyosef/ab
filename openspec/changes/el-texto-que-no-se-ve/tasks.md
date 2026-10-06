# Tasks

## 1. El tema lleva su color

- [x] 1.1 `_textThemeDe(base, c)` con un `TextStyle` de fabrica que pone el color por
      defecto, para que **anadir** un estilo sin color exija escribirlo
- [x] 1.2 Los seis que se quedaban sin color, con el color puesto
- [x] 1.3 `bodySmall` y `labelSmall` con `textoSuave`, que es lo que quiere decir "secundario"
- [x] 1.4 Los que no estaban en la lista --`display*`, `headline*`, `labelMedium`-- tambien,
      porque son los del numero de capitulo y los avisos
- [x] 1.5 Y **sin** `apply` para los colores, porque `apply(bodyColor:)` tambien pisa el
      `textoSuave` explicito de `bodySmall` y `labelSmall`
- [x] 1.6 Medido antes: `#000000` sobre `#14110E` son **1,12:1**; con el color puesto en su
      sitio pero tomandolo de la paleta clara, **1,05:1**

## 2. La comprobacion que faltaba

- [x] 2.1 `test/ui/el_tema_lleva_su_color_test.dart`: el color **final** de un `Text` de
      verdad, no el del mapa del tema; verificado en los seis estilos y los tres temas
- [x] 2.2 Contra el **fondo** y contra la **superficie**, porque un modulo esta sobre el
      primero y un campo sobre el segundo
- [x] 2.3 El rojo de las palabras de Jesus por **7:1** en los tres temas
- [x] 2.4 Y el **color cruzado**: el texto del oscuro tiene que ser mas claro que el del
      claro, que es lo que hace el dano de un tema que se paints con la paleta del otro
- [x] 2.5 `themeAnimationDuration: Duration.zero`, porque `AnimatedTheme` **interpola** y el
      primer fotograma es el del tema **anterior**; medido: los tres temas daban `ff1a1714`
- [x] 2.6 `canal`, `luminancia` y `contraste` del otro fichero pasan a **publicas**, para que
      el algoritmo de WCAG siga estando en **un** sitio

## 3. Los destinos que no llevaban a nada

- [x] 3.1 `alElegirDestino` lleva `BuildContext`, y es el **del elemento del destino**, que
      esta por debajo del `Navigator`
- [x] 3.2 El panel de la izquierda y la barra de abajo pasan los dos el contexto; verificado
      a 360 y a 1440
- [x] 3.3 "Biblia" con nada abierto: `_primeraBibliaEnElDispositivo()`, que filtra por
      **tipo** y no por "el primero"
- [x] 3.4 "Comentarios" sin contexto: avisa, y no va a la biblioteca en silencio
- [x] 3.5 "Comentarios" sin texto abierto: va a la biblioteca con un motivo
- [x] 3.6 Y los cinco destinos con rama siguen compiles: el `switch` es exhaustivo y un
      `return` explicito donde antes caia de un caso al siguiente

## 4. Por que se esta en la biblioteca

- [x] 4.1 `motivoDeLaVisita`, `pedirTexto()` y `olvidarElMotivo()`
- [x] 4.2 **Fuera** de `avisos`, que es lo que hace que sobreviva a un refresco; verificado
- [x] 4.3 Se olvida al leer, porque en cuanto hay texto el motivo es falso
- [x] 4.4 `_CajaDelMotivo` en la banda, **primero**, con regla a la izquierda y no con fondo
- [x] 4.5 Boton "Bajar el primero", y no "Instalar"
- [x] 4.6 Que apaga el filtro "solo lo que tengo" antes de elegir, y que entre los
      descargables elige **una Biblia**
- [x] 4.7 La descarga llega de fuera, como los otros tres callbacks de la pantalla

## 5. Las pruebas

- [x] 5.1 `test/app/destinos_del_marco_test.dart`, 9 pruebas
- [x] 5.2 Y la comprobacion es "**ha llegado a donde tenia que llegar**", no "ha cambiado la
      ruta": `irAHome()` desde la biblioteca **no** cambia la ruta, y una comprobacion de
      "ha cambiado" pasaria con el bug puesto
- [x] 5.3 Catalogo montado a mano con un modulo de cada tipo, porque con dos Biblias "el
      primero descargado" y "la primera Biblia" darian lo mismo
- [x] 5.4 El contexto del marco se busca por **icono** y no por `tooltip`: el panel extendido
      ensena el nombre escrito y a 1440 px no hay ningun tooltip que buscar
- [x] 5.5 Suite completa: **759** en verde, `flutter analyze` sin avisos

## 6. Comprobado en el navegador

- [x] 6.1 Tema oscuro en la biblioteca: titulos, nombres y etiquetas legibles
- [x] 6.2 "Biblia" desde la biblioteca con una Biblia descargada: abre la lectura
- [x] 6.3 Con las dos descargadas: abre **la Biblia**, no el comentario
- [x] 6.4 Sin ninguna descargada: la biblioteca dice por que y ofrece bajarla
- [x] 6.5 "Comentarios" sin texto: avisa en vez de no hacer nada

## 7. Lo que queda

- [ ] 7.1 **El boton de exportar los resaltados**, que el modelo tiene y la interfaz no
- [ ] 7.2 El almacen de `IndexedDB` de los resaltados: sin el, no sobreviven a cerrar el
      navegador
- [ ] 7.3 Los destinos del marco a 1440 px con **panel**: el resto del marco esta medido a
      los dos anchos y estos tres no