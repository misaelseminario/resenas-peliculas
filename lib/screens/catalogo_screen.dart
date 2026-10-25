import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/catalogo_controller.dart';
import '../models/pelicula.dart';
import '../theme/app_theme.dart';
import '../widgets/cargando_view.dart';
import '../widgets/estado_views.dart';
import '../widgets/poster_pelicula.dart';
import 'detalle_pelicula_screen.dart';

/// Pantalla principal: el catálogo con búsqueda y filtro por género. Cubre los
/// tres estados: cargando, vacío y error.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _catalogo = Get.find<CatalogoController>();
  final _auth = Get.find<AuthController>();
  final _textoBusqueda = TextEditingController();

  @override
  void dispose() {
    _textoBusqueda.dispose();
    super.dispose();
  }

  void _quitarFiltros() {
    _textoBusqueda.clear();
    _catalogo.quitarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Recargar', onPressed: _catalogo.cargar),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: _auth.cerrarSesion),
        ],
      ),
      body: Obx(() {
        switch (_catalogo.estado.value) {
          case EstadoCarga.cargando:
            return const CargandoView(mensaje: 'Cargando películas...');
          case EstadoCarga.error:
            return ErrorView(mensaje: _catalogo.mensajeError.value, onReintentar: _catalogo.cargar);
          case EstadoCarga.exito:
            if (_catalogo.peliculas.isEmpty) {
              return VacioView(
                mensaje: 'Aún no hay películas en el catálogo.',
                accion: _catalogo.cargar,
                textoAccion: 'Recargar',
              );
            }
            return Column(
              children: [
                _buildBusqueda(),
                _buildFiltroGenero(),
                Expanded(child: _buildLista(_catalogo.peliculasFiltradas)),
              ],
            );
        }
      }),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: TextField(
        controller: _textoBusqueda,
        onChanged: _catalogo.buscar,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Buscar por título o director',
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFiltroGenero() {
    final seleccionado = _catalogo.generoFiltro.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: seleccionado == null,
            onSelected: (_) => _catalogo.filtrarPorGenero(null),
          ),
          for (final genero in _catalogo.generos) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(genero),
              selected: seleccionado == genero,
              onSelected: (_) => _catalogo.filtrarPorGenero(genero),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLista(List<Pelicula> peliculas) {
    if (peliculas.isEmpty) {
      return VacioView(
        mensaje: 'Ninguna película coincide con tu búsqueda.',
        accion: _quitarFiltros,
        textoAccion: 'Quitar filtros',
      );
    }
    return RefreshIndicator(
      onRefresh: _catalogo.cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: peliculas.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = peliculas[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            leading: PosterPelicula(pelicula: p, ancho: 40),
            title: Text(p.titulo),
            subtitle: Text('${p.anio} · ${p.genero} · ${p.director}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => DetallePeliculaScreen(pelicula: p)),
          );
        },
      ),
    );
  }
}
