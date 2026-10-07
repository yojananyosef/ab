# Tasks

## 1. Donde viven

- [x] 1.1 `AlmacenamientoDeResaltadosWeb`, con `dart:js_interop` y sin paquete, como el de
      modulos
- [x] 1.2 Base **propia**: `ab-resaltados`, y **NOT** un almacen mas de la de los modulos
- [x] 1.3 Dos almacenes, `resaltados` y `estilos`, para que renombrar un estilo no reescriba
      los miles de resaltados
- [x] 1.4 `crearAlmacenamientoDeResaltados()` con import condicional, que es el unico sitio
      donde se decide
- [x] 1.5 `AlmacenamientoDeResaltadosNativo`: un **fichero** JSON, en el directorio de
      soporte de la aplicacion y en un subdirectorio propio
- [x] 1.6 Escritura **atomica** a `.parcial` y `rename`, y si falla el estado en memoria se
      queda como estaba
- [x] 1.7 `resaltado_web.dart` con `jsify`/`dartify` de un mapa, y no un `JSObject` a mano

## 2. El cableado, que era lo que faltaba

- [x] 2.1 **`main.dart` pasa `crearAlmacenamientoDeResaltados()`**, que era la linea entera del
      fallo
- [x] 2.2 `AbApp` acepta el almacen por parametro, y el motivo esta escrito: en la maquina de
      Dart no hay `path_provider` y el almacen nativo se queda esperando, con lo que el
      `Timer` del plazo sobrevive a la prueba y falla con `A Timer is still pending`, que no
      menciona ni el almacen ni los resaltados
- [x] 2.3 `test/widget_test.dart` pasa el suyo

## 3. Lo que la escritura tiene que hacer bien

- [x] 3.1 **Esperar a la transaccion**, no solo a la peticion: una transaccion puede fallar al
      confirmar, por ejemplo si se agota la cuota, y con solo la peticion `poner` diria «ok» de
      un resaltado que no esta en ningun sitio
- [x] 3.2 Un registro que no se puede leer **se salta**, y no tumba el `getAll` entero
- [x] 3.3 Cada campo con su tipo al leer, y no solo «que no sea null»: `capitulo` en `3.5`
      daria un versiculo 3 en el sitio equivocado
- [x] 3.4 El color **como entero**, y no como cadena hexadecimal; leerlo mal es un fallo
      **silencioso**, el resaltado sale en otro color y nadie sabe por que
- [x] 3.5 `borrarTodo` quita **los dos** almacenes

## 4. Las pruebas

- [x] 4.1 `test/data/almacenamiento_de_resaltados_test.dart`, 12 pruebas
- [x] 4.2 **Sobre el view model de la aplicacion**: que la fabrica no devuelva el almacen en
      memoria. Es la comprobacion que faltaba y la que evita que esto vuelva: una prueba que
      construye su propio almacen comprueba que el almacen funciona, no que la aplicacion **lo
      use**
- [x] 4.3 Cerrar y volver a abrir el almacen, que es la unica forma de ver un fallo «no se
      guarda»
- [x] 4.4 Que no queda un `.parcial` a medias, y que cinco escrituras dejan **un** fichero
- [x] 4.5 Un JSON con registros raros, y uno que no es JSON
- [x] 4.6 View model, almacen y fichero unidos, con el recorrido completo

## 5. La hoja, que se ha encontrado rota de paso

- [x] 5.1 `isScrollControlled: true` y un `maxHeight` del 80 %: un `SingleChildScrollView`
      **no pide** su alto natural, lo pide infinito, y con el valor de por defecto la hoja se
      conforma con lo que le dan y no crece
- [x] 5.2 `test/ui/marcar_llega_al_almacen_test.dart`: los cinco estilos **dentro** de la
      ventana a 640, a 900 y a 1200, y no solo en el arbol. Un `find.text` encuentra un widget
      que esta fuera de la ventana, y ahi no se ve ni se puede tocar

## 6. Comprobado en el navegador

- [x] 6.1 La aplicacion abre la base `ab-resaltados`, crea el almacen `resaltados` y lo lee:
      `indexedDB.databases()` devuelve `["ab", "ab-resaltados"]` y `getAll` devuelve `[]` en
      vez de un error
- [x] 6.2 El indice del modulo sobrevive a quitar el service worker y las caches, que es lo
      que permite comprobar la escritura sin volver a bajar 22 MiB
- [x] 6.3 Sin errores de pagina

## 7. **PENDIENTE Y SIN RESOLVER**, escrito aqui para que no se pierda

- [ ] 7.1 **La altura de la hoja a 1440 px. SIN RESUELTO Y CON MAS DATOS QUE EL 6 DE
      OCTUBRE.** Medido en el navegador a 1440 x 900 con el paquete nuevo y el servidor
      correcto: la hoja mide **unos 140 px** y los cinco estilos quedan **debajo del pliegue**:
      se ven el titulo y el subtitulo y nada mas.
      Y **no se reproduce en Dart**: cinco pruebas lo miran a 360, a 768 y a 1440 de ancho, con
      la ventana a 640, a 900 y a 1200 de alto, y **dentro del marco de estudio** --que es como
      se ve de verdad a 1440 px-- y en todos los casos los cinco caben. Esta en
      `seleccionar-y-la-linea-que-sigues/tasks.md`, 6.2 y 6.3.
- [ ] 7.2 Lo que **no** se ha explicado es la diferencia entre los dos anchos. La hoja mide
      145 px con los dos anchos, con lo que no es que el ancho la encoja. La sospecha que no
      se ha podido comprobar es el `useRootNavigator` de por defecto: la hoja se abre desde el
      `context` de la vista de lectura, que a 1440 px esta dentro del marco, y podria estar
      midiéndose contra otro `MediaQuery`.
- [ ] 7.3 **No** se ha cerrado el recorrido entero en el navegador: marcar un versiculo, recargar
      y ver que sigue ahi. Lo que si esta comprobado es la base creada y legible, y en Dart el
      recorrido completo con cierre y reapertura. Lo que falta es unir las dos cosas.
- [ ] 7.4 **El almacen nativo no se ha ejecutado.** `AGENTS.md` lo dice y aqui se repite porque
      es un fichero nuevo: no hay SDK de Android ni GTK en esta maquina. Lo que si esta
      comprobado es el formato del fichero y la conversion.

## 8. Lo que queda de los resaltados

- [ ] 8.1 El boton de exportar e importar, que el modelo tiene con 25 pruebas y la interfaz no
- [ ] 8.2 El panel de gestion, con buscar por estilo
- [ ] 8.3 Los ficheros de resaltados intercambiables
- [ ] 8.4 Las notas de texto libre