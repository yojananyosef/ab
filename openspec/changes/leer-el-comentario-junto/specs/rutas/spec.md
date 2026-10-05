# Spec Delta

## Purpose

Definir como dice la URL que se esta leyendo el versiculo **con** el comentario al lado,
que es lo que hace que un enlace se pueda copiar y mandar y Wantoniendo.

## ADDED Requirements

### Requirement: La ruta lleva el comentario del lado

La ruta SHALL llevar el identificador del comentario cuando lo hay, en un segmento `con`
**detras** del pasaje, y la app SHALL escribirlo tambien.

#### Scenario: El versiculo a secas

- **WHEN** la ruta es `/leer/KJV2006/John.3.16`
- **THEN** se lee el texto sin nada al lado
- **AND** una direccion de antes del cambio sigue abriendo lo mismo

#### Scenario: El versiculo con comentario

- **WHEN** la ruta es `/leer/KJV2006/John.3.16/con/CLARKE`
- **THEN** se lee el versiculo del KJV2006 con el CLARKE al lado
- **AND** el segmento va **detras** del pasaje, porque es lo que se anade a algo

#### Scenario: La ida y la vuelta cuadran

- **WHEN** se escribe una ruta y se vuelve a leer
- **THEN** sale exactamente la misma cadena
- **AND** un enlace copiado de la barra de direcciones abre lo que se veia

#### Scenario: Dos rutas que solo difieren en el comentario

- **WHEN** se comparan `/leer/KJV2006/John.3.16` y `/leer/KJV2006/John.3.16/con/CLARKE`
- **THEN** **NO** son iguales
- **AND** poner y quitar el comentario se ejecutan como dos rutas distintas

#### Scenario: Con prefijo de despliegue y con reserva en el hash

- **WHEN** llega `/ab/leer/KJV2006/John.3.16/con/CLARKE` o `/#/leer/KJV2006/John.3.16/con/CLARKE`
- **THEN** las dos dan la misma ruta

### Requirement: Un comentario mal escrito no se abre en silencio

La app SHALL tratar como ruta que no se entiende un `con` sin comentario, un segmento
distinto de `con`, o un segmento de mas.

#### Scenario: `con` sin identificador

- **WHEN** la ruta es `/leer/KJV2006/John.3.16/con` o termina en `/con/`
- **THEN** no se entiende
- **AND** **NOT** se abre el texto sin comentario como si eso fuera lo pedido

#### Scenario: Un segmento que no es `con`

- **WHEN** la ruta es `/leer/KJV2006/John.3.16/CLARKE`
- **THEN** no se entiende

#### Scenario: Un segmento de mas

- **WHEN** la ruta es `/leer/KJV2006/John.3.16/con/CLARKE/extra`
- **THEN** no se entiende
- **AND** la app **NOT** inventa una sintaxis que nadie ha escrito

#### Scenario: Por que no se abre en silencio

- **THEN** porque un enlace mal escrito que abre en silencio **parece un enlace bueno**,
  y quien lo recibe no tiene forma de saber que falta el comentario
