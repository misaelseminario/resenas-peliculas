import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario_app.dart';

/// Error de autenticación con un mensaje listo para mostrar a la persona.
class AuthException implements Exception {
  const AuthException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Lo que la app necesita de la autenticación. El controlador depende de esta
/// interfaz y no de Firebase: así las pruebas usan un servicio falso.
abstract class AuthService {
  /// Emite el usuario cada vez que la sesión cambia (`null` = sin sesión).
  Stream<UsuarioApp?> cambiosDeSesion();

  Future<UsuarioApp> registrar(String correo, String clave);

  Future<UsuarioApp> iniciarSesion(String correo, String clave);

  Future<void> cerrarSesion();

  /// Token de identidad de la sesión actual, para servidores propios (el
  /// asistente). Se usa solo en la cabecera `Authorization`; nunca se imprime.
  Future<String?> tokenActual();
}

/// Implementación real con Firebase Authentication. El token lo guarda y lo
/// renueva el propio SDK; la app nunca lo lee ni lo imprime.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<UsuarioApp?> cambiosDeSesion() => _auth.authStateChanges().map(_aUsuario);

  @override
  Future<UsuarioApp> registrar(String correo, String clave) =>
      _ejecutar(() => _auth.createUserWithEmailAndPassword(email: correo, password: clave));

  @override
  Future<UsuarioApp> iniciarSesion(String correo, String clave) =>
      _ejecutar(() => _auth.signInWithEmailAndPassword(email: correo, password: clave));

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  @override
  Future<String?> tokenActual() async => _auth.currentUser?.getIdToken();

  Future<UsuarioApp> _ejecutar(Future<UserCredential> Function() accion) async {
    try {
      final credencial = await accion();
      return _aUsuario(credencial.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mensajeDeError(e.code));
    }
  }

  UsuarioApp? _aUsuario(User? u) => u == null ? null : UsuarioApp(uid: u.uid, correo: u.email ?? '');

  /// Traduce los códigos de Firebase a mensajes en español.
  static String mensajeDeError(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es muy débil: usa al menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
      default:
        return 'No se pudo completar la operación. Inténtalo de nuevo.';
    }
  }
}
