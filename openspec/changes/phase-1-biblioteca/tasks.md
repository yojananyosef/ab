# Tasks

## 1. Estructura de capas y dominio

- [x] 1.1 Crear `lib/domain/models/` con `Modulo` (id, nombre, tipo, idioma, licencia, tamano, sha256, url), `Manifiesto`, `Referencia`, `Pasaje` y `Versiculo`, y verificar con `flutter analyze` que no hay avisos
- [x] 1.2 Crear `lib/domain/models/estado_modulo.dart` con los cinco estados (`disponible`, `descargando`, `descargado`, `desactualizado`, `retirado`), y verificar con una prueba que cada estado se obtiene de comparar manifiesto y dispositivo y que **ninguno** se persiste en ningun sitio
- [x] 1.3 Crear `lib/data/models/` con los equivalentes de API: `ModuloCatalogo`, `ManifiestoApi`, `UltimoJson`; verificar que el mapeo a dominio convierte `sizeBytes` a entero y falla si el manifiesto no trae los campos obligatorios
- [x] 1.4 Anadir `REPOSITORIO` y la derivacion de URLs en `lib/data/services/origen.dart`, sobrescribible con `--dart-define=AB_ORIGEN_CATALOGO=...`. Verificar **con el grep anclado**, no suelto:

  ```
  grep -rnE '^[^/]*\b(KJV|RVR60|ASV|Douay|Young|Geneva|Sefarad|Lenguer)\b' lib/
  ```

  Sin anclar, el patron tambien casa con los comentarios, y hay un comentario
  que menciona la RVR precisamente para explicar por que no hay tabla de
  numeros. Una comprobacion que da falsas alarmas acaba ignorandose, que es peor
  que no comprobar. Anclado, `lib/` queda limpio y el motivo esta escrito. Y el
  cambio es el unico sitio donde vive una direccion
- [x] 1.5 Escribir `lib/domain/models/libros.dart` con los 66 nombres de libro en castellano y su clave de modulo, y **nada mas**: ni capitulos, ni versiculos, ni totales; verificar con una prueba que el fichero no contiene ningun numero de capitulo

## 2. Services: red, hash y SQLite

- [x] 2.1 Crear `lib/data/services/http_service.dart` con `rango(Uri, from, to)`, y verificar contra un servidor local que un rango `bytes=0-1023` devuelve exactamente 1024 bytes y que la respuesta final se ve en las cabeceras
- [x] 2.2 Crear `lib/data/services/hash_service.dart` que calcule el sha256 por tramos con `AccumulatorSink`; verificar que el hash calculado por tramos de un fichero real es el mismo que da `sha256sum`
- [x] 2.3 Crear `lib/data/services/sqlite_nativo.dart`, `sqlite_web.dart` y `sqlite_service.dart` con import condicional; verificar con `flutter analyze` que solo los dos primeros mencionan `package:sqlite3/sqlite3.dart` o `package:sqlite3/wasm.dart`
- [x] 2.4 Abrir un `.amod` real en modo solo lectura y ejecutar `PRAGMA quick_check`, `SELECT value FROM info WHERE key='id'` y `SELECT count(*) FROM verses`; verificar que salen `ok`, `KJV2006` y `31102`, usando el `.amod` real de `aa` como fixture, y **NOT** uno inventado de 10 filas
- [x] 2.5 Calcular el sha256 del fichero antes y despues de leer y verificar que es `ce0cb1bc4edbf3341d673739539421bbfed3972e39cbac5fc129f35f25324fe9` en los dos momentos, o sea, que leer no lo altera
- [x] 2.6 Comprobar que abrir en modo escritura **NOT** es posible por la via que usa la app, para que un modulo no se pueda modificar por descuido; verificar que el intento falla con error de solo lectura
- [x] 2.7 Leer la tabla `info` del modulo a modelos de dominio: `copyright`, `attribution`, `license`, `license_evidence`, `defects`, `defects_count`, `content_hash`, `versification`, `schema_version`, `minReaderVersion`. Verificar contra el KJV real que salen los 15 campos y que `defects_count` es 0
- [x] 2.8 Comparar la `schema_version` y el `minReaderVersion` con los que la app soporta, y negar la apertura si exceden. **Medido: los dos NO vienen del mismo sitio.** La `schema_version` esta en la tabla `info` del modulo; el `minReaderVersion` **no esta**, y hay que leerlo del manifiesto, porque es compatibilidad del cliente. Verificar con tres pruebas: `schema_version` mayor, `minReaderVersion` mayor, y el KJV real que si abre. Que el error nombre las dos versiones

## 3. Catalogo: manifiesto, verificacion y respaldo

- [x] 3.1 Leer `latest.json` y `catalog.json` desde el origen; verificar contra el manifiesto real publicado que se leen 2 modulos con los 12 campos obligatorios presentes y no vacios
- [x] 3.2 Verificar el `catalogSha256` antes de usar el manifiesto; verificar con dos pruebas, una con hash coincidente y otra con un byte alterado, que la segunda **NOT** pinta ningun modulo y que el error dice los dos hashes
- [x] 3.3 Guardar el ultimo manifiesto leido con exito y usarlo cuando el servidor no responde; verificar que con origen caido y manifiesto guardado se pinta la biblioteca y se avisa de que es una copia guardada
- [x] 3.4 Comprobar que con origen caido y **sin** manifiesto guardado hay error con boton de reintentar y **NOT** una espera indefinida; verificar que la prueba termina antes de 10 s y no con un temporizador colgado
- [x] 3.5 Calcular el estado de cada modulo a partir de manifiesto y dispositivo; verificar con una prueba que cubre los cinco estados, incluido que un modulo descargado que desaparece del manifiesto queda `retirado` y no desaparece de la biblioteca

## 4. Obtencion de modulos

- [ ] 4.1 Obtener por rango con progreso en bytes reales; verificar que un modulo de 22.544.384 bytes reporta de 0 a 22.544.384, sin saltos y sin pasar del total
- [ ] 4.2 Calcular el sha256 mientras llegan los bytes y no despues; verificar que la memoria no llega a tener el modulo entero dos veces, midiendo el pico en la prueba
- [ ] 4.3 Distinguir el fallo de origen cruzado del fallo de red, en vez de tratarlos igual. **La URL real que falla es `downloadUrl`, no `browserUrl`**: `browserUrl` ya funciona, y probarla esperando que falle seria una prueba que pasa por lo que no toca. Verificar las dos ramas: con la `downloadUrl` del catalogo publicado, que esta medida como bloqueada, sale el estado de origen no legible; y con un servidor local sin la cabecera, tambien
- [ ] 4.4 Hacer que el mismo codigo funcione contra un servidor local que envie `Access-Control-Allow-Origin: *`; verificar que el modulo queda `descargado` y no sale ningun aviso
- [ ] 4.4b **Probar la via principal contra el sitio real, no solo contra el mock.** Descargar un `.amod` desde la `browserUrl` del catalogo publicado y comprobar que el sha256 recibido es el que declara el manifiesto. Es la unica prueba de que este change sirve de algo: todo lo demas del grupo va contra un servidor que controlamos nosotros y que no puede fallar como el de verdad
- [ ] 4.5 Obtener desde fichero local, por selector y por arrastrar y soltar; verificar que el hash se comprueba contra el manifiesto y que un fichero ajeno se rechaza mostrando su sha256
- [ ] 4.6 Acotar los reintentos a 3 y terminar en estado final con boton de reintentar; verificar que tras 3 intentos el progreso **NOT** sigue animado y que el error dice cuantos bytes llegaron de los esperados
- [ ] 4.7 Cancelar una descarga en curso; verificar que tras cancelar no queda ninguna fila en estado `descargando` ni un fichero a medias abierto

## 5. Persistencia del modulo en el dispositivo

- [ ] 5.1 Volcar el `.amod` obtenido a IndexedDB en web y a fichero en nativo, escribiendo primero en memoria y volcando despues, porque la API de SQLite es sincrona y el almacenamiento es asincrono; verificar con una prueba de que el volcado termina y el modulo se vuelve a abrir
- [ ] 5.2 Comprobar la cuota del navegador **antes** de escribir y decirlo con palabras si no cabe, en vez de fallar en silencio; verificar que el modulo ya se puede leer en memoria aunque no se haya podido guardar
- [ ] 5.3 Recuperar en el arranque siguiente el modulo guardado sin volver a traer los bytes; verificar en el grupo 8 con dos ejecuciones del mismo perfil de navegador

## 6. Pantalla de biblioteca

- [ ] 6.1 Pintar cada modulo con nombre, tipo, idioma, licencia y tamano en megabytes con un decimal, todo leido del manifiesto; verificar con una prueba de widget que un modulo declarado solo en el manifiesto aparece con su tamano exacto
- [ ] 6.2 Anadir filtro por texto, por idioma y "solo lo que ya tengo"; verificar que filtrar por un idioma que no existe deja la lista vacia **con aviso**, y no un error
- [ ] 6.3 Mostrar el estado con texto y no solo con color; verificar con una prueba de widget que los cinco estados tienen texto legible
- [ ] 6.4 Mostrar el aviso de manifiesto copiado cuando se usa el respaldo; verificar con una prueba de widget que aparece y desaparece segun el estado
- [ ] 6.5 Mostrar en la fila el motivo por el que un modulo no se puede descargar, y el boton de fichero local. Verificar **las dos ramas por separado**: con la `downloadUrl` real, que si falla, el texto aparece y el boton existe; y con la `browserUrl` real, que funciona, el texto **NOT** aparece. Un aviso que sale siempre no informa de nada
- [ ] 6.6 Comprobar la pantalla a 360x640 y a 1440x900 sin excepciones; verificar ademas que a 360 px el boton de cada fila se alcanza sin desplazar horizontalmente

## 7. Pantalla de lector y rutas

- [ ] 7.1 Mostrar un capitulo completo con los versiculos numerados; verificar con una prueba de widget que Juan 3 sale con 36 versiculos y que el 16 es el texto completo
- [ ] 7.2 Resolver los 66 nombres de libro en castellano contra un `.amod` real; verificar que los 66 resuelven y que "1 Corintios" y "Segundo de Corintios" abren el mismo libro
- [ ] 7.3 Avisar en castellano cuando un pasaje no existe en esa traduccion, y ofrecer el ultimo pasaje valido anterior; verificar con una prueba de widget con un capitulo y un versiculo inventados
- [ ] 7.4 Escribir la referencia en la direccion, con `PathUrlStrategy` y `HashUrlStrategy` como reserva; verificar que recargar conserva el pasaje y que "atras" vuelve a la biblioteca
- [ ] 7.5 Usar `replaceState` para cambiar de version o de ajuste, y `pushState` para cambiar de capitulo; verificar que tras cambiar de version, "atras" **NO** deshace ese cambio
- [ ] 7.6 Anadir el campo de referencia con validacion en vivo y el boton de buscar deshabilitado mientras no sea valido; verificar a 360 px con el teclado abierto que el campo y el boton quedan por encima del teclado y que el texto de entrada es de al menos 16 px
- [ ] 7.7 Limitar la columna de texto a 90 caracteres por linea como maximo y centrarla en pantallas anchas; verificar a 1440 px que el ancho de la columna no supera ese limite
- [ ] 7.8 Obtener el numero de capitulos de cada libro con una consulta al modulo, sin ninguna tabla de capitulos en el codigo; verificar que Genesis ofrece del 1 al 50 y **NOT** un 51, y que Juan suma 879 versiculos. El 51 es el numero que da la RVR, y el fallo de escribirlo de memoria esta documentado en el repositorio hermano
- [ ] 7.9 Comprobar que en el codigo no hay ninguna tabla de numeros de libro, con el grep anclado a codigo: `grep -rnE '^[^/]*\b(chapterCount|versiculosPorLibro|numCapitulos|capitulosPorLibro)\b' lib/`. Sin anclar casaria con los comentarios que explican que no hay tabla, y una comprobacion que siempre falla no verifica nada
- [ ] 7.10 Mostrar en la pantalla de lectura los terminos del modulo: `copyright` y `attribution` visibles sin abrir ningun menu; verificar con una prueba de widget que aparecen sin pulsar nada
- [ ] 7.11 Mostrar `license` y `license_evidence` junto a la atribucion; verificar con una prueba de widget que tambien son accesibles en un solo toque
- [ ] 7.12 Si el manifiesto y el `info` del modulo discrepan de licencia, mostrar la del modulo y avisar de la discrepancia con las dos; verificar con una prueba que usa un manifiesto alterado a proposito
- [ ] 7.13 Si `defects_count` es mayor que 0, avisar en castellano de cuantos versiculos vienen incompletos y mostrar el texto de `defects`; verificar con una prueba con un modulo de defecto, y la inversa: con `defects_count` 0 **NOT** aparece ningun aviso de texto incompleto
- [ ] 7.14 Mostrar el valor de `versification` del modulo; verificar con una prueba de widget que aparece el `KJV` del KJV real

## 8. Comprobacion en navegador de verdad

Este grupo es el que `flutter test` **NOT** puede sustituir: Flutter pinta en un
canvas y `flutter test` no ejecuta el motor de render. Una app puede pasar todas
las pruebas de los grupos anteriores y no funcionar en ningun navegador.

- [ ] 8.1 Anadir un script que haga `flutter build web`, sirva `build/web` en local y lo lance en Chrome headless volcando el resultado al DOM; verificar que el script imprime el resultado en vez de fallar en silencio
- [ ] 8.2 Comprobar con ese script que la app abre un `.amod` real desde el navegador y muestra Juan 3:16; verificar que el texto pintado es el mismo que el de `docs/investigacion/sqlite-en-navegador.md`
- [ ] 8.3 Ejecutar el script dos veces con el mismo perfil de navegador; verificar que en la segunda el contador de bytes descargados es 0, porque el modulo se recupera del almacenamiento
- [ ] 8.4 Comprobar con el script que el manifiesto se lee del origen real y que un modulo aparece con su tamano; verificar que el texto de pantalla coincide con el `catalog.json` publicado
- [ ] 8.5 Ejecutar `flutter analyze`, `flutter test` y `flutter build web` en este orden; verificar que los tres salen con codigo 0

## 9. Documentacion

- [ ] 9.1 Explicar en `README.md` que los modulos se bajan de `browserUrl` y **NOT** de `downloadUrl`, y por que: la segunda es correcta para nativo y en navegador da `Failed to fetch`. Verificar que el enlace a `transporte-cors.md` apunta a un fichero que esta en el repositorio, y que el texto no dice que la descarga este bloqueada, porque ya no lo esta
- [ ] 9.2 Anadir a `docs/investigacion/sqlite-en-navegador.md` la salida del grupo 8 junto a la del spike; verificar que las dos cifras se distinguen explicitamente, para que nadie las confunda
- [ ] 9.3 Dejar escrito en `AGENTS.md` que el SDK es Flutter 3.47.6 y que Android, Linux y Windows no estan verificados; verificar que el numero de version coincide con el de `flutter --version`