/// Eventos del EventsBloc
///
/// Define todas las acciones que pueden modificar el estado de eventos.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/event_participant_model.dart';

/// Clase base abstracta para todos los eventos de Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar todos los eventos
class EventsFetchRequested extends EventsEvent {
  const EventsFetchRequested();
}

/// Evento para cargar eventos próximos
class EventsFetchUpcomingRequested extends EventsEvent {
  const EventsFetchUpcomingRequested();
}

/// Evento para cargar eventos pasados
class EventsFetchPastRequested extends EventsEvent {
  const EventsFetchPastRequested();
}

/// Evento para cargar eventos del usuario actual
class EventsFetchUserEventsRequested extends EventsEvent {
  final String userId;

  const EventsFetchUserEventsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para cargar eventos en los que participa el usuario
class EventsFetchJoinedEventsRequested extends EventsEvent {
  final String userId;

  const EventsFetchJoinedEventsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para crear un nuevo evento
class EventsCreateRequested extends EventsEvent {
  final String title;
  final String description;
  final DateTime date;
  final String puntoEncuentro;
  final String createdBy;
  final String? destino;
  final double? puntoEncuentroLat;
  final double? puntoEncuentroLng;
  final double? destinoLat;
  final double? destinoLng;
  final String? fotoUrl;
  final String? grupoId;
  final bool isPublic;

  const EventsCreateRequested({
    required this.title,
    required this.description,
    required this.date,
    required this.puntoEncuentro,
    required this.createdBy,
    this.destino,
    this.puntoEncuentroLat,
    this.puntoEncuentroLng,
    this.destinoLat,
    this.destinoLng,
    this.fotoUrl,
    this.grupoId,
    this.isPublic = true,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    date,
    puntoEncuentro,
    createdBy,
    destino,
    puntoEncuentroLat,
    puntoEncuentroLng,
    destinoLat,
    destinoLng,
    fotoUrl,
    grupoId,
    isPublic,
  ];
}

/// Evento para actualizar un evento existente
class EventsUpdateRequested extends EventsEvent {
  final String eventId;
  final String? title;
  final String? description;
  final DateTime? date;
  final String? puntoEncuentro;
  final String? destino;
  final double? puntoEncuentroLat;
  final double? puntoEncuentroLng;
  final double? destinoLat;
  final double? destinoLng;
  final String? fotoUrl;
  final String? grupoId;
  final bool? isPublic;

  const EventsUpdateRequested({
    required this.eventId,
    this.title,
    this.description,
    this.date,
    this.puntoEncuentro,
    this.destino,
    this.puntoEncuentroLat,
    this.puntoEncuentroLng,
    this.destinoLat,
    this.destinoLng,
    this.fotoUrl,
    this.grupoId,
    this.isPublic,
  });

  @override
  List<Object?> get props => [eventId, title, description, date];
}

/// Evento para eliminar un evento
class EventsDeleteRequested extends EventsEvent {
  final String eventId;

  const EventsDeleteRequested({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

/// Evento para unirse a un evento
class EventsJoinRequested extends EventsEvent {
  final String eventId;
  final String userId;
  final EstadoAsistencia estado;

  const EventsJoinRequested({
    required this.eventId,
    required this.userId,
    this.estado = EstadoAsistencia.confirmado,
  });

  @override
  List<Object?> get props => [eventId, userId, estado];
}

/// Evento para salir de un evento
class EventsLeaveRequested extends EventsEvent {
  final String eventId;
  final String userId;

  const EventsLeaveRequested({required this.eventId, required this.userId});

  @override
  List<Object?> get props => [eventId, userId];
}

/// Evento para buscar eventos
class EventsSearchRequested extends EventsEvent {
  final String query;

  const EventsSearchRequested({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Evento para cargar detalles de un evento específico
class EventsLoadDetailsRequested extends EventsEvent {
  final String eventId;

  const EventsLoadDetailsRequested({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}
