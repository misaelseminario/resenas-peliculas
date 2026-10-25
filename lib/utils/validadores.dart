/// Validaciones de formulario. Firebase sigue siendo la autoridad: esto solo
/// evita enviar al servidor datos que de todas formas rechazaría.
class Validadores {
  static final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo';
    if (!_formatoCorreo.hasMatch(texto)) return 'El correo no tiene un formato válido';
    return null;
  }

  static String? clave(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Escribe tu contraseña';
    if (texto.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }
}
