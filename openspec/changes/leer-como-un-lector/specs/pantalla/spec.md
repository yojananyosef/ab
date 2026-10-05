# Spec Delta

## Purpose

Definir lo que hay encima del texto y lo que no, con los numeros medidos en una imagen.

## ADDED Requirements

### Requirement: El boton de ir va dentro del campo

La app SHALL poner el boton de ir **dentro** del campo, como icono de sufijo, y SHALL NOT en
una fila debajo.

#### Scenario: Sin texto no hay boton

- **WHEN** el campo esta vacio
- **THEN** **NO** hay boton de ir
- **AND** el motivo es que dos iconos grises en un campo vacio son dos controles que no
  hacen nada

#### Scenario: Con texto, borrado e ir

- **WHEN** hay texto escrito
- **THEN** salen los dos iconos de sufijo
- **AND** el de ir esta deshabilitado si lo escrito no es una referencia

#### Scenario: El teclado tambien lleva

- **WHEN** se manda la accion de buscar desde el teclado
- **THEN** se va al pasaje escrito

#### Scenario: Por que cambio

- **AND** el motivo es que el boton de abajo ocupaba **48 px de alto** y el campo entero, y
  eso recortaba el texto a 12 caracteres justo al escribir "Juan 3:16"
- **AND** el motivo es que eran **62 px** de los 760, un 8 % de la pantalla, para un control
  deshabilitado el 99 % del tiempo

#### Scenario: El campo toma la columna

- **WHEN** se mide el campo a 360 px
- **THEN** mide mas de **280 px**
- **AND** el motivo es que "Juan 3:16" tiene que entrar entero

### Requirement: El titulo del capitulo no se repite

La pantalla de lectura SHALL NOT volver a escribir el pasaje que ya esta en la barra.

#### Scenario: La barra es la cabecera

- **WHEN** se mira la barra
- **THEN** dice el pasaje en una linea y la version debajo

#### Scenario: Y en el cuerpo no se repite

- **WHEN** se mira el cuerpo
- **THEN** **NO** hay un titulo con el pasaje

#### Scenario: Lo que se midio

- **AND** el motivo es que la fila repetida eran **40 px** por encima del primer versiculo
- **AND** el motivo es que la barra ya decia "Juan 3:16" en su propia linea

### Requirement: Las flechas de capitulo van en la fila del campo

La app SHALL poner las flechas de capitulo en la misma fila que el campo.

#### Scenario: Una sola fila

- **WHEN** se mira la parte de arriba del cuerpo
- **THEN** el campo y las dos flechas estan en la misma linea

#### Scenario: Lo que se midio

- **AND** el motivo es que la fila sola eran **48 px** mas un hueco, con dos flechas a la
  derecha y nada mas, que se leen como un boton suelto en mitad de la pantalla

#### Scenario: Con densidad compacta

- **WHEN** se miran las flechas
- **THEN** van con `VisualDensity.compact`
- **AND** el motivo es que con la densidad normal el campo tiene que crecer para poder
  alinearse al centro, y el campo es lo que importa

### Requirement: Cambiar de capitulo conserva el versiculo en el mismo libro

La app SHALL conservar el versiculo al cambiar de capitulo **dentro del mismo libro**.

#### Scenario: Juan 3:16 a Juan 2

- **WHEN** se lee Juan 3:16 y se elige el capitulo 2 de Juan
- **THEN** se abre Juan 2:16

#### Scenario: A otro libro

- **WHEN** se elige otro libro
- **THEN** se abre su capitulo sin versiculo
- **AND** el motivo es que no hay un "Juan 2:16" que signifique algo en Josue
