import 'dart:async';

import 'package:get/get.dart';

import '../models/resena.dart';
import '../repositories/peliculas_repository.dart' show DatosException;
import '../repositories/resenas_repository.dart';
import 'auth_controller.dart';
import 'catalogo_controller.dart' show EstadoCarga;

/// Reseñas de UNA película (se crea al abrir su ficha, con la película como
/// `tag`, y se elimina al salir). Escucha los cambios en tiempo real: si otra
/// persona publica una reseña, aparece sola.
class ResenasController extends GetxController {
  ResenasController(this.peliculaId, {ResenasRepository? repositorio})
      : _repositorio = repositorio ?? Get.find<ResenasRepository>();

  final String peliculaId;
  final ResenasRepository _repositorio;
  final _auth = Get.find<AuthController>();
  StreamSubscription<ResenasInstantanea>? _suscripcion;

  final RxList<Resena> resenas = <Resena>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;
  final RxBool desdeCache = false.obs;

  /// `true` mientras se guarda o borra la reseña propia.
  final RxBool enviando = false.obs;

  String? get _uid => _auth.usuario.value?.uid;

  /// La reseña de la persona con sesión, si ya escribió una.
  Resena? get miResena => resenas.firstWhereOrNull((r) => r.uid == _uid);

  double get promedio =>
      resenas.isEmpty ? 0 : resenas.map((r) => r.estrellas).reduce((a, b) => a + b) / resenas.length;

  @override
  void onInit() {
    super.onInit();
    escuchar();
  }

  @override
  void onClose() {
    _suscripcion?.cancel();
    super.onClose();
  }

  void escuchar() {
    _suscripcion?.cancel();
    estado.value = EstadoCarga.cargando;
    _suscripcion = _repositorio.escuchar(peliculaId).listen(
      (instantanea) {
        resenas.assignAll(instantanea.resenas);
        desdeCache.value = instantanea.desdeCache;
        estado.value = EstadoCarga.exito;
      },
      onError: (Object e) {
        mensajeError.value = e is DatosException ? e.mensaje : DatosException.desde(e).mensaje;
        estado.value = EstadoCarga.error;
      },
    );
  }

  /// Publica (o reemplaza) la reseña propia. Devuelve el mensaje de error, o
  /// `null` si salió bien.
  Future<String?> publicar(int estrellas, String texto) async {
    final usuario = _auth.usuario.value;
    if (usuario == null) return 'Inicia sesión para escribir una reseña.';
    return _ejecutar(() => _repositorio.guardar(peliculaId,
        uid: usuario.uid, autor: usuario.correo, estrellas: estrellas, texto: texto.trim()));
  }

  Future<String?> eliminarMiResena() async {
    final uid = _uid;
    if (uid == null) return 'Inicia sesión para borrar tu reseña.';
    return _ejecutar(() => _repositorio.eliminar(peliculaId, uid));
  }

  Future<String?> _ejecutar(Future<void> Function() accion) async {
    enviando.value = true;
    try {
      await accion();
      return null;
    } on DatosException catch (e) {
      return e.mensaje;
    } finally {
      enviando.value = false;
    }
  }
}
