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
}
