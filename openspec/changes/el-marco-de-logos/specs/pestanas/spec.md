# Spec Delta

## Purpose

Que haya pestanas de panel, y que organizen el trabajo como en Logos.

## ADDED Requirements

### Requirement: Los paneles abiertos son pestañas

La app SHALL mostrar una fila de pestañas con los paneles abiertos, y SHALL poder abrir y
cerrar paneles.

#### Scenario: La fila de pestañas

- **WHEN** hay **2** paneles abiertos
- **THEN** hay una fila de pestañas **encima** de los paneles, con el nombre de cada texto
- **AND** cada pestaña se cierra con su `X`, y hay un `+` para abrir otro
- **AND** la fila mide **40 px** de alto
- **AND** el motivo es que es lo que hace la captura de Logos, y es lo que hace util que "tengo
  dos textos abiertos" sea una cosa que se pueda **ensenar**: una tira de pestañas dice RVR60
  y JFB, y dos lineas de texto en una barra no dicen eso

#### Scenario: Y es el eje, no un adorno

- **WHEN** se pulsa una pestaña
- **THEN** ese panel pasa al frente y **los demas se quedan como estaban**, con su pasaje y su
      scroll
- **AND** cambiar de panel **no** cambia el pasaje del otro
- **AND** el motivo es que comparar dos traducciones del mismo pasaje es la interaccion mas
  valiosa de la categoria, y para eso sirven las pestañas

#### Scenario: Cerrar un panel cierra su modulo

- **WHEN** se cierra un panel
- **THEN** su `.amod` se cierra
- **AND** el motivo es que tres textos de 22,5 MiB abiertos son **67.633.152 bytes** de paginas
  SQLite, y en un movil de gama baja eso es lo que hace que el sistema mate el proceso
- **AND** la app SHALL avisar **antes** de quitar el panel de la lista y **despues** destruir su
      view model, y no al reves: al reves, el frame que se pinta entre medias muestra un panel
      abierto cuyo `.amod` ya esta cerrado, y leer de ahi da un `SqliteException` en pantalla

#### Scenario: Y cerrar un panel no lo vuelve a abrir

- **WHEN** se cierra un panel y despues se vuelve a aplicar la ruta
- **THEN** el panel **no** se abre otra vez
- **AND** el motivo es que la ruta se calcula **antes** de cerrar, con los paneles que quedan, y
      no despues: construirla despues daria una ruta con el panel cerrado, y aplicarla lo
      reabriria. Cerrar una ventana y que se vuelva a abrir sola es el peor fallo posible de
      esta pantalla

#### Scenario: Cerrar el unico panel deja la biblioteca

- **WHEN** se cierra el panel que esta delante y no queda ninguno
- **THEN** se va a la biblioteca
- **AND** el motivo es que una pantalla de lectura sin texto es una pantalla en blanco con un
      titulo, que es peor que no tener nada

### Requirement: Cuantos paneles caben lo decide un ancho, no un numero

La app SHALL decidir cuantos paneles pintar **midiendo el ancho de la columna de lectura**, y
SHALL NOT usar un numero fijo de pestanas.

#### Scenario: El corte sale de la medida

- **WHEN** la ventana es de **1.440 px**, con el panel de herramientas de **226,5 px**
- **THEN** caben **2** paneles, de **557,8 px** de columna cada uno
- **WHEN** la ventana es de **1.920 px**
- **THEN** caben **3** paneles
- **WHEN** la ventana es de menos de **1.100 px**
- **THEN** cabe **1**, y no hay pestanas
- **AND** el motivo es que con Roboto a 18 px, dos columnas a 1440 px salen de **68 caracteres**
  por linea, tres de **43** --el borde-- y cuatro de **31**, que no se lee; y a 1920 px tres
  son **63 caracteres**, que si se lee
- **AND** un "maximo de tres" escrito en el codigo seria un numero que miente en cuanto la
      ventana cambia, y con un ancho minimo de columna --**420 px**, unos 55 caracteres-- el
      numero sale solo

#### Scenario: El tope de tres es de memoria, y esta escrito por eso

- **THEN** nunca se pintan mas de **3** paneles
- **AND** el motivo es que sin ese tope, el maximo sale de `ancho / 420`, que a 2.560 px son
      **6** textos de 22,5 MiB abiertos a la vez: **135 MiB** de paginas SQLite. Y eso no lo
      mata el limite de pantalla, lo mata el movil que hay detras del navegador

#### Scenario: Y en pantalla estrecha hay pestanas, y solo una columna

- **WHEN** hay **2** paneles abiertos y la ventana es de **360 px**
- **THEN** se ven **las dos pestanas**, y **una sola columna**, con su scroll propio
- **AND** la barra de pestanas es la fila **completa**: los dos nombres, con puntos
      suspensivos si no caben, no solo el que tiene columna
- **AND** pedir abrir un segundo panel **lo abre**, y no avisa
- **AND** el motivo esta medido y es una correccion. La regla de antes --"por debajo de 1.100
      px no hay pestanas"-- salia de un argumento cierto y una conclusion falsa: a 360 px
      tres nombres son tres columnas de 60 px. Cierto, pero esos 60 px son de las **columnas
      en paralelo**, no de la **fila**. Y MEDIDO en una captura del 6 de octubre de 2026 a
      360 px con `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16`: se ve un panel y el segundo
      esta abierto --**22,5 MiB** de paginas SQLite-- y **no hay ninguna manera de llegar a
      el**. Un panel invisible no existe; una pestana con puntos suspensivos se sabe que esta
      ahi
- **AND** lo que se recorta con el ancho son las **columnas**, y no los paneles abiertos:
      abierto y alcanzable a un toque se ve; cerrado se ve que no hay nada al lado, que es
      tambien una respuesta

#### Scenario: Y los dos nombres se ven a la vez, sin desplazar

- **WHEN** hay **2** pestanas en una ventana de **360 px**
- **THEN** las dos pastillas estan en pantalla a la vez
- **AND** el ancho del nombre **se reparte** y no es un numero escrito: con 48 px de la fila
      que no son de nombre --el padding de la lista y el `+`-- y 40 por pastilla --16 de
      padding y 24 entre la `X` y su hueco-- quedan `(360 - 48 - 2 x 40) / 2 = 116 px`, y se
      topean en **200** para que en una ventana ancha una pastilla no mida 600
- **AND** el motivo es que la fila es desplazable y con un tope fijo de 200 la primera
      pastilla se comia los 360: la segunda no se perdia, se **escondia**, y quien no sepa
      que puede desplazar creeria que hay un solo texto abierto

### Requirement: En paralelo, y sin que estorbe

La app SHALL poner los paneles lado a lado cuando hay sitio, y SHALL NOT quitarle ancho a la
lectura por ello.

#### Scenario: El ancho se reparte

- **WHEN** hay **2** paneles abiertos en pantalla ancha
- **THEN** cada uno mide la mitad del espacio que hay, y **cada uno con su scroll propio**
- **AND** el panel de herramientas lateral **no** se ensancha
- **AND** el motivo es que es lo que dice `docs/investigacion-ux.md`: el panel de referencias
  no puede comerse el ancho de lectura, que es el fallo que se le atribuye a Bible Gateway

#### Scenario: Y el divisor entre columnas es un pixel, no un margen

- **THEN** entre dos columnas hay una linea de **1 px**
- **AND** el motivo es que dos columnas de texto pegadas se leen como una sola linea de 1.100
  caracteres, que es lo que hace que un texto en dos columnas sin separacion sea incomodo en
  vez de comodo

#### Scenario: Y el ancho del panel de herramientas es UN numero, en un sitio

- **THEN** `Medidas.anchoDelPanelDeHerramientas` vale **226,5 px** y es lo que se pone de
      `minExtendedWidth` del `NavigationRail`
- **AND** el motivo es que ese ancho lo necesita **quien reparte la lectura**: si el minimo
      estuviera en 176 y el reparto contara con 226,5, el dia que la etiqueta mas larga --"Comentarios"--
      creciera una letra el panel se ensancharia y **la cuenta de paneles seguiria con el
      numero viejo**, y saldrían tres columnas donde solo caben dos

### Requirement: El enlace profundo abre los paneles que dice

La app SHALL llevar el panel activo en la URL, y SHALL NOT perder el pasaje al recargar.

#### Scenario: La URL de dos ventanas

- **WHEN** se abre `/leer/KJV2006/John.3.16`
- **THEN** se abre Juan 3:16 del KJV con un panel
- **AND** recargar conserva el pasaje
- **AND** `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16` abre **dos** paneles: el KJV delante y
      el CLARKE al lado

#### Scenario: `con` y `y` son dos cosas distintas

- **THEN** `/leer/A/John.3.16/con/B` es **una** ventana con un comentario **dentro** del panel
- **AND** `/leer/A/John.3.16/y/B/John.3.16` son **dos** ventanas
- **AND** el motivo de que sean dos rutas y no una con un parametro es que con `con` no hay dos
      columnas, y con `y` no hay un comentario debajo del texto. En Logos estan las dos, y el
      que decide de las dos cosas es quien esta leyendo

#### Scenario: Con dos paneles

- **WHEN** hay dos paneles y el de delante es el CLARKE
- **THEN** la URL es `/leer/CLARKE/John.3.16/y/KJV2006/John.3.16`
- **AND** el otro no se pierde: se vuelve a abrir al lado
- **AND** el motivo es que sin esto, quien recibe el enlace ve un solo panel y no sabe que el
      otro existia

#### Scenario: Los paneles pueden estar en pasajes distintos

- **THEN** `/leer/KJV2006/John.3.16/y/CLARKE/Psalms.119.1` se entiende y abre Juan 3 en un
      panel y Salmo 119 en el otro
- **AND** el motivo es que en Logos los paneles pueden estar en sitios distintos, y obligar a
      que todos muestren la misma referencia seria inventar una regla que el producto no tiene

#### Scenario: Un panel que no se puede abrir no se lleva por delante el otro

- **WHEN** la ruta pide `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16` y el CLARKE no esta
      descargado
- **THEN** se abre **Juan 3:16 del KJV entero**, con un panel, y la direccion queda con un solo
      panel
- **AND** el motivo es que volver a la biblioteca entera seria romper la lectura del texto por
      una ventana que no se ha podido abrir

### Requirement: Los ajustes de lectura son de la ventana

La app SHALL compartir los ajustes de lectura --letra, alto de linea, espaciado, tema, y las
palabras de Jesus en rojo-- entre **todos** los paneles.

#### Scenario: Cambiar la letra en un panel se ve en el otro

- **WHEN** hay dos paneles abiertos
- **AND** se cambia el tamano de letra en uno
- **THEN** **los dos** salen con la letra nueva
- **AND** el motivo es que con los ajustes dentro del view model de lectura, cada panel tendria
      los suyos: cambiar la letra en el de la izquierda escribiria en el almacenamiento y el de
      la derecha no se enteraria hasta que se volviera a abrir. **Dos textos con dos letras
      distintas lado a lado**

#### Scenario: Y ninguna comprobacion de las que habia lo habria visto

- **THEN** el motivo es que cada view model por separado se comporta bien, asi que todas las
      pruebas que hay sobre ellos siguen dando verde con el bug puesto. Lo que no se puede
      probar en solitario es que los dos esten de acuerdo

#### Scenario: Cerrar un panel no destruye los ajustes si hay otro vivo

- **WHEN** se cierra un panel con dos abiertos
- **THEN** cambiar un ajuste en el que queda **sigue funcionando**
- **AND** el motivo es que un `dispose` que cerrara unos ajustes que otro panel sigue usando
      deja al que queda en un `ChangeNotifier` al que ya no le avisa nadie, y el resultado es un
      ajuste que se pulsa y no pasa nada --sin error y sin aviso--