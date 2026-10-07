# Spec Delta

## Purpose

Que la apertura siga al cursor y que se pueda fijar.

## ADDED Requirements

### Requirement: La apertura sigue al raton

La app SHALL mover la apertura a donde este el cursor mientras no este fijada.

#### Scenario: Y sin raton esta en el centro

- **WHEN** el raton no esta sobre la columna
- **THEN** la apertura esta en el **centro vertical** de la columna
- **AND** el motivo es que el equivalente de «donde estoy leyendo» sin raton a la vista es el
  centro, que es donde esta la cabeza con el telefono a media altura
- **AND** con el dedo se queda en el centro, y al arrastrar esta scrolleando, que es lo unico
  que hace el dedo en un texto: si la banda lo sigue, no se puede leer

#### Scenario: Y sigue al raton al moverlo en vertical

- **WHEN** el raton se mueve dentro de la columna
- **THEN** la apertura va a la altura del cursor

#### Scenario: Y NO se pone al centro cuando el raton sale

- **WHEN** el raton sale de la columna
- **THEN** la apertura se queda donde estaba
- **AND** el motivo es que si volviera al centro seria una banda que **tiembla**: siguiendo el
  raton mientras esta dentro y volviendo al centro en cuanto sale

### Requirement: La apertura se puede fijar

La app SHALL dejar de mover la apertura cuando quien lee la fija.

#### Scenario: Y las flechas la mueven y la **fijan**

- **WHEN** se pulsa la flecha arriba o abajo
- **THEN** la apertura se mueve **una linea**
- **AND** queda **fijada**, y el raton ya no se la lleva
- **AND** el motivo es que sin fijarla la flecha no serviria de nada: en cuanto el raton se
  moviera, la banda volveria a donde este el raton

#### Scenario: Y con el dedo no se roba la pantalla

- **THEN** la apertura no se mueve al arrastrar el dedo
- **AND** el motivo es que el arrastre con el dedo es scrollear, y quien lee Juan 3 tiene
  16.848 pixeles de texto que recorrer

### Requirement: Las flechas no se comen el campo de texto

La app SHALL ignorar las flechas cuando el foco este en un campo de texto.

#### Scenario: Y con el campo «Ir a» enfocado, las flechas mueven el cursor

- **THEN** las flechas **no** mueven la apertura
- **AND** el motivo es que en la pantalla de lectura hay un campo y con las flechas dentro de
  el se mueve el cursor del texto: sin esta guarda, arreglar la banda dejaria **sin poder
  escribir en el campo**, que es el fallo mas desconcertante que hay porque no se parece en
  nada a lo que se ha roto

### Requirement: La abertura tiene margen y se ve entera

La app SHALL acotar la banda a la columna y darle margen.

#### Scenario: Y si la banda es mas alta que la columna, la banda **es** la columna

- **THEN** los dos velos se reparten lo que sobra
- **AND** el motivo es que sin esto `centro - banda / 2` sale **negativo**, los velos se salen de
  la columna y la apertura **desaparece** en vez de abrirse, que es lo que se vio: una banda
  fija arriba y sin hacer nada

#### Scenario: Y el margen es de 16 px con varias lineas y de 8 con una

- **THEN** la banda mide `lineas * altoDeLinea + margen`
- **AND** el motivo es que sin margen la banda queda pegada a la linea de arriba y a la de
  abajo, y el texto de al lado se ve **cortado** en vez de atenuado, que es un recorte de verdad
  y no un efecto de luz

#### Scenario: Y NO se recorta el numero de lineas

- **THEN** el conmutador sigue abriendo las lineas que dice
- **AND** el motivo es que recortarlas seria volver a mentir sobre lo que el boton dice
