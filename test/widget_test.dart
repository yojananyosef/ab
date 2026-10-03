// Prueba de humo del punto de entrada provisional.
//
// Cuando el lector llegue, esta prueba se sustituye por pruebas de las
// pantallas reales. Si sobrevive, es que nadie la actualizo: borrarla.

import 'package:ab/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la app arranca y se identifica', (WidgetTester tester) async {
    await tester.pumpWidget(const AbApp());

    expect(find.textContaining('AB'), findsOneWidget);
  });

  testWidgets('arranca sin excepciones en pantalla estrecha', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AbApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}