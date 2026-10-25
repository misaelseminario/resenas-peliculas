import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resenas_peliculas/controllers/auth_controller.dart';
import 'package:resenas_peliculas/controllers/catalogo_controller.dart';
import 'package:resenas_peliculas/controllers/lista_por_ver_controller.dart';
import 'package:resenas_peliculas/repositories/lista_por_ver_repository.dart';
import 'package:resenas_peliculas/main.dart';
import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

import 'fakes/auth_service_falso.dart';
import 'fakes/lista_por_ver_repository_falso.dart';
import 'fakes/peliculas_repository_falso.dart';

AuthServiceFalso _montar({UsuarioApp? sesionGuardada}) {
  Get.reset();
  Get.testMode = true;
  final servicio = AuthServiceFalso(sesionGuardada: sesionGuardada);
  Get.put<AuthService>(servicio);
  Get.put(AuthController());
  Get.put<PeliculasRepository>(PeliculasRepositoryFalso());
  Get.put(CatalogoController());
  Get.put<ListaPorVerRepository>(ListaPorVerRepositoryFalso());
  Get.put(ListaPorVerController());
  return servicio;
}

void main() {
  test('iniciar sesión con la contraseña correcta deja el usuario', () async {
    _montar();
    final auth = Get.find<AuthController>();
    await auth.iniciarSesion('ana@correo.com', 'clave123');
    expect(auth.estaAutenticado, isTrue);
    expect(auth.usuario.value!.correo, 'ana@correo.com');
    expect(auth.mensajeError.value, isEmpty);
  });

  test('contraseña incorrecta muestra el mensaje y no abre sesión', () async {
    _montar();
    final auth = Get.find<AuthController>();
    await auth.iniciarSesion('ana@correo.com', 'otra-clave');
    expect(auth.estaAutenticado, isFalse);
    expect(auth.mensajeError.value, 'Correo o contraseña incorrectos.');
  });

  test('registrar un correo repetido muestra el mensaje del servicio', () async {
    _montar();
    final auth = Get.find<AuthController>();
    await auth.registrar('ana@correo.com', 'clave123');
    expect(auth.estaAutenticado, isFalse);
    expect(auth.mensajeError.value, 'Ya existe una cuenta con ese correo.');
  });

  test('cerrar sesión deja la app sin usuario', () async {
    _montar();
    final auth = Get.find<AuthController>();
    await auth.iniciarSesion('ana@correo.com', 'clave123');
    await auth.cerrarSesion();
    expect(auth.estaAutenticado, isFalse);
  });

  testWidgets('sin sesión se ve el login; un correo inválido se rechaza sin llamar al servicio', (tester) async {
    final servicio = _montar();
    await tester.pumpWidget(const ResenasApp());
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'no-es-correo');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    expect(find.text('El correo no tiene un formato válido'), findsOneWidget);
    expect(servicio.llamadas, 0);
  });

  testWidgets('con una sesión guardada se entra directo al catálogo', (tester) async {
    _montar(sesionGuardada: const UsuarioApp(uid: 'u1', correo: 'ana@correo.com'));
    await tester.pumpWidget(const ResenasApp());
    await tester.pumpAndSettle();
    expect(find.text('Películas'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsNothing);
  });
}
