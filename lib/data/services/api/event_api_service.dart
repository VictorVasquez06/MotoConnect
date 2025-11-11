/// Servicio de API de Eventos
///
/// Capa más baja de abstracción - interactúa directamente con Supabase
///
/// Responsabilidades:
/// - Llamadas a Supabase para eventos
/// - Conversión de respuestas a modelos
/// - Manejo de errores de API
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/event_model.dart';

class EventApiService {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ========================================
  // MÉTODOS PÚBLICOS - CRUD EVENTOS
  // ========================================

  /// Obtiene todos los eventos
  Future<List<Event>> getEvents() async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos: ${e.toString()}');
    }
  }

  /// Obtiene un evento por ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.eventsTable)
              .select()
              .eq('id', eventId)
              .maybeSingle();

      if (response == null) return null;
      return Event.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener evento: ${e.toString()}');
    }
  }

  /// Crea un nuevo evento
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String createdBy,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.eventsTable)
              .insert({
                'titulo': title,
                'descripcion': description,
                'fecha_hora': date.toIso8601String(),
                'ubicacion': location,
                'creado_por': createdBy,
              })
              .select()
              .single();

      return Event.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear evento: ${e.toString()}');
    }
  }

  /// Actualiza un evento
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    String? location,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (title != null) updates['titulo'] = title;
      if (description != null) updates['descripcion'] = description;
      if (date != null) updates['fecha_hora'] = date.toIso8601String();
      if (location != null) updates['ubicacion'] = location;

      await _supabase
          .from(ApiConstants.eventsTable)
          .update(updates)
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Error al actualizar evento: ${e.toString()}');
    }
  }

  /// Elimina un evento
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from(ApiConstants.eventsTable).delete().eq('id', eventId);
    } catch (e) {
      throw Exception('Error al eliminar evento: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - PARTICIPANTES
  // ========================================

  /// Registra un usuario a un evento
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _supabase.from(ApiConstants.eventParticipantsTable).insert({
        'evento_id': eventId,
        'usuario_id': userId,
        'estado': 'confirmado',
      });
    } catch (e) {
      throw Exception('Error al unirse al evento: ${e.toString()}');
    }
  }

  /// Cancela participación
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _supabase
          .from(ApiConstants.eventParticipantsTable)
          .delete()
          .eq('evento_id', eventId)
          .eq('usuario_id', userId);
    } catch (e) {
      throw Exception('Error al cancelar participación: ${e.toString()}');
    }
  }

  /// Obtiene participantes de un evento
  Future<List<String>> getEventParticipants(String eventId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventParticipantsTable)
          .select('usuario_id')
          .eq('evento_id', eventId)
          .eq('estado', 'confirmado');

      return (response as List)
          .map((item) => item['usuario_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener participantes: ${e.toString()}');
    }
  }

  /// Verifica si un usuario está registrado
  Future<bool> isUserJoined(String eventId, String userId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.eventParticipantsTable)
              .select()
              .eq('evento_id', eventId)
              .eq('usuario_id', userId)
              .eq('estado', 'confirmado')
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Busca eventos por título o ubicación
  Future<List<Event>> searchEvents(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .or('titulo.ilike.%$query%,ubicacion.ilike.%$query%')
          .order('fecha_hora', ascending: true)
          .limit(20);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar eventos: ${e.toString()}');
    }
  }

  /// Obtiene eventos próximos (futuro)
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .gte('fecha_hora', now)
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos próximos: ${e.toString()}');
    }
  }

  /// Obtiene eventos pasados
  Future<List<Event>> getPastEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .lt('fecha_hora', now)
          .order('fecha_hora', ascending: false);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos pasados: ${e.toString()}');
    }
  }

  /// Obtiene eventos creados por un usuario
  Future<List<Event>> getEventsByUser(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .eq('creado_por', userId)
          .order('fecha_hora', ascending: false);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos del usuario: ${e.toString()}');
    }
  }

  /// Obtiene eventos en los que participa un usuario
  Future<List<Event>> getEventsUserJoined(String userId) async {
    try {
      // Obtener IDs de eventos donde el usuario es participante
      final participations = await _supabase
          .from(ApiConstants.eventParticipantsTable)
          .select('evento_id')
          .eq('usuario_id', userId)
          .eq('estado', 'confirmado');

      if ((participations as List).isEmpty) return [];

      final eventIds = participations.map((p) => p['evento_id']).toList();

      // Obtener los eventos correspondientes
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .inFilter('id', eventIds)
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Error al obtener eventos donde participa el usuario: ${e.toString()}');
    }
  }

  /// Obtiene el conteo de participantes de un evento
  Future<int> getEventParticipantsCount(String eventId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventParticipantsTable)
          .select('usuario_id')
          .eq('evento_id', eventId)
          .eq('estado', 'confirmado');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Verifica si un usuario es el creador de un evento
  Future<bool> isUserCreator(String eventId, String userId) async {
    try {
      final event = await getEventById(eventId);
      return event?.createdBy == userId;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene eventos por ubicación cercana
  Future<List<Event>> getEventsByLocation({
    required String location,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .ilike('ubicacion', '%$location%')
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos por ubicación: ${e.toString()}');
    }
  }

  /// Obtiene eventos en un rango de fechas
  Future<List<Event>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.eventsTable)
          .select()
          .gte('fecha_hora', startDate.toIso8601String())
          .lte('fecha_hora', endDate.toIso8601String())
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Error al obtener eventos por rango de fechas: ${e.toString()}');
    }
  }
}
