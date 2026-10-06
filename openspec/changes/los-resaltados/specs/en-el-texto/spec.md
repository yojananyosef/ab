# Spec Delta

## Purpose

Poner y quitar el resaltado desde el texto, sin salir de la lectura.

## ADDED Requirements

### Requirement: El versiculo se toca

La app SHALL permitir marcar un versiculo tocandolo.

#### Scenario: Un toque abre el panel de estilos

- **WHEN** se toca un versiculo
- **THEN** sale una hoja corta con los cinco estilos y "quitar"
- **AND** el motivo es el **primer** nivel de los tres de Accordance: un toque da la
  eleccion, y el segundo --el selector de herramienta-- es opcional y sigue sin hacer

#### Scenario: Y el toque es solo en el numero

- **WHEN** se toca el texto de un versiculo
- **THEN** **NO** pasa nada
- **AND** el motivo es que el texto es para leer y hay que poder tocarlo para selectingo; un
  toque en cualquier parte del texto seria un fallo de escritura, y la palabra "seleccionar"
  es justo una de las que se usa con el dedo

#### Scenario: Un toque y ya esta puesto

- **WHEN** se elige un estilo
- **THEN** el versiculo sale marcado **inmediatamente** y la hoja se cierra
- **AND** el motivo es que un toque que deja la hoja abierta y un boton mas que pulsar son
  dos pasos, y marcar es una accion de un paso

### Requirement: El marcado se ve con el texto

La app SHALL pintar el fondo del versiculo marcado con el color de su estilo.

#### Scenario: Y el color no tapa el texto

- **WHEN** un versiculo esta marcado
- **THEN** el fondo del versiculo es el color de su estilo y el **texto se lee igual**
- **AND** el motivo es que un color de fondo saturado por encima del texto hace la Escritura
  ilegible, y un resaltado que no deja leer es un resaltado que estorba
- **AND** el motivo es que por eso el fondo va **detras** del `TextSpan` y no en un `Box` de
  color por delante

#### Scenario: Y con borde cuando el estilo lo pide

- **WHEN** el estilo es de los de "fondo y borde" o "solo borde"
- **THEN** sale tambien el **contorno** del versiculo
- **AND** el motivo es que hay quien marca con un contorno para no perder el fondo, que es lo
  que se hace en un texto con muchas marcas de colores

#### Scenario: Y el versiculo ya marcado se vuelve a marcar

- **WHEN** se toca un versiculo que ya tiene un estilo
- **THEN** se puede cambiar a otro o quitarlo, y sale cual tiene
- **AND** el motivo es que quien ya ha marcado y quiere cambiarlo tiene que poder, y no
  hacerlo obliga a quitar y volver a poner

#### Scenario: Y el fondo del versiculo no tapa los terminos del modulo

- **WHEN** se baja al final del capitulo, a los terminos del modulo
- **THEN** **NO** hay ningun fondo marcado
- **AND** el motivo es que los terminos son una **obligacion de licencia** y no texto de la
  persona, y van con su propio fondo
