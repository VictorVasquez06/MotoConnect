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
import '../../domain/repositories/i_route_repository.dart';
import '../services/api/route_api_service.dart';
import '../models/route_model.dart';
import 'dart:math';

class RouteRepository implements IRouteRepository {
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

  /// Obtiene todas las rutas
  ///
  /// [filters] - Filtros opcionales para aplicar a la consulta
  /// [limit] - Número máximo de rutas a obtener
  /// [offset] - Número de rutas a omitir
  ///
  /// Retorna:
  /// - Lista de todas las rutas en el sistema
  Future<List<RouteModel>> getRoutes({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      // Por ahora, usar getRoutes básico y aplicar filtros manualmente
      var routes = await _apiService.getRoutes();

      // Aplicar límite y offset
      if (offset != null && offset > 0) {
        routes = routes.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        routes = routes.take(limit).toList();
      }

      return routes;
    } catch (e) {
      throw Exception('Error al obtener rutas: ${e.toString()}');
    }
  }

  /// Obtiene rutas guardadas/favoritas de un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de rutas guardadas por el usuario
  Future<List<RouteModel>> getSavedRoutesForUser(String userId) async {
    try {
      return await _apiService.getSavedRoutesForUser(userId);
    } catch (e) {
      throw Exception('Error al obtener rutas guardadas: ${e.toString()}');
    }
  }

  /// Obtiene rutas creadas por un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de rutas creadas por el usuario
  Future<List<RouteModel>> getRoutesCreatedByUser(String userId) async {
    try {
      return await _apiService.getRoutesCreatedByUser(userId);
    } catch (e) {
      throw Exception('Error al obtener rutas creadas: ${e.toString()}');
    }
  }

  /// Verifica si una ruta está guardada por el usuario
  ///
  /// [routeId] - ID de la ruta
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si la ruta está guardada por el usuario
  Future<bool> isRouteSavedByUser(String routeId, String userId) async {
    try {
      return await _apiService.isRouteSavedByUser(routeId, userId);
    } catch (e) {
      return false;
    }
  }

  /// Guarda una ruta en los favoritos del usuario
  ///
  /// [routeId] - ID de la ruta
  /// [userId] - ID del usuario
  Future<void> saveRouteForUser(String routeId, String userId) async {
    try {
      await _apiService.saveRouteForUser(routeId, userId);
    } catch (e) {
      throw Exception('Error al guardar ruta: ${e.toString()}');
    }
  }

  /// Elimina una ruta de los favoritos del usuario
  ///
  /// [routeId] - ID de la ruta
  /// [userId] - ID del usuario
  Future<void> removeRouteFromUserFavorites(
    String routeId,
    String userId,
  ) async {
    try {
      await _apiService.removeRouteFromUserFavorites(routeId, userId);
    } catch (e) {
      throw Exception('Error al remover ruta de favoritos: ${e.toString()}');
    }
  }

  /// Actualiza el estado de una ruta
  ///
  /// [routeId] - ID de la ruta
  /// [status] - Nuevo estado de la ruta
  Future<void> updateRouteStatus(String routeId, String status) async {
    try {
      await _apiService.updateRouteStatus(routeId, status);
    } catch (e) {
      throw Exception('Error al actualizar estado de ruta: ${e.toString()}');
    }
  }

  /// Verifica si una ruta está siendo usada en eventos activos
  ///
  /// [routeId] - ID de la ruta
  ///
  /// Retorna:
  /// - true si la ruta está siendo usada en eventos activos
  Future<bool> isRouteUsedInActiveEvents(String routeId) async {
    try {
      return await _apiService.isRouteUsedInActiveEvents(routeId);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene rutas por ubicación
  ///
  /// [latitude] - Latitud de la ubicación
  /// [longitude] - Longitud de la ubicación
  /// [radiusKm] - Radio de búsqueda en kilómetros (default: 10km)
  ///
  /// Retorna:
  /// - Lista de rutas cercanas a la ubicación
  Future<List<RouteModel>> getRoutesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      return await _apiService.getRoutesByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw Exception('Error al obtener rutas por ubicación: ${e.toString()}');
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
