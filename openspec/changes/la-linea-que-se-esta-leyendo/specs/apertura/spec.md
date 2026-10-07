# Spec Delta

## Purpose

Que el conmutador de la línea que se está leyendo haga lo que dice.

## ADDED Requirements

### Requirement: El conmutador pone la apertura sobre la columna de lectura

La app SHALL pintar la apertura cuando la preferencia dice que hay mas de cero lineas.

#### Scenario: Apagada, una, tres y cinco lineas

- **WHEN** la preferencia es 0, 1, 3 o 5
- **THEN** con 0 **no** hay apertura ninguna
- **AND** con 1, 3 o 5 hay **una** banda de ese numero de lineas en el centro de la columna
- **AND** el motivo es que 0 y 1 no son lo mismo: con 0 el conmutador esta apagado, y una banda
  de alto **cero** es la columna entera velada, que es leer a oscuras

#### Scenario: Y el velo es del color del fondo, y no un gris

- **THEN** el velo usa `colores.fondo`, con una opacidad
- **AND** el motivo es que un gris encima de un crema se ve como una mancha y encima de un
  fondo casi negro se ve como niebla
- **AND** con el color del fondo lo que se atenua es la luz que llega del fondo y el texto se
  queda con su contraste de **15,17:1** en el oscuro

#### Scenario: Y la apertura no come toques

- **THEN** los velos van dentro de un `IgnorePointer`
- **AND** el motivo es que sin el se comen la seleccion del texto, y el sintoma seria «no
  puedo copiar un versiculo», que no apunta a nada

#### Scenario: Y dos velos, no uno con un hueco

- **THEN** hay un velo arriba y otro abajo
- **AND** el motivo es que un solo velo con un hueco obliga a un `Path` con un recorte, y el
  recorte se ve mal en cuanto el alto de la columna no es multiplo del de linea: el borde sale
  a medio pixel y se ensena una linea gris que no esta en el texto

### Requirement: El alto de una linea sale del texto que se esta pintando

La app SHALL calcular el alto de linea con el **mismo** estilo que pinta el texto.

#### Scenario: Y `height` es un multiplicador

- **WHEN** se calcula el alto de una linea
- **THEN** es `fontSize * height`
- **AND** el motivo es que `TextStyle.height` es un multiplicador: 18 px con 1,6 son 28,8 px, y
  tomado como pixeles daria una banda de 1,6 px, mas fina que una linea de texto

#### Scenario: Y no se vuelve a multiplicar en otro sitio

- **AND** la vista usa el estilo de lectura que **ya** tiene el tamano y el alto
- **AND** el motivo es que son las mismas dos cifras en dos sitios y un dia divergen, que es lo
  que paso con el margen de la fila --`14` en un sitio y `margenPara` en otro-- y que esta
  escrito en `AGENTS.md`

#### Scenario: Y la banda es mas baja cuando se abren mas lineas

- **WHEN** se pasa de una linea a tres y a cinco
- **THEN** el velo de arriba **baja** en cada paso
- **AND** el motivo es que mas banda quiere decir menos velo, y un conmutador que abre mas
  lineas y apaga mas pantalla esta al reves de lo que dice
