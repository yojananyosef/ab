# Spec Delta

## Purpose

Que la cabecera del panel se parezca a la de Logos, donde el pasaje es un campo y la version
es la pestana.

## ADDED Requirements

### Requirement: El pasaje es un campo en la cabecera del panel

La app SHALL mostrar la referencia en un campo **dentro** de la cabecera, y SHALL NOT en el
cuerpo del texto.

#### Scenario: Donde esta cada cosa

- **WHEN** se mira la cabecera
- **THEN** la referencia esta en un **campo editable**, a la izquierda
- **AND** el nombre de la version esta en la **pestana** de encima
- **AND** el motivo es que en Logos la version identifica la pestana y la referencia es el
  campo: son dos datos y van en dos sitios
- **AND** **NOT** estan los dos en la barra, que es lo que hay ahora

#### Scenario: El cuerpo se queda sin cromo

- **WHEN** se mira el cuerpo del texto
- **THEN** **NO** hay campo `Ir a`
- **AND** **NOT** hay flechas de capitulo sueltas
- **AND** el motivo es que medido a 360 px eran **164 px** de campo y boton mas **48 px** de
  flechas por encima del primer versiculo

#### Scenario: Y las flechas siguen estando

- **THEN** hay un control de capitulo anterior y siguiente
- **AND** va en la cabecera del panel, no en una fila propia
- **AND** el motivo es que leer seguido es el uso mas frecuente y no se puede perder

### Requirement: El numero de version es la pestana

La app SHALL identificar el panel por su version, en una pestana encima de la cabecera.

#### Scenario: Una pestana

- **WHEN** hay un solo panel
- **THEN** hay **una** pestana con el nombre corto de la version
- **AND** el motivo es que el nombre corto cabe donde el largo no cabia nunca

#### Scenario: El nombre corto, y de donde sale

- **THEN** sale de la version, no de una lista escrita a mano
- **AND** el motivo es que "King James Version (2006)" son 24 caracteres y no caben en una
  pestana de 160 px

### Requirement: Sin cromo que no hace nada

La app SHALL NOT pintar un elemento de barra que no lleve a ninguna parte.

#### Scenario: La barra de formato de Logos

- **WHEN** se considere su segunda barra --`Contenido`, `Historia`, `Articulo`, `Conjunto de
  enlaces`--
- **THEN** se deja para cuando haya algo detras
- **AND** el motivo es que en Logos cada uno abre algo, y una barra con cuatro etiquetas que
  no abren nada es ruido con apariencia de producto

#### Scenario: Lo que si se puede llenar hoy

- **THEN** los destinos del panel de herramientas y el campo de la cabecera
- **AND** **NOT** una segunda barra
