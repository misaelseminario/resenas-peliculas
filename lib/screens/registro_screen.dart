import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Crear una cuenta. Si Firebase la acepta, la sesión queda abierta y la app
/// pasa sola a la pantalla de inicio.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _auth.limpiarError();
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    await _auth.registrar(_correo.text, _clave.text);
    // Con la sesión abierta se vuelve a la raíz, que ya muestra el inicio.
    if (_auth.estaAutenticado) Get.until((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                    decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)'),
                    validator: Validadores.clave,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmacion,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Repite la contraseña'),
                    validator: (v) => v != _clave.text ? 'Las contraseñas no coinciden' : null,
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
                        onPressed: _auth.cargando.value ? null : _crear,
                        child: _auth.cargando.value
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Crear cuenta'),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
