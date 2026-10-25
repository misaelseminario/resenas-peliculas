import 'package:resenas_peliculas/models/pelicula.dart';
import 'package:resenas_peliculas/models/resena.dart';
import 'package:resenas_peliculas/services/asistente_service.dart';

/// Asistente sin red para las pruebas. Guarda lo último que recibió para
/// comprobar qué datos se enviarían al servidor.
class AsistenteServiceFalso implements AsistenteService {
  AsistenteServiceFalso({this.error});

  final AsistenteException? error;
  List<Pelicula> ultimoCatalogo = [];
  List<Resena> ultimasResenas = [];

  @override
  Future<String> recomendar(String consulta, {required List<Pelicula> catalogo, required List<Pelicula> porVer}) async {
    if (error != null) throw error!;
    ultimoCatalogo = catalogo;
    return 'Te recomiendo «${catalogo.first.titulo}».';
  }

  @override
  Future<String> resumirResenas(Pelicula pelicula, List<Resena> resenas) async {
    if (error != null) throw error!;
    ultimasResenas = resenas;
    return '«${pelicula.titulo}» tiene ${resenas.length} reseña(s).';
  }
}
