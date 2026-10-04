# Spec Delta

## Purpose

Define como se abre un modulo que no es una Biblia, y como la biblioteca
distingue un error de un progreso de un hecho. Los dos requisitos que hay aqui
salieron de mirar la pantalla el 4 de octubre de 2026, con una ventana de 1900
px y veinte cajas rojas apiladas.

## ADDED Requirements

### Requirement: El tipo de contenido lo declara el modulo

La app SHALL leer la clase de contenido de un modulo de su tabla `info`, en la
clave `type`, y SHALL NOT deducirla de las tablas que encuentre ni tener una
lista de que modulos son comentarios.

#### Scenario: Una Biblia se abre y se lee

- **WHEN** se abre un modulo cuyo `info.type` es `bible`
- **THEN** se abren y funcionan sus consultas de versiculos
- **AND** el modulo declara 66 libros y 31.102 versiculos

#### Scenario: Un comentario se abre y se dice que es un comentario

- **WHEN** se abre un modulo cuyo `info.type` es `commentary`
- **THEN** el modulo se abre sin error y se dice que es un comentario
- **AND** se dice que el fichero esta entero y que lo que falta es la pantalla de lectura

#### Scenario: El tipo se pregunta una vez, al abrir

- **WHEN** se pinte la etiqueta de un modulo en la biblioteca
- **THEN** se lee solo su tabla `info`, sin comprobar la integridad del fichero entero
- **AND** el motivo es que la comprobacion de integridad son 57 MiB y una etiqueta no los necesita

#### Scenario: Un comentario nuevo no necesita tocar el codigo

- **WHEN** el catalogo publica un comentario que no habia cuando se escribio la app
- **THEN** se abre sin error y se identifica como comentario
- **AND** el motivo es que el tipo se lee del fichero y no de una lista del proyecto

### Requirement: Un modulo con un tipo desconocido no se abre

La app SHALL negarse a abrir un modulo cuyo `info.type` falta o no es un tipo que
conoce, y SHALL NOT suponer que es una Biblia.

#### Scenario: Sin tipo declarado

- **WHEN** un modulo no declara `info.type`
- **THEN** no se abre
- **AND** el motivo dice que no se puede saber si se entiende

#### Scenario: Un tipo que la app no conoce

- **WHEN** un modulo declara un tipo que no es `bible` ni `commentary`
- **THEN** no se trata como una Biblia
- **AND** el motivo dice que es un tipo de contenido que la app no conoce

### Requirement: Pedir versiculos a un comentario da un motivo, no un fallo de SQL

La app SHALL lanzar, en vez de devolver una lista vacia, cuando se le pide a un
modulo algo que su tipo no tiene.

#### Scenario: El motivo esta en castellano y dice que es

- **WHEN** se pide la lista de libros a un comentario
- **THEN** el motivo dice que es un comentario y que no tiene versiculos
- **AND** el motivo no dice "no such table: verses", que no le dice nada a quien lo lee

#### Scenario: Una lista vacia seria informacion, no un fallo

- **WHEN** la peticion no tiene sentido para el tipo del modulo
- **THEN** no se devuelve una lista vacia
- **AND** el motivo es que una lista vacia se confunde con "este modulo no tiene ese pasaje", que es una informacion

#### Scenario: La excepcion no es un fallo de apertura

- **WHEN** se pide un pasaje a un modulo que ya esta abierto
- **THEN** el modulo **NOT** se cierra
- **AND** el motivo es que el fichero esta bien y lo que no hay es esa pantalla

### Requirement: Un aviso tiene clase, y solo lo que fallo es un error

La biblioteca SHALL distinguir tres clases de aviso, y SHALL NOT pintar como
error nada que no sea un fallo.

#### Scenario: El progreso no es un error

- **WHEN** hay un modulo bajandose
- **THEN** su progreso **NOT** se pinta como error ni con icono de alarma
- **AND** se pinta como una barra con el porcentaje escrito al lado

#### Scenario: Una copia guardada no es un error

- **WHEN** el manifiesto se lee de una copia guardada porque el servidor no contesta
- **THEN** el aviso **NOT** se pinta como error
- **AND** el motivo es que no se ha roto nada, pero lo que se ve no es lo de hoy

#### Scenario: Una version nueva pendiente no es un error

- **WHEN** hay una version nueva de un modulo ya descargado
- **THEN** el aviso **NOT** se pinta como error
- **AND** el motivo es que se puede seguir leyendo lo que hay

#### Scenario: Un fallo de obtencion si es un error

- **WHEN** la descarga falla, se corta, o el hash no cuadra
- **THEN** el aviso se pinta como error
- **AND** se puede quitar de uno en uno cuando ya no sea verdad

### Requirement: Un progreso se reemplaza, no se acumula

La biblioteca SHALL mostrar **un** progreso por modulo que se esta bajando, y
SHALL NOT acumular uno por cada tramo de la descarga.

#### Scenario: Diez tramos, un progreso

- **WHEN** un modulo de 57 MiB avanza diez veces, una por cada diez por ciento
- **THEN** hay **un** progreso para ese modulo
- **AND** su porcentaje es el ultimo

#### Scenario: Dos descargas a la vez no se confunden

- **WHEN** se estan bajando dos modulos a la vez
- **THEN** hay un progreso por modulo, con su propio porcentaje
- **AND** el progreso de uno **NOT** borra el del otro

#### Scenario: Al terminar, el progreso desaparece

- **WHEN** una descarga termina, salga bien o mal
- **THEN** su progreso ya **NOT** esta en pantalla
- **AND** el motivo es que decir "bajando" de algo ya bajado es mentir

### Requirement: La banda de avisos no tapa la lista

La biblioteca SHALL limitar la altura de la banda de avisos, y el modulo SHALL
quedar visible con cualquier numero de avisos.

#### Scenario: Con veinte avisos se sigue viendo el modulo

- **WHEN** hay veinte progresos y errores a la vez
- **THEN** el nombre del primer modulo esta en pantalla
- **AND** no hay nada fuera de los limites de la pantalla

#### Scenario: El tope es de altura, no de lineas

- **WHEN** hay avisos de tres lineas de texto
- **THEN** la banda no crece de su altura maxima
- **AND** el motivo es que un aviso de tres lineas y uno de una ocupan distinto

#### Scenario: La banda no ocupa sitio si no hay nada que decir

- **WHEN** no hay ningun aviso
- **THEN** la banda no ocupa altura
- **AND** el primer modulo esta arriba, y no debajo de un hueco vacio