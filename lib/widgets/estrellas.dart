import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra una calificación de 0 a 5 estrellas (admite medias para el promedio).
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.tamano = 18});

  final double valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${valor.toStringAsFixed(1)} de 5 estrellas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              valor >= i ? Icons.star : (valor >= i - 0.5 ? Icons.star_half : Icons.star_border),
              size: tamano,
              color: AppTheme.acento,
            ),
        ],
      ),
    );
  }
}

/// Selector de 1 a 5 estrellas para el formulario.
class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({super.key, required this.valor, required this.alCambiar});

  final int valor;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
            iconSize: 36,
            onPressed: () => alCambiar(i),
            icon: Icon(valor >= i ? Icons.star : Icons.star_border, color: AppTheme.acento),
          ),
      ],
    );
  }
}
