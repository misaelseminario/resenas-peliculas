import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../theme/app_theme.dart';

/// Muestra el estado de una consulta a la IA: cargando, error o respuesta,
/// siempre con el aviso de que es una sugerencia.
class RespuestaIA extends StatelessWidget {
  const RespuestaIA({super.key, required this.consulta});

  final ConsultaIA consulta;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Obx(() {
      if (consulta.cargando.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: AppSpacing.md),
            Text('El asistente está pensando...'),
          ]),
        );
      }
      if (consulta.error.value.isNotEmpty) {
        return Card(
          color: colores.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Icon(Icons.error_outline, color: colores.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(consulta.error.value, style: TextStyle(color: colores.onErrorContainer))),
            ]),
          ),
        );
      }
      if (consulta.respuesta.value.isEmpty) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppTheme.acento),
                const SizedBox(width: AppSpacing.sm),
                Text('Sugerencia de IA: verifica antes de decidir.', style: Theme.of(context).textTheme.labelMedium),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text(consulta.respuesta.value),
            ],
          ),
        ),
      );
    });
  }
}
