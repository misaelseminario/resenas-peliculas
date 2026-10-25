import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/pelicula.dart';
import '../models/resena.dart';
import 'auth_service.dart';

/// Dirección del servidor propio del asistente. Se cambia al ejecutar con
/// `--dart-define=ASISTENTE_URL=...`. Por defecto: `localhost` en la web y
/// `10.0.2.2` en el emulador Android (así ve el emulador a tu computador).
/// La app NO conoce ninguna clave de IA: solo esta dirección.
String get urlAsistente {
  const definida = String.fromEnvironment('ASISTENTE_URL');
  if (definida.isNotEmpty) return definida;
  return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
}

/// Error del asistente con un mensaje listo para mostrar.
class AsistenteException implements Exception {
  const AsistenteException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Lo que la app necesita del asistente. El controlador depende de esta
/// interfaz: las pruebas usan una versión falsa sin red.
abstract class AsistenteService {
  Future<String> resumirResenas(Pelicula pelicula, List<Resena> resenas);

  Future<String> recomendar(String consulta, {required List<Pelicula> catalogo, required List<Pelicula> porVer});
}

/// Implementación real: llama al servidor propio (`servidor-ia/`) con el token
/// de Firebase en la cabecera. Envía solo datos mínimos: ni correos ni nombres
/// de las personas que escribieron las reseñas.
class HttpAsistenteService implements AsistenteService {
  HttpAsistenteService({required this.auth, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: urlAsistente,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 25),
            ));

  /// De aquí sale el token de la sesión para la cabecera `Authorization`.
  final AuthService auth;
  final Dio _dio;

  @override
  Future<String> resumirResenas(Pelicula pelicula, List<Resena> resenas) => _preguntar({
        'tipo': 'resumen',
        'pelicula': {'titulo': pelicula.titulo, 'anio': pelicula.anio, 'genero': pelicula.genero},
        'resenas': [for (final r in resenas) {'estrellas': r.estrellas, 'texto': r.texto}],
      });

  @override
  Future<String> recomendar(String consulta, {required List<Pelicula> catalogo, required List<Pelicula> porVer}) =>
      _preguntar({
        'tipo': 'recomendacion',
        'consulta': consulta,
        'catalogo': [for (final p in catalogo) {'titulo': p.titulo, 'anio': p.anio, 'genero': p.genero}],
        'porVer': [for (final p in porVer) {'titulo': p.titulo, 'genero': p.genero}],
      });

  Future<String> _preguntar(Map<String, dynamic> cuerpo) async {
    final token = await auth.tokenActual();
    if (token == null) throw const AsistenteException('Inicia sesión para usar el asistente.');
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/asistente',
        data: cuerpo,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (r.data?['respuesta'] as String?) ?? 'El asistente no devolvió una respuesta.';
    } on DioException catch (e) {
      throw AsistenteException(mensajeDeError(e));
    }
  }

  /// Mensajes distintos según quién falló: la red, la sesión, la petición,
  /// el proveedor de IA o el propio servidor.
  static String mensajeDeError(DioException e) {
    final detalle = e.response?.data is Map ? (e.response!.data as Map)['detail'] as String? : null;
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el asistente. ¿Está encendido el servidor (servidor-ia)?';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'El asistente tardó demasiado en responder. Inténtalo de nuevo.';
      default:
        break;
    }
    final codigo = e.response?.statusCode;
    if (codigo == 401) return 'Tu sesión no es válida. Inicia sesión de nuevo.';
    if (codigo == 400 || codigo == 422) return detalle ?? 'La consulta no es válida.';
    if (codigo == 429) return detalle ?? 'Se alcanzó el límite de consultas a la IA. Inténtalo más tarde.';
    if (codigo != null && codigo >= 500) return detalle ?? 'El asistente tuvo un problema. Inténtalo de nuevo.';
    return 'No se pudo completar la consulta al asistente.';
  }
}
