# Spec Delta

## Purpose

Que el color de la paleta **llegue** al texto, y que eso se compruebe.

## ADDED Requirements

### Requirement: Cada estilo del texto lleva el color de su paleta

La app SHALL poner el color de la paleta en **todos** los estilos del `textTheme`, y SHALL NOT
dejar ninguno sin color.

#### Scenario: Los seis que se quedaban sin color

- **WHEN** se construye el `ThemeData` de cualquier tema
- **THEN** `bodyMedium`, `bodyLarge`, `titleLarge`, `titleMedium`, `titleSmall` y `labelLarge`
  llevan `color`
- **AND** `bodySmall` y `labelSmall` llevan `textoSuave`
- **AND** el motivo es que `TextTheme.copyWith` **sustituye** el `TextStyle` entero, con lo
  que un `TextStyle` de solo tamano se queda **sin color**, y sin color no es "el del tema":
  es el de la cadena de `DefaultTextStyle`

#### Scenario: Y en el oscuro sale el color del oscuro, y no el del claro

- **WHEN** se mide el color **final** de un `Text` con `titleMedium` en el tema oscuro
- **THEN** sale `#EDE6DA`, y no `#1A1714` ni `#000000`
- **AND** el motivo es que los tres dan entre **1,05:1** y **1,12:1** sobre `#14110E`
- **AND** el contraste exigido es **4,5:1** contra el fondo y **4,5:1** contra la superficie

#### Scenario: Y el rojo de las palabras de Jesus sigue siendo texto de cuerpo

- **AND** el rojo da **7:1** o mas en los tres temas
- **AND** el motivo es que el rojo **es** texto de cuerpo y no un adorno, y con el
  `copyWith` roto tambien se caia

#### Scenario: Y se comprueba **el color final**, no el del mapa del tema

- **AND** la comprobacion mete un `Text` de verdad y resuelve el color con la cadena de
  herencia, porque leer `textTheme.titleMedium.color` daria `null` --que ya es un aviso-- y
  no el color equivocado, que es lo que hay que mirar

### Requirement: Un texto con el color equivocado no falla, y por eso hay que medirlo

La app SHALL tener una comprobacion viva del contraste del texto **pintado**, y SHALL NOT
fiarse solo de los numeros de la paleta.

#### Scenario: Por que dos ficheros de contraste

- **AND** uno mide que la paleta es buena y el otro que **llega**
- **AND** el primero pasaba con la aplicacion rota, que es lo que pasa con una comprobacion
  que no comprueba lo nuevo
- **AND** el motivo es que un `Text` con el color equivocado **se pinta bien**: no hay
  excepcion, no hay `overflow`, no hay aviso

#### Scenario: Y la animacion del tema a cero en las pruebas

- **WHEN** una prueba lee el color de un `Text` nada mas montar
- **THEN** el tema tiene que estar ya aplicado
- **AND** el motivo es que `AnimatedTheme` **interpola** y el primer fotograma esta en
  t = 0, donde el dato sigue siendo **el del tema anterior**
- **AND** sin esto, una prueba que comprobara "el color cambia con el tema" pasaria sin
  comprobar nada, porque el de los tres seria el primero, siempre
