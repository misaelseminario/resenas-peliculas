import 'package:flutter/material.dart';

import '../models/pelicula.dart';
import '../theme/app_theme.dart';
import '../widgets/poster_pelicula.dart';

/// Ficha de una película. En el bloque 3 se agregan aquí las reseñas.
class DetallePeliculaScreen extends StatelessWidget {
  const DetallePeliculaScreen({super.key, required this.pelicula});

  final Pelicula pelicula;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(pelicula.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterPelicula(pelicula: pelicula, ancho: 96),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pelicula.titulo, style: textos.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _Dato(icono: Icons.calendar_today, texto: '${pelicula.anio}'),
                    _Dato(icono: Icons.category, texto: pelicula.genero),
                    _Dato(icono: Icons.person, texto: pelicula.director),
                    _Dato(icono: Icons.schedule, texto: '${pelicula.duracion} min'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Sinopsis', style: textos.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(pelicula.sinopsis, style: textos.bodyLarge),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
