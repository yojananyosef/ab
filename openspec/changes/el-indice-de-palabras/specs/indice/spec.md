# Spec Delta

## Purpose

Definir el indice de una palabra del lexicon: que promete, que no promete y de donde sale
cada numero.

## ADDED Requirements

### Requirement: El indice NO es un diccionario y lo dice

La pantalla SHALL decir que no es un diccionario, y SHALL NOT mostrar significados.

#### Scenario: El significado no esta en el modulo

- **WHEN** se busca el significado de `G2316`
- **THEN** el modulo **NO** lo tiene
- **AND** sus tablas son `info` y `verses`, y las trece claves de `info` **NOT** son de
  lexicon

#### Scenario: El aviso va **antes** de la lista

- **WHEN** se abre el indice
- **THEN** la frase sale antes de la lista
- **AND** el motivo es que con 200 lineas en medio un aviso al final no se ve nunca

#### Scenario: No hay significados inventados

- **WHEN** se muestra el indice
- **THEN** **NOT** hay transliteracion, ni raiz, ni glosa
- **AND** el motivo es que escribirlos a mano seria poner la opinion de quien los escribio

### Requirement: El indice cuenta y lista, y los dos numeros se distinguen

La app SHALL decir cuantos versiculos tienen el numero y WHICH vericulos son.

#### Scenario: El total es de versiculos, no de ocurrencias

- **WHEN** se busca `G2316` en el KJV
- **THEN** **1.171** versiculos
- **AND** **1.359** ocurrencias, que es otro numero
- **AND** la lista es de versiculos, porque Juan 3:16 tiene la palabra una vez y Mateo 1:23
  tres

#### Scenario: El total y las entradas son dos cosas

- **WHEN** hay mas versiculos de los que caben
- **THEN** se dicen los dos numeros
- **AND** quien ve 200 lineas sabe si son todas

#### Scenario: Las escrituras de la palabra

- **WHEN** se abre el indice
- **THEN** salen las escrituras con su cuenta, de mas a menos
- **AND** si hay mas de doce se dice cuantas quedan
- **AND** la cuenta es sobre lo que se ensena, no sobre todo el texto

#### Scenario: El numero que no sale

- **WHEN** se busca un numero que no esta en el texto
- **THEN** se dice cual es y que no sale
- **AND** **NOT** es un fallo

### Requirement: Las palabras con numero son pulsables

El lector SHALL hacer pulsables las palabras con numero del lexicon, y SHALL NOT las que no
lo tienen.

#### Scenario: Una palabra con numero

- **WHEN** se pulsa una palabra que tiene numero
- **THEN** se abre su indice
- **AND** la palabra **NOT** lleva estilo, porque el cursor de la mano ya dice que se puede
  tocar

#### Scenario: Una palabra sin numero

- **WHEN** una palabra no tiene numero
- **THEN** **NOT** es pulsable
- **AND** el motivo es que el indice es de numeros

#### Scenario: Los gestores de gesto se cierran

- **WHEN** cambia el versiculo
- **THEN** los reconocedores del anterior se cierran
- **AND** el motivo es que sin `dispose` se acumulan en cada `build` y cada uno se queda
  apuntando a un `TextSpan` que ya no existe

#### Scenario: Las dos marcas a la vez

- **WHEN** una palabra es del traductor **y** tiene numero
- **THEN** el subrayado gana
- **AND** el motivo es que es el dato que no se ve de otra manera

### Requirement: Un numero que no es un numero no busca

La app SHALL validar el numero ANTES de consultar, y SHALL NOT buscar sin el.

#### Scenario: Una palabra en vez de un numero

- **WHEN** se pide el indice de `Dios`
- **THEN** **NO** busca, y devuelve cero
- **AND** el motivo es que el patron vacio casaria con los **31.102** versiculos

#### Scenario: Un numero demasiado corto

- **WHEN** se pide `G1`
- **THEN** **NOT** se acepta, porque no hay entradas de una letra en el lexicon

#### Scenario: El comentario

- **WHEN** se pide un indice en un comentario
- **THEN** da cero
- **AND** **NOT** revienta con `no such column: raw`, porque el comentario no la tiene

### Requirement: Volver del indice vuelve al pasaje

La app SHALL devolver al pasaje de donde se vino, con el comentario que hubiera.

#### Scenario: Se entra desde una palabra del versiculo

- **WHEN** se abre el indice desde Juan 3:16 y se vuelve
- **THEN** se esta en Juan 3:16
- **AND** **NOT** en Juan 1, que es donde abriria un indice por su cuenta

#### Scenario: Abrir es un ajuste y volver es volver

- **WHEN** se abre el indice
- **THEN** la ruta se sustituye
- **AND** al volver la ruta se anade, porque el indice va **encima** del pasaje
