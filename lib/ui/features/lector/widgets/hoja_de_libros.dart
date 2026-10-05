// La hoja para elegir libro, capitulo y versiculo.
//
// QUE ES Y QUE NO ES. Es el selector de referencias, y es la pantalla que mas se echa de
// menos en un lector de Biblia mientras esta. El fallo es siempre el mismo: hay un campo
// de texto y ya esta, y para pasar de Juan a Josue hay que escribir "Josue 1". Sesenta y
// seis libros, mil ciento ochenta y nueve capitulos y un teclado.
//
// Y EL QUE SE COPIA ES EL DE BIBLE GATEWAY: una **vista previa del capitulo** junto al
// numero. Es la mejor idea de localizacion de referencias que se ha visto, y lo resuelve
// con una linea de texto: "se que estaba en el capitulo 12 de algo, pero no de que" se
// responde leyendo la primera frase del 12.
//
// ============================================================================
// Y POR QUE DICE "PRIMERA FRASE" Y NO "RESUMEN", QUE ES LO QUE NO ES
// ============================================================================
//
// Un resumen de capitulo son las palabras del capitulo en tres lineas, y **no esta en el
// modulo**. Habria que escribirlo, y escribirlo es poner el dato de otra persona en
// pantalla. Lo que si esta es el texto, y la primera frase es una preview honesta.
//
// Y NO SE PONE UN NUMERO DE CARACTERES FIJO. Cortar en 120 caracteres parte frases por la
// mitad y deja el final colgando en "...y dijo a". El corte va donde hay un punto, y si la
// frase entera no tiene punto --los cuatro evangelios abren sin ninguno-- se corta donde
// toca y se dice con puntos suspensivos.
//
// ============================================================================
// Y POR QUE NO HAY UNA LISTA PLANA DE LIBROS
// ============================================================================
//
// El filtro **deja escribir una referencia entera**, no solo un nombre de libro. Es lo que
// hace el campo que esto sustituye, y quitarlo seria cambiar una cosa por otra: quien
// escribe "Juan 3:16" y ve una lista filtrada de libros donde solo sale "Juan" tendria que
// elegir el capitulo a mano. Con la referencia entera se ofrece el pasaje.
//
// Y LOS LIBROS VIENEN EN ORDEN CANONICO, que es como la gente sabe que se lee un libro,
// y ese orden **no lo declara el modulo** --`book` es texto sin indice-- y sale de la tabla
// del dominio. Los capitulos, en cambio, salen del modulo con una consulta, porque el
// numero de capitulos de un libro **depende de la traduccion**: la KJV tiene 50 capitulos
// de Genesis y la RVR tiene 51, y ofrecer el 51 en una lleva a una pantalla en blanco.
//
// Y SI EL LIBRO QUE ESTA EN LA RUTA NO ESTA EN ESTE MODULO, la hoja lo dice al abrir en
// lugar de abrir en un libro cualquiera. Un selector que abre en Genesis porque es el
// primero de la lista es un selector que ha perdido el sitio de quien lo ha abierto.

import 'package:flutter/material.dart';

import 'package:ab/domain/models/libro.dart';
import 'package:ab/domain/models/libros.dart';
import 'package:ab/domain/models/referencia.dart';
import 'package:ab/ui/core/tema.dart';

/// Lo que el selector necesita de un modulo abierto.
///
/// Y ES UNA INTERFAZ Y NO EL `ModuloAbierto` ENTERO, por lo mismo que en el indice: el
/// repositorio no se puede construir en una prueba sin abrir un `.amod` de 22 MiB.
abstract class ModuloConLibros {
  /// Los libros del modulo con los capitulos que tienen, en el orden que los trae.
  Map<String, List<int>> librosConCapitulos();

  /// La primera frase de cada capitulo de un libro.
  Map<int, String> primeraFraseDeCapitulos(String libro);
}

/// Pide un pasaje. Devuelve la referencia, o null si se cierra sin elegir.
Future<Referencia?> mostrarHojaDeLibros({
  required BuildContext context,
  required ModuloConLibros modulo,
  required Referencia? leyendo,
}) {
  return showModalBottomSheet<Referencia>(
    context: context,
    // Y CON `MAXIMO` Y NO A MEDIAS, y aqui si al maximo, al contrario que en la hoja de
    // comentarios. Aquella elige entre cuatro cosas y el alto la ponia el contenido; esta
    // tiene que pintar sesenta y seis libros y su lista de capitulos, y una hoja con el
    // alto justo se convierte en un molde de tres lineas que hay que ir empujando.
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _HojaDeLibros(modulo: modulo, leyendo: leyendo),
    ),
  );
}

class _HojaDeLibros extends StatefulWidget {
  const _HojaDeLibros({required this.modulo, required this.leyendo});

  final ModuloConLibros modulo;
  final Referencia? leyendo;

  @override
  State<_HojaDeLibros> createState() => _HojaDeLibrosState();
}

class _HojaDeLibrosState extends State<_HojaDeLibros> {
  final TextEditingController _control = TextEditingController();
  late Map<String, List<int>> _conCapitulos;

  /// El libro abierto, o null si se esta viendo la lista de libros.
  String? _libroAbierto;

  /// La primera frase de los capitulos de [_libroAbierto]. Se pide al abrir el libro y no
  /// antes, porque son 21 filas de texto del modulo y no hacen falta para pintar la lista
  /// de libros.
  Map<int, String> _primerasFrases = const <int, String>{};

  @override
  void initState() {
    super.initState();
    _control.text = widget.leyendo?.paraUrl ?? '';
    _conCapitulos = widget.modulo.librosConCapitulos();
    // Y SE ABRE EN EL LIBRO QUE SE ESTA LEYENDO, y no en el primero de la lista. Una hoja
    // que se abre en Genesis porque es el primero es una hoja que ha perdido el sitio de
    // quien la ha abierto, y abrirla para cambiar de capitulo es el uso normal.
    final id = widget.leyendo?.libro;
    if (id != null && _conCapitulos.containsKey(id)) _abrirLibro(id);
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  void _abrirLibro(String id) {
    _libroAbierto = id;
    _primerasFrases = widget.modulo.primeraFraseDeCapitulos(id);
  }

  void _alEscribir(String texto) {
    // Y AL ESCRIBIR SE SALE A LA LISTA DE LIBROS, y no se queda en el capitulo del libro
    // anterior. Escribir "Sal" con el capitulo de Juan abierto no puede dejar a nadie en
    // Juan: lo que se ha pedido es otra cosa.
    if (_libroAbierto != null && texto.trim() != (widget.leyendo?.paraUrl ?? '')) {
      _libroAbierto = null;
      _primerasFrases = const <int, String>{};
    }
    setState(() {});
  }

  /// Lo que se ha escrito, si es una referencia completa.
  ///
  /// Y SOLO SI TIENE CAPITULO. "Juan" es un libro y se resuelve en la lista; "Juan 3" es un
  /// pasaje y se ofrece para ir. La distincion es la que evita que escribir el nombre de
  /// un libro salte a su capitulo 1 sin querer.
  Referencia? get _comoPaseaje {
    final v = _referenciaDelTexto(_control.text);
    return (v != null && v.versiculo != null) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _barra(superior: _libroAbierto == null),
          _campo(),
          Expanded(child: _libroAbierto == null ? _libros() : _capitulos(_libroAbierto!)),
        ],
      ),
    );
  }

  /// La cabecera de la hoja, con la flecha de volver **solo** cuando hay algo a lo que
  /// volver.
  Widget _barra({required bool superior}) {
    final l = _libroAbierto == null ? null : libroPorId(_libroAbierto!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Medidas.margenEstrecho, 0, Medidas.margenEstrecho, 4),
      child: Row(
        children: <Widget>[
          if (!superior)
            IconButton(
              tooltip: 'Volver a los libros',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _libroAbierto = null;
                _primerasFrases = const <int, String>{};
                _control.clear();
              }),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              l?.nombre ?? 'Libro y capitulo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// El filtro.
  ///
  /// Y CON UN `hintText` QUE DIGA LAS DOS COSAS, porque el campo acepta las dos. Un campo
  /// que dice "buscar" y que ademas entiende una referencia deja a medio camino a quien
  /// escribe "Juan 3:16" y ve la lista de Juan.
  Widget _campo() => Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          4,
          Medidas.margenEstrecho,
          8,
        ),
        child: TextField(
          controller: _control,
          autofocus: false,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Un libro, o una referencia: Juan 3:16',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _control.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _control.clear();
                      _alEscribir('');
                    },
                  ),
          ),
          onChanged: _alEscribir,
        ),
      );

  Widget _libros() {
    final texto = _control.text.trim();
    final nombres = _librosQueCasan(texto);
    final pasaje = texto.isEmpty ? null : _comoPaseaje;

    if (nombres.isEmpty && pasaje == null) {
      return _vacio('Ningun libro se llama "$texto" en este texto.');
    }

    // Y UN **GRUPO** POR TESTAMENTO Y NO UNA LISTA CORRIDA. `kNuevoTestamentoDesde` ya
    // estaba en el repositorio para esto y no lo usaba nadie: son treinta y nueve libros
    // de un lado y veintisiete del otro, y sin el separador hay que recorrer media pantalla
    // para saber si uno esta antes o despues del agua.
    final antiguos = <Libro>[];
    final nuevos = <Libro>[];
    for (final l in nombres) {
      (kLibros.indexOf(l) >= kNuevoTestamentoDesde ? nuevos : antiguos).add(l);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: Medidas.margenAncho),
      children: <Widget>[
        if (pasaje != null)
          ListTile(
            leading: const Icon(Icons.arrow_forward, color: Colores.acento),
            title: Text('Ir a ${pasaje.texto}'),
            subtitle: Text(
              'Referencia completa',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colores.textoSuave),
            ),
            onTap: () => Navigator.of(context).pop(pasaje),
          ),
        if (antiguos.isNotEmpty) ..._grupo('Antiguo Testamento', antiguos, widget.leyendo),
        if (nuevos.isNotEmpty) ..._grupo('Nuevo Testamento', nuevos, widget.leyendo),
      ],
    );
  }

  List<Widget> _grupo(String titulo, List<Libro> libros, Referencia? leyendo) {
    final abierto = leyendo?.libro;
    return <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenEstrecho,
          14,
          Medidas.margenEstrecho,
          4,
        ),
        child: Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colores.textoSuave, letterSpacing: 0.6),
        ),
      ),
      for (final l in libros)
        ListTile(
          dense: true,
          // Y EL NUMERO DE CAPITULOS AL LADO DEL NOMBRE, en el `trailing`. Es el dato que
          // dice cuanto hay dentro, y va en el sitio donde el ojo ya esta mirando para
          // elegir y no en un sitio nuevo.
          title: Text(l.nombre),
          trailing: Text(
            '${_conCapitulos[l.id]?.length ?? 0}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colores.textoSuave),
          ),
          // Y EL LIBRO QUE SE ESTA LEYENDO MARCADO, y con el capitulo actual al lado. Es
          // lo unico que dice donde estas, y abrir la hoja para no perder el sitio es
          // desconcertante.
          subtitle: l.id == abierto && leyendo != null
              ? Text(
                  'capitulo ${leyendo.capitulo}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colores.acento),
                )
              : null,
          selected: l.id == abierto,
          onTap: () => setState(() => _abrirLibro(l.id)),
        ),
    ];
  }

  Widget _capitulos(String libro) {
    final capitulos = _conCapitulos[libro] ?? const <int>[];
    final leyendo = widget.leyendo;
    // Y EL VERSICULO SE SACA **UNA VEZ** Y NO EN CADA FILA. Es el mismo dato para las
    // veinte, y una vez escrito como `leyendo?.libro == libro ? leyendo.versiculo : null`
    // dentro del `onTap` el analizador no lo puede narrowing porque `leyendo` es nullable:
    // dos preguntan al mismo objeto en la misma expresion y el compilador lo rechaza.
    final mismoLibro = leyendo != null && leyendo.libro == libro;
    final versiculo = mismoLibro ? leyendo.versiculo : null;

    if (capitulos.isEmpty) {
      return _vacio('Este texto no tiene capitulos en $libro.');
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Medidas.margenAncho),
      itemCount: capitulos.length,
      separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, i) {
        final n = capitulos[i];
        final frase = _primerasFrases[n] ?? '';
        final esElQueSeLee =
            leyendo != null && leyendo.libro == libro && leyendo.capitulo == n;

        return ListTile(
          // Y EL NUMERO EN UNA COLUMNA FIJA DE 56, y no delante del texto en la misma
          // linea. En una `ListTile` con `dense`, el titulo y el subtitulo se alinean a la
          // izquierda y las frases largas se descuadran en una escalera; con el numero en
          // una columna aparte todas las frases empiezan en el mismo pixel y se leen como
          // una lista.
          leading: SizedBox(
            width: 56,
            child: Text(
              '$n',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: esElQueSeLee ? Colores.acento : Colores.texto,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
            ),
          ),
          title: Text(
            frase,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: frase.isEmpty ? FontStyle.italic : null,
                  color: frase.isEmpty ? Colores.textoSuave : Colores.texto,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          selected: esElQueSeLee,
          // Y EL VERSICULO SE CONSERVA **EN EL MISMO LIBRO**, y no solo en el mismo
          // capitulo. Leer Juan 3:16 y abrir la hoja para ir a Juan 2 tiene que dejar en
          // Juan 2:16, que es el mismo versiculo del mismo sitio: perderlo aterrizaba en
          // Juan 2:1, que es un pasaje distinto, sin avisar.
          //
          // Y A OTRO LIBRO NO SE CONSERVA, porque no hay un "Juan 2:16" que signifique
          // algo en Josue.
          onTap: () => Navigator.of(context).pop(Referencia(libro, n, versiculo)),
        );
      },
    );
  }

  Widget _vacio(String texto) => Padding(
        padding: const EdgeInsets.all(Medidas.margenAncho),
        child: Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colores.textoSuave),
        ),
      );

  /// Los libros que casan con lo escrito: por nombre, por alias y por clave de modulo.
  ///
  /// Y POR LAS TRES COSAS, y el motivo de la tercera es que el filtro de arriba acepta
  /// una referencia: si se escribe `Jn` --la abreviatura que usa media gente-- y solo se
  /// buscase por nombre no saldria nada, y con `John` tampoco. Se busca en las tres y se
  /// enseñan una sola vez.
  List<Libro> _librosQueCasan(String texto) {
    final delModulo = _conCapitulos.keys;
    final enElModulo = <Libro>[
      for (final l in kLibros)
        if (delModulo.contains(l.id)) l,
    ];
    if (texto.isEmpty) return enElModulo;

    final ref = _referenciaDelTexto(texto);
    final elLibro = ref?.libro;
    if (elLibro != null && enElModulo.any((l) => l.id == elLibro)) {
      return enElModulo.where((l) => l.id == elLibro).toList();
    }

    final limpio = _normalizar(texto);
    return enElModulo.where((l) {
      if (_normalizar(l.nombre).contains(limpio)) return true;
      if (_normalizar(l.id).contains(limpio)) return true;
      return aliasDe(l).any((a) => _normalizar(a).contains(limpio));
    }).toList();
  }

  /// El texto escrito como referencia, o null si no lo es.
  ///
  /// Y USA EL MISMO LECTOR QUE EL CAMPO QUE ESTA SUSTITUYENDO, y no uno nuevo. Dos
  /// lectores de referencia en la misma pantalla son dos verdades, y basta que uno acepte
  /// "Juan 3.16" y el otro no para que el usuario escriba una vez y le falle.
  static Referencia? _referenciaDelTexto(String texto) => Referencia.tryParse(texto);

  static String _normalizar(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàä]'), 'a')
      .replaceAll(RegExp(r'[éèë]'), 'e')
      .replaceAll(RegExp(r'[íìï]'), 'i')
      .replaceAll(RegExp(r'[óòö]'), 'o')
      .replaceAll(RegExp(r'[úùü]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}