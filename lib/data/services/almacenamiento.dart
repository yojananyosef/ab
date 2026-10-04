// Guardar unas cuantas cosas entre sesiones.
//
// QUE COSAS SON: exactamente una, el **ultimo manifiesto que se leyo con exito**.
//
// Y esa es toda la gracia. Si alguien guarda aqui notas, resaltados o marcadores,
// este fichero deja de ser una comodidad y pasa a ser el sitio donde se puede
// perder el trabajo de la persona, que es el peor fallo posible en este
// proyecto. Lo que se guarda aqui es informacion que se puede volver a bajar.
//
// HAY DOS IMPLEMENTACIONES: una de verdad, con las preferencias del sistema, y
// otra en memoria, para las pruebas. La de memoria no es un adorno: una prueba
// que escribiera en las preferencias de verdad dejaria basura entre ejecuciones
// y fallaria la segunda vez por un motivo que no tiene que ver con lo que
// comprueba.

import 'package:shared_preferences/shared_preferences.dart';

/// Leer y escribir un valor de texto, o nada.
///
/// Interfaz minima a proposito: son dos metodos. Si alguna vez hiciera falta
/// guardar mas cosas, se anaden aqui y en la interfaz, no se convierte esto en
/// una base de datos.
abstract class Almacenamiento {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> borrar(String clave);
}

/// Con las preferencias del sistema. Funciona en las cuatro plataformas.
///
/// En web usa `localStorage`, que son unos 5 MB: de sobra para un manifiesto de
/// 1.468 bytes.
class Preferencias implements Almacenamiento {
  const Preferencias();

  @override
  Future<String?> leer(String clave) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(clave);
  }

  @override
  Future<void> escribir(String clave, String valor) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(clave, valor);
  }

  @override
  Future<void> borrar(String clave) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(clave);
  }
}

/// En memoria, para pruebas. Se puede rellenar de golpe, para simular que ya
/// hay un manifiesto guardado.
class AlmacenamientoEnMemoria implements Almacenamiento {
  AlmacenamientoEnMemoria([Map<String, String>? inicial])
    : _datos = <String, String>{...?inicial};

  final Map<String, String> _datos;

  Map<String, String> get datos => Map.unmodifiable(_datos);

  @override
  Future<String?> leer(String clave) async => _datos[clave];

  @override
  Future<void> escribir(String clave, String valor) async => _datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => _datos.remove(clave);
}

/// La clave con la que se guarda el manifiesto. En un solo sitio, y en un solo
/// formato, porque si se escribiera en dos sitios uno de los dos se queda viejo
/// y se acaba leyendo el que no se actualiza.
const String claveManifiestoGuardado = 'ab.manifiesto.ultimo';

/// La clave con la que se guarda de que release vino ese manifiesto.
const String claveEtiquetaGuardada = 'ab.manifiesto.etiqueta';
