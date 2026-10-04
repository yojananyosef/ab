# Proposal

## Why

La pantalla de biblioteca, tal y como estaba el 4 de octubre de 2026, era
**imposible de usar**, y no por una razon de gusto sino por tres fallos
medidos. La captura que lo documento mostraba una ventana de 1900 px con
**veinte cajas rojas apiladas** y **ni un solo modulo en la lista**.

Detras de esa pantalla havia cuatro cosas distintas, y solo una era de
estetica:

1. **Un comentario no se podia abrir.** `main.dart` hacia
   `SELECT count(*) FROM verses` de todo lo que se descargaba, y un comentario
   **no tiene esa tabla**: tiene `commentary`. El modulo se descargaba entero,
   se guardaba bien y reventaba al abrir con
   `SqliteException(1): no such table: verses`. Ninguna de las 338 pruebas lo
   detectaba, porque todas las que abren un modulo usan el KJV.

2. **El progreso de descarga era un error.** Los avisos eran `List<String>`, sin
   tipo, asi que "Bajando CLARKE: 90 por ciento" salia en rojo con triangulo de
   alarma. Y no se reemplazaba: cada diez por ciento anadia una linea mas, y
   **ninguna se quitaba**, ni al terminar la descarga.

3. **Los avisos tapaban la biblioteca.** Van encima de la lista, en un `Column`
   sin tope de altura, y veinte cajas de texto se comen la pantalla entera.

4. **La barra y el cuerpo no caian en la misma columna.** A 1900 px el titulo
   estaba en la esquina y el contenido centrado a 560, a 1345 pixeles de
   distancia. Y la fila usaba un margen fijo de 14 mientras el filtro usaba
   `Medidas.margenPara`, que da 24 en anchas: diez pixeles de desfase entre el
   campo de busqueda y lo que filtra.

## What this change does

Arregla los cuatro, y anade lo que hace que no vuelvan:

- `TipoDeContenido`, que se lee de `info.type` del propio `.amod`, y
  `NoEsUnaBiblia`, que es una excepcion y no un resultado: una peticion que no
  tiene sentido no devuelve una lista vacia, porque una lista vacia se confunde
  con "este modulo no tiene ese capitulo".
- `Aviso`, con clase (`error` / `informacion`) y clave, para que un progreso
  **reemplace** al anterior en vez de acumularse, y para que solo lo que de
  verdad fallo se pinte como error.
- Una banda de avisos con tope de **altura** y scroll propio, el progreso como
  **barra** en lugar de texto, y un boton para quitar un error que ya no es
  verdad.
- El titulo de la barra dentro del mismo `ContenidoCentrado` que el cuerpo, y el
  margen de la fila saliendo de `Medidas.margenPara`.

Y arregla, de paso, un quinto fallo que solo aparecio al mirar la comprobacion
en navegador: la sonda **se tragaba sus propias excepciones**. Al mandar
`List<Aviso>` a un `jsonEncode` que solo sabe escribir `List<String>`, la
excepcion salia de `escribir` y se perdia, porque quien llama esta en un
`addPostFrameCallback`. Desde fuera, "la comprobacion no ha comprobado nada" y
"la comprobacion no ha dicho nada" se ven igual.

## What this change does NOT do

- **No lee comentarios.** Un comentario se descarga y se guarda, y se dice que
  todavia no hay pantalla para el. Enseñar el comentario junto al versiculo es
  el change siguiente, y este no lo adelanta ni un paso.
- **No toca el catalogo.** Sigue siendo un cliente: no decide licencias ni
  construye nada.
- **No cambia el resto de la pantalla de lectura.** El problema estaba en la
  biblioteca; lo de leer ya estaba comprobado en navegador.