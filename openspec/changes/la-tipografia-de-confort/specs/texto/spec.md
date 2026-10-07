# Spec Delta

## Purpose

Que la tipografia de confort se pueda elegir, y que llegue al texto.

## ADDED Requirements

### Requirement: La tipografia de confort es elegible

La app SHALL ofrecer cuatro tipografias y aplicarlas al texto de lectura.

#### Scenario: Y son cuatro opciones, y no tres

- **THEN** hay tres fuentes y una opcion de **no poner ninguna**
- **AND** el motivo es que son tres fuentes nuevas, pero cuatro opciones, y la cuarta es dejar la
  del sistema

#### Scenario: Y cada opcion dice para quien sirve

- **THEN** cada opcion enseña su motivo, y no solo su nombre
- **AND** el motivo es que «Atkinson Hyperlegible» no dice a quien le sirve, y una lista de tres
  nombres de fuente sin explicacion hace que quien no sepa cual elegir la elija al azar, que es
  como se quedan las tres sin usar

#### Scenario: Y la fuente llega al **texto que se pinta**

- **WHEN** se elige una tipografia
- **THEN** el texto de los versiculos se pinta con esa familia

#### Scenario: Y sin tocar nada sigue la del sistema

- **THEN** el `fontFamily` es `null`, que es «deja la que haya»
- **AND** el motivo es que una cadena **vacia** es el nombre de una fuente que no existe, con lo
  que el motor cae en la de reserva y el texto sale con una letra que nadie ha pedido

### Requirement: Guardar la familia, y recuperarla suave

La app SHALL guardar el **nombre** de la familia y no un indice.

#### Scenario: Y sobrevive a guardar y leer

- **THEN** las cuatro tipografias vuelven iguales tras un `serializar` y un `deserializar`

#### Scenario: Y un nombre desconocido NO rompe los otros ajustes

- **WHEN** el fichero guardado tiene un nombre de fuente que esta version no conoce
- **THEN** la tipografia cae en la del sistema
- **AND** el tamano, el alto de linea, el espaciado, el tema y la atenuacion **siguen ahi**
- **AND** el motivo es que un fichero de ajustes es **dato de la persona**: perder cinco ajustes
  por un nombre de fuente es el fallo que `AGENTS.md` llama el peor posible
