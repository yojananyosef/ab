# Proposal

## Why

En `AGENTS.md` estaba escrito, con su justificacion medida, que **la palabra de Dios en
rojo no se puede pintar** en este catalogo. Escribi en `token_de_texto.dart` que "no hay
ninguna marca de habla divina en los modulos de este catalogo".

La primera mitad es cierta. **La conclusion es falsa**, y el error fue de busqueda: se
busco una marca de habla divina --`\divine`, `\god`, una lista de versiculos-- y no se
miraron las que hay.

La marca es **`\wj`**, que en USFM es el marcador de **palabras de Jesus**: el mismo que
usan las Biblias de letras rojas. Esta ahi, en 2.028 versiculos del KJV, y el parser no la
miraba porque se tomo por marca de estructura --la lista de "diez marcas" lo cuenta como
`\wj` y `\tl` de estructura—.

Medido el 5 de octubre de 2026 sobre el fichero real de 22.544.384 bytes, con el parser de
la aplicacion y no con una expresion regular:

    versiculos del KJV                     31.102
    que reciben anotaciones                30.350   (97,60 %)
    con palabras de Jesus                   2.015
    palabras de Jesus                   41.284   de 835.159   (4,94 %)
    aperturas `\wj`                       2.038
    versiculos con `\wj`                   2.028

## Y por que se llaman "de Jesus" y no "de Dios"

Porque son dos cosas y **solo una es cierta**:

| | |
| --- | --- |
| **Lo que dijo Jesus** | si, en 2.015 versiculos |
| **Lo que dijo el Dios del Antiguo Testamento** | **no, en ninguno de los 21 libros** |

Lo segundo no esta en ningun sitio de este catalogo. Y no hay de donde sacarlo: escribir a
mano una lista de versiculos en los que Dios habla es poner en pantalla el dato de otra
persona y atribuirselo al modulo, que es lo unico que este proyecto no hace.

Por eso el interruptor se llama "Palabras de Jesus en rojo" y no "Palabra de Dios".

## Y por que el dato es de fiar

Porque el marcador marca **dialogo de Cristo**, no "habla divina". La comprobacion que lo
dice son los dos capitulos de Corinto:

    1 Corintios 11:24    las palabras de Cristo citadas por Pablo
    2 Corintios 12:9    las palabras de Cristo citadas por Pablo

Un marcador que significara "dialogo" tambien los traeria. Uno que significara "habla
divina" **no**, porque Pablo no es Cristo. Y el Antiguo Testamento entero da **cero**.

Y dentro de un mismo capitulo, el marcador separa los dos lados:

    Juan 3:11    24 de 24 palabras    de Jesus
    Juan 3:16    25 de 25 palabras    de Jesus
    Juan 3:28     0 de 20             el Bautista
    Juan 3:29     0 de 32             el narrador
    Juan 3:36     0 de 28             el narrador

Si marcara el capitulo entero, o no marcara nada, esos cuatro darian el mismo resultado.

## Que es un 4,94 % del texto

De cada veinte palabras del KJV, una es de Jesus. No es una pantalla en color: en los
evangelios, la mitad aproximadamente, que es justo lo que se espera de una Biblia de letras
rojas. En el Antiguo Testamento, ninguna.

## El interruptor

De partida **puesto**, sin preguntar: es lo que espera quien abre una app de Biblia en la
que el dato esta, y una funcion escondida tras un interruptor apagado es una funcion que no
existe. Y **guardado**, porque es una preferencia y una preferencia que se pierde al
recargar hay que volver a buscar cada vez.

## Y el texto no se toca

Un lector que altera el texto que va a leer es un lector que no se puede citar. El color va
en el `TextSpan` y se quita dejando el texto exactamente igual, y por eso el interruptor se
puede tocar sin miedo.
