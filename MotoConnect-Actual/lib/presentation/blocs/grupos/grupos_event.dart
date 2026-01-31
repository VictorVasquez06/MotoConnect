/// Eventos del GruposBloc
///
/// Define todas las acciones que pueden modificar el estado de grupos.
library;

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos de grupos
abstract class GruposEvent extends Equatable {
  const GruposEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de grupos del usuario
class GruposFetchRequested extends GruposEvent {
  const GruposFetchRequested();
}

/// Evento para crear un nuevo grupo
class GruposCreateRequested extends GruposEvent {
  final String nombre;
  final String? descripcion;

  const GruposCreateRequested({required this.nombre, this.descripcion});

  @override
  List<Object?> get props => [nombre, descripcion];
}

/// Evento para unirse a un grupo mediante código
class GruposJoinRequested extends GruposEvent {
  final String codigo;

  const GruposJoinRequested({required this.codigo});

  @override
  List<Object?> get props => [codigo];
}

/// Evento para cargar el detalle de un grupo
class GruposLoadDetail extends GruposEvent {
  final String grupoId;

  const GruposLoadDetail({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// Evento para cargar miembros de un grupo
class GruposLoadMembers extends GruposEvent {
  final String grupoId;

  const GruposLoadMembers({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// Evento para iniciar una sesión de ruta activa
class GruposStartSession extends GruposEvent {
  final String grupoId;
  final String nombreSesion;
  final String? descripcion;
  final String? rutaId;

  const GruposStartSession({
    required this.grupoId,
    required this.nombreSesion,
    this.descripcion,
    this.rutaId,
  });

  @override
  List<Object?> get props => [grupoId, nombreSesion, descripcion, rutaId];
}

/// Evento para actualizar la ubicación del usuario en una sesión
class GruposUpdateLocation extends GruposEvent {
  final String sesionId;
  final double latitud;
  final double longitud;
  final double? velocidad;
  final double? direccion;

  const GruposUpdateLocation({
    required this.sesionId,
    required this.latitud,
    required this.longitud,
    this.velocidad,
    this.direccion,
  });

  @override
  List<Object?> get props => [
    sesionId,
    latitud,
    longitud,
    velocidad,
    direccion,
  ];
}

/// Evento para suscribirse a ubicaciones en tiempo real
class GruposSubscribeToLocations extends GruposEvent {
  final String sesionId;

  const GruposSubscribeToLocations({required this.sesionId});

  @override
  List<Object?> get props => [sesionId];
}

/// Evento para cancelar suscripción de ubicaciones
class GruposUnsubscribeFromLocations extends GruposEvent {
  const GruposUnsubscribeFromLocations();
}

/// Evento para eliminar un grupo
class GruposDeleteRequested extends GruposEvent {
  final String grupoId;

  const GruposDeleteRequested({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// Evento para salir de un grupo
class GruposLeaveRequested extends GruposEvent {
  final String grupoId;

  const GruposLeaveRequested({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// Evento para refrescar la lista de grupos
class GruposRefreshRequested extends GruposEvent {
  const GruposRefreshRequested();
}

/// Evento interno para actualizar ubicaciones recibidas
class GruposLocationsUpdated extends GruposEvent {
  final List<dynamic> ubicaciones;

  const GruposLocationsUpdated({required this.ubicaciones});

  @override
  List<Object?> get props => [ubicaciones];
}
