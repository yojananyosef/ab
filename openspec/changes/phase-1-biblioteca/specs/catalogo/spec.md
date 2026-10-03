# Spec Delta

## Purpose

Define como la app averigua que recursos existen y que estado tiene cada uno,
sin que el catalogo este compilado dentro de la aplicacion.

## ADDED Requirements

### Requirement: La lista de modulos viene del manifiesto y de ninguna otra parte

La app SHALL obtener la lista de modulos unicamente del manifiesto publicado, en
tiempo de ejecucion. El codigo de la app SHALL NOT contener ninguna lista de
textos, de identificadores de traduccion ni de nombres de Biblia.

#### Scenario: El manifiesto declara modulos que la app no conoce

- **WHEN** el manifiesto declara un modulo cuyo `id` y cuyo `name` no aparecen
  en ninguna parte del codigo de la app
- **THEN** la biblioteca lo muestra con su nombre, su tipo y su tamano
- **AND** la app no lo descarta por desconocido

#### Scenario: El manifiesto no declara ningun modulo

- **WHEN** el manifiesto se lee correctamente y su lista de modulos esta vacia
- **THEN** la biblioteca aparece vacia con un aviso en castellano
- **AND** la app **NOT** muestra ningun texto de ejemplo ni modulo de reserva

#### Scenario: Un modulo desaparece del manifiesto

- **WHEN** un modulo ya descargado **NOT** aparece en el manifiesto siguiente
- **THEN** sigue apareciendo en la biblioteca marcado como `retirado`
- **AND** se puede seguir leyendo
- **AND** se dice que ya no esta en el catalogo

### Requirement: El manifiesto se verifica por hash antes de mostrarse

La app SHALL comprobar que el `catalogSha256` del puntero coincide con el hash
del manifiesto descargado, antes de usar su contenido.

#### Scenario: Manifiesto integro

- **WHEN** el hash del manifiesto coincide con el `catalogSha256` declarado
- **THEN** la biblioteca se pinta con los modulos del manifiesto

#### Scenario: Manifiesto alterado

- **WHEN** el hash del manifiesto **NOT** coincide con el declarado
- **THEN** la app **NOT** muestra ningun modulo de ese manifiesto
- **AND** el error dice el hash esperado y el hash obtenido

### Requirement: Un manifiesto ilegible no bloquea la biblioteca

La app SHALL conservar el ultimo manifiesto leido con exito y usarlo como
respaldo cuando el servidor no responde, saying it is doing so.

#### Scenario: Servidor caido con manifiesto en cache

- **WHEN** no se puede contactar con el servidor del catalogo y existe un
  manifiesto leido con exito anteriormente
- **THEN** la biblioteca se pinta con ese manifiesto
- **AND** se avisa de que se esta usando una copia guardada

#### Scenario: Servidor caido sin manifiesto en cache

- **WHEN** no se puede contactar con el servidor del catalogo y **NOT** hay
  manifiesto guardado
- **THEN** la app muestra un error con un boton de reintentar
- **AND** **NOT** queda esperando indefinidamente

### Requirement: Cada modulo muestra tamano, licencia y estado antes de obtenerlo

La biblioteca SHALL mostrar, para cada modulo, su nombre, su tipo, su idioma, su
tamano en bytes y su licencia, sin necesidad de descargarlo.

#### Scenario: Modulo disponible y no descargado

- **WHEN** el manifiesto declara un modulo que no esta en el dispositivo
- **THEN** su fila muestra `sizeBytes` en megabytes con un decimal y el valor
  de `license`
- **AND** su estado es `disponible`

#### Scenario: Estados posibles

- **WHEN** se consulta el estado de un modulo
- **THEN** es exactamente uno de `disponible`, `descargando`, `descargado`,
  `desactualizado` o `retirado`
- **AND** un modulo que no se ha descargado **NOT** aparece nunca como
  `solo local`

### Requirement: El manifiesto se relee sin cachear a ciegas

La app SHALL volver a leer el manifiesto en cada arranque y **NOT** depender de
una copia local para saber que hay disponible.

#### Scenario: El catalogo cambia entre dos arranques

- **WHEN** el manifiesto cambia entre un arranque y el siguiente
- **THEN** la biblioteca del segundo arranque muestra el contenido nuevo
- **AND** los modulos ya descargados siguen descargados