import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/catalogo_controller.dart';
import 'controllers/lista_por_ver_controller.dart';
import 'firebase_options.dart';
import 'repositories/lista_por_ver_repository.dart';
import 'repositories/peliculas_repository.dart';
import 'repositories/resenas_repository.dart';
import 'screens/catalogo_screen.dart';
import 'screens/login_screen.dart';
import 'services/asistente_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/cargando_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Get.put<AuthService>(FirebaseAuthService(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put<PeliculasRepository>(FirestorePeliculasRepository(), permanent: true);
  Get.put(CatalogoController(), permanent: true);
  Get.put<ResenasRepository>(FirestoreResenasRepository(), permanent: true);
  Get.put<ListaPorVerRepository>(HiveListaPorVerRepository(), permanent: true);
  Get.put(ListaPorVerController(), permanent: true);
  Get.put<AsistenteService>(HttpAsistenteService(auth: Get.find<AuthService>()), permanent: true);
  Get.put(AsistenteController(), permanent: true);
  runApp(const ResenasApp());
}

class ResenasApp extends StatelessWidget {
  const ResenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Reseñas de Películas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: const PuertaSesion(),
    );
  }
}

/// Decide qué ver según la sesión: cambia sola al iniciar o cerrar sesión.
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.comprobandoSesion.value) {
        return const Scaffold(body: CargandoView(mensaje: 'Comprobando sesión...'));
      }
      return auth.estaAutenticado ? const CatalogoScreen() : const LoginScreen();
    });
  }
}
