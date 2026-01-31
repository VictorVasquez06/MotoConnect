/// Interface de Repositorio de Eventos
///
/// Define el contrato para las operaciones de eventos.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/event_model.dart';
import '../../data/models/event_participant_model.dart';

abstract class IEventRepository {
  /// Obtiene todos los eventos
  Future<List<Event>> getEvents();

  /// Obtiene eventos próximos (futuro)
  Future<List<Event>> getUpcomingEvents();

  /// Obtiene un evento por ID
  Future<Event?> getEventById(String eventId);

  /// Crea un nuevo evento
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
  });

  /// Actualiza un evento existente
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
  });

  /// Elimina un evento
  Future<void> deleteEvent(String eventId);

  /// Registra un usuario a un evento
  Future<void> joinEvent(
    String eventId,
    String userId, {
    EstadoAsistencia estado = EstadoAsistencia.confirmado,
  });

  /// Actualiza el estado de asistencia de un usuario
  Future<void> updateAttendanceStatus(
    String eventId,
    String userId,
    EstadoAsistencia estado,
  );

  /// Cancela la participación de un usuario en un evento
  Future<void> leaveEvent(String eventId, String userId);

  /// Obtiene los participantes de un evento
  Future<List<String>> getEventParticipants(String eventId);

  /// Verifica si un usuario está registrado en un evento
  Future<bool> isUserJoined(String eventId, String userId);

  /// Busca eventos por título o ubicación
  Future<List<Event>> searchEvents(String query);

  /// Obtiene eventos pasados
  Future<List<Event>> getPastEvents();

  /// Obtiene eventos creados por un usuario
  Future<List<Event>> getEventsByUser(String userId);

  /// Obtiene eventos en los que participa un usuario
  Future<List<Event>> getEventsUserJoined(String userId);

  /// Obtiene el conteo de participantes de un evento
  Future<int> getEventParticipantsCount(String eventId);

  /// Obtiene participantes detallados de un evento
  Future<List<EventParticipantModel>> getEventParticipantsDetailed(
    String eventId,
  );

  /// Verifica si un usuario es el creador de un evento
  Future<bool> isUserCreator(String eventId, String userId);

  /// Obtiene eventos por ubicación
  Future<List<Event>> getEventsByLocation({required String location});

  /// Obtiene eventos en un rango de fechas
  Future<List<Event>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtiene todos los eventos (alias)
  Future<List<Event>> getAllEvents();
}
