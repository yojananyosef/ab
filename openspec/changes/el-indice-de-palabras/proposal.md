# Proposal

## Why

El change anterior guardo el numero del lexicon de cada palabra --`Dios` es `G2316`-- y se
quedo ahi, guardado y invisible. Es exactamente la clase de dato que esta a medio camino:
esta en el fichero, es util, y no se puede llegar a el.

Con esto se llega **pulsando la palabra en el versiculo**, y sale: en que versiculos del
texto abierto sale, con que escrituras, y cuantas veces.

## Y lo que este change NO hace, y es lo importante

NO ES UN DICCIONARIO. No dice que significa `G2316`.

Y no es prudencia: es que el dato **no esta**. Medido el 5 de octubre de 2026 sobre el KJV
publicado: el `.amod` tiene dos tablas, `info` y `verses`, y las trece claves de `info` son

    id, name, language, license, license_evidence, copyright, attribution,
    origin, source, schema_version, type, versification, defects, defects_count

**Ninguna de lexicon.** El significado de `G2316` esta en un diccionario del griego, y ese
diccionario no lo trae este catalogo ni ningun otro de los dos repositorios.

Escribir los significados a mano seria poner en pantalla la opinion de quien los escribio, en
una aplicacion cuyo primer requisito es no alterar lo que lee. Y quien busca el significado
de una palabra es que tiene un diccionario, y entonces no lo necesita aqui.

Por eso la pantalla **dice que no es un diccionario**, arriba, antes de la lista. Con una
lista de 200 lineas en medio, un aviso al final no se ve nunca.

## Lo que si sale del modulo, y es real

Medido el 5 de octubre de 2026:

    numeros distintos en el KJV          14.047
    ocurrencias totales                 348.884
    G2316  en   1.171 versiculos, 1.359 veces
    H3068  en   5.519
    G2532  en   9.092
    contar un numero                      15 ms
    listar 200 filas                        2 ms

Y las escrituras: en el KJV `G2316` sale con `God`, `gods`, `godly` y `God` otra vez. Cuatro
palabras que un usuario que ha pulsado `God` quiere saber antes de mirar 1.171 versiculos.

## Un numero de indice sin lexicon es un indice de otra cosa

El recuento es de **versiculos**, no de ocurrencias: Juan 3:16 tiene `Dios` una vez y Mateo
1:23 tres, y la lista que se pinta es de versiculos. `G2316` sale en **1.171 versiculos** y
**1.359 veces**, y son dos numeros distintos. Confundirlos haria que el indice prometiese una
lista mas corta de lo que es.
