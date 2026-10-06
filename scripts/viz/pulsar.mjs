// Capturas de la hoja de formato, y de lo que hay que pulsar para llegar a ella.
//
// ============================================================================
// POR QUE HACE FALTA UN GUIÓN DE PULSOS Y NO BASTA CON `capturar.mjs`
// ============================================================================
//
// Flutter pinta en un `canvas`: **no hay nada pulsable en el DOM**. `page.click('text=Descargar')`
// no encuentra nada, y un guion que Pulse por coordenadas es lo unico que hay.
//
// Y HAY QUE PULSAR DE VERDAD PORQUE LA BIBLIOTECA **NO BAJA NADA SOLA**: abrir `/` no descarga
// el modulo, hay que darle al boton. Un guion que visitase `/` y esperase --que es lo que
// hacia la opcion `AB_PREPARAR`-- se quedaria esperando un modulo que nadie ha pedido, y la
// captura de la pantalla de lectura saldria siendo la biblioteca, con lo que parece que la
// ruta no funciona.
//
// Las coordenadas estan medidas **a mano sobre las capturas** y con la relacion de ironia de
// las capturas, que es 2: el boton de "Descargar" esta en (180, 381) a 360 px de ancho, y el
// icono de formato en (286, 28).

import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';

const BASE = process.env.AB_URL ?? 'http://127.0.0.1:8099';
const SALIDA = process.env.AB_SALIDA ?? '/tmp/opencode/viz/capturas';
const ESPERA = Number(process.env.AB_ESPERA ?? 10000);
const ESPERA_DESCARGA = Number(process.env.AB_ESPERA_DESCARGA ?? 40000);
const PERFIL = process.env.AB_PERFIL ?? '/tmp/opencode/viz/perfil';

const args = [
  '--no-sandbox',
  '--disable-dev-shm-usage',
  '--enable-unsafe-swiftshader',
  '--use-angle=swiftshader-webgl',
  '--disable-gpu-sandbox',
];

async function capturar(page, nombre) {
  const ruta = `${SALIDA}/${nombre}.png`;
  await page.screenshot({ path: ruta, animations: 'disabled' });
  console.log(`  ${ruta}`);
  return ruta;
}

async function main() {
  mkdirSync(SALIDA, { recursive: true });

  const contexto = await chromium.launchPersistentContext(PERFIL, {
    executablePath: process.env.AB_NAVEGADOR ?? '/usr/bin/brave-browser',
    viewport: { width: 360, height: 760 },
    deviceScaleFactor: 2,
    locale: 'es-ES',
    args,
  });

  const page = await contexto.newPage();
  const errores = [];
  page.on('pageerror', (e) => errores.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error') errores.push(m.text());
  });

  console.log('==> bajando el modulo, que la biblioteca no lo baja sola');
  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(ESPERA);
  await capturar(page, 'gui-01-biblioteca');

  // Y EL PULSO, en el centro del boton de "Descargar" del primer modulo. Medido sobre la
  // captura a 360 px: el boton va de x 28 a 332 y de y 362 a 400.
  await page.mouse.click(180, 381);
  await page.waitForTimeout(ESPERA_DESCARGA);
  await capturar(page, 'gui-02-tras-bajar');
  console.log(`  errores: ${errores.length}`);

  console.log('==> y a la lectura');
  await page.goto(`${BASE}/leer/KJV2006/John.3.16`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(ESPERA);
  await capturar(page, 'gui-03-lectura');

  console.log('==> y la hoja de formato');
  // Y EL ICONO DE FORMATO ES EL **TERCERO POR LA DERECHA** en la barra: buscar, letras rojas,
  // formato, comentario. A 360 px el grupo empieza en 300 y cada icono son 28 px de captura
  // --14 reales--, con lo que el de formato cae en (286, 28).
  await page.mouse.click(286, 28);
  await page.waitForTimeout(1500);
  await capturar(page, 'gui-04-formato');

  // Y ABAJO DENTRO DE LA HOJA, para ver los fondos y el boton de restaurar.
  await page.mouse.move(180, 400);
  await page.mouse.wheel(0, 400);
  await page.waitForTimeout(1200);
  await capturar(page, 'gui-05-formato-abajo');

  if (errores.length > 0) {
    console.log(`  ERRORES (${errores.length}):`);
    for (const e of errores.slice(0, 5)) console.log(`    ${e.slice(0, 200)}`);
  }

  await contexto.close();
}

main().catch((e) => {
  console.error('fallo:', e.message);
  process.exit(1);
});