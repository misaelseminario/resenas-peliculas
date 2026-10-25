import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/lista_por_ver_controller.dart';
import '../models/pelicula.dart';

/// Botón de marcador para agregar o quitar una película de «Mi lista por ver».
/// Se usa en el catálogo y en la ficha: el estado vive en el controlador.
class BotonPorVer extends StatelessWidget {
  const BotonPorVer({super.key, required this.pelicula, this.color});

  final Pelicula pelicula;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final lista = Get.find<ListaPorVerController>();
    return Obx(() {
      final guardada = lista.estaEnLista(pelicula.id);
      return IconButton(
        tooltip: guardada ? 'Quitar de mi lista' : 'Agregar a mi lista',
        color: color,
        icon: Icon(guardada ? Icons.bookmark : Icons.bookmark_border),
        onPressed: () async {
          final quedo = await lista.alternar(pelicula);
          Get.closeAllSnackbars();
          Get.snackbar(
            quedo ? 'Agregada a tu lista' : 'Quitada de tu lista',
            pelicula.titulo,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
      );
    });
  }
}
