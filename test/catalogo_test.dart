import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resenas_peliculas/controllers/auth_controller.dart';
import 'package:resenas_peliculas/controllers/catalogo_controller.dart';
import 'package:resenas_peliculas/controllers/lista_por_ver_controller.dart';
import 'package:resenas_peliculas/repositories/lista_por_ver_repository.dart';
import 'package:resenas_peliculas/models/pelicula.dart';
import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart';
import 'package:resenas_peliculas/screens/catalogo_screen.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

import 'fakes/auth_service_falso.dart';
import 'fakes/lista_por_ver_repository_falso.dart';
import 'fakes/peliculas_repository_falso.dart';

CatalogoController _montar(PeliculasRepository repositorio) {
  Get.reset();
  Get.testMode = true;
  Get.put<AuthService>(AuthServiceFalso(sesionGuardada: const UsuarioApp(uid: 'u1', correo: 'ana@correo.com')));
  Get.put(AuthController());
  Get.put<PeliculasRepository>(repositorio);
  Get.put<ListaPorVerRepository>(ListaPorVerRepositoryFalso());
  Get.put(ListaPorVerController());
  return Get.put(CatalogoController());
}

void main() {
  test('Pelicula.desdeMapa lee los campos de Firestore y tolera los que faltan', () {
    final p = Pelicula.desdeMapa('x', {'titulo': 'Coco', 'anio': 2017});
    expect(p.titulo, 'Coco');
    expect(p.anio, 2017);
    expect(p.genero, 'otros');
  });

  test('el filtro por género y la búsqueda se combinan', () async {
    final catalogo = _montar(PeliculasRepositoryFalso(peliculas: peliculasDePrueba));
    await catalogo.cargar();
    expect(catalogo.generos, ['animación', 'ciencia ficción']);

    catalogo.filtrarPorGenero('ciencia ficción');
    expect(catalogo.peliculasFiltradas.map((p) => p.titulo), ['Interestelar', 'Matrix']);

    catalogo.buscar('nolan');
    expect(catalogo.peliculasFiltradas.map((p) => p.titulo), ['Interestelar']);

    catalogo.quitarFiltros();
    expect(catalogo.peliculasFiltradas.length, 3);
  });

  test('cerrar sesión vacía el catálogo', () async {
    final catalogo = _montar(PeliculasRepositoryFalso(peliculas: peliculasDePrueba));
    await catalogo.cargar();
    await Get.find<AuthController>().cerrarSesion();
    expect(catalogo.peliculas, isEmpty);
  });

  testWidgets('la pantalla muestra el catálogo y filtra al tocar un género', (tester) async {
    final catalogo = _montar(PeliculasRepositoryFalso(peliculas: peliculasDePrueba));
    await catalogo.cargar();
    await tester.pumpWidget(const GetMaterialApp(home: CatalogoScreen()));
    await tester.pump();
    expect(find.text('Coco'), findsOneWidget);
    expect(find.text('Matrix'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'animación'));
    await tester.pump();
    expect(find.text('Coco'), findsOneWidget);
    expect(find.text('Matrix'), findsNothing);
  });

  testWidgets('una búsqueda sin resultados ofrece «Quitar filtros»', (tester) async {
    final catalogo = _montar(PeliculasRepositoryFalso(peliculas: peliculasDePrueba));
    await catalogo.cargar();
    await tester.pumpWidget(const GetMaterialApp(home: CatalogoScreen()));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Ninguna película coincide con tu búsqueda.'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pump();
    expect(find.text('Coco'), findsOneWidget);
  });

  testWidgets('un catálogo vacío muestra el estado vacío', (tester) async {
    final catalogo = _montar(PeliculasRepositoryFalso());
    await catalogo.cargar();
    await tester.pumpWidget(const GetMaterialApp(home: CatalogoScreen()));
    await tester.pump();
    expect(find.text('Aún no hay películas en el catálogo.'), findsOneWidget);
  });

  testWidgets('si falla la carga se ve el error con «Reintentar»', (tester) async {
    final catalogo = _montar(PeliculasRepositoryFalso(
        error: const DatosException('No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.')));
    await catalogo.cargar();
    await tester.pumpWidget(const GetMaterialApp(home: CatalogoScreen()));
    await tester.pump();
    expect(find.text('No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
