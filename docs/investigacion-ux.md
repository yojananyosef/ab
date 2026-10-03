# Investigacion de UX: que copiamos y que evitamos

Sintesis de la investigacion hecha antes de escribir la primera linea de la
aplicacion. No es un resumen: es un documento de decisiones. Cada punto dice
que se decide, y por que se puede defender.

Los informes completos, con sus citas, sus precios y sus marcas de
`VERIFICADO` / `INFERENCIA`, estan en `docs/investigacion/crudo-*.md`. Ahi esta
la evidencia. Aqui esta la conclusion.

## Como se lee este documento

Tres informes de referencia:

| Fichero | Quien |
| --- | --- |
| `crudo-01-logos-accordance.md` | Logos Bible Software y Accordance |
| `crudo-02-stepbible-mybible.md` | STEPBible y MyBible: el sistema de modulos |
| `crudo-03-youversion-web.md` | YouVersion/Bible.com, Bible Gateway, el mercado en espanol, los lectores web |

Marcas:

- **[V]** VERIFICADO. Primera fuente oficial, sonda HTTP directa, o cita
  textual de un autor identificado.
- **[I]** INFERENCIA. Lectura nuestra de la evidencia, con confianza indicada.
- **[R]** RELATO DE USUARIO. Alguien cuenta algo que le paso. Es senal, no
  hecho.

La prosa de este repositorio va sin acentos. Las citas de los informes
cruditos van con su ortografia original, porque una cita sin acento deja de
ser la cita.

---

## 1. El hueco por el que entra esta app

**[V]** La version web de YouVersion/Bible.com **no tiene notas, ni marcadores,
ni descarga sin conexion, ni colores de resaltado a medida, ni imagenes de
versiculo, ni planes compartidos, y su audio tiene un solo narrador.** Todo
ello esta documentado en la propia ayuda de YouVersion. En la aplicacion movil
todo eso existe.

Lo que si se puede hacer en la web de bible.com: leer, resaltar con una paleta
fija, buscar y compartir por URL.

**[V]** Bible Gateway ofrece 200+ traducciones, hasta 5 en paralelo, busqueda
avanzada y audio **sin obligar a crear una cuenta**.

**[V]** bible.com esta delante de una proteccion anti-bot de F5/Shape: una
peticion HTTP normal recibe una pagina de 3038 bytes titulada `Client
Challenge`, con un desafio de JavaScript y una cookie que caduca a los 10
segundos. No es un problema de la herramienta de rastreo: significa que
cualquier proxy corporativo, red con proteccion o navegador con extensiones
estrictas puede dejar a una persona sin acceso al texto.

**Decision.** Web primero no es una concesion por falta de recursos: es la
puerta que esta abierta. El lector web de `ab` lleva desde el primer dia
notas, marcadores, resaltados con color elegido por la persona, descarga para
leer sin conexion e instalacion como PWA. Eso es, literalmente, la lista de
cosas que el lider del mercado hace en movil y no en web.

**Decision.** Nunca delante del texto habra un desafio de JavaScript, un muro
de verificacion ni nada que dependa de que las extensiones del navegador
funcionen. Si una red esta bloqueada, se dice y se sigue leyendo lo que ya
este en el dispositivo.

---

## 2. Producto: las cuatro ausencias

Estas cuatro no son una lista de deseos. Cada una corresponde a la queja mas
repetida que se encontro en las tiendas de apps, y varias veces con cita
textual de un usuario de espanol.

### Sin anuncios

Es la queja numero uno en espanol, en todas las apps de una sola traduccion.
Con anuncios **dentro** de la Biblia, que es lo grave:

> *"la publicidad con sonido puede hacerte pasar un mal momento en la
> iglesia"*

> *"entorpece a cada rato la busqueda en la Biblia... cuando estas en la
> iglesia"*

Y el resultado de cobrar por quitarlos y no cumplir:

> *"PAGUE .99 PARA QUITAR LOS ANUNCIOS Y SIGUEN AHI. Intente comprar de nuevo
> o restaurar compra y NO LOS QUITA."** (etiquetado como "SCAM")

**[V]** A esto se suma que la propia aplicacion movil de Logos, que es de pago,
lleva anuncios. De un cliente que lleva gastados cientos de dolares:

> *"As much money as I've spent on this software, I am riddled with ads and
> they just made it so that you can't turn them off. My dashboard is unusable
> now because there are so many ads."*

La regla de `AGENTS.md` no es una preferencia de gusto: es la respuesta a esa
frase.

### Sin compras

Ninguna app gratuita del mercado en espanol es creible. Todas son clones de
una traduccion con banner y video interstitial, y ninguna tiene lo que la
gente pide. **[R]** Hay usuarios que tratan el cobro por una traduccion como
una ofensa moral:

> *"Que para leer la Biblia haya que pagar... estan vendiendo la presencia de
> Dios... deberian no cobrar por las versiones; si quieren cobrar, cobren los
> mapas, diccionarios, devocionales."*

Ademas, el problema tecnico: **[V]** si alguna vez se cobrara, la licencia de
YouVersion Platform lo prohibe expresamente, porque exige que la experiencia
final sea gratuita, sin publicidad y sin ingresos "directa o indirectamente".

### Sin cuentas

**[V]** Todos los lectores bien tratados dejan leer sin cuenta: STEPBible,
Sefaria, BibleOL, Bible Gateway. Bolls deja la cuenta solo para sincronizar y
no esconde nada detras de ella.

Una cuenta es una puerta por la que se pierde el acceso a lo propio. **[R]**
Varias resenas de una estrella de Accordance, todas sobre lo mismo: no se
puede crear la cuenta, el boton de ayuda abre un foro y no hay forma de
cambiar la contrasena. **[R]** En YouVersion, un cambio de politica de
privacidad en 2026.expuso a una persona a perder 8 anos de planes completados.
El fallo mas barato de arreglar y el mas vergonzoso posible es, justamente, no
tener cuentas.

### Sin telemetria

Por acuerdo propio, y porque leer la Biblia es un acto privado.

---

## 3. Lectura

### La referencia es la URL

**[V]** El mejor esquema de URL de pasaje de la categoria es el de YouVersion:
`bible.com/bible/{id}/{BOOK}.{CH}.{V}.{VERSION}`, que ademas **selecciona** el
primer versiculo del rango al abrirse.

`ab` copia el modelo: una URL canonica por pasaje, legible por una persona,
estable, y compartible. En movil, un enlace a "Juan 3:16" abre la app con ese
versiculo ya resaltado.

### El historial del navegador es sagrado

Es el fallo numero uno de las aplicaciones de una sola pagina en la web. La
regla que sale de la evidencia:

- **La pila de pantallas vive en la URL.** Recargar, compartir y "atras"
  funcionan.
- **Un estado que no merece historial va en `replaceState`**: cambiar de
  traduccion, cambiar el tamano de letra, resaltar. No ensuciar el historial.
- **Un capitulo si merece historial** va en `pushState`.
- El servidor tiene que servir la aplicacion para **toda** ruta bajo la base.
  Olvidar esto es la razon de que los enlaces profundos den 404.

En una aplicacion movil el equivalente es la misma regla: **el orden de las
pantallas y los gestos se congela.** Es la queja mas repetida de Logos, con una
estrella:

> *"Hate is not a strong enough word for this update... I accidentally clicked
> on an AI search tool and now I cannot even find my library on my iPad."*

Un lector de Biblia se usa todos los dias durante anos. Mover donde estaba la
biblioteca cada tres meses es una traicion a ese uso.

### En paralelo, sin limites, y sin que estorbe

**[V]** Bible Gateway llega a 5 traducciones; Bolls, ilimitadas. **[V]** El
redisenio de Bible Gateway de 2020 empeoro justo eso: la barra lateral de
referencias se comio el ancho de lectura y con 3 o 4 versiones el texto dejo
de ser legible. Un pastor que prepara sermones en paralelo lo describio como
*"more difficult, not easier... which is ironic considering what Bible Gateway
claims."*

**Decision.** En pantallas anchas, tantas versiones en paralelo como quepan.
La interfaz de referencia **nunca** se lleva el ancho de la columna de lectura:
en paralelo, la lectura manda; las referencias se abren encima, debajo o en un
panel que la persona abre y cierra.

### Tipografia: todo se toca

**[V]** El conjunto que respeta la gente: tamano, familia, alto de linea, color
de fondo, y los interruptores de versiculos, capitulos, titulos, notas al pie,
referencias cruzadas, letras rojas y desplazamiento continuo. El fondo claro
arrastrando el modo oscuro del navegador entero es un gesto bueno: una
decision, dos efectos.

En `ab` los ajustes de lectura son **persistentes y por-version**: cada
traduccion puede tener su propio tamano de letra, porque el KJV en letra
grande y el RVR en letra pequena se leen distinto.

### Copiar y pegar nunca puede fallar

**[R]** La funcion de copiar de Bible Gateway en iOS **eliminaba palabras y
espacios** al pegar, con el consiguiente riesgo de citar mal la Escritura. Un
lector que copia un versiculo corrupto es peor que inutil: propaga el error a
un sermon.

Es el fallo mas grave que puede tener esta categoria de aplicacion, y el mas
facil de no comprobar. `ab` lo prueba de forma explicita.

### Las unidades de altura

**[V]** Entre 2015 y 2016 Apple y Google decidieron que `100vh` fuera el viewport
**con la barra de direcciones recogida**. El contenido dimensionado a `100vh`
se sale por la altura de la barra cuando esta visible, y en movil se nota
siempre.

- `100svh` para lo que no debe moverse: cabecera, columna de lectura, pie.
- `100dvh` solo para lo que ocupa todo: hojas y dialogos a pantalla completa.
- **Declarar `vh` antes que `svh`/`dvh`**, porque todavia hay Android WebView
  viejo.
- `viewport-fit=cover` con `env(safe-area-inset-*)` para la muesca.
- `overscroll-behavior-y: contain` para que tirar de la pantalla no recargue la
  pagina a mitad de un capitulo.

En Flutter esto se resuelve con el `MediaQuery` del sistema, pero el criterio
es el mismo y hay que dejarlo escrito para que nadie lo deshaga.

### La instalacion hay que ofrecerla, no esperarla

**[V]** El aviso de instalacion de una PWA no aparece solo, y si falta una
pieza (HTTPS, manifiesto valido, service worker con `fetch`) **no falla: no
aparece nunca y sin error**. Y en iOS no existe `beforeinstallprompt`: hay que
detectar Safari y decir con palabras que se pulses Compartir y luego "Anadir a
pantalla de inicio".

**Decision.** La aplicacion ofrece su propio boton de instalar, captura el
`beforeinstallprompt` en Android y Chrome, y en Safari de iOS muestra una linea
de instruccion que desaparece cuando la app ya corre en modo standalone.

**Decision.** Se avisa de "descargado para leer sin conexion", con un estado
visible. En iOS la PWA no da ninguna senal de estar lista y la gente cree que
esta rota.

**Decision.** Cuando hay una version nueva se muestra un cartel
*"hay una version nueva, toca para actualizar"* que aplica el cambio. **No**
se hace `skipWaiting()` por la fuerza: recargar debajo de los dedos de alguien
que esta escribiendo una nota es perder su nota.

---

## 4. Resaltados: el sistema de Accordance

Es la mejor funcion de las dos apps de pago, y ninguna app gratuita se acerca.
Cuesta poco: son cinco propiedades sobre una tabla.

1. **Estilos definidos por la persona**: color, intensidad, forma y **patron**
   ("subrayado punteado con borde rojo vivo").
2. **Varios ficheros de resaltados** que se cambian de un clic. Un conjunto
   "temas teologicos", otro "devocion personal", otro "preparacion de clase". El
   mismo versiculo puede quedar marcado de tres maneras sin ensuciarse.
3. **Por referencia, no por traduccion**: se marca en una version y aparece en
   todas. Cambiar de version nunca hace perder lo marcado.
4. **Buscables**: buscar por estilo devuelve todos los versiculos marcados asi.
   Es un indice tematico personal hecho a mano.
5. **Reversibles**: borrar y rehacer sin miedo.

**Decision.** Las cinco. Y una sexta, nuestra: **el resaltado se guarda en el
dispositivo antes de intentar nada con la nube.** Nada de lo que la persona
escribio depende de que haya red.

---

## 5. Navegacion y estudio

### Los botones que se copian

- **Selector de version desde la cabecera del lector**, con filtro mientras
  se escribe e indicador de si hay audio. Comparar versiones sin salir de la
  lectura es la interaccion mas valiosa de una app de Biblia. **[V]**
- **Resumen de cada capitulo en el selector de libros** (Bible Gateway). Es la
  mejor idea de localizacion de referencias que se ha visto: resuelve "se que
  estaba en el cap. 12 de algo, pero no de que".
- **El panel de ideas de Logos**: un trozo de comentario que vive **dentro** del
  panel de la Biblia y se actualiza con el scroll. Cero coste de navegacion, y
  es lo primero que quiere alguien que lee en el telefono. En movil, el
  comentario va **en linea**, no en un panel de al lado: en pantalla estrecha
  el panel de al lado se come el texto.
- **Tres niveles de interaccion con el texto** (Accordance): un toque da la
  definicion, dos toques abren el selector de herramienta, "Live Click" busca en
  toda la biblioteca. Revelacion progresiva en tres pasos, y el tercero sigue
  siendo opcional.
- **El autocompletado de comandos de Accordance**: el menu va diciendo que
  comandos existen mientras escribes. Quien sabe usa linea de comandos; el
  resto tiene un menu. Hacer las dos cosas a la vez no lo hace nadie mas.
- **El escaner de referencias de Logos**: la camara ve "Juan 3:16" en una pagina
  impresa y devuelve una lista de pasajes. Es un detalle pequeno y nadie mas
  lo tiene. Entra cuando haya camara; en web, cuando los navegadores lo
  permitan.
- **La ambiguedad de versificacion se muestra, no se tapa** (Accordance). En
  algunos salmos el encabezado hebreo ocupa dos versiculos, y el mismo numero
  no significa lo mismo en cada traduccion. Accordance lo resuelve mostrando
  los paneles en paralelo en vez de dejar un numero en blanco. `[V]`

### Busqueda

La busqueda **por palabra** es la base y no se toca nunca.

- Un boton de alcance (capitulo, versiculo, frase, parrafo, libro) y otro de
  rango (Antiguo Testamento, Nuevo Testamento). **[V]**
- Busqueda por estilo de resaltado, que convierte el marcado en indice. **[V]**
- **[V]** En paralelo, busqueda **semantica** (Bolls la ofrece desde julio de
  2026: se busca por significado y cae a lexis si pides literalidad). Es la
  funcion mas avanzada de cualquier lector gratuito. Entra como **un modo
  mas**, nunca en lugar de la busqueda por palabra.

### Lo que Logos se hizo mal y no hay que imitar

- **La IA delante de la busqueda determinista.** En Logos la busqueda
  inteligente paso a ser el sitio por defecto y la precisa quedo escondida:

  > *"The AI addition interferes with word searches and, for the mobile edition,
  > eliminated the tabs which made book selection simple."*

  **Decision.** La IA puede **anadirse**. No puede quitar lo que habia ni ponerse
  delante. En `ab` hoy no hay IA; cuando la haya, es un boton mas.

- **Creditos de IA medidos con un contador permanente** en la barra. En una app
  de lectura eso es un recordatorio permanente de que leer cuesta dinero.

- **Meter una herramienta basica detras del plan mas caro y del escritorio a
  la vez.** El morfograma y el interlineal solo en plan Max y solo en escritorio
  es lo mas criticado de todo el software biblico moderno.

- **Una matriz de precios que se multiplica sola**: 8 niveles de biblioteca x 4
  trayectorias x 11 denominaciones x ano de edicion. Un reviewer que la
  promociona escribe *"Their offerings look too complicated."*

- **Exigir red para buscar lo que ya esta en el dispositivo.** **[V]** Los
  propios manuales de Logos reconocen que el movil *"is highly dependent on your
  internet connection"* y recomiendan un portatil para trabajar sin conexion.
  Se lee en avion, en un sotano, en una iglesia con mala senal, y en los paises
  donde existe YouVersion Lite. Eso no es una inconvenience: es el caso normal.

- **Fragmentacion de funciones entre plataformas vendida como "el mismo
  producto".** La propia matriz de Logos admite lo que el movil no tiene.

---

## 6. Datos: la parte que no se negocia

### El precedente que manda

**[V]** Accordance 14.1, de septiembre de 2025, **quito la sincronizacion con
Dropbox sin sustituto listo**. El sustituto, "Accordance Sync", sigue en beta
abierta y, segun la documentacion del 15 de agosto de 2026, **solo sincroniza a
mano**, con 100 MB de tope total. **[R]** Dos anos despues:

> *"I have lost all of my highlighted verses on the desktop app... The notes
> on my iPhone app are all messed up."*

> *"Sync has been broken for MONTHS... I currently cannot sync notes or
> highlights between devices."*

**Decision.** En `ab`, las notas, los resaltados y los marcadores se escriben
primero en un almacenamiento local **que es un fichero SQLite normal, en un
sitio conocido y con un esquema legible**. Cualquiera con un cliente de SQL lo
abre. Exportarlos no requiere cuenta, ni nube, ni conexion.

**Decision.** La sincronizacion, si llega, **solo anade**. Si el destino falla,
la escritura local ya esta hecha y se queda. Si la nube no existe, no se
pierde nada.

**Decision.** **Nunca se retira una traduccion, ni un libro, ni una funcion de
la que alguien dependa, sin avisar y sin dejar el dato.** Es la queja
catastrofica mas repetida en espanol:

> *"que mal, quitaron las 4 versiones que estaban habilitadas y solo dejaron
> activa la NTV... perdi todo lo que tenia senalado."*

> *"Un dia si hay versiones y otro dia no. No jueguen con esto."*

> *"ya NO HAY... las versiones se eliminan y los marcadores se borran."*

**Decision.** Cuando un modulo desaparece del catalogo, la app lo dice y deja
leer lo ya descargado. El texto descargado es de la persona.

### Lo que nadie mas hace

**[V]** Los tramos largos sin actualizar. Entre la version 14 de Accordance
(noviembre de 2022) y la 14.1 (septiembre de 2025) hay tres anos, y la ficha
de la app avisa a la gente de que **no actualice el sistema operativo** hasta
que salga la 14.2. Una app de lectura que pasa tres anos sin actualizarse pierde
a la gente.

**Decision.** Un cambio al mes, aunque sea pequeno. Y cada version dice
exactamente que ha cambiado.

**[V]** Exportar e importar. Accordance exporta la biblioteca a PDF y a RIS, e
importa notas de BibleWorks. Si los datos de la persona estan atrapados en un
formato, no son suyos.

---

## 7. Lo que queda sin verificar

- **`crudo-02-stepbible-mybible.md` no esta todavia.** El informe sobre el
  sistema de modulos y de descarga de STEPBible y MyBible sigue en curso. Es el
  que mas directamente afecta a como `ab` presenta su biblioteca de modulos, y
  cuando termine se anade a este documento antes de escribir los changes de
  OpenSpec que dependan de el.
- Los precios de Bible Gateway que circulan en blogs ($4,99/mes) estan
  caducados. El dato bueno es $6,99/mes y $69,99/ano, de su propia pagina de
  suscripcion. Lo que importa para `ab` es la conclusion de fondo: la
  suscripcion que se compra es para mas contenido, y ese contenido no es
  nuestro.
- No se pudo verificar nada de los foros de Logos ni de `reddit.com/r/LogosBibleSoftware`
  (403). Nada de lo que hay aqui viene de ahi.
- Los "cincos estrellas" y los indices de seguridad que aparecen en las fichas de
  las tiendas son de generadores automatizados. No se usan como criterio.