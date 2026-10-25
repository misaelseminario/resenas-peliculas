import 'package:hive/hive.dart';

import '../models/pelicula.dart';

/// Lo que la app necesita de la lista «Por ver». El controlador depende de
/// esta interfaz y no de Hive: así las pruebas usan una lista en memoria.
abstract class ListaPorVerRepository {
  /// Abre la lista de esa persona (cada usuario tiene la suya).
  Future<void> abrir(String uid);

  Future<void> cerrar();

  /// Películas guardadas, la más reciente primero.
  List<Pelicula> leer();

  Future<void> agregar(Pelicula pelicula);

  Future<void> quitar(String peliculaId);
}

/// Implementación con Hive: guarda en el dispositivo (en la web, en IndexedDB),
/// así la lista sobrevive al cierre completo de la app. Solo guarda datos
/// públicos del catálogo, nada personal ni el token.
class HiveListaPorVerRepository implements ListaPorVerRepository {
  Box<Map>? _caja;

  @override
  Future<void> abrir(String uid) async {
    await cerrar();
    _caja = await Hive.openBox<Map>('por_ver_$uid');
  }

  @override
  Future<void> cerrar() async {
    await _caja?.close();
    _caja = null;
  }

  @override
  List<Pelicula> leer() {
    final caja = _caja;
    if (caja == null) return [];
    final entradas = caja.toMap().entries.toList()
      ..sort((a, b) => (b.value['agregada'] as int? ?? 0).compareTo(a.value['agregada'] as int? ?? 0));
    return entradas.map((e) => Pelicula.desdeMapa(e.key as String, Map<String, dynamic>.from(e.value))).toList();
  }

  @override
  Future<void> agregar(Pelicula pelicula) async {
    await _caja?.put(pelicula.id, {...pelicula.aMapa(), 'agregada': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Future<void> quitar(String peliculaId) async {
    await _caja?.delete(peliculaId);
  }
}
