# Spec Delta

## Purpose

Definir que muestra la pantalla de lectura cuando se pide un versiculo, que antes era solo
ese versiculo.

## ADDED Requirements

### Requirement: Un versiculo pedido trae su capitulo

La app SHALL traer el capitulo desde el versiculo pedido, y SHALL NOT traer solo ese
versiculo.

#### Scenario: Juan 3:16

- **WHEN** se abre Juan 3:16
- **THEN** se ensenan los versiculos del 16 al 36
- **AND** son **21**, porque Juan 3 va del 1 al 36

#### Scenario: Por que

- **AND** el motivo es que medido en una captura a 360 px, el versiculo suelto era el **16 %**
  de la pantalla y los terminos el 35 %
- **AND** un lector que al abrir un versiculo ensena un versiculo no esta enseñando la Biblia

#### Scenario: Que dicen los tres que se copian

- **AND** YouVersion "selecciona" el primer versiculo del rango, y seleccionar no es acotar
- **AND** MyBible deja poner cualquier pasaje "into the center of your screen and study it
  in its immediate context"
- **AND** Accordance resuelve la ambiguedad de versificacion mostrando los paneles, no
  dejando un numero en blanco

#### Scenario: El ultimo versiculo

- **WHEN** se pide Juan 3:36
- **THEN** se ensena **solo** el 36
- **AND** el motivo es que si aqui salieran mas, la consulta cruzaria el capitulo

#### Scenario: El capitulo mas largo

- **WHEN** se pide Salmos 119
- **THEN** entran los **176** versiculos
- **AND** el motivo es que lo que se nota de ese capitulo no es el tiempo, es que hay que
  desplazarse mucho

#### Scenario: El coste

- **WHEN** se lee un capitulo con el `raw` de los Strong incluido
- **THEN** Juan 3:16 son **5,1 ms** y Salmos 119 **9,6 ms**
- **AND** el comentario, **0,26 ms**

### Requirement: El versiculo pedido se sabe y se marca

La app SHALL decir cual de los versiculos se pidio, y SHALL NOT deducirlo de la lista.

#### Scenario: Dos rutas, la misma lista

- **WHEN** se abre Juan 3:16 y luego Juan 3
- **THEN** las dos traen versiculos que se solapan
- **AND** lo unico que las distingue es cual se pidio

#### Scenario: Se marca con una linea

- **WHEN** se ensena el versiculo pedido
- **THEN** lleva una **linea vertical** al lado y el texto en color de acento
- **AND** el motivo es que el texto de la Escritura no cambia de color

#### Scenario: El numero no se mueve

- **WHEN** se marca un versiculo
- **THEN** su numero sigue en la columna de 34 px
- **AND** el motivo es que una columna de versiculos desalineada no se lee como columna

#### Scenario: Capitulo entero

- **WHEN** se pide Juan 3 sin versiculo
- **THEN** **ningun** versiculo sale marcado
- **AND** el motivo es que si no, el primero de la lista saldria destacado sin que nadie lo
  haya pedido

### Requirement: El comentario sigue el mismo alcance

La app SHALL traer del comentario las notas del mismo rango que el texto.

#### Scenario: Juan 3:16 en el CLARKE

- **WHEN** se abre Juan 3:16 con el comentario abierto
- **THEN** el pasaje trae las notas **desde el 16**
- **AND** son **19**, no 1
- **AND** lo que ve quien lee, versiculo a versiculo, es `notasDe(16)`

#### Scenario: El texto sigue sin verses
- **AND** un comentario **NOT** trae versiculos de Biblia, ni al cambiar el alcance

#### Scenario: La nota repetida
- **WHEN** se pide Mateo 23:13
- **THEN** las dos filas identicas del fichero siguen siendo **una**
- **AND** la comprobacion es `notasDe(13)`, que es la vista que ve quien lee
