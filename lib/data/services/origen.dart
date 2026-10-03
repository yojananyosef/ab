// De donde vive el catalogo.
//
// ESTE ES EL UNICO SITIO DEL REPOSITORIO DONDE VIVE UNA DIRECCION. Y por que
// esta separado es lo importante:
//
// - `REPOSITORIO` es de donde sale todo lo demas. Cambiar de cuenta o de
//   organizacion es editar una linea, no buscar una URL por el codigo.
// - No dice **que** hay en el catalogo. Solo donde se pregunta. La lista de
//   textos vive en el manifiesto, y en ningun otro sitio.
//
// Se puede cambiar en tiempo de compilacion, y eso no es un adorno: las pruebas
// necesitan apuntar a un servidor local que se pueda romper a voluntad, y
// probarlo contra el sitio real haria que una prueba dependiera de la red.
//
//   flutter build web --dart-define=AB_ORIGEN_CATALOGO=http://localhost:8099

/// Cuenta y repositorio del catalogo. Lo unico escrito a mano.
///
/// En Dart las constantes van en lowerCamelCase y el analizador lo exige. En el
/// repositorio hermano esta misma constante se llama `REPOSITORIO`, en
/// mayusculas, porque ahi es TypeScript y es su convencion. El nombre se lee
/// igual; el cambio de estilo es del lenguaje.
const String repositorio = 'yojananyosef/aa';

/// Sobrescribe el origen en compilacion. Vacio significa "usa el de arriba".
const String _origenDeCompilacion = String.fromEnvironment('AB_ORIGEN_CATALOGO');

/// El origen del catalogo, sin barra final.
///
/// El de por defecto es el **sitio de GitHub Pages**, no la release, y no es
/// capricho: Pages responde `Access-Control-Allow-Origin: *` tambien en los
/// binarios, y la release de GitHub no responde ninguna. Un navegador puede
/// leer el primero y el segundo le da `Failed to fetch`. En nativo los dos
/// funcionan, asi que el mismo origen vale para las cuatro plataformas y no hay
/// que decidir por plataforma.
///
/// La razon de que la release no sirva esta medida y escrita en
/// `docs/investigacion/transporte-cors.md`.
String get origenCatalogo {
  if (_origenDeCompilacion.isNotEmpty) return _sinBarraFinal(_origenDeCompilacion);
  return _sinBarraFinal(
    'https://${repositorio.split('/').first}.github.io/${repositorio.split('/').last}',
  );
}

/// Puntero flotante: que release esta vigente y donde esta su manifiesto.
Uri get urlUltimoJson => Uri.parse('$origenCatalogo/latest.json');

/// Manifiesto de una etiqueta concreta.
Uri urlCatalogo(String etiqueta) => Uri.parse('$origenCatalogo/modulos/$etiqueta/catalog.json');

/// Como se ve el origen, para la pantalla de ajustes y para las pruebas.
String get origenLegible => origenCatalogo;

String _sinBarraFinal(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;
