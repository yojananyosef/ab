# Spec Delta

## Purpose

Definir como dice la URL una busqueda, que es lo que la hace compartible.

## ADDED Requirements

### Requirement: La busqueda tiene su propio prefijo

La ruta de una busqueda SHALL ser `/buscar/{modulo}/{palabra}`, y SHALL NOT ir dentro de
`/leer/`.

#### Scenario: La palabra va codificada

- **WHEN** la palabra es "in the world", "in/that", "100%" o "solo el hijo"
- **THEN** la ruta lleva la palabra codificada y al leerla sale **la misma**
- **AND** con espacios, con barra y con el tanto por ciento

#### Scenario: Con barra final es la pantalla vacia

- **WHEN** la ruta es `/buscar/KJV2006/`
- **THEN** es una busqueda sin palabra: la pantalla con el campo puesto

#### Scenario: Sin barra final no se entiende

- **WHEN** la ruta es `/buscar/KJV2006`
- **THEN** no se entiende
- **AND** el motivo es que no dice que pantalla es

#### Scenario: Con el prefijo del despliegue

- **WHEN** llega `/ab/buscar/KJV2006/begotten` o `/#/buscar/KJV2006/begotten`
- **THEN** las dos dan la misma ruta
- **AND** sin esto **toda** busqueda compartida seria un enlace roto en el sitio publicado

#### Scenario: Una ruta de busqueda no es una de lectura

- **WHEN** se comparan `/buscar/KJV2006/begotten` y `/leer/KJV2006/John.3.16`
- **THEN** **NO** son iguales
