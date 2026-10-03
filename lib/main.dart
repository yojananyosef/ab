// AB - Lector de Biblia de dominio publico.
//
// Punto de entrada provisorio. La estructura real (`lib/data`, `lib/domain`,
// `lib/ui`) la introduce el primer change de OpenSpec; este archivo solo
// mantiene la app compilando y las pruebas en verde mientras tanto.
//
// Regla: este archivo no crece. Cuando llegue el lector, desaparecer.

import 'package:flutter/material.dart';

void main() => runApp(const AbApp());

class AbApp extends StatelessWidget {
  const AbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AB',
      debugShowCheckedModeBanner: false,
      home: const _Pendiente(),
    );
  }
}

class _Pendiente extends StatelessWidget {
  const _Pendiente();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'AB todavia no lee. El lector llega en el primer change de '
            'OpenSpec.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}