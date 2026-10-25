import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/lista_por_ver_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_por_ver.dart';
import '../widgets/estado_views.dart';
import '../widgets/poster_pelicula.dart';
import 'detalle_pelicula_screen.dart';

/// «Mi lista por ver»: lo guardado en el dispositivo con Hive. Funciona aunque
/// no haya conexión.
class ListaPorVerScreen extends StatelessWidget {
  const ListaPorVerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lista = Get.find<ListaPorVerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi lista por ver')),
      body: Obx(() {
        if (lista.peliculas.isEmpty) {
          return VacioView(
            mensaje: 'Tu lista está vacía.\nToca el marcador de una película para guardarla aquí.',
            accion: Get.back,
            textoAccion: 'Ir al catálogo',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          itemCount: lista.peliculas.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = lista.peliculas[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              leading: PosterPelicula(pelicula: p, ancho: 40),
              title: Text(p.titulo),
              subtitle: Text('${p.anio} · ${p.genero}'),
              trailing: BotonPorVer(pelicula: p),
              onTap: () => Get.to(() => DetallePeliculaScreen(pelicula: p)),
            );
          },
        );
      }),
    );
  }
}
