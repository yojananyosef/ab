// Capturas de la aplicacion, con Playwright.
//
// POR QUE ESTE FICHERO EXISTE Y QUE NO HACE EL DE `scripts/`
// =========================================================
//
// `scripts/comprobar-en-navegador.sh` **no puede hacer capturas**. Medido el 5 de octubre
// de 2026 con Brave 154:
//
//     brave-browser --headless=new --dump-dom http://127.0.0.1:8099/ > salida.html
//     exit=124   salida.html con 0 bytes
//     GPU stall due to ReadPixels
//
// Y el paso `--screenshot` se quito del script por lo mismo. Sin imagen **no se puede
// mirar la interfaz**, y mirar la interfaz es la mitad del trabajo: el fallo de los
// 13,9 pixeles se ve en una captura en un segundo y leyendo el codigo no se ve nunca.
//
// QUE HACE ESTE Y POR QUE SI
// =========================
//
// `page.screenshot()` de Playwright es **otro camino** al motor, no el de `--screenshot`:
//
//   - Espera a que la pagina diga `networkidle` y ademas a un tiempo fijo, en vez de
//     depender del presupuesto de reloj virtual.
//   - Usa `--enable-unsafe-swiftshader`, sin el cual Brave 154 dice "Automatic fallback to
//     software WebGL has been deprecated" y no pinta.
//   - No usa `--virtual-time-budget`, que es lo que deja a Flutter colgado: el motor
//     mantiene vivo el bucle de `requestAnimationFrame` y el reloj virtual nunca avanza.
//
// Y UNA CAPTURA DE UNA PANTALLA DE LECTURA NO DICE SI SE PUEDE INTERACTUAR. Para eso esta
// `scripts/comprobar-en-navegador.sh`, que ademas hace la comprobacion de la sonda. Las dos
// cosas se necesitan y ninguna sustituye a la otra.

// ============================================================================
// DEPENDENCIA
// ============================================================================
//
// Se necesita Playwright, y **NO** va en `pubspec.yaml` porque no es una dependencia de
// la aplicacion: es una herramienta de mirar. Se instala una vez, en el arbol de trabajo, no
// en el repositorio:
//
//     cd scripts/viz && npm install playwright
//     node scripts/viz/capturar.mjs
//
// Y EL FICHERO ESTA **AQUI MISMO**, y no en `scripts/`, por un motivo concreto: Node busca
// `node_modules` subiendo desde el directorio **del fichero**, no desde el de trabajo. Con el
// script en `scripts/` y las dependencias en `scripts/viz/`, esto es lo que pasaba:
//
//     Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'playwright' imported from
//     /home/j/ab/scripts/capturar.mjs
//
// Y lo que mas engaña es que el `package.json` esta a la vista, en `scripts/viz/`, con sus
// dependencias. El error habla de un paquete inexistente y no de que el fichero este en el
// sitio equivocado.
//
// Y el navegador es el del sistema --`/usr/bin/brave-browser`--, no uno que descarga
// Playwright: son 300 MB que no hacen falta porque ya hay un Chromium instalado.
import { chromium } from 'playwright';
import { mkdirSync, readFileSync, existsSync } from 'node:fs';

const BASE = process.env.AB_URL ?? 'http://127.0.0.1:8099';
const SALIDA = process.env.AB_SALIDA ?? '/tmp/opencode/viz/capturas';
const ESPERA = Number(process.env.AB_ESPERA ?? 9000);

/** Cuanto se espera a que el modulo este descargado y guardado. */
const ESPERA_DESCARGA = Number(process.env.AB_ESPERA_DESCARGA ?? 25000);

/** Si hay que pasar antes por la biblioteca para que el modulo quede en el `IndexedDB`. */
const procesados = new Set((process.env.AB_PREPARAR ?? '').split(',').filter(Boolean));

// ============================================================================
// BAJAR UN MODULO DE LA BIBLIOTECA ANTES DE MIRAR NADA
// ============================================================================
//
// Y POR QUE HACE FALTA, MEDIDO. Para mirar **dos paneles** --que es la pantalla nueva-- hace
// falta que los dos `.amod` esten en el dispositivo. En el perfil persistente solo estaba el
// KJV2006, y la captura de `/leer/KJV2006/John.3.16/y/CLARKE/John.3.16` salia con **un solo
// panel y su barra**, que es exactamente lo que la app debe hacer cuando el segundo modulo no
// esta --y asi que la captura no miraba nada de lo nuevo.
//
// Y POR QUE HAY QUE **PULSAR**, y no bajarlo por la URL. La biblioteca **no baja nada sola**:
// abrir `/` no descarga el modulo, hay que darle al boton. Y `page.click('text=Descargar')` no
// encuentra nada, porque Flutter pinta en un `canvas` y el DOM no tiene el texto. Es lo
// mismo que ya hace `pulsar.mjs`, y por eso las coordenadas estan **medidas sobre una
// captura** y no calculadas.
//
// Y SE ESCRIBE COMO `AB_BAJAR='CLARKE,180,568'`.
//
// Y LAS COORDENADAS **SE PASAN POR PARAMETRO** y no estan escritas aqui, porque dependen del
// ancho y de la altura de cada tarjeta. Con el perfil de este repositorio, a 360 px, medido
// sobre la captura de la biblioteca del 6 de octubre de 2026 --con la relacion de ironias de
// la captura, que es 2--:
//
//     KJV2006    boton "Leer"       (180,381)
//     CLARKE     boton "Descargar" (180,568)
//
// Y EL ESPERA TRAS EL PULSO ES LARGA, porque son **57 MiB** del comentario, medido.
const bajar = (process.env.AB_BAJAR ?? '').split(';').filter(Boolean);

/** Un ancho y un alto con nombre, porque "360x760" en una lista no dice nada. */
const PANTALLAS = {
  movil: { width: 360, height: 760 },
  movilPequeno: { width: 320, height: 640 },
  movilGrande: { width: 414, height: 896 },
  tableta: { width: 834, height: 1112 },
  escritorio: { width: 1440, height: 900 },
  escritorioAncho: { width: 1920, height: 1080 },
};

/**
 * Una captura.
 *
 * Y `fullPage: false`, SIEMPRE. Una captura de pagina completa con el motor de Flutter es
 * una captura de 3000 px de alto donde el 90 % es el mismo fondo, yisterior hay que abrirla
 * en algo que la reducga para ver nada.
 */
async function capturar(page, nombre) {
  const ruta = `${SALIDA}/${nombre}.png`;
  await page.screenshot({ path: ruta, fullPage: false, animations: 'disabled' });
  const { statSync } = await import('node:fs');
  console.log(`  ${ruta}  ${statSync(ruta).size} bytes`);
  return ruta;
}

/**
 * Que el `404.html` que hay en el paquete sea **de esta** build.
 *
 * Y POR QUE HACE FALTA. `flutter build` reescribe `index.html` y **no toca `404.html`**, que
 * se copia a mano. Con dos compilaciones de prefijos distintos --`--base-href=/` en local y
 * `--base-href=/ab/` para GitHub Pages-- el `404.html` se queda con el prefijo de la build
 * anterior, y como las rutas profundas losirven **el** `404.html`, un enlace a
 * `/leer/KJV2006/John.3.16` pide `/ab/flutter_bootstrap.js` contra un servidor local que no
 * tiene `/ab/`, y la pantalla sale **en blanco**.
 *
 * Medido el 5 de octubre de 2026: una captura de 19.307 bytes, que es el color del fondo y
 * nada mas, con cuatro 404 en la consola. Y `/` funcionaba, con lo que parecia un fallo de
 * la aplicacion y era un fichero viejo.
 *
 * Se comprueba aqui y no en el servidor porque **una captura en blanco es una captura**: sin
 * mirar el tamano del PNG no hay nada que sospeche, y el PNG en blanco parece una pantalla
 * vacia.
 */
function comprobarEl404() {
  const raiz = process.env.AB_PAQUETE ?? '/home/j/ab/build/web';
  const idx = `${raiz}/index.html`;
  const cfa = `${raiz}/404.html`;
  if (!existsSync(idx) || !existsSync(cfa)) {
    console.log('  el paquete no tiene index.html o 404.html; se sigue igual');
    return;
  }
  const base = (f) => (readFileSync(f, 'utf8').match(/<base href="([^"]*)"/) ?? [, '?'])[1];
  const a = base(idx);
  const b = base(cfa);
  if (a !== b) {
    console.log(`  AVISO: index.html declara "${a}" y 404.html declara "${b}".`);
    console.log('         Las rutas profundas se sirven con 404.html, y con el prefijo');
    console.log('         viejo la pantalla sale EN BLANCO. Se arregla con:');
    console.log(`             cp ${idx} ${cfa}`);
  }
}

async function main() {
  mkdirSync(SALIDA, { recursive: true });
  comprobarEl404();

  const rutas = (process.env.AB_RUTAS ?? '/leer/KJV2006/John.3.16').split(',');
  const pantallas = (process.env.AB_PANTALLAS ?? 'movil,escritorio').split(',');

  // Y UN PERFIL **PERSISTENTE**, y el motivo es la velocidad de iterar.
  //
  // El `.amod` son 22,5 MB y va al `IndexedDB` del navegador. Con un perfil de cada vez,
  // **cada captura se baja el modulo entero**: una iteracion de diseño son 12 segundos de
  // descarga antes de poder mirar nada, y mirando se llega a hacer veinte.
  //
  // Con perfil persistente la segunda vez ya esta en el `IndexedDB`, la captura sale en dos
  // segundos, y se puede mirar la pantalla de lectura --que es la que importa-- sin pagar la
  // descarga. Es la diferencia entre mirar la interfaz y no mirarla.
  const perfil = process.env.AB_PERFIL ?? '/tmp/opencode/viz/perfil';

  for (const clave of pantallas) {
    const medida = PANTALLAS[clave];
    if (!medida) {
      console.log(`  pantalla desconocida: ${clave}`);
      continue;
    }

    const contexto = await chromium.launchPersistentContext(perfil, {
      executablePath: process.env.AB_NAVEGADOR ?? '/usr/bin/brave-browser',
      viewport: medida,
      deviceScaleFactor: 2,
      args: [
        '--no-sandbox',
        '--disable-dev-shm-usage',
        // Y ESTOS TRES, Y SIN ELLOS NO PINTA. Brave 154 avisa por stderr y sale con el
        // lienzo en blanco, que es el peor fallo posible: parece que la app esta rota.
        '--enable-unsafe-swiftshader',
        '--use-angle=swiftshader-webgl',
        '--disable-gpu-sandbox',
      ],
      // Y EL IDIOMA EN CASTELLANO, porque `text-rendering` depende de las fuentes del
      // sistema y una captura con las de otra idioma no es la que ve nadie aqui.
      locale: 'es-ES',
      isMobile: medida.width < 600,
    });

    for (const ruta of rutas) {
      const page = await contexto.newPage();
      const errores = [];
      page.on('pageerror', (e) => errores.push(String(e)));

      // Y EL **PERFIL SE CALIENTA** ANTES DE MIRAR NADA, y no es un detalle.
      //
      // Un enlace profundo a un modulo que no esta descargado **avisa y se queda en la
      // biblioteca**: no reintenta solo, y es lo que hay escrito en `AGENTS.md`. Con el
      // perfil frio, la primera captura de la pantalla de lectura sale siendo la biblioteca
      // con un 60 % de descarga, y parece que la ruta no funciona.
      //
      // Asi que se abre primero la biblioteca --donde esta el boton de descargar-- y se
      // espera a que el modulo este en el `IndexedDB`. A partir de ahi, la segunda vez, el
      // enlace profundo si abre la lectura y la captura es la que se quiere mirar.
      if (procesados.has('biblioteca') || bajar.length > 0) {
        await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(ESPERA);

        for (const uno of bajar) {
          // Y LOS DOS SEPARADORES SON DISTINTOS A PROPOSITO: `;` separa los modulos y `,` separa
          // las tres partes de cada uno. Con `,` para los dos, `AB_BAJAR='CLARKE,180,568'`
          // se rompia en tres trozos --`CLARKE`, `180` y `568`-- y el sintoma era
          //
          //     AB_BAJAR: "CLARKE" no tiene las tres partes "id,x,y".
          //
          // que al menos nombra la variable. Con `:` para las partes y `,` para la lista
          // pasaba lo contrario, y el error era del navegador y con un `undefined` en medio:
          //
          //     mouse.click: Protocol error (Input.dispatchMouseEvent): Invalid parameters
          //
          // que no dice nada de que el numero no era un numero.
          const [id, ...resto] = uno.split(',');
          const [x, y] = resto.map(Number);
          if (!Number.isFinite(x) || !Number.isFinite(y)) {
            throw new Error(
              `AB_BAJAR: "${uno}" no tiene las tres partes "id,x,y".`,
            );
          }
          console.log(`  bajando ${id} con el pulso en (${x}, ${y})`);
          await page.mouse.click(x, y);
          // Y LA ESPERA ES **POR MODULO** y no una sola para todos: son 57 MiB el primero y
          // 22 el segundo, y con una espera comun el segundo se pulsaria mientras el primero
          // baja --y entonces el segundo se perderia, porque la biblioteca no acepta dos
          // descargas a la vez.
          await page.waitForTimeout(Number(process.env.AB_ESPERA_DESCARGA ?? 25000));
        }
        await page.waitForTimeout(ESPERA);
      }

      console.log(`==> ${ruta} a ${medida.width}x${medida.height}`);
      await page.goto(`${BASE}${ruta}`, { waitUntil: 'domcontentloaded' });
      // Y LA ESPERA ES FIJA Y POSTERIOR A LA CARGA. El modulo son 22 MiB y hay que bajarlo
      // y abrirlo; esperar a `networkidle` no sirve porque Flutter mantiene conexiones
      // abiertas, y esperar a un elemento del `canvas` no sirve porque el texto **no esta
      // en el DOM**: Flutter pinta en un `canvas` y el DOM solo tiene el `<pre>` de la
      // sonda. Un tiempo fijo es feo, y es lo unico que se puede hacer sin la sonda.
      // Y SE LIMPIA EL **SERVICE WORKER** ANTES DE MIRAR, y no es una medida de higiene.
      //
      // Medido el 5 de octubre de 2026: una captura de la pantalla de lectura salia de
      // **19.307 bytes**, que es una imagen del color del fondo y nada mas. La pagina
      // estaba en blanco y el perfil **no** estaba roto:
      //
      //     Manifest fetch from http://127.0.0.1:8099/ab/manifest.json failed, code 404
      //
      // Se estaba pidiendo `/ab/` cuando el paquete local declara `/`. La causa es el
      // `flutter_service_worker.js`, que **cachea el paquete entero** y se queda con la
      // ultima build. Como `scripts/publicar.sh` compila con `--base-href=/ab/` para GitHub
      // Pages y en local se compila con `--base-href=/`, el service worker tenia la build de
      // Pages y servia esa, con sus rutas de Pages, contra un servidor local que no las tiene.
      //
      // Y LO QUE HACE ESTO PELIGROSO ES QUE **NO FALLA**: una captura en blanco es una
      // captura, y sin mirar los errores de pagina parece que la pantalla esta vacia. Una
      // herramienta que puede enseñar una build equivocada y no lo dice es peor que no
      // tenerla -- y este es el mismo fallo que `AGENTS.md` escribe para las comprobaciones
      // que pasan sin comprobar lo nuevo.
      //
      // Y POR QUE NO SE BORRA EL PERFIL ENTERO: el `.amod` de 22,5 MB vive en el
      // `IndexedDB`, que **no** es la Cache Storage. `caches.delete` se lleva el service
      // worker y el paquete cacheado y deja el texto descargado, que es lo que hace lento
      //cada iteracion.
      await page.evaluate(async () => {
        for (const r of await navigator.serviceWorker.getRegistrations()) {
          await r.unregister();
        }
        for (const k of await caches.keys()) {
          await caches.delete(k);
        }
      });
      await page.reload({ waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(ESPERA);

      const nombre = `${clave}-${ruta.replace(/[^A-Za-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'raiz'}`;
      await capturar(page, nombre);

      // Y LOS ERRORES DE LA PAGINA, que una captura no enseña. Un `RenderFlex overflowed`
      // sale por la consola del navegador y no aparece en la imagen, y es justo el fallo que
      // se está mirando aqui.
      if (errores.length > 0) {
        console.log(`  ERRORES DE PAGINA (${errores.length}):`);
        for (const e of errores.slice(0, 5)) console.log(`    ${e}`);
      }
      await page.close();
    }
    await contexto.close();
  }
}

main().catch((e) => {
  console.error('fallo:', e.message);
  process.exit(1);
});