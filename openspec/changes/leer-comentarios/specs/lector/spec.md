# Spec Delta

## Purpose

Define como se lee un modulo de comentario: que trae, como se pinta y como se navega. Los
requisitos salen de medir el CLARKE real el 4 de octubre de 2026.

## ADDED Requirements

### Requirement: Un comentario trae notas, no texto de Biblia

La app SHALL leer un modulo de comentario de su tabla `commentary` y SHALL NOT de la tabla
`verses`.

#### Scenario: Juan 3:16 tiene su nota

- **WHEN** se lee Juan 3:16 del CLARKE
- **THEN** el pasaje trae **una** nota y ningun versiculo
- **AND** el versiculo **NOT** se pinta como si fuera texto de Biblia

#### Scenario: El capitulo entero trae todas las notas, en orden

- **WHEN** se lee Juan 3 sin versiculo
- **THEN** trae las 32 notas del capitulo, que esta medido
- **AND** van ordenadas por versiculo y, dentro de cada versiculo, por `seq`

#### Scenario: Juan 3 tiene 36 versiculos con texto y 32 con nota

- **WHEN** se lee el capitulo entero del comentario
- **THEN** traen 32 notas, no 36
- **AND** los cuatro versiculos sin nota **NOT** aparecen

### Requirement: El nombre de la tabla sale del tipo del modulo

La app SHALL deducir el nombre de la tabla del contenido del tipo que declara el modulo, y
SHALL NOT escribirlo a mano en las consultas.

#### Scenario: Una Biblia y un comentario con el mismo codigo

- **WHEN** se leen los libros, los capitulos y un pasaje
- **THEN** sale de la tabla `verses` en una Biblia y de `commentary` en un comentario
- **AND** el nombre de la tabla **NOT** esta escrito en ninguna consulta

#### Scenario: El comentario nuevo funciona sin tocar el codigo

- **WHEN** el catalogo publica un comentario que no habia cuando se escribio la app
- **THEN** se lee igual, porque el codigo no lo nombraba

#### Scenario: Un tipo que la app no conoce no se abre

- **WHEN** un modulo declara un tipo sin tabla
- **THEN** no se abre
- **AND** el motivo dice que el fichero se ha descargado bien y que lo que no se puede es enseñarlo

### Requirement: El numero de versiculos es de versiculos, no de notas ni de numeros

La app SHALL contar los versiculos como la terna de libro, capitulo y versiculo.

#### Scenario: El KJV tiene 31.102 versiculos

- **WHEN** se cuenta el contenido de un modulo de Biblia
- **THEN** son 31.102
- **AND** no son 176, que es lo que sale contando numeros de versiculo distintos

#### Scenario: El comentario tiene mas notas que versiculos

- **WHEN** se cuentan las notas y los versiculos del CLARKE
- **THEN** son 19.742 notas sobre 19.741 versiculos
- **AND** la diferencia es que hay un versiculo con dos notas

#### Scenario: Una Biblia no tiene notas, y eso da cero

- **WHEN** se cuentan las notas de un modulo de Biblia
- **THEN** son 0
- **AND** **NOT** es un fallo de SQL

### Requirement: Una nota repetida del dato se ensena una vez

La app SHALL ensenar una sola vez las notas identicas del mismo versiculo, y SHALL NOT
quitar nada mas.

#### Scenario: Mateo 23:13, que esta dos veces en el fichero

- **WHEN** se lee Mateo 23:13 del CLARKE
- **THEN** el fichero trae dos notas con el **mismo** texto de 2.709 caracteres
- **AND** en pantalla sale **una**

#### Scenario: Notas parecidas, pero no iguales, se ensenan las dos

- **WHEN** dos notas del mismo versiculo se parecen pero no son identicas
- **THEN** se ensenan las dos
- **AND** el motivo es que quitar contenido porque se parece a otro es peor que ensenarlo de mas

#### Scenario: El texto repetido en versiculos distintos se enseena en los dos

- **WHEN** dos versiculos distintos tienen el mismo texto
- **THEN** se ensena en los dos

#### Scenario: El `.amod` no se toca

- **WHEN** se quita la nota repetida
- **THEN** el fichero no se modifica
- **AND** el sha256 sigue cuadrando con el del manifiesto

### Requirement: Las notas no se disfrazan de Biblia

La pantalla SHALL pintar las notas de otra manera que los versiculos, y SHALL agruparlas
por el versiculo al que se refieren.

#### Scenario: El texto de una nota es mas pequeno que el de un versiculo

- **WHEN** se mide el cuerpo del texto de una nota y el de un versiculo
- **THEN** el de la nota es mas pequeño
- **AND** la razon es que el texto principal es la Escritura y el comentario va en voz baja

#### Scenario: Cada nota va debajo de su versiculo

- **WHEN** se lee un capitulo de comentario
- **THEN** cada versiculo sale con su numero y sus notas debajo
- **AND** hay un separador entre versiculo y versiculo

#### Scenario: Un versiculo con dos notas dice que tiene dos

- **WHEN** un versiculo tiene mas de una nota que ensenar
- **THEN** se dice cuantas, al lado del numero

#### Scenario: Un lector de pantalla oye a que versiculo es cada nota

- **WHEN** se lee una nota con lector de pantalla
- **THEN** se anuncia a que versiculo se refiere

### Requirement: Un versiculo sin nota no existe en ese comentario

La app SHALL decir que un versiculo sin nota no existe, y SHALL NOT ensenar un hueco con su
numero.

#### Scenario: Juan 3:1, que no tiene nota

- **WHEN** se pide Juan 3:1 del CLARKE, que esta medido que no tiene nota
- **THEN** se dice que en ese comentario no hay nada
- **AND** **NOT** se pinta un "1" sin nada debajo

#### Scenario: El selector ofrece los que tienen nota

- **WHEN** se mira el selector de versiculos de Juan 3 en el comentario
- **THEN** ofrece 32 versiculos, no 36
- **AND** van en orden

### Requirement: La navegacion sale del comentario, no de una tabla del proyecto

La app SHALL ofrecer los libros, capitulos y versiculos que el comentario tiene.

#### Scenario: Los libros son los del comentario

- **WHEN** se pide la lista de libros
- **THEN** son los 66 que tienen nota
- **AND** un libro sin nota **NOT** aparece

#### Scenario: Juan tiene 21 capitulos con nota

- **WHEN** se piden los capitulos de Juan
- **THEN** son 21
- **AND** **NOT** son 23, que es lo que tiene el texto
