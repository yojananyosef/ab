# Proposal

## Why

MEDIDO EL 7 DE OCTUBRE DE 2026: un `grep` de `fontFamily` en `pubspec.yaml` y en `lib/` no
devuelve **nada**, y en el repositorio no hay ni un `.ttf`. El texto se pinta con la fuente que
traiga el sistema: Roboto en Android, la del navegador en web.

Y eso, en un lector de Biblia, no es una falta de respeto a la dislexia: es solo la **falta de
una opcion**. Hay tres cosas que se tocan en la hoja de formato --tamano, alto de linea y
espaciado-- y la fuente no estaba. Y la fuente es la que mas distingue a unas letras de otras.

## QUE SE HACE

Tres familias, y una cuarta opcion que es **no poner ninguna**:

| | |
| --- | --- |
| **La del sistema** | la que alguien ya tiene ajustada en su pantalla |
| **Literata** | con serifa, como un libro. La de Amazon Kindle |
| **Atkinson Hyperlegible** | del Braille Institute; la i, la l y el 1 no se confunden |
| **OpenDyslexic** | letra de pie pesada y base ancha: las letras no se separan |

Las tres son del repo hermano, que las llama «Tipografia de Accesibilidad Cognitiva», y las tres
son **SIL Open Font License 1.1**, que permite redistribuir. La licencia de cada una esta al
lado, en `assets/fuentes/`.

## Y POR QUE UNA CUARTA, «La del sistema»

Porque la fuente del sistema es la que alguien ya tiene ajustada con su tamano y su contraste,
y cambiarsela a quien ya esta bien es molestia. Y en un movil hay una fuente de accesibilidad
configurada en el sistema que esta app no tiene por que pisar.

## Y POR QUE GUARDAR LA **FAMILIA** Y NO UN NUMERO

Por el mismo motivo por el que un resaltado guarda un **estilo** y no un color: si alguien
marca con «amarillo» y lo reexporta, tiene que salir el amarillo que eligio quien marco. Y con
las fuentes igual: guardando el indice de una lista, al reimportar en otra version el «2» puede
ser otra cosa. Guardando la familia --«Literata»-- el fichero se entiende en cualquier sitio.

## Y LO QUE HAY QUE MIRAR ANTES DE REDISTRIBUIR

OpenDyslexic tiene **nombre de fuente reservado** en su licencia. Si alguien cambia el nombre de
la familia y la vuelve a publicar, la licencia lo prohibe. Por eso el nombre es el de verdad y
por eso esta nota esta aqui: es el unico sitio donde el cambio de nombre seria un problema legal
y no solo de estilo.
