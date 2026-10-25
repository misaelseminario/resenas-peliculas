import 'package:get/get.dart';

import '../models/pelicula.dart';
import '../repositories/lista_por_ver_repository.dart';
import 'auth_controller.dart';

/// Estado de «Mi lista por ver», compartido por el catálogo, la ficha y la
/// pantalla de la lista. Se abre la lista de cada persona al iniciar sesión.
class ListaPorVerController extends GetxController {
  ListaPorVerController({ListaPorVerRepository? repositorio})
      : _repositorio = repositorio ?? Get.find<ListaPorVerRepository>();

  final ListaPorVerRepository _repositorio;
  final _auth = Get.find<AuthController>();

  final RxList<Pelicula> peliculas = <Pelicula>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.usuario, (u) => u == null ? _cerrar() : _abrir(u.uid));
    final u = _auth.usuario.value;
    if (u != null) _abrir(u.uid);
  }

  Future<void> _abrir(String uid) async {
    await _repositorio.abrir(uid);
    peliculas.assignAll(_repositorio.leer());
  }

  Future<void> _cerrar() async {
    // Solo se cierra: la lista queda guardada para cuando la persona vuelva.
    await _repositorio.cerrar();
    peliculas.clear();
  }

  bool estaEnLista(String peliculaId) => peliculas.any((p) => p.id == peliculaId);

  /// Agrega o quita la película. Devuelve `true` si quedó en la lista.
  Future<bool> alternar(Pelicula pelicula) async {
    if (estaEnLista(pelicula.id)) {
      await _repositorio.quitar(pelicula.id);
    } else {
      await _repositorio.agregar(pelicula);
    }
    peliculas.assignAll(_repositorio.leer());
    return estaEnLista(pelicula.id);
  }
}
