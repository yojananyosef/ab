// La tipografia de confort: que se pueda **elegir** la letra.
//
// ============================================================================
// POR QUE ESTE FICHERO EXISTE
// ============================================================================
//
// MEDIDO EL 7 DE OCTUBRE DE 2026: un `grep` de `fontFamily` en `pubspec.yaml` y en `lib/`
// no devuelve **nada**, y en el repositorio no hay ni un `.ttf`. El texto se pinta con la
// fuente que traiga el sistema: Roboto en Android, la del navegador en web.
//
// Y ESO, EN UN LECTOR DE BIBLIA, NO ES UNA FALTA DE RESPETO A LA DISLEXIA: es solo la falta
// de una opcion. **No se puede elegir nada.** Y quien lee con dislexia necesita poder elegir,
// porque lo que le ayuda es una fuente y no un tamano. Hay tres cosas que se tocan en la hoja
// de formato --tamano, alto de linea y espaciado-- y la fuente no estaba, que es la que mas
// distingue a unas letras de otras.
//
// ============================================================================
// Y LAS TRES SON DEL REPO HERMANO, Y LAS TRES SON LIBRES
// ============================================================================
//
// `aletheia-reader` las llama «Tipografia de Accesibilidad Cognitiva», y son:
//
//   - **Literata**, la de Amazon Kindle. Con serifa, la de «leer un libro».
//   - **Atkinson Hyperlegible**, del Braille Institute. Sin serifa, con las **i**, las **l** y
//     el **1** dibujados de forma que no se confundan entre si.
//   - **OpenDyslexic**, con la letra de pie pesada y la base ancha, que es lo que hace que las
//     letras no se separen al leer.
//
// Las tres son **SIL Open Font License 1.1**, que permite redistribuir, y la licencia de cada
// una esta al lado en `assets/fuentes/`.
//
// Y HAY UN AVISO EN LA LICENCIA DE OPENDYSLEXIC QUE IMPORTA: tiene **nombre reservado**. Si
// alguien cambia el nombre de la fuente y la vuelve a publicar, la licencia lo prohibe. Por eso
// el nombre de la familia es el de verdad y no uno abreviado, y por eso esta nota esta aqui:
// es el unico sitio donde el cambio de nombre seria un problema legal y no solo de estilo.
//
// ============================================================================
// Y POR QUE HAY UNA CUARTA, «La del sistema», Y NO TRES OPCIONES
// ============================================================================
//
// Porque la fuente del sistema es la que alguien ya tiene ajustada en su pantalla, con su
// tamano de letra y su contraste, y cambiarsela a alguien que ya esta bien es molestia. Y en un
// movil, donde el sistema ya tiene una fuente de accesibilidad configurada --Android
//allowlist y el tamano del texto del sistema--, respetarla es lo correcto.
//
// ============================================================================
// Y POR QUE GUARDAR LA **FAMILIA** Y NO UN NUMERO
// ============================================================================
//
// Por el mismo motivo por el que un resaltado guarda un **estilo** y no un color: si alguien
// marca un versiculo con «amarillo» y lo reexporta, tiene que salir el amarillo que eligio
// quien marco, no el que tenga la instalacion de al lado. Y con las fuentes pasa igual: si
// guardamos el indice de una lista, al reimportar en otra version el «2» puede ser otra
// cosa. Guardando la familia --«Literata»-- el fichero se entiende en cualquier sitio.

/// La tipografia de confort que se puede elegir.
enum TipografiaDeLectura {
  sistema('La del sistema', null),
  literata('Literata (con serifa)', 'Literata'),
  atkinson('Atkinson Hyperlegible', 'Atkinson'),
  openDyslexic('OpenDyslexic', 'OpenDyslexic');

  const TipografiaDeLectura(this.rotulo, this.familia);

  /// Como sale en la hoja de formato.
  ///
  /// Y CON EL MOTIVO DE CADA UNA, y no solo el nombre. «Atkinson Hyperlegible» no dice a quien
  /// le sirve: una hoja con tres nombres de fuente y ninguna explicación hace que quien no sepa
  /// cual elegir la elija al azar, que es como se quedan las tres sin usar.
  final String rotulo;

  /// La familia que entiende Flutter, o `null` para la del sistema.
  ///
  /// Y ES `null` Y NO UN NOMBRE, y no por pereza: la fuente del sistema **no tiene nombre** en
  /// Flutter. Ponerle un nombre inventado seria hacer que `fontFamily` valiera y el motor
  /// dejaria de encontrar la fuente del sistema, con lo que el texto saldría con la fuente de
  /// reserva --que es lo mismo que no tener fuente-- y nadie sabria por que.
  final String? familia;

  /// La explicacion corta, para el menu.
  String get motivo => switch (this) {
        TipografiaDeLectura.sistema =>
          'La que tenga ya su pantalla ajustada. La respeta la del sistema.',
        TipografiaDeLectura.literata =>
          'Con serifa, como un libro. La de las novelas.',
        TipografiaDeLectura.atkinson =>
          'La i, la l y el uno no se confunden. Del Braille Institute.',
        TipografiaDeLectura.openDyslexic =>
          'Letra de pie pesada y base ancha: las letras no se separan.',
      };

  /// Leer una familia guardada, y **volver a la del sistema** si no se reconoce.
  ///
  /// Y NO LANZA, y no por robustez: el fichero de preferencias es **dato de la persona** y un
  /// nombre que no se reconoce tiene que poder venir de una version anterior que si lo tenia.
  /// Tirar la preferencia entera porque una fuente desaparecio seria perder los ajustes de
  /// tamano, alto de linea y espaciado por un nombre, que es justo el fallo que `AGENTS.md`
  /// llama el peor posible.
  static TipografiaDeLectura desdeFamilia(String? familia) {
    if (familia == null) return TipografiaDeLectura.sistema;
    for (final t in TipografiaDeLectura.values) {
      if (t.familia == familia) return t;
    }
    return TipografiaDeLectura.sistema;
  }
}
