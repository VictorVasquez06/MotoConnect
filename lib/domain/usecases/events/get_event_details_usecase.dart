import 'package:dartz/dartz.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Use case para obtener los detalles completos de un evento
/// 
/// Maneja la lógica de negocio para recuperar información detallada
/// de un evento, incluyendo participantes y organizador
class GetEventDetailsUseCase {
  final EventRepository _eventRepository;
  final UserRepository _userRepository;

  GetEventDetailsUseCase(
    this._eventRepository,
    this._userRepository,
  );

  /// Ejecuta el use case para obtener detalles del evento
  /// 
  /// [eventId] - ID del evento a consultar
  /// [includeParticipants] - Si debe incluir información de los participantes
  /// [includeOrganizer] - Si debe incluir información del organizador
  /// 
  /// Retorna [Right] con EventDetails si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, EventDetails>> execute({
    required String eventId,
    bool includeParticipants = true,
    bool includeOrganizer = true,
  }) async {
    try {
      // Validar ID del evento
      if (eventId.isEmpty) {
        return const Left('ID de evento inválido');
      }

      // Obtener información básica del evento
      final event = await _eventRepository.getEventById(eventId);
      if (event == null) {
        return const Left('Evento no encontrado');
      }

      // Obtener información del organizador si se solicita
      UserModel? organizer;
      if (includeOrganizer && event.organizerId != null) {
        organizer = await _getUserInfo(event.organizerId!);
      }

      // Obtener información de los participantes si se solicita
      List<UserModel>? participants;
      if (includeParticipants && event.participants != null) {
        participants = await _getParticipantsInfo(event.participants!);
      }

      // Calcular estadísticas adicionales
      final stats = _calculateEventStats(event);

      // Verificar si el usuario actual está inscrito
      final isUserJoined = await _isCurrentUserJoined(eventId);

      // Construir objeto de detalles
      final details = EventDetails(
        event: event,
        organizer: organizer,
        participants: participants,
        stats: stats,
        isUserJoined: isUserJoined,
      );

      return Right(details);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene un resumen rápido del evento (sin información completa de usuarios)
  Future<Either<String, EventModel>> getQuickSummary({
    required String eventId,
  }) async {
    try {
      if (eventId.isEmpty) {
        return const Left('ID de evento inválido');
      }

      final event = await _eventRepository.getEventById(eventId);
      if (event == null) {
        return const Left('Evento no encontrado');
      }

      return Right(event);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene información de un usuario
  Future<UserModel?> _getUserInfo(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      print('Error al obtener información del usuario $userId: $e');
      return null;
    }
  }

  /// Obtiene información de múltiples usuarios (participantes)
  Future<List<UserModel>> _getParticipantsInfo(List<String> participantIds) async {
    final participants = <UserModel>[];
    
    for (final userId in participantIds) {
      final user = await _getUserInfo(userId);
      if (user != null) {
        participants.add(user);
      }
    }
    
    return participants;
  }

  /// Verifica si el usuario actual está inscrito en el evento
  Future<bool> _isCurrentUserJoined(String eventId) async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser == null) return false;

      final event = await _eventRepository.getEventById(eventId);
      if (event == null) return false;

      return event.participants?.contains(currentUser.id) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Calcula estadísticas del evento
  EventStats _calculateEventStats(EventModel event) {
    final currentParticipants = event.participants?.length ?? 0;
    final maxParticipants = event.maxParticipants ?? 0;
    
    final availableSpots = maxParticipants > 0 
        ? maxParticipants - currentParticipants 
        : -1; // -1 significa ilimitado

    final occupancyRate = maxParticipants > 0 
        ? (currentParticipants / maxParticipants * 100).roundToDouble() 
        : 0.0;

    final isFull = maxParticipants > 0 && currentParticipants >= maxParticipants;

    // Calcular tiempo hasta el evento
    String timeUntilEvent = 'N/A';
    bool isUpcoming = true;
    bool isPast = false;

    if (event.date != null) {
      final now = DateTime.now();
      final eventDate = event.date!;
      
      isPast = eventDate.isBefore(now);
      isUpcoming = eventDate.isAfter(now);

      if (isUpcoming) {
        final difference = eventDate.difference(now);
        if (difference.inDays > 0) {
          timeUntilEvent = '${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
        } else if (difference.inHours > 0) {
          timeUntilEvent = '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
        } else {
          timeUntilEvent = '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
        }
      } else if (isPast) {
        timeUntilEvent = 'Evento finalizado';
      }
    }

    return EventStats(
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
      availableSpots: availableSpots,
      occupancyRate: occupancyRate,
      isFull: isFull,
      timeUntilEvent: timeUntilEvent,
      isUpcoming: isUpcoming,
      isPast: isPast,
    );
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('not found')) {
      return 'El evento no existe o fue eliminado.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para ver este evento.';
    } else {
      return 'Error al cargar detalles del evento: ${error.toString()}';
    }
  }
}

/// Clase que encapsula todos los detalles de un evento
class EventDetails {
  final EventModel event;
  final UserModel? organizer;
  final List<UserModel>? participants;
  final EventStats stats;
  final bool isUserJoined;

  EventDetails({
    required this.event,
    this.organizer,
    this.participants,
    required this.stats,
    required this.isUserJoined,
  });

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'organizer': organizer?.toJson(),
      'participants': participants?.map((p) => p.toJson()).toList(),
      'stats': stats.toJson(),
      'isUserJoined': isUserJoined,
    };
  }
}

/// Clase para estadísticas del evento
class EventStats {
  final int currentParticipants;
  final int maxParticipants;
  final int availableSpots; // -1 significa ilimitado
  final double occupancyRate; // Porcentaje de ocupación
  final bool isFull;
  final String timeUntilEvent;
  final bool isUpcoming;
  final bool isPast;

  EventStats({
    required this.currentParticipants,
    required this.maxParticipants,
    required this.availableSpots,
    required this.occupancyRate,
    required this.isFull,
    required this.timeUntilEvent,
    required this.isUpcoming,
    required this.isPast,
  });

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'availableSpots': availableSpots,
      'occupancyRate': occupancyRate,
      'isFull': isFull,
      'timeUntilEvent': timeUntilEvent,
      'isUpcoming': isUpcoming,
      'isPast': isPast,
    };
  }

  /// Obtiene un mensaje descriptivo del estado
  String getStatusMessage() {
    if (isPast) {
      return 'Evento finalizado';
    } else if (isFull) {
      return 'Evento lleno';
    } else if (availableSpots > 0 && availableSpots <= 5) {
      return '¡Solo quedan $availableSpots lugares!';
    } else if (isUpcoming) {
      return 'Evento próximo - $timeUntilEvent';
    } else {
      return 'Evento disponible';
    }
  }
}
