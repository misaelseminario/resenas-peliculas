import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:resenas_peliculas/controllers/asistente_controller.dart';
import 'package:resenas_peliculas/controllers/auth_controller.dart';
import 'package:resenas_peliculas/controllers/catalogo_controller.dart';
import 'package:resenas_peliculas/controllers/lista_por_ver_controller.dart';
import 'package:resenas_peliculas/models/usuario_app.dart';
import 'package:resenas_peliculas/repositories/lista_por_ver_repository.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart';
import 'package:resenas_peliculas/screens/asistente_screen.dart';
import 'package:resenas_peliculas/services/asistente_service.dart';
import 'package:resenas_peliculas/services/auth_service.dart';

import 'fakes/asistente_service_falso.dart';
import 'fakes/auth_service_falso.dart';
import 'fakes/lista_por_ver_repository_falso.dart';
import 'fakes/peliculas_repository_falso.dart';

/// Registra todo sin esperas (sirve también dentro del reloj simulado de las
/// pruebas de widgets). El catálogo se carga solo al ver la sesión; hay que
/// dejar correr las microtareas antes de preguntar.
AsistenteController _montar({AsistenteException? error}) {
  Get.reset();
  Get.testMode = true;
  Get.put<AuthService>(AuthServiceFalso(sesionGuardada: const UsuarioApp(uid: 'u1', correo: 'ana@correo.com')));
  Get.put(AuthController());
  Get.put<PeliculasRepository>(PeliculasRepositoryFalso(peliculas: peliculasDePrueba));
  Get.put(CatalogoController());
  Get.put<ListaPorVerRepository>(ListaPorVerRepositoryFalso());
  Get.put(ListaPorVerController());
  Get.put<AsistenteService>(AsistenteServiceFalso(error: error));
  return Get.put(AsistenteController());
}

DioException _respuesta(int codigo, [String? detalle]) => DioException(
      requestOptions: RequestOptions(path: '/asistente'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/asistente'),
        statusCode: codigo,
        data: detalle == null ? null : {'detail': detalle},
      ),
    );

void main() {
  test('una recomendación llega con la respuesta y usa el catálogo cargado', () async {
    final asistente = _montar();
    await Future<void>.delayed(Duration.zero);
    await asistente.recomendar('algo de ciencia ficción');
    expect(asistente.recomendacion.respuesta.value, 'Te recomiendo «Coco».');
    expect(asistente.recomendacion.error.value, isEmpty);
    final servicio = Get.find<AsistenteService>() as AsistenteServiceFalso;
    expect(servicio.ultimoCatalogo.length, 3);
  });

  test('una pregunta vacía no llama al servidor y explica qué falta', () async {
    final asistente = _montar();
    await Future<void>.delayed(Duration.zero);
    await asistente.recomendar('   ');
    expect(asistente.recomendacion.error.value, 'Escribe qué tipo de película te apetece.');
  });

  test('si el servidor falla se guarda el mensaje de error', () async {
    final asistente = _montar(error: const AsistenteException('No se pudo conectar con el asistente.'));
    await Future<void>.delayed(Duration.zero);
    await asistente.recomendar('comedia');
    expect(asistente.recomendacion.error.value, 'No se pudo conectar con el asistente.');
    expect(asistente.recomendacion.respuesta.value, isEmpty);
  });

  test('cada tipo de falla tiene su propio mensaje', () {
    final sinRed = DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError);
    expect(HttpAsistenteService.mensajeDeError(sinRed), contains('No se pudo conectar'));
    expect(HttpAsistenteService.mensajeDeError(_respuesta(401)), 'Tu sesión no es válida. Inicia sesión de nuevo.');
    expect(HttpAsistenteService.mensajeDeError(_respuesta(422, 'Escribe una pregunta.')), 'Escribe una pregunta.');
    expect(HttpAsistenteService.mensajeDeError(_respuesta(429)), contains('límite'));
    expect(HttpAsistenteService.mensajeDeError(_respuesta(502)), contains('problema'));
  });

  testWidgets('la pantalla muestra la respuesta con el aviso de que es una sugerencia', (tester) async {
    _montar();
    await tester.pumpWidget(const GetMaterialApp(home: AsistenteScreen()));
    await tester.pump();
    await tester.tap(find.text('Recomiéndame algo de ciencia ficción'));
    await tester.pumpAndSettle();
    expect(find.text('Te recomiendo «Coco».'), findsOneWidget);
    expect(find.text('Sugerencia de IA: verifica antes de decidir.'), findsOneWidget);
  });
}
