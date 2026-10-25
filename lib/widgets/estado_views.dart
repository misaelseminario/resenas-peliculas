import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado «error»: explica qué pasó y ofrece reintentar (nunca un callejón
/// sin salida).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(onPressed: onReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Estado «vacío»: no hay nada que mostrar, con una acción opcional.
class VacioView extends StatelessWidget {
  const VacioView({super.key, required this.mensaje, this.accion, this.textoAccion});

  final String mensaje;
  final VoidCallback? accion;
  final String? textoAccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(mensaje, textAlign: TextAlign.center),
            if (accion != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: accion, child: Text(textoAccion ?? 'Volver')),
            ],
          ],
        ),
      ),
    );
  }
}
