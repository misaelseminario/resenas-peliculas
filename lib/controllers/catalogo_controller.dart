import 'package:get/get.dart';

import '../models/pelicula.dart';
import '../repositories/peliculas_repository.dart';
import 'auth_controller.dart';

enum EstadoCarga { cargando, exito, error }

/// Estado del catálogo: la lista, el filtro por género y la búsqueda. Se carga
/// solo al iniciar sesión y se vacía al cerrarla.
class CatalogoController extends GetxController {
  CatalogoController({PeliculasRepository? repositorio}) : _repositorio = repositorio ?? Get.find<PeliculasRepository>();

  final PeliculasRepository _repositorio;
  final _auth = Get.find<AuthController>();

  final RxList<Pelicula> peliculas = <Pelicula>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;

  /// Género elegido en el filtro; `null` significa «Todos».
  final RxnString generoFiltro = RxnString();
  final RxString busqueda = ''.obs;

  /// Géneros presentes en el catálogo, en orden alfabético.
  List<String> get generos => (peliculas.map((p) => p.genero).toSet().toList()..sort());

  List<Pelicula> get peliculasFiltradas {
    final texto = busqueda.value.trim().toLowerCase();
    return peliculas
        .where((p) => generoFiltro.value == null || p.genero == generoFiltro.value)
        .where((p) => texto.isEmpty || p.titulo.toLowerCase().contains(texto) || p.director.toLowerCase().contains(texto))
        .toList();
  }

  bool get hayFiltros => generoFiltro.value != null || busqueda.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.usuario, (u) => u == null ? limpiar() : cargar());
    if (_auth.estaAutenticado) cargar();
  }

  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    try {
      peliculas.assignAll(await _repositorio.obtenerCatalogo());
      estado.value = EstadoCarga.exito;
    } on DatosException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  void filtrarPorGenero(String? genero) => generoFiltro.value = genero;

  void buscar(String texto) => busqueda.value = texto;

  void quitarFiltros() {
    generoFiltro.value = null;
    busqueda.value = '';
  }

  void limpiar() {
    peliculas.clear();
    quitarFiltros();
    mensajeError.value = '';
    estado.value = EstadoCarga.cargando;
  }
}
