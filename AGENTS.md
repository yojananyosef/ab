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