// Proposal

## Why

Preguntado "¿que falta?", y la respuesta corta es: **los resaltados y las notas del usuario no
existen**. No hay modelo, no hay almacenamiento y no hay pantalla.

```
class Resaltado     -> no existe
class NotaUsuario   -> no existe
```

Y es la mayor ausencia de todo el proyecto por dos motivos a la vez:

1. `AGENTS.md` dice que **perder datos del usuario es el peor fallo posible**, con las
   reseñas de Accordance sobre la sincronizacion rota como prueba. Aqui no hay nada que
   perder porque no hay nada.
2. `docs/investigacion-ux.md` dice del sistema de resaltados de Accordance que **"cuesta muy
   poco de implementar y ninguna app gratuita se acerca"**.

Y es la unica funcion que ademas crea un usuario: lo demas --descargar, leer, buscar-- lo hace
tambien MyBible, y esto no.

// ============================================================================
// EL PROBLEMA DE VERDAD: NO HAY SINCRONIZACION Y ESO HAY QUE RESOLVERLO
// ============================================================================
//
// Este proyecto, por decision escrita, **no tiene cuentas ni sincronizacion**. Y con eso, un
// resaltado guardado en el almacenamiento del navegador **se pierde** en cuanto la persona
// borra los datos del sitio, cambia de navegador o cambia de telefono. Que es exactamente la
// trampa de Accordance, textual:
//
//     "I have lost all of my highlighted verses on the desktop app... The notes on my iPhone
//     app are all messed up."
//
// Sin cuentas no hay nube. Pero **sin nube todavia se puede sacar lo tuyo**, y por eso la
// obligacion que sale de aqui no es "sincronizar", que no se va a hacer:
//
// ============================================================================
// LA REGLA DE ESTE CHANGE
// ============================================================================
//
// **Todo lo que escribe la persona tiene que poder salir del dispositivo.**
//
// Y NO ES "EXPORTAR" COMO ADICION, ES LA CONDICION PARA QUE EXISTA. Si se puede resaltar y no
// se puede sacar, el resaltado esta a una borrada de distancia de perderse y la app no puede
// decir lo contrario. Es la misma regla que ya esta escrita en `AGENTS.md` para la
// comprobacion en navegador --"una comprobacion que puede pasar sin comprobar lo nuevo es peor
// que no comprobar"--, subida de nivel: **un dato que no se puede recuperar es peor que un
// dato que no existe**, porque ademas engaña.
//
// Y EL FORMATO DE LA SALIDA ES UN FICHERO `.json` QUE LA PERSONA GUARDA, con un
// `formato` y una `version` como los del `.amod`. Que sea un fichero y no un boton de
// "sincronizar" es lo que hace que funcione sin cuentas: el fichero va por donde quiera la
// persona, que es lo unico que hay.

// ============================================================================
// Y LO QUE SE COPIA DE ACCORDANCE, QUE ES LO QUE LO HACE BUENO
// ============================================================================
//
// Del documento de investigacion, cinco cosas:
//
//   1. **Estilos definidos por la persona**: color, intensidad, forma y **patron**. No cinco
//      colores fijos, sino cinco estilos con nombre que se pueden renombrar.
//   2. **Varios ficheros de resaltados** intercambiables de un clic: un conjunto "temas
//      teologicos", otro "devocion personal", otro "preparacion de clase". El mismo versiculo
//      marcado de tres maneras sin ensuciarse.
//   3. **Por referencia y no por version**: se marca en una traduccion y aparece en todas.
//   4. **Buscables por estilo**: buscar por estilo devuelve todos los versiculos marcados asi.
//      Un indice tematico personal hecho a mano.
//   5. **Totalmente reversibles**.
//
// Y LA 3 Y LA 5 SON LAS QUE CONDICIONAN EL MODELO, y por eso van las primeras en el codigo: un
// resaltado que guarda el **texto** en vez de la **referencia** no aparece al cambiar de
// traduccion --que es justo lo que quiere quien lee en dos versiones-- y un resaltado que no se
// puede quitar del todo es una marca permanente en el texto.

// ============================================================================
// LO QUE HACE ESTE CHANGE Y LO QUE NO
// ============================================================================
//
// **Hace**: el modelo, el almacenamiento con plazo, la importacion y la exportacion, y poner y
// quitar un resaltado desde el texto, en cinco estilos.
//
// **No hace, y queda escrito**: la pantalla de gestion, la busqueda por estilo, los ficheros
// de resaltados intercambiables, y las notas de texto libre junto al resaltado. Cada uno es un
// change, y el orden es el de `tasks.md`.