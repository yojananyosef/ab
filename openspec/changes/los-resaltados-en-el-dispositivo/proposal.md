# Proposal

## Why

Los resaltados **no se guardan**. En `main.dart` se crea el view model **sin almacen**:

```dart
_resaltados = ResaltadosViewModel();
```

y eso cae en `AlmacenamientoDeResaltadosEnMemoria`. Se marca un versiculo, se ve marcado, y
al recargar desaparece.

Y ES LA PEOR CLASE DE FALLO DE ESTE REPOSITORIO, por lo escrito en `AGENTS.md`: lo que ha
escrito la persona «no es un estado descartable». Un resaltado perdido es trabajo.

Peor todavia: **parece que funciona**. Marca, se ve, no da error, no avisa. La perdida
ocurre al cerrar y no dice nada. Y se descubre usando la aplicacion dos veces, que es
justo cuando ya se ha confiado en que funciona.

Y ESTA EN EL `main` DESPLEGADO. El change `los-resaltados` se merging con el modelo, el
plazo de cinco segundos, la exportacion y veinticinco pruebas, y **sin esta pieza**. La
comprobacion que faltaba es una sola, y hay que escribirla **antes** que esto: comprobar
que el view model de la aplicacion **no** se puede construir sin almacen.

---

## Y POR QUE UNA BASE DE DATOS **PROPIA**, Y NO UN ALMACEN MAS DE LA DE MODULOS

En el fichero de modulos hay un fallo ya documentado que decide esto:

> abrir dos veces a la vez hace que la segunda se quede esperando un `onupgradeneeded` que no
> va a llegar: el primer `open` resuelve el primero y el segundo se queda colgado para
> siempre.

Anadir un almacen a la base `ab` obliga a subir `_versionDb` de 1 a 2, y esa subida **es** un
`onupgradeneeded`. Con la aplicacion abierta en dos pestanas --que es lo normal en un
lector-- la segunda se queda colgada esperando una transaccion de version que no va a
llegar. Es decir: **anadir los resaltados al mismo sitio donde viven los modulos rompe la
aplicacion** para quien tenga dos pestanas.

Y ADEMAS hay una razon ya escrita en la interfaz de los resaltados, y aqui con mas fuerza
por ser la parte de abajo: `AlmacenamientoDeModulos` tiene una accion de limpieza --«borrar
los modulos que no uso para ganar sitio»-- y `AGENTS.md` prohibe que una accion de limpieza
limpie tambien el trabajo. Con **dos bases distintas** esa accion no puede tocar los
resaltados ni por accidente: `deleteDatabase('ab')` no ve `ab-resaltados`.

Y EL COSTE ES UN FICHERO MAS, con el patron ya escrito y probado.

---

## LO QUE HACE ESTE CHANGE

- `AlmacenamientoDeResaltadosWeb`, con su propia base: `ab-resaltados`, y dos almacenes,
  `resaltados` y `estilos`
- **`main.dart` le pasa el almacen de verdad**, que es la linea que faltaba
- Un almacen **nativo** con la misma forma, para que Android, Linux y Windows no se queden
  sin la funcion aunque aqui no se puedan comprobar
- Una prueba que comprueba que **el view model de la aplicacion** lleva almacen, que es la
  comprobacion que faltaba y que evita que esto vuelva a pasar en silencio