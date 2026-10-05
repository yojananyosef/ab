# Spec Delta

## Purpose

Que haya una pantalla de estudio con panel de herramientas, y no una pantalla con una barra
de Material y un boton de volver.

## ADDED Requirements

### Requirement: Hay un panel de herramientas

La app SHALL tener un panel de herramientas lateral en pantalla ancha, y SHALL NOT cobrar el
ancho de lectura.

#### Scenario: Los cinco destinos, y que los cinco llevan a algo

- **THEN** son Biblia, Buscar, Lexico, Comentarios y Biblioteca
- **AND** el motivo es que en Logos sus nueve destinos llevan cada uno a un producto, y un
  destino que no lleva a ninguna parte es peor que uno que no existe
- **AND** **NOT** hay Tienda, ni Entrenos, ni "Panel de Control"
- **AND** el motivo es que el proyecto ya tiene escrito que no hay cuentas, ni compras, ni
  anuncios: eso no es una carencia, es una decision
- **AND** **NOT** hay Asistente de estudio, Enciclopedia biblica, Guias de Estudio ni
  Herramientas
- **AND** el motivo es que **no tienen nada detras**

#### Scenario: El lexico no tiene pantalla propia

- **WHEN** se pulsa Lexico
- **THEN** se abre el indice de la **primera palabra con numero** de la lectura actual
- **AND** si la lectura no trae ninguno, se va a la biblioteca
- **AND** el motivo es que se llega al indice desde la palabra, porque quien quiere saber
  donde mas sale `G2316` ya esta leyendo la palabra y la toca

#### Scenario: Y si no se puede, a la biblioteca

- **AND** el motivo es que "Buscar" sin texto abierto no busca nada, y un aviso encima dira
  "no hay texto abierto" y dejara buscando el mismo boton

#### Scenario: La lista, y esta es la comprobacion

- **WHEN** se mira el marco
- **THEN** hay un **panel de herramientas a la izquierda** con destinos rotulados
- **AND** el motivo es que es lo que hace Logos y lo que no existia

#### Scenario: Los destinos, y solo los que hacen algo

- **THEN** estan Biblia, Buscar, Lexico, Comentarios y Biblioteca
- **AND** el motivo es que los cinco existen en la aplicacion
- **AND** **NOT** hay entradas de adorno: un destino que no lleva a ninguna parte es peor
  que un destino que no existe
- **AND** el motivo es que Logos tiene tambien tienda y entrenos, y aqui no hay ni cuentas
  ni compras

#### Scenario: La regla del ancho

- **WHEN** la ventana es de **1100 px** o mas
- **THEN** el panel va **extendido**, con los nombres a la vista
- **WHEN** la ventana es de menos de **1100 px**
- **THEN** **NO** hay panel lateral
- **AND** el motivo es que la captura responsive de Logos a 768 px no tiene panel lateral:
  tiene una barra de iconos abajo

#### Scenario: El panel no se come el texto

- **AND** el motivo es que un panel lateral que se come la columna de lectura es el fallo
  que el propio `docs/investigacion-ux.md` le atribuye a Bible Gateway
- **AND** la columna de lectura se queda con el ancho que ya tenia

#### Scenario: No hay boton de volver

- **WHEN** se mira la barra del panel de lectura
- **THEN** **NO** hay flecha de volver
- **AND** el motivo es que el panel de herramientas **es** el camino de vuelta, y tener las
  dos cosas es la manera de no decidir cual manda

### Requirement: En pantalla estrecha los destinos van abajo

La app SHALL poner los destinos en una barra abajo cuando no hay panel lateral, y SHALL NOT
poner el campo de referencia en esa barra.

#### Scenario: Los destinos abajo

- **WHEN** la ventana es de menos de 1100 px
- **THEN** hay una barra abajo con los cinco destinos en icono
- **AND** el motivo es que es lo de la captura responsive de Logos, que a 768 px no tiene
  panel lateral

#### Scenario: El campo NO va abajo, y el motivo esta medido

- **AND** el campo se queda en su fila de cabecera en los dos anchos
- **AND** el motivo es que a 360 px cinco `IconButton` de Material son **240 px** --48 cada
  uno, el minimo pulsable-- y del campo quedarían **98**. Medido.
- **AND** el motivo es que el campo de Logos en esa barra es una **busqueda global**, y el
  nuestro es **la referencia del panel**: no son el mismo control

#### Scenario: Lo que si se copia de esa barra

- **THEN** los destinos van con icono y **sin texto**
- **AND** el motivo es que en la barra el icono **es** el nombre, y el texto solo sale en el
  `tooltip`, que en un movil sale si se deja el dedo quieto
- **AND** van repartidos con `spaceAround` y no pegados a la izquierda
- **AND** el motivo es que con cinco destinos pegados hay que acertar a uno de 48 entre
  otros cuatro; repartidos, a 360 px cada uno tiene 72 px

### Requirement: El marco no decide donde va el campo

La app SHALL preguntar al marco el ancho, y SHALL NOT recibir el ancho por parametro.

#### Scenario: La pregunta

- **WHEN** una pantalla necesita saber si hay panel de herramientas
- **THEN** lo pregunta a `AnchoDeEstudio.of(context)`
- **AND** el motivo es que si el marco lo dijera por parametro, cada pantalla que dibujase un
  campo tendria que recibir el ancho y decidir por su cuenta

#### Scenario: Sin marco

- **WHEN** no hay marco --los montajes de prueba--
- **THEN** la respuesta es que **no** hay panel
- **AND** el motivo es que es la situacion mas estrecha y la que menos sitio quita

### Requirement: El marco da su propio `Material`

La app SHALL poner un `Material` en el panel lateral y en la barra de abajo.

#### Scenario: Por que

- **AND** el motivo es que el marco vive **fuera** del `Scaffold`, y el `Scaffold` pone el
  suyo en la barra y en el cuerpo
- **AND** sin el, un `TextField` dentro lanza `could not find a Material ancestor`, que es
  un fallo que no dice de donde viene
