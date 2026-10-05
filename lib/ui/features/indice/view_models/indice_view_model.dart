// El indice de una palabra del lexicon en el texto abierto.
//
// QUE RECIBE Y QUE NO. Recibe el modulo ya abierto, por la misma razon que el lector: el
// que elige el texto es la biblioteca y el enrutador, y si el indice recibiera el
// repositorio habria dos sitios decidiendo cual se mira.
//
// Y NO SABE NADA DEL LEXICON. No hay significado, no hay transliteracion, no hay raiz. El
// indice es una cuenta y una lista, y las dos salen del modulo.

import 'package:flutter/foundation.dart';

import 'package:ab/domain/models/indice_de_strong.dart';

/// En que punto esta el indice de una palabra.
enum EstadoDeIndice {
  /// Se esta recorriendo el texto.
  cargando,

  /// Hay entradas.
  conEntradas,

  /// El numero no sale en este texto.
  vacio,

  /// El modulo no se pudo consultar.
  fallo,
}

/// Lo que el indice necesita de un modulo abierto.
///
/// Y ES UNA INTERFAZ Y NO EL `ModuloAbierto` ENTERO, por lo mismo que en la busqueda:
/// `ModuloAbierto` no se puede construir en una prueba sin abrir un `.amod` de 22 MiB, y
/// estas pruebas no necesitan uno.
abstract class ModuloIndiciable {
  /// Cuantos versiculos tienen el numero [numero].
  int versiculosConStrong(String numero);

  /// Los versiculos que lo tienen, con las palabras que lo llevan.
  List<IndiceDeStrong> indiceDeStrong(String numero);

  /// Las formas de la palabra y cuantas veces sale cada una en lo indeksado.
  Map<String, int> formasDeStrong(String numero);
}

class IndiceViewModel extends ChangeNotifier {
  IndiceViewModel({ModuloIndiciable? moduloIndiciable}) : _modulo = moduloIndiciable;

  ModuloIndiciable? _modulo;

  ModuloIndiciable? get modulo => _modulo;

  EstadoDeIndice _estado = EstadoDeIndice.cargando;
  String _numero = '';
  List<IndiceDeStrong> _entradas = const <IndiceDeStrong>[];
  Map<String, int> _formas = const <String, int>{};
  int _versiculos = 0;
  String _motivoDelFallo = '';

  /// El numero del lexicon que se esta indexando, tal cual lo trae el modulo.
  String get numero => _numero;

  EstadoDeIndice get estado => _estado;

  /// Los versiculos que tienen el numero, con las palabras.
  List<IndiceDeStrong> get entradas => _entradas;

  /// Las escrituras de la palabra en este texto y su cuenta, de mas a menos.
  Map<String, int> get formas => _formas;

  /// Cuantos versiculos del texto entero tienen el numero.
  ///
  /// Y ES DISTINTO DE [entradas.length], y la diferencia son los que no caben en el
  /// limite. Sin los dos numeros, quien ve 200 lineas no sabe si son todas.
  int get versiculos => _versiculos;

  String get motivoDelFallo => _motivoDelFallo;

  /// Abre el modulo y calcula el indice del numero [numero].
  ///
  /// Y SON **DOS** LLAMADAS AL MODULO Y NO UNA, y hay un motivo: `versiculosConStrong` es
  /// un `count(*)` de 15 ms y `indiceDeStrong` trae las filas. Juntas serian una sola
  /// consulta con una ventana, y el total saldría del `count` de la ventana --que es el
  /// limite-- y no del total real, que es lo unico que distingue "estos son todos" de
  /// "estos son algunos".
  Future<void> abrir(ModuloIndiciable modulo, {required String numero}) async {
    _modulo = modulo;
    _numero = numero;
    _estado = EstadoDeIndice.cargando;
    _motivoDelFallo = '';
    notifyListeners();

    try {
      _versiculos = modulo.versiculosConStrong(numero);
      _entradas = _versiculos == 0 ? const <IndiceDeStrong>[] : modulo.indiceDeStrong(numero);
      _formas = modulo.formasDeStrong(numero);
      _estado = _entradas.isEmpty ? EstadoDeIndice.vacio : EstadoDeIndice.conEntradas;
    } catch (e) {
      _estado = EstadoDeIndice.fallo;
      _entradas = const <IndiceDeStrong>[];
      _formas = const <String, int>{};
      _motivoDelFallo = 'No se ha podido recorrer el texto: $e';
    }
    notifyListeners();
  }
}
