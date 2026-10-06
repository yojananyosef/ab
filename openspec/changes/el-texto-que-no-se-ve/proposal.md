# Proposal

## Why

Tres fallos que se ven en la pantalla, reportados los 6 de octubre de 2026 sobre la web ya
desplegada, con una Biblia y un comentario descargados:

1. **El tema oscuro pinta texto oscuro.** Los titulos, los nombres de los modulos y las
   etiquetas de los filtros salen casi negros sobre fondo casi negro.
2. **"Biblia" no hace nada.** Con una Biblia descargada.
3. **"Comentarios" no hace nada.** Igual.

Y LOS TRES SON EL MISMO TIPO DE FALLO, que es lo que los hace un change y no tres: **ninguno
de los tres lanza una excepcion**. Los tres son "pinta, no peta", y un fallo que no peta no lo
coge ni `flutter analyze` ni una prueba que mire lo que throws.

---

## 1. El tema oscuro: el `copyWith` tira el color

La paleta oscura esta bien. El texto da **15,17:1** sobre su fondo. El problema es que ese
color **no llegaba al texto**:

```dart
textTheme: base.textTheme
    .apply(bodyColor: c.texto, displayColor: c.texto)
    .copyWith(
      bodyMedium:  const TextStyle(fontSize: 16, height: 1.45),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ...
    )
```

`TextTheme.copyWith` **sustituye** el `TextStyle` entero. No le cambia el tamano: le quita el
color que el `.apply()` de la linea anterior acababa de poner. Y un `TextStyle` con la letra
`color` a null **no significa "el del tema"**, significa "el que venga de fuera", que es la
cadena de `DefaultTextStyle` de Material.

Medido, en los seis estilos afectados:

| | color que salia | sobre el fondo | contraste |
| --- | --- | --- | --- |
| forma anterior | `#000000` | `#14110E` | **1,12:1** |
| con el color puesto en el sitio | `#1A1714` | `#14110E` | **1,05:1** |

Los dos son ilegibles, y los dos son el color del **tema claro**: la cadena de
`DefaultTextStyle` de Material 3 con el tema oscuro acaba tomando el color de la paleta
clara.

### Y por que la prueba de contraste decia que estaba bien

Porque mide **los nueve colores de `Colores` entre si**, y esos estan bien. Ese fichero
comprueba que **la paleta es buena**; ninguno comprueba que **la paleta llega al texto**. Son
dos cosas y hacen falta las dos, y la segunda es la que faltaba.

Es el mismo tipo de fallo que el titulo que le quedaban 13,9 pixeles: **no falla**, se pinta
recortado. Un texto ilegible tampoco falla.

---

## 2 y 3. Los destinos que no hacen nada

Los dos tienen el **mismo sintoma** y **causas distintas**, y por eso hace falta un change con
las dos:

| destino | por que no hacia nada |
| --- | --- |
| `comentarios` | el marco llamaba a `alElegirDestino(destino)` **sin contexto**, asi que el `BuildContext?` del enrutador era siempre `null` y caia en `irAHome()` |
| `biblia` | solo sabia volver al pasaje **ya abierto**; sin pasaje --que es estar en la biblioteca-- caia en la misma `irAHome()` |

Y LAS DOS TERMINAN IGUAL PORQUE `irAHome()` **DESDE LA BIBLIOTECA ES NO HACER NADA**.

Y DETRAS DE `comentarios` hay una segunda causa que sigue ahí aunque se arregle la primera:
[elegirComentario] empieza con `if (ruta is! RutaLectura) return;`, que es lo correcto y
**se vuelve sin decir nada**. Desde un boton, eso es indistinguible de no hacer nada.

### Y la regla que faltaba

Hay una regla escrita en el propio enrutador:

> Cada destino **tenia** que llevar a algo, porque en Logos los nueve llevan a un producto y
> un destino que no lleva a ninguna parte es peor que un destino que no existe.

Y **no se estaba comprobando**. Los cinco destinos tenian una rama, y que la rama hiciera
algo era cosa de leerla.

Y UNA RAMA QUE "NO HACIA NADA" NO ES UNA RAMA DE SEGURIDAD, ES UNA RAMA **SIN EXAMEN**. Ir a
la biblioteca sin texto esta bien **si se dice por que**; ir a la biblioteca sin texto y sin
decir nada es dejar a alguien en un callejon sin salida.

---

# LO QUE HACE ESTE CHANGE

- Los seis estilos del `textTheme` llevan su color, y hay una comprobacion **viva** de que el
  texto que se ve sale con el color de la paleta, en los tres temas, contra fondo y contra
  superficie.
- "Biblia" abre una Biblia **que este en el dispositivo**; si no hay ninguna, va a la
  biblioteca **diciendolo**.
- "Comentarios" recibe un contexto de verdad; sin texto abierto va a la biblioteca
  **diciendolo**.
- La biblioteca sabe **por que** se esta en ella, y lo dice con una accion.
- Una comprobacion por cada uno de los cinco destinos, que **no** es "ha cambiado la ruta"
  sino "ha llegado a donde tenia que llegar" o "ha dicho por que".