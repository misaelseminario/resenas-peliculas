import 'package:resenas_peliculas/models/pelicula.dart';
import 'package:resenas_peliculas/repositories/lista_por_ver_repository.dart';

/// Lista «Por ver» en memoria para las pruebas de pantallas y controladores.
class ListaPorVerRepositoryFalso implements ListaPorVerRepository {
  final _porUsuario = <String, List<Pelicula>>{};
  String? _uid;

  @override
  Future<void> abrir(String uid) async => _uid = uid;

  @override
  Future<void> cerrar() async => _uid = null;

  @override
  List<Pelicula> leer() => _uid == null ? [] : List.of(_porUsuario[_uid] ?? []);

  @override
  Future<void> agregar(Pelicula pelicula) async => _porUsuario.putIfAbsent(_uid!, () => []).insert(0, pelicula);

  @override
  Future<void> quitar(String peliculaId) async => _porUsuario[_uid]?.removeWhere((p) => p.id == peliculaId);
}
