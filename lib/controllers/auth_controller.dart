import 'dart:async';

import 'package:get/get.dart';

import '../models/usuario_app.dart';
import '../services/auth_service.dart';

/// Estado de la sesión, compartido por toda la app. Las pantallas solo leen
/// este controlador; nunca llaman a Firebase directamente.
class AuthController extends GetxController {
  AuthController({AuthService? servicio}) : _servicio = servicio ?? Get.find<AuthService>();

  final AuthService _servicio;
  StreamSubscription<UsuarioApp?>? _suscripcion;

  final Rxn<UsuarioApp> usuario = Rxn<UsuarioApp>();

  /// `true` mientras Firebase dice si había una sesión guardada (al abrir).
  final RxBool comprobandoSesion = true.obs;

  /// `true` mientras se envía el formulario de inicio o registro.
  final RxBool cargando = false.obs;
  final RxString mensajeError = ''.obs;

  bool get estaAutenticado => usuario.value != null;

  @override
  void onInit() {
    super.onInit();
    // Por qué: Firebase recuerda la sesión entre reinicios; al abrir la app
    // emite el usuario guardado (o `null`) y desde ahí cada cambio.
    _suscripcion = _servicio.cambiosDeSesion().listen((u) {
      usuario.value = u;
      comprobandoSesion.value = false;
    });
  }

  @override
  void onClose() {
    _suscripcion?.cancel();
    super.onClose();
  }

  Future<void> iniciarSesion(String correo, String clave) =>
      _ejecutar(() => _servicio.iniciarSesion(correo.trim(), clave));

  Future<void> registrar(String correo, String clave) =>
      _ejecutar(() => _servicio.registrar(correo.trim(), clave));

  Future<void> cerrarSesion() async {
    await _servicio.cerrarSesion();
    usuario.value = null;
  }

  void limpiarError() => mensajeError.value = '';

  Future<void> _ejecutar(Future<UsuarioApp> Function() accion) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      usuario.value = await accion();
    } on AuthException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }
}
