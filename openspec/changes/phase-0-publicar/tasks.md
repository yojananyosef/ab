# Tasks

## 1. Repositorio

- [ ] 1.1 Crear `yojananyosef/ab` como repositorio publico, verificar con `gh repo view yojananyosef/ab` que `visibility` es `PUBLIC` y que no hay `.gitignore` de plantilla que estorbe
- [ ] 1.2 Anadir `origin` y subir `main`, verificar con `git ls-remote origin` que la rama existe y que el commit remoto es el mismo hash que el local
- [ ] 1.3 Anadir la licencia MIT en `LICENSE`, con la exclusion explicita de que los textos descargados del catalogo no son codigo de este repositorio; verificar que el fichero existe y que `README.md` lo menciona
- [ ] 1.4 Publicar la v0.0.1 con el mismo esquema que `aa`: tag inmutable mas `latest.json` flotante; verificar que `latest.json` descargado desde la URL real resuelve

## 2. Version web con GitHub Pages

- [ ] 2.1 Anadir `.github/workflows/pages.yml` que compile con `flutter build web --base-href=/ab/`, suba el artefacto con `actions/upload-pages-artifact` y lo despliegue con `actions/deploy-pages`; verificar que el workflow corre en GitHub Actions y sale en verde
- [ ] 2.2 Anadir el `404.html` que Pages necesita para que los enlaces profundos funcionen, porque Pages devuelve 404 en cualquier ruta que no exista en vez de servir el documento de entrada; verificar con una peticion real que `/ab/leer/KJV2006` devuelve el documento de la aplicacion y no la pagina de error de GitHub
- [ ] 2.3 Comprobar que `sqlite3.wasm` llega al sitio publicado y **NOT** se sirve con una cabecera de contenido que rompa WebAssembly; verificar con `curl` a la URL real que devuelve 200 y `content-type: application/wasm`
- [ ] 2.4 Medir si la cabecera `Access-Control-Allow-Origin` que Pages envia permite leer un `.amod` desde el navegador, y dejar el resultado escrito en `docs/investigacion/transporte-cors.md` con la cifra y la fecha, tanto si funciona como si no
- [ ] 2.5 Anadir al README la URL del sitio y que Pages es el despliegue; verificar que el enlace es alcanzable y devuelve 200

## 3. Comprobaciones finales

- [ ] 3.1 `flutter analyze`, `flutter test` y `flutter build web --base-href=/ab/` los tres en verde, en ese orden; verificar que los tres salen con codigo 0
- [ ] 3.2 Abrir la URL publicada en Chrome headless y comprobar que la aplicacion arranca y pinta; verificar que la consola no tiene errores
- [ ] 3.3 Guardar en `docs/investigacion/transporte-cors.md` la conclusion de si GitHub Pages puede servir los modulos, y no dar por hecho que por enviar cabeceras de origen cruzado ya se puede; verificar que la conclusion esta apoyada en una peticion con `Origin:` de verdad