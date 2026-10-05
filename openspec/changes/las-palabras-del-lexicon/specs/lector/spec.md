# Spec Delta

## Purpose

Definir que se saca del marcado USFM del modulo y que **no** se saca, y la promesa de que
el texto no cambia.

## ADDED Requirements

### Requirement: El texto del versiculo NO cambia

La pantalla SHALL pintar el texto de la columna `text` del modulo, y SHALL NOT
reconstruirlo desde el marcado.

#### Scenario: Los 31.102 versiculos

- **WHEN** se lee cualquier versiculo del KJV
- **THEN** lo que se pinta es **exactamente** lo que el modulo tiene, byte a byte
- **AND** no hay ni un caracter de mas ni de menos

#### Scenario: Ni mayusculas, ni acentos, ni espacios

- **WHEN** el texto del modulo tiene comillas raras, espacios seguidos o saltos de linea
- **THEN** se pinta tal cual
- **AND** **NOT** se normaliza

#### Scenario: Por que no desde el `raw`

- **THEN** porque las dos columnas dicen lo mismo y no con los mismos caracteres, y
  reconstruir una desde la otra obliga a aprender una regla por caso

### Requirement: Las palabras del traductor se saben cuales son

La app SHALL distinguir las palabras que el modulo marco como anadidas por el traductor.

#### Scenario: 1 Cronicas 1:19

- **WHEN** se lee 1 Cronicas 1:19 del KJV
- **THEN** salen **dos** palabras marcadas, y las dos son "was"
- **AND** `Peleg` y `Joktan`, que vienen despues, **NO** salen marcadas

#### Scenario: Juan 3:16

- **WHEN** se lee Juan 3:16
- **THEN** **NO** hay ninguna palabra marcada
- **AND** eso es lo que hace comprobable la cifra de 41.692 marcas

#### Scenario: Como se distinguen en pantalla

- **WHEN** una palabra es del traductor
- **THEN** sale **subrayada**
- **AND** **NOT** de otro color, porque un color pondria algo en el sitio del texto que no
  es texto

#### Scenario: El lexicon no se pinta

- **WHEN** hay un numero del lexicon
- **THEN** **NOT** aparece en pantalla
- **AND** el motivo es que un numero al lado de cada palabra convierte el versiculo en una
  tabla

### Requirement: La palabra de Dios en rojo NO es posible con estos modulos

La app SHALL NOT marcar ninguna palabra como habla divina, y SHALL NOT inventar cual es.

#### Scenario: No hay marca de habla divina

- **WHEN** se buscan marcas de habla divina en los 31.102 versiculos del KJV
- **THEN** **NO** hay ninguna
- **AND** lo que hay son numeros del lexicon y texto anadido

#### Scenario: Por que no se pinta de rojo

- **THEN** porque pintar de rojo lo que uno no sabe que es la Palabra es inventarse el
  dato, y este dato es la Escritura

### Requirement: Las anotaciones o cuadran todas o no hay ninguna

La app SHALL entregar **una** anotacion por palabra del versiculo, o ninguna.

#### Scenario: Una lista a medias

- **WHEN** el marcado trae mas o menos palabras que el texto
- **THEN** **NO** hay anotaciones para ese versiculo
- **AND** el motivo es que una lista a medias pondria el numero de la palabra trece en la
  doce, y eso no se ve hasta que alguien lo busca

#### Scenario: Un versiculo corto

- **WHEN** el versiculo tiene una palabra y el marcado tiene tres
- **THEN** no hay anotaciones
- **AND** el texto se lee igual

#### Scenario: La cobertura es un numero medido

- **WHEN** se cuenta
- **THEN** **97,60 %** de los versiculos del KJV reciben anotaciones
- **AND** el 2,40 % restante son los que traen el aparato de variantes de las cronicas
- **AND** el numero va en una constante con nombre, para que se vea si baja
