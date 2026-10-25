import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/resenas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/estrellas.dart';

/// Hoja inferior para escribir o editar la reseña propia. Las mismas reglas
/// que valida el servidor (1 a 5 estrellas, 3 a 500 caracteres) se revisan
/// aquí para no enviar algo que Firestore rechazaría.
class FormularioResena extends StatefulWidget {
  const FormularioResena({super.key, required this.controller});

  final ResenasController controller;

  static Future<void> abrir(BuildContext context, ResenasController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FormularioResena(controller: controller),
    );
  }

  @override
  State<FormularioResena> createState() => _FormularioResenaState();
}

class _FormularioResenaState extends State<FormularioResena> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _texto;
  late int _estrellas;
  String? _error;

  @override
  void initState() {
    super.initState();
    final mia = widget.controller.miResena;
    _texto = TextEditingController(text: mia?.texto ?? '');
    _estrellas = mia?.estrellas ?? 0;
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_estrellas == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await widget.controller.publicar(_estrellas, _texto.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      Get.snackbar('Reseña publicada', 'Gracias por compartir tu opinión.', snackPosition: SnackPosition.BOTTOM);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.controller.miResena != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editando ? 'Editar mi reseña' : 'Escribir reseña',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SelectorEstrellas(valor: _estrellas, alCambiar: (v) => setState(() => _estrellas = v)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _texto,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: '¿Qué te pareció?'),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Escribe al menos 3 caracteres' : null,
            ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: AppSpacing.sm),
            ],
            Obx(() => FilledButton(
                  onPressed: widget.controller.enviando.value ? null : _publicar,
                  child: widget.controller.enviando.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(editando ? 'Guardar cambios' : 'Publicar'),
                )),
          ],
        ),
      ),
    );
  }
}
