import 'package:dartz/dartz.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Use case para que un usuario se una a un evento
///
/// Maneja la lógica de negocio para la participación en eventos,
/// incluyendo validaciones de capacidad y permisos
class JoinEventUseCase {
  final EventRepository _eventRepository;
  final UserRepository _userRepository;

  JoinEventUseCase(this._eventRepository, this._userRepository);

  /// Ejecuta el use case para unirse a un evento
  ///
  /// [eventId] - ID del evento al que se desea unir
  /// [userId] - ID del usuario que se une (opcional, usa el usuario actual)
  ///
  /// Retorna [Right] con el evento actualizado si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, EventModel>> execute({
    required String eventId,
    String? userId,
  }) async {
    try {
      // Validar ID del evento
      if (eventId.isEmpty) {
        return const Left('ID de evento inválido');
      }

      // Obtener ID del usuario actual si no se proporciona
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Obtener información del evento
      final eventResult = await _eventRepository.getEventById(eventId);
      if (eventResult == null) {
        return const Left('Evento no encontrado');
      }

      // Validar si el usuario puede unirse
      final validationResult = _validateJoinEligibility(
        event: eventResult,
        userId: currentUserId,
      );
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Unir al usuario al evento
      await _eventRepository.joinEvent(eventId, currentUserId);

      // Obtener el evento actualizado
      final updatedEvent = await _eventRepository.getEventById(eventId);
      if (updatedEvent == null) {
        return const Left('Error al obtener el evento actualizado');
      }

      // Enviar notificación al organizador (opcional)
      await _notifyEventOrganizer(
        event: updatedEvent,
        newParticipantId: currentUserId,
      );

      return Right(updatedEvent);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Abandona un evento
  Future<Either<String, EventModel>> leaveEvent({
    required String eventId,
    String? userId,
  }) async {
    try {
      if (eventId.isEmpty) {
        return const Left('ID de evento inválido');
      }

      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Obtener información del evento
      final event = await _eventRepository.getEventById(eventId);
      if (event == null) {
        return const Left('Evento no encontrado');
      }

      // Validar que el usuario no sea el organizador
      if (event.organizerId == currentUserId) {
        return const Left('El organizador no puede abandonar su propio evento');
      }

      // Validar que falte tiempo para el evento
      final timeUntilEvent = event.date!.difference(DateTime.now());
      if (timeUntilEvent.inHours < 2) {
        return const Left(
          'No puedes abandonar el evento con menos de 2 horas de anticipación',
        );
      }

      // Abandonar el evento
      await _eventRepository.leaveEvent(eventId, currentUserId);

      // Obtener el evento actualizado
      final updatedEvent = await _eventRepository.getEventById(eventId);
      if (updatedEvent == null) {
        return const Left('Error al obtener el evento actualizado');
      }

      return Right(updatedEvent);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Valida si el usuario puede unirse al evento
  String? _validateJoinEligibility({
    required EventModel event,
    required String userId,
  }) {
    // Verificar si el evento ya pasó
    if (event.date != null && event.date!.isBefore(DateTime.now())) {
      return 'No puedes unirte a un evento que ya pasó';
    }

    // Verificar si el evento está cancelado
    if (event.status == 'cancelled') {
      return 'Este evento ha sido cancelado';
    }

    // Verificar si el usuario ya está inscrito
    if (event.participants?.contains(userId) ?? false) {
      return 'Ya estás inscrito en este evento';
    }

    // Verificar si el usuario es el organizador
    if (event.organizerId == userId) {
      return 'Eres el organizador de este evento';
    }

    // Verificar capacidad del evento
    final currentParticipants = event.participants?.length ?? 0;
    final maxParticipants = event.maxParticipants;

    if (maxParticipants != null && currentParticipants >= maxParticipants) {
      return 'El evento ha alcanzado el máximo de participantes';
    }

    // Verificar si el evento requiere aprobación
    if (event.requiresApproval ?? false) {
      // En este caso, se debería crear una solicitud pendiente
      return null; // Permitir, pero marcar como pendiente
    }

    // Verificar si el evento es privado
    if (event.isPublic == false) {
      // Aquí se podría verificar si el usuario tiene invitación
      return 'Este es un evento privado';
    }

    return null;
  }

  /// Obtiene el ID del usuario actual
  Future<String?> _getCurrentUserId() async {
    try {
      final user = await _userRepository.getCurrentUser();
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  /// Notifica al organizador sobre el nuevo participante
  Future<void> _notifyEventOrganizer({
    required EventModel event,
    required String newParticipantId,
  }) async {
    try {
      // Aquí se implementaría la lógica de notificaciones
      // Por ejemplo, enviar push notification o email

      // TODO: Implementar sistema de notificaciones
      // await _notificationService.sendNotification(
      //   userId: event.organizerId,
      //   title: 'Nuevo participante',
      //   body: 'Alguien se unió a tu evento: ${event.title}',
      // );
    } catch (e) {
      // No fallar si la notificación falla
      // Error al enviar notificación
    }
  }

  /// Verifica cuántos espacios quedan en el evento
  Future<Either<String, int>> getAvailableSpots({
    required String eventId,
  }) async {
    try {
      final event = await _eventRepository.getEventById(eventId);
      if (event == null) {
        return const Left('Evento no encontrado');
      }

      final currentParticipants = event.participants?.length ?? 0;
      final maxParticipants = event.maxParticipants ?? 0;
      final available = maxParticipants - currentParticipants;

      return Right(available > 0 ? available : 0);
    } catch (e) {
      return Left('Error al verificar espacios disponibles: ${e.toString()}');
    }
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para unirte a este evento.';
    } else if (error.toString().contains('not found')) {
      return 'El evento no existe o fue eliminado.';
    } else if (error.toString().contains('full')) {
      return 'El evento está lleno.';
    } else {
      return 'Error al unirse al evento: ${error.toString()}';
    }
  }
}
