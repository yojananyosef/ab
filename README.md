# AB

Lector de Biblia de dominio publico, en castellano, para Latinoamerica
hispanohablante. Web primero. Sin anuncios, sin cuentas, sin pagar, sin
telemetria.

Este repositorio es **solo la aplicacion**. El catalogo de recursos vive en el
repositorio hermano `aa`, que lo publica como API. `ab` lo consume; no sabe
construirlo ni decidir que es publicable.

## Que hay aqui y que no

| Aqui (`ab`) | Alli (`aa`) |
| --- | --- |
| Descargar un modulo y comprobar su hash | Construir el modulo |
| Leer un modulo con SQL | Decidir si una Biblia es de dominio publico |
| Elegir, buscar, marcar, anotar, sincronizar | Publicar el recurso y sus sumarios |
| Decidir que version se muestra al usuario | Saber de antemano que Biblias existen |

Si este repositorio contiene una lista de textos, alguien cruzo la frontera.

## Version web

<https://yojananyosef.github.io/ab/>

Se publica con GitHub Pages desde `main`, en cada push. El workflow de
`.github/workflows/ci.yml` ejecuta `flutter analyze`, `flutter test` y
`flutter build web` **antes** de desplegar, y comprueba que el motor SQLite
viaja en el paquete: si faltara, la app arrancaria y fallaria al abrir el
primer modulo, que es el peor sitio para descubrirlo.

## Catalogo

<https://yojananyosef.github.io/aa/latest.json> es el puntero flotante del
catalogo. De ahi sale el manifiesto, y de ahi se baja cada modulo.

**Cada modulo declara DOS direcciones y hay que saber cual va donde.**

| | |
| --- | --- |
| `browserUrl` | la de **navegador**. Es la que usa la app en web |
| `downloadUrl` | la de **nativo**. Es la de la release de GitHub |

Y no es "cualquiera de las dos": en la release de GitHub **no** hay cabecera
`Access-Control-Allow-Origin` en la respuesta final, y un navegador que pide
`.../releases/download/...` falla con `Failed to fetch`. GitHub Pages si la
manda, tambien en los binarios, y por eso `browserUrl` apunta ahi.

Medido el 3 de octubre de 2026; el razonamiento y las peticiones estan en
`docs/investigacion/transporte-cors.md`.

Y EN WEB LA app no baja **nada** del origen, porque los modulos ya estan en el
almacenamiento del navegador: se baja la primera vez y se recuperan de ahi. En
la comprobacion en navegador del grupo 8, dos ejecuciones seguidas con el mismo
perfil bajaron 22.544.384 bytes y 0.

El repositorio hermano es <https://github.com/yojananyosef/aa>.

## Documentacion

- `AGENTS.md` - reglas del repositorio, para quien trabaje aqui.
- `docs/investigacion-ux.md` - que se aprendio de las apps que ya existen.
- `docs/investigacion/crudo-*.md` - informes de referencia, con citas.
- `docs/investigacion/transporte-cors.md` - por que la release de GitHub no se
  puede leer desde un navegador y Pages si, medido con peticiones de verdad.
- `docs/investigacion/sqlite-en-navegador.md` - prueba de que un `.amod`
  real se abre en el navegador, con las cifras del spike y las de la
  comprobacion automatica distinguidas.
- `scripts/comprobar-en-navegador.sh` - la comprobacion en navegador de la
  aplicacion entera. **No** la sustituye `flutter test`: esta lee lo que la
  propia aplicacion escribe en el DOM, porque Flutter pinta en un canvas.
- `openspec/` - los cambios del proyecto y sus especificaciones.

## Desarrollo

```bash
flutter pub get
flutter analyze      # sin avisos
flutter test         # verde
flutter build web
```

Plataformas, en este orden: web, Android, Linux, Windows. iOS no se planifica
y ningun cambio depende de que exista.

## Licencia

Codigo bajo MIT. Los textos que se descargan del catalogo **no** son codigo de
este repositorio: cada modulo declara sus propios terminos en el campo `info` de
su cabecera, y la app los ensena antes de dejar leer, sin esconderlos en un menu.

Que se ensenen es un requisito del change `phase-1-biblioteca`, no una promesa
de este texto: `specs/lector/spec.md` lo recoge con escenarios.