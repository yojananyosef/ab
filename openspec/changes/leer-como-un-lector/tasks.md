# Tasks

## 1. Poder mirar

- [x] 1.1 `scripts/capturar.mjs` con Playwright; `page.screenshot()` funciona donde `--screenshot` no
- [x] 1.2 Con `--enable-unsafe-swiftshader`, sin el cual el lienzo sale **en blanco**
- [x] 1.3 **Sin** `--virtual-time-budget`, que es lo que deja a Flutter colgado
- [x] 1.4 Perfil **persistente**, o cada captura se baja 22,5 MB
- [x] 1.5 Calentar el perfil antes, o un enlace profundo a un modulo no descargado sale en la biblioteca
- [x] 1.6 Varios anchos con nombre: 320, 360, 414, 834, 1440, 1920
- [x] 1.7 Los errores de pagina se imprimen, porque un `overflow` no sale en la imagen

## 2. El alcance del pasaje

- [x] 2.1 Un versiculo pedido trae el capitulo **desde ese**, no un versiculo; verificar
- [x] 2.2 `Pasaje.versiculoPedido`, porque `Juan 3:16` y `Juan 3` dan la misma lista; verificar
- [x] 2.3 El versiculo pedido se marca con una **linea vertical** y color de acento; verificar
- [x] 2.4 El **numero** del versiculo no cambia de columna, para que se lea como columna; verificar
- [x] 2.5 Pedir el ultimo versiculo trae solo ese; verificar
- [x] 2.6 Salmos 119, el capitulo mas largo, entra entero; verificar
- [x] 2.7 El comentario trae las notas del mismo rango; verificar
- [x] 2.8 El coste medido: 5,1 ms Juan 3:16, 9,6 ms Salmos 119, 0,26 ms el comentario; verificar

## 3. Lo que sobraba arriba

- [x] 3.1 El boton de ir **dentro** del campo, y no debajo; verificar
- [x] 3.2 Con texto aparece el boton y no hay texto, no; verificar
- [x] 3.3 El teclado tambien lleva a lo escrito; verificar
- [x] 3.4 El titulo del capitulo, que **repetia** la barra, desaparece; verificar
- [x] 3.5 Las flechas de capitulo van en la fila del campo; verificar
- [x] 3.6 A 360 y a 320 px no sale del borde; verificar

## 4. Los dos fallos que solo se ven mirando

- [x] 4.1 El enrutador **avisa** cuando la biblioteca cambia; verificar
- [x] 4.2 La version aparece cuando llega el manifiesto, con el enrutador entero montado; verificar
- [x] 4.3 Y el pasaje sigue donde estaba al redibujar; verificar

## 5. Lo que queda, y no se hace aqui

- [ ] 5.1 Los terminos del modulo, que son la parte mas larga de la pantalla con un pasaje corto
- [ ] 5.2 La biblioteca: tres controles por modulo donde basta uno
- [ ] 5.3 Las paginas de dialogo casi todas rojas en los evangelios
