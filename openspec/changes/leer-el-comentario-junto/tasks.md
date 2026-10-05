# Tasks

## 1. La ruta

- [x] 1.1 `RutaLectura` con `comentario`, y `==`/`hashCode`/`toString` que lo tengan en cuenta; verificar que dos rutas que solo difieren en el comentario **no** son iguales
- [x] 1.2 `Rutas.leer` acepta el segmento `/con/` y lo quita antes de pedirle el pasaje al `Referencia.tryParse`; verificar que `/con/` pegado al pasaje no se cuela dentro de el
- [x] 1.3 `Rutas.escribir` escribe el segmento cuando hay comentario y **no** lo escribe cuando no; verificar que la ida y la vuelta cuadran en los dos sentidos
- [x] 1.4 Un `con/` sin comentario, o con uno vacio, es una ruta que no se entiende; verificar que no revienta
- [x] 1.5 El `404.html` del despliegue sigue sirviendo estas rutas; verificar con el script

## 2. El ViewModel

- [x] 2.1 Abrir el comentario **no** cierra el texto, y cerrar el comentario **no** borra el pasaje; verificar que `pasaje` sobrevive
- [x] 2.2 `notasDe(versiculo)` sale del comentario y **no** del texto; verificar que con el mismo versiculo en los dos sale lo del comentario
- [x] 2.3 `versiculosConNota` y `tieneNotasDe(versiculo)`; verificar que un versiculo sin nota no dice que tiene
- [x] 2.4 Sin comentario, las notas estan vacias y **no** hay error; verificar que es lo que pasa al abrir `/leer/KJV2006/John.3.16` a secas
- [x] 2.5 Cerrar el comentario se lleva por delante su base de datos; verificar que no queda abierto
- [x] 2.6 Un comentario que no abre deja el texto leido y lo avisa; verificar que no se cae la pantalla

## 3. La pantalla

- [x] 3.1 Las notas van **debajo de su versiculo**, y no todas al final del capitulo; verificar el orden en pantalla
- [x] 3.2 Se reutiliza el widget de nota del change anterior, no una copia; verificar que el cuerpo de una nota junto al versiculo es el mismo que el de la pantalla de comentario
- [x] 3.3 La nota se dice de que versiculo es tambien aqui, con un lector de pantalla; verificar el nombre accesible
- [x] 3.4 El boton de la barra dice que comentario hay abierto y como quitarlo; verificar los dos estados
- [x] 3.5 La lista sale del manifiesto y de lo descargado, y **no** de una lista en el codigo; verificar que no hay ningun identificador escrito
- [x] 3.6 A 360 px el versiculo con su nota no sale del borde; verificar con una nota de 405 caracteres

## 4. El comentario que falta

- [x] 4.1 El aviso ofrece **bajarlo**, con el tamano en el boton; verificar que sale el de megabytes y no un "Descargar" a ciegas
- [x] 4.2 Lo que el catalogo no tiene **no** se ofrece; verificar que no hay boton y que el texto se lee igual
- [x] 4.3 Al terminar la descarga el comentario se abre **solo**; verificar que la URL no cambia
- [x] 4.4 La escucha del enrutador mira **una** sola cosa; verificar que abrir y quitar el comentario dos veces no lo reabre

## 5. El navegador

- [x] 5.1 La sonda distingue el comentario **suelto** del que va **al lado**; verificar que los dos casos se pueden comprobar por separado
- [x] 5.2 El script tiene una tercera ejecucion con `/con/`, reutilizando el perfil; verificar que solo bajan los 57 MiB del comentario
- [x] 5.3 El historial del navegador sigue siendo el mismo; verificar que el comentario **no** lo cambia
- [x] 5.4 La tercera ejecucion tiene **su propia build**, porque la ruta de la sonda va compilada dentro; verificar que la del navegador lleva `/con/`
- [x] 5.5 `mirarLaAplicacion` no da el resultado por bueno mientras falte el comentario; verificar que sin esto se pasa con 0 bytes
- [x] 5.6 La sonda navega **con** el comentario de la ruta; verificar que la URL final lo lleva

## 6. Comprobarlo

- [x] 6.1 `flutter analyze` limpio y `flutter test` en verde
- [x] 6.2 Los numeros vienen del CLARKE y el KJV **reales**
- [x] 6.3 En `AGENTS.md`: los 79 MiB de dos modulos abiertos, el enlace que no bajaba nada, y abrir **no** es leer
