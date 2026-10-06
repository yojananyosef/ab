# Spec Delta

## Purpose

Que un destino del marco **lleve a algo**, y si no puede, que lo diga.

## ADDED Requirements

### Requirement: "Biblia" abre una Biblia que este en el dispositivo

La app SHALL abrir, desde el marco, una Biblia que este **en el dispositivo**.

#### Scenario: Con un pasaje abierto, vuelve a ese pasaje

- **WHEN** hay un pasaje abierto y se pulsa "Biblia"
- **THEN** se vuelve a **ese** pasaje
- **AND** el motivo es que pulsar "Biblia" con algo abierto es **volver**, y quien esta
  leyendo Juan 3 no quiere que le salten a Juan 1

#### Scenario: Y sin pasaje abierto, abre una Biblia, no un comentario

- **WHEN** no hay nada abierto y hay una Biblia en el dispositivo
- **THEN** se abre esa Biblia
- **AND** el motivo es que un comentario son notas de un texto que **no esta ahi**, y abrirlo
  sin texto es abrir algo que no se puede leer

#### Scenario: Y si solo hay un comentario descargado, NO lo abre

- **THEN** se busca por **tipo**, no por "el primero"
- **AND** el motivo es que el filtro de tipo y el de estado son preguntas distintas: "esta en el
  dispositivo" incluye lo desactualizado y lo retirado, que se leen; "se puede abrir sin
  descargar" incluye lo que no se puede abrir

#### Scenario: Y si no hay ninguna Biblia, va a la biblioteca **diciendolo**

- **WHEN** no hay ninguna Biblia en el dispositivo
- **THEN** se va a la biblioteca con un motivo, y el motivo tiene un boton
- **AND** el motivo es que un destino que te deja en la biblioteca sin decir por que es un
  callejon sin salida
- **AND** el boton dice "Bajar el primero" y no "Instalar", porque **instalar** es una palabra
  de tienda y lo que hay es un modulo en un catalogo

#### Scenario: Y el boton baja una Biblia aunque haya comentarios primero

- **AND** el motivo es que el boton se llama "el primero" y tiene que hacer lo que dice, con
  el filtro "solo lo que tengo" apagado

### Requirement: "Comentarios" recibe un contexto y, si no puede, avisa

La app SHALL pasar un `BuildContext` **real** al elegir un destino, y SHALL NOT dejar que un
destino se vaya en silencio.

#### Scenario: El contexto va en la firma del marco

- **WHEN** se pulsa un destino del panel o de la barra de abajo
- **THEN** el callback recibe el contexto **del elemento del destino**
- **AND** el motivo es que `showModalBottomSheet` busca el `Overlay` hacia arriba y hace falta
  un contexto **por debajo** del `Navigator`; con el del marco, que esta al mismo nivel,
  saldria `No Overlay widget found`

#### Scenario: Y sin contexto no hay destino, pero hay aviso

- **WHEN** se pulsa "Comentarios" sin contexto
- **THEN** se avisa, y **NOT** se va a la biblioteca en silencio
- **AND** el motivo es que volver sin decir nada desde un boton es indistinguible de no hacer
  nada

#### Scenario: Y sin texto abierto, va a la biblioteca diciendolo

- **WHEN** se pulsa "Comentarios" y no hay texto abierto
- **THEN** se va a la biblioteca con un motivo
- **AND** el motivo es que una hoja de comentarios sin texto al que ponerlos no tiene
  sentido, y `elegirComentario` se vuelve en silencio cuando no hay ruta de lectura
- **AND** **NOT** es un fallo: es una rama que se pide avisar

### Requirement: La biblioteca sabe por que se esta en ella

La app SHALL poder decir por que se ha llegado a ella, y el motivo SHALL NOT irse con un
refresco del catalogo.

#### Scenario: Y el motivo esta **fuera** de la lista de avisos

- **WHEN** se pone un motivo
- **THEN** **NOT** esta en `avisos`
- **AND** el motivo es que `aplicarResultado` reemplaza esa lista entera cada vez que llega
  algo del repositorio, que es lo que hacia que los avisos de progreso se reemplazaran a si
  mismos, y un motivo guardado ahi se iria en el primer refresco
- **AND** **NOT** es un aviso porque son cosas distintas: un aviso dice lo que ha pasado y un
  motivo dice **lo que hay que hacer**, con un boton

#### Scenario: Y se olvida en cuanto hay un texto abierto

- **WHEN** se abre un texto
- **THEN** el motivo se olvida
- **AND** el motivo es que en cuanto hay una Biblia abierta, decir "no tienes ninguna Biblia"
  es **falso**, y un texto en pantalla que no se corresponde con lo que se ve es la peor
  forma de avisar

#### Scenario: Y el motivo es una caja con regla, no un fondo de error

- **THEN** lleva una regla a la izquierda y **NOT** un fondo de aviso
- **AND** el motivo es que no es un error: es "aqui tienes algo que saber", y un fondo en rojo
  por abrir una aplicacion vacia es gritar donde no pasa nada
