# Spec Delta

## Purpose

Definir como se lee un versiculo con un comentario al lado: que notas salen, de donde, en
que orden, y que **no** puede pasar cuando el comentario falta.

## ADDED Requirements

### Requirement: El texto se lee igual con comentario al lado

La app SHALL abrir un segundo modulo sin tocar el texto que ya se esta leyendo.

#### Scenario: Juan 3:16 del KJV con el CLARKE al lado

- **WHEN** se lee Juan 3:16 con el CLARKE abierto
- **THEN** el versiculo sale entero y en el mismo cuerpo
- **AND** debajo sale **una** nota, que esta medido

#### Scenario: Las notas salen del comentario, no del texto

- **WHEN** se piden las notas de Juan 3:16
- **THEN** son las del CLARKE, que no estan en ningun otro sitio
- **AND** el texto del versiculo no ha cambiado

#### Scenario: Un versiculo SIN nota no deja de leerse

- **WHEN** se lee Juan 3:1, que **no** tiene nota en el CLARKE, medido
- **THEN** el versiculo se ensena entero
- **AND** el estado de lectura es el de leer
- **AND** **NOT** se dice que no existe

#### Scenario: Un comentario que revienta al consultarse

- **WHEN** el comentario falla al consultarse
- **THEN** el texto sigue en pantalla
- **AND** las notas salen vacias
- **AND** **NOT** se cae la pantalla

### Requirement: Las notas van debajo de su versiculo

La pantalla SHALL ensenar cada versiculo con sus notas debajo, y SHALL NOT ponerlas todas
al final del capitulo.

#### Scenario: El orden en pantalla

- **WHEN** se lee Juan 3:16 con comentario
- **THEN** el versiculo sale antes que su nota

#### Scenario: Un versiculo sin nota no deja hueco ni separacion

- **WHEN** Juan 3 tiene cuatro versiculos sin nota --el 1, el 7, el 24 y el 28, medido--
- **THEN** por esos cuatro no se pinta ninguna separacion
- **AND** la nota del versiculo siguiente **si** se pinta

#### Scenario: Hay una etiqueta por versiculo con nota

- **WHEN** se lee Juan 3 entero con comentario
- **THEN** hay 32 etiquetas, que es el numero de versiculos con nota
- **AND** **NOT** 36

#### Scenario: El cuerpo de la nota es mas pequeno que el del versiculo

- **THEN** el mismo widget que en la pantalla de comentario, porque es la misma
  distincion: la Sagrada Escritura va en voz alta y el comentario en voz baja

### Requirement: Un comentario que no esta no rompe la lectura

La app SHALL avisar y seguir, y SHALL NOT quitar el texto ni volver a la biblioteca.

#### Scenario: El comentario no esta descargado

- **WHEN** llega `/leer/KJV2006/John.3.16/con/CLARKE` a un dispositivo sin el CLARKE
- **THEN** Juan 3:16 se ensena entero
- **AND** hay un aviso que dice que al lado no hay nada y donde se puede bajar
- **AND** el texto abierto no se intenta abrir otra vez

#### Scenario: Un texto de Biblia pedido como comentario

- **WHEN** se pide `/leer/KJV2006/John.3.16/con/KJV2006`
- **THEN** el versiculo se lee igual
- **AND** se dice que es un texto de Biblia y no un comentario

#### Scenario: El aviso tiene un boton para quitarlo

- **WHEN** hay un comentario abierto y sale el aviso
- **THEN** hay un boton "Quitar"
- **AND** el aviso **NOT** deja a quien lo ve sin salida

### Requirement: El comentario que falta se OFRECE bajar, y se abre solo al terminar

La app SHALL ofrecer bajar el comentario pedido desde la propia lectura, y SHALL abrirlo
cuando la descarga termine, sin que quien lee tenga que hacer nada mas.

#### Scenario: El boton lleva el tamano

- **WHEN** el comentario pedido esta en el catalogo y no en el dispositivo
- **THEN** hay un boton "Descargar, 54.9" --el tamano en megas, medido--
- **AND** el boton **NOT** es un "Descargar" sin coste, porque ante un boton cuyo coste no
  se sabe lo que hace la gente es no pulsarlo

#### Scenario: Al terminar la descarga se abre solo

- **WHEN** el comentario se termina de descargar y guardar
- **THEN** se abre y las notas salen debajo de los versiculos
- **AND** el aviso desaparece
- **AND** **NOT** hay que volver a pedir la lectura

#### Scenario: La URL no cambia al terminar la descarga

- **WHEN** el comentario se abre al terminar la descarga
- **THEN** la ruta sigue siendo la misma
- **AND** quien copie la direccion puede mandarla con lo que ve

#### Scenario: Lo que el catalogo no tiene no se ofrece

- **WHEN** el comentario pedido no esta en el catalogo, porque el enlace es de otro
  despliegue
- **THEN** **NOT** hay boton de descargar
- **AND** el texto se lee igual

#### Scenario: Por que esto se comprobo en un navegador

- **THEN** porque ninguna prueba de Dart puede ver que un enlace con `/con/CLARKE` en un
  perfil donde el CLARKE no estaba no bajaba **nada**: el boton de descargar y el camino de
  vuelta son de la pantalla y del enrutador, no del modelo

### Requirement: Cambiar de pasaje no vuelve a abrir los modulos

La app SHALL volver a leer las notas del pasaje nuevo sin reabrir ninguno de los dos
modulos.

#### Scenario: De Juan 3 a Juan 5 con el comentario abierto

- **WHEN** se pasa de Juan 3 a Juan 4 y a Juan 5 con el CLARKE al lado
- **THEN** no se vuelve a abrir ningun modulo
- **AND** las notas **cambian**: Juan 3 trae 32 y Juan 5 trae 43, medido
- **AND** Juan 5 **NOT** ensena las notas de Juan 3

#### Scenario: Volver a la biblioteca cierra los dos

- **WHEN** se vuelve a la biblioteca
- **THEN** se cierra el texto **y** el comentario
- **AND** no quedan 79 MiB de paginas SQLite abiertas

#### Scenario: Cambiar de texto se lleva el comentario

- **WHEN** se abre otro texto
- **THEN** se cierra el comentario del anterior
- **AND** las notas de un texto **NOT** quedan al lado de otro

### Requirement: Elegir comentario sale de lo descargado

La lista de comentarios SHALL salir del manifiesto cruzado con lo que hay en el
dispositivo, y SHALL NOT salir de una lista escrita en el codigo.

#### Scenario: Poner un comentario

- **WHEN** se elige un comentario de la lista
- **THEN** la ruta lo dice, con `/con/`
- **AND** es un `replaceState`, porque poner un comentario es un ajuste de lo que se esta
  leyendo

#### Scenario: Quitarlo

- **WHEN** se elige "Quitar el comentario"
- **THEN** la ruta deja de llevar `/con/`
- **AND** el texto se queda como estaba

#### Scenario: Cerrar la hoja sin elegir

- **WHEN** se cierra la hoja sin tocar nada
- **THEN** **NO** se quita el comentario
- **AND** la diferencia entre "quitar" y "no hacer nada" son dos valores distintos

#### Scenario: No hay ningun comentario descargado

- **WHEN** no hay ninguno
- **THEN** la hoja dice que se bajan en la biblioteca
- **AND** **NOT** dice "no hay comentarios", que suena a que la app esta rota

#### Scenario: Ningun identificador escrito en el codigo

- **THEN** el comentario que aparece lo dice el manifiesto, no el codigo
- **AND** en cuanto el catalogo publique un segundo comentario, aparece sin tocar la app
