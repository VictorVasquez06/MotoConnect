/// Servicio de API de Talleres
///
/// Capa más baja de abstracción - interactúa directamente con Supabase
///
/// Responsabilidades:
/// - Llamadas a Supabase para talleres
/// - Conversión de respuestas a modelos
/// - Manejo de errores de API
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/taller_model.dart';
import 'dart:math';

class TallerApiService {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ========================================
  // MÉTODOS PÚBLICOS - CRUD TALLERES
  // ========================================

  /// Obtiene todos los talleres
  Future<List<TallerModel>> getTalleres() async {
    try {
      final response = await _supabase
          .from(ApiConstants.talleresTable)
          .select('*, usuarios(nombre)')
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => TallerModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener talleres: ${e.toString()}');
    }
  }

  /// Obtiene un taller por ID
  Future<TallerModel?> getTallerById(String tallerId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.talleresTable)
              .select('*, usuarios(nombre)')
              .eq('id', tallerId)
              .maybeSingle();

      if (response == null) return null;
      return TallerModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener taller: ${e.toString()}');
    }
  }

  /// Crea un nuevo taller
  Future<TallerModel> createTaller({
    required String nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
    required String creadoPor,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.talleresTable)
              .insert({
                'nombre': nombre,
                'direccion': direccion,
                'telefono': telefono,
                'horario': horario,
                'latitud': latitud,
                'longitud': longitud,
                'creado_por': creadoPor,
              })
              .select('*, usuarios(nombre)')
              .single();

      return TallerModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear taller: ${e.toString()}');
    }
  }

  /// Actualiza un taller existente
  Future<void> updateTaller({
    required String tallerId,
    String? nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (nombre != null) updates['nombre'] = nombre;
      if (direccion != null) updates['direccion'] = direccion;
      if (telefono != null) updates['telefono'] = telefono;
      if (horario != null) updates['horario'] = horario;
      if (latitud != null) updates['latitud'] = latitud;
      if (longitud != null) updates['longitud'] = longitud;

      if (updates.isEmpty) return;

      await _supabase
          .from(ApiConstants.talleresTable)
          .update(updates)
          .eq('id', tallerId);
    } catch (e) {
      throw Exception('Error al actualizar taller: ${e.toString()}');
    }
  }

  /// Elimina un taller
  Future<void> deleteTaller(String tallerId) async {
    try {
      await _supabase
          .from(ApiConstants.talleresTable)
          .delete()
          .eq('id', tallerId);
    } catch (e) {
      throw Exception('Error al eliminar taller: ${e.toString()}');
    }
  }

  /// Obtiene talleres creados por un usuario
  Future<List<TallerModel>> getTalleresByUser(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.talleresTable)
          .select('*, usuarios(nombre)')
          .eq('creado_por', userId)
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => TallerModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener talleres del usuario: ${e.toString()}');
    }
  }

  /// Busca talleres por nombre o dirección
  Future<List<TallerModel>> searchTalleres(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from(ApiConstants.talleresTable)
          .select('*, usuarios(nombre)')
          .or('nombre.ilike.%$query%,direccion.ilike.%$query%')
          .order('nombre', ascending: true)
          .limit(20);

      return (response as List)
          .map((json) => TallerModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar talleres: ${e.toString()}');
    }
  }

  /// Obtiene talleres cercanos a una ubicación
  /// Nota: Esta es una implementación básica. Para búsquedas geoespaciales
  /// más eficientes, considera usar PostGIS en Supabase
  Future<List<TallerModel>> getTalleresNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      // Obtener todos los talleres con coordenadas
      final response = await _supabase
          .from(ApiConstants.talleresTable)
          .select('*, usuarios(nombre)')
          .not('latitud', 'is', null)
          .not('longitud', 'is', null);

      final List<TallerModel> allTalleres =
          (response as List).map((json) => TallerModel.fromJson(json)).toList();

      // Filtrar por distancia (cálculo simple)
      // Para producción, considera usar una función de Supabase con PostGIS
      return allTalleres.where((taller) {
        if (taller.latitud == null || taller.longitud == null) return false;

        final distance = _calculateDistance(
          latitude,
          longitude,
          taller.latitud!,
          taller.longitud!,
        );

        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener talleres cercanos: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  /// Retorna la distancia en kilómetros
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
