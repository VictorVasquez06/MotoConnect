/// EventsBloc - Gestión de estado de eventos
///
/// Implementa la lógica de negocio para eventos usando BLoC pattern.
/// Depende de IEventRepository para abstracción de datos.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_event_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final IEventRepository eventRepository;

  EventsBloc({required this.eventRepository}) : super(const EventsInitial()) {
    on<EventsFetchRequested>(_onFetchRequested);
    on<EventsFetchUpcomingRequested>(_onFetchUpcomingRequested);
    on<EventsFetchPastRequested>(_onFetchPastRequested);
    on<EventsFetchUserEventsRequested>(_onFetchUserEventsRequested);
    on<EventsFetchJoinedEventsRequested>(_onFetchJoinedEventsRequested);
    on<EventsCreateRequested>(_onCreateRequested);
    on<EventsUpdateRequested>(_onUpdateRequested);
    on<EventsDeleteRequested>(_onDeleteRequested);
    on<EventsJoinRequested>(_onJoinRequested);
    on<EventsLeaveRequested>(_onLeaveRequested);
    on<EventsSearchRequested>(_onSearchRequested);
    on<EventsLoadDetailsRequested>(_onLoadDetailsRequested);
  }

  /// Carga todos los eventos
  Future<void> _onFetchRequested(
    EventsFetchRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.getEvents();
      emit(EventsLoaded(events: events, filterType: 'all'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga eventos próximos
  Future<void> _onFetchUpcomingRequested(
    EventsFetchUpcomingRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.getUpcomingEvents();
      emit(EventsLoaded(events: events, filterType: 'upcoming'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga eventos pasados
  Future<void> _onFetchPastRequested(
    EventsFetchPastRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.getPastEvents();
      emit(EventsLoaded(events: events, filterType: 'past'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga eventos creados por el usuario
  Future<void> _onFetchUserEventsRequested(
    EventsFetchUserEventsRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.getEventsByUser(event.userId);
      emit(EventsLoaded(events: events, filterType: 'user'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga eventos en los que participa el usuario
  Future<void> _onFetchJoinedEventsRequested(
    EventsFetchJoinedEventsRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.getEventsUserJoined(event.userId);
      emit(EventsLoaded(events: events, filterType: 'joined'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Crea un nuevo evento
  Future<void> _onCreateRequested(
    EventsCreateRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      await eventRepository.createEvent(
        title: event.title,
        description: event.description,
        date: event.date,
        puntoEncuentro: event.puntoEncuentro,
        createdBy: event.createdBy,
        destino: event.destino,
        puntoEncuentroLat: event.puntoEncuentroLat,
        puntoEncuentroLng: event.puntoEncuentroLng,
        destinoLat: event.destinoLat,
        destinoLng: event.destinoLng,
        fotoUrl: event.fotoUrl,
        grupoId: event.grupoId,
        isPublic: event.isPublic,
      );
      emit(
        const EventsOperationSuccess(
          message: 'Evento creado exitosamente',
          operationType: EventsOperationType.created,
        ),
      );
      // Recargar la lista de eventos
      add(const EventsFetchRequested());
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Actualiza un evento existente
  Future<void> _onUpdateRequested(
    EventsUpdateRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      await eventRepository.updateEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        date: event.date,
        puntoEncuentro: event.puntoEncuentro,
        destino: event.destino,
        puntoEncuentroLat: event.puntoEncuentroLat,
        puntoEncuentroLng: event.puntoEncuentroLng,
        destinoLat: event.destinoLat,
        destinoLng: event.destinoLng,
        fotoUrl: event.fotoUrl,
        grupoId: event.grupoId,
        isPublic: event.isPublic,
      );
      emit(
        const EventsOperationSuccess(
          message: 'Evento actualizado exitosamente',
          operationType: EventsOperationType.updated,
        ),
      );
      // Recargar la lista de eventos
      add(const EventsFetchRequested());
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Elimina un evento
  Future<void> _onDeleteRequested(
    EventsDeleteRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      await eventRepository.deleteEvent(event.eventId);
      emit(
        const EventsOperationSuccess(
          message: 'Evento eliminado exitosamente',
          operationType: EventsOperationType.deleted,
        ),
      );
      // Recargar la lista de eventos
      add(const EventsFetchRequested());
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Unirse a un evento
  Future<void> _onJoinRequested(
    EventsJoinRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      await eventRepository.joinEvent(
        event.eventId,
        event.userId,
        estado: event.estado,
      );
      emit(
        const EventsOperationSuccess(
          message: '¡Te has unido al evento!',
          operationType: EventsOperationType.joined,
        ),
      );
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Salir de un evento
  Future<void> _onLeaveRequested(
    EventsLeaveRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      await eventRepository.leaveEvent(event.eventId, event.userId);
      emit(
        const EventsOperationSuccess(
          message: 'Has salido del evento',
          operationType: EventsOperationType.left,
        ),
      );
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Busca eventos
  Future<void> _onSearchRequested(
    EventsSearchRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final events = await eventRepository.searchEvents(event.query);
      emit(EventsLoaded(events: events, filterType: 'search'));
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga detalles de un evento específico
  Future<void> _onLoadDetailsRequested(
    EventsLoadDetailsRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());
    try {
      final eventData = await eventRepository.getEventById(event.eventId);
      if (eventData == null) {
        emit(const EventsError(message: 'Evento no encontrado'));
        return;
      }

      final participantsCount = await eventRepository.getEventParticipantsCount(
        event.eventId,
      );

      emit(
        EventsDetailLoaded(
          event: eventData,
          participantsCount: participantsCount,
        ),
      );
    } catch (e) {
      emit(EventsError(message: _parseErrorMessage(e)));
    }
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('permission denied')) {
      return 'No tienes permiso para realizar esta acción';
    } else if (message.contains('not found')) {
      return 'Evento no encontrado';
    } else if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    }
    return 'Error: $message';
  }
}
