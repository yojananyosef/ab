# Spec Delta

## Purpose

Definir el selector de version, que hoy no deja comparar nada y hay que decirlo.

## ADDED Requirements

### Requirement: El selector ofrece las Biblias del catalogo

La app SHALL ofrecer en el selector de version las Biblias del manifiesto, y SHALL NOT los
comentarios.

#### Scenario: Solo Biblias

- **WHEN** hay un comentario en el catalogo
- **THEN** **NOT** aparece en el selector de version
- **AND** el motivo es que un selector de version que ofrece un comentario es otra pantalla
  y otro boton, con su propia hoja

#### Scenario: Con su estado

- **WHEN** una version no esta descargada
- **THEN** lo dice, con su tamano

#### Scenario: Sin estado redundante

- **WHEN** una version **SI** esta descargada
- **THEN** **NOT** hay una linea que diga "descargado"
- **AND** el motivo es que el icono ya lo dice y una linea de mas es ruido

#### Scenario: El estado de donde sale

- **AND** el motivo es que el estado sale de la biblioteca, que es quien sabe, y **NOT** del
  manifiesto, que es lo que ocupa en el servidor

### Requirement: El filtro busca por nombre y por identificador

La app SHALL filtrar por las dos cosas.

#### Scenario: El nombre del manifiesto

- **WHEN** se escribe "KJV"
- **THEN** sale, aunque el nombre completo sea "King James Version (2006)"

#### Scenario: El nombre de la gente

- **WHEN** se escribe "king"
- **THEN** sale tambien

### Requirement: Con una sola version, se lo dice

La app SHALL decir que solo hay un texto en el catalogo cuando solo hay uno.

#### Scenario: El catalogo de hoy

- **WHEN** se abre el selector
- **THEN** dice que solo hay un texto
- **AND** el motivo es que ensenar un desplegable con una linea donde se espera haber
  encontrado la comparacion de versiones es peor que decir que no la hay

#### Scenario: Y el boton esta

- **AND** el selector **SI** esta disponible, porque en cuanto haya una segunda version
  tiene que aparecer
