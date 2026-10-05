# Tasks

## 1. Los datos

- [x] 1.1 Que `buscar` devuelva tambien el **extracto** de alrededor, en la misma consulta; verificar que no hace una consulta por resultado
- [x] 1.2 Que el extracto salga de `instr`/`substr` y no de traer el versiculo entero; verificar que la consulta trae poco
- [x] 1.3 Que diga **cuantos** hay en total, no solo los primeros 200; verificar que el numero sale del mismo `count(*)`
- [x] 1.4 Que busque tambien en el comentario, y con el mismo extracto; verificar que las dos tablas funcionan
- [x] 1.5 Que el patron se escape para que `%` y `_` que escriba quien busca sean literales; verificar que `%` no trae todo

## 2. El dominio

- [x] 2.1 `ResultadoDeBusqueda` con referencia, extracto y si hay mas; verificar que la palabra buscada se guarda **en el**, y no en un campo aparte
- [x] 2.2 Que el texto de la palabra buscada este en el extracto en el sitio exacto, no "parecido"; verificar con mayusculas y minusculas

## 3. La ruta

- [x] 3.1 `/buscar/{modulo}/{palabra}`, y la palabra va **codificada**; verificar que una palabra con `/` o con espacios no rompe la ruta
- [x] 3.2 Id y vuelta en los dos sentidos; verificar
- [x] 3.3 Que `/buscar/{modulo}/` con barra final sea la pantalla de busqueda vacia, y que **sin** barra sea una ruta que no se entiende; verificar las dos
- [x] 3.4 Que un modulo que no esta descargado avise y vuelva, como en el lector; verificar

## 4. La pantalla

- [x] 4.1 Los resultados se pintan con el **numero de versiculo** y el extracto, y nada mas
- [x] 4.2 Al pulsar un resultado se abre **ese** pasaje, con el comentario que hubiera; verificar
- [x] 4.3 Un campo para cambiar la palabra, y no salir al pulsar "atras"
- [x] 4.4 Si no hay resultados, se dice en una frase lo que se busco; verificar
- [x] 4.5 Si hay mas de 200, se dice cuantos hay en total
- [x] 4.6 Se dice que es una busqueda por texto, no por palabra; verificar que el aviso esta
- [x] 4.7 A 360 px un resultado largo no sale del borde; verificar

## 5. Comprobarlo

- [x] 5.1 Pruebas con el KJV y el CLARKE **reales**
- [x] 5.2 `flutter analyze` limpio y `flutter test` en verde
- [x] 5.3 En `AGENTS.md`: lo que `LIKE` **no** es, y el `%` que hay que escapar
