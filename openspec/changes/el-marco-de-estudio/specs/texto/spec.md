# Spec Delta

## Purpose

Que el texto se parezca a un texto: nombre del libro encima, epigrafe y numero de capitulo.

## ADDED Requirements

### Requirement: El nombre del libro va sobre el texto

La app SHALL poner el nombre del libro en una banda sobre el texto, con su capitulo.

#### Scenario: Las migas

- **WHEN** se abre Juan 1
- **THEN** sobre el texto dice **Juan 1**
- **AND** el motivo es que es lo que hace Logos --«San Juan», «The Gospel according to John
  Chapter 1»-- y que el nombre del libro no sale en ninguna parte de la pantalla

#### Scenario: Y es un salto, no un texto

- **THEN** al pulsarlo se abre el selector de libros
- **AND** el motivo es que es la forma mas corta de ir a otro sitio y ya existe

### Requirement: El capitulo se anuncia antes de los versiculos

La app SHALL poner el numero de capitulo antes de los versiculos.

#### Scenario: El numero

- **WHEN** se abre Juan 1
- **THEN** sale un **1** grande antes del primer versiculo
- **AND** el motivo es que en un capitulo largo --Salmos 119, 176 versiculos-- saber donde se
  esta no es un detalle

#### Scenario: El ancho de la columna

- **WHEN** se mide la columna de texto
- **THEN** el capitulo se anuncia **dentro** de la columna de lectura
- **AND** el motivo es que si se sale, el texto se descentra y el ojo no vuelve al sitio de
  siempre
