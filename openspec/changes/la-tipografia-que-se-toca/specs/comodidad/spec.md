# Spec Delta

## Purpose

Lo que se trae de `aletheia-reader` y que no tiene ninguno de los que se copian.

## ADDED Requirements

### Requirement: Atenuador por software

La app SHALL poder atenuar la luz con un velo, sin bajar el brillo fisico de la pantalla.

#### Scenario: Y por que un velo y no el brillo

- **WHEN** se atenua
- **THEN** se pone un velo negro encima, de 1,0 --sin atenuar-- a 0,4
- **AND** el motivo es que en web y en movil la aplicacion **no puede** bajar el brillo del
  panel, y bajarlo por software a pantalla completa es lo que hacen los lectores que no
  pueden hacerlo de verdad
- **AND** el motivo es que tambien es lo que evita el parpadeo de los paneles con PWM, que es
  lo que hace que OLED duela a los que lo tienen

#### Scenario: El velo no tapa los menus

- **THEN** el velo va por debajo de las hojas y por encima del contenido
- **AND** un boton no baja su contraste al abrirse un menu

#### Scenario: Y se guarda

- **WHEN** se atenua a 0,6 y se recarga
- **THEN** sigue en 0,6

### Requirement: Linea enfocada

La app SHALL poder marcar la linea que se esta leyendo.

#### Scenario: Como funciona

- **WHEN** esta puesto
- **THEN** hay una apertura suave de **1, 3 o 5 lineas** sobre la linea del medio
- **AND** el alto de la apertura sale de `tamanoDeLetra x altoDeLinea`, no de un numero
  escrito: si el texto grows, la apertura crece con el
- **AND** el motivo es que una apertura de un alto fijo se desajusta en cuanto se cambia el
  tamano de letra

#### Scenario: Y sigue a donde se lee

- **WHEN** se desplaza
- **THEN** la apertura se queda en el centro de la pantalla

#### Scenario: Apagada por defecto

- **THEN** por defecto esta apagada
- **AND** el motivo es que una regla de leer puesta sin querer molesta mas que ayudar

### Requirement: Puntos silabicos

La app SHALL poder poner un punto entre silabas del texto **español**.

#### Scenario: Y solo en espanol, y hay que decirlo

- **WHEN** el texto es español
- **THEN** los puntos van entre silabas, con las reglas de silabeacion del espanol
- **WHEN** el texto **no** es español
- **THEN** **NO** se pone ningun punto
- **AND** el motivo es que silabear "`For God so loved`" con reglas del espanol produce puntos
  en sitios que no son silabas, y un modo de ayuda que se activa sobre texto que no le
  corresponde no es una ayuda

#### Scenario: Y hoy es inerte, y hay que decirlo

- **AND** el unico modulo de este catalogo es el KJV, que esta en ingles, asi que el modo no
  hace nada visible hasta que haya un texto en espanol
- **AND** por eso **no** se cuenta como terminado hasta que haya un modulo en espanol con el
  que probarlo
