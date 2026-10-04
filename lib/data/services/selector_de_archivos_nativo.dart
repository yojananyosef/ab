// El selector de archivos del sistema operativo.
//
// Uno de los dos ficheros que saben en que plataforma estamos. Si anades un
// metodo aqui, anadelo tambien en `selector_de_archivos_web.dart`, o el codigo
// que funciona en una plataforma no compilara en la otra.
//
// Y este fichero **puede** importar `package:file_selector` a pelo, sin
// condiciones, porque el import condicional de `selector_de_archivos.dart` nunca
// carga este fichero en web. Es la razon por la que el reparto por plataformas
// se hace con un import condicional y no con una comprobacion dentro del codigo:
// asi cada implementacion se compila solo donde toca, y puede usar su paquete sin
// trucos.

import 'package:file_selector/file_selector.dart';

import 'selector_de_archivos.dart';

/// En nativo se usa el dialogo del sistema.
///
/// El filtro va como lista de wildcards y **es una sugerencia**, no una
/// imposicion. En Linux, cuando el selector abre un portal GTK, el filtro puede
/// outright esconder ficheros; y si esconde el `.amod` de alguien, la conclusion
/// que saca es "esta app no tiene mi Biblia". Un filtro que esconde ficheros hace
/// que la gente piense que la app ha perdido su texto, que es lo peor que puede
/// pasarle a un lector.
class SelectorNativo implements SelectorDeArchivos {
  SelectorNativo({this.filtroSugerido = const ['*.amod']});

  @override
  final List<String>? filtroSugerido;

  @override
  Future<ResultadoDeElegir> elegir() async {
    try {
      final grupo = await openFiles(
        acceptedTypeGroups: [const XTypeGroup(label: 'Modulos', extensions: ['amod'])],
      );
      if (grupo.isEmpty) return const ResultadoDeElegir.cancelado();

      final ruta = grupo.first;
      // `path` solo existe en las plataformas que tienen sistema de ficheros, que
      // son exactamente las que cargan este fichero. Por eso se puede usar sin
      // mirar la plataforma.
      return ResultadoDeElegir.elegido(
        ArchivoElegido(nombre: ruta.name, bytes: await ruta.readAsBytes()),
      );
    } catch (e) {
      // Cancelar tambien llega aqui como excepcion en algunos sistemas y versiones
      // del plugin. Se distingue por el motivo; cuando no se puede distinguir, se
      // dice "no se ha podido" en vez de mentir. Un mensaje equivocado se puede
      // corregir; uno que hace que la app parezca rota, no tan facil.
      final texto = e.toString().toLowerCase();
      if (texto.contains('cancel')) return const ResultadoDeElegir.cancelado();
      return const ResultadoDeElegir.fallido(
        'No se ha podido abrir el selector de archivos.',
      );
    }
  }

  @override
  void dispose() {}
}

/// La implementacion de este fichero. La llama `crearSelector()` del otro.
SelectorDeArchivos crearSelector() => SelectorNativo();
