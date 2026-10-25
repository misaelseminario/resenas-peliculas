import 'package:resenas_peliculas/models/pelicula.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart';

/// Catálogo en memoria para las pruebas. Con `error` simula una falla de red.
class PeliculasRepositoryFalso implements PeliculasRepository {
  PeliculasRepositoryFalso({this.peliculas = const [], this.error});

  final List<Pelicula> peliculas;
  final DatosException? error;

  @override
  Future<List<Pelicula>> obtenerCatalogo() async {
    if (error != null) throw error!;
    return [...peliculas]..sort((a, b) => a.titulo.compareTo(b.titulo));
  }
}

const peliculasDePrueba = [
  Pelicula(id: 'matrix', titulo: 'Matrix', anio: 1999, genero: 'ciencia ficción', director: 'Lana y Lilly Wachowski', duracion: 136, sinopsis: '...'),
  Pelicula(id: 'coco', titulo: 'Coco', anio: 2017, genero: 'animación', director: 'Lee Unkrich', duracion: 105, sinopsis: '...'),
  Pelicula(id: 'interestelar', titulo: 'Interestelar', anio: 2014, genero: 'ciencia ficción', director: 'Christopher Nolan', duracion: 169, sinopsis: '...'),
];
