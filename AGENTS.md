# AGENTS.md

Instrucciones para quien trabaje en este repositorio, empezando por un agente
autonomo.

---

## 1. Que es `ab` y que no es

`ab` es una **aplicacion lectora**. Su unico trabajo es descargar modulos de un
catalogo y dejar leerlos bien, en cualquier pantalla.

`ab` **no construye, no valida, no licencia y no publica recursos**. De eso se
ocupa el repositorio hermano, `aa`. Aqui no hay ni una linea de eso.

La frontera es una API, no una carpeta: `ab` consume `catalog.json` y ficheros
`.amod` como un cliente consume cualquier otra API. Si `ab` necesita saber
**como** se construyo un modulo, la frontera esta mal puesta.

Lo que si es de la app:

- Descargar un `.amod` y comprobar que su hash cuadra. Eso lo hace el cliente,
  siempre.
- Leer un modulo con SQL.
- Elegir, buscar, marcar, anotar, sincronizar.

Lo que **no** es de la app:

- Decidir si una Biblia es de dominio publico.
- Construir un `.amod`.
- Publicar un recurso.
- Saber de antemano que Biblias existen.

Si la app contiene una lista de textos, es porque alguien cruzo la frontera.
La lista de textos vive en el `catalog.json`, que la app lee.

## 2. Plataforma, en este orden

1. **Web**, primero. Es donde llega la gente que no instala nada.
2. **Android**, segundo.
3. **Linux y Windows**, tercero.
4. **iOS**, despues. No se planifica y ningun change puede depender de que
   exista.

**El SDK es Flutter 3.47.6, y se comprueba antes de fiarse de nada.** Comprobado
con `flutter --version` el 4 de octubre de 2026. Si cambia la version, hay que
volver a mirar lo que este documentado aqui: `--headless=new`, el
`RouteInformationReportingType`, el `RouteInformationProvider` y el
`loadFromUrlString` de `package:sqlite3` son cosas que se han mirado **en esa
version**, y en otra pueden estar distintas.

**Lo que NO esta verificado, y no se finge lo contrario:**

| | Por que |
| --- | --- |
| **Android** | no hay SDK de Android en esta maquina |
| **Linux y Windows** | no hay GTK, ni una maquina con Windows |

De las tres no se ha ejecutado **nada**. Todo el codigo de esas plataformas --
el almacenamiento de modulos, el selector de archivos, la apertura del `.amod` por
`ffi`-- esta escrito y compartido, pero **comprobado solo en Dart**. Y hay al
menos un fallo en el que un test de Dart no puede encontrar: las rutas del VFS
en memoria tienen que ser absolutas, y eso solo se rompe en el VFS de WebAssembly.

Y EN WEB SI ESTA VERIFICADO, con navegador de verdad:
`scripts/comprobar-en-navegador.sh`.

**Mobile-first y responsive en todas partes.** En web, "responsive" incluye
que funcione dentro del navegador del telefono: sin barra de direcciones, sin
barra de sistema, con el teclado tapando media pantalla. **Web no es la version
de escritorio en una ventana pequena.**

Un widget que revienta a 360 px no esta terminado, por muy bonito que sea a
1440 px.

## 3. Arquitectura

Capas estrictas, sin mezcla. La UI no lee ficheros ni escribe SQL.

```
lib/
├── data/
│   ├── models/         # modelos de API
│   ├── repositories/   #Repositories: devuelven modelos de dominio
│   └── services/       # clientes HTTP, SQLite, almacenamiento
├── domain/
│   ├── models/         # modelos de dominio, inmutables
│   └── use_cases/      # logica compartida
└── ui/
    ├── core/           # widgets compartidos, temas, tipografia
    └── features/
        └── [feature]/
            ├── view_models/
            └── views/
```

El skill `flutter-apply-architecture-best-practices` es la referencia y su
estructura es la del proyecto. MVVM con `ChangeNotifier` y vistas delgadas:
la View pide datos a su ViewModel y pinta lo que le dan.

Una vista con `if (sqlite.query(...))` dentro es un bug de arquitectura aunque
funcione.

## 4. Reglas que no se negocian

### Nada de logica del catalogo

Ni gate de licencia, ni construccion, ni publicacion. Descargar y comprobar
integridad si es de la app. Construir y decidir si algo es publicable, no.

### Sin compras dentro de la app, jamas

Ni modulo de pago, ni suscripcion, ni "version completa", ni "desbloquea el
comentario". La app es gratuita y completa o el proyecto esta mal.

La investigacion de mercado es clara en esto: lo que la gente odia de las apps
gratuitas es exactamente el cupo de cobro. Si alguna vez aparece un paywall,
no es una decision que se haya tomado: es un fallo.

### Sin publicidad

Un anuncio en un lector de Biblia es un anuncio al lado de la Palabra. Ademas,
la queja numero uno y mas repetida de los usuarios de pago de las apps que lo
hacen: han pagado y les aparece un banner.

### Un rango comprimido no es un rango

Medido contra `yojananyosef.github.io` el 3 de octubre de 2026, pidiendo 4 MiB de
`KJV2006_bible.amod`:

    pedida bytes=0-4194303        ->  206 con 20.766.289 bytes
                                     content-range: bytes 0-4194303/4562858
    pedida bytes=20766289-22544383 -> 416

Los dos numeros son **de dos ficheros distintos**. El cliente HTTP pide `gzip` por
su cuenta, el servidor contesta el rango comprimido y el cliente lo descomprime
antes de que nadie lo mire: el cuerpo llega con el tamano del fichero real y el
`Content-Range` con el del comprimido. El siguiente rango se calcula con el
primero y se sale del fichero.

Por eso `HttpService.rango` manda `Accept-Encoding: identity`. No es una
optimizacion, y no es que un `.amod` comprimible: es que **no se puede pedir un
rango de una representacion comprimida**, porque los limites no significan lo
mismo. Sin esa linea la descarga se declara incompleta cuando el servidor ha
contestado perfectamente.

Este fallo no lo encuentra ninguna prueba contra un servidor de pruebas, porque un
`HttpServer` de `dart:io` no comprime nada salvo que se lo pidas. Lo encuentra la
prueba de `test/red/`, y esa es la razon de que exista.

### La memoria residente mide basura, no memoria viva

Medido el mismo dia, bajando el KJV real de 21,5 MiB, con tres formas de
acumular los trozos:

| Como | Pico de RSS |
| --- | --- |
| `[...acumulado, ...trozo]` | **+1242,8 MiB** |
| `BytesBuilder(copy: false)` | +43,3 MiB |
| `Uint8List(total)` reservado | +51,8 MiB |

Dos cosas que hay que saber de esta tabla:

1. La primera encaja **cada byte en un puntero** y ademas copia el acumulado en
   cada trozo. 55 veces el modulo, y con el comentario de 57 MB serian mas de
   3 GiB. En un movil de gama baja eso es lo que hace que el sistema mate el
   proceso, sin dar ningun error.

2. **Las dos ultimas dan numeros que no distinguen nada**, porque la diferencia
   entre 43 y 52 MiB esta dentro del ruido del recolector. En dos ejecuciones
   distintas la version con `Uint8List` dio +51,8 y +9,9 MiB. RSS **no mide
   memoria viva**: incluye la basura que el recolector todavia no se ha llevado.

Por eso la prueba de 4.2 pone el umbral en cuatro veces el modulo y **dice en el
propio comentario que no demuestra que no haya dos copias en memoria**. Lo que si
hace es cazar el fallo catastrofico, con un margen de veinticuatro veces. Y la
comprobacion exacta de por que la eleccion es la buena --una reserva exacta, sin
crecidas y sin copia final-- es estructural, y se comprueba de otra manera.

### Una prueba que declara el hash de lo que ella misma sirve no comprueba nada

Esta se pago al escribir las pruebas del catalogo, y es la clase de error que
mas caro sale en las pruebas, porque **dan verde**.

Lo que se habia hecho: un servidor de pruebas que servia un `latest.json` cuyo
`catalogSha256` se calculaba con el manifiesto que el propio servidor estaba
sirviendo. Con eso, el hash **siempre cuadra**, y la prueba de "que pasa si el
manifiesto esta alterado" pasaba sin comprobar nada. Verde y vacia.

La separacion que hace falta:

| | Que es |
| --- | --- |
| **lo que se sirve** | el manifiesto que llega al repositorio |
| **lo que declara el indice** | el manifiesto **bueno**, cuyo hash se anuncia |

Alterar uno y dejar el otro quieto es lo que produce el caso que hay que cazar.
Y un `latest.json` de pruebas tiene que traer `browserUrl` **apuntando al
servidor de pruebas**, porque el de verdad trae URLs absolutas a otro sitio y
entonces la prueba se descarga el manifiesto de verdad y no ve ningun cambio.

### El `.amod` no lleva `minReaderVersion`

Medido sobre el KJV real: su tabla `info` tiene **15 claves**, y `minReaderVersion`
no esta entre ellas. Las dos versiones de compatibilidad estan en sitios
distintos:

| Campo | Donde vive | Que es |
| --- | --- | --- |
| `schema_version` | tabla `info` del `.amod` | como esta escrito el fichero |
| `minReaderVersion` | `catalog.json` | que version de la app lo entiende |

La razon de que sea asi tiene sentido: `minReaderVersion` es una declaracion
sobre el **cliente**, y el modulo no sabe nada del cliente. El que lo publica si.

Consecuencia practica: para comprobar compatibilidad hay que mirar en los dos
sitios, y un `null` en el segundo no es un fallo de lectura, es que la
informacion no esta ahi. Hay una prueba que comprueba precisamente eso: que el
modulo **no** tiene el campo, para que si alguien anade el campo al formato y
empieza a leerlo de ahi, salte en vez de dar un null en silencio.

### Los terminos del modulo se ensenan, no se esconden

Cada `.amod` declara en su tabla `info` su `copyright`, su `attribution`, su
`license`, su `license_evidence`, sus `defects` y su `content_hash`. La app los
muestra **antes de dejar leer**, en la propia pantalla de lectura y sin abrir
ningun menu.

No es cortesia. YouVersion, que tiene los terminos de cada traduccion en su
base, los renderiza junto al pasaje porque la atribucion **es una obligacion de
la licencia**, no un adorno. Y aqui hay un caso que obliga mas: un modulo puede
declarar `defects_count` mayor que 0 cuando la fuente no traia algunos
versiculos. Un lector que no lo dice esta ensenando texto incompleto sin
avisar, y quien lo esta leyendo no tiene forma de saberlo.

La informacion se toma del **modulo**, no del manifiesto. El manifiesto es un
puntero: cuando los dos discrepan, gana el modulo, que es el texto que se esta
leyendo, y se dice que discrepan.

### Los numeros salen del modulo

La app no trae ninguna tabla de capitulos ni de versiculos por libro. Se leen
del modulo abierto, con una consulta.

El motivo esta medido en el repositorio hermano: su tabla de libros se escribio
primero de memoria y **21 de 66 libros tenia un numero de versiculos
equivocado**. Repetir eso en la app seria el mismo fallo con otro nombre. La
comprobacion es concreta: Genesis ofrece 50 capitulos, y un 51 es exactamente el
error.

### Un modulo con formato desconocido no se abre

Si la `schema_version` o el `minReaderVersion` de un modulo excede lo que la app
soporta, **no se abre**, y el error dice las dos versiones. Abrir un formato que
no se entiende produce texto equivocado con toda la pinta de texto bueno, que es
peor que negarse a leer.

### Sin telemetria por defecto

Nada de analisis de uso, nada de identificadores. Si alguna vez hace falta, es
un change explicito que lo pide y explica por que.

### Perder datos del usuario es el peor fallo posible

Notas, marcados y resaltados son trabajo de la persona, no un estado
descartable.

Esto no es hipotetico. Al investigar Accordance se encontro esto en las
resenas de iOS, textuales:

> *"I have lost all of my highlighted verses on the desktop app... The notes on
> my iPhone app are all messed up."*

> *"Sync has been broken for MONTHS... I currently cannot sync notes or
> highlights between devices."*

Causa: la version 14.1 **quito la sincronizacion con Dropbox sin sustituto
listo**, y dos anos despues la sincronizacion sigue siendoBeta y sigue
fallando. Ese es el hueco que `ab` no puede tener.

Si un cambio arriesga perder un resaltado, el cambio esta mal, aunque ahorre
200 lineas. Un cache que se limpia solo no puede tocar lo que el usuario
escribio.

### Interfaz en castellano

Es codigo abierto. Las traducciones se donaran despues y no se mezclan con el
codigo.

## 5. Lo que ya sabemos, para no repetirlo

Viene de la investigacion de UX hecha al empezar el proyecto. Esta en
`docs/investigacion-ux.md`; lo esencial:

### Lo que hay que copiar

**El sistema de resaltados de Accordance.** Cinco cosas en una sola funcion:

1. Estilos definidos por el usuario: color, intensidad, forma y **patron** (por
   ejemplo "subrayado punteado con borde rojo vivo").
2. **Varios ficheros de resaltados** intercambiables de un clic: un conjunto
   "temas teologicos", otro "devocion personal", otro "preparacion de clase".
   El mismo versiculo puede estar marcado de tres maneras sin ensuciarse.
3. Los resaltados son **por referencia, no por version**: se marca en una
   traduccion y aparece en todas las demas.
4. Los resaltados son **buscables**: buscar por estilo devuelve todos los
   versiculos marcados asi. Es un indice tematico personal hecho a mano.
5. Totalmente reversibles.

Cuesta muy poco de implementar y ninguna app gratuita se acerca.

**El panel de ideas de Logos**: un trozo de comentario que vive DENTRO del
panel de la Biblia y se actualiza con el scroll. Cero coste de navegacion. Es lo
que un lector de movil quiere primero.

**Los tres niveles de interaccion con el texto de Accordance**: un toque da la
definicion, dos toques abren un selector de herramienta, "Live Click" busca en
toda la biblioteca. Revelacion progresiva en tres pasos, y el tercero sigue
siendo opcional.

**El autocompletado de Accordance en todo el lenguaje de busqueda**: el menu
te va diciendo que comandos existen mientras escribes. Los expertos tienen linea
de comandos; el resto tiene un menu. Nadie mas hace las dos cosas.

**El escaner de referencias de Logos**: la camara ve "Juan 3:16" en una pagina
impresa y la convierte en una lista de passages. Nadie mas lo tiene.

**Los limites de capacidad por plataforma de Logos**: los mapas de sus
comentariosGesture los califican explicitamente "(no para movil)". Declarar lo
que no funciona en movil es honesto y evita el enfado.

### Lo que hay que evitar

**La app de Logos para Android lleva anuncios.** En la ficha de Google Play
pone "Contains ads". Y esto, textual de una resena de un cliente que lleva
gastados cientos de dolares:

> *"As much money as I've spent on this software, I am riddled with ads and they
> just made it so that you can't turn them off. My dashboard is unusable now
> because there are so many ads."*

De ahi la regla de sin publicidad: no es una preferencia, es la queja
documentada de quien ya pago.

**Logos destroza la biblioteca en cada rediseno.** Es la queja mas repetida,
con obtener una estrella:

> *"Logos mobile update to v53 is a step in the wrong direction... now it is
> direct access to the store."*

> *"The new UI is complete garbage. It seems like every new UI overhaul is worse
> than the previous."*

> *"Hate is not a strong enough word for this update... I accidentally clicked
> on an AI search tool and now I cannot even find my library on my iPad."*

De ahi una regla: **el orden de las pantallas y los gestos sehzon congelado.**
Un lector de Biblia es algo que se usa todos los dias durante anos. Cambiar
donde estaba la biblioteca cada tres meses es una traicion a ese uso.

**La IA desplazando a la busqueda determinista.** En Logos, la busqueda
inteligente paso a ser el sitio por defecto y la busqueda precisa quedo
escondida:

> *"The AI addition interferes with word searches and, for the mobile edition,
> eliminated the tabs which made book selection simple."*

La IA puede **anadirse**. No puede quitar lo que habia ni ponerse delante.

**La matriz de precios de Logos**: 8 niveles de biblioteca x 4 trayectorias x
11 denominaciones x ano de edicion. Un reviewer que los promociona escribe
*"Their offerings look too complicated."* Si `ab` llega a tener monetizacion,
eso esta probado y sale caro.

**Los tramos largos sin actualizar.** Entre la version 14 de Accordance (noviembre
de 2022) y la 14.1 (septiembre de 2025) hay tres anos. La ficha de la app
avisa a los usuarios que **no actualicen el sistema operativo** hasta que salga
la 14.2. Una app de lectura que va tres anos sin actualizarse pierde a la
gente.

**El fallo de recuperacion de cuenta**. En las resenas de Accordance, varias de
una estrella, todas sobre lo mismo: no se puede crear la cuenta, el boton de
ayuda lleva a un foro y no hay forma de cambiar la contrasena. Es el fallo mas
barato de arreglar y el mas vergonzoso posible. En una app sin cuentas ni
suscripcion, esto no puede ocurrir por construccion: es una ventaja.

### Las pruebas usan modulos reales, y hay que bajarlos antes

Antes de `flutter test`:

```bash
bash scripts/preparar-fixtures.sh
```

Cuatro ficheros de pruebas necesitan un `.amod` de verdad, de 22.544.384 y
57.536.512 bytes. **No se versionan**, y no es por tamano: es porque fijarlos a una
version haria que las pruebas comprobaran un `.amod` viejo en vez de lo que se
publica hoy.

El script los baja del sitio publicado y **comprueba el sha256 de cada uno contra
el manifiesto antes de dejarlo**, dos veces: una contra lo que declara el
manifiesto y otra contra una constante escrita en el propio script. Con dos
comparaciones, un manifiesto alterado que se llevase bien un fichero nuestro
tampoco pasa.

Y si no estan, las pruebas **fallan**, no se saltan. El mensaje dice que script
ejecutar. Una prueba que se salta no verifica nada, y una suite donde media parte
se salta es una suite que da verde sin comprobar.

Esto no fue improvisado: se escribio con una ruta `/home/j/aa/modules/build/...`
en cuatro ficheros de pruebas, que aqui existe y en un runner de GitHub Actions no.
Los cuatro despliegues siguientes fallaron con un error que no decia nada de su
causa. Por eso ahora hay **un solo sitio** con la ruta y el hash, que es
`test/support/fixtures.dart`, y ninguna prueba lleva una ruta escrita.

### El CI hace lo mismo que tu, en el mismo orden

`analyze` -> bajar fixtures -> `flutter test` -> pruebas contra el sitio real ->
build web -> comprobar el motor -> desplegar. Si el CI se pone rojo, se puede
reproducir entero en local con la misma secuencia.

Un detalle que parece pequeno y no lo es: **el paso de pruebas contra el sitio real
va aparte** de `flutter test`. No son hermeticas, y mezcladas harian que un fallo de
Internet tirase el despliegue entero. Se lanzan con `--tags red --run-skipped`: las
dos banderas hacen falta porque el `skip` de `dart_test.yaml` manda siempre.

### El catalogo se ve aunque el almacenamiento no conteste

Medido en Chrome 154 headless el 4 de octubre de 2026, en la web ya desplegada:

    fetch https://yojananyosef.github.io/aa/latest.json  ->  HTTP 200, tag v0.1.1
    indexedDB.open('ab', 1)                             ->  nunca resuelve

Ni `onsuccess`, ni `onerror`, ni `onblocked`. Nada. Se queda esperando para siempre.

Y el efecto era el peor posible: la biblioteca **vacia** con el texto "El catalogo no
declara ningun modulo todavia", que era mentira. El catalogo declara dos. Lo que no
contestaba era el almacenamiento del navegador, y el aviso **no salia**, porque el
`await` del almacenamiento estaba antes de aplicar el resultado en pantalla. O sea
que la app no fallaba: fallaba **mintiendo**, en silencio, con un texto que parecia
el correcto.

Es el modo de fallo de MyBible en otro traje, y por eso hay tres reglas:

| | |
| --- | --- |
| **El catalogo primero** | es lo unico necesario para ensenar la lista, y no tiene nada que ver con el almacenamiento |
| **El almacenamiento con plazo** | cinco segundos. Un `await` sin plazo sobre un evento que no llega cuelga la pantalla **entera** |
| **Lo que no se pudo saber, se dice** | y nunca la conclusion de "no hay nada" a partir de un fallo |

Las tres viven en `lib/app/arranque.dart`, que es un fichero y no tres lineas de
`main.dart` **porque tiene una garantia que hay que poder comprobar**. Y esa garantia
tiene 17 pruebas, con un doble que se queda colgado exactamente como el navegador.

Dos cosas mas que salieron de arreglarlo:

- **`aplicarResultado` reemplaza la lista de avisos.** Poner los avisos del motor
  antes de aplicarlo los hacia desaparecer, y el de "el motor no ha arrancado" es el
  mas importante de todos. Se vio mirando la pantalla, no leyendo el codigo.
- **Los hashes y los ids van al mismo sitio y fallan a la vez.** Si el navegador no
  contesta a `ids`, no va a contestar a `idsConHash`: preguntar dos veces es pedir el
  mismo fallo dos veces y ensenar dos avisos donde bastaba uno.

Y una regla que se dedujo al escribir las pruebas: **"tengo los hashes" no es que la
llamada haya funcionado, es que cubren a los modulos que hay.** Un indice vacio con un
modulo descargado quiere decir que el indice se perdio, no que no haya nada que mirar.
Y eso ocurre de verdad: el indice se escribe al guardar, y un modulo escrito por una
version anterior no lo tiene.

### Un modulo no es una Biblia porque lo diga la app

Medido el 4 de octubre de 2026 con los dos `.amod` reales:

    KJV2006   info.type = 'bible'       tablas: ['info', 'verses']
    CLARKE    info.type = 'commentary'   tablas: ['info', 'commentary']

Y la app hacia `SELECT count(*) FROM verses` de **todo** lo que se descargaba, con lo
que al abrir el comentario reventaba con:

    SqliteException(1): while preparing statement, no such table: verses

El modulo se descargaba entero, se guardaba bien y era **imposible de abrir**. Y no lo
detectaba ninguna de las 338 pruebas, porque todas las que abren un modulo usan el KJV.

Tres reglas:

- **El tipo de contenido lo declara el modulo**, en `info.type`. No lo deduce la app de
  que tablas encuentra: `sqlite_master` es la **implementacion** del fichero, y si
  manana un comentario guardara tambien referencias en `verses` la comprobacion dejaria
  de pasar sin que nadie hubiera cambiado nada.
- **Un modulo con un tipo que no se conoce no se supone una Biblia.** Es el enum
  `TipoDeContenido.desconocido`, y `abrir` no lo deja pasar. Un `switch` al que le
  falta un caso inventa siempre "es una Biblia", y esa suposicion es el crash.
- **Una peticion que no tiene sentido no devuelve una lista vacia, lanza.** Una lista
  vacia se confunde con "este modulo no tiene ese capitulo", que es una informacion y no
  un fallo: pinta una pantalla en blanco y dice que el texto no esta ahi.

### Un aviso no es un error, y un progreso no es un aviso

Medido el 4 de octubre de 2026. La biblioteca era un `Column` de cajas, una por aviso,
encima de la lista, y los avisos eran `List<String>`. Consecuencias, todas medidas:

| | Que pasaba |
| --- | --- |
| Todo en rojo | un `String` no sabe si es un error, asi que **el progreso tambien salia como error** |
| Veinte lineas | un modulo de 57 MiB a trozos de 4 MiB da diez tramos, y **cada uno anadia un aviso** que no se quitaba nunca |
| Ni un modulo en pantalla | veinte cajas de texto se comen la pantalla entera, y los avisos van **encima** de la lista |

Y lo peor: al terminar la descarga seguia diciendo "Bajando CLARKE: 90 por ciento".

Tres reglas:

- **Un tipo de aviso, no un `String`.** Un `bool esError` devuelve el mismo fallo: el
  progreso tambien es un `esError: false`, y entonces comparte caja, color y ciclo de
  vida con lo que no es un error.
- **Un progreso se reemplaza a si mismo, y necesita una clave.** La clave es
  `progreso:$id`: dos mensajes con la misma clave son el mismo mensaje en dos momentos.
  Y el `finally` de la descarga lo quita **siempre**, porque hay siete finales posibles
  y con `finally` no se puede olvidar en uno.
- **La banda de avisos tiene un tope de ALTURA con scroll propio**, no un tope de lineas:
  un aviso de tres lineas y uno de una ocupan distinto, y a 360 px la diferencia entre
  "caben cuatro" y "caben uno" es la diferencia entre ver la lista y no verla.

### Una sonda que se traga sus errores no es una sonda

Medido el 4 de octubre de 2026. La sonda paso a mandar `List<Aviso>` --que es lo
correcto, porque los avisos tienen tipo-- y `jsonEncode` **lanza** con un objeto dentro
en vez de escribirlo. La excepcion salio de `escribir`, se subio por la cadena y, como
quien llama esta en un `addPostFrameCallback` y no hay nadie que la coja, se perdio.

Lo que se vio desde fuera: la app **funcionaba**, Juan 3:16 se leia en la pantalla del
navegador, la descarga iba bien... y la sonda no escribia nada. El script dijo "la sonda
no ha escrito nada en 900 s", que parece un fallo de la comprobacion y era un fallo de
la sonda.

Y **"no ha comprobado nada" y "no ha dicho nada" se ven igual desde fuera**. Una
comprobacion que se traga sus errores es peor que no tenerla, porque ocupa el hueco de
una que funciona.

Dos reglas, y hacen falta las dos:

- **Al informe no se mete nada que `jsonEncode` no sepa escribir.** Los avisos viajan
  como `List<String>`, no como `List<Aviso>`.
- **`escribir` no lanza nunca.** Si aun asi falla, escribe un informe que diga que ha
  fallado y por que. Un `try` que devuelve un informe vacio sigue mintiendo.

### La barra y el cuerpo tienen que caer en la misma columna

Medido el 4 de octubre de 2026 a 1900 px de ancho: el contenido se centraba en una
columna de 560 --la lista, los filtros-- y el titulo se quedaba en la esquina de la
ventana, a 1345 pixeles de lo que titula. Parece una pantalla hecha de dos.

Y el margen de la fila estaba escrito a `14` mientras el del filtro salia de
`Medidas.margenPara`, que da `24` en pantallas anchas: diez pixeles de desfase entre el
campo de busqueda y lo que filtra. Se ve mas a 1440 que a 360, y por eso solo se nota
mirando la ancha.

Dos reglas:

- **El margen sale de `Medidas.margenPara`, siempre.** Un `14` escrito en un sitio y un
  `margenPara` en otro son dos medidas que divergen en cuanto alguien cambia una.
- **El `AppBar` no alinea su `title` con el cuerpo**, y no hay `titleSpacing` que lo
  arregle. La unica forma de que las dos cosas caigan donde deben es poner **el mismo
  `ContenidoCentrado` en los dos sitios**, y pegar el texto a la izquierda **dentro** de
  el --con un `Align` hijo, no con una opcion del `ContenidoCentrado`: asi se mueve el
  texto y no la columna.

### En web, cuatro cosas que funcionan en Dart y no en un navegador

Medido el 4 de octubre de 2026, con Brave 154 en headless, montando la comprobacion en
navegador del grupo 8. Los cuatro fallos estaban en el camino **normal** --la biblioteca,
un enlace profundo, descargar y leer-- y ninguno se podría ver en una prueba. Por eso
esta seccion existe.

Ninguno se hubiera visto con `flutter test`. Los cuatro son de `package:sqlite3`, de
`package:web` y de como resuelve un navegador las rutas, y las tres cosas funcionan
igual en la maquina de Dart.

| | Que pasaba | Por que |
| --- | --- | --- |
| 1 | Con un enlace profundo, el navegador pedia `GET /leer/KJV2006/sqlite3.wasm` y contestaba 404 | `WasmSqlite3.loadFromUrlString` pasa la cadena a `fetch`, y `fetch` resuelve una URL relativa contra la **direccion del documento**, no contra el `<base href>` |
| 2 | La app se negaba a descargar y decia "abre un fichero local" | `noDejaLeerDesdeNavegador` miraba si la respuesta traia `access-control-allow-origin`; en el despliegue real aplicacion y modulos estan en el **mismo origen**, y esa cabecera no viene porque no hay nada que autorizar |
| 3 | `SqliteException(14): unable to open database file`, con el modulo descargado y guardado | El VFS en memoria de `package:sqlite3` **no resuelve rutas relativas**: `xOpen` busca el nombre tal cual y SQLite le pasa la ruta ya resuelta contra `/`. Con `modulos/x.amod` en el mapa y `/modulos/x.amod` buscado, no aparece |
| 4 | La pantalla se quedaba en la biblioteca despues de descargar el texto | El enrutador pide la ruta al arrancar, no puede abrir el texto porque aun no esta, avisa y vuelve. Nadie vuelve a pedirla |

El primero y el segundo juntos significan que **en el sitio desplegado no se podia abrir
ningun texto desde un enlace**, y que la descarga no funcionaba siquiera desde la
biblioteca. El tercero que el `.amod` descargado no se abria en ningun caso en web. Y el
cuatro que el flujo de enlace profundo se quedaba a medias.

Las cuatro correcciones estan en el sitio de cada uno: `sqlite_web.dart`,
`obtener_modulo.dart`, `almacenamiento_de_modulos_web.dart` y `main.dart`. Las tres
primeras tienen pruebas en Dart que las fijan. La cuarta es de flujo y la unica forma de
fijarla es el navegador.

Y **LAS REGLAS**:

- **Ninguna URL del paquete se da por relativa.** Se resuelve contra
  `document.baseURI` uno mismo, con el motivo escrito al lado.
- **No se decide si el navegador puede leer algo mirando una cabecera.** Se hace la
  peticion y se mira lo que contesto. En un navegador, si CORS bloquea, **no llega
  nada**: `rango` devuelve `null`. No hay que adivinarlo con `Access-Control-Allow-Origin`.
- **Toda ruta de un fichero en el VFS en memoria es absoluta, con barra delante.**
  En nativo el mismo nombre significa otra cosa, y por eso el error solo aparece en web.
- **Un enlace profundo que no se puede seguir tiene que reintentarse cuando pasa a poder
  seguirse**, o avisar de que se vuelva a pulsar. Ahora avisa; reintentar solo, y solo
  con la sonda.

Y la leccion de fondo, que es la que importa: **`flutter test` no puede ver nada de
esto**. Las 330 pruebas del repositorio estaban en verde con las cuatro cosas rotas en
web. Unicamente abrir un navegador de verdad y mirar lo que pedia ha encontrado las
cuatro. Por eso el grupo 8 existe y por eso `scripts/comprobar-en-navegador.sh` se
ejecuta aparte y no se puede sustituir por una prueba.

### En web, `--dump-dom` no sirve y `page.evaluate` tampoco se puede aqui

Medido el 4 de octubre de 2026 con Brave 154:

    brave-browser --headless=new --dump-dom http://127.0.0.1:8099/ > salida.html
    exit=124   salida.html con 0 bytes

Se queda esperando hasta que le matan el proceso. Con `--virtual-time-budget`, sin el,
y con `--timeout`: igual. Y con una pagina normal **si** funciona --se comprobo con un
`file://` de tres lineas--, asi que el problema es el motor de Flutter, que mantiene
vivo el bucle de `requestAnimationFrame` y `--dump-dom` espera a que la pagina termine
de cargar.

Dos motivos, y los dos estan en la misma frase: **Flutter pinta en un `canvas`**, asi
que el DOM no tiene el texto que se ve, tiene una foto; y el navegador no termina solo.

Lo que se hace, y por que:

| | |
| --- | --- |
| **La app escribe en el DOM** | un `<pre id="ab-sonda">` con lo que ha leido. Es lo que pedia la tarea 8.1 y sirve para mirarlo con las herramientas del navegador |
| **Y ademas lo manda por HTTP** | a un colector local (`scripts/colector.py`). Es lo que el script comprueba, porque es lo unico que se puede leer de fuera |
| **Y el navegador se lanza con `--screenshot`**, que si termina | es la unica forma de que headless salga solo |

Que la sonda escriba **dentro** de la aplicacion y no desde un piloto externo es lo que
hace que esto compruebe algo: lo que llega al colector es el texto que ha devuelto una
consulta SQL a un `.amod` de 22.544.384 bytes. Un piloto que condujera el navegador
tendria que reimplementar el arranque, y comprobaria lo que el piloto quiere.

### El servidor local tiene que hacer lo que hace GitHub Pages

Dos cosas, y sin las dos la comprobacion en navegador mide otra cosa:

**1. `404.html` para las rutas profundas.** `/leer/KJV2006/John.3.16` no es un fichero,
es una ruta. GitHub Pages sirve `404.html` cuando no encuentra lo que se le pide, y el
CI copia `index.html` a `404.html` a proposito. `python3 -m http.server` **no** lo
hace: devuelve su propia pagina de error, sin aplicacion dentro, y entonces recargar en
un enlace no se puede ni intentar.

**2. `/aa` en el mismo origen.** En el sitio real la aplicacion esta en `.../ab/` y los
modulos en `.../aa/`: mismo origen, y ninguna peticion puede fallar por CORS. Servida en
local, son origenes distintos, la peticion lleva `Range` --que no es una cabecera
"simple" y por eso dispara un `preflight`-- y GitHub Pages **no responde a los
preflight**:

    $ curl -X OPTIONS -H 'Access-Control-Request-Headers: range' .../KJV2006_bible.amod
    HTTP/2 405

Con un 405 el navegador no hace ni la peticion. Y la comprobacion fallaba con "El
servidor no permite leerlo desde el navegador", que **no era un fallo de la
aplicacion**: era una situacion --origenes distintos-- que en produccion no puede
ocurrir. `scripts/servir.py` reenvia `/aa` a GitHub Pages cambiando **solo el host** en
el JSON del manifiesto, y recalcula `catalogSha256` porque el manifiesto de un espejo es
otro manifiesto. Los bytes del `.amod` no se tocan, y el motor lo comprueba con su
sha256: no hay forma de hacer trampas por el proxy sin que se note.

Y `Accept-Encoding: identity` **siempre** en el proxy, nunca lo que pida el navegador.
GitHub Pages comprime si le dejan, y un `.amod` comprimido tiene un sha256 que no cuadra
con el del manifiesto --el mismo fallo que ya esta escrito mas arriba en "Un rango
comprimido no es un rango", y aqui por el otro lado del cable.

### Comprobar que un proceso sigue vivo ANTES de mirar si responde

Un servidor que se muere al arrancar porque el puerto esta ocupado y otro servidor que
deja el puerto ocupado dan el mismo sintoma: `curl` responde. Con el `curl` primero, la
comprobacion de vida del proceso no llega a hacerse nunca en el caso para el que existe.

Medido el 4 de octubre de 2026: `scripts/comprobar-en-navegador.sh` daba "el servidor
responde" con un servidor de una ejecucion anterior de la misma tarde, y todo lo que se
veia era "No se ha podido contactar con el catalogo", que senala a la red cuando el
problema es un proceso que se murio treinta segundos antes. Ahora:

- se comprueba que los puertos estan **libres** antes de arrancar nada, y se dice con
  `ss -ltnp | grep` como mirar quien los tiene;
- se mira `kill -0 $PID` **antes** del `curl`, en el servidor y en el colector.

### `TMPDIR` va fuera de `/tmp`

`/tmp` en esta maquina es un tmpfs de **3,7 GB**, no un disco. El compilador de
`flutter test` escribe ahi el `.dill` que genera, y si se llena:

    FileSystemException: writeFrom failed ... (OS Error: Disk quota exceeded)

Lo que pasa entonces no es un error claro: `flutter test` **se queda colgado**
sin decir nada, y parece un problema de las pruebas. Se pierden minutos
buscando un test que no cuelga cuando el problema es que no hay sitio.

Por eso, antes de `flutter test` o `flutter build`:

```bash
export TMPDIR=/home/j/.tmp
```

Y si `/tmp` se llena otra vez, mirar primero `/tmp/opencode`: el tarball de
Flutter son 1,5 GB y se puede borrar en cuanto esta extraido.

## 6. Como trabajar aqui

```bash
flutter analyze          # sin avisos, siempre
flutter test             # verde, siempre
flutter build web
```

`flutter analyze` y `flutter test` en verde son parte de terminar una tarea, no
un extra.

Un cambio de comportamiento es un change de OpenSpec en `openspec/changes/`,
con `proposal.md`, `tasks.md` y `specs/`. Se valida con
`openspec validate <nombre>`.

El texto de la interfaz y los textos de la investigacion van en castellano.

## 7. Lo que no se hace aqui

- **No se tocan los repositorios anteriores.** Es decision de la persona duena
  del proyecto, al final, y solo si esto funciona. No es tarea de ningun change.
- **No se copia logica del catalogo ni se reimplementa el gate.**
- **No se mete contenido.** Ni una Biblia, ni un comentario, ni un indice de
  recursos dentro del codigo.
- **No se planifica iOS.** Se deja para despues, y ningun change puede
  depender de que exista.