/// Una película del catálogo (colección `peliculas` de Firestore).
class Pelicula {
  const Pelicula({
    required this.id,
    required this.titulo,
    required this.anio,
    required this.genero,
    required this.director,
    required this.duracion,
    required this.sinopsis,
  });

  final String id;
  final String titulo;
  final int anio;
  final String genero;
  final String director;

  /// Minutos.
  final int duracion;
  final String sinopsis;

  /// Para guardar la película en la lista local (Hive) con lo necesario para
  /// mostrarla aunque el catálogo todavía no haya cargado.
  Map<String, dynamic> aMapa() => {
        'titulo': titulo,
        'anio': anio,
        'genero': genero,
        'director': director,
        'duracion': duracion,
        'sinopsis': sinopsis,
      };

  factory Pelicula.desdeMapa(String id, Map<String, dynamic> datos) => Pelicula(
        id: id,
        titulo: datos['titulo'] as String? ?? 'Sin título',
        anio: (datos['anio'] as num?)?.toInt() ?? 0,
        genero: datos['genero'] as String? ?? 'otros',
        director: datos['director'] as String? ?? 'Desconocido',
        duracion: (datos['duracion'] as num?)?.toInt() ?? 0,
        sinopsis: datos['sinopsis'] as String? ?? '',
      );
}
