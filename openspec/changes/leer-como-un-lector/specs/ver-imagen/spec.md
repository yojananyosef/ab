# Spec Delta

## Purpose

Que exista una forma de mirar la aplicacion, y que su fallo se documente en vez de
declararse imposible.

## ADDED Requirements

### Requirement: Hay una forma de mirar la interfaz

El repositorio SHALL tener una herramienta que saque imagenes de la aplicacion en marcha.

#### Scenario: El camino que no funciona

- **WHEN** se usa `--screenshot` de Brave
- **THEN** se queda colgado y devuelve 0 bytes
- **AND** el motivo es que el motor de Flutter mantiene vivo el `requestAnimationFrame`

#### Scenario: El camino que si

- **WHEN** se usa `page.screenshot()` de Playwright
- **THEN** funciona

#### Scenario: Las tres diferencias

- **THEN** espera a `domcontentloaded` y ademas a un tiempo fijo
- **AND** lleva `--enable-unsafe-swiftshader`, sin el cual el lienzo sale **en blanco**
- **AND** **NOT** usa `--virtual-time-budget`

#### Scenario: El perfil es persistente

- **WHEN** se repiten capturas
- **THEN** el modulo **NO** se vuelve a bajar
- **AND** el motivo es que son 22,5 MB en el `IndexedDB`, y sin perfil persistente cada
  iteracion de diseno paga la descarga entera

#### Scenario: Y hay que calentarlo

- **WHEN** el perfil esta frio y se abre un enlace profundo
- **THEN** se avisa y se queda en la biblioteca
- **AND** el motivo es que reintentar solo esta en la sonda
- **AND** el motivo es que si no, la primera captura de la lectura sale siendo la biblioteca
  con un 60 % de descarga, y parece que la ruta no funciona

### Requirement: Los errores de pagina se enseñan

La herramienta SHALL imprimir los errores de la pagina, y SHALL NOT solo la imagen.

#### Scenario: Un desbordamiento no sale en la imagen

- **WHEN** hay un `RenderFlex overflowed`
- **THEN** sale por la consola del navegador
- **AND** el motivo es que no aparece en el PNG

### Requirement: Sin imagen se perdian fallos enteros

La app SHALL dar por bueno un cambio de interfaz solo con `flutter test`, y SHALL documentar
lo que eso no ve.

#### Scenario: El nombre de la version, que no salia nunca

- **WHEN** el enrutador escucha a la biblioteca solo para el comentario y no avisa
- **THEN** la pantalla se queda con la lista de versiones que tenia al construirse
- **AND** **NINGUNA** comprobacion lo ve: la sonda lee el pasaje y la prueba monta la
  pantalla con la lista ya puesta a mano
- **AND** las dos dan verde con el bug puesto

#### Scenario: El boton debajo del campo

- **WHEN** el boton de ir esta en su propia fila de 48 px
- **THEN** el campo se queda con la mitad del ancho y el texto se corta a 12 caracteres
- **AND** el motivo del cambio es que la causa **NO** era la fila, sino que el boton de
  abajo ocupaba la fila entera
