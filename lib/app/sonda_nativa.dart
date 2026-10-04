// La sonda en nativo: no hay DOM, asi que no hay nada que escribir.
//
// Y NO ES UN "NO HAGO NADA" DE ADORNOS. Es lo que permite que `sonda.dart` se
// compile en la maquina de Dart, que es donde se ejecutan todas las pruebas. Si el
// import de `package:web` estuviera en `sonda.dart`, `flutter test` no compilaria, y con
// el no compilaria el grupo entero de pruebas del lector.
//
// La firma es la misma que la de `sonda_web.dart` y el cuerpo no hace nada, que es lo
// unico que se puede hacer en un movil: no hay documento al que escribir.

/// En nativo no hay DOM. No hace nada, y no avisa.
///
/// Y NO AVISA A POSTERIOR, y es lo correcto: el aviso seria por pantalla, en una
/// aplicacion de leer la Biblia, cada vez que alguien imprimiera el resultado de una
/// comprobacion que solo se pide en el navegador. Es ruido en un sitio donde no hay
/// nadie mirando.
void escribirEnElMarcador(String id, String texto) {}

/// Fuera del navegador no hay historial, y no hay nada que medir.
///
/// Y DEVUELVE NULL Y NO CERO. Con cero, una comprobacion que comparase "antes" y
/// "despues" veria que no ha cambiado y concluiria que el ajuste no entra en el
/// historial --que es justo lo que se quiere comprobar-- cuando lo que ha pasado es que
/// no habia historial que mirar. El que decide es el script, que ve el null.
int? longitudDelHistorial() => null;

/// Fuera del navegador no hay a quien notificar.
///
/// Y NO ES UN "NO HAGO NADA" QUE SE PUEDA OLVIDAR: la sonda en nativo solo existe para
/// que `sonda.dart` compile en la maquina de Dart, donde no hay navegador, no hay DOM y
/// no hay colector. Si se llamara, no habria a quien escribir y no habria nadie leyendo.
void notificarPorHttp(String url, String texto) {}
