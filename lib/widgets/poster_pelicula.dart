import 'package:flutter/material.dart';

import '../models/pelicula.dart';

/// Póster ilustrado: un color y un ícono según el género, con la inicial del
/// título. No descarga imágenes de terceros, así no depende de URLs externas
/// ni de sus licencias.
class PosterPelicula extends StatelessWidget {
  const PosterPelicula({super.key, required this.pelicula, this.ancho = 56});

  final Pelicula pelicula;
  final double ancho;

  static const _colores = {
    'acción': Color(0xFFC62828),
    'animación': Color(0xFFEF6C00),
    'aventura': Color(0xFF2E7D32),
    'ciencia ficción': Color(0xFF1565C0),
    'comedia': Color(0xFFF9A825),
    'crimen': Color(0xFF37474F),
    'drama': Color(0xFF6A1B9A),
    'fantasía': Color(0xFF00838F),
    'romance': Color(0xFFAD1457),
    'suspenso': Color(0xFF4E342E),
    'terror': Color(0xFF212121),
  };

  static const _iconos = {
    'acción': Icons.local_fire_department,
    'animación': Icons.auto_awesome,
    'aventura': Icons.explore,
    'ciencia ficción': Icons.rocket_launch,
    'comedia': Icons.sentiment_very_satisfied,
    'crimen': Icons.gavel,
    'drama': Icons.theater_comedy,
    'fantasía': Icons.castle,
    'romance': Icons.favorite,
    'suspenso': Icons.visibility,
    'terror': Icons.dark_mode,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colores[pelicula.genero] ?? Colors.blueGrey;
    return Container(
      width: ancho,
      height: ancho * 1.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.45)!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconos[pelicula.genero] ?? Icons.movie, color: Colors.white70, size: ancho * 0.4),
          Text(
            pelicula.titulo.characters.firstWhere((c) => RegExp(r'[A-Za-zÁÉÍÓÚÑ]').hasMatch(c), orElse: () => '?'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: ancho * 0.35),
          ),
        ],
      ),
    );
  }
}
