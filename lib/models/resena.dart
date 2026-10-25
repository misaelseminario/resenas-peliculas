/// Reseña de una película (subcolección `peliculas/{id}/resenas`). Su id es el
/// uid de quien la escribió: una reseña por persona y película.
class Resena {
  const Resena({
    required this.uid,
    required this.autor,
    required this.estrellas,
    required this.texto,
    this.fecha,
  });

  final String uid;

  /// Correo de quien la escribió.
  final String autor;

  /// De 1 a 5.
  final int estrellas;
  final String texto;

  /// La pone el servidor; es `null` un instante mientras la reseña nueva viaja.
  final DateTime? fecha;

  /// Lo que se muestra como nombre: la parte del correo antes de la arroba.
  String get nombreVisible => autor.contains('@') ? autor.substring(0, autor.indexOf('@')) : autor;
}
