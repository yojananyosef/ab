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

## Documentacion

- `AGENTS.md` — reglas del repositorio, para quien trabaje aqui.
- `docs/investigacion-ux.md` — que se aprendio de las apps que ya existen.
- `docs/investigacion/crudo-*.md` — informes de referencia, con citas.
- `docs/investigacion/transporte-cors.md` — por que la web todavia no puede
  descargar un modulo, medido en navegador real.
- `openspec/` — los cambios del proyecto y sus especificaciones.

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
este repositorio: cada modulo declara sus propios terminos en el campo `info`
de su cabecera, y la app los muestra antes de dejarlo leer.