# AGENTS.md — reglas del proyecto Reseñas de Películas

Archivo de contexto para agentes de código (Claude Code, Codex, Antigravity…). Lo leen al abrir esta carpeta.

## Qué es el proyecto

App Flutter (Android y web) para explorar un catálogo de películas, escribir reseñas que ven todos los usuarios, guardar una lista «por ver» y pedir recomendaciones a un asistente de IA. Autenticación con Firebase Auth, datos remotos en Firestore, persistencia local con Hive, estado con GetX y un servidor propio en Node (`servidor-ia/`) que guarda la clave de IA.

## Dónde está cada cosa

- `lib/screens/` y `lib/widgets/` — pantallas y piezas de interfaz. **Nunca** llaman a Firebase, Hive ni HTTP.
- `lib/controllers/` — estado compartido (controladores GetX).
- `lib/services/` y `lib/repositories/` — único acceso a Firebase Auth, Firestore, Hive y al servidor de IA. Cada uno es una interfaz con su implementación real.
- `lib/models/`, `lib/utils/`, `lib/theme/` — modelos, validaciones y tema visual.
- `test/` y `test/fakes/` — pruebas con servicios falsos (sin red).
- `firestore.rules` — reglas de seguridad de Firestore. `servidor-ia/` — servidor del asistente.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test
```

Los dos deben terminar sin errores. No desactives el análisis ni borres pruebas para que pasen.

## Convenciones

- Pantalla → controlador GetX → servicio o repositorio → fuente de datos.
- Todo texto visible va en español neutro; los errores se muestran con mensajes claros, nunca con trazas técnicas.
- Cada pantalla con datos cubre cargando, vacío y error.
- Un cambio a la vez, con una prueba por cada comportamiento nuevo.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `.env`.
- Agregar dependencias nuevas sin avisar y explicar por qué.
- Ejecutar `git push`, crear etiquetas o publicar reglas de Firestore: eso lo hace la persona tras revisar el cambio.

## Reglas del proyecto

- Los nombres de clases, funciones y variables van en español, igual que en el resto del código.
- Antes de crear un widget nuevo, revisa si ya existe uno parecido en `lib/widgets/`.
