# Spec Delta

## Purpose

Donde viven los datos de la persona, y con que plazo se leen.

## ADDED Requirements

### Requirement: Los datos de la persona NO van en las preferencias

La app SHALL guardar los resaltados en su propio almacenamiento, y SHALL NOT en las
preferencias del sistema.

#### Scenario: Y por que no en las preferencias

- **WHEN** se guarda un resaltado
- **THEN** no va en `Preferencias` --`localStorage`--
- **AND** el motivo es que `Preferencias` es un almacen de **ajustes**: son unos 5 MB, y lo
  que hay ahi se puede perder borrando datos del sitio sin ningun aviso
- **AND** el motivo es que un ajuste y el trabajo de una persona **no son la misma clase de
  dato**, y `AGENTS.md` dice que lo que ha escrito la persona no es un estado descartable

#### Scenario: En su propio almacen, con su indice

- **THEN** hay un `AlmacenamientoDeNotas` propio, con la misma forma que el de modulos
- **AND** el motivo es que el de modulos guarda **bytes de otros** y este guarda **lo de la
  persona**, y mezclarlos haria que "borrar los modulos" borrara los resaltados
- **AND** el motivo es que en web el de modulos va en IndexedDB, que es donde cabe lo que
  tiene que sobrevivir a cerrar el navegador

#### Scenario: Y un almacen **por Passage**, no una lista

- **WHEN** se guardan dos resaltados
- **THEN** hay **un registro por versiculo marcado**, no una lista que reescribir entera
- **AND** el motivo es que reescribir una lista de mil resaltados por cada uno que se añade
  es el camino corto a perderlos: si se corta a la mitad, se pierden mil en vez de uno

### Requirement: Se leen con plazo y sin hangar la pantalla

La app SHALL leer los resaltados con un plazo de **cinco segundos**.

#### Scenario: El plazo

- **WHEN** el almacenamiento no contesta
- **THEN** a los cinco segundos se sigue con la pantalla
- **AND** el motivo es el mismo que el del catalogo y el de las preferencias, y esta medido:
  en el navegador, `indexedDB.open` puede quedarse esperando **para siempre**
- **AND** una pantalla colgada por leer resaltados es una pantalla colgada: no hay nada
  sensacional que leer y no se ha abierto

#### Scenario: Y si no contesta, se dice

- **WHEN** el almacenamiento no contesta
- **THEN** la pantalla **avisa** de que no se han podido leer los resaltados
- **AND** el motivo es lo contrario que con una preferencia: lo que se ha perdido aqui no son
  dos toques, es **el trabajo de la persona**, y hay que decirlo
- **AND** el motivo es que "no hay" y "no se ha podido leer" tienen que ser
  estados distintos en pantalla, o la persona cree que no tiene nada

#### Scenario: Guardar tambien tiene plazo y tambien avisa

- **WHEN** el resaltado no se puede guardar
- **THEN** se avisa, y **NOT** se da por puesto
- **AND** el motivo es que un resaltado que se ve en pantalla y no esta en el almacen es
  peor que no tener el boton: la persona lo ha marcado y no lo tiene
