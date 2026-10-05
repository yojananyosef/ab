# Spec Delta

## Purpose

Dejar escrito como se decide que pantalla aparece al abrir, y por que hoy es la biblioteca.

## ADDED Requirements

### Requirement: Sin texto en el dispositivo se abre la biblioteca

La app SHALL abrir la biblioteca cuando no hay ningun modulo en el dispositivo.

#### Scenario: Y por que no es raro

- **WHEN** no hay ningun texto descargado
- **THEN** la biblioteca es la **unica** pantalla que puede hacer algo
- **AND** el motivo es que no hay nada que leer y no hay a donde ir
- **AND** el motivo es que un lector vacio es una pantalla en blanco con un titulo, que es
  peor que no tener nada

### Requirement: Con texto en el dispositivo NO se abre la biblioteca

La app SHALL NOT abrir la lista de modulos cuando ya hay un texto, y SHALL abrir el pasaje
donde se quedo.

#### Scenario: El estado de hoy

- **WHEN** se abre la aplicacion con un modulo ya descargado
- **THEN** hoy se abre la **biblioteca**, y eso esta mal
- **AND** el motivo es que en Logos la aplicacion abre en el texto, y quien vuelve a leer
  quiere leer

#### Scenario: Lo que falta para arreglarlo

- **THEN** hace falta **una clave mas en `Almacenamiento`** con el pasaje y la version
- **AND** `ultimoPasaje` **no existe** hoy en el codigo: no hay ninguna memoria de donde se
  estaba leyendo
- **AND** tiene que leerse **con plazo de cinco segundos**, como la preferencia de las
  palabras de Jesus, y si no contesta se abre el primer texto con el primer capitulo
- **AND** va **despues** de los paneles múltiples, que es lo que hace que tener dos sitios
  donde se esta leyendo tenga sentido
