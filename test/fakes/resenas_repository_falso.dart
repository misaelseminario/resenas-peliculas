import 'dart:async';

import 'package:resenas_peliculas/models/resena.dart';
import 'package:resenas_peliculas/repositories/peliculas_repository.dart' show DatosException;
import 'package:resenas_peliculas/repositories/resenas_repository.dart';

/// Reseñas en memoria para las pruebas. Cada cambio se emite por el flujo,
/// igual que Firestore en tiempo real; `agregarDeOtraPersona` simula que otro
/// usuario publica desde su teléfono.
class ResenasRepositoryFalso implements ResenasRepository {
  final _porPelicula = <String, Map<String, Resena>>{};
  final _flujos = <String, StreamController<ResenasInstantanea>>{};
  DatosException? errorAlEscuchar;

  StreamController<ResenasInstantanea> _flujo(String peliculaId) =>
      _flujos.putIfAbsent(peliculaId, () => StreamController<ResenasInstantanea>.broadcast());

  void _emitir(String peliculaId) {
    final lista = (_porPelicula[peliculaId] ?? {}).values.toList().reversed.toList();
    _flujo(peliculaId).add(ResenasInstantanea(lista));
  }

  @override
  Stream<ResenasInstantanea> escuchar(String peliculaId) async* {
    if (errorAlEscuchar != null) throw errorAlEscuchar!;
    yield ResenasInstantanea((_porPelicula[peliculaId] ?? {}).values.toList().reversed.toList());
    yield* _flujo(peliculaId).stream;
  }

  @override
  Future<void> guardar(String peliculaId,
      {required String uid, required String autor, required int estrellas, required String texto}) async {
    _porPelicula.putIfAbsent(peliculaId, () => {})[uid] =
        Resena(uid: uid, autor: autor, estrellas: estrellas, texto: texto, fecha: DateTime(2026, 10, 25));
    _emitir(peliculaId);
  }

  @override
  Future<void> eliminar(String peliculaId, String uid) async {
    _porPelicula[peliculaId]?.remove(uid);
    _emitir(peliculaId);
  }

  Future<void> agregarDeOtraPersona(String peliculaId, {int estrellas = 4}) =>
      guardar(peliculaId, uid: 'otra', autor: 'luis@correo.com', estrellas: estrellas, texto: 'Me encantó');
}
