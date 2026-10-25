import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resenas_peliculas/controllers/auth_controller.dart';
import 'package:resenas_peliculas/controllers/resenas_controller.dart';
import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart' show DatosException;
import 'package:resenas_peliculas/repositories/resenas_repository.dart';
import 'package:resenas_peliculas/screens/detalle_pelicula_screen.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

import 'fakes/auth_service_falso.dart';
import 'fakes/peliculas_repository_falso.dart';
import 'fakes/resenas_repository_falso.dart';

ResenasRepositoryFalso _montar() {
  Get.reset();
  Get.testMode = true;
  Get.put<AuthService>(AuthServiceFalso(sesionGuardada: const UsuarioApp(uid: 'yo', correo: 'ana@correo.com')));
  Get.put(AuthController());
  final repo = ResenasRepositoryFalso();
  Get.put<ResenasRepository>(repo);
  return repo;
}

Future<void> _esperarMicrotareas() => Future<void>.delayed(Duration.zero);

void main() {
  test('publicar una reseña la muestra y la marca como propia', () async {
    _montar();
    final c = Get.put(ResenasController('coco'));
    await _esperarMicrotareas();

    expect(await c.publicar(5, '  Preciosa  '), isNull);
    await _esperarMicrotareas();
    expect(c.resenas.length, 1);
    expect(c.miResena!.texto, 'Preciosa');
    expect(c.miResena!.autor, 'ana@correo.com');
  });

  test('la reseña de otra persona aparece sola (tiempo real) y cuenta en el promedio', () async {
    final repo = _montar();
    final c = Get.put(ResenasController('coco'));
    await _esperarMicrotareas();
    await c.publicar(5, 'Preciosa');
    await repo.agregarDeOtraPersona('coco', estrellas: 3);
    await _esperarMicrotareas();

    expect(c.resenas.length, 2);
    expect(c.promedio, 4.0);
    expect(c.miResena!.uid, 'yo');
  });

  test('eliminar mi reseña la quita y deja la de los demás', () async {
    final repo = _montar();
    final c = Get.put(ResenasController('coco'));
    await _esperarMicrotareas();
    await c.publicar(5, 'Preciosa');
    await repo.agregarDeOtraPersona('coco');
    await c.eliminarMiResena();
    await _esperarMicrotareas();

    expect(c.miResena, isNull);
    expect(c.resenas.single.autor, 'luis@correo.com');
  });

  test('si no se pueden leer las reseñas queda el estado de error con su mensaje', () async {
    final repo = _montar();
    repo.errorAlEscuchar = const DatosException('No tienes permiso para hacer esto. Inicia sesión de nuevo.');
    final c = Get.put(ResenasController('coco'));
    await _esperarMicrotareas();
    expect(c.mensajeError.value, 'No tienes permiso para hacer esto. Inicia sesión de nuevo.');
  });

  testWidgets('la ficha sin reseñas invita a escribir la primera', (tester) async {
    _montar();
    await tester.pumpWidget(GetMaterialApp(home: DetallePeliculaScreen(pelicula: peliculasDePrueba[1])));
    await tester.pump();
    expect(find.text('Aún no hay reseñas. ¡Sé la primera persona en opinar!'), findsOneWidget);
    expect(find.text('Escribir reseña'), findsOneWidget);
  });

  testWidgets('el formulario exige elegir estrellas antes de publicar', (tester) async {
    _montar();
    await tester.pumpWidget(GetMaterialApp(home: DetallePeliculaScreen(pelicula: peliculasDePrueba[1])));
    await tester.pump();
    await tester.tap(find.text('Escribir reseña'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Muy buena');
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
    await tester.pump();
    expect(find.text('Elige de 1 a 5 estrellas.'), findsOneWidget);
  });
}
