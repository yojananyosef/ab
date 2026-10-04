// Lo que la biblioteca dice por encima de la lista, y de que tipo es cada cosa.
//
// MEDIDO EL 4 DE OCTUBRE DE 2026, mirando la pantalla: veinte cajas rojas apiladas que
// decian
//
//     Bajando CLARKE: 90 por ciento
//     Bajando CLARKE: 80 por ciento
//     ...y diez mas de cada modulo
//
// Y ni un solo modulo en la lista. Tres fallos en uno, y los tres aqui:
//
//  1. **El progreso se guardaba como aviso de ERROR.** Todo lo que salia en la lista
//     era rojo, con triangulo, porque la lista no tenia tipos: `List<String>`.
//  2. **Los avisos no se reemplazaban, se acumulaban.** Un modulo de 57 MiB a trozos
//     de 4 MiB son diez mensajes, y se quedan **para siempre** los diez, despues de
//     haber terminado la descarga. El aviso "descargado y guardado" queda debajo de
//     nueve avisos que ya no son verdad.
//  3. **La lista no cabia.** Los avisos van **encima** de la lista, en un `Column`, y
//     veinte cajas de texto se comen la pantalla entera. Los `Expanded` de al lado
//     reciben lo que queda, que es nada.
//
// LA REGLA. Hay tres clases de cosa y se distinguen:
//
// | | Que es | Cuanto vive | Como se ve |
// | --- | --- | --- | --- |
// | [Aviso.error] | Algo no ha ido bien | hasta que se resuelve | rojo, con icono |
// | [Aviso.informacion] | Un hecho que hay que saber | hasta que se resuelve | neutro |
// | [Aviso.progreso] | Cuanto se ha bajado de un modulo concreto | **se reemplaza a si mismo** | barra, no una caja |
//
// Y LA SEPARACION DE [progreso] NO ES ESTETICA, ES LA QUE ARREGLA EL ACUMULO. Un
// progreso tiene que poder decir "ahora va por el 90 por ciento" **en el mismo sitio**
// donde decia "ahora va por el 80 por ciento". Eso necesita una clave, y por eso
// [progreso] lleva una: dos mensajes de progreso con la misma clave son el mismo
// mensaje.
//
// Y LOS ERRORES TAMBIEN SE RESUELVEN. Un error que ya no es verdad --"no se ha podido
// abrir el modulo" cuando ya se ha abierto-- y que sigue en pantalla teaches a quien
// lee que hay un problema que no hay. Por eso estan en una lista y hay una manera de
// quitarlos.

/// Que clase de aviso es. Y POR QUE NO ES UN BOOLEANO.
///
/// Con un `bool esError` se tiene justo el fallo que se ha arreglado: el progreso
/// tambien es un `bool esError` a `false`, y entonces comparte caja, comparte color y
/// comparte ciclo de vida con lo que no es un error. Un enum obliga a que **cada**
/// sitio que pinta un aviso decida cual de los tres esta pintando, y no puede
/// equivocarse por no pensar en ello.
enum ClaseDeAviso {
  /// Algo no ha ido bien y hay que decirlo.
  ///
  /// NO ES "lo que no me gusta". Un aviso de error se queda en pantalla hasta que se
  /// resuelve, asi que solo entra aqui lo que de verdad ha fallado.
  error,

  /// Un hecho que hay que saber pero que no es un fallo.
  ///
  /// "Se esta usando una copia guardada del catalogo del martes" es de aqui: no se ha
  /// roto nada, pero lo que se ve no es lo de hoy y hay que decirlo.
  informacion,
}

/// Un aviso, con su tipo y --si es de progreso-- su clave.
///
/// INMUTABLE A PROPOSITO. Se reemplaza entero, no se muta: un `List<String>` con
/// `copyWith` es mas codigo que un objeto con tres campos, y aqui los tres campos
/// existen porque el tipo del aviso **cambia lo que se pinta**.
class Aviso {
  const Aviso({
    required this.texto,
    this.clase = ClaseDeAviso.informacion,
    this.clave,
    this.id,
    this.porcentaje,
  });

  /// Un aviso de texto, sin clave ni progreso.
  factory Aviso.esteTexto(
    String texto, {
    ClaseDeAviso clase = ClaseDeAviso.informacion,
  }) => Aviso(texto: texto, clase: clase);

  /// Un aviso de progreso de la descarga de [id].
  ///
  /// CON CLAVE POR ID, y no una lista de datos. La clave es lo que hace que el 90 por
  /// ciento **reemplace** al 80 en lugar de acumularse con el: dos mensajes de
  /// progreso con el mismo id son el mismo mensaje visto en dos momentos.
  factory Aviso.progreso(String id, int porcentaje) => Aviso(
    texto: 'Bajando $id: $porcentaje por ciento',
    clase: ClaseDeAviso.informacion,
    clave: 'progreso:$id',
    id: id,
    porcentaje: porcentaje,
  );

  final String texto;
  final ClaseDeAviso clase;

  /// Que es lo que este aviso va contando, si va contando algo.
  ///
  /// Dos avisos con la misma clave no pueden convivir: el segundo **sustituye** al
  /// primero. Y es lo unico que evita que un modulo de 57 MiB deje diez lineas
  /// seleccionables en la pantalla.
  final String? clave;

  /// El modulo del que es este progreso. Para el mensaje y para la barra.
  final String? id;

  /// El porcentaje ya bajado, de 0 a 100. Null si este aviso no es de progreso.
  final int? porcentaje;

  bool get esError => clase == ClaseDeAviso.error;
  bool get esProgreso => porcentaje != null;

  @override
  bool operator ==(Object other) =>
      other is Aviso &&
      other.texto == texto &&
      other.clase == clase &&
      other.clave == clave &&
      other.porcentaje == porcentaje;

  @override
  int get hashCode => Object.hash(texto, clase, clave, porcentaje);

  @override
  String toString() => 'Aviso(${clase.name}, $texto)';
}