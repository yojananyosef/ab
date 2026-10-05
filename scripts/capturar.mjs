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
// la aplicacion: es una herramienta de mirar. Se instala una vez, en el arbol de trabajo,
// no en el repositorio:
//
//     cd scripts/viz && npm install playwright
//
// Y el navegador es el del sistema --`/usr/bin/brave-browser`--, no uno que descarga
// Playwright: son 300 MB que no hacen falta porque ya hay un Chromium instalado.
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';

const BASE = process.env.AB_URL ?? 'http://127.0.0.1:8099';
const SALIDA = process.env.AB_SALIDA ?? '/tmp/opencode/viz/capturas';
const ESPERA = Number(process.env.AB_ESPERA ?? 9000);

/** Cuanto se espera a que el modulo este descargado y guardado. */
const ESPERA_DESCARGA = Number(process.env.AB_ESPERA_DESCARGA ?? 25000);

/** Si hay que pasar antes por la biblioteca para que el modulo quede en el `IndexedDB`. */
const procesados = new Set((process.env.AB_PREPARAR ?? '').split(',').filter(Boolean));

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

async function main() {
  mkdirSync(SALIDA, { recursive: true });

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
      if (procesados.has('biblioteca')) {
        await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(ESPERA_DESCARGA);
      }

      console.log(`==> ${ruta} a ${medida.width}x${medida.height}`);
      await page.goto(`${BASE}${ruta}`, { waitUntil: 'domcontentloaded' });
      // Y LA ESPERA ES FIJA Y POSTERIOR A LA CARGA. El modulo son 22 MiB y hay que bajarlo
      // y abrirlo; esperar a `networkidle` no sirve porque Flutter mantiene conexiones
      // abiertas, y esperar a un elemento del `canvas` no sirve porque el texto **no esta
      // en el DOM**: Flutter pinta en un `canvas` y el DOM solo tiene el `<pre>` de la
      // sonda. Un tiempo fijo es feo, y es lo unico que se puede hacer sin la sonda.
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