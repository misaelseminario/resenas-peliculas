import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/respuesta_ia.dart';

/// Asistente de recomendaciones: la persona escribe qué le apetece y la IA
/// sugiere películas SOLO del catálogo, teniendo en cuenta su lista.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _asistente = Get.find<AsistenteController>();
  final _pregunta = TextEditingController();

  static const _sugerencias = [
    'Recomiéndame algo de ciencia ficción',
    'Quiero una película animada para ver en familia',
    '¿Qué veo si me gustó Matrix?',
  ];

  @override
  void initState() {
    super.initState();
    _asistente.recomendacion.reiniciar();
  }

  @override
  void dispose() {
    _pregunta.dispose();
    super.dispose();
  }

  void _preguntar([String? texto]) {
    if (texto != null) _pregunta.text = texto;
    FocusScope.of(context).unfocus();
    _asistente.recomendar(_pregunta.text);
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _asistente.recomendacion;
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de películas')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text('Cuéntame qué te apetece ver y te recomiendo películas del catálogo.'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pregunta,
            maxLines: 2,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _preguntar(),
            decoration: const InputDecoration(labelText: '¿Qué te apetece ver?'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in _sugerencias)
                    ActionChip(label: Text(s), onPressed: consulta.cargando.value ? null : () => _preguntar(s)),
                ],
              )),
          const SizedBox(height: AppSpacing.md),
          Obx(() => FilledButton.icon(
                onPressed: consulta.cargando.value ? null : _preguntar,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Preguntar'),
              )),
          const SizedBox(height: AppSpacing.md),
          RespuestaIA(consulta: consulta),
        ],
      ),
    );
  }
}
