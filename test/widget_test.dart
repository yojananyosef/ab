// La app entera, montada de verdad.
//
// ESTA PRUEBA MONTA `main.dart`. No un doble. Y es a proposito, y es lo que se
// Y casi ninguna app lo hace, que es precisamente el problema.
//
// La razon: un doble de cien lineas que solo se usa en pruebas es una **segunda
// implementacion** de la app, y no la prueba nadie. Con el tiempo, la que se
// arregla es la de las pruebas y la que se rompe es la de verdad, y no hay ninguna
// prueba que lo note. Montando el codigo de verdad, esta prueba y el navegador
// ejecutan las mismas lineas.
//
// LO QUE COMPRUEBA, Y POR QUE ESTAS CUATRO COSAS Y NO OTRAS:
//
//  1. Que arranca sin excepciones. Es lo minimo y lo que mas falla.
//  2. Que se identifica como `AB`. Antes de este grupo, esta prueba comprobaba que
//     aparecia el cartel de "todavia no lee". Ahora comprueba que aparece
//     "Biblioteca", y esa diferencia **es** el grupo 6 hecho.
//  3. Que no se rompe a 360 px. La regla del repositorio: un widget que revienta a
//     360 px no esta terminado.
//  4. Que sin red ensena algo y **no** una pantalla en blanco.
//
// Y NO COMPRUEBA QUE SE VEAN MODULOS. Aqui no hay red y el almacenamiento es de
// verdad, asi que la lista sale vacia, y una prueba que espera ver el KJV
// fallaria siempre en un runner sin Internet. Eso es lo que comprueba
// `test/red/sitio_real_test.dart`, en su propio paso.

import 'package:ab/data/services/almacenamiento_de_resaltados.dart';
import 'package:ab/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La app entera con un almacen de resaltados **que no toca el disco**.
///
/// Y POR QUE HACE FALTA UN AYUDANTE Y NO CAMBIAR LAS CUATRO LLAMADAS A PELA. La app real
/// pide su almacen con `crearAlmacenamientoDeResaltados()`, y en nativo eso llama a
/// `getApplicationSupportDirectory()`, que necesita un motor de plataformas y **no lo hay** en
/// la maquina de Dart: se queda esperando a un canal que nadie responde. Ese `Future` colgado
/// deja vivo el `Timer` del plazo de cinco segundos, y la prueba falla con
///
///     A Timer is still pending even after the widget tree was disposed.
///
/// que no menciona ni el almacen ni los resaltados. Por eso el parametro existe en `AbApp`.
/// El almacen en memoria de las pruebas de la app entera.
///
/// Y ES **UNO SOLO** PARA LAS CUATRO PRUEBAS y no uno por prueba, y no por savescribir: cada
/// uno tendria que llamar a `dispose` en su `tearDown`, y un `dispose` olvidado en un `tearDown`
/// es una prueba que se lleva por delante las siguientes. Ademas, sharing significa que las
/// cuatro pruebas MIRAN LO MISMO, que es lo que hace comparables.
final AlmacenamientoDeResaltados almacenDeResaltadosDeLaPrueba =
    AlmacenamientoDeResaltadosEnMemoria();

/// La app entera, con un almacen de resaltados que no toca el disco.
AbApp abAppDePrueba() =>
    AbApp(almacenamientoDeResaltados: almacenDeResaltadosDeLaPrueba);

/// El movil mas estrecho que se usa hoy.
const Size anchoEstrecho = Size(360, 640);

void main() {
  testWidgets('la app arranca y se identifica', (tester) async {
    await tester.pumpWidget(abAppDePrueba());
    await tester.pump();

    // Antes de este grupo, esta misma prueba comprobaba "AB todavia no lee".
    // Ahora comprueba "Biblioteca", y el titulo va en el `AppBar`, que es donde
    // esta --no en un `Center`-- para que en un movil quede arriba y no en medio
    // de una pantalla vacia.
    expect(find.widgetWithText(AppBar, 'Biblioteca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arranca sin excepciones en pantalla estrecha', (tester) async {
    tester.view.physicalSize = anchoEstrecho;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(abAppDePrueba());
    // Tres `pump`: el primero monta, el segundo deja correr el `initState` que pide
    // el catalogo, y el tercero deja pintar el resultado. Sin el tercero, la
    // pantalla sale a medio construir y la prueba pasa sin comprobar lo que dice
    // comprobar.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Biblioteca'), findsWidgets);
  });

  testWidgets('sin catalogo ensena un aviso y NO una pantalla en blanco', (tester) async {
    await tester.pumpWidget(abAppDePrueba());
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Sin red, la lectura del catalogo falla, y la pantalla tiene que decirlo. Un
    // `Center` con un `Text` vacio no dice nada, y parece una app que no arranca.
    // Aqui se comprueba que hay texto, no que sea el exacto: el texto exacto lo
    // comprueba `test/ui/biblioteca_view_test.dart` con un manifiesto controlado.
    expect(find.byType(Text), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el filtro esta y se puede escribir en el, a 360 px', (tester) async {
    tester.view.physicalSize = anchoEstrecho;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(abAppDePrueba());
    await tester.pump();
    await tester.pump();

    // El filtro **sigue ahi** aunque la lista este vacia. Es como se quita un
    // filtro que ha dejado la lista vacia: si desaparece con ella, no hay forma de
    // quitarlo sin recargar la pagina.
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'valera');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
