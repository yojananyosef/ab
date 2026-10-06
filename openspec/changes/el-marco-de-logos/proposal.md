# Proposal

## Why

El usuario ha puesto una captura de esta aplicacion al lado de una de Logos, a la misma
tarea --leer Juan 1--, y ha dicho que sigue viendose asi. Y tiene razon.

La diferencia ya no es de distribucion: el panel de herramientas existe, los cinco destinos
existen y el texto se lee. Lo que falta es **la forma en que Logos organiza el trabajo**, que
son cuatro cosas medibles:

| | Logos | `ab` al 6 de octubre de 2026 |
| --- | --- | --- |
| pestanas de panel arriba (`RVR60`, `JFB`, `+`) | si, y son el eje de la organizacion | **no existe** |
| fila de menu por panel (`Inicio`, `Busqueda`, `Notas`, `Formato`, `Vista`, ...) | si, 7 entradas | **no existe** |
| segunda barra (`Contenido`, `Historia`, `Articulo`, `Conjunto de enlaces`, ...) | si, 7 entradas | **no existe** |
| notas al pie con letra en el texto y su lista al final | si | **no existe, y el texto las lleva pegadas** |

Y una quinta, que no es de la interfaz sino del **dato**, y es la mas grave:

**LAS NOTAS AL PIE SE ESTAN PINTANDO COMO SI FUERAN ESCRITURA.** Medido hoy sobre el
`KJV2006_bible.amod` real (22.544.384 bytes, 31.102 versiculos):

    versiculos con \f                     5.844   (18,79 %)
    notas al pie en total                 6.959
    capitulos con notas                     913
    notas por capitulo: media              7,6   maximo 35 (Daniel 11)
    notas cuya ancla cae dentro del versiculo  6.956 de 6.959

Y la columna `text` las trae **pegadas al final**, en orden, con su referencia delante. Un
versiculo real:

    1Cronicas 1:6
    text: And the sons of Gomer; Ashchenaz, and Riphath, and Togarmah. 1.6 Riphath: or,
          Diphath as it is in some copies
    raw:  And the \w sons|strong="H1121"\w* ... Togarmah|strong="H8425"\w*.
          \f + \fr 1.6 \ft Riphath: or, Diphath as it is in some copies\f*

Lo que se pinta hoy en la pantalla de lectura es **todo**, la nota incluida, en el mismo
cuerpo y con el mismo color que la Palabra. Lo unico que se ha medido y no se ha resuelto es
el numero: **`\x`, las referencias cruzadas, sale CERO veces**, asi que los enlaces azules
de Logos no existen en este modulo. Y los **epigrafes** tampoco: `\s1` sale 35 veces y las
35 son la suscripcion final de las epistolas, ningun titulo de seccion.

## Que se copia, y que no, y por que

**SE COPIA, y es lo que este change hace:**

- **Pestanas de panel.** Logos organiza por pestanas, no por pantallas. Es el cambio de
  estado que `el-marco-de-estudio` dejo medido y sin hacer (tarea 5.1).
- **La fila de menu por panel** (`Inicio`, `Busqueda`, `Notas`, `Formato`, `Vista`,
  `Herramientas`, `Compartir`) y **la segunda barra** (`Contenido`, `Historia`,
  `Articulo`, `Conjunto de enlaces`, `Mas informacion`, `Informacion`).
- **Las notas al pie**, que son lo que el modulo trae y lo que hoy se pinta como Escritura.

**NO SE COPIA, y el motivo esta medido, no es una opinion:**

- **Los enlaces azules a otros pasajes.** `\x` sale **0** de 31.102. No hay tabla de
  referencias cruzadas. Pintarlos seria escribir el indice de otro.
- **Los epigrafes de seccion.** `\s1` sale 35 veces y las 35 son la suscripcion de las
  epistolas. Un modulo con titulos de seccion los traeria; este no los tiene.
- **Tienda, Entrenos y el Panel de Control.** Compra, suscripcion y cuenta. Decidido.

## Y QUE HACE FALTA EN `aa`

Tres cosas, y son del repositorio hermano, no de este:

1. **Un modulo con referencias cruzadas** (`\x`), si se quiere el panel de ideas con enlaces.
2. **Un modulo con epigrafes** (`\s1` de seccion), si se quiere "El Verbo hecho carne" sobre
   Juan 1.
3. **Mas versiones en castellano.** Hoy el catalogo tiene KJV2006 y CLARKE, los dos en
   ingles. Comparar versiones --que es la interaccion mas valiosa de la categoria-- no se
   puede enseñar con una sola Biblia.

## FUERA DE ALCANCE

- **iOS.** No se planifica.
- **Android, Linux y Windows.** No hay SDK ni GTK en esta maquina; lo que se escriba se
  comprueba solo en Dart. Lo unico verificado en navegador es lo que toca web.
- **La tienda de recursos, las cuentas y la nube de Logos.** No hay cuentas, no hay
  compras, no hay anuncios.

## COMO SE COMPRUEBA

- `flutter analyze` y `flutter test`, con `bash scripts/preparar-fixtures.sh` antes.
- **A 360 px y a 1440 px**, porque el corte del marco esta en 1.100 px y las dos barras
  nuevas se tienen que comportarse distinto a cada lado.
- **`scripts/viz/capturar.mjs`**, y la captura **al lado** de la de Logos. Un cambio de este
  que solo se comprueba con `flutter test` no esta comprobado: el fallo que motivo este
  change --las notas al pie pintadas como Escritura-- es invisible en Dart.