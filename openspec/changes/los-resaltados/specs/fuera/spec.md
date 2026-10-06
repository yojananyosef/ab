# Spec Delta

## Purpose

Que todo lo que escribe la persona pueda salir del dispositivo.

## ADDED Requirements

### Requirement: Exportar es parte de poder resaltar

La app SHALL poder exportar los resaltados a un fichero, y esa exportacion SHALL ser parte de
la funcion de resaltar y no un extra.

#### Scenario: El fichero

- **WHEN** se exportan
- **THEN** sale un **`.json`** con `formato`, `version` y la lista
- **AND** `formato` dice de que es y `version` que version del formato
- **AND** el motivo es que un fichero sin version no se puede leer dentro de dos años, y este
  repositorio ya tiene el mismo problema resuelto para los `.amod`

#### Scenario: Con estilo y colores dentro, y no por nombre

- **WHEN** se exporta
- **THEN** cada resaltado lleva su estilo **con su nombre, su color y su forma**
- **AND** el motivo es que si solo llevara el nombre del estilo, al reimportar en otra
  instalacion con los estilos cambiados los resaltados saldrian en un color que la persona
  no eligio, y no podria saber cual

#### Scenario: Y al reimportar se puede elegir

- **WHEN** se importan dos ficheros con el mismo estilo pero distinto color
- **THEN** se pregunta, y no se decide solo
- **AND** el motivo es que un importador que pisa los estilos sin preguntar pierde el trabajo
  de la persona sin avisar

#### Scenario: Y un fichero con datos raros se dice y no se come lo que hay

- **WHEN** se importa un `.json` que no es de esta app
- **THEN** **NOT** se cambia nada, y se dice que no se reconoce
- **AND** el motivo es que importar es la operacion que **escribe** lo de la persona, y una
  operacion que escribe con un fichero equivocado es la peor forma de perderlo

### Requirement: Lo que no se puede, se dice

La app SHALL NOT tener datos de la persona que no se puedan sacar.

#### Scenario: Y porque es una regla y no una intencion

- **AND** el motivo es que sin cuentas **no hay nube**, y un dato que solo vive en el
  navegador se pierde en cuanto se borran los datos del sitio, se cambia de navegador o se
  cambia de telefono
- **AND** el motivo es que eso es exactamente lo que se leyo de las resenas de Accordance
- **AND** el motivo es que por eso la exportacion **no es** una funcion de luxe: es lo que
  hace que el resaltado sea de la persona y no un dato de la aplicacion
