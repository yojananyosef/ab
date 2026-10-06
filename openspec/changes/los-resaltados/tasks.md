# Tasks

## 1. El modelo

- [x] 1.1 `Resaltado` con **libro, capitulo, versiculo y estilo**, y nada mas; verificado que
      no hay campo de texto, ni de version, ni de fecha
- [x] 1.2 La clave es `John.3.16`, **la misma que la de la URL**; verificado
- [x] 1.3 `esElDe` campo a campo, y **sin version**: dos del mismo versiculo son el mismo
- [x] 1.4 `EstiloDeResaltado` con `id` y `nombre` **por separado**, para que renombrar no
      rompa los resaltados que lo usan; verificado
- [x] 1.5 `IntensidadDelResaltado` en tres pasos con nombre, y **suave = 0,30**, no 0,15;
      verificado que por debajo de 0,2 la marca no se ve
- [x] 1.6 `FormaDelResaltado` con tres pasos, y `enElAlmacenamiento` porque **los nombres de
      `enum` no son estables** entre compilaciones
- [x] 1.7 `ColorDeResaltado` en ARGB, con cinco de partida y **con mas**: un color que no se
      puede leer cae en el de partida, no en transparente
- [x] 1.8 `Resaltado.desdeJson` devuelve `null` con un campo malo, y **no** importa a medias

## 2. Donde viven

- [x] 2.1 `AlmacenamientoDeResaltados`, **propio y distinto** del de modulos; verificado que
      no se mezclan
- [x] 2.2 **Un registro por versiculo**, no una lista que se reescribe entera
- [x] 2.3 Un almacen **en memoria** para pruebas y pruebas de pantalla
- [x] 2.4 Un almacen **que lanza** y uno **que se queda esperando**, y son dos porque el plazo
      solo se puede probar contra una promesa que no resuelve
- [x] 2.5 `leerResaltadosConPlazo` con el plazo **por parametro**, para que la prueba del
      almacen colgado tarde 10 ms y no 5 s
- [x] 2.6 `ResultadoDeResaltados.hayQueAvisar`, que **no** es el negativo de `leido`

## 3. El view model

- [x] 3.1 `ResaltadosViewModel` propio, y no dentro del del lector: los resaltados son de la
      persona y los ven la lectura, la busqueda y el indice
- [x] 3.2 `cargar` **una vez** al abrir, y en paralelo con el catalogo, sin esperarlo
- [x] 3.3 `marcar` **pinta antes de guardar**, y avisa despues si el guardado no llego
- [x] 3.4 `quitar` **no avisa** si no habia nada: quitar lo que no esta es una pulsacion de mas
- [x] 3.5 `marcar` **pisa** el resaltado anterior en vez de anadir un segundo
- [x] 3.6 `estilosDelCapitulo` devuelve un mapa por versiculo, **una vez** por capitulo
- [x] 3.7 `estiloConEseId` cae en el primer estilo, y un resaltado con un estilo que no existe
      **se ve igual**; verificado
- [x] 3.8 `exportar` es un `Future`, porque leer los estilos es una espera
- [x] 3.9 `prepararImportar` **no escribe**: decide quien llama

## 4. Salir del dispositivo

- [x] 4.1 `exportarResaltados` con `formato`, `version` y `generado`, como los `.amod`
- [x] 4.2 Los estilos viajan **enteros**, con nombre, color, intensidad y forma
- [x] 4.3 `leerResaltados` **mira el `formato`**: un JSON de otra cosa se dice y no se come lo
      que hay; verificado con cuatro ficheros distintos
- [x] 4.4 Un texto que no es JSON **no lanza**: devuelve un `ResultadoDeImportar` con motivo
- [x] 4.5 Un resaltado malo dentro de un fichero bueno **se salta**, y el resto entra
- [x] 4.6 Un fichero sin estilos usa los de partida, para que nada quede invisible

## 5. En el texto

- [x] 5.1 `hoja_de_resaltado.dart`, con los cinco estilos y **quitar solo si lo hay**
- [x] 5.2 `EleccionDeResaltado` con **tres salidas**: elegir, quitar y cerrar. Con un solo
      `null`, cerrar la hoja sin querer **borra** el resaltado que habia
- [x] 5.3 Elegir el estilo **marca y cierra**: marcar es una accion de un paso
- [x] 5.4 La hoja **se desplaza**: a 360 x 640 se desbordaban 216 px, medido
- [x] 5.5 El numero del versiculo es un `TextButton` de 34 px con `shrinkWrap`, y **el texto
      no**: el texto se toca para seleccionar y copiar
- [x] 5.6 El fondo va **detras** del `TextSpan`, en el `DecoratedBox` de la fila
- [x] 5.7 `BoxDecoration` solo cuando hay algo que pintar: un `BorderSide` de ancho **0** con
      radio **no se puede pintar**, y el aviso sale al pintar; medido
- [x] 5.8 `_decoracionDelResaltado` en un sitio, y no cuatro `BorderSide` en linea
- [x] 5.9 El fondo del resaltado **no** tapa los terminos del modulo al final del capitulo
- [x] 5.10 `claveDelFondoDelResaltado`, porque una prueba que adivina cual `DecoratedBox` mira
      **pasa mirando el equivocado**

## 6. Lo que no estaba y hacia falta

- [x] 6.1 `LectorView` **escucha** a `ResaltadosViewModel`. Sin esto el marcado **no se veia**:
      la hoja se abria, se elegia estilo, y el versiculo seguia sin fondo. Medido en una
      captura a 360 px con veinticinco pruebas del view model en verde
- [x] 6.2 `didUpdateWidget` cambia la escucha cuando cambia el view model
- [x] 6.3 Cableado en `main.dart` y en el enrutador; `resaltados` es **opcional** en la vista
- [x] 6.4 Las siete pruebas de `flutter test` que montan `NavegadorAb`, con un almacen en
      memoria

## 7. Las pruebas

- [x] 7.1 `test/data/resaltados_test.dart`, 25 pruebas: modelo, estilos, quitar, plazo,
      exportar, importar
- [x] 7.2 `test/ui/marcar_versiculo_test.dart`, 8 pruebas **montando la pantalla** y marcando
      por el dedo, que es lo que ve el fallo de 6.1
- [x] 7.3 El aviso se prueba con `test` y **no** con `testWidgets`: dentro de `testWidgets` el
      reloj es falso y un `Future.timeout` no vence nunca, y la prueba se colgaba cuatro minutos
- [x] 7.4 `montarLector` acepta `resaltados` en opcional, para no montar un almacen en las 60
      pruebas que no miran resaltados
- [x] 7.5 Suite completa: **660** en verde, `flutter analyze` sin avisos

## 8. Comprobado en el navegador

- [x] 8.1 Captura a 360 px con el versiculo 16 marcado en amarillo: el fondo sale, el texto
      **sigue siendo el rojo de las palabras de Jesus** y se lee igual
- [x] 8.2 La marca del versiculo pedido -- la regla verde de la izquierda -- sigue encima
- [x] 8.3 La hoja sale con los cinco estilos, cada uno con su color y su forma
- [x] 8.4 Sin errores de pagina

## 9. Lo que queda, y por que

- [ ] 9.1 **La pantalla de gestion**: listar, buscar y renombrar estilos. Es un destino mas del
      marco, o una hoja
- [ ] 9.2 **Buscables por estilo**, que es la cuarta de las cinco cosas de Accordance: buscar
      "amarillo" devuelve todos los versiculos marcados asi. Un indice tematico personal
- [ ] 9.3 **Varios ficheros de resaltados** intercambiables de un clic: "temas teologicos",
      "devocion", "clase". El mismo versiculo marcado de tres maneras sin ensuciarse
- [ ] 9.4 **Notas de texto libre** junto al resaltado
- [ ] 9.5 **Exportar e importar desde la interfaz**: hoy la exportacion existe y esta probada
      en el modelo, pero no hay boton
- [ ] 9.6 **El almacen en el navegador**: `AlmacenamientoDeResaltados` solo tiene la
      implementacion en memoria. La de `IndexedDB` es la que falta, y es la que decide si esto
      sobrevive a cerrar el navegador. **No se puede dar por hecho que esta hecho**
- [ ] 9.7 **Notas**: el modelo tiene el sitio --`esElDe` y `clave`-- pero no el tipo