/// Estados del NavigationBloc
///
/// Define todos los posibles estados de la navegación turn-by-turn.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/navigation_session.dart';
import '../../../data/models/navigation_step.dart';

/// Clase base abstracta para todos los estados de navegación
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - navegación en reposo
class NavigationInitial extends NavigationState {
  const NavigationInitial();
}

/// Estado de carga - calculando ruta inicial
class NavigationLoading extends NavigationState {
  final String? message;

  const NavigationLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado principal de navegación activa
class NavigationActive extends NavigationState {
  /// Sesión de navegación completa
  final NavigationSession session;

  /// Ubicación actual del usuario
  final LatLng currentLocation;

  /// Paso actual de navegación
  final NavigationStep currentStep;

  /// Siguiente paso (null si es el último)
  final NavigationStep? nextStep;

  /// Índice del paso actual
  final int currentStepIndex;

  /// Distancia restante al destino en metros
  final double distanceRemainingMeters;

  /// Tiempo restante estimado en segundos
  final int timeRemainingSeconds;

  /// Distancia al siguiente giro en metros
  final double distanceToNextTurnMeters;

  /// Velocidad actual en km/h
  final double? currentSpeedKmh;

  /// Si está cerca del siguiente giro (para alertas)
  final bool isNearNextTurn;

  /// Si está fuera de ruta
  final bool isOffRoute;

  /// Puntos de la polyline para dibujar en el mapa
  final List<LatLng> polyline;

  const NavigationActive({
    required this.session,
    required this.currentLocation,
    required this.currentStep,
    this.nextStep,
    required this.currentStepIndex,
    required this.distanceRemainingMeters,
    required this.timeRemainingSeconds,
    required this.distanceToNextTurnMeters,
    this.currentSpeedKmh,
    this.isNearNextTurn = false,
    this.isOffRoute = false,
    required this.polyline,
  });

  @override
  List<Object?> get props => [
    session,
    currentLocation,
    currentStep,
    nextStep,
    currentStepIndex,
    distanceRemainingMeters,
    timeRemainingSeconds,
    distanceToNextTurnMeters,
    currentSpeedKmh,
    isNearNextTurn,
    isOffRoute,
    polyline,
  ];

  /// Copia con modificaciones
  NavigationActive copyWith({
    NavigationSession? session,
    LatLng? currentLocation,
    NavigationStep? currentStep,
    NavigationStep? nextStep,
    int? currentStepIndex,
    double? distanceRemainingMeters,
    int? timeRemainingSeconds,
    double? distanceToNextTurnMeters,
    double? currentSpeedKmh,
    bool? isNearNextTurn,
    bool? isOffRoute,
    List<LatLng>? polyline,
  }) {
    return NavigationActive(
      session: session ?? this.session,
      currentLocation: currentLocation ?? this.currentLocation,
      currentStep: currentStep ?? this.currentStep,
      nextStep: nextStep ?? this.nextStep,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceRemainingMeters:
          distanceRemainingMeters ?? this.distanceRemainingMeters,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      distanceToNextTurnMeters:
          distanceToNextTurnMeters ?? this.distanceToNextTurnMeters,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      isNearNextTurn: isNearNextTurn ?? this.isNearNextTurn,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      polyline: polyline ?? this.polyline,
    );
  }

  // ========================================
  // GETTERS DE CONVENIENCIA PARA UI
  // ========================================

  /// Instrucción actual formateada
  String get currentInstruction => currentStep.instruction;

  /// Descripción de la maniobra actual
  String get currentManeuverDescription => currentStep.maneuverDescription;

  /// Icono de la maniobra actual
  IconData get currentManeuverIcon => currentStep.maneuverIcon;

  /// Texto de distancia restante formateado
  String get distanceRemainingText {
    if (distanceRemainingMeters < 1000) {
      return '${distanceRemainingMeters.toInt()} m';
    }
    return '${(distanceRemainingMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Texto de tiempo restante formateado
  String get timeRemainingText {
    final mins = (timeRemainingSeconds / 60).ceil();
    if (mins < 60) {
      return '$mins min';
    }
    final hours = (mins / 60).floor();
    final remainingMins = mins % 60;
    return '${hours}h ${remainingMins}min';
  }

  /// Texto de distancia al siguiente giro
  String get distanceToNextTurnText {
    if (distanceToNextTurnMeters < 1000) {
      return '${distanceToNextTurnMeters.toInt()} m';
    }
    return '${(distanceToNextTurnMeters / 1000).toStringAsFixed(1)} km';
  }

  /// ETA (hora estimada de llegada)
  DateTime get estimatedArrivalTime {
    return DateTime.now().add(Duration(seconds: timeRemainingSeconds));
  }

  /// ETA formateado como hora
  String get etaText {
    final eta = estimatedArrivalTime;
    final hour = eta.hour.toString().padLeft(2, '0');
    final minute = eta.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Progreso de navegación (0.0 - 1.0)
  double get progress {
    if (session.totalDistanceMeters == 0) return 0;
    return 1 - (distanceRemainingMeters / session.totalDistanceMeters);
  }

  /// Número total de pasos
  int get totalSteps => session.steps.length;

  /// Indica si es el último paso
  bool get isLastStep => currentStepIndex == session.steps.length - 1;
}

/// Estado de navegación pausada
class NavigationPausedState extends NavigationState {
  final NavigationSession session;
  final LatLng lastKnownLocation;
  final int lastStepIndex;

  const NavigationPausedState({
    required this.session,
    required this.lastKnownLocation,
    required this.lastStepIndex,
  });

  @override
  List<Object?> get props => [session, lastKnownLocation, lastStepIndex];
}

/// Estado de llegada al destino
class NavigationArrival extends NavigationState {
  final NavigationSession session;
  final Duration totalDuration;
  final double totalDistanceTraveled;

  const NavigationArrival({
    required this.session,
    required this.totalDuration,
    required this.totalDistanceTraveled,
  });

  @override
  List<Object?> get props => [session, totalDuration, totalDistanceTraveled];

  /// Texto de duración total formateado
  String get totalDurationText {
    final mins = totalDuration.inMinutes;
    if (mins < 60) {
      return '$mins min';
    }
    final hours = (mins / 60).floor();
    final remainingMins = mins % 60;
    return '${hours}h ${remainingMins}min';
  }

  /// Texto de distancia total formateado
  String get totalDistanceText {
    if (totalDistanceTraveled < 1000) {
      return '${totalDistanceTraveled.toInt()} m';
    }
    return '${(totalDistanceTraveled / 1000).toStringAsFixed(1)} km';
  }
}

/// Estado de error
class NavigationError extends NavigationState {
  final String message;
  final NavigationSession? previousSession;

  const NavigationError({required this.message, this.previousSession});

  @override
  List<Object?> get props => [message, previousSession];
}

/// Estado de recálculo de ruta
class NavigationRecalculating extends NavigationState {
  final NavigationSession currentSession;
  final LatLng currentLocation;

  const NavigationRecalculating({
    required this.currentSession,
    required this.currentLocation,
  });

  @override
  List<Object?> get props => [currentSession, currentLocation];
}
