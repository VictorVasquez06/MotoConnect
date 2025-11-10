/// Repository de Eventos
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de eventos
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de eventos
/// - Gestión de participantes
/// - Comunicación con EventApiService
library;

import '../services/api/event_api_service.dart';
import '../models/event_model.dart';

class EventRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de eventos
  final EventApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de eventos
  EventRepository({EventApiService? apiService})
    : _apiService = apiService ?? EventApiService();

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Obtiene todos los eventos
  ///
  /// Retorna:
  /// - Lista de eventos desde Supabase
  ///
  /// Lanza:
  /// - Exception si falla la obtención
  Future<List<Event>> getEvents() async {
    try {
      return await _apiService.getEvents();
    } catch (e) {
      throw Exception('Error al obtener eventos: ${e.toString()}');
    }
  }

  /// Obtiene eventos próximos (futuro)
  ///
  /// Retorna:
  /// - Lista de eventos cuya fecha es posterior a hoy
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final allEvents = await _apiService.getEvents();
      final now = DateTime.now();
      return allEvents.where((event) => event.date.isAfter(now)).toList();
    } catch (e) {
      throw Exception('Error al obtener eventos próximos: ${e.toString()}');
    }
  }

  /// Obtiene un evento por ID
  ///
  /// [eventId] - ID del evento
  ///
  /// Retorna:
  /// - Evento encontrado o null
  Future<Event?> getEventById(String eventId) async {
    try {
      return await _apiService.getEventById(eventId);
    } catch (e) {
      throw Exception('Error al obtener evento: ${e.toString()}');
    }
  }

  /// Crea un nuevo evento
  ///
  /// [title] - Título del evento
  /// [description] - Descripción
  /// [date] - Fecha y hora
  /// [location] - Ubicación
  /// [createdBy] - ID del usuario creador
  ///
  /// Retorna:
  /// - Evento creado
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String createdBy,
  }) async {
    try {
      return await _apiService.createEvent(
        title: title,
        description: description,
        date: date,
        location: location,
        createdBy: createdBy,
      );
    } catch (e) {
      throw Exception('Error al crear evento: ${e.toString()}');
    }
  }

  /// Actualiza un evento existente
  ///
  /// [eventId] - ID del evento a actualizar
  /// [title] - Nuevo título (opcional)
  /// [description] - Nueva descripción (opcional)
  /// [date] - Nueva fecha (opcional)
  /// [location] - Nueva ubicación (opcional)
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    String? location,
  }) async {
    try {
      await _apiService.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        date: date,
        location: location,
      );
    } catch (e) {
      throw Exception('Error al actualizar evento: ${e.toString()}');
    }
  }

  /// Elimina un evento
  ///
  /// [eventId] - ID del evento a eliminar
  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiService.deleteEvent(eventId);
    } catch (e) {
      throw Exception('Error al eliminar evento: ${e.toString()}');
    }
  }

  /// Registra un usuario a un evento
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _apiService.joinEvent(eventId, userId);
    } catch (e) {
      throw Exception('Error al unirse al evento: ${e.toString()}');
    }
  }

  /// Cancela la participación de un usuario en un evento
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _apiService.leaveEvent(eventId, userId);
    } catch (e) {
      throw Exception('Error al cancelar participación: ${e.toString()}');
    }
  }

  /// Obtiene los participantes de un evento
  ///
  /// [eventId] - ID del evento
  ///
  /// Retorna:
  /// - Lista de IDs de usuarios participantes
  Future<List<String>> getEventParticipants(String eventId) async {
    try {
      return await _apiService.getEventParticipants(eventId);
    } catch (e) {
      throw Exception('Error al obtener participantes: ${e.toString()}');
    }
  }

  /// Verifica si un usuario está registrado en un evento
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario está registrado
  Future<bool> isUserJoined(String eventId, String userId) async {
    try {
      return await _apiService.isUserJoined(eventId, userId);
    } catch (e) {
      throw Exception('Error al verificar participación: ${e.toString()}');
    }
  }
}
