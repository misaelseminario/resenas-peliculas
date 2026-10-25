import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resena.dart';
import 'peliculas_repository.dart' show DatosException;

/// Lo que llega en cada actualización de las reseñas de una película.
class ResenasInstantanea {
  const ResenasInstantanea(this.resenas, {this.desdeCache = false});

  final List<Resena> resenas;

  /// `true` si Firestore no pudo hablar con el servidor y muestra su copia
  /// local: la pantalla avisa que puede no estar al día.
  final bool desdeCache;
}

/// Lo que la app necesita de las reseñas. El controlador depende de esta
/// interfaz y no de Firestore: así las pruebas usan un repositorio falso.
abstract class ResenasRepository {
  /// Reseñas de una película, en tiempo real (la más reciente primero).
  Stream<ResenasInstantanea> escuchar(String peliculaId);

  /// Crea o reemplaza la reseña de `uid` en esa película.
  Future<void> guardar(String peliculaId, {required String uid, required String autor, required int estrellas, required String texto});

  Future<void> eliminar(String peliculaId, String uid);
}

/// Implementación real con Firestore. Las reglas (`firestore.rules`) validan
/// en el servidor quién puede escribir y qué contenido es válido.
class FirestoreResenasRepository implements ResenasRepository {
  FirestoreResenasRepository([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _resenas(String peliculaId) =>
      _db.collection('peliculas').doc(peliculaId).collection('resenas');

  @override
  Stream<ResenasInstantanea> escuchar(String peliculaId) {
    return _resenas(peliculaId)
        .orderBy('fecha', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => ResenasInstantanea(
              snap.docs.map((d) => _aResena(d.id, d.data())).toList(),
              desdeCache: snap.metadata.isFromCache,
            ))
        .handleError((Object e) => throw DatosException.desde(e));
  }

  @override
  Future<void> guardar(String peliculaId,
      {required String uid, required String autor, required int estrellas, required String texto}) async {
    try {
      await _resenas(peliculaId).doc(uid).set({
        'uid': uid,
        'autor': autor,
        'estrellas': estrellas,
        'texto': texto,
        'fecha': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const DatosException('No hay conexión: tu reseña se enviará cuando vuelva internet.');
    } catch (e) {
      throw DatosException.desde(e);
    }
  }

  @override
  Future<void> eliminar(String peliculaId, String uid) async {
    try {
      await _resenas(peliculaId).doc(uid).delete().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const DatosException('No hay conexión: la reseña se borrará cuando vuelva internet.');
    } catch (e) {
      throw DatosException.desde(e);
    }
  }

  Resena _aResena(String id, Map<String, dynamic> datos) => Resena(
        uid: datos['uid'] as String? ?? id,
        autor: datos['autor'] as String? ?? 'Anónimo',
        estrellas: (datos['estrellas'] as num?)?.toInt() ?? 0,
        texto: datos['texto'] as String? ?? '',
        fecha: (datos['fecha'] as Timestamp?)?.toDate(),
      );
}
