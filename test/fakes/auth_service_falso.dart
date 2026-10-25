import 'dart:async';

import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

/// `AuthService` en memoria para las pruebas: no necesita Firebase ni internet.
/// Imita lo importante: cuentas con contraseña, errores con mensaje y el flujo
/// de cambios de sesión.
class AuthServiceFalso implements AuthService {
  AuthServiceFalso({UsuarioApp? sesionGuardada}) : _actual = sesionGuardada;

  final _cuentas = <String, String>{'ana@correo.com': 'clave123'};
  final _cambios = StreamController<UsuarioApp?>.broadcast();
  UsuarioApp? _actual;
  int llamadas = 0;

  @override
  Stream<UsuarioApp?> cambiosDeSesion() async* {
    yield _actual;
    yield* _cambios.stream;
  }

  @override
  Future<UsuarioApp> iniciarSesion(String correo, String clave) async {
    llamadas++;
    if (_cuentas[correo] != clave) throw const AuthException('Correo o contraseña incorrectos.');
    return _abrir(correo);
  }

  @override
  Future<UsuarioApp> registrar(String correo, String clave) async {
    llamadas++;
    if (_cuentas.containsKey(correo)) throw const AuthException('Ya existe una cuenta con ese correo.');
    _cuentas[correo] = clave;
    return _abrir(correo);
  }

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
    _cambios.add(null);
  }

  UsuarioApp _abrir(String correo) {
    _actual = UsuarioApp(uid: 'uid-$correo', correo: correo);
    _cambios.add(_actual);
    return _actual!;
  }
}
