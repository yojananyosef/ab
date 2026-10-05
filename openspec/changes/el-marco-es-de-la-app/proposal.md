# Proposal

## Why

Pregunta de quien mira: "el catalogo no deberia estar contenido en el sidebar? porque esta
como desacoplado y en el index principal es raro".

**Las dos cosas son verdad, y las dos tienen una causa distinta.**

## 1. "Desacoplado": el marco estaba dentro del lector

`MarcoDeEstudio` vivia en `LectorView.build`. Solo la pantalla de lectura lo tenia, con lo
que al pulsar **Biblioteca** en el panel lateral se salia del panel lateral: la biblioteca se
pintaba sin marco, sin saber donde estabas y sin poder cambiar de destino sin darle a atras.

El marco es de la **aplicacion** --una ventana con herramientas al lado y destinos-- y no de
una pantalla. Lo pone el enrutador, que es el unico que sabe cual de las cuatro pantallas esta
viva.

Y **NINGUNA PRUEBA LO CAZABA**, y el motivo es el que mas ha costado en este repositorio:
las pruebas del enrutador se montaban todas a **360 px**, y por debajo de `Medidas
.anchoParaPanelDeHerramientas` --1100-- **no hay panel lateral**, hay barra de destinos abajo.
A 360 px las cuatro pantallas se veian con barra de destinos y todo encajaba. **El fallo solo
existe por encima de 1100 px** y ninguna prueba llegaba ahi con el enrutador montado.

## 2. "Raro en el indice principal": la app arranca en la biblioteca

`Ruta _ruta = const RutaBiblioteca()`. La aplicacion abre con una lista de modulos, no con el
texto. En Logos la aplicacion abre en **el texto**, en el pasaje donde se quedo, y la
biblioteca es un destino mas del panel.

Con lo que hay hoy, abrir la app y ver una lista de ficheros no es un error: es lo unico
razonable cuando no hay ningun texto en el dispositivo. Lo que no es razonable es abrir con
esa lista **tambien cuando si hay un texto**, que es el caso normal de quien vuelve.

## Lo que este change hace

1. El marco lo pone el enrutador y envuelve **las cuatro** pantallas.
2. El destino marcado sale de la ruta, con una tabla, y no de un parametro.
3. La pantalla de lectura cae a la biblioteca cuando no hay texto, y entonces **la marca
   dice Biblioteca**, que es lo que se ve.
4. `_montar` de las pruebas del enrutador acepta el tamano, porque una prueba que pone 360 px
   no puede ver un fallo que no existe a 360 px.

## Y LO QUE NO SE HACE AQUI

**Abrir por el pasaje donde se quedo.** Es la respuesta completa a "raro en el indice
principal", y necesita **una clave mas en `Almacenamiento`** con el pasaje y la version.
Ahora no hay ninguna: `ultimoPasaje` no existe en el codigo. Es un change propio, con su
plazo de cinco segundos y su "si no contesta, se abre el primero", y va después de los
paneles múltiples, que es lo que falta para que tener "dos sitios donde se está leyendo"
tenga sentido.
