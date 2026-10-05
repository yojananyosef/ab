# Proposal

## Why

Por primera vez se ha podido **mirar** la aplicacion, con capturas de verdad
(`scripts/capturar.mjs`, Playwright). Todo lo anterior se decidio leyendo el codigo y
probando con `flutter test`, y las dos cosas no ven la mitad de los fallos de una interfaz.

Medido en una captura de la pantalla de lectura a 360 px, con Juan 3:16 abierto en el KJV y
el modulo entero ya descargado:

    barra de arriba                              56 px
    campo "Ir a" + boton "Buscar" de 48 px      164 px
    titulo del capitulo, que repetia la barra   40 px
    --------------------------------------------------------
    cromo antes del primer versiculo            260 px
    el versiculo, que era TODO el texto          122 px
    los terminos del modulo                      268 px

**De 760 px de alto, el versiculo era el 16 % y los terminos el 35 %.**

## Y la causa no era el diseno: era el dato

`Juan 3:16` traia **un versiculo**, porque la consulta filtraba con `verse = ?`. Un lector
de Biblia que al abrir un versiculo ensena un versiculo y tres lineas de terminos no esta
ensenando la Biblia. Rediseñar la pantalla sin arreglar eso habria sido pintar de nicer un
problema de alcance.

Y lo que dicen los tres que se copian, de `docs/investigacion-ux.md`:

- **YouVersion**: la URL canonica por pasaje "que ademas **selecciona** el primer versiculo
  del rango al abrirse". Selecciona, no acota.
- **MyBible**: "it allows you to put any place of a book into the center of your screen and
  study it in its immediate context". Su contexto inmediato es el capitulo.
- **Accordance**: la ambiguedad de versificacion "se muestra, no se tapa", resolviendola
  "mostrando los paneles en paralelo en vez de dejar un numero en blanco". Un versiculo
  suelto no deja ver nada de eso.

## Los dos fallos que salieron mirando, y no leyendo

**1. El nombre de la version no salia nunca en la cabecera.** El enrutador escuchaba a la
biblioteca **solo** para saber si podia abrir el comentario y **nunca llamaba a
`notifyListeners()`**. La pantalla se quedaba con la lista de versiones que tenia al
construirse --vacia-- para siempre. Se espero 20 s en un navegador de verdad: no era tiempo.

Y **ninguna comprobacion lo veia**: el nombre de la version es texto de la barra, la sonda
del navegador lee el **pasaje**, y `flutter test` montaba la pantalla con la lista ya puesta
a mano. Las dos dan verde con el bug puesto.

**2. El boton de "Ir" estaba debajo del campo por un motivo medido mal.** El argumento era
que en fila el boton se quedaba con la mitad del ancho y "el texto se corta a los 12
caracteres". Es cierto, y la causa no era la fila: era que el boton de abajo ocupaba 48 px
de alto y el campo entero. Con el boton **dentro**, como icono de sufijo, el campo toma la
columna y "Juan 3:16" entra de sobra. Ademas eran **62 px** de los 760 --un 8 %-- para un
control deshabilitado el 99 % del tiempo.

## Y lo que queda mal, y se ve en la imagen

- Los **terminos del modulo** son el 35 % de la pantalla si el pasaje es corto. Ahora el
  pasaje es el capitulo, con lo que pasan a ser una nota al pie proporcionada, pero siguen
  siendo la parte mas larga de la pantalla.
- En los evangelios, las paginas de **dialogo son casi todas rojas**. Es correcto segun la
  marca `\\wj` --Juan 3 del 16 al 21 son palabras de Jesus-- y hay un interruptor, pero es un
  hecho de la fuente y hay que staringlo.
- La **biblioteca** gasta tres controles por modulo --"Disponible", "Descargar" y "Fichero
  local"-- donde uno basta, y cada modulo ocupa una pantalla entera.
