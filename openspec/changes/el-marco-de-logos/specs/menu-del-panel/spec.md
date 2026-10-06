# Spec Delta

## Purpose

Que cada panel tenga su fila de menu, como en la captura de Logos.

## ADDED Requirements

### Requirement: El panel tiene una fila de menu

La app SHALL poner una fila de menu bajo la cabecera del panel, y SHALL NOT pintar entradas
que no lleven a ninguna parte.

#### Scenario: La fila aparece CUANDO DESAPARECE la barra

- **WHEN** hay **1** panel abierto
- **THEN** no hay fila de menu, y sus funciones estan en la barra de arriba
- **WHEN** hay **2** o mas paneles y se ven en pantalla
- **THEN** **no hay ninguna `AppBar`**, y hay una fila de menu por panel
- **AND** la fila de pestañas hace de barra
- **AND** el motivo esta medido: con las dos cosas a la vez son **56 px** de barra + **36** de
      fila por encima del primer versiculo, sin que la columna de texto --que es de **769 px**
      a 1440-- crezca nada. Las mismas tres funciones en dos sitios es una de cada una

#### Scenario: Y el criterio es "se ve la fila", no "hay dos paneles"

- **WHEN** hay **2** paneles abiertos en una ventana de **800 px**
- **THEN** no hay fila de pestanas --por debajo de 1.100 px no cabe el paralelo-- y **la barra
      sigue poniendo**
- **AND** el motivo es que si la barra desapareciera siempre que hay dos paneles, a 800 px la
      pantalla no diria en ningun sitio que texto se esta leyendo

#### Scenario: Las entradas que si llevan a alguna parte

- **THEN** `Buscar` y `Formato` **siempre**, porque las dos tienen algo detras siempre
- **THEN** `Notas` **solo si el versiculo que se esta leyendo trae notas al pie**
- **THEN** `Comentario` **siempre**, y su texto **cambia con el estado**: con comentario
      abierto dice **el nombre**, y sin comentario dice `Comentario`
- **AND** el motivo de que el texto cambie es que un icono de bocadillo en un menu dice "aqui
      hay comentarios" y no dice cuales, y quien esta leyendo Juan 3:16 con el CLARKE al
      lado necesita poder confirmar de un vistazo que lo que tiene al lado es lo que pidio

#### Scenario: Lo que NO se pinta, y por que

- **THEN** de las trece entradas de la captura de Logos --siete en la fila de menu y seis en
      la segunda barra-- se pintan **cuatro**
- **AND** el motivo esta medido, entrada por entrada:
  - `Inicio`, `Vista`, `Herramientas` y `Compartir` **no tienen nada detras** en este
    proyecto. Un elemento de menu que no lleva a ninguna parte es peor que uno que no existe,
    porque enseña a usar la aplicacion con una promesa que no se puede cumplir
  - `Historia` y `Articulo` son de un **articulo** y de su historia editorial. Este catalogo
    tiene una Biblia y un comentario: no hay articulos
  - `Conjunto de enlaces` es el **panel de ideas** con las referencias cruzadas, y `\x` sale
    **0 de 31.102** versiculos: no hay nada que enlazar
  - `Mas informacion` del recurso es la licencia, la atribucion y los defectos, que **ya estan
    al pie del capitulo**, visibles y sin menus. Moverlos a un menu seria esconder una
    obligacion de licencia del repositorio hermano, y hay escrito que una obligacion que hay
    que ir a buscar no se cumple

#### Scenario: Y no hay dos filas

- **THEN** hay **una** fila, de **36 px**
- **AND** el motivo esta medido: las dos filas de Logos son 7 + 6 = 13 entradas y
      **208 px** de cromo encima del primer versiculo, con el versiculo de Juan 3 --122 px
      medidos-- en el 16 % de una pantalla de 760. El cromo crece y el texto no

### Requirement: `Notas` muestra las del versiculo, no las del capitulo

La app SHALL mostrar en `Notas` **las del versiculo que se esta leyendo**, y SHALL NOT abrir
una hoja vacia.

#### Scenario: La hoja

- **WHEN** se pulsa `Notas` y el versiculo trae notas al pie
- **THEN** se ven **con su letra y a que versiculo es cada una**
- **AND** el titulo dice **de que** son, y el numero dice cuantas
- **AND** el motivo de las dos cosas es que la lista del pie del capitulo se le parece mucho --
      son **7,6** de media--, y quien las ve las dos sin diferencia cree que son lo mismo

#### Scenario: Y si no hay, no se pinta la entrada

- **WHEN** el versiculo que se esta leyendo no trae ninguna nota
- **THEN** la entrada `Notas` **no existe**
- **AND** el motivo esta medido: de los **31.102** versiculos del KJV, **5.844** traen notas --
      el **18,79 %**--, asi que de cada cinco versiculos, cuatro no tienen ninguna. Y Juan 3
      entero no tiene ni una
- **AND** una entrada que al pulsarla abre una hoja que dice "no hay" es peor que una que no
      existe

#### Scenario: Y en un panel de comentario tampoco

- **WHEN** el panel que esta delante es un comentario
- **THEN** no hay entrada `Notas`
- **AND** el motivo es que las notas de un comentario son de **otro tipo** y salen debajo de
      cada versiculo; preguntar por notas al pie a un panel de comentario daria una lista
      vacia

#### Scenario: El numero maximo, medido

- **THEN** la hoja cabe sin scroll en el caso normal, y **no recorta** si un modulo trae mas
- **AND** el maximo medido es **3 notas por versiculo**, sobre las **6.959** del KJV, y esta
      escrito para que un cambio en el parser se note en una prueba y no en una hoja con treinta
      lineas

### Requirement: La fila no se come la barra

La app SHALL medir la fila nueva contra el campo de referencia, y SHALL NOT dejarlos
competir.

#### Scenario: El campo sigue teniendo la pantalla

- **WHEN** la ventana es de **360 px**
- **THEN** el campo de referencia mide lo que mide hoy, y la fila de menu va **debajo**
- **AND** el motivo es una medida ya escrita: a 360 px cinco `IconButton` son **240 px** y del
  campo quedan **98**, que no caben ni con "Juan 3:16" dentro
- **AND** por eso la fila de menu **no** se pone en la barra, sino en su propia linea

#### Scenario: En horizontal NO se juntan, y por que

- **WHEN** la ventana es de **1.440 px**
- **THEN** la fila de menu y el campo de referencia caben en la misma linea, y **aun asi no se
      juntan**
- **AND** el motivo es que en la captura de Logos, a lo ancho, la fila va en la misma barra que
  el campo, y aqui juntarlas haria que la cabecera del panel dejase de ser "donde se ve que
  texto y que pasaje" y pasase a ser un menu mas. Lo que se busca en una cabecera de lectura es
  la referencia

#### Scenario: Y la fila es desplazable

- **THEN** las entradas se pueden desplazar horizontalmente
- **AND** el motivo esta medido: cuatro entradas con icono y texto son unos **405 px**, y con el
  `+` no caben a 360. Una entrada que se sale del borde es una entrada que no se puede pulsar