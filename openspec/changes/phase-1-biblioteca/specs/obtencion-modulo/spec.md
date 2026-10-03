# Spec Delta

## Purpose

Define como entran en el dispositivo los bytes de un modulo: desde una URL
declarada por el catalogo o desde un fichero que elige la persona, y que pasa
cuando algo se rompe por el camino.

## ADDED Requirements

### Requirement: Los bytes se traen por rango y con progreso real

La obtencion de un modulo por URL SHALL solicitar los bytes por rangos y
reportar el progreso como **bytes leidos sobre `sizeBytes`**, no como un
porcentaje inventado.

#### Scenario: Descarga con progreso

- **WHEN** se obtiene un modulo de 22.544.384 bytes
- **THEN** el progreso va de 0 a 22.544.384 y llega a 22.544.384 exacto
- **AND** nunca se muestra un porcentaje que no corresponda a esos bytes

#### Scenario: Cancelacion

- **WHEN** la persona cancela una descarga en curso
- **THEN** el modulo queda en estado `disponible`
- **AND** **NOT** queda un fichero a medias que se pueda abrir

### Requirement: Un origen no legible desde el navegador se dice, no se tapa

Si el origen de la URL no responde a una peticion de origen cruzado, la app
SHALL explicar la situacion en castellano en la fila del modulo y ofrecer la
via del fichero local.

#### Scenario: El origen no envia permisos de origen cruzado

- **WHEN** la peticion del modulo falla porque el origen no devuelve
  `Access-Control-Allow-Origin`
- **THEN** la fila del modulo dice, en castellano, que el servidor no permite
  leerlo desde el navegador
- **AND** ofrece abrir un fichero local
- **AND** el error **NOT** se muestra como "error de red" generico

#### Scenario: El origen si es legible

- **WHEN** el origen responde con `Access-Control-Allow-Origin` y los bytes
  llegan completos
- **THEN** el modulo queda `descargado` sin mostrar ningun aviso

### Requirement: El sha256 se comprueba antes de abrir

La app SHALL comprobar el hash de los bytes obtenidos contra el `sha256` que
declara el manifiesto, antes de abrir el modulo.

#### Scenario: Bytes correctos

- **WHEN** el sha256 de los bytes obtenidos coincide con el del manifiesto
- **THEN** el modulo se abre

#### Scenario: Un byte alterado

- **WHEN** el sha256 de los bytes obtenidos **NOT** coincide con el del
  manifiesto, por ejemplo porque se altero 1 byte de los 22.544.384
- **THEN** el modulo **NOT** se abre
- **AND** el error dice el hash esperado y el hash obtenido
- **AND** el modulo vuelve al estado `disponible` y **NOT** a `descargado`

### Requirement: Un modulo se puede obtener sin conexion

La app SHALL permitir obtener un `.amod` de un fichero local, elegido o
arrastrado, sin necesidad de red y sin cuenta.

#### Scenario: Fichero local correcto

- **WHEN** se elige un `.amod` cuyo sha256 coincide con el de un modulo del
  manifiesto
- **THEN** el modulo queda `descargado` y se puede abrir

#### Scenario: Fichero local que no es ningun modulo del catalogo

- **WHEN** se elige un fichero cuyo sha256 no coincide con ninguno del
  manifiesto
- **THEN** la app dice que no es un modulo publicado por el catalogo
- **AND** muestra su sha256 para que se pueda comprobar por fuera
- **AND** **NOT** lo abre

### Requirement: Los fallos tienen final

Un fallo de obtencion SHALL terminar en un estado final con un boton de
reintentar, nunca en un progreso infinito.

#### Scenario: Servidor inalcanzable

- **WHEN** no se puede contactar con el servidor 3 veces seguidas
- **THEN** el modulo queda en `disponible` con el error y un boton de reintentar
- **AND** **NOT** queda animado como si siguiera bajando

#### Scenario: Descarga que se corta a la mitad

- **WHEN** la transferencia termina con menos bytes de los declarados
- **THEN** el modulo **NOT** se abre, el error dice cuantos bytes llegaron de
  los esperados, y no queda nada a medias en disco