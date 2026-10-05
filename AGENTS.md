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

### La comprobacion en navegador se puede COMER lo que tiene que comprobar

Cuatro veces seguidas, el 4 y el 5 de octubre de 2026, la tercera ejecucion de
`scripts/comprobar-en-navegador.sh` dio "FALLO" y en las cuatro el motivo era el mismo y
no era la app:

1. La sonda arranca en `--dart-define=AB_SONDA=$RUTA_SONDA`, que va **compilado dentro**.
   Arrancarla en `/leer/KJV2006/John.3.16/con/CLARKE` sin recompilar no abre ese enlace:
   la aplicacion arranca en la ruta de la primera y **reescribe la del navegador**. El
   informe decia `ruta: .../John.3.16`, que es la prueba del fallo.
2. `ejecutar pareja` se llamaba **sin** el argumento de la ruta, asi que `ejecutar` uso
   `$RUTA_SONDA`. Un argumento muerto --el nombre de una captura que se habia quitado-- se
   llevo por delante el nuevo.
3. El paso 0 ofrecia bajar el comentario **antes** de que la ruta estuviera aplicada:
   `comentarioPedido` era null, la espera se daba por buena y no se bajaba nada.
4. La propia sonda navegaba con `RutaLectura(_moduloDeLaSonda, esperado)`, **sin** el
   comentario, y se comia el `/con/`.

Y EL QUE MAS ENSEÑA ES EL 3, Y NO ES UN ERROR DE LA SONDA. `comentarioPedido == null` se
lee igual que "no hay nada pendiente", asi que la espera se acababa y el paso 1 se
encontraba Juan 3:16 entero a los dos segundos y devolvia `ok`. La comprobacion decia que
si con **0 bytes** bajados, porque lo unico que miraba era el texto, y el texto es lo que
funcionaba.

La leccion, y es la misma de siempre: **una comprobacion que puede pasar sin comprobar lo
nuevo es peor que no comprobar**, porque da verde. Por eso ahora `mirarLaAplicacion` no
devuelve nada mientras la ruta pida un comentario y no este abierto, y por eso el paso 0
espera a que haya pasaje antes de ofrecer la descarga.

Y CADA UNO DE ESTOS CUATRO SALIO EN UN "FALLO" QUE DECIA LA VERDAD A MEDIAS. Un fallo que
dice la verdad a medias es peor que uno que no dice nada: hace perder el rato mirando la
app en vez de mirar el fallo.

### LAS PALABRAS DE JESUS SI ESTAN, Y SE PINTAN EN ROJO

**ESTA SECCION CORRIGE UNA QUE ESTABA MAL.** Antes decia que la palabra de Dios en rojo no
se podia pintar, y la razon que daba era que no habia ninguna marca de habla divina en los
modulos. La razon era cierta: no la hay. **La conclusion era falsa**, porque se busco una
marca --`\divine`, `\god`, una lista de versiculos-- y no se miraron las que hay.

La marca es **`\wj`**, que en USFM es el marcador de **palabras de Jesus**, el mismo que
usan las Biblias de letras rojas. Esta ahi, y el parser no la miraba. Medido el 5 de
octubre de 2026 sobre el KJV entero, con el parser de la aplicacion:

    versiculos del KJV                     31.102
    con palabras de Jesus                   2.015
    palabras de Jesus                   41.284   de 835.159   (4,94 %)
    aperturas `\wj`                       2.038
    versiculos con `\wj`                   2.028

Los tres numeros de `\wj` son distintos y hay que saber cual es cual: hay **2.038
aperturas en 2.028 versiculos** porque Juan 21:15, Juan 21:16 y ocho mas abren el marcador
dos veces dentro del mismo versiculo. Y de los 2.028, **2.015** reciben anotaciones: los
13 que faltan tienen el marcado descuadrado con el texto y se descartan enteros, que es la
misma regla que para el numero del lexicon.

Y POR LIBRO, que es donde se ve que el marcador dice lo que dice:

    Mateo 641   Lucas 584   Juan 415   Marcos 284
    Apocalipsis 61   Hechos 27   1 Corintios 2   2 Corintios 1
    Genesis 0   Salmos 0   Exodo 0   (y los otros 18 del Antiguo Testamento, 0)

**LAS DOS FILAS DE CORINTIOS SON LA PRUEBA.** En 1 Corintios 11:24 y 2 Corintios 12:9 son
palabras de Cristo **citadas por Pablo**. Si `\wj` significara "dialogo", tambien las
traeria; si significara "habla divina", no, porque Pablo no es Cristo.

### LO QUE SE PINTA EN ROJO SON LAS PALABRAS DE JESUS, NO LAS DE DIOS

Y ESTA ES LA DISTINCION QUE HAY QUE PODER DECIR, porque son dos cosas y solo una es
cierta:

| | |
| --- | --- |
| **Lo que dijo Jesus** | **si**, en 2.015 versiculos, y se pinta en rojo |
| **Lo que dijo el Dios del Antiguo Testamento** | **no**, en ninguno de los 21 libros |

Lo segundo no esta en ningun sitio de este catalogo. No hay `\divine`, no hay
`\god`, no hay convencion. Y no hay de donde sacarlo: inventar una lista de versiculos en
los que Dios habla es escribir el dato de otra persona y atribuirselo al modulo, que es lo
peor que puede hacer un lector de Biblia.

Por eso el interruptor se llama **"Palabras de Jesus en rojo"** y no "Palabra de Dios", y
por eso se pinta en rojo lo que el modulo marca y no lo que uno cree que deberia.

### Y LO MISMO CON LOS VERSICULOS: `\wj` MARCA, NO RESUELVE

Medido, y con los dos lados porque los dos importan:

    Juan 3:16    25 de 25 palabras    todo el versiculo es de Jesus
    Juan 3:11    24 de 24
    Juan 3:28     0 de 20             el Bautista
    Juan 3:29     0 de 32             el narrador
    Juan 3:36     0 de 28             el narrador

Si el marcador marcara el capitulo entero, o no marcara nada, esos cuatro darian el mismo
resultado. **Por eso la comprobacion que importa es "tiene marca Y el siguiente no la
tiene"**, y no "tiene marca". Con una sola de las dos, un rojo puesto sin criterio seria
rojo en todo Juan 3 y no estaria diciendo nada.

Y el fallo de la bandera es el de siempre: `\wj` se lee de la **pila**, no de una bandera
que se ponia al abrir y no se apagaba al cerrar. Con la bandera, Juan 3:28 --20 palabras del
Bautista-- salia entero rojo.

### EL COLOR ES TEXTO, Y EL CONTRASTE SE MIDE

El rojo de las palabras de Jesus es `0xFF992B22`, y da **7,33:1** sobre el fondo de la
pantalla y **7,71:1** sobre la superficie. El umbral de AAA para texto normal es 7:1, y el
texto corriente da 16,96:1.

No se eligio a ojo. Es color de **texto de cuerpo**, y un rojo claro de letras rojas se lee
como texto deshabilitado y no como Escritura. Y la comprobacion esta **viva en cada
ejecucion**: si alguien cambia el color del tema y lo deja en 4:1, la prueba se pone roja.

Y NO ES EL COLOR DE `peligro` CON OTRO NOMBRE. Si las dos cosas fueran el mismo color, un
dia el aviso de error pasaria a ser del color de la Palabra de Cristo y nadie sabria que
paso. Cada color dice una cosa.

### LAS DOS MARCAS SE SUMAN, Y EN ESTE CATALOGO NUNCA COINCIDEN

Medido: de 835.159 palabras del KJV, **cero** son a la vez `\add` y `\wj`. Asi que el caso
de las dos marcas **no se puede probar con el fichero real**, y por eso la decision de
estilo esta en `widgets/estilo_de_palabra.dart`, una funcion pura que se prueba entera.

Y NO HAY QUE ELEGIR UNA. La primera version hacia que "el subrayado ganara" sobre el rojo, y
una palabra anadida por el traductor **dentro** de las palabras de Jesus salia negra con
subrayado: el rojo se perdia justo en el unico sitio donde mas se nota. Y con el interruptor
apagado el subrayado **se queda**: apagar el color no puede borrar informacion del modulo.

### UNA PREFERENCIA QUE SE LEE SIN PLAZO CUELGA LA PANTALLA

El interruptor guarda si esta puesto, en `Almacenamiento`, que es donde vive la unica
preferencia de lectura. Leerla es un `await` sobre `localStorage`, y ya hay un caso medido
en este repositorio --el almacenamiento del navegador que nunca contesta-- donde un `await`
sin plazo **cuelga la pantalla entera**.

La primera version no tenia plazo. La prueba con un almacenamiento que devuelve una promesa
que no se resuelve **se quedo colgando cinco minutos** y dio `TimeoutException`, que es la
forma exacta del fallo que existe fuera de las pruebas.

Por eso:

- **Cinco segundos**, no uno: el caso medido no es lento, es que no contesta.
- **Es un parametro**, para que una prueba lo baje a diez milisegundos y pueda comprobar el
  caso sin esperar.
- **Si no contesta, se queda el valor de partida y no se avisa.** Aqui, a diferencia del
  catalogo, el silencio si es lo correcto: lo que se ha perdido es una preferencia --dos
  toques-- y un aviso en medio de Juan 3 no le sirve a nadie.

Y UNA PREFERENCIA SE LEE AL ABRIR LA PANTALLA, no al arrancar la app. Si se leyera al
arrancar, abrir una pestana nueva al lado de otra se pintaria con el color de la primera.

### LA BARRA ESTABA TAN LLENA QUE AL TITULO LE QUEDABAN 13,9 PIXELES

Medido a 360 px el 5 de octubre de 2026, con la cabecera de dos lineas y el boton de
comentario como boton con texto:

    hueco que le quedaba al titulo      13,9 pixeles
    palabra "Comentario" sola          110 pixeles
    el mismo boton, como icono          48 pixeles

Trece pixeles. "Juan 3:16" no cabe en trece pixeles, y el nombre de la version tampoco.

**Y NO LO HABRIA VISTO NADIE LEYENDO EL CODIGO**: tres widgets correctos, cada uno en su
sitio, que juntos no dejan sitio. Y el sintoma no es un `overflow`, que es lo que se
buscaria primero: **un `Text` de 13,9 pixeles no desborda nunca**, se recorta entero y no
hay excepcion. Un titulo ilegible **no falla**, y por eso la comprobacion que lo caza
mide el **ancho del widget**:

    a 360 px   el pasaje ocupa mas de 60
    a 320 px   el pasaje ocupa mas de 50

Y el arreglo fue **quitarle sitio a otro**, no anadirle sitio al titulo: el boton de
comentario paso a ser icono. El selector de version no es un quinto boton porque a 360 px
no cabria un quinto boton, y porque de `docs/investigacion-ux.md` es "la interaccion mas
valiosa de una app de Biblia" --que no cabe en un boton-- y lo que hace falta para que quepa
es **dejarle sitio** en la barra, que es donde ya se mira.

### `alCambiarDeVersion` ESTABA CABLEADO Y NADIE LO LLAMABA

El enrutador tenia `cambiarDeVersion` con su `replaceState` y su comentario sobre por que,
desde el principio. **Ningun boton lo llamaba.** Era la interaccion mas valiosa de la
categoria de `docs/investigacion-ux.md` y era **inalcanzable**, y no habia ninguna prueba
que se queja: las pruebas comprueban que la funcion hace lo que debe, no que algo la llame.

Con una hoja de codigo que nadie lee, ese es el fallo que no aparece: **una funcion sin
llamador no falla nunca**.

### EL PRIMER VERSICULO **NO** ES UN RESUMEN DE CAPITULO

La idea de localizacion que se copio de Bible Gateway es "el resumen de cada capitulo en el
selector de libros". Lo que hay **no es un resumen**, y el nombre lo dice: es la primera
frase.

Medido sobre el KJV entero, tomando `verse = 1` de los 31.102 versiculos:

    mayoria son Genealogias, Salmos y Proverbios, donde la primera frase no dice nada del
    capitulo: "1 These are the generations of Adam"
    Juan 3 y Romanos 1 si la dicen, porque empiezan con un sustantivo propio

Es un **indice de referencia**, no un indice tematico. Un resumen de verdad son las
palabras del capitulo en tres lineas, y eso **no esta en el modulo**: el lexicon no esta en
el `.amod` (ver mas abajo). Escribirlo seria el dato de otra persona.

Y el coste sale de una consulta:

    `librosConCapitulos()`      66 libros, 1.189 capitulos,   **8 ms**
    `primeraFraseDeCapitulos()` Juan, 21 capitulos,         **1 ms**

8 ms es **una** consulta y no 66. Leer los 66 con `libros()` y luego `capitulosDe()` por
libro son **67** consultas para pintar una lista, y en un movil se nota.

Y LA FRASE SE CORTA EN UN PUNTO, no a un numero de caracteres: cortar a 120 parte frases y
deja el final colgando en "...y dijo a". Si la frase entera no tiene punto --los cuatro
evangelios abren sin ninguno-- se corta donde toca y se dice con puntos suspensivos.

### UN TAMANO SE FORMATEA EN UN SITIO, Y EN CASTELLANO

`Modulo.megabytes` era `(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)` y devolvia
**`"21.5"` con punto**. En castellano el punto separa los millares y la coma los decimales,
o sea que "21.5 MB" se leia como veintiuno con cinco.

Estaba en **tres** sitios de la interfaz --la biblioteca, el boton de descargar y el de
quitar el comentario--, con lo que el numero estaba mal en los tres. Y el boton deia
**"Descargar, 54.9"**, sin unidad, que no dice de que son los 54,9.

Ahora hay un `bytesEnCastellano` en `ui/core/numeros.dart` y **no hay ningun formateador en
el dominio**. Con la unidad dentro y decimal hasta cien megabytes:

    22.544.384 bytes    21,5 MB      (no 22,5: es dividir por 1.048.576, no por un millon)
    57.536.512 bytes    54,9 MB

### EL LEXICON NO ESTA EN EL `.amod`, Y POR ESO NO HAY DICCIONARIO

Medido el 5 de octubre de 2026 sobre el KJV publicado. Las tablas son dos:

    info, verses

Y las trece claves de `info`:

    id, name, language, license, license_evidence, copyright, attribution,
    origin, source, schema_version, type, versification, defects, defects_count

**Ninguna de lexicon.** El significado de `G2316` esta en un diccionario del griego, y ese
diccionario no lo trae este catalogo ni el otro.

Lo que si trae es el **numero**: 14.047 numeros distintos y 348.884 ocurrencias en el KJV.
Con eso se puede hacer un indice del texto --"donde mas sale esta palabra en ESTA
traduccion"—, y **no** un diccionario.

Escribir los significados a mano seria poner en pantalla la opinion de quien los escribio, en
una aplicacion cuyo primer requisito es no alterar lo que lee. Y quien busca el significado
de una palabra es que tiene un diccionario, y entonces no lo necesita en la app.

Asi que el indice **dice que no es un diccionario**, arriba, antes de la lista. Con 200
lineas en medio, un aviso al final no se ve nunca.

Y EL RECUENTO ES DE **VERSI...CULOS**, no de ocurrencias:

    G2316   1.171 versiculos     1.359 veces

Juan 3:16 tiene la palabra una vez y Mateo 1:23 tres, y la lista que se pinta es de
versiculos. Confundir los dos numeros haria que el indice prometiese una lista mas corta de
lo que es.

### UN NUMERO SIN VALIDAR BUSCA EN EL TEXTO ENTERO

`buscar('%')` y `buscar('_')` ya devolvian **los 31.102 versiculos** del KJV, porque el
comodin se quita y el patron se queda en `%%` o `__`, y una cadena vacia casa con todo. El
mismo fallo con el indice: `indiceDeStrong('Dios')` sin validar daria los 31.102.

Por eso se comprueba **antes de consultar**: `G` o `H` y cuatro digitos o mas. `G1` no es una
entrada del lexicon, y `X1234` tampoco es un idioma.

### EL TEXTO NO SE RECONSTRUYE DESDE EL `raw`

Las dos columnas dicen lo mismo y dan la misma Biblia, pero **no con los mismos
caracteres**. Medido:

    5.844 versiculos cuyo `raw` tiene un `+` que `text` no tiene
    13.740 marcas `\nd` de "sin divisor"
    notas al pie cuyo numero va en una columna y no en la otra
    1.201 versiculos con el numero de seccion `\s1` en el `raw` y no en el texto

Reconstruir `text` desde `raw` obliga a aprender una regla por caso, y se intento: tres
versiones, y la tercera se rindio con el aparato de variantes de las cronicas, que necesita
cuatro reglas distintas segun el versiculo. Una regla por caso es escribir el texto del
modulo sin saber que se esta escribiendo.

**Asi que el texto se pinta desde `text`, siempre, y del `raw` solo salen anotaciones** --
el numero del lexicon y la marca de `dd`--, que se descartan si las palabras no cuadran.
Medido: **97,60 %** de los versiculos del KJV reciben anotaciones. Preferimos un versiculo
sin lexicon a uno con el numero de la palabra de al lado.

### `LIKE` NO es buscar palabras

Medido el 5 de octubre de 2026 sobre el KJV real:

    "a"                31.027 versiculos de 31.102
    "ab"                4.677
    "God" / "god"       4.140
    "begotten"             26
    "propitiation"          3
    en el CLARKE, "propitiation"   15

Tres cosas que salen de ahi y que no se ven sin medir:

**1. Una palabra de una letra no busca.** `a` sale en 31.027 de 31.102, y con un limite
de 200 eso son 200 lineas de las que 29.927 no estan. Y el peor detalle es el de la
pantalla: si "no hay resultados" y "no se ha buscado" son el mismo estado, quien escribe
`a` lee que el texto no tiene esa palabra, **que es falso**. Por eso `sinBuscar` es un
estado aparte y la pantalla puede decir "dos letras o mas".

**2. El `%` y el `_` se QUITAN, no se escapan.** Escribir `a_b` busca `ab`, y por eso
devuelve 4.677: no hay ni una palabra con guion bajo en el KJV. Y escribir `%` deja el
patron en `%%`, que no es "todo" sino una cadena vacia --y una cadena vacia **si** sale en
todo--, asi que sin una comprobacion antes de consultar devolveria los 31.102. La primera
version de la prueba pedia menos de 200 y fallaba con 4.677, y la conclusion "--no se
escapa--" era falsa.

**3. `LIKE` no distingue mayusculas y `instr` si.** Por eso el recorte del extracto lleva
`lower()` en los dos lados: sin el, buscar `god` en el KJV --que escribe `God`-- encuentra
los 4.140 versiculos y luego el recorte sale centrado donde no toca.

Y EL RECORTE **NO** ES EL VERSICULO ENTERO. Juan 3:16 tiene 141 caracteres y el extracto
son 120, empezados 40 antes de la coincidencia: ` loved the world, that he gave his only
begotten Son, ... have everla`. Con 200 lineas de 405 caracteres serian 81.000 caracteres
en pantalla para encontrar una palabra.

### El separador de millares hay que ponerlo a mano

`4140.toString()` es `"4140"`. En castellano son `4.140`, con **punto** y no coma: la coma
es el separador decimal, y `4,140` son cuatro con ciento cuarenta mil. Dart no lo pone y
nadie lo pone por el, asi que esta en `ui/core/numeros.dart`.

Y empieza en las **cuatro** cifras, no en las cinco. La RAE dice que los numeros de cuatro
cifras se escriben sin separador y que este puede añadirse cuando ayude a leerlos; en
pantalla se añade siempre, porque `4140` son cuatro digitos que hay que contar mientras
`4.140` se lee de un vistazo. En prosa la regla seria la otra, y por eso la funcion es de
la interfaz y no del dominio.

### Un enlace con un comentario tiene que poder bajarlo

Medido el 4 de octubre de 2026 en la comprobacion en navegador, con
`/leer/KJV2006/John.3.16/con/CLARKE` en un perfil donde el CLARKE no estaba:

    Juan 3:16           se lee entero
    comentario abierto  ninguno
    bytes bajados       0

Y ninguna de las 414 pruebas de Dart lo ve, porque el fallo **no esta en el modelo**: esta
en que la app decia "el comentario CLARKE no esta descargado en este dispositivo" y se
paraba ahi. Quien recibe el enlace no tenia forma de conseguir el comentario sin dejar de
estar leyendo, y un enlace con un comentario que no se puede seguir no es un enlace: es
una frase.

La cadena que faltaba tiene tres saltos y ninguno de ellos es del modelo:

1. **El aviso ofrece bajarlo**, con el boton al lado y el tamano en el boton. Un
   "Descargar" sin coste conocido no se pulsa; uno que dice 54,9 MB se decide.
2. **Quien baja es la biblioteca** y quien aplica una ruta es el enrutador. No hay nadie
   en medio, asi que el enrutador **escucha** a la biblioteca.
3. **Al terminar la descarga**, el enrutador vuelve a aplicar el comentario de la ruta, y
   se abre solo.

Y el paso 2 es el que no se ve: si el enrutador no escucha, el boton baja 57 MiB, termina,
y quien lo pidio se queda con el texto y el comentario a medio bajar. Sin dar ningun error.

Y LA ESCUCHA MIRA **UNA** COSA: que el identificador pedido este entre los descargados. La
biblioteca avisa de los progresos de la descarga, de los errores y de los filtros, y con
cualquier otro aviso la comprobacion se cumple igual y se reabre el comentario en cada
barra de progreso.

### Abrir un modulo NO es leer sus notas

Medido el 4 de octubre de 2026 con el CLARKE abierto y una ruta que pide Juan 5:

    Juan 3, que es de donde venian las notas   32 notas
    Juan 5, que es de donde se iban a leer     32 notas   <- las mismas

Juan 5 tiene **43** versiculos con nota. Ir de Juan 3 a Juan 5 con el comentario abierto
dejaba las notas de Juan 3 encima de Juan 5, y la pantalla no decia nada: 32 notas
correctas de otro pasaje, escritas donde iba la de Juan 5.

La causa fue tratar "abrir el comentario" y "leer sus notas" como la misma cosa. En
`NavegadorAb._aplicarComentario` se compara con lo que ya hay abierto y, si es el mismo,
no se hace nada. Para **abrir** eso es lo correcto --reabrir 57 MiB y volver a pasarle
`PRAGMA quick_check` para traer las mismas notas no tiene sentido--, pero el pasaje ha
cambiado y las notas son de otro.

La forma correcta es separarlas: si el comentario ya es el que toca, **no se reabre y se
vuelven a leer**. Y se vuelve a leer solo si el pasaje es otro, o `leer` y esto se turban
en un bucle de consultas.

### Dos modulos abiertos: lo caro no es el tiempo

Medido el 4 de octubre de 2026 sobre los ficheros reales:

    PRAGMA quick_check, KJV2006    (22.544.384 bytes)     8,3 ms
    PRAGMA quick_check, CLARKE     (57.536.512 bytes)    11,5 ms

Doce milisegundos para comprobar 57 MiB. La sorpresa es util: al disenar el comentario al
lado del texto, lo que se calculaba era el tiempo de abrir un segundo `.amod`, y se iba a
saltar la comprobacion de integridad en el secundario por ser "un modulo secundario". No
hace falta: son 11,5 ms y el sha256 ya se comprobo al descargar.

Lo que si es caro es la **memoria**: 22 + 57 = 79 MiB de paginas SQLite abiertas a la vez.
Y eso no se mide en el navegador, se nota en un movil de gama baja. Por eso:

- El comentario se cierra al cambiar de texto, no solo al volver a la biblioteca.
- Se cierra al cambiar de version del texto.
- No se abre en ningun caso si la ruta no lo pide.

### `count(DISTINCT verse)` NO cuenta versiculos

Medido el 4 de octubre de 2026 sobre el KJV real:

    SELECT count(*) FROM verses                 ->  31.102
    SELECT count(DISTINCT verse) FROM verses    ->  176

176, no 31.102. Porque `verse` es el numero **dentro del capitulo**, y en todo el modulo
solo hay 176 numeros distintos. Es un numero cierto y no es el que se quiere, y es el
error que se escribe cuando se generaliza una consulta a dos tablas.

Lo que cuenta versiculos es contar **pasajes**, que son la terna de libro, capitulo y
versiculo. En el KJV da 31.102; en el CLARKE da 19.741, que son los versiculos con al
menos una nota.

Y el otro lado de lo mismo: `versiculosDe(libro)` si puede usar `count(DISTINCT verse)`,
porque dentro de **un** libro el numero si identifica el versiculo. El `DISTINCT` hace
falta por otra razon ahi: hay un versiculo con dos notas, y sin el el selector lo ofrece
dos veces.

### Una nota repetida en el dato, y `defects_count` que no lo declara

Medido el 4 de octubre de 2026 sobre el CLARKE publicado:

    notas                                      19.742
    pasajes distintos (book, chapter, verse)   19.741
    versiculos con MAS de una nota             1
    info.defects_count                         0

El unico es **Mateo 23:13**, y sus dos notas son **el mismo texto**, 2.709 caracteres cada
una. Es una fila repetida en el fichero, y `defects_count` dice `0`, con lo cual esta
mintiendo.

Que se quite en la app y no en el modulo es deliberado: la app es de solo lectura y no
toca el `.amod`, y un lector que ensena el mismo parrafo dos veces seguidas parece roto.

El limite es estrecho a proposito:

- **Solo** si el texto es identico.
- **Solo** en el **mismo versiculo**, y solo la repeticion inmediata. Dos notas parecidas
  que no sean iguales se ensenan las dos: quitar contenido porque se parece a otro es
  peor que ensenarlo de mas.

Y lo que hay que arreglar de verdad esta en `aa`, que es quien construyo el `.amod`, y es
decision de la persona del proyecto.

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

### SIN IMAGEN NO SE PUEDE MIRAR LA INTERFAZ, Y ESO CAMBIA LO QUE SE ENCUENTRA

Medido el 5 de octubre de 2026. `--screenshot` de Brave se queda colgado y devuelve 0
bytes, asi que el paso de la captura se quito de `scripts/comprobar-en-navegador.sh` y se
documento como imposible. **No era imposible: era otro camino.**

`page.screenshot()` de Playwright funciona, y las tres diferencias son:

| | |
| --- | --- |
| espera a `domcontentloaded` y ademas a un tiempo fijo | en vez de depender del reloj virtual |
| `--enable-unsafe-swiftshader` | sin el, Brave 154 avisa y sale con el lienzo **en blanco** |
| **no** usa `--virtual-time-budget` | que es lo que deja a Flutter colgado: el motor mantiene vivo el `requestAnimationFrame` |

```bash
cd scripts/viz && npm install playwright          # una vez, no se versiona
node scripts/viz/capturar.mjs                      # a 360 y a 1440
```

Y EL PERFIL **PERSISTENTE**, que es lo que hace esto utilizable: el `.amod` son 22,5 MB y
va al `IndexedDB`. Con perfil de cada vez, cada captura se baja el modulo entero, y una
iteracion de diseno son 12 segundos de descarga antes de poder mirar nada. Con perfil
persistente la segunda vez ya esta y la captura sale en dos.

Y ADEMAS HAY QUE **CALENTAR EL PERFIL**: un enlace profundo a un modulo que no esta
descargado avisa y se queda en la biblioteca, porque reintentar solo esta en la sonda. Con
el perfil frio, la primera captura de la pantalla de lectura sale siendo la biblioteca con
un 60 % de descarga, y parece que la ruta no funciona.

### LO QUE SALIO DE MIRAR, Y NO SALIO DE LEER

Medido en una captura a 360 px, con Juan 3:16 abierto y el KJV entero descargado:

    barra de arriba                              56 px
    campo "Ir a" + boton "Buscar" de 48 px      164 px
    titulo del capitulo, que repetia la barra   40 px
    ----------------------------------------------------------
    cromo antes del primer versiculo            260 px
    el versiculo, que era TODO el texto          122 px
    los terminos del modulo                      268 px

**De 760 px de alto, el versiculo era el 16 % y los terminos el 35 %.** Y ninguna prueba
de este repositorio lo veia, porque el sintoma no es un fallo: es una pantalla que muestra
muy poco texto.

Y la causa **no era el diseno**, era el dato: `Juan 3:16` traia **un versiculo**, porque la
consulta filtraba con `verse = ?`. Un lector de Biblia que al abrir un versiculo ensena un
versiculo y tres lineas de terminos no esta enseñando la Biblia.

### LA LISTA DE LA CAPTURA, Y POR QUE ESTA EN EL SPEC

Medido el 5 de octubre de 2026, poniendo una captura de esta aplicacion al lado de una de
Logos con la misma tarea:

    panel de herramientas a la izquierda      Logos si    aqui no
    pestanas por panel                        Logos si    aqui no
    paneles lado a lado con scroll propio     Logos si    aqui no
    fila de menu por panel                    Logos si    aqui no
    segunda barra de formato                  Logos si    aqui no
    migas de pan sobre el texto               Logos si    aqui no
    numero de capitulo grande y epigrafes     Logos si    aqui no
    numeros de versiculo en linea             Logos si    columna a la izquierda
    panel de ideas a la derecha               Logos si    aqui no
    barra inferior en pantalla estrecha       Logos si    no habia ninguna

De diez cosas, **una** estaba. Y el fallo **no era el diseno**, era el metodo: se hicieron
nueve changes, cada uno probado, y las capturas eran de la aplicacion propia. Decian «no
desborda» y «el versiculo sale», nunca «esto se parece a lo que te ensenaron». La lista esta
ahora en `openspec/changes/el-marco-de-estudio/specs/marco/spec.md` como requisito
comprobable, no como descripcion.

**ASI QUE LA CAPTURA TIENE QUE IR AL LADO DE LA DE REFERENCIA, NO SOLA.** Mirar la propia
pantalla es ver que se ha dibujado.

### LOS TRES FALLOS QUE SALIERON AL COPIAR LA DISTRIBUCION

Todos en el mismo commit, y los tres los sacaron pruebas que ya existian:

**1. `NavigationRail` con `minWidth: 0` revienta.** Con `extended: true` el `minWidth` tiene
que ser `null`:

    Failed assertion: line 118 pos 15: 'minWidth == null || minWidth > 0'

Y `minExtendedWidth` es un **minimo**, no un ancho: el panel mide **226,5** porque la
etiqueta mas larga es "Comentarios", no los 176 que se le habian puesto.

**2. El marco esta fuera del `Scaffold` y necesita su propio `Material`.** El `Scaffold` pone
el suyo en la barra y en el cuerpo; un `TextField` en la barra de abajo lanza

    The specific widget that could not find a Material ancestor was: TextField

que es un fallo que no dice de donde viene.

**3. `find.byType(Scrollable).first` cogia el `EditableText` del campo, no la lista.** En
la pantalla de lectura hay **dos** `Scrollable`: el de dentro del campo --212 x 23-- y el
de la lista --332 x 480--. El primero esta antes en el arbol, el arrastre no hacia nada, y
la prueba de los terminos decia "no han salido" cuando en realidad no se habia movido nada.
Hay que acotar al `ListView`.

**Y UN MAS, DE LOS PROPIOS TESTS**: recoger "los numeros de versiculo visibles" por
`find.byType(RichText)` y quedarse con los que son un numero entero devolvio `[3, 36]` al
abrir Juan 3. El 3 de mas era el **numero de capitulo**, que ahora va antes de los
versiculos. Tres pruebas contaban 37 versiculos visibles. Se resolvio con una clave publica
en el numero del versiculo, no con un filtro mas estrecho.

### UN CI ROJO SIN UNA LINEA DE LOG ES QUE NO HAY CORREDOR, Y SE CONFIRMA EN EL ESTADO DE GITHUB

Medido el 5 de octubre de 2026. El run del marco de estudio fallo asi:

    The job was not acquired by Runner of type hosted even after multiple attempts
    Internal server error. Correlation ID: 4f78c28c-30d9-4058-aced-52fc943f16fc

**Sin una linea de log.** El job quedo `cancelado` sin ejecutar **un solo paso**: no
instalo Flutter, no mire el codigo y no fallo ninguna prueba. Con el run anterior --la
pantalla de lectura-- todo en verde en 3 min 38 s con el mismo workflow.

Y EL DIAGNOSTICO MAL HECHO, que es la parte que importa. El aviso que trae el propio run es

    The ubuntu-latest label will migrate to Ubuntu 26 beginning October 19, 2026

y de ahi se concluyo que la etiqueta era la causa y se fijo `runs-on: ubuntu-24.04`. **No lo
era.** Con la imagen fijada el run se quedo igual, y el estado de GitHub dice, tres veces
seguidas con un minuto de separacion:

    https://www.githubstatus.com/api/v2/components.json
    Actions            major_outage
    indicator: major   Partial System Outage

O sea que **la conclusion era correcta y la prueba estaba incompleta**: "no hay corredor" es
una causa de "el job no arranca", y "la etiqueta se esta moviendo" es una causa **posible**
de "no hay corredor". Se dio por buena la posible sin mirar si habia corredores, que es una
cosa distinta y se mira en un sitio.

Y ASI SE ESCRIBE EL ERROR, que es lo que hay que mirar la proxima vez:

- **Un commit que dice "arreglado" y no arregla es peor que no haber tocado nada**, porque
  el siguiente que vea el commit asume que la causa era la etiqueta y pierde el rato
  cambiando etiquetas de imagen.
- **Cambiar la configuracion a ciegas y mirar el resultado no es diagnosticar**: hay que
  tener el estado del servicio delante, porque es una comprobacion de treinta segundos.
- Y **el aviso de la migracion estaba ahi para informar, no para culpar**. Es un aviso de
  octubre, y el fallo era de hoy.

Asi que `runs-on: ubuntu-latest` se queda, y cuando llegue la migracion se fija la imagen
entonces, con el motivo de entonces. Lo que **no** se hace es dejar un cambio puesto que
dice arreglar algo que no arregla.

Y LO QUE SI SIRVE, para la proxima vez: `gh run view <id> --json jobs` da `conclusion:
cancelled` **sin pasos**, y eso ya dice que no llego a ejecutar nada. Un job con pasos en
`completed` y alguno en `failure` es un fallo de codigo; un job **sin pasos** no es un fallo
de codigo y no hay que_debugarlo.

### UNA CAPTURA EN BLANCO ES UN `404.html` VIEJO, Y NO ES LA APLICACION

Medido el 5 de octubre de 2026. Una captura de la pantalla de lectura a 1440 px salia de
**19.307 bytes**, que es una imagen del color del fondo y nada mas, mientras `/` servia
perfectamente.

La causa: **`flutter build` reescribe `index.html` y no toca `404.html`**, que se copia a
mano. Con dos compilaciones de prefijos distintos --`--base-href=/` en local y
`--base-href=/ab/` para GitHub Pages-- el `404.html` se quedaba con el prefijo de la build
anterior:

    index.html declara "/"
    404.html   declara "/ab/"

Y como las rutas profundas losirven **el** `404.html`, un enlace a
`/leer/KJV2006/John.3.16` pedia `/ab/flutter_bootstrap.js` contra un servidor local que no
tiene `/ab/`, con cuatro 404 en la consola y la pantalla en blanco.

TRES COSAS QUE HACE ESTO FALAR Y QUE NO SON LA APLICACION:

- **`/` funcionaba.** Con lo que parecia un fallo de la pantalla de lectura, y era un fichero
  del directorio de la build anterior.
- **Una captura en blanco es una captura.** Sin mirar el tamano del PNG no hay nada que
  sospeche, y el PNG en blanco parece una pantalla vacia.
- **Borrar el perfil del navegador tampoco lo arregla**, que es lo que se pruebo primero, y
  con acierto: el `flutter_service_worker.js` cachea el paquete entero, pero el culpable de
  estos 404 era el `404.html`.

Por eso `scripts/viz/capturar.mjs` **comprueba los dos `base href` antes de sacar nada** y avisa
con el comando exacto, y por eso hay que dejar el `404.html` al dia en cuanto se compila, no
cuando se va a publicar.

### EL SCRIPT DE CAPTURAS BUSCA `node_modules` EN SU DIRECTORIO, NO EN EL DE TRABAJO

Medido el 5 de octubre de 2026. Con el script en `scripts/capturar.mjs` y las dependencias en
`scripts/viz/`:

    Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'playwright' imported from
    /home/j/ab/scripts/capturar.mjs

Node busca `node_modules` subiendo desde el directorio **del fichero**, no desde el que se
ejecuta. Y lo que mas engaña es que el `package.json` esta a la vista, con sus dependencias
instaladas al lado. El error habla de un paquete que no existe y no de un fichero en el sitio
equivocado.

Por eso el script esta **en `scripts/viz/`**, y hay un `.gitignore` con `node_modules/` para
que las 300 MB de Playwright no se acaben versionando por accidente.

### LO QUE MIDIO Y NO SE PEDIA

**Juan 3, que son 36 versiculos, ocupa 16.848 pixeles a 360 px de ancho.** La columna de
texto se queda en 260 px y cada versiculo sale en cinco o seis lineas. Que es lo que pasa
sin un solo ajuste de tamano de letra, de alto de linea o de fondo, que es exactamente lo
que no existe.

### LOS DOS FALLOS QUE SOLO SALIERON MIRANDO

**1. La version no salia nunca en la cabecera.** El enrutador escuchaba a la biblioteca
**solo** para saber si podia abrir el comentario, y **nunca llamaba a `notifyListeners()`**.
Asi que la pantalla de lectura se quedaba con la lista de versiones que tenia al
construirse --vacia, porque el manifiesto no habia llegado-- para siempre. Se espero 20 s en
el navegador: no era tiempo.

Y **ninguna comprobacion lo veía**: el nombre de la version es texto de la barra, la sonda
del navegador lee el **pasaje**, y `flutter test` montaba la pantalla con la lista ya puesta
a mano. Las dos dan verde con el bug puesto.

**2. El boton de "Ir" estaba debajo del campo por un motivo que se midio mal.** El
argumento era que en fila con el campo el boton se quedaba con la mitad del ancho y "el
texto se corta a los 12 caracteres". Es verdad, y la causa no era la fila: era que el boton
de abajo era de **48 px de alto y de ancho completo**, y el campo solo tenia la mitad. Con
el boton **dentro** del campo, como icono de sufijo, el campo toma la columna entera y
"Juan 3:16" entra de sobra.

Y el boton de abajo eran **62 px** de los 760 --un 8 % de la pantalla-- para un control
deshabilitado el 99 % del tiempo porque no hay nada escrito. Con el boton dentro no hay
segunda fila, y el `textInputAction: search` --que ya estaba-- hace lo mismo desde el
teclado.

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