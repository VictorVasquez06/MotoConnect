/// Interface de Repositorio de Rutas
///
/// Define el contrato para las operaciones de rutas.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_model.dart';

abstract class IRouteRepository {
  /// Obtiene todas las rutas de un usuario
  Future<List<RouteModel>> getUserRoutes(String userId);

  /// Obtiene una ruta por ID
  Future<RouteModel?> getRouteById(String routeId);

  /// Crea una nueva ruta
  Future<RouteModel> createRoute({
    required String userId,
    required String nombreRuta,
    String? descripcionRuta,
    required List<LatLng> puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  });

  /// Actualiza una ruta existente
  Future<void> updateRoute({
    required String routeId,
    String? nombreRuta,
    String? descripcionRuta,
    List<LatLng>? puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
  });

  /// Elimina una ruta
  Future<void> deleteRoute(String routeId);

  /// Obtiene rutas recientes de todos los usuarios
  Future<List<RouteModel>> getRecentRoutes({int limit = 20});

  /// Busca rutas por nombre
  Future<List<RouteModel>> searchRoutes(String query, {String? userId});

  /// Obtiene todas las rutas
  Future<List<RouteModel>> getRoutes({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  });

  /// Obtiene rutas guardadas/favoritas de un usuario
  Future<List<RouteModel>> getSavedRoutesForUser(String userId);

  /// Obtiene rutas creadas por un usuario
  Future<List<RouteModel>> getRoutesCreatedByUser(String userId);

  /// Verifica si una ruta está guardada por el usuario
  Future<bool> isRouteSavedByUser(String routeId, String userId);

  /// Guarda una ruta en los favoritos del usuario
  Future<void> saveRouteForUser(String routeId, String userId);

  /// Elimina una ruta de los favoritos del usuario
  Future<void> removeRouteFromUserFavorites(String routeId, String userId);

  /// Actualiza el estado de una ruta
  Future<void> updateRouteStatus(String routeId, String status);

  /// Verifica si una ruta está siendo usada en eventos activos
  Future<bool> isRouteUsedInActiveEvents(String routeId);

  /// Obtiene rutas por ubicación
  Future<List<RouteModel>> getRoutesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Calcula la distancia total de una ruta en kilómetros
  double calculateRouteDistance(List<LatLng> puntos);
}
