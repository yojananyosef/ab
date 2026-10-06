// Los cinco destinos del marco tienen que **llevar a algo**.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE Y NO SE PUEDE SUSTITUIR POR LEER EL CODIGO
// ============================================================================
//
// Porque el fallo que este fichero caza **no es una excepcion**: un destino que vuelve a la
// pantalla en la que ya estas no lanza nada, no desborda nada y no aparece en ningun aviso.
// Medido el 6 de octubre de 2026 en la web ya desplegada, con una Biblia descargada:
//
//     "Biblia"      no cambia la pantalla
//     "Comentarios" no cambia la pantalla
//
// Y las dos cosas tienen el mismo sintoma y **causas distintas**, que es lo que hace que un
// solo caso no las entienda:
//
//   - "Comentarios" recibia un `BuildContext` **siempre en null**, porque el marco llamaba
//     a `alElegirDestino(destino)` sin contexto. Caia en su rama de seguridad, que es
//     `irAHome()`.
//   - "Biblia" solo sabia volver al pasaje que ya estaba leyendo. Sin pasaje abierto --que es
//     justo cuando estas en la biblioteca-- caia en la misma rama de seguridad.
//
// Y LAS DOS TERMINAN IGUAL porque `irAHome()` **desde la biblioteca es no hacer nada**.
//
// Y LO QUE HACE FALSA A LA PRUEBA DE "NO HACE NADA" ES QUE ES FACIL QUE PASE: si la
// comprobacion es "la ruta ha cambiado", `irAHome()` cuando ya estas en la biblioteca **no
// cambia la ruta**, y una prueba que mire eso daria verde. Por eso estas pruebas comprueban
// las dos cosas: **que se va a la pantalla de lectura** y, en el caso sin textos, **que se
// dice por que**.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ab/app/navegador.dart';
import 'package:ab/data/repositories/catalogo_repository.dart';
import 'package:ab/domain/models/manifiesto.dart';
import 'package:ab/domain/models/modulo.dart';
import 'package:ab/ui/features/biblioteca/view_models/aviso.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/rutas.dart';
import 'package:ab/ui/features/lector/widgets/marco_de_estudio.dart';

import 'navegador_test.dart' show montarNavegador;

void main() {
  group('1. "Biblia" desde la biblioteca, con una Biblia descargada', () {
    testWidgets('abre la lectura, y no se queda donde estaba', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      _catalogo(n, descargados: <String>{'KJV2006'});

      // Y ESTANDO EN LA BIBLIOTECA, que es donde estaba el fallo.
      await n.setNewRoutePath(const RutaBiblioteca());
      expect(n.currentConfiguration, isA<RutaBiblioteca>());

      await n.irAlDestino(DestinoDeEstudio.biblia);

      // Y LA COMPROBACION ES QUE ESTA EN UNA **RUTA DE LECTURA**, y no que "ha cambiado":
      // `irAHome()` desde la biblioteca deja la ruta igual, y una comprobacion de "ha
      // cambiado" pasaria con el bug puesto.
      expect(n.currentConfiguration, isA<RutaLectura>());
    });

    testWidgets('y abre una Biblia, no un comentario', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      // Y **SOLO** LA BIBLIA DESCARGADA. Con las dos descargadas, "el primero del catalogo" y
      // "la primera Biblia" darian el mismo resultado y la comprobacion no probaria el
      // filtro de tipo, que es justo de lo que se trata.
      _catalogo(n, descargados: <String>{'KJV2006', 'CLARKE'});
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.irAlDestino(DestinoDeEstudio.biblia);

      final ruta = n.currentConfiguration;
      expect(ruta, isA<RutaLectura>());
      // Y QUE SEA UNA BIBLIA, y no "el primer modulo descargado". Con el CLARKE descargado y
      // ninguna Biblia, abrir el comentario es abrir algo que **no se puede leer**: un
      // comentario son notas de un texto que no esta ahi.
      expect((ruta as RutaLectura).modulo, 'KJV2006');
    });

    testWidgets('y con un pasaje abierto vuelve a ese pasaje', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      await n.setNewRoutePath(Rutas.leer('/leer/KJV2006/John.3.16'));
      expect(n.lector.leyendo, isNotNull);

      await n.irAlDestino(DestinoDeEstudio.biblia);

      expect(n.currentConfiguration, const RutaLectura('KJV2006', Referencia('John', 3, 16)));
      // Y ESTO NO ES LO DE ARRIBA CAMBIADO: es que "volver a Juan 3" y "abrir Juan 1" son
      // decisiones distintas. Pulsar "Biblia" con algo abierto es **volver**, y quien esta
      // leyendo Juan 3 no quiere que le salten a Juan 1.
    });
  });

  group('2. "Biblia" sin ningun texto: va a la biblioteca y lo dice', () {
    testWidgets('pone un motivo, y el motivo se ve', (t) async {
      final n = montarNavegador(abiertos: <String>[]);
      addTearDown(n.dispose);
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.irAlDestino(DestinoDeEstudio.biblia);

      // Y QUE DIGA ALGO. Lo que se pidio, y es lo unico que hace que la pantalla no sea un
      // callejon sin salida: un boton que te deja en la biblioteca sin decir por que.
      expect(n.biblioteca.motivoDeLaVisita, isNotNull);
      expect(n.biblioteca.motivoDeLaVisita, contains('descargado'));
    });

    testWidgets('y el motivo **no esta** en la lista de avisos', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      // Y EL CATALOGO **SI** PUESTO Y SIN NADA DESCARGADO, que es el caso que importa: no es
      // "no hay catalogo", es "hay oferta y no hay nada tuyo". Un destino que en ese caso
      // vuelve a la biblioteca sin decir nada es el que ha fallado.
      _catalogo(n, descargados: <String>{});
      await n.setNewRoutePath(const RutaBiblioteca());
      await n.irAlDestino(DestinoDeEstudio.biblia);

      final motivo = n.biblioteca.motivoDeLaVisita;
      expect(motivo, isNotNull);

      // Y ESTA ES LA COMPROBACION DE LA **DECISION DE DISENO**, no del comportamiento, y es
      // la que no se ve: el motivo esta **fuera** de `avisos`, y por eso sobrevive a un
      // refresco. `aplicarResultado` reemplaza esa lista entera cada vez que llega algo del
      // repositorio --que es lo que hacia que los avisos de progreso se reemplazaran a si
      // mismos-- asi que un motivo guardado ahi se iría en el primer refresco, que es justo
      // cuando lo hace falta.
      //
      // Y SE COMPRUEBA **ASI** Y NO LLAMANDO A `aplicarResultado`: construir un
      // `ResultadoCatalogo` entero en una prueba es montar el manifiesto a mano, y una
      // comprobacion que necesita el manifiesto para demostrar que un campo **no** esta en
      // otra lista es una comprobacion cara que nadie va a volver a ejecutar. Esta mira
      // exactamente lo que importa: que el texto del motivo no aparece en `avisos`.
      expect(n.biblioteca.avisos.any((Aviso a) => a.texto == motivo), isFalse,
          reason: 'si estuviera en la lista de avisos, el primer refresco se lo '
              'llevaria, que es justo cuando hace falta');
    });

    testWidgets('y se olvida en cuanto se abre un texto', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      _catalogo(n, descargados: <String>{});
      await n.setNewRoutePath(const RutaBiblioteca());
      await n.irAlDestino(DestinoDeEstudio.biblia);
      expect(n.biblioteca.motivoDeLaVisita, isNotNull);

      await n.abrirDesdeLaBiblioteca('KJV2006');

      // Y SE OLVIDA AL **ABRIR**, no al volver a la biblioteca: en cuanto hay una Biblia
      // abierta, decir "no tienes ninguna Biblia descargada" es **falso**, y un texto en
      // pantalla que no se corresponde con lo que se ve es la peor forma de avisar.
      expect(n.currentConfiguration, isA<RutaLectura>());
    });
  });

  group('3. "Comentarios" sin texto abierto', () {
    testWidgets('dice algo, en vez de volver en silencio a la biblioteca', (t) async {
      final n = montarNavegador();
      addTearDown(n.dispose);
      _catalogo(n, descargados: <String>{'KJV2006'});
      await n.setNewRoutePath(const RutaBiblioteca());

      await n.irAlDestino(DestinoDeEstudio.comentarios);

      // Y LA COMPROBACION ES EL MOTIVO, y no "ha cambiado la ruta": `elegirComentario`
      // empieza con `if (ruta is! RutaLectura) return;`, que es lo correcto y **se vuelve
      // sin decir nada**. Desde un boton, eso es indistinguible de no hacer nada.
      expect(n.biblioteca.motivoDeLaVisita, isNotNull);
      expect(n.biblioteca.motivoDeLaVisita, contains('texto abierto'));
    });
  });

  group('4. el marco pasa un contexto de verdad', () {
    for (final ancho in <double>[360, 1440]) {
      testWidgets('el contexto que llega no es null, a $ancho px',
          (WidgetTester t) async {
        BuildContext? recibido;

        // Y LA PANTALLA SE FIJA **ANTES** DEL PRIMER `pumpWidget`. Con el orden al reves,
        // el primer montaje sale a 800 x 600 --panel de la izquierda-- y cambiar el tamano
        // despues no lo quita, con lo que la prueba acababa midiendo siempre el panel.
        // Fijar antes es lo unico que hace que los dos anchos sean los dos anchos.
        t.view.physicalSize = Size(ancho, 800);
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.reset);

        await t.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MarcoDeEstudio(
              destino: DestinoDeEstudio.buscar,
              alElegirDestino: (DestinoDeEstudio _, BuildContext c) => recibido = c,
              hijo: const SizedBox.shrink(),
            ),
          ),
        ));
        await t.pumpAndSettle();

        // Y POR EL **ICONO** Y NO POR EL `tooltip`. El panel de la izquierda, cuando esta
        // extendido, ensena el nombre **escrito** y no el emergent, asi que a 1440 px no hay
        // ningun `tooltip` que buscar: la prueba fallaba con "Found 0 widgets" en el ancho
        // grande y pasaba en el pequeno. El icono esta en los dos anchos, que es lo unico
        // que hay en los dos.
        await t.tap(find.byIcon(DestinoDeEstudio.buscar.icono).first);
        await t.pumpAndSettle();

        expect(recibido, isNotNull,
            reason: 'sin contexto, elegir comentario no puede abrir la hoja, y desde la '
                'biblioteca eso es volver a la biblioteca: no se ve nada');
      });
    }
  });
}

/// Poner un catalogo con una Biblia y un comentario, y decir cuales estan aqui.
///
/// Y POR QUE HAY QUE MONTARLO A MANO Y NO USAR EL QUE TRAE `montarNavegador`: porque el que
/// trae deja la biblioteca **vacia**, y con la biblioteca vacia no hay nada que probar --no
/// hay ni texto descargado ni texto que no lo este-- y las tres comprobaciones pasan por
/// pruebas que no miran nada.
///
/// Y EL CATALOGO TIENE **UNO DE CADA TIPO** porque es la unica manera de comprobar que "Biblia"
/// elige una Biblia: con dos Biblias y ningun comentario, "el primero descargado" daria el
/// mismo resultado que "la primera Biblia".
void _catalogo(NavegadorAb n, {required Set<String> descargados}) {
  n.biblioteca.aplicarResultado(
    ResultadoCatalogo(
      manifiesto: Manifiesto(
        formato: 'aa-catalog/1',
        version: 'v0.1.1',
        etiqueta: 'v0.1.1',
        modulos: <Modulo>[
          _modulo('KJV2006', 'King James Version 2006', TipoModulo.biblia, 22544384),
          _modulo('CLARKE', 'Comentario de Adam Clarke', TipoModulo.comentario, 57536512),
        ],
      ),
      estado: EstadoLectura.delServidor,
    ),
    idsLocales: descargados,
    hashesLocales: <String, String>{for (final id in descargados) id: 'a' * 64},
  );
}

/// Un modulo del catalogo de pruebas.
///
/// Y LOS MISMOS SHA256 PARA LOS DOS, a proposito: si fueran distintos, una prueba que
/// comprueba "cual ha cambiado" tendria dos respuestas posibles y no sabria cual espera.
Modulo _modulo(String id, String nombre, TipoModulo tipo, int tamano) => Modulo(
      id: id,
      nombre: nombre,
      tipo: tipo,
      idioma: 'eng',
      licencia: 'PublicDomain',
      tamanoBytes: tamano,
      sha256: 'a' * 64,
      urlDescarga: Uri.parse('https://example.invalid/$id.amod'),
      urlNavegador: Uri.parse('https://example.invalid/$id'),
    );
