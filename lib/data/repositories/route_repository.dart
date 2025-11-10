/// Repository de Rutas
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de rutas
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de rutas
/// - Gestión de rutas guardadas
/// - Comunicación con RouteApiService
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api/route_api_service.dart';
import '../models/route_model.dart';
import 'dart:math';

class RouteRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de rutas
  final RouteApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de rutas
  RouteRepository({RouteApiService? apiService})
    : _apiService = apiService ?? RouteApiService();

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Obtiene todas las rutas de un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de rutas del usuario
  Future<List<RouteModel>> getUserRoutes(String userId) async {
    try {
      return await _apiService.getUserRoutes(userId);
    } catch (e) {
      throw Exception('Error al obtener rutas del usuario: ${e.toString()}');
    }
  }

  /// Obtiene una ruta por ID
  ///
  /// [routeId] - ID de la ruta
  ///
  /// Retorna:
  /// - RouteModel de la ruta
  /// - null si no se encuentra
  Future<RouteModel?> getRouteById(String routeId) async {
    try {
      return await _apiService.getRouteById(routeId);
    } catch (e) {
      throw Exception('Error al obtener ruta: ${e.toString()}');
    }
  }

  /// Crea una nueva ruta
  ///
  /// [userId] - ID del usuario que crea la ruta
  /// [nombreRuta] - Nombre de la ruta
  /// [descripcionRuta] - Descripción (opcional)
  /// [puntos] - Lista de puntos GPS de la ruta
  /// [distanciaKm] - Distancia total en km (opcional)
  /// [duracionMinutos] - Duración en minutos (opcional)
  /// [imagenUrl] - URL de imagen asociada (opcional)
  ///
  /// Retorna:
  /// - RouteModel de la ruta creada
  Future<RouteModel> createRoute({
    required String userId,
    required String nombreRuta,
    String? descripcionRuta,
    required List<LatLng> puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  }) async {
    try {
      if (puntos.isEmpty) {
        throw Exception('La ruta debe tener al menos un punto');
      }

      return await _apiService.createRoute(
        userId: userId,
        nombreRuta: nombreRuta,
        descripcionRuta: descripcionRuta,
        puntos: puntos,
        distanciaKm: distanciaKm,
        duracionMinutos: duracionMinutos,
        imagenUrl: imagenUrl,
      );
    } catch (e) {
      throw Exception('Error al crear ruta: ${e.toString()}');
    }
  }

  /// Actualiza una ruta existente
  ///
  /// [routeId] - ID de la ruta
  /// [nombreRuta] - Nuevo nombre (opcional)
  /// [descripcionRuta] - Nueva descripción (opcional)
  /// [puntos] - Nuevos puntos GPS (opcional)
  /// [distanciaKm] - Nueva distancia (opcional)
  /// [duracionMinutos] - Nueva duración (opcional)
  /// [imagenUrl] - Nueva URL de imagen (opcional)
  Future<void> updateRoute({
    required String routeId,
    String? nombreRuta,
    String? descripcionRuta,
    List<LatLng>? puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  }) async {
    try {
      await _apiService.updateRoute(
        routeId: routeId,
        nombreRuta: nombreRuta,
        descripcionRuta: descripcionRuta,
        puntos: puntos,
        distanciaKm: distanciaKm,
        duracionMinutos: duracionMinutos,
        imagenUrl: imagenUrl,
      );
    } catch (e) {
      throw Exception('Error al actualizar ruta: ${e.toString()}');
    }
  }

  /// Elimina una ruta
  ///
  /// [routeId] - ID de la ruta
  Future<void> deleteRoute(String routeId) async {
    try {
      await _apiService.deleteRoute(routeId);
    } catch (e) {
      throw Exception('Error al eliminar ruta: ${e.toString()}');
    }
  }

  /// Obtiene rutas recientes de todos los usuarios
  ///
  /// [limit] - Número máximo de rutas a obtener
  ///
  /// Retorna:
  /// - Lista de rutas recientes
  Future<List<RouteModel>> getRecentRoutes({int limit = 20}) async {
    try {
      return await _apiService.getRecentRoutes(limit: limit);
    } catch (e) {
      throw Exception('Error al obtener rutas recientes: ${e.toString()}');
    }
  }

  /// Busca rutas por nombre
  ///
  /// [query] - Texto a buscar
  /// [userId] - ID del usuario (opcional, para filtrar por usuario)
  ///
  /// Retorna:
  /// - Lista de rutas que coinciden con la búsqueda
  Future<List<RouteModel>> searchRoutes(String query, {String? userId}) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _apiService.searchRoutes(query, userId: userId);
    } catch (e) {
      throw Exception('Error al buscar rutas: ${e.toString()}');
    }
  }

  /// Calcula la distancia total de una ruta en kilómetros
  ///
  /// [puntos] - Lista de puntos GPS de la ruta
  ///
  /// Retorna:
  /// - Distancia total en kilómetros
  double calculateRouteDistance(List<LatLng> puntos) {
    if (puntos.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < puntos.length - 1; i++) {
      totalDistance += _calculateDistance(
        puntos[i].latitude,
        puntos[i].longitude,
        puntos[i + 1].latitude,
        puntos[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
