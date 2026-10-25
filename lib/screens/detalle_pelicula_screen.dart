import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/catalogo_controller.dart' show EstadoCarga;
import '../controllers/resenas_controller.dart';
import '../models/pelicula.dart';
import '../models/resena.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_views.dart';
import '../widgets/estrellas.dart';
import '../widgets/poster_pelicula.dart';
import 'formulario_resena.dart';

/// Ficha de una película con sus reseñas en tiempo real.
class DetallePeliculaScreen extends StatefulWidget {
  const DetallePeliculaScreen({super.key, required this.pelicula});

  final Pelicula pelicula;

  @override
  State<DetallePeliculaScreen> createState() => _DetallePeliculaScreenState();
}

class _DetallePeliculaScreenState extends State<DetallePeliculaScreen> {
  late final ResenasController _resenas;

  @override
  void initState() {
    super.initState();
    // Un controlador por película (tag = id), vivo solo mientras está abierta.
    _resenas = Get.put(ResenasController(widget.pelicula.id), tag: widget.pelicula.id);
  }

  @override
  void dispose() {
    Get.delete<ResenasController>(tag: widget.pelicula.id);
    super.dispose();
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Eliminar tu reseña?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true) return;
    final error = await _resenas.eliminarMiResena();
    Get.snackbar(error == null ? 'Reseña eliminada' : 'No se pudo eliminar', error ?? 'Tu reseña se borró.',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pelicula;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(p.titulo)),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            onPressed: _resenas.enviando.value ? null : () => FormularioResena.abrir(context, _resenas),
            icon: Icon(_resenas.miResena == null ? Icons.rate_review : Icons.edit),
            label: Text(_resenas.miResena == null ? 'Escribir reseña' : 'Editar mi reseña'),
          )),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterPelicula(pelicula: p, ancho: 96),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.titulo, style: textos.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _Dato(icono: Icons.calendar_today, texto: '${p.anio}'),
                    _Dato(icono: Icons.category, texto: p.genero),
                    _Dato(icono: Icons.person, texto: p.director),
                    _Dato(icono: Icons.schedule, texto: '${p.duracion} min'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Sinopsis', style: textos.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(p.sinopsis, style: textos.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          Obx(_buildResenas),
        ],
      ),
    );
  }

  Widget _buildResenas() {
    final textos = Theme.of(context).textTheme;
    switch (_resenas.estado.value) {
      case EstadoCarga.cargando:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      case EstadoCarga.error:
        return ErrorView(mensaje: _resenas.mensajeError.value, onReintentar: _resenas.escuchar);
      case EstadoCarga.exito:
        final lista = _resenas.resenas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Reseñas (${lista.length})', style: textos.titleMedium),
                const Spacer(),
                if (lista.isNotEmpty) ...[
                  Estrellas(valor: _resenas.promedio),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_resenas.promedio.toStringAsFixed(1)),
                ],
              ],
            ),
            if (_resenas.desdeCache.value)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(child: Text('Sin conexión: las reseñas pueden no estar al día.')),
                  ],
                ),
              ),
            if (lista.isEmpty)
              const VacioView(mensaje: 'Aún no hay reseñas. ¡Sé la primera persona en opinar!')
            else
              for (final r in lista) _TarjetaResena(resena: r, esMia: r.uid == _resenas.miResena?.uid, alEliminar: _confirmarEliminar),
          ],
        );
    }
  }
}

class _TarjetaResena extends StatelessWidget {
  const _TarjetaResena({required this.resena, required this.esMia, required this.alEliminar});

  final Resena resena;
  final bool esMia;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final f = resena.fecha;
    final fecha = f == null ? 'Enviando...' : '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Estrellas(valor: resena.estrellas.toDouble(), tamano: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(esMia ? '${resena.nombreVisible} (tú)' : resena.nombreVisible,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(fecha, style: Theme.of(context).textTheme.bodySmall),
                if (esMia)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar mi reseña',
                    onPressed: alEliminar,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(resena.texto),
          ],
        ),
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
