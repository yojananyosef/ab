# Spec Delta

## Purpose

Que se pueda seleccionar el texto y que tocar una palabra no se lo lleve.

## ADDED Requirements

### Requirement: El texto de la lectura se puede seleccionar

La app SHALL envolver la columna de lectura en una region de seleccion.

#### Scenario: Y la region es **una**, y no una por versiculo

- **THEN** hay **una** region de seleccion alrededor de toda la columna
- **AND** el motivo es que con una por versiculo no se puede seleccionar a caballo de dos
  versiculos, y una frase partida en dos es la que se copia
- **AND** el motivo es que `SelectableText` no acepta `TextSpan` con reconocedores, asi que la
  region va **alrededor** de la columna y no sobre cada versiculo

#### Scenario: Y la region abarca la columna, y no el campo de buscar

- **THEN** la region llega del borde superior al inferior de la columna
- **AND** el motivo es que hay mas de un `SelectionArea` en la pantalla, y uno alrededor del
  campo de buscar comprobaria lo mismo y dejaria el texto sin seleccionar

### Requirement: Tocar una palabra NO se lleva la seleccion

La app SHALL abrir el indice con un gesto que no compita con la seleccion.

#### Scenario: Y no hay reconocedor de toque por palabra

- **THEN** ninguna palabra del texto tiene un `TapGestureRecognizer`
- **AND** el motivo es que el toque es el gesto que pide el dedo, y con el lexicon del KJV --
  **348.884 ocurrencias en 31.102 versiculos**-- seria en practica todas las palabras

#### Scenario: Y el indice se abre con pulsacion larga

- **THEN** las palabras con numero de lexicon abren el indice con pulsacion larga
- **AND** el motivo es que la pulsacion larga **ya era** el gesto de seleccionar: los dos gestos
  existian y solo estaban peleando, y se decide cual de los dos nombra el indice

#### Scenario: Y marcar por el numero sigue funcionando

- **THEN** el numero del versiculo abre la hoja de estilos con la region de seleccion puesta
- **AND** el motivo es que el numero esta **dentro** de la region, y una region que se lleva los
  toques dejaria sin poder marcar, que es como se marca en esta app

### Requirement: La banda de la apertura no se sale de la columna

La app SHALL acotar la banda a la altura de la columna de lectura.

#### Scenario: Con cinco lineas pedidas y una columna baja

- **WHEN** la banda sale mas alta que la columna
- **THEN** la banda **es** la columna
- **AND** los dos velos se reparten lo que sobra
- **AND** el motivo es que sin esto `porArriba` sale **negativo**, el `clamp` lo deja en 0, los
  dos velos miden cero y la apertura **desaparece** en vez de abrirse: que es lo que vio
  quien lo probo, y parecia que no siguiera al scroll

#### Scenario: Y no se recorta el numero de lineas

- **THEN** el conmutador sigue abriendo las lineas que dice
- **AND** el motivo es que recortarlas seria volver a mentir sobre lo que el boton dice, que es
  el fallo que este change vino a arreglar
