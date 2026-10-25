import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'registro_screen.dart';

/// Inicio de sesión. El estado de la sesión vive en `AuthController`; aquí solo
/// quedan los campos del formulario.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  @override
  void initState() {
    super.initState();
    _auth.limpiarError();
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    await _auth.iniciarSesion(_correo.text, _clave.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas de Películas')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.movie_filter, size: 72, color: AppTheme.primario),
                  const SizedBox(height: AppSpacing.md),
                  Text('Inicia sesión',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: Validadores.correo,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clave,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: Validadores.clave,
                    onFieldSubmitted: (_) => _entrar(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() => _auth.mensajeError.value.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(_auth.mensajeError.value,
                              style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        )),
                  Obx(() => FilledButton(
                        onPressed: _auth.cargando.value ? null : _entrar,
                        child: _auth.cargando.value
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Entrar'),
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Get.to(() => const RegistroScreen()),
                    child: const Text('¿No tienes cuenta? Crea una'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
