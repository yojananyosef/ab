# Spec Delta

## Purpose

Definir el selector de libro y capitulo, y dejar escrito que lo que se enseena **no** es un
resumen de capitulo.

## ADDED Requirements

### Requirement: El selector se abre donde se esta leyendo

La app SHALL abrir el selector en el libro del pasaje actual, y SHALL NOT abrirlo en el
primero de la lista.

#### Scenario: Leyendo Juan 3

- **WHEN** se abre el selector
- **THEN** se ven los capitulos de Juan
- **AND** **NOT** los de Génesis, que es el primero

#### Scenario: El capitulo que se esta leyendo

- **THEN** el capitulo actual esta marcado

#### Scenario: Sin pasaje

- **WHEN** no hay pasaje abierto
- **THEN** se ve la lista completa de libros

### Requirement: Cada capitulo lleva su primera frase

La app SHALL enseñar la primera frase de cada capitulo junto a su numero.

#### Scenario: El numero va en su propia columna

- **WHEN** se ve la lista de capitulos
- **THEN** el numero va en una columna fija
- **AND** el motivo es que si no, las frases largas se descuadran en una escalera

#### Scenario: La frase se corta donde hay un punto

- **WHEN** la frase tiene un punto
- **THEN** se corta ahi
- **AND** **NOT** a un numero de caracteres, porque eso parte frases y deja el final colgando

#### Scenario: La frase no tiene punto

- **WHEN** la frase entera no tiene ninguno
- **THEN** se corta donde toca y se dice con puntos suspensivos

#### Scenario: Nunca una fila en blanco

- **WHEN** un capitulo no tiene versiculo 1
- **THEN** su fila **NOT** esta en blanco

### Requirement: NO es un resumen de capitulo

La app SHALL llamar a esto primera frase, y SHALL NOT llamarlo resumen.

#### Scenario: Por que el primer versiculo no sirve de resumen

- **WHEN** se toma `verse = 1` de los 31.102 versiculos
- **THEN** la mayoria son Genealogias, Salmos y Proverbios
- **AND** su primera frase **NO** dice nada del capitulo
- **AND** Juan 3 y Romanos 1 si la dicen, porque empiezan con un sustantivo propio
- **AND** el motivo es que un indice de referencia no es un indice tematico

#### Scenario: Un resumen de verdad

- **WHEN** se quisiera escribir un resumen
- **THEN** **NOT** es posible con lo que trae el modulo
- **AND** el lexicon **NO** esta en el `.amod`
- **AND** el motivo de que no se escriba a mano es que seria el dato de otra persona

### Requirement: El filtro acepta un nombre o una referencia

La app SHALL resolver lo que se escribe como nombre de libro, alias, clave de modulo o
referencia completa.

#### Scenario: Una referencia entera

- **WHEN** se escribe "Juan 3:16"
- **THEN** se ofrece ir a ese pasaje
- **AND** **NOT** solo una lista de libros donde sale "Juan"

#### Scenario: Solo un libro

- **WHEN** se escribe "Juan"
- **THEN** **NO** se ofrece un pasaje
- **AND** el motivo es que escribir el nombre de un libro no debe saltar a su capitulo 1

#### Scenario: Un alias o la clave

- **WHEN** se escribe "Jn" o "John"
- **THEN** sale Juan

#### Scenario: Lo que no esta

- **WHEN** se escribe algo que no es ningun libro
- **THEN** lo dice, y **NOT** pinta una lista vacia sin explicar

#### Scenario: Al escribir se sale a los libros

- **WHEN** se escribe con un libro de capitulos abierto
- **THEN** se vuelve a la lista de libros

### Requirement: Cambiar de capitulo conserva el versiculo

La app SHALL conservar el versiculo al cambiar de capitulo **dentro del mismo libro**.

#### Scenario: Juan 3:16 a Juan 2

- **WHEN** se lee Juan 3:16 y se elige el capitulo 2 de Juan
- **THEN** se abre Juan 2:16
- **AND** **NOT** Juan 2:1, que es otro pasaje y sin avisar

#### Scenario: A otro libro

- **WHEN** se elige otro libro
- **THEN** se abre su capitulo sin versiculo
- **AND** el motivo es que no hay un "Juan 2:16" que signifique algo en Josue
