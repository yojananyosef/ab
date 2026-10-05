# Spec Delta

## Purpose

Definir como se escribe un tamano en castellano, en un solo sitio.

## ADDED Requirements

### Requirement: Un solo formateador de tamano

La app SHALL formatear los bytes en **un** sitio, y el dominio SHALL NOT formatearlos.

#### Scenario: Lo que habia

- **WHEN** se pide el tamano de un modulo al modelo
- **THEN** **NOT** hay un `megabytes` en el dominio
- **AND** el motivo es que estaba en tres sitios de la interfaz

#### Scenario: Y estaba mal en los tres

- **WHEN** se imprimia el tamano
- **THEN** salia `"21.5"` con punto
- **AND** en castellano el punto separa los millares y la coma los decimales

#### Scenario: El unico sitio

- **WHEN** se formatea un tamano
- **THEN** se usa el formateador de la interfaz
- **AND** el motivo es que un formateador de lo que se ve es de la interfaz

### Requirement: El decimal es una coma

La app SHALL escribir el decimal con **coma** en todo tamano.

#### Scenario: El numero

- **WHEN** se formatean 22.544.384 bytes
- **THEN** sale `21,5 MB`
- **AND** **NOT** `21.5 MB` ni `22,5 MB`

#### Scenario: Por que 21 y no 22

- **AND** el motivo es que es dividir por 1.048.576, que es un mebibyte, y no por un millon

### Requirement: El boton lleva la unidad

La app SHALL poner la unidad **dentro** del boton de descarga.

#### Scenario: Lo que dice

- **WHEN** se ofrece descargar un comentario
- **THEN** el boton dice "Descargar, 54,9 MB"
- **AND** **NOT** "Descargar, 54.9", que no dice de que son los 54,9

### Requirement: Con decimal hasta cien

La app SHALL poner un decimal por debajo de cien megabytes y ninguno por encima.

#### Scenario: Decision de descarga

- **WHEN** el tamano esta por debajo de cien
- **THEN** lleva un decimal, porque la diferencia entre 22,5 y 22 cambia la percepcion

#### Scenario: Ruido por encima

- **WHEN** el tamano esta por encima de cien
- **THEN** es un entero, porque un decimal no se distingue de un vistazo
