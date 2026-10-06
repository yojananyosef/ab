# Spec Delta

## Purpose

Que el texto de lectura se pueda ajustar, y que los valores por defecto no sean una suposicion.

## ADDED Requirements

### Requirement: Tres ajustes de tipografia

La app SHALL ofrecer tamano de letra, alto de linea y espaciado entre letras.

#### Scenario: El tamano

- **WHEN** se mira el texto de lectura
- **THEN** sale con el tamano de la preferencia, de **15 a 26 px**
- **AND** el valor por defecto es **18**
- **AND** el motivo es que el 16 px de este tema era el minimo de un **campo de texto**, que es
  otra cosa: por debajo de 16 el navegador del movil hace zoom al enfocar un campo. El cuerpo
  del texto no tiene ese problema y a 16 px se lee corto para rato largo

#### Scenario: El alto de linea

- **THEN** va de **1,2 a 2,5**, con 0,1 de paso
- **AND** el valor por defecto es **1,6**
- **AND** el motivo es que el valor anterior era 1,7 y estaba escrito en un `copyWith` del
  cuerpo de la vista, que es donde no se toca

#### Scenario: El espaciado entre letras

- **THEN** va de **0 a 0,1 em**
- **AND** el valor por defecto es **0,02 em**
- **AND** el motivo es que en un textojustificado a columna estrecha las letras se pegan, y
  esto no lo tiene ninguno de los tres que se copian

#### Scenario: Y los tres se aplican a la vez

- **WHEN** se cambian los tres
- **THEN** el texto se repinta con los tres, sin recargar

### Requirement: Los ajustes se guardan

La app SHALL guardar los tres ajustes, y SHALL NOT perderlos al recargar.

#### Scenario: Una sola clave, y por que

- **WHEN** se guardan
- **THEN** van en **una** clave, con los cinco campos juntos
- **AND** el motivo es que `Almacenamiento` guarda texto, y cinco `await` sobre un
  `localStorage` que hay un caso medido de que **nunca contesta** son cinco oportunidades de
  colgar la pantalla

#### Scenario: El plazo, y es el de siempre

- **AND** se leen con **cinco segundos** de plazo, como la preferencia de las palabras de Jesus
- **AND** si no contesta, se queda el valor por defecto y **no** se avisa

#### Scenario: Una clave que no existe

- **WHEN** no hay nada guardado
- **THEN** se usan los valores recomendados
- **AND** **NOT** se escribe nada, para que un usuario que no ha tocado nada no tenga una
  preferencia guardada

#### Scenario: Una clave que esta corrupta

- **WHEN** el texto guardado no se puede leer
- **THEN** se usan los valores recomendados, uno a uno
- **AND** el motivo es que un campo malo no puede tirar los buenos: si el tamano se guardo y
  el espaciado no, se respeta el tamano

#### Scenario: Un numero fuera de rango

- **WHEN** el valor guardado esta fuera del rango
- **THEN** se **acota** al rango, y no se descarta el resto

### Requirement: Restaurar valores

La app SHALL devolver todos los ajustes a los recomendados en una pulsacion.

#### Scenario: Uno lo pone todo

- **WHEN** se pulsa
- **THEN** vuelven tamano, alto de linea, espaciado y tema
- **AND** se guarda el cambio

#### Scenario: Y es un boton, no un ajuste mas

- **AND** el motivo es que devolver cinco cosas a su valor es una accion, y una accion se
  reconoce como tal

#### Scenario: La preferencia nueva no pisa la vieja

- **WHEN** se lee una clave guardada sin el espaciado
- **THEN** el espaciado sale en **0,02** y **el resto se respeta**
- **AND** el motivo es que el caso es el de toda preference nueva, y es de las cosas que se
  rompen al anadir un ajuste
