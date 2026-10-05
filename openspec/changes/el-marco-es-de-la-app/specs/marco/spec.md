# Spec Delta

## Purpose

Que el marco sea de la aplicación y no de una pantalla.

## ADDED Requirements

### Requirement: El marco lo pone el enrutador

La app SHALL envolver **todas** las pantallas en el marco, y SHALL NOT ponerlo en una sola.

#### Scenario: Las cuatro pantallas

- **WHEN** se mira cualquiera de las cuatro pantallas
- **THEN** las cuatro tienen panel lateral a partir de **1100 px**, y barra de destinos por
  debajo
- **AND** el motivo es que el marco describe la aplicacion y no una pantalla

#### Scenario: Cambiar de destino no saca del marco

- **WHEN** se pulsa Biblioteca en el panel lateral
- **THEN** la biblioteca **sigue dentro** del marco
- **AND** el motivo es que si no, ir a un destino te saca de la aplicacion

#### Scenario: Y ninguna prueba lo cazaba

- **AND** el motivo es que las pruebas del enrutador se montaban a **360 px**, y por debajo de
  1100 hay barra de destinos y las cuatro pantallas se ven igual
- **AND** el motivo es que **el fallo solo existe por encima de 1100 px**

#### Scenario: Y el tamano de la prueba es un parametro

- **WHEN** una prueba del enrutador necesita ver el panel lateral
- **THEN** monta a **1440 px**
- **AND** el motivo es que una prueba que fija 360 px no puede ver un fallo que no existe a
  360 px

### Requirement: El destino marcado sale de la ruta

La app SHALL deducir el destino de la barra de la ruta activa, y SHALL NOT recibirlo como
parametro.

#### Scenario: Una tabla, y no una cadena de `if`

- **WHEN** se deduce el destino
- **THEN** hay un `switch` sobre la ruta, con un caso por tipo
- **AND** el motivo es que hay cinco destinos y cuatro tipos de ruta y la combinacion se
  olvida antes de que se note

#### Scenario: Lectura sin texto cae a la biblioteca, y lo dice

- **WHEN** la ruta es de lectura y no hay texto abierto
- **THEN** lo que se ve es la biblioteca
- **AND** el destino marcado es **Biblioteca**
- **AND** el motivo es que si la marca se queda en Biblia, lo que se ve y lo que la barra
  dicen son dos cosas distintas

#### Scenario: La ruta que no se conoce

- **WHEN** la ruta no es ninguna de las cuatro
- **THEN** el destino marcado es **Biblia**
- **AND** el motivo es que el `switch` tiene que ser exhaustivo y el analisis avisa del caso
  que falta
