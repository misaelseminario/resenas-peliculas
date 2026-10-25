import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

/// Pantalla principal con sesión iniciada. En el bloque 2 muestra el catálogo
/// de películas; por ahora confirma quién inició sesión y permite salir.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: auth.cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Obx(() => Text(
                'Hola, ${auth.usuario.value?.correo ?? ''}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              )),
        ),
      ),
    );
  }
}
