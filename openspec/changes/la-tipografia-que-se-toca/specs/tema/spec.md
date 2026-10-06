# Spec Delta

## Purpose

Tres fondos, con el contraste medido en las nueve combinaciones de cada uno.

## ADDED Requirements

### Requirement: Tres temas de lectura

La app SHALL ofrecer tema claro, sepia y oscuro.

#### Scenario: Los tres, y por que

- **WHEN** se mira el selector
- **THEN** hay **claro**, **sepia** y **oscuro**
- **AND** el motivo es que el sepia lo usa quien lee Bibias en papel y quiere lo de papel, y
  el oscuro es lo unico legible en la cama

#### Scenario: El claro es el que hay

- **THEN** el claro es el que hay hoy, con los mismos colores
- **AND** el motivo es que cambiar el que ya estaba seria cambiarlo por gusto

#### Scenario: El oscuro no es el claro invertido

- **WHEN** se mira el oscuro
- **THEN** el rojo de las palabras de Jesus es **claro**, no el mismo rojo
- **AND** el motivo es que un rojo oscuro sobre fondo oscuro no se ve

### Requirement: El contraste se mide, no se elige

La app SHALL medir el contraste de cada color de texto sobre cada fondo, en los tres temas.

#### Scenario: Los numeros, y estan medidos

- **THEN** texto sobre fondo: **claro 16,96**, **sepia 11,81**, **oscuro 15,17** -- el
  minimo es 7:1
- **THEN** texto suave: **claro 7,14**, **sepia 5,62**, **oscuro 8,01** -- el minimo es 4,5:1
- **THEN** palabras de Jesus: **claro 7,33**, **sepia 7,15**, **oscuro 8,23**
- **THEN** acento, peligro y primario, todos por encima de 4,5:1 en los tres
- **AND** el motivo es que el rojo de las palabras de Jesus es **texto de cuerpo** y por eso
  tiene el umbral de 7:1 y no el de 4,5

#### Scenario: Y la comprobacion esta viva

- **WHEN** alguien cambia un color y lo deja en 4:1
- **THEN** la prueba se pone roja
- **AND** el motivo es que una comprobacion de contraste que no se ejecuta no comprueba nada

#### Scenario: Y el calculo es el de verdad

- **THEN** la luminancia relativa sale de los canales **lineales**, con el exponento 2,4, y la
  razon es `(L1 + 0,05) / (L2 + 0,05)`
- **AND** el motivo es que un calculo de contraste escrito a mano se equivoca: una primera
  version de esta medicion daba **6,05:1** para el rojo de las palabras de Jesus donde el
  valor bueno es **7,33**, y es que el `pow` de la calculadora estaba mal. Los numeros
  buenos de `AGENTS.md` eran los correctos y la herramienta la que mentia

### Requirement: El tema se aplica a toda la aplicacion

La app SHALL aplicar el tema a todas las pantallas, y SHALL NOT solo a la lectura.

#### Scenario: Y el atenuador va encima de todo

- **WHEN** hay atenuacion puesta
- **THEN** el velo va **encima** de todo, incluidas las hojas y los menus
- **AND** el motivo es que un atenuador que se atenua a si mismo al abrir un menu es un
  atenuador roto
