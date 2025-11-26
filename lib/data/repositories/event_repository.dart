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
import '../models/event_participant_model.dart';

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
  /// [puntoEncuentro] - Ubicación del punto de encuentro
  /// [createdBy] - ID del usuario creador
  /// [destino] - Ubicación del destino (opcional)
  /// [puntoEncuentroLat] - Latitud del punto de encuentro (opcional)
  /// [puntoEncuentroLng] - Longitud del punto de encuentro (opcional)
  /// [destinoLat] - Latitud del destino (opcional)
  /// [destinoLng] - Longitud del destino (opcional)
  /// [fotoUrl] - URL de la foto del evento (opcional)
  /// [grupoId] - ID del grupo asociado (opcional)
  /// [isPublic] - Si es público (true) o privado (false)
  ///
  /// Retorna:
  /// - Evento creado
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String puntoEncuentro,
    required String createdBy,
    String? destino,
    double? puntoEncuentroLat,
    double? puntoEncuentroLng,
    double? destinoLat,
    double? destinoLng,
    String? fotoUrl,
    String? grupoId,
    bool isPublic = true,
  }) async {
    try {
      return await _apiService.createEvent(
        title: title,
        description: description,
        date: date,
        puntoEncuentro: puntoEncuentro,
        createdBy: createdBy,
        destino: destino,
        puntoEncuentroLat: puntoEncuentroLat,
        puntoEncuentroLng: puntoEncuentroLng,
        destinoLat: destinoLat,
        destinoLng: destinoLng,
        fotoUrl: fotoUrl,
        grupoId: grupoId,
        isPublic: isPublic,
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
  /// [puntoEncuentro] - Nuevo punto de encuentro (opcional)
  /// [destino] - Nuevo destino (opcional)
  /// [puntoEncuentroLat] - Nueva latitud del punto de encuentro (opcional)
  /// [puntoEncuentroLng] - Nueva longitud del punto de encuentro (opcional)
  /// [destinoLat] - Nueva latitud del destino (opcional)
  /// [destinoLng] - Nueva longitud del destino (opcional)
  /// [fotoUrl] - Nueva URL de foto (opcional)
  /// [grupoId] - Nuevo ID de grupo (opcional)
  /// [isPublic] - Nueva configuración de privacidad (opcional)
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    String? puntoEncuentro,
    String? destino,
    double? puntoEncuentroLat,
    double? puntoEncuentroLng,
    double? destinoLat,
    double? destinoLng,
    String? fotoUrl,
    String? grupoId,
    bool? isPublic,
  }) async {
    try {
      await _apiService.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        date: date,
        puntoEncuentro: puntoEncuentro,
        destino: destino,
        puntoEncuentroLat: puntoEncuentroLat,
        puntoEncuentroLng: puntoEncuentroLng,
        destinoLat: destinoLat,
        destinoLng: destinoLng,
        fotoUrl: fotoUrl,
        grupoId: grupoId,
        isPublic: isPublic,
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

  /// Registra un usuario a un evento con estado de asistencia
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  /// [estado] - Estado de asistencia (por defecto: confirmado)
  Future<void> joinEvent(
    String eventId,
    String userId, {
    EstadoAsistencia estado = EstadoAsistencia.confirmado,
  }) async {
    try {
      await _apiService.joinEvent(eventId, userId, estado: estado);
    } catch (e) {
      throw Exception('Error al unirse al evento: ${e.toString()}');
    }
  }

  /// Actualiza el estado de asistencia de un usuario
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  /// [estado] - Nuevo estado de asistencia
  Future<void> updateAttendanceStatus(
    String eventId,
    String userId,
    EstadoAsistencia estado,
  ) async {
    try {
      await _apiService.updateAttendanceStatus(eventId, userId, estado);
    } catch (e) {
      throw Exception('Error al actualizar estado de asistencia: ${e.toString()}');
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

  /// Busca eventos por título o ubicación
  ///
  /// [query] - Texto a buscar
  ///
  /// Retorna:
  /// - Lista de eventos que coinciden con la búsqueda
  Future<List<Event>> searchEvents(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _apiService.searchEvents(query);
    } catch (e) {
      throw Exception('Error al buscar eventos: ${e.toString()}');
    }
  }

  /// Obtiene eventos pasados
  ///
  /// Retorna:
  /// - Lista de eventos cuya fecha ya pasó
  Future<List<Event>> getPastEvents() async {
    try {
      return await _apiService.getPastEvents();
    } catch (e) {
      throw Exception('Error al obtener eventos pasados: ${e.toString()}');
    }
  }

  /// Obtiene eventos creados por un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de eventos creados por el usuario
  Future<List<Event>> getEventsByUser(String userId) async {
    try {
      return await _apiService.getEventsByUser(userId);
    } catch (e) {
      throw Exception('Error al obtener eventos del usuario: ${e.toString()}');
    }
  }

  /// Obtiene eventos en los que participa un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de eventos donde el usuario es participante
  Future<List<Event>> getEventsUserJoined(String userId) async {
    try {
      return await _apiService.getEventsUserJoined(userId);
    } catch (e) {
      throw Exception(
          'Error al obtener eventos donde participa el usuario: ${e.toString()}');
    }
  }

  /// Obtiene el conteo de participantes de un evento
  ///
  /// [eventId] - ID del evento
  ///
  /// Retorna:
  /// - Cantidad de participantes confirmados
  Future<int> getEventParticipantsCount(String eventId) async {
    try {
      return await _apiService.getEventParticipantsCount(eventId);
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene participantes detallados de un evento
  ///
  /// [eventId] - ID del evento
  ///
  /// Retorna:
  /// - Lista de participantes con información completa y estado
  Future<List<EventParticipantModel>> getEventParticipantsDetailed(
    String eventId,
  ) async {
    try {
      return await _apiService.getEventParticipantsDetailed(eventId);
    } catch (e) {
      throw Exception('Error al obtener participantes detallados: ${e.toString()}');
    }
  }

  /// Verifica si un usuario es el creador de un evento
  ///
  /// [eventId] - ID del evento
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario es el creador
  Future<bool> isUserCreator(String eventId, String userId) async {
    try {
      return await _apiService.isUserCreator(eventId, userId);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene eventos por ubicación
  ///
  /// [location] - Texto de ubicación a buscar
  ///
  /// Retorna:
  /// - Lista de eventos en la ubicación especificada
  Future<List<Event>> getEventsByLocation({required String location}) async {
    try {
      return await _apiService.getEventsByLocation(location: location);
    } catch (e) {
      throw Exception('Error al obtener eventos por ubicación: ${e.toString()}');
    }
  }

  /// Obtiene eventos en un rango de fechas
  ///
  /// [startDate] - Fecha de inicio
  /// [endDate] - Fecha de fin
  ///
  /// Retorna:
  /// - Lista de eventos en el rango de fechas
  Future<List<Event>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _apiService.getEventsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception(
          'Error al obtener eventos por rango de fechas: ${e.toString()}');
    }
  }

  /// Obtiene todos los eventos (alias para mantener compatibilidad)
  ///
  /// Retorna:
  /// - Lista de todos los eventos
  Future<List<Event>> getAllEvents() async {
    try {
      return await getEvents();
    } catch (e) {
      throw Exception('Error al obtener todos los eventos: ${e.toString()}');
    }
  }
}
