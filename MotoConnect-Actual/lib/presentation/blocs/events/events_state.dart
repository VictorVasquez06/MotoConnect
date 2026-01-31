/// Estados del EventsBloc
///
/// Define todos los posibles estados de la gestión de eventos.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/event_model.dart';

/// Clase base abstracta para todos los estados de Events
abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar eventos
class EventsInitial extends EventsState {
  const EventsInitial();
}

/// Estado de carga durante operaciones
class EventsLoading extends EventsState {
  const EventsLoading();
}

/// Estado con lista de eventos cargada exitosamente
class EventsLoaded extends EventsState {
  final List<Event> events;
  final String? filterType; // 'all', 'upcoming', 'past', 'user', 'joined'

  const EventsLoaded({required this.events, this.filterType});

  @override
  List<Object?> get props => [events, filterType];

  /// Crea una copia con eventos actualizados
  EventsLoaded copyWith({List<Event>? events, String? filterType}) {
    return EventsLoaded(
      events: events ?? this.events,
      filterType: filterType ?? this.filterType,
    );
  }
}

/// Estado con detalles de un evento específico
class EventsDetailLoaded extends EventsState {
  final Event event;
  final int participantsCount;
  final bool isUserJoined;
  final bool isUserCreator;

  const EventsDetailLoaded({
    required this.event,
    this.participantsCount = 0,
    this.isUserJoined = false,
    this.isUserCreator = false,
  });

  @override
  List<Object?> get props => [
    event,
    participantsCount,
    isUserJoined,
    isUserCreator,
  ];
}

/// Estado de error en operaciones de eventos
class EventsError extends EventsState {
  final String message;

  const EventsError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado de operación exitosa (crear, actualizar, eliminar, unirse, salir)
class EventsOperationSuccess extends EventsState {
  final String message;
  final EventsOperationType operationType;

  const EventsOperationSuccess({
    required this.message,
    required this.operationType,
  });

  @override
  List<Object?> get props => [message, operationType];
}

/// Tipos de operaciones exitosas
enum EventsOperationType { created, updated, deleted, joined, left }
