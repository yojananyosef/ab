# Spec Delta

## Purpose

Definir que se pinta en rojo, con que nombre, y de donde sale el color.

## ADDED Requirements

### Requirement: Las palabras de Jesus se pintan en rojo

La app SHALL pintar en rojo las palabras que el modulo marco con `wj`, y SHALL NOT pintar
ninguna otra.

#### Scenario: Un versiculo entero

- **WHEN** se lee Juan 3:16
- **THEN** sus 25 palabras salen en rojo
- **AND** es lo que dice el modulo, no lo que parece que deberia

#### Scenario: Y el siguiente no

- **WHEN** se lee Juan 3:29
- **THEN** **NO** hay ni una palabra en rojo
- **AND** el motivo es que es el narrador

#### Scenario: Por que esos dos juntos

- **AND** el motivo es que si el marcador marcara el capitulo entero, o no marcara nada,
  Juan 3:11, 3:16, 3:28, 3:29 y 3:36 darian el mismo resultado

#### Scenario: El Antiguo Testamento

- **WHEN** se lee cualquier versiculo del Antiguo Testamento
- **THEN** **NO** hay ni una palabra en rojo
- **AND** el motivo es que el modulo no marca el hablar de Dios, y no hay de donde sacarlo

### Requirement: Se llaman palabras de Jesus y no de Dios

La app SHALL llamarlas palabras de Jesus, y SHALL NOT llamarlas palabras de Dios.

#### Scenario: El nombre del interruptor

- **WHEN** se mira el interruptor
- **THEN** dice "Palabras de Jesus en rojo"
- **AND** **NOT** dice "Palabra de Dios"

#### Scenario: El motivo

- **AND** el motivo es que las palabras del Dios del Antiguo Testamento **NO** estan
  marcadas en ningun sitio de este catalogo

#### Scenario: Una lista inventada

- **WHEN** se pinte de rojo una palabra
- **THEN** **NOT** sea por una lista de versiculos escrita a mano
- **AND** el motivo es que seria el dato de otra persona atribuido al modulo

### Requirement: El marcador es de fiar, y hay que comprobarlo

La app SHALL comprobar que el marcador marca dialogo de Cristo y no "habla divina".

#### Scenario: Las citas de Cristo en las epistolas

- **WHEN** se mira 1 Corintios 11:24 y 2 Corintios 12:9
- **THEN** tienen palabras de Jesus
- **AND** el motivo es que son palabras de Cristo **citadas por Pablo**, que un marcador de
  "habla divina" no traeria

#### Scenario: El Antiguo entero

- **WHEN** se mira cualquiera de los 21 libros del Antiguo Testamento
- **THEN** da cero palabras
- **AND** el motivo es que ahi no hay nada marcado

### Requirement: El color del texto se mide

La app SHALL usar un color cuyo contraste con el fondo sea al menos de AAA, y SHALL NOT
elegirlo a ojo.

#### Scenario: El contraste

- **WHEN** se mide el rojo de las palabras de Jesus contra el fondo
- **THEN** da **7,33:1**, y **7,71:1** contra la superficie
- **AND** el umbral de AAA para texto normal es **7:1**

#### Scenario: Por que se mide

- **AND** el motivo es que es color de texto de cuerpo, y un rojo claro se lee como texto
  deshabilitado y no como Escritura

#### Scenario: La comprobacion esta viva

- **WHEN** alguien baja el contraste del color del tema
- **THEN** la prueba se pone roja
- **AND** **NOT** hay un numero escrito en el comentario

#### Scenario: No es el color de aviso

- **AND** el color de las palabras de Jesus **NOT** es el de los avisos de error
- **AND** el motivo es que un dia el aviso pasaria a ser del color de la Palabra de Cristo

### Requirement: Las dos marcas se suman

La app SHALL pintar las dos marcas a la vez cuando las haya, y SHALL NOT elegir una.

#### Scenario: Una palabra anadida y de Jesus

- **WHEN** una palabra es del traductor **y** de Jesus
- **THEN** sale subrayada **y** en rojo

#### Scenario: El fallo que ya se cometio

- **AND** el motivo es que con "el subrayado gana" el rojo se perdia justo en el unico
  sitio donde mas se nota

#### Scenario: En este catalogo no ocurre

- **WHEN** se mira el KJV entero
- **THEN** **cero** de 835.159 palabras son a la vez `add` y `wj`
- **AND** el motivo de que la funcion sea pura y se pruebe entera

#### Scenario: Con el interruptor apagado

- **WHEN** el interruptor esta apagado y la palabra es del traductor
- **THEN** el subrayado **se queda**
- **AND** apagar el color **NOT** puede borrar informacion del modulo

### Requirement: El texto no cambia con el color

La app SHALL pintar el texto exacto del modulo con el color puesto y sin el.

#### Scenario: Con el interruptor puesto

- **WHEN** se lee Juan 3:16 con el interruptor puesto
- **THEN** lo que se lee es exactamente el texto del modulo

#### Scenario: Con el interruptor apagado

- **WHEN** se apaga el interruptor
- **THEN** lo que se lee es exactamente el mismo texto
- **AND** el motivo es que un lector que altera el texto que va a leer es un lector que no
  se puede citar
