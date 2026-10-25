/// La persona con sesión iniciada. Solo lo que la app necesita: el resto de
/// la cuenta lo guarda Firebase Auth.
class UsuarioApp {
  const UsuarioApp({required this.uid, required this.correo});

  final String uid;
  final String correo;
}
