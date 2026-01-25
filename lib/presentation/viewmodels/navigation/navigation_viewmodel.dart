/// ViewModel de Navegación Turn-by-Turn
///
/// Patrón MVVM:
/// - Hereda de ChangeNotifier para notificar cambios a la UI
/// - Gestiona el estado completo de navegación
/// - Orquesta UseCases
/// - Se suscribe a LocationTrackingService
///
/// Responsabilidades:
/// - Iniciar/pausar/reanudar/finalizar navegación
/// - Actualizar progreso en tiempo real
/// - Detectar desvíos y recalcular rutas
/// - Exponer estado para la UI
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/navigation_session.dart';
import '../../../data/models/navigation_step.dart';
import '../../../domain/usecases/navigation/start_navigation_usecase.dart';
import '../../../domain/usecases/navigation/update_navigation_progress_usecase.dart';
import '../../../domain/usecases/navigation/pause_navigation_usecase.dart';
import '../../../domain/usecases/navigation/resume_navigation_usecase.dart';
import '../../../domain/usecases/navigation/end_navigation_usecase.dart';
import '../../../domain/usecases/navigation/recalculate_route_usecase.dart';
import '../../../services/location_tracking_service.dart';
import '../../../services/navigation_voice_service.dart';

class NavigationViewModel extends ChangeNotifier {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  final StartNavigationUseCase _startNavigationUseCase;
  final UpdateNavigationProgressUseCase _updateProgressUseCase;
  final PauseNavigationUseCase _pauseNavigationUseCase;
  final ResumeNavigationUseCase _resumeNavigationUseCase;
  final EndNavigationUseCase _endNavigationUseCase;
  final RecalculateRouteUseCase _recalculateRouteUseCase;
  final LocationTrackingService _locationService;
  final NavigationVoiceService _voiceService;

  // ========================================
  // ESTADO
  // ========================================

  /// Sesión de navegación actual
  NavigationSession? _currentSession;

  /// Estado de la navegación
  NavigationStatus _status = NavigationStatus.planning;

  /// Mensaje de error (si hay)
  String? _errorMessage;

  /// Stream subscription de ubicación
  StreamSubscription<Position>? _locationSubscription;

  /// Timer para anuncios periódicos de progreso
  Timer? _progressAnnouncementTimer;

  /// Indica si está calculando ruta
  bool _isCalculating = false;

  /// Última ubicación conocida
  LatLng? _lastKnownLocation;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  NavigationViewModel({
    required StartNavigationUseCase startNavigationUseCase,
    required UpdateNavigationProgressUseCase updateProgressUseCase,
    required PauseNavigationUseCase pauseNavigationUseCase,
    required ResumeNavigationUseCase resumeNavigationUseCase,
    required EndNavigationUseCase endNavigationUseCase,
    required RecalculateRouteUseCase recalculateRouteUseCase,
    required LocationTrackingService locationService,
    required NavigationVoiceService voiceService,
  })  : _startNavigationUseCase = startNavigationUseCase,
        _updateProgressUseCase = updateProgressUseCase,
        _pauseNavigationUseCase = pauseNavigationUseCase,
        _resumeNavigationUseCase = resumeNavigationUseCase,
        _endNavigationUseCase = endNavigationUseCase,
        _recalculateRouteUseCase = recalculateRouteUseCase,
        _locationService = locationService,
        _voiceService = voiceService;

  // ========================================
  // GETTERS PÚBLICOS
  // ========================================

  /// Sesión actual de navegación
  NavigationSession? get currentSession => _currentSession;

  /// Estado actual
  NavigationStatus get status => _status;

  /// Mensaje de error
  String? get errorMessage => _errorMessage;

  /// Indica si está calculando
  bool get isCalculating => _isCalculating;

  /// Última ubicación conocida
  LatLng? get lastKnownLocation => _lastKnownLocation;

  // ========================================
  // GETTERS DE CONVENIENCIA
  // ========================================

  /// Paso actual de navegación
  NavigationStep? get currentStep => _currentSession?.currentStep;

  /// Siguiente paso
  NavigationStep? get nextStep => _currentSession?.nextStep;

  /// Indica si está navegando
  bool get isNavigating => _status == NavigationStatus.navigating;

  /// Indica si está pausado
  bool get isPaused => _status == NavigationStatus.paused;

  /// Indica si está fuera de ruta
  bool get isOffRoute => _status == NavigationStatus.offRoute;

  /// Indica si está completado
  bool get isCompleted => _status == NavigationStatus.completed;

  /// Indica si fue cancelado
  bool get isCancelled => _status == NavigationStatus.cancelled;

  /// Indica si hay sesión activa
  bool get hasActiveSession => _currentSession != null;

  /// ETA formateado
  String? get etaFormatted {
    if (_currentSession == null) return null;
    final eta = _currentSession!.estimatedArrivalTime;
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicia navegación
  ///
  /// [destination] - Destino final
  /// [destinationName] - Nombre del destino (opcional)
  /// [sesionGrupalId] - ID de sesión grupal (null si es individual)
  /// [mode] - Modo de transporte
  Future<void> startNavigation({
    required LatLng destination,
    String? destinationName,
    String? sesionGrupalId,
    String mode = 'driving',
  }) async {
    try {
      _status = NavigationStatus.planning;
      _errorMessage = null;
      _isCalculating = true;
      notifyListeners();

      // Ejecutar UseCase
      _currentSession = await _startNavigationUseCase.execute(
        destination: destination,
        destinationName: destinationName,
        sesionGrupalId: sesionGrupalId,
        mode: mode,
      );

      _status = NavigationStatus.navigating;
      _isCalculating = false;
      notifyListeners();

      // Inicializar voz
      await _voiceService.initialize();

      // Anunciar primera instrucción
      if (_currentSession!.currentStep != null) {
        await _voiceService.announceInstruction(
          _currentSession!.currentStep!.instruction,
          _currentSession!.currentStep!.distanceText,
          stepIndex: _currentSession!.currentStepIndex,
        );
      }

      // Iniciar tracking de ubicación
      await _startLocationTracking();

      // Iniciar anuncios periódicos cada 2 minutos
      _progressAnnouncementTimer = Timer.periodic(
        const Duration(minutes: 2),
        (timer) {
          if (_currentSession != null && isNavigating) {
            _voiceService.announceProgress(
              _currentSession!.remainingDistanceText,
              _currentSession!.remainingDurationText,
            );
          }
        },
      );
    } catch (e) {
      _errorMessage = 'Error al iniciar navegación: ${e.toString()}';
      _status = NavigationStatus.cancelled;
      _isCalculating = false;
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  /// Pausa la navegación
  Future<void> pauseNavigation() async {
    if (_currentSession == null || !isNavigating) return;

    try {
      await _pauseNavigationUseCase.execute(_currentSession!.id);
      _status = NavigationStatus.paused;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al pausar: ${e.toString()}';
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  /// Reanuda la navegación
  Future<void> resumeNavigation() async {
    if (_currentSession == null || !isPaused) return;

    try {
      await _resumeNavigationUseCase.execute(_currentSession!.id);
      _status = NavigationStatus.navigating;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al reanudar: ${e.toString()}';
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  /// Finaliza la navegación
  ///
  /// [completed] - true si llegó al destino, false si canceló
  Future<void> endNavigation({bool completed = false}) async {
    if (_currentSession == null) return;

    try {
      await _endNavigationUseCase.execute(
        sessionId: _currentSession!.id,
        completed: completed,
      );

      _status =
          completed ? NavigationStatus.completed : NavigationStatus.cancelled;

      // Cancelar suscripción de ubicación
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al finalizar: ${e.toString()}';
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  /// Recalcula la ruta
  Future<void> recalculateRoute() async {
    if (_currentSession == null) return;

    try {
      _isCalculating = true;
      notifyListeners();

      _currentSession = await _recalculateRouteUseCase.execute(
        currentSession: _currentSession!,
      );

      _status = NavigationStatus.navigating;
      _isCalculating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al recalcular: ${e.toString()}';
      _isCalculating = false;
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }

  /// Limpia el error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Inicia el tracking de ubicación
  Future<void> _startLocationTracking() async {
    // Cancelar suscripción previa si existe
    await _locationSubscription?.cancel();

    // Suscribirse al stream de ubicación
    _locationSubscription = _locationService.ubicacionStream.listen(
      _onLocationUpdate,
      onError: (error) {
        debugPrint('Error en ubicación: $error');
        _errorMessage = 'Error de GPS: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  /// Callback cuando cambia la ubicación
  Future<void> _onLocationUpdate(Position position) async {
    if (_currentSession == null || !isNavigating) return;

    try {
      final currentLocation = LatLng(position.latitude, position.longitude);
      final currentSpeedKmh = position.speed * 3.6; // m/s a km/h

      _lastKnownLocation = currentLocation;

      // Guardar índice de paso anterior para detectar cambios
      final previousStepIndex = _currentSession!.currentStepIndex;

      // Actualizar progreso
      _currentSession = await _updateProgressUseCase.execute(
        currentSession: _currentSession!,
        currentLocation: currentLocation,
        currentSpeedKmh: currentSpeedKmh,
      );

      // Detectar cambio de paso y anunciar nueva instrucción
      if (_currentSession!.currentStepIndex != previousStepIndex) {
        if (_currentSession!.currentStep != null) {
          await _voiceService.announceInstruction(
            _currentSession!.currentStep!.instruction,
            _currentSession!.currentStep!.distanceText,
            stepIndex: _currentSession!.currentStepIndex,
          );
        }
      }

      // Alertas de proximidad a giros
      if (_currentSession!.currentStep != null) {
        final distanceToStep = _currentSession!.currentStep!.distanceMeters;

        // Alerta a 200m
        if (distanceToStep <= 200 && distanceToStep > 150) {
          await _voiceService.announceProximityAlert(
            _currentSession!.currentStep!.instruction,
            200,
          );
        }
        // Alerta a 100m
        else if (distanceToStep <= 100 && distanceToStep > 50) {
          await _voiceService.announceProximityAlert(
            _currentSession!.currentStep!.instruction,
            100,
          );
        }
      }

      // Verificar si llegó al destino
      if (_currentSession!.isLastStep) {
        final distanceToEnd = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          _currentSession!.destination.latitude,
          _currentSession!.destination.longitude,
        );

        // Si está a menos de 30 metros del destino, marcar como completado
        if (distanceToEnd < 30.0) {
          // Anunciar llegada
          await _voiceService.announceArrival();

          // Cambiar estado a completado (NO llamar endNavigation)
          _status = NavigationStatus.completed;
          await _locationSubscription?.cancel();
          _locationSubscription = null;
          _progressAnnouncementTimer?.cancel();
          notifyListeners();
          return;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error actualizando progreso: $e');
    }
  }

  // ========================================
  // LIFECYCLE
  // ========================================

  /// Guarda la ruta completada en Supabase
  ///
  /// [routeName] - Nombre de la ruta
  /// [routeDescription] - Descripción opcional
  Future<void> saveCompletedRoute({
    required String routeName,
    String? routeDescription,
  }) async {
    if (_currentSession == null || !isCompleted) {
      throw Exception('No hay sesión completada para guardar');
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Usuario no autenticado');
    }

    // Convertir polyline a JSON
    final puntosJson = _currentSession!.completePolyline
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    // Calcular métricas reales
    final distanciaKm = _currentSession!.totalDistanceMeters / 1000.0;
    final duracionMinutos = _currentSession!.elapsedTime.inMinutes;

    // Guardar en Supabase
    await Supabase.instance.client.from('rutas_realizadas').insert({
      'usuario_id': uid,
      'nombre_ruta': routeName,
      'fecha': DateTime.now().toIso8601String(),
      'puntos': puntosJson,
      'distancia_km': distanciaKm,
      'duracion_minutos': duracionMinutos,
      'imagen_url': null,
      'descripcion_ruta':
          routeDescription?.isEmpty == true ? null : routeDescription,
    });

    debugPrint('Ruta guardada: $routeName ($distanciaKm km, $duracionMinutos min)');
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _progressAnnouncementTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}
