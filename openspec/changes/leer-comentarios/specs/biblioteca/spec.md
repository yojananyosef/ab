# Spec Delta

## Purpose

Definir lo que la biblioteca dice de un comentario una vez descargado, y que ya no diga
que se puede leer cuando se puede.

## ADDED Requirements

### Requirement: La biblioteca ofrece leer un comentario descargado

La biblioteca SHALL ofrecer "Leer" para un comentario descargado, y SHALL NOT negarse a
abrirlo.

#### Scenario: Un comentario se descarga y se lee

- **WHEN** se descarga el CLARKE y se pulsa "Leer"
- **THEN** se abre y se ven sus notas

#### Scenario: Ya no se dice que falta la pantalla

- **WHEN** termina de descargarse un comentario
- **THEN** el aviso dice cuantas notas tiene y que esta listo para leer
- **AND** **NOT** dice que falta la pantalla de comentarios

### Requirement: El aviso de un comentario dice sus numeros, no un numero de texto

La biblioteca SHALL decir cuantas notas y sobre cuantos versiculos tiene el comentario, y
SHALL NOT announcing su numero de versiculos de texto.

#### Scenario: El CLARKE

- **WHEN** termina de descargarse
- **THEN** el aviso dice que tiene 19.742 notas sobre 19.741 versiculos
- **AND** **NOT** dice "0 versiculos", que suena a que esta vacio

#### Scenario: El nombre de la tabla no esta escrito a mano

- **WHEN** se cuenta lo que tiene un comentario al terminar la descarga
- **THEN** el nombre de la tabla sale del tipo de contenido
- **AND** **NOT** esta escrito en el codigo
