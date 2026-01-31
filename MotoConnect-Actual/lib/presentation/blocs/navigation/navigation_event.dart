/// Eventos del NavigationBloc
///
/// Define todas las acciones que pueden modificar el estado de navegación.
library;

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/navigation_step.dart';

/// Clase base abstracta para todos los eventos de navegación
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para iniciar la navegación hacia un destino
class NavigationStarted extends NavigationEvent {
  final LatLng origin;
  final LatLng destination;
  final String? destinationName;
  final List<NavigationStep> steps;
  final List<LatLng> polyline;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final String? sesionGrupalId;

  const NavigationStarted({
    required this.origin,
    required this.destination,
    this.destinationName,
    required this.steps,
    required this.polyline,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    this.sesionGrupalId,
  });

  @override
  List<Object?> get props => [
    origin,
    destination,
    destinationName,
    steps,
    polyline,
    totalDistanceMeters,
    totalDurationSeconds,
    sesionGrupalId,
  ];
}

/// Evento interno para cuando el GPS reporta nueva posición
class NavigationPositionUpdated extends NavigationEvent {
  final LatLng currentLocation;
  final double? speedKmh;
  final double? heading;

  const NavigationPositionUpdated({
    required this.currentLocation,
    this.speedKmh,
    this.heading,
  });

  @override
  List<Object?> get props => [currentLocation, speedKmh, heading];
}

/// Evento para pausar la navegación
class NavigationPaused extends NavigationEvent {
  const NavigationPaused();
}

/// Evento para reanudar la navegación
class NavigationResumed extends NavigationEvent {
  const NavigationResumed();
}

/// Evento para detener/cancelar la navegación
class NavigationStopped extends NavigationEvent {
  const NavigationStopped();
}

/// Evento cuando el usuario se desvía de la ruta
class NavigationRecalculateRequested extends NavigationEvent {
  final LatLng currentLocation;

  const NavigationRecalculateRequested({required this.currentLocation});

  @override
  List<Object?> get props => [currentLocation];
}

/// Evento cuando se avanza al siguiente paso
class NavigationStepAdvanced extends NavigationEvent {
  final int newStepIndex;

  const NavigationStepAdvanced({required this.newStepIndex});

  @override
  List<Object?> get props => [newStepIndex];
}

/// Evento cuando se llega al destino
class NavigationArrivalDetected extends NavigationEvent {
  const NavigationArrivalDetected();
}

/// Evento para restaurar una sesión de navegación existente
class NavigationSessionRestored extends NavigationEvent {
  final String sessionId;

  const NavigationSessionRestored({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Evento para verificar si hay navegación activa al iniciar la app
class NavigationCheckActiveSession extends NavigationEvent {
  const NavigationCheckActiveSession();
}
