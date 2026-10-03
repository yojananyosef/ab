# Spec Delta

## Purpose

Define como se abre un modulo verificado y como se lee: capitulos, versiculos,
navegacion por URL y el comportamiento en pantallas de telefono y de escritorio.

## ADDED Requirements

### Requirement: El modulo se abre en modo solo lectura

La app SHALL abrir un modulo en modo solo lectura y **NOT** escribir en el.

#### Scenario: Leer no modifica el fichero

- **WHEN** se lee el capitulo 3 de Juan de un modulo abierto
- **THEN** el sha256 del fichero en disco es el mismo antes y despues

#### Scenario: Un modulo con escritura sigue cuadrando

- **WHEN** se comprueba el sha256 del fichero tras cualquier operacion de
  lectura
- **THEN** coincide con el que declara el manifiesto

### Requirement: Se muestra un capitulo completo con sus versiculos

El lector SHALL mostrar todos los versiculos del capitulo pedido, con su
numero, en el orden del capitulo.

#### Scenario: Capitulo existente

- **WHEN** se pide Juan capitulo 3 de un modulo de Biblia
- **THEN** se muestran 36 versiculos numerados del 1 al 36
- **AND** el versiculo 16 es el texto completo de Juan 3:16

#### Scenario: Capitulo o versiculo que no existe

- **WHEN** se pide un capitulo o un versiculo que el modulo no tiene
- **THEN** se dice en castellano que ese pasaje no existe en esa traduccion
- **AND** se propone el ultimo pasaje valido anterior

### Requirement: Los 66 libros se resuelven por su nombre en castellano

La app SHALL traducir los nombres de libro en castellano a la clave con la que
el modulo los guarda, y SHALL verificar los 66 contra un modulo real.

#### Scenario: Todos los libros resuelven

- **WHEN** se comprueban los 66 nombres de libro en castellano contra un modulo
  de Biblia abierto
- **THEN** los 66 se resuelven a un libro existente
- **AND** ninguno se queda sin resolver

#### Scenario: Nombre con numero

- **WHEN** se pide "1 Corintios" o "Segundo de Corintios"
- **THEN** ambos abren el mismo libro

#### Scenario: Nombre desconocido

- **WHEN** se escribe un nombre de libro que no existe
- **THEN** se dice que no se reconoce y se propone la lista de libros

### Requirement: La referencia es la direccion

Cada pasaje abierto SHALL tener una direccion propia, y recargar, compartir y
"atras" SHALL funcionar sobre ella.

#### Scenario: Direccion de un pasaje

- **WHEN** se abre Juan 3:16 de un modulo
- **THEN** la direccion contiene el identificador del modulo y la referencia
  `John.3.16`
- **AND** tiene una de estas dos formas: `/leer/<id>?ref=John.3.16`, si el
  despliegue sirve la aplicacion para toda ruta, o `/#/leer/<id>?ref=John.3.16`
- **AND** las dos son una referencia legible por una persona

#### Scenario: Recargar conserva el pasaje

- **WHEN** se recarga la pagina sobre la direccion de un pasaje
- **THEN** se abre el mismo pasaje, no la biblioteca

#### Scenario: Volver atras

- **WHEN** se va de la biblioteca a un pasaje y se pulsa "atras"
- **THEN** se vuelve a la biblioteca, **NOT** a un sitio exterior

#### Scenario: Abrir un enlace

- **WHEN** se abre una direccion de pasaje de otra persona o de otra sesion
- **THEN** el versiculo 1 del rango queda seleccionado

### Requirement: Cambiar de version o de ajuste no llena el historial

Un cambio de estado que **NOT** es navegar SHALL **NOT** crear una entrada en el
historial del navegador.

#### Scenario: Cambiar de version

- **WHEN** se cambia de version con un pasaje abierto
- **THEN** el pasaje sigue abierto
- **AND** pulsar "atras" **NOT** deshace el cambio de version

#### Scenario: Cambiar de capitulo

- **WHEN** se pasa al capitulo siguiente
- **THEN** la direccion cambia a la del capitulo nuevo
- **AND** pulsar "atras" vuelve al capitulo anterior

### Requirement: El lector funciona en movil y en escritorio

El lector SHALL ser utilizable y legible a 360 px de ancho y a 1440 px, sin
excepciones de Flutter ni contenido cortado.

#### Scenario: Pantalla de telefono de 360 px

- **WHEN** se muestra el lector a 360 x 640
- **THEN** no se lanza ninguna excepcion
- **AND** el texto del versiculo es legible y los controles de capitulo
  anterior y siguiente son alcanzables con el pulgar
- **AND** el texto no se corta por la derecha

#### Scenario: Escritorio de 1440 px

- **WHEN** se muestra el lector a 1440 x 900
- **THEN** la columna de texto no ocupa mas de 90 caracteres por linea
- **AND** el texto esta centrado y los controles de capitulo siguen visibles

#### Scenario: Teclado abierto en movil

- **WHEN** se abre el campo de referencia en un navegador de telefono y el
  teclado tapa la mitad de la pantalla
- **THEN** el campo y el boton de buscar siguen visibles por encima del teclado
- **AND** el texto de entrada tiene al menos 16 px, para que el navegador no
  haga zoom al pulsarlo