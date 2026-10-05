# Tasks

## 1. El marco

- [x] 1.1 `MarcoDeEstudio`, con panel lateral y con barra de abajo
- [x] 1.2 A **1100 px** o mas, panel extendido con los nombres; verificado a 1100 y a 1099
- [x] 1.3 Menos de **1100 px**, sin panel lateral
- [x] 1.4 Los cinco destinos llevan a las pantallas que ya existen; verificado uno a uno
- [x] 1.5 Sin boton de volver, porque el panel **es** el camino de vuelta; verificado
- [x] 1.6 El hijo recibe exactamente lo que el panel no ocupa; verificado a 1440 y a 834
- [x] 1.7 Los destinos abajo van con icono y **sin texto**, repartidos con `spaceAround`
- [x] 1.8 Y **no** hay entradas de adorno: sin Tienda, Entrenos, Panel de Control, ni los
      cuatro que no tienen nada detras; verificado por nombre
- [x] 1.9 El marco da su propio `Material`, porque vive fuera del `Scaffold`

## 2. La cabecera del panel

- [x] 2.1 La referencia es un campo, en su propia fila; verificado
- [x] 2.2 Y **no** esta dentro de la barra: ahi le quedaban 225 px de 330; verificado
- [x] 2.3 La version es el rotulo de la pestana, de encima; verificado
- [x] 2.4 El nombre sale de la version y no de una lista a mano; verificado
- [x] 2.5 Las flechas de capitulo van en la fila del campo; verificado
- [x] 2.6 El cuerpo del texto **NO** lleva campo ni flechas; verificado
- [x] 2.7 A 360 px el campo mide **248** --360 menos 28 de margenes, 4 y 80 de flechas-- y
      a 320, **208**; verificado
- [x] 2.8 La fila **crece** con el texto de error: con 48 px fijos se salia 24; verificado
- [x] 2.9 El campo tiene **tope de 360** en pantalla ancha; estirado ocupaba 1.260 y
      parecia la pagina de busqueda; verificado
- [x] 2.10 Sin flecha de volver en la barra; verificado

## 3. El texto

- [x] 3.1 El nombre del libro sobre el texto, con el capitulo; verificado
- [x] 3.2 Es un salto al selector de libros; verificado
- [x] 3.3 El numero de capitulo antes de los versiculos, dentro de la columna; verificado
- [x] 3.4 En `headlineLarge` y no en `displaySmall`: en `displaySmall` se comia 72 px de alto,
      un 9 % de la pantalla de 360; verificado

## 4. Lo que NO se pudo, y por que

- [-] 4.1 Los enlaces azules a otros pasajes y las referencias cruzadas. El `.amod` tiene
      **dos** tablas, `info` y `verses(book, chapter, verse, text, raw)`. No hay tabla de
      referencias cruzadas, y el panel de ideas de Logos se alimenta de esa. Sin ella no se
      pueden pintar sin inventar un indice, que seria el dato de otra persona.

## 5. Lo que entra despues, y por que

- [ ] 5.1 Paneles multiples con pestanas y scroll propio — es un change de estado: hoy
      `LectorViewModel` tiene **un** pasaje, y este change deja el sitio y el cableado
- [ ] 5.2 El panel de ideas a la derecha, que sigue el scroll. Los datos **si** estan:
      el CLARKE tiene 19.742 notas. En pantalla estrecha va **en linea**, que es lo que dice
      `docs/investigacion-ux.md` linea 317
- [ ] 5.3 La segunda barra, cuando `Formato` tenga ajustes de lectura detras
- [ ] 5.4 Los numeros de versiculo en linea, al nivel del texto
- [ ] 5.5 Las palabras anadidas del traductor en cursiva, que es la convencion, y no
      subrayadas
- [ ] 5.6 Tipografia de lectura: **no existe ninguna**. Medido: Juan 3, 36 versiculos,
      ocupa **16.848 pixeles** a 360 px de ancho. Tamano de letra, alto de linea y fondo
      sensibilidad al pulgar
