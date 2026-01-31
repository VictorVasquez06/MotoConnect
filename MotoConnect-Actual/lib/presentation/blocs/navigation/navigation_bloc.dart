/// NavigationBloc - Gestión de estado de navegación turn-by-turn
///
/// Implementa la lógica de negocio para navegación GPS usando BLoC pattern.
/// Depende de INavigationRepository para abstracción de datos.
/// Soporta navegación individual y grupal con actualizaciones en tiempo real.
///
/// NOTA: La lógica visual (GoogleMapController, Markers, Polylines) debe
/// permanecer en el widget State. Este BLoC solo maneja datos de navegación.
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/repositories/i_navigation_repository.dart';
import '../../../data/models/navigation_session.dart';

import '../../../data/services/navigation/navigation_tracking_service.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final INavigationRepository navigationRepository;
  final NavigationTrackingService _trackingService =
      NavigationTrackingService();

  /// Sesión de navegación actual
  NavigationSession? _currentSession;

  /// Suscripción a actualizaciones de posición (si aplica)
  StreamSubscription? _positionSubscription;

  /// Tiempo de inicio de navegación
  DateTime? _navigationStartTime;

  /// Distancia total recorrida
  double _totalDistanceTraveled = 0;

  /// Última ubicación conocida
  LatLng? _lastKnownLocation;

  NavigationBloc({required this.navigationRepository})
    : super(const NavigationInitial()) {
    on<NavigationStarted>(_onNavigationStarted);
    on<NavigationPositionUpdated>(_onPositionUpdated);
    on<NavigationPaused>(_onNavigationPaused);
    on<NavigationResumed>(_onNavigationResumed);
    on<NavigationStopped>(_onNavigationStopped);
    on<NavigationRecalculateRequested>(_onRecalculateRequested);
    on<NavigationStepAdvanced>(_onStepAdvanced);
    on<NavigationArrivalDetected>(_onArrivalDetected);
    on<NavigationSessionRestored>(_onSessionRestored);
    on<NavigationCheckActiveSession>(_onCheckActiveSession);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }

  /// Inicia una nueva sesión de navegación
  Future<void> _onNavigationStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) async {
    emit(const NavigationLoading(message: 'Iniciando navegación...'));

    try {
      // Crear sesión de navegación en el repositorio
      final session = await navigationRepository.createNavigationSession(
        origin: event.origin,
        destination: event.destination,
        destinationName: event.destinationName,
        sesionGrupalId: event.sesionGrupalId,
        steps: event.steps,
        completePolyline: event.polyline,
      );

      _currentSession = session;
      _navigationStartTime = DateTime.now();
      _totalDistanceTraveled = 0;
      _lastKnownLocation = event.origin;

      // Emitir estado activo inicial
      emit(
        _buildActiveState(
          session: session,
          currentLocation: event.origin,
          currentStepIndex: 0,
        ),
      );
    } catch (e) {
      emit(NavigationError(message: _parseErrorMessage(e)));
    }
  }

  /// Maneja actualizaciones de posición GPS
  Future<void> _onPositionUpdated(
    NavigationPositionUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) return;

    final currentState = state;
    if (currentState is! NavigationActive) return;

    try {
      // Determinar el paso actual basado en la ubicación
      final newStepIndex = _trackingService.determineCurrentStep(
        currentLocation: event.currentLocation,
        steps: session.steps,
        lastStepIndex: currentState.currentStepIndex,
      );

      // Verificar si se llegó al destino
      if (newStepIndex >= session.steps.length - 1) {
        final lastStep = session.steps.last;
        final distanceToEnd = _trackingService.calculateDistanceToStepEnd(
          currentLocation: event.currentLocation,
          currentStep: lastStep,
        );

        if (distanceToEnd < 30) {
          // Menos de 30 metros del destino
          add(const NavigationArrivalDetected());
          return;
        }
      }

      // Calcular distancia recorrida desde última posición
      if (_lastKnownLocation != null) {
        final distanceDelta = _trackingService.calcularDistancia(
          lat1: _lastKnownLocation!.latitude,
          lng1: _lastKnownLocation!.longitude,
          lat2: event.currentLocation.latitude,
          lng2: event.currentLocation.longitude,
        );
        _totalDistanceTraveled += distanceDelta;
      }
      _lastKnownLocation = event.currentLocation;

      // Verificar si está fuera de ruta
      final currentStep = session.steps[newStepIndex];
      final isOffRoute = _trackingService.isOffRoute(
        currentLocation: event.currentLocation,
        currentStep: currentStep,
      );

      if (isOffRoute) {
        // Emitir estado con flag de off-route
        emit(
          currentState.copyWith(
            currentLocation: event.currentLocation,
            isOffRoute: true,
            currentSpeedKmh: event.speedKmh,
          ),
        );
        return;
      }

      // Calcular distancia al siguiente giro
      final distanceToNextTurn = _trackingService.calculateDistanceToStepEnd(
        currentLocation: event.currentLocation,
        currentStep: currentStep,
      );

      // Verificar si está cerca del siguiente giro
      final nextStep =
          newStepIndex + 1 < session.steps.length
              ? session.steps[newStepIndex + 1]
              : null;

      final isNearNextTurn =
          nextStep != null &&
          _trackingService.isNearNextTurn(
            currentLocation: event.currentLocation,
            nextStep: nextStep,
          );

      // Calcular distancia y tiempo restante
      final remainingDistance = _trackingService.calculateRemainingDistance(
        currentLocation: event.currentLocation,
        steps: session.steps,
        currentStepIndex: newStepIndex,
      );

      final remainingDuration = _trackingService.calculateRemainingDuration(
        steps: session.steps,
        currentStepIndex: newStepIndex,
      );

      // Actualizar progreso en el repositorio (para navegación grupal)
      if (session.isGroupNavigation) {
        await navigationRepository.updateNavigationProgress(
          sessionId: session.id,
          currentStepIndex: newStepIndex,
          currentLocation: event.currentLocation,
          distanceToNextStep: distanceToNextTurn,
          etaSeconds: remainingDuration,
          remainingDistance: remainingDistance,
        );
      }

      // Emitir nuevo estado activo
      emit(
        currentState.copyWith(
          currentLocation: event.currentLocation,
          currentStep: currentStep,
          nextStep: nextStep,
          currentStepIndex: newStepIndex,
          distanceRemainingMeters: remainingDistance,
          timeRemainingSeconds: remainingDuration,
          distanceToNextTurnMeters: distanceToNextTurn,
          currentSpeedKmh: event.speedKmh,
          isNearNextTurn: isNearNextTurn,
          isOffRoute: false,
        ),
      );

      // Actualizar sesión en el repositorio
      await navigationRepository.updateNavigationSession(
        sessionId: session.id,
        currentStepIndex: newStepIndex,
        distanceTraveled: _totalDistanceTraveled,
      );
    } catch (e) {
      // Log error pero no interrumpir navegación
      // ignore: avoid_print
      print('Error updating navigation: $e');
    }
  }

  /// Pausa la navegación
  Future<void> _onNavigationPaused(
    NavigationPaused event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) return;

    final currentState = state;
    if (currentState is! NavigationActive) return;

    try {
      await navigationRepository.pauseNavigation(session.id);

      emit(
        NavigationPausedState(
          session: session,
          lastKnownLocation: currentState.currentLocation,
          lastStepIndex: currentState.currentStepIndex,
        ),
      );
    } catch (e) {
      emit(
        NavigationError(
          message: _parseErrorMessage(e),
          previousSession: session,
        ),
      );
    }
  }

  /// Reanuda la navegación
  Future<void> _onNavigationResumed(
    NavigationResumed event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) return;

    final currentState = state;
    if (currentState is! NavigationPausedState) return;

    try {
      await navigationRepository.resumeNavigation(session.id);

      emit(
        _buildActiveState(
          session: session,
          currentLocation: currentState.lastKnownLocation,
          currentStepIndex: currentState.lastStepIndex,
        ),
      );
    } catch (e) {
      emit(
        NavigationError(
          message: _parseErrorMessage(e),
          previousSession: session,
        ),
      );
    }
  }

  /// Detiene/cancela la navegación
  Future<void> _onNavigationStopped(
    NavigationStopped event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) {
      emit(const NavigationInitial());
      return;
    }

    try {
      await navigationRepository.endNavigation(
        sessionId: session.id,
        status: NavigationStatus.cancelled,
      );

      await navigationRepository.deleteUserProgress(session.id);

      _currentSession = null;
      _navigationStartTime = null;
      _totalDistanceTraveled = 0;
      _lastKnownLocation = null;

      emit(const NavigationInitial());
    } catch (e) {
      emit(NavigationError(message: _parseErrorMessage(e)));
    }
  }

  /// Solicita recálculo de ruta
  Future<void> _onRecalculateRequested(
    NavigationRecalculateRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) return;

    emit(
      NavigationRecalculating(
        currentSession: session,
        currentLocation: event.currentLocation,
      ),
    );

    // NOTA: El recálculo real de ruta debe hacerse desde la UI
    // usando Google Directions API y luego reiniciar la navegación
    // con los nuevos pasos. Este estado notifica a la UI que debe recalcular.
  }

  /// Avanza al siguiente paso
  void _onStepAdvanced(
    NavigationStepAdvanced event,
    Emitter<NavigationState> emit,
  ) {
    final currentState = state;
    if (currentState is! NavigationActive) return;

    final session = _currentSession;
    if (session == null) return;

    if (event.newStepIndex >= session.steps.length) {
      add(const NavigationArrivalDetected());
      return;
    }

    final newStep = session.steps[event.newStepIndex];
    final nextStep =
        event.newStepIndex + 1 < session.steps.length
            ? session.steps[event.newStepIndex + 1]
            : null;

    emit(
      currentState.copyWith(
        currentStep: newStep,
        nextStep: nextStep,
        currentStepIndex: event.newStepIndex,
      ),
    );
  }

  /// Maneja llegada al destino
  Future<void> _onArrivalDetected(
    NavigationArrivalDetected event,
    Emitter<NavigationState> emit,
  ) async {
    final session = _currentSession;
    if (session == null) return;

    try {
      await navigationRepository.endNavigation(
        sessionId: session.id,
        status: NavigationStatus.completed,
      );

      await navigationRepository.deleteUserProgress(session.id);

      final totalDuration =
          _navigationStartTime != null
              ? DateTime.now().difference(_navigationStartTime!)
              : Duration.zero;

      emit(
        NavigationArrival(
          session: session,
          totalDuration: totalDuration,
          totalDistanceTraveled: _totalDistanceTraveled,
        ),
      );

      _currentSession = null;
      _navigationStartTime = null;
    } catch (e) {
      emit(
        NavigationError(
          message: _parseErrorMessage(e),
          previousSession: session,
        ),
      );
    }
  }

  /// Restaura una sesión de navegación existente
  Future<void> _onSessionRestored(
    NavigationSessionRestored event,
    Emitter<NavigationState> emit,
  ) async {
    emit(const NavigationLoading(message: 'Restaurando navegación...'));

    try {
      final session = await navigationRepository.getNavigationSession(
        event.sessionId,
      );

      if (session == null) {
        emit(const NavigationError(message: 'Sesión no encontrada'));
        return;
      }

      _currentSession = session;
      _navigationStartTime = session.startTime;
      _totalDistanceTraveled = session.distanceTraveledMeters;

      emit(
        _buildActiveState(
          session: session,
          currentLocation: session.origin, // Será actualizado por GPS
          currentStepIndex: session.currentStepIndex,
        ),
      );
    } catch (e) {
      emit(NavigationError(message: _parseErrorMessage(e)));
    }
  }

  /// Verifica si hay navegación activa al iniciar la app
  Future<void> _onCheckActiveSession(
    NavigationCheckActiveSession event,
    Emitter<NavigationState> emit,
  ) async {
    try {
      final activeSession = await navigationRepository.getActiveNavigation();

      if (activeSession != null) {
        add(NavigationSessionRestored(sessionId: activeSession.id));
      }
    } catch (e) {
      // No emitir error, simplemente no hay sesión activa
    }
  }

  /// Construye el estado activo inicial
  NavigationActive _buildActiveState({
    required NavigationSession session,
    required LatLng currentLocation,
    required int currentStepIndex,
  }) {
    final currentStep = session.steps[currentStepIndex];
    final nextStep =
        currentStepIndex + 1 < session.steps.length
            ? session.steps[currentStepIndex + 1]
            : null;

    final distanceToNextTurn = _trackingService.calculateDistanceToStepEnd(
      currentLocation: currentLocation,
      currentStep: currentStep,
    );

    final remainingDistance = _trackingService.calculateRemainingDistance(
      currentLocation: currentLocation,
      steps: session.steps,
      currentStepIndex: currentStepIndex,
    );

    final remainingDuration = _trackingService.calculateRemainingDuration(
      steps: session.steps,
      currentStepIndex: currentStepIndex,
    );

    return NavigationActive(
      session: session,
      currentLocation: currentLocation,
      currentStep: currentStep,
      nextStep: nextStep,
      currentStepIndex: currentStepIndex,
      distanceRemainingMeters: remainingDistance,
      timeRemainingSeconds: remainingDuration,
      distanceToNextTurnMeters: distanceToNextTurn,
      polyline: session.completePolyline,
    );
  }

  /// Parsea mensajes de error
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (message.contains('permission')) {
      return 'Se requieren permisos de ubicación';
    } else if (message.contains('not found')) {
      return 'Sesión de navegación no encontrada';
    }
    return 'Error: ${message.length > 100 ? message.substring(0, 100) : message}';
  }
}
