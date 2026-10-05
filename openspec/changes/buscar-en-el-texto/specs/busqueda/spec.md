# Spec Delta

## Purpose

Definir la busqueda en el texto abierto: que busca, como lo dice y que no promete.

## ADDED Requirements

### Requirement: La busqueda es del modulo abierto

La app SHALL buscar en el modulo que esta abierto, y SHALL NOT buscar sobre el catalogo
entero.

#### Scenario: La ruta lleva el modulo

- **WHEN** la ruta es `/buscar/KJV2006/propitiation`
- **THEN** se busca en el KJV2006 y en ningun otro

#### Scenario: El comentario tambien se busca

- **WHEN** se busca "propitiation" en el CLARKE
- **THEN** salen **15** coincidencias, que esta medido
- **AND** la consulta es la misma que en una Biblia, porque las dos tablas tienen los
  mismos campos

#### Scenario: Por que no sobre toda la Biblia

- **THEN** porque una busqueda que atraviesa varios modulos necesita saber **cual** se
  busca antes de empezar, y los modulos pueden declarar versificaciones distintas y estar
  en idiomas distintos

### Requirement: Los resultados dicen cuantos hay

La busqueda SHALL decir el numero total de coincidencias, no solo las que caben.

#### Scenario: Tres coincidencias

- **WHEN** se busca "begotten" en el KJV
- **THEN** salen **26** y se dicen las 26

#### Scenario: Cuatro mil coincidencias

- **WHEN** se busca "God" en el KJV
- **THEN** se enseñan 200 y se dice "4.140 coincidencias"
- **AND** se dice que esas son las primeras 200

#### Scenario: El numero va con los miles separados

- **THEN** en castellano, con punto: `4.140`, y **NOT** `4140` ni `4,140`

#### Scenario: Sin resultados no se anuncia un numero

- **WHEN** la palabra no sale
- **THEN** se dice la palabra que se busco
- **AND** **NOT** se dice "0 coincidencias"

### Requirement: Una palabra de una letra no busca

La busqueda SHALL distinguir "no se ha buscado" de "no hay nada".

#### Scenario: Una letra

- **WHEN** se busca "a"
- **THEN** no se busca
- **AND** la pantalla dice que hacen falta dos letras
- **AND** **NOT** dice que no hay resultados, que es mentira: "a" sale en 31.027 de los
  31.102 versiculos del KJV

#### Scenario: Una palabra de verdad que no sale

- **WHEN** se busca "xyzzy"
- **THEN** si se ha buscado y se dice que no sale

### Requirement: La busqueda avisa de que es por texto

La pantalla SHALL decir que busca el texto entero y no palabras sueltas.

#### Scenario: Buscar un prefijo

- **WHEN** se busca "pro"
- **THEN** sale un aviso de que tambien sale en "propitiation"
- **AND** el motivo es que `LIKE` no entiende de palabras, y sin el aviso quien busca
  piensa que el buscador no funciona

#### Scenario: El comodin se quita, no se escapa

- **WHEN** se busca "a_b"
- **THEN** se busca "ab", y **NOT** "cualquier caracter"
- **AND** con un `%` no se busca nada, en vez de devolver los 31.102 versiculos

### Requirement: Una coincidencia se pinta con su extracto

Cada resultado SHALL traer el trozo de texto de alrededor, y SHALL NOT obligar a preguntar
otra vez.

#### Scenario: El extracto tiene la palabra dentro

- **WHEN** se busca "begotten"
- **THEN** el extracto de Juan 3:16 empieza en " loved the world" y acaba en "have everla"
- **AND** son 120 caracteres de un versiculo que tiene 141

#### Scenario: El extracto sale con el color del versiculo

- **WHEN** se mira una coincidencia
- **THEN** sale el versiculo al que es y el numero de capitulo
- **AND** el capitulo va al lado, porque "Juan 3:16" y "1 Juan 2:2" empiezan igual

#### Scenario: Pulsar un resultado abre ese pasaje

- **WHEN** se pulsa una coincidencia
- **THEN** se abre **ese** pasaje
- **AND** con el comentario que hubiera, porque buscar no quita nada

### Requirement: Buscar no es irse

La app SHALL dejar el texto abierto mientras se busca, y SHALL devolver al pasaje con el
comentario que hubiera.

#### Scenario: Volver de la busqueda

- **WHEN** se entra en la busqueda desde Juan 3:16 con el CLARKE al lado
- **THEN** el texto **no** se cierra
- **AND** al abrir un resultado se vuelve a Juan 3:16 **con** el CLARKE al lado

#### Scenario: Entrar por un enlace no busca

- **WHEN** se entra en `/buscar/KJV2006/begotten`
- **THEN** el campo sale escrito y **no** hay resultados
- **AND** quien quiera solo tiene que pulsar "buscar"

#### Scenario: Un texto que no esta

- **WHEN** se entra en `/buscar/RVR1960/x` y no esta descargado
- **THEN** se avisa y se vuelve a la biblioteca
