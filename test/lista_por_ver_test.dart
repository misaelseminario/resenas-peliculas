import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:resenas_peliculas/controllers/auth_controller.dart';
import 'package:resenas_peliculas/controllers/lista_por_ver_controller.dart';
import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/repositories/lista_por_ver_repository.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

import 'fakes/auth_service_falso.dart';
import 'fakes/lista_por_ver_repository_falso.dart';
import 'fakes/peliculas_repository_falso.dart';

void main() {
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync('hive_por_ver').path));

  test('con Hive real, la lista sigue ahí después de cerrar y volver a abrir', () async {
    final repo = HiveListaPorVerRepository();
    await repo.abrir('u1');
    await repo.agregar(peliculasDePrueba[0]);
    await repo.agregar(peliculasDePrueba[1]);
    await repo.cerrar();

    // Simula el cierre completo de la app: un repositorio nuevo lee del disco.
    final otraVez = HiveListaPorVerRepository();
    await otraVez.abrir('u1');
    expect(otraVez.leer().map((p) => p.titulo), ['Coco', 'Matrix']);
    expect(otraVez.leer().first.director, 'Lee Unkrich');
    await otraVez.cerrar();
  });

  test('cada usuario tiene su propia lista', () async {
    final repo = HiveListaPorVerRepository();
    await repo.abrir('u2');
    expect(repo.leer(), isEmpty);
    await repo.cerrar();
  });

  test('el controlador agrega y quita con alternar', () async {
    Get.reset();
    Get.testMode = true;
    Get.put<AuthService>(AuthServiceFalso(sesionGuardada: const UsuarioApp(uid: 'u1', correo: 'ana@correo.com')));
    Get.put(AuthController());
    Get.put<ListaPorVerRepository>(ListaPorVerRepositoryFalso());
    final lista = Get.put(ListaPorVerController());
    await Future<void>.delayed(Duration.zero);

    expect(await lista.alternar(peliculasDePrueba[0]), isTrue);
    expect(lista.estaEnLista('matrix'), isTrue);
    expect(await lista.alternar(peliculasDePrueba[0]), isFalse);
    expect(lista.peliculas, isEmpty);
  });
}
