# Spec Delta

## Purpose

Que la columna de texto se parezca a la de la captura de Logos en lo que el modulo permite.

## ADDED Requirements

### Requirement: Los numeros de versiculo van en linea

La app SHALL pintar el numero de versiculo al nivel del texto, y SHALL NOT en una columna
aparte, con la salvedad medida.

#### Scenario: En linea

- **WHEN** se lee un capitulo
- **THEN** el numero va **al principio de su versiculo**, en el mismo cuerpo, como en Logos
- **AND** **NOT** en una columna de 34 px a la izquierda
- **AND** el motivo es la comparacion de las dos capturas: Logos lleva los numeros en linea y
  el hueco de la izquierda lo ocupa el panel de ideas

#### Scenario: Y el hueco no se desperdicia

- **WHEN** el numero va en linea
- **THEN** la columna de texto gana los **34 px** de la columna de numeros mas los **10** del
      separador
- **AND** el motivo es que a 360 px son 44 px de un total de 260, un **17 %** mas de texto en
  la misma pantalla

#### Scenario: Salvedad medida, y es una

- **THEN** la columna de numeros se queda cuando el **capitulo tiene mas de 100 versiculos**
- **AND** el motivo es Salmos 119, que tiene 176, y a 360 px con los numeros en linea el
      texto se parte cada dos palabras
- **AND** en cualquier otro capitulo --casi todos, el maximo del KJV fuera de Salmos esta por
      debajo de 80-- van en linea

### Requirement: Las palabras del traductor van en cursiva

La app SHALL pintar las palabras que el traductor anadio en cursiva, y SHALL NOT en
subrayado.

#### Scenario: La marca

- **WHEN** el modulo marco una palabra con `\add`
- **THEN** va en **cursiva**, que es la convencion de toda Biblia impresa
- **AND** **NOT** en subrayado
- **AND** el motivo es que el subrayado es el subrayado del resaltado de la persona: si las
  dos cosas se pintan igual, marcar un versiculo y ver que el traductor anadio una palabra se
  confunden

#### Scenario: Y con el resaltado puesto, las dos se ven

- **WHEN** un versiculo tiene palabras anadidas **y** esta resaltado
- **THEN** se ven las dos cosas a la vez: la cursiva de la palabra y el fondo del resaltado
- **AND** el motivo es la regla que ya esta escrita en `estilo_de_palabra.dart`: la primera
  version hacia que el subrayado ganara, y una palabra anadida **dentro** de las palabras de
  Jesus salia negra con subrayado, y el rojo se perdia justo en el unico sitio donde mas se
  nota

#### Scenario: Medido

- **WHEN** se mira el KJV
- **THEN** hay **41.692** marcas `\add` en **13.736 versiculos**, el **44,16 %**
- **AND** Juan 3:16 no tiene ni una, porque es texto que la traduccion no toco