# Spec Delta

## Purpose

Define que la comprobacion en navegador tiene que decir cuando algo no sale, y
que la sonda no puede tragarse sus propios fallos. Este requisito sale de un
fallo medido el 4 de octubre de 2026, en el que la app **funcionaba** y la
sonda **no escribia nada**.

## ADDED Requirements

### Requirement: La sonda no se traga sus propios fallos

La sonda SHALL NOT propagar una excepcion al escribir su informe, y SHALL
escribir un informe que diga que ha fallado y por que.

#### Scenario: Un valor que no se sabe convertir a JSON

- **WHEN** un valor del informe no se puede convertir a JSON
- **THEN** la sonda **NOT** lanza
- **AND** escribe un informe que dice que no ha podido escribir y por que

#### Scenario: Un informe que no sale **NOT** es un informe vacio

- **WHEN** falla la conversion del informe
- **THEN** lo escrito dice que fallo
- **AND** el motivo es que un informe vacio sigue mintiendo igual

#### Scenario: El camino bueno no se toca

- **WHEN** el informe se puede convertir
- **THEN** se escribe entero y sin cambios
- **AND** el motivo es que un arreglo de un fallo que rompe la funcion es el mismo fallo con mas pasos

#### Scenario: Un fallo no cambia lo que se ha visto

- **WHEN** un informe no se puede escribir
- **THEN** el contador de bytes bajados no cambia
- **AND** el motivo es que un dato falso que no se distingue de "no se ha bajado nada" es peor que no escribir

### Requirement: Al informe no se mete nada que no se sepa escribir

La sonda SHALL enviar los avisos como texto, y SHALL NOT enviar objetos.

#### Scenario: La lista de avisos viaja como texto

- **WHEN** la sonda manda el estado de la biblioteca
- **THEN** los avisos viajan como una lista de cadenas
- **AND** el motivo es que `jsonEncode` lanza con un objeto dentro en vez de escribirlo

#### Scenario: No comprobar y no decir nada se ven igual

- **WHEN** la sonda no escribe por un fallo suyo
- **THEN** el resultado es indistinguible de una comprobacion que no ha comprobado nada
- **AND** el motivo es que una comprobacion que se traga sus errores es peor que no tenerla