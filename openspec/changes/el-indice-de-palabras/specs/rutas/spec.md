# Spec Delta

## Purpose

Definir la direccion del indice de una palabra, que es lo que lo hace compartible.

## ADDED Requirements

### Requirement: La ruta lleva el numero del lexicon

La ruta SHALL ser `/indice/{modulo}/{numero}`, con el numero tal cual lo trae el modulo.

#### Scenario: Con su letra

- **WHEN** la ruta es `/indice/KJV2006/G2316`
- **THEN** el numero va con su letra
- **AND** `G2316` y `H2316` son rutas distintas, porque `G` es griego y `H` hebreo

#### Scenario: La letra minuscula se sube

- **WHEN** la ruta es `/indice/KJV2006/g2316`
- **THEN** es el indice de `G2316`

#### Scenario: Con el prefijo del despliegue

- **WHEN** llega `/ab/indice/KJV2006/G2316` o `/#/indice/KJV2006/G2316`
- **THEN** las dos dan la misma ruta

#### Scenario: No lleva la palabra

- **WHEN** se escribe la ruta
- **THEN** **NOT** lleva la palabra
- **AND** el motivo es que `G2316` sale con cuatro escrituras en el KJV y habria que adivinar
  cual es la buena

### Requirement: Un numero invalido no se entiende

La app SHALL tratar como ruta que no se entiende lo que no es un numero del lexicon, y lo
SHALL comprobar en el parser.

#### Scenario: Una palabra

- **WHEN** la ruta es `/indice/KJV2006/God`
- **THEN** no se entiende

#### Scenario: Un numero demasiado corto

- **WHEN** la ruta es `/indice/KJV2006/G1`
- **THEN** no se entiende

#### Scenario: Una letra que no es G ni H

- **WHEN** la ruta es `/indice/KJV2006/X1234`
- **THEN** no se entiende

#### Scenario: Falta el numero, o sobra un segmento

- **WHEN** la ruta es `/indice/KJV2006/`, `/indice/KJV2006` o `/indice/KJV2006/G2316/extra`
- **THEN** no se entiende

#### Scenario: Por que en el parser

- **THEN** porque una ruta que no se entiende avisa y se queda donde estaba, y una que se
  entiende con un numero malo abre una pantalla vacia sin decir por que
