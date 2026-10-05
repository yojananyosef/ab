# Spec Delta

## Purpose

Definir el interruptor: que esta puesto por defecto, que se guarda, y que no puede colgar
la lectura cuando no se puede guardar.

## ADDED Requirements

### Requirement: El interruptor esta puesto de partida

La app SHALL tener las palabras de Jesus en rojo sin pedir nada, y SHALL permitir apagarlas.

#### Scenario: La primera vez

- **WHEN** se abre el lector por primera vez
- **THEN** las palabras de Jesus estan en rojo
- **AND** el motivo es que una funcion escondida tras un interruptor apagado es una funcion
  que no existe

#### Scenario: Cuanto rojo es

- **AND** son el **4,94 %** de las palabras del KJV
- **AND** el motivo es que en los evangelios es la mitad aproximadamente, que es lo que se
  espera de una Biblia de letras rojas

#### Scenario: Apagarlo

- **WHEN** se apaga el interruptor
- **THEN** **NO** hay rojo
- **AND** el texto es el mismo

### Requirement: La preferencia se guarda

La app SHALL guardar el estado del interruptor y SHALL volver a leerlo al abrir la pantalla
de lectura.

#### Scenario: Entre sesiones

- **WHEN** se apaga el interruptor, se cierra la app y se vuelve a abrir
- **THEN** sigue apagado

#### Scenario: El valor es legible

- **WHEN** se mira el almacenamiento
- **THEN** el valor es `si` o `no`
- **AND** el motivo es que se puede leer de un vistazo

#### Scenario: Donde se lee

- **WHEN** se abre la pantalla de lectura
- **THEN** se lee la preferencia
- **AND** **NOT** al arrancar la app, porque si no una pestana nueva se pinta con el color
  de la primera

#### Scenario: Una preferencia y no una nota

- **AND** el motivo de que no va al sitio de las notas es que esto se puede volver a poner
  como estaba en dos toques

### Requirement: Una preferencia que no contesta no cuelga la lectura

La app SHALL poner un plazo a la lectura de la preferencia, y SHALL NOT avisar al usuario si
falla.

#### Scenario: El almacenamiento no responde

- **WHEN** la lectura no contesta
- **THEN** tras **cinco segundos** se sigue con el valor de partida
- **AND** la pantalla de lectura **NO** se queda esperando

#### Scenario: Por que cinco y no uno

- **AND** el motivo es que el caso medido en este repositorio **NO** es lento: es que no
  contesta

#### Scenario: Por que no se avisa

- **AND** lo que se ha perdido es una preferencia, que son dos toques
- **AND** un aviso en medio de Juan 3 no le sirve a nadie

#### Scenario: El plazo se puede probar

- **WHEN** una prueba baja el plazo a diez milisegundos
- **THEN** puede comprobar el caso sin esperar cinco segundos
