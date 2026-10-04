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

### Requirement: Los terminos que declara el modulo se ensenan antes de leer

Al abrir un modulo, la app SHALL leer su tabla `info` y SHALL mostrar `copyright`,
`attribution`, `license`, `license_evidence`, `defects_count` y `content_hash`
antes de que la persona lea el texto. **NOT** SHALL escondidos en un menu de tres
niveles ni solo en una pantalla de "acerca de".

La informacion que se muestra despues de obtener un modulo SHALL venir de su
propia tabla `info`, no del manifiesto.

#### Scenario: Los terminos son visibles sin buscar en ningun sitio

- **WHEN** se abre un modulo de Biblia
- **THEN** su `copyright` y su `attribution` estan visibles en la pantalla de
  lectura
- **AND** su `license` y su `license_evidence` tambien
- **AND** llegar a ellos no requiere abrir ningun menu

#### Scenario: Un modulo con texto incompleto lo dice

- **WHEN** el modulo declara `defects_count` mayor que 0
- **THEN** la app avisa, en castellano, de cuantos versiculos vienen incompletos
  de la fuente
- **AND** muestra el texto de `defects`

#### Scenario: Un modulo sin defectos no inventa una preocupacion

- **WHEN** el modulo declara `defects_count` igual a 0
- **THEN** la app **NOT** muestra ningun aviso de texto incompleto

#### Scenario: El manifiesto y el modulo discrepan

- **WHEN** el manifiesto declara una licencia distinta de la que declara la tabla
  `info` del modulo ya descargado
- **THEN** la app muestra la del modulo, que es el texto que se esta leyendo
- **AND** dice que discrepan y muestra las dos

#### Scenario: El hash de contenido es comprobable por fuera

- **WHEN** se consulta el `content_hash` de un modulo abierto
- **THEN** es el que declara su tabla `info`, y coincide con el que declara el
  catalogo

### Requirement: Un modulo con un formato que la app no entiende no se abre

La app SHALL declarar que versiones de formato entiende y SHALL negarse a abrir
un modulo cuya `schema_version` exceda lo que soporta. La `schema_version` se lee
del **modulo**; el `minReaderVersion` se lee del **catalogo**, porque el modulo no
lo guarda.

#### Scenario: Formato mas nuevo que la app

- **WHEN** el modulo declara en su tabla `info` una `schema_version` mayor que la
  que la app soporta
- **THEN** la app **NOT** lo abre
- **AND** el error dice la `schema_version` del modulo y la que la app soporta

#### Scenario: App demasiado antigua para el modulo

- **WHEN** el catalogo declara para ese modulo un `minReaderVersion` mayor que la
  version de la app
- **THEN** la app **NOT** lo abre
- **AND** el error dice que hace falta una version mas nueva de la aplicacion

#### Scenario: Un modulo compatible se abre

- **WHEN** la `schema_version` del modulo y el `minReaderVersion` del catalogo
  son los que la app soporta
- **THEN** se abre normalmente

#### Scenario: Las dos versiones vienen de sitios distintos

- **WHEN** se pide la `schema_version` a la tabla `info` del modulo
- **THEN** el modulo **NOT** tiene un campo `minReaderVersion`: se ha medido que su
  tabla `info` tiene 15 claves y esa no esta entre ellas
- **AND** el `minReaderVersion` se ha leido del manifiesto, no del modulo

### Requirement: El numero de capitulos sale del modulo, no de una tabla de la app

La app SHALL obtener el numero de capitulos de cada libro del modulo abierto, con
una consulta. **NOT** SHALL traer una tabla propia de capitulos o versiculos por
libro.

El motivo esta medido y es concreto: en el repositorio hermano, la tabla de
libros se escribio primero de memoria y **21 de 66 libros tenia un numero de
versiculos equivocado**. Una app que lea sus numeros de una tabla propia repite
ese fallo con otro nombre.

#### Scenario: Los capitulos de Genesis son 50, no 51

- **WHEN** se abre el selector de capitulos del libro Genesis en un modulo KJV
- **THEN** ofrece capitulos del **1 al 50**
- **AND** **NOT** ofrece un capitulo 51, que no existe en esa traduccion

#### Scenario: Un capitulo que el modulo no tiene

- **WHEN** se pide un capitulo que el modulo no contiene
- **THEN** se dice que esa traduccion no lo tiene
- **AND** **NOT** se sustituye por el contenido de otro capitulo

#### Scenario: El total de versiculos coincide con el declarado

- **WHEN** se cuenta el numero de versiculos de Juan en un modulo KJV abierto
- **THEN** son 879
- **AND** ese numero viene de una consulta al modulo, no de una constante del
  codigo

### Requirement: La app declara que versificacion usa el modulo y no supone la de KJV

La app SHALL leer y mostrar la `versification` que declara la tabla `info` del
modulo, y SHALL **NOT** suponer que es `KJV` ni alinear dos textos con
versificaciones distintas sin decirlo.

#### Scenario: El modulo declara su versificacion

- **WHEN** se abre un modulo
- **THEN** se muestra el valor de su campo `versification`

#### Scenario: Una referencia que no existe en esa versificacion

- **WHEN** se pide un pasaje que el modulo no tiene, porque su versificacion
  numera distinto
- **THEN** se dice en castellano que esa traduccion no lo tiene
- **AND** se propone el ultimo pasaje valido anterior
- **AND** **NOT** se recurre a la numeracion de otro modulo como si fueran
  intercambiables

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