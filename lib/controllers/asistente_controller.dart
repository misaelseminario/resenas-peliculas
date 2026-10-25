import 'package:get/get.dart';

import '../models/pelicula.dart';
import '../models/resena.dart';
import '../services/asistente_service.dart';
import 'catalogo_controller.dart';
import 'lista_por_ver_controller.dart';

/// Resultado de una consulta al asistente: lo que muestra la pantalla.
class ConsultaIA {
  final RxBool cargando = false.obs;
  final RxString respuesta = ''.obs;
  final RxString error = ''.obs;

  void reiniciar() {
    respuesta.value = '';
    error.value = '';
  }
}

/// Estado del asistente de IA: recomendaciones a partir del catálogo y la
/// lista «por ver», y resúmenes de las reseñas de una película.
class AsistenteController extends GetxController {
  AsistenteController({AsistenteService? servicio}) : _servicio = servicio ?? Get.find<AsistenteService>();

  final AsistenteService _servicio;

  final recomendacion = ConsultaIA();
  final resumen = ConsultaIA();

  Future<void> recomendar(String consulta) async {
    if (consulta.trim().isEmpty) {
      recomendacion.error.value = 'Escribe qué tipo de película te apetece.';
      return;
    }
    await _ejecutar(
      recomendacion,
      () => _servicio.recomendar(
        consulta.trim(),
        catalogo: Get.find<CatalogoController>().peliculas,
        porVer: Get.find<ListaPorVerController>().peliculas,
      ),
    );
  }

  Future<void> resumirResenas(Pelicula pelicula, List<Resena> resenas) =>
      _ejecutar(resumen, () => _servicio.resumirResenas(pelicula, resenas));

  Future<void> _ejecutar(ConsultaIA consulta, Future<String> Function() accion) async {
    consulta.cargando.value = true;
    consulta.reiniciar();
    try {
      consulta.respuesta.value = await accion();
    } on AsistenteException catch (e) {
      consulta.error.value = e.mensaje;
    } finally {
      consulta.cargando.value = false;
    }
  }
}
