# Spec Delta

## Purpose

Que las notas al pie del modulo dejen de pintarse como si fueran Escritura.

## ADDED Requirements

### Requirement: La nota al pie es una nota, y se separa del versiculo

La app SHALL pintar el texto de un versiculo **sin** las notas al pie que el modulo le
declara, y SHALL NOT alterar ningun otro caracter.

#### Scenario: Lo que hay, medido

- **WHEN** se mira el `KJV2006_bible.amod` real
- **THEN** hay **6.959** notas al pie en **5.844** versiculos, el **18,79 %** del texto
- **AND** estan en **913** capitulos, con una media de **7,6** notas por capitulo
- **AND** el capitulo con mas notas es Daniel 11, con **35**

#### Scenario: Y hoy se pinta todo junto

- **WHEN** se lee 1Cronicas 1:6 en la pantalla
- **THEN** la columna `text` del modulo trae el versiculo **y** la nota pegados:

      And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. 1.6 Riphath: or,
      Diphath as it is in some copies

- **AND** hoy se pinta **todo** en el mismo cuerpo y con el mismo color que la Palabra
- **AND** el motivo es que el `raw` dice `\f + \fr 1.6 \ft Riphath: ...\f*` y el `raw` no se
  leia para esto

#### Scenario: La separacion es exacto o no es

- **WHEN** se separa la nota del versiculo
- **THEN** se comprueba que `text` **termina exactamente** en `"REF TEXTO"` de cada nota, en
      orden, separadas por un espacio
- **AND** si no cuadra, **no se separa nada** y el versiculo se pinta entero
- **AND** el motivo es la misma regla que ya se usa con el marcado: es preferible un
      versiculo sin notas a un versiculo con una nota de otro sitio

#### Scenario: La comprobacion son los 31.102

- **WHEN** se cambia el parser
- **THEN** una prueba recorre **los 31.102 versiculos** del fichero real y comprueba que el
      texto que se pinta mas las notas es **exactamente** lo que traia `text`
- **AND** el motivo es que un lector que altera el texto que va a leer es un lector que no se
      puede citar, y citar mal la Escritura es el fallo mas grave de esta categoria

### Requirement: La nota lleva letra, y la letra es del capitulo

La app SHALL poner una letra en el texto, en la palabra que el modulo engancho, y SHALL
listar las notas del capitulo al final.

#### Scenario: La letra

- **WHEN** el versiculo tiene notas
- **THEN** cada una lleva una letra --`a`, `b`, `c`-- **reiniciada en cada capitulo**
- **AND** va en superindice, pegada a la palabra que el `raw` marca
- **AND** el motivo es que la referencia del modulo es `1.6` --libro.capitulo.versiculo-- y
  por eso no sirve como letra: en pantalla seria un numero repetido

#### Scenario: El enganche cae dentro del versiculo

- **WHEN** se busca la palabra donde va la letra
- **THEN** se cuenta sobre el `raw` hasta el `\f`, y se contrasta con las palabras de `text`
- **AND** medido: el ancla cae dentro del versiculo en **6.956 de 6.959**
- **AND** si cayera fuera, la nota se lista al final y **no** se engancha: una letra pegada
  a la palabra equivocada es peor que una nota sin letra

#### Scenario: Al final del capitulo

- **WHEN** el capitulo tiene notas
- **THEN** se listan al final, con su letra y su texto, **separadas del texto del versiculo**
- **AND** en cuerpo mas pequeno y con color suave, que es como se distingue una glosa de la
      Escritura
- **AND** si el capitulo no tiene notas, **no hay lista**: Juan 3 no tiene ni una, medido, y
  una cabecera de "notas" vacia parece un fallo

### Requirement: Una nota no puede cambiar como se lee el versiculo

La app SHALL pintar el versiculo igual aunque el modulo traiga notas que no se puedan
separar.

#### Scenario: El caso raro

- **WHEN** un versiculo trae `\f` pero el `text` no termina en la nota
- **THEN** se pinta el `text` **entero**, con la nota dentro, y no se avisa
- **AND** el motivo son **3 versiculos** de 5.844 --medido--, y son Salmos 119:24, 119:112 y
  119:160, donde el modulo anade el nombre hebreo de la letra despues de la nota y ese
  nombre no esta en el `\ft`
- **AND** tres versiculos de Salmos no justifican un aviso en pantalla para los otros 5.841