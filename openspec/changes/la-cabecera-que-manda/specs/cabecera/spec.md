# Spec Delta

## Purpose

Definir la cabecera de la pantalla de lectura: que lleva, como se comporta y por que el
titulo se mide.

## ADDED Requirements

### Requirement: El titulo de la barra es la cabecera

La cabecera de la lectura SHALL llevar el pasaje y el nombre de la version, cada uno en su
linea, y cada uno pulsable.

#### Scenario: El pasaje abre los libros

- **WHEN** se pulsa la linea del pasaje
- **THEN** se abre el selector de libro y capitulo

#### Scenario: La version abre las versiones

- **WHEN** se pulsa la linea de la version
- **THEN** se abre el selector de version del texto

#### Scenario: Sin manifiesto

- **WHEN** no hay nombre de version
- **THEN** **NOT** hay segunda linea ni hueco
- **AND** el motivo es que un hueco de mas empuja el texto sin motivo

#### Scenario: Para un lector de pantalla

- **WHEN** se recorre la cabecera con un lector de pantalla
- **THEN** las dos lineas se anuncian como pulsables
- **AND** **NOT** como texto plano

### Requirement: No hay icono de version

La cabecera SHALL NOT anadir un icono para cambiar de version.

#### Scenario: Los tres que hay

- **WHEN** se mira la barra a 360 px
- **THEN** hay volver, buscar y letras rojas
- **AND** **NOT** hay un icono mas

#### Scenario: Por que

- **AND** el motivo es que la interaccion mas valiosa de la categoria no cabe en un boton
- **AND** lo que hace falta es **dejarle sitio**, no anadirle sitio

### Requirement: El titulo tiene ancho, y se mide

La app SHALL medir el ancho del titulo de la cabecera a 360 y a 320 px, y SHALL NOT
considerar que basta con que no desborde.

#### Scenario: El fallo que no se ve

- **WHEN** el titulo se queda con **13,9 pixeles**
- **THEN** **NO** hay `overflow`
- **AND** el texto se recorta entero y no hay exception
- **AND** el motivo es que un `Text` corto no desborda nunca

#### Scenario: Lo que hace que pase

- **WHEN** hay un boton con la palabra "Comentario"
- **THEN** se come **110 pixeles** de una barra de 360
- **AND** con icono se le quedan 48

#### Scenario: El minimo

- **WHEN** se mide el pasaje a 360 px
- **THEN** su ancho es mayor de **60**
- **AND** a 320 px es mayor de **50**

#### Scenario: Lo que se comprueba

- **AND** la comprobacion es del ancho del widget, y **NOT** de que no haya excepcion

### Requirement: El boton de comentario es un icono

La barra SHALL llevar el comentario como icono, con su estado en el color y su nombre en
la etiqueta.

#### Scenario: Con comentario abierto

- **WHEN** hay un comentario abierto
- **THEN** el icono esta en color y la etiqueta dice cual es

#### Scenario: Sin comentario

- **WHEN** no hay ninguno
- **THEN** el icono cambia de forma y la etiqueta dice que se puede poner uno

#### Scenario: Por que no lleva texto

- **AND** el motivo es que el texto se come 110 pixeles y el nombre exacto ya estaba en la
  etiqueta
