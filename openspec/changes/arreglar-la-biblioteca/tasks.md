# Tasks

## 1. Un modulo no es una Biblia porque lo diga la app

El crash de la captura: `SELECT count(*) FROM verses` sobre un comentario, que
tiene tabla `commentary` y no `verses`.

- [x] 1.1 Medir, sobre los dos `.amod` reales, que tablas tienen y que declara `info.type`; verificar que son cosas distintas y que las dos se pueden medir por separado
- [x] 1.2 Anadir `TipoDeContenido` en `lib/domain/models/`, que se lee de `info.type`; verificar que un tipo desconocido **no** se supone una Biblia
- [x] 1.3 Anadir `NoEsUnaBiblia` como excepcion y no como resultado; verificar que el mensaje dice que es un comentario y que el fichero esta entero
- [x] 1.4 Preguntar el tipo en `ModuloAbierto.abrir` y negarse a abrir si falta; verificar que el motivo lo dice
- [x] 1.5 Poner el guard en las ocho consultas que usan `verses`; verificar que una Biblia sigue funcionando con 66 libros y 31.102 versiculos
- [x] 1.6 Cambiar `_comprobarQueAbre` en `main.dart` para que pregunte el tipo y no la tabla; verificar que el CLARKE real sale con un mensaje de "falta la pantalla" y no con un `SqliteException`
- [x] 1.7 Pruebas con el CLARKE y con el KJV reales; verificar que se abre, que dice que es un comentario, y que pedirle versiculos da el motivo en castellano

## 2. Un aviso no es un error, y un progreso no es un aviso

Los veinte "Bajando X: N por ciento" en rojo de la captura.

- [x] 2.1 Anadir `Aviso` con `clase` (`error` / `informacion`) y `clave`; verificar que el progreso lleva clave `progreso:$id`
- [x] 2.2 Cambiar `avisos` de `List<String>` a `List<Aviso>` y deducir la clase de los del repositorio segun el estado de lectura; verificar que una copia guardada **no** es un error
- [x] 2.3 Anadir `progresoDeDescarga`, que reemplaza el anterior del mismo modulo; verificar que diez tramos dejan **un** aviso
- [x] 2.4 Anadir `quitarProgreso` y llamarlo en un `finally` de la descarga; verificar que el progreso desaparece salga bien o mal
- [x] 2.5 Anadir `quitarAviso`, `quitarErrores` y el recorte a cuatro; verificar que quitar los errores **no** quita los de informacion
- [x] 2.6 Marcar como error los cinco finales de obtencion que lo son, y dejar `HayVersionNueva` como informacion; verificar que una app en funcionamiento no se ve rota
- [x] 2.7 Pintar el progreso como **barra** con el porcentaje escrito, y los errores en caja con boton de quitar; verificar que "Bajando CLARKE: 90 por ciento" no sale nunca como texto

## 3. La banda de avisos no tapa la biblioteca

- [x] 3.1 Poner un tope de **altura** con scroll propio, no un tope de lineas; verificar que con seis avisos largos no crece de 168 px
- [x] 3.2 Verificar con veinte progresos y dos errores que el modulo **sigue viendose** a 360 px y que no hay nada fuera de la pantalla
- [x] 3.3 Verificar que el progreso de un modulo no borra el de otro, porque dos descargas a la vez son posibles
- [x] 3.4 Verificar que la banda no crece cuando no hay avisos, y que el primer modulo queda arriba

## 4. La barra y el cuerpo caen en la misma columna

- [x] 4.1 Meter el titulo dentro del mismo `ContenidoCentrado` que el cuerpo, con el texto pegado a la izquierda **dentro**; verificar que no se puede con un `titleSpacing`
- [x] 4.2 Sacar el margen de la fila de `Medidas.margenPara`; verificar que el desfase de diez pixeles entre filtro y fila desaparece
- [x] 4.3 Pruebas a 360, 768, 1440 y 1900 px; verificar que titulo, filtro y lista empiezan en el mismo sitio y que la columna no se estira de 560

## 5. Una sonda que se traga sus errores no es una sonda

Aparicio al montar la comprobacion en navegador con los cambios de arriba.

- [x] 5.1 Convertir los avisos del informe a `List<String>` antes de mandarlos; verificar que `jsonEncode` no puede lanzar
- [x] 5.2 Envolver el `JsonEncoder` de `escribir` en un `try` que escribe el fallo; verificar que `escribir` no lanza nunca
- [x] 5.3 Exponer `escribirConEsteCodigo` para poder probarlo sin navegador; verificar que no es un parametro de la sonda, sino una funcion aparte
- [x] 5.4 Pruebas: un informe con un objeto que no es JSON escribe el motivo y no revienta, un informe normal se escribe entero, y un informe que falla no cambia lo que se ha visto

## 6. Comprobarlo entero

- [x] 6.1 `flutter analyze` sin avisos; verificar que sale con codigo 0
- [x] 6.2 `flutter test` en verde; verificar que pasan las 368 pruebas
- [x] 6.3 `scripts/comprobar-en-navegador.sh` en un navegador de verdad; verificar que Juan 3:16 sale, que Juan 3 tiene 36 versiculos, que la segunda ejecucion baja 0 bytes y que el historial va `3 -> 4 -> 4 -> 5`
- [x] 6.4 Dejar en `AGENTS.md` los cinco fallos medidos, con la regla que sale de cada uno; verificar que estan con su sintoma, su causa y su regla