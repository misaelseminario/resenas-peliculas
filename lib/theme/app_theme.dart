import 'package:flutter/material.dart';

/// Colores, tipografía y espaciado de toda la app, en un solo lugar, para que
/// todas las pantallas se vean consistentes.
class AppTheme {
  static const Color primario = Color(0xFF4A148C);
  static const Color acento = Color(0xFFFFB300);

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primario, secondary: acento),
        appBarTheme: const AppBarTheme(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}

/// Espaciados estándar (múltiplos de 4).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
