import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pelicula.dart';

/// Error al leer o guardar datos, con un mensaje listo para mostrar.
class DatosException implements Exception {
  const DatosException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;

  /// Traduce los errores de Firestore a mensajes en español.
  static DatosException desde(Object error) {
    if (error is DatosException) return error;
    if (error is TimeoutException) {
      return const DatosException('El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.');
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return const DatosException('No tienes permiso para hacer esto. Inicia sesión de nuevo.');
        case 'unavailable':
        case 'deadline-exceeded':
          return const DatosException('No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.');
      }
    }
    return const DatosException('Algo salió mal con los datos. Inténtalo de nuevo.');
  }
}

/// Lo que la app necesita del catálogo. El controlador depende de esta
/// interfaz y no de Firestore: así las pruebas usan un repositorio falso.
abstract class PeliculasRepository {
  Future<List<Pelicula>> obtenerCatalogo();
}

/// Implementación real: lee la colección `peliculas` de Firestore.
class FirestorePeliculasRepository implements PeliculasRepository {
  FirestorePeliculasRepository([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Pelicula>> obtenerCatalogo() async {
    try {
      final snap = await _db.collection('peliculas').orderBy('titulo').get().timeout(const Duration(seconds: 15));
      return snap.docs.map((d) => Pelicula.desdeMapa(d.id, d.data())).toList();
    } catch (e) {
      throw DatosException.desde(e);
    }
  }
}
