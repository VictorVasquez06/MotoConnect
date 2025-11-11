/// Servicio de API de Rutas
///
/// Capa más baja de abstracción - interactúa directamente con Supabase
///
/// Responsabilidades:
/// - Llamadas a Supabase para rutas
/// - Conversión de respuestas a modelos
/// - Manejo de errores de API
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/route_model.dart';
import 'dart:math';

class RouteApiService {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ========================================
  // MÉTODOS PÚBLICOS - CRUD RUTAS
  // ========================================

  /// Obtiene todas las rutas de un usuario
  Future<List<RouteModel>> getUserRoutes(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.routesTable)
          .select()
          .eq('usuario_id', userId)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rutas: ${e.toString()}');
    }
  }

  /// Obtiene una ruta por ID
  Future<RouteModel?> getRouteById(String routeId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.routesTable)
              .select()
              .eq('id', routeId)
              .maybeSingle();

      if (response == null) return null;
      return RouteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener ruta: ${e.toString()}');
    }
  }

  /// Crea una nueva ruta
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
      final puntosJson =
          puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

      final response =
          await _supabase
              .from(ApiConstants.routesTable)
              .insert({
                'usuario_id': userId,
                'nombre_ruta': nombreRuta,
                'descripcion_ruta': descripcionRuta,
                'fecha': DateTime.now().toIso8601String(),
                'puntos': puntosJson,
                'distancia_km': distanciaKm ?? 0.0,
                'duracion_minutos': duracionMinutos ?? 0,
                'imagen_url': imagenUrl,
              })
              .select()
              .single();

      return RouteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear ruta: ${e.toString()}');
    }
  }

  /// Actualiza una ruta existente
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
      final Map<String, dynamic> updates = {};
      if (nombreRuta != null) updates['nombre_ruta'] = nombreRuta;
      if (descripcionRuta != null) {
        updates['descripcion_ruta'] = descripcionRuta;
      }
      if (puntos != null) {
        updates['puntos'] =
            puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
      }
      if (distanciaKm != null) updates['distancia_km'] = distanciaKm;
      if (duracionMinutos != null) {
        updates['duracion_minutos'] = duracionMinutos;
      }
      if (imagenUrl != null) updates['imagen_url'] = imagenUrl;

      if (updates.isEmpty) return;

      await _supabase
          .from(ApiConstants.routesTable)
          .update(updates)
          .eq('id', routeId);
    } catch (e) {
      throw Exception('Error al actualizar ruta: ${e.toString()}');
    }
  }

  /// Elimina una ruta
  Future<void> deleteRoute(String routeId) async {
    try {
      await _supabase.from(ApiConstants.routesTable).delete().eq('id', routeId);
    } catch (e) {
      throw Exception('Error al eliminar ruta: ${e.toString()}');
    }
  }

  /// Obtiene rutas recientes de todos los usuarios (feed público)
  Future<List<RouteModel>> getRecentRoutes({int limit = 20}) async {
    try {
      final response = await _supabase
          .from(ApiConstants.routesTable)
          .select()
          .order('fecha', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rutas recientes: ${e.toString()}');
    }
  }

  /// Busca rutas por nombre
  Future<List<RouteModel>> searchRoutes(String query, {String? userId}) async {
    try {
      if (query.isEmpty) return [];

      var queryBuilder = _supabase
          .from(ApiConstants.routesTable)
          .select()
          .ilike('nombre_ruta', '%$query%');

      if (userId != null) {
        queryBuilder = queryBuilder.eq('usuario_id', userId);
      }

      final response = await queryBuilder
          .order('fecha', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar rutas: ${e.toString()}');
    }
  }

  /// Obtiene todas las rutas
  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await _supabase
          .from(ApiConstants.routesTable)
          .select()
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rutas: ${e.toString()}');
    }
  }

  /// Obtiene rutas guardadas por un usuario
  Future<List<RouteModel>> getSavedRoutesForUser(String userId) async {
    try {
      // Asumiendo que existe una tabla de rutas guardadas/favoritas
      // Si no existe, este método devuelve las rutas del usuario
      final response = await _supabase
          .from(ApiConstants.routesTable)
          .select()
          .eq('usuario_id', userId)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener rutas guardadas: ${e.toString()}');
    }
  }

  /// Obtiene rutas creadas por un usuario
  Future<List<RouteModel>> getRoutesCreatedByUser(String userId) async {
    try {
      return await getUserRoutes(userId);
    } catch (e) {
      throw Exception('Error al obtener rutas creadas: ${e.toString()}');
    }
  }

  /// Verifica si una ruta está guardada por el usuario
  Future<bool> isRouteSavedByUser(String routeId, String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.routesTable)
          .select()
          .eq('id', routeId)
          .eq('usuario_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Guarda una ruta para el usuario (agregar a favoritos)
  Future<void> saveRouteForUser(String routeId, String userId) async {
    try {
      // Esta funcionalidad requeriría una tabla de favoritos
      // Por ahora, simplemente verificamos que la ruta existe
      final route = await getRouteById(routeId);
      if (route == null) {
        throw Exception('Ruta no encontrada');
      }
      // Implementar lógica de favoritos cuando se cree la tabla
    } catch (e) {
      throw Exception('Error al guardar ruta: ${e.toString()}');
    }
  }

  /// Elimina una ruta de los favoritos del usuario
  Future<void> removeRouteFromUserFavorites(String routeId, String userId) async {
    try {
      // Esta funcionalidad requeriría una tabla de favoritos
      // Implementar lógica cuando se cree la tabla
    } catch (e) {
      throw Exception('Error al remover ruta de favoritos: ${e.toString()}');
    }
  }

  /// Actualiza el estado de una ruta
  Future<void> updateRouteStatus(String routeId, String status) async {
    try {
      await _supabase
          .from(ApiConstants.routesTable)
          .update({'estado': status})
          .eq('id', routeId);
    } catch (e) {
      throw Exception('Error al actualizar estado de ruta: ${e.toString()}');
    }
  }

  /// Verifica si una ruta está siendo usada en eventos activos
  Future<bool> isRouteUsedInActiveEvents(String routeId) async {
    try {
      // Verificar en la tabla de eventos si hay eventos activos que usen esta ruta
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .eq('ruta_id', routeId)
          .gte('fecha_hora', DateTime.now().toIso8601String())
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene rutas por ubicación (cercanas a un punto)
  Future<List<RouteModel>> getRoutesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      // Obtener todas las rutas y filtrar por distancia
      final allRoutes = await getRoutes();

      // Filtrar rutas que tengan puntos cerca de la ubicación especificada
      return allRoutes.where((route) {
        if (route.puntos.isEmpty) return false;

        // Verificar si algún punto de la ruta está dentro del radio
        return route.puntos.any((punto) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            punto.latitude,
            punto.longitude,
          );
          return distance <= radiusKm;
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener rutas por ubicación: ${e.toString()}');
    }
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

    final a = sin(dLat / 2) * sin(dLat / 2) +
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
