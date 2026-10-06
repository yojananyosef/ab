# Spec Delta

## Purpose

Que el resaltado guarde la referencia y no el texto, y que se pueda quitar del todo.

## ADDED Requirements

### Requirement: Un resaltado es una referencia con un estilo

La app SHALL guardar el resaltado como una referencia --libro, capitulo y versiculo-- mas un
estilo, y SHALL NOT guardar el texto del versiculo.

#### Scenario: Por que la referencia y no el texto

- **WHEN** se marca Juan 3:16 en el KJV
- **THEN** lo que se guarda es `John`, `3`, `16` y el estilo
- **AND** **NOT** el texto "For God so loved the world..."
- **AND** el motivo es lo que dice `docs/investigacion-ux.md`: el resaltado es **por
  referencia y no por version**, y se marca en una traduccion y aparece en todas
- **AND** el motivo es que un texto guardado se queda viejo en cuanto se publica una edicion
  nueva de la traduccion, y la persona ve un texto que ya no es el que esta leyendo

#### Scenario: Y entonces se ve en las dos versiones

- **WHEN** se marca Juan 3:16 con el KJV abierto y luego se abre la misma traduccion
- **THEN** el resaltado sale
- **AND** el motivo es que es lo que hace que comparar dos versiones con los mismos
  marcados sea util

#### Scenario: El texto y el numero de versiculo NO son un dato del resaltado

- **AND** el motivo es que si el resaltado guardara el texto, dos versiculos con el mismo
  texto --"Y dijo Dios: Sea la luz"-- serian indistinguibles al reimportar

### Requirement: Un resaltado se quita del todo

La app SHALL permitir quitar un resaltado, y SHALL NOT dejar marca de que estuvo.

#### Scenario: Quitar

- **WHEN** se quita un resaltado de un versiculo
- **THEN** el versiculo sale sin nada
- **AND** el motivo es lo de "totalmente reversibles" del documento: una marca que no se
  puede quitar es una tachadura en la Escritura

#### Scenario: Y no queda registro

- **WHEN** se quita un resaltado y se vuelve a poner
- **THEN** sale limpio, con el estilo que se elija
- **AND** el motivo es que si quedara un historial, "quitar" seria "marcar como borrado", que
  es distinto y mas dificil de explicar

### Requirement: Hay cinco estilos, y son cinco

La app SHALL ofrecer cinco estilos de resaltado, con color, intensidad y forma.

#### Scenario: Los cinco, con nombre

- **THEN** hay **cinco**: Amarillo, Verde, Azul, Rosa y Naranja
- **AND** cada uno tiene su color, su intensidad y su forma
- **AND** el motivo es que son los de los cuadernos de(subrayar) y los de las Biblias
  impresas, y cinco es un numero que se distinguen de un vistazo sin mirar el nombre

#### Scenario: Intensidad y forma, y no solo color

- **THEN** la intensidad va de tres pasos: suave, medio y fuerte
- **THEN** la forma va de tres pasos: solo el fondo, fondo y borde, y solo el borde
- **AND** el motivo es que dos personas que marcan lo mismo para distinto motivo necesitan
  distinguirlo, y el color solo no llega

#### Scenario: Y el nombre se puede cambiar

- **THEN** el nombre del estilo lo pone la persona
- **AND** el motivo es que "amarillo" no dice para que se marca, y un conjunto con "para la
  predicacion del domingo" si

#### Scenario: Y el estilo es reversible

- **WHEN** se cambia el nombre de un estilo
- **THEN** los resaltados que lo usan salen con el nombre nuevo
- **AND** el motivo es que el estilo es **un nombre y una forma**, no cinco colores
  repartidos por el codigo
