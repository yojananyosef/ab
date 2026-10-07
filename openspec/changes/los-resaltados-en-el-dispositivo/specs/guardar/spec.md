# Spec Delta

## Purpose

Que los resaltados se guarden de verdad, y que no se puedan perder en silencio.

## ADDED Requirements

### Requirement: El resaltado sobrevive a cerrar la aplicacion

La app SHALL guardar los resaltados en un almacen **que sobreviva a cerrar**, y SHALL NOT
usar un almacen en memoria en la aplicacion.

#### Scenario: Marcar, cerrar, volver

- **WHEN** se marca un versiculo, se cierra la pestana y se vuelve a abrir
- **THEN** el versiculo sale marcado
- **AND** el motivo es que un almacen en memoria no falla nunca, no avisa y no dice nada:
  **parece** que funciona y pierde todo al cerrar
- **AND** el motivo es que lo que ha escrito la persona «no es un estado descartable»

#### Scenario: Y una comprobacion que no deja volver a hacerlo en silencio

- **THEN** hay una prueba que comprueba que el view model **de la aplicacion** lleva
  almacen
- **AND** el motivo es que el fallo anterior no lo cagio ninguna prueba: el view model es
  correcto con y sin almacen, y lo unico que faltaba era el cableado
- **AND** la prueba mira **el de la aplicacion**, y no uno construido en la prueba, que es
  donde se puede volver a meter el equivocado sin que se note

### Requirement: Los resaltados viven en su propia base de datos

La app SHALL guardar los resaltados en una base **distinta** de la de los modulos.

#### Scenario: Y no en la misma, por el bloqueo de version

- **WHEN** se decide donde viven
- **THEN** **NOT** en la base `ab`, que es la de los modulos
- **AND** el motivo es que anadir un almacen obliga a subir la version, y esa subida es un
  `onupgradeneeded` que con dos pestanas abiertas deja a la segunda **esperando para
  siempre**: es el fallo que ya esta escrito en el fichero de modulos

#### Scenario: Y "borrar los modulos" no puede tocar los resaltados

- **WHEN** se borra la base de datos de los modulos para ganar sitio
- **THEN** los resaltados **no** se van
- **AND** el motivo es que una accion de limpieza no puede limpiar tambien el trabajo, y con
  dos bases distintas no hay forma de que lo haga ni por error

#### Scenario: Y dos almacenes, porque son dos cosas

- **THEN** hay un almacen para los resaltados y otro para los estilos
- **AND** el motivo es que los estilos se cambian --se renombran, se recolorean-- mucho mas
  que los resaltados, y guardarlos juntos obliga a reescribir los resaltados para cambiar un
  nombre

### Requirement: El almacen que no contesta se sigue_notificando

La app SHALL avisar cuando los resaltados no se han podido guardar, y SHALL NOT hacerlo en
silencio.

#### Scenario: Y si el navegador no contesta

- **WHEN** el almacen no contesta en el plazo de cinco segundos
- **THEN** se avisa en pantalla, con palabras sobre **los datos** de la persona
- **AND** el motivo es que "no hay resaltados" y "no se han podido leer" tienen que ser
  estados distintos, o la persona cree que no ha marcado nada

#### Scenario: Y el aviso se ve al arrancar, no solo al marcar

- **WHEN** se arranca sin haber marcado nada
- **THEN** se comprueba si hay algo que avisar
- **AND** el motivo es que el fallo aparece al arrancar y al marcar, y solo mirar el segundo
  deja pasar el primero
