/// Servicio de Tracking de Navegación
///
/// Responsabilidades:
/// - Determinar en qué paso está el usuario basado en GPS
/// - Calcular ETA dinámico
/// - Detectar desvíos de ruta
/// - Calcular distancia restante
/// - Alertas de proximidad a giros
library;

import 'dart:math' show min, max, sqrt, pow;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/navigation_step.dart';

class NavigationTrackingService {
  // ========================================
  // CONSTANTES
  // ========================================

  /// Umbral de proximidad para considerar que completó un paso (en metros)
  static const double PROXIMITY_THRESHOLD_METERS = 30.0;

  /// Umbral de distancia para considerar que se desvió de la ruta (en metros)
  static const double OFF_ROUTE_THRESHOLD_METERS = 50.0;

  /// Distancia de alerta para el próximo giro (en metros)
  static const double NEXT_TURN_ALERT_METERS = 200.0;

  /// Factor de corrección para ETA (considera tráfico, semáforos, etc.)
  static const double ETA_CORRECTION_FACTOR = 1.15; // 15% más tiempo

  /// Velocidad mínima para calcular ETA basado en velocidad actual (km/h)
  static const double MIN_SPEED_FOR_ETA_KMH = 5.0;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Determina en qué paso está el usuario basado en su ubicación GPS
  ///
  /// Algoritmo:
  /// 1. Empieza desde el último paso conocido
  /// 2. Verifica si está cerca del final del paso actual
  /// 3. Si está cerca, verifica si ya avanzó al siguiente paso
  /// 4. Verifica si está en la polyline del paso
  ///
  /// [currentLocation] - Ubicación actual del usuario
  /// [steps] - Lista de pasos de la ruta
  /// [lastStepIndex] - Último paso conocido
  ///
  /// Retorna:
  /// - Índice del paso actual (0-based)
  int determineCurrentStep({
    required LatLng currentLocation,
    required List<NavigationStep> steps,
    required int lastStepIndex,
  }) {
    // Validar entrada
    if (steps.isEmpty) return 0;
    if (lastStepIndex >= steps.length) return steps.length - 1;
    if (lastStepIndex < 0) return 0;

    // Empezar desde el último paso conocido
    for (int i = lastStepIndex; i < steps.length; i++) {
      final step = steps[i];

      // Calcular distancia al final del paso
      final distanceToEnd = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        step.endLocation.latitude,
        step.endLocation.longitude,
      );

      // Si está cerca del final del paso
      if (distanceToEnd < PROXIMITY_THRESHOLD_METERS) {
        // Si hay siguiente paso, verificar si está más cerca del inicio del siguiente
        if (i + 1 < steps.length) {
          final nextStep = steps[i + 1];
          final distanceToNextStart = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            nextStep.startLocation.latitude,
            nextStep.startLocation.longitude,
          );

          // Si está más cerca del siguiente paso, avanzar
          if (distanceToNextStart < distanceToEnd) {
            return i + 1;
          }
        }

        // Si es el último paso y está cerca del fin, mantener
        return i;
      }

      // Verificar si está en la polyline de este paso
      if (_isOnPolyline(currentLocation, step.polylinePoints)) {
        return i;
      }
    }

    // Si no se encontró cambio, mantener paso actual
    return lastStepIndex;
  }

  /// Calcula la distancia al final del paso actual
  ///
  /// [currentLocation] - Ubicación actual
  /// [currentStep] - Paso actual
  ///
  /// Retorna:
  /// - Distancia en metros
  double calculateDistanceToStepEnd({
    required LatLng currentLocation,
    required NavigationStep currentStep,
  }) {
    return Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );
  }

  /// Verifica si el usuario está cerca del siguiente giro
  ///
  /// [currentLocation] - Ubicación actual
  /// [nextStep] - Siguiente paso
  /// [threshold] - Umbral de distancia (default: NEXT_TURN_ALERT_METERS)
  ///
  /// Retorna:
  /// - true si está cerca del siguiente giro
  bool isNearNextTurn({
    required LatLng currentLocation,
    required NavigationStep nextStep,
    double threshold = NEXT_TURN_ALERT_METERS,
  }) {
    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      nextStep.startLocation.latitude,
      nextStep.startLocation.longitude,
    );

    return distance <= threshold;
  }

  /// Detecta si el usuario se desvió de la ruta
  ///
  /// [currentLocation] - Ubicación actual
  /// [currentStep] - Paso actual
  ///
  /// Retorna:
  /// - true si se desvió de la ruta
  bool isOffRoute({
    required LatLng currentLocation,
    required NavigationStep currentStep,
  }) {
    return !_isOnPolyline(
      currentLocation,
      currentStep.polylinePoints,
      threshold: OFF_ROUTE_THRESHOLD_METERS,
    );
  }

  /// Calcula ETA dinámico basado en velocidad actual
  ///
  /// [remainingDistanceMeters] - Distancia restante
  /// [currentSpeedKmh] - Velocidad actual en km/h
  /// [remainingDurationSeconds] - Duración estimada original
  ///
  /// Retorna:
  /// - DateTime con la hora estimada de llegada
  DateTime calculateETA({
    required double remainingDistanceMeters,
    required double currentSpeedKmh,
    required int remainingDurationSeconds,
  }) {
    // Si la velocidad es muy baja o cero, usar duración estimada original
    if (currentSpeedKmh < MIN_SPEED_FOR_ETA_KMH) {
      return DateTime.now().add(Duration(seconds: remainingDurationSeconds));
    }

    // Calcular tiempo basado en velocidad actual
    final speedMps = currentSpeedKmh / 3.6; // km/h a m/s
    final timeSeconds = remainingDistanceMeters / speedMps;

    // Aplicar factor de corrección (tráfico, semáforos, etc.)
    final adjustedTimeSeconds = (timeSeconds * ETA_CORRECTION_FACTOR).toInt();

    // Promediar con duración estimada para suavizar
    final finalTimeSeconds = (adjustedTimeSeconds + remainingDurationSeconds) ~/ 2;

    return DateTime.now().add(Duration(seconds: finalTimeSeconds));
  }

  /// Calcula la distancia restante total
  ///
  /// [currentLocation] - Ubicación actual
  /// [steps] - Lista de pasos
  /// [currentStepIndex] - Índice del paso actual
  ///
  /// Retorna:
  /// - Distancia restante en metros
  double calculateRemainingDistance({
    required LatLng currentLocation,
    required List<NavigationStep> steps,
    required int currentStepIndex,
  }) {
    double total = 0.0;

    // Validar entrada
    if (steps.isEmpty || currentStepIndex >= steps.length) {
      return 0.0;
    }

    // Distancia al final del paso actual
    final currentStep = steps[currentStepIndex];
    total += calculateDistanceToStepEnd(
      currentLocation: currentLocation,
      currentStep: currentStep,
    );

    // Sumar distancias de pasos restantes
    for (int i = currentStepIndex + 1; i < steps.length; i++) {
      total += steps[i].distanceMeters;
    }

    return total;
  }

  /// Calcula la duración restante total
  ///
  /// [steps] - Lista de pasos
  /// [currentStepIndex] - Índice del paso actual
  ///
  /// Retorna:
  /// - Duración restante en segundos
  int calculateRemainingDuration({
    required List<NavigationStep> steps,
    required int currentStepIndex,
  }) {
    int total = 0;

    // Validar entrada
    if (steps.isEmpty || currentStepIndex >= steps.length) {
      return 0;
    }

    // Sumar duraciones desde el paso actual
    for (int i = currentStepIndex; i < steps.length; i++) {
      total += steps[i].durationSeconds;
    }

    return total;
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Verifica si un punto está en una polyline
  ///
  /// [point] - Punto a verificar
  /// [polyline] - Lista de puntos de la polyline
  /// [threshold] - Umbral de distancia (default: OFF_ROUTE_THRESHOLD_METERS)
  ///
  /// Retorna:
  /// - true si el punto está en la polyline
  bool _isOnPolyline(
    LatLng point,
    List<LatLng> polyline, {
    double threshold = OFF_ROUTE_THRESHOLD_METERS,
  }) {
    if (polyline.length < 2) return false;

    // Verificar cada segmento de la polyline
    for (int i = 0; i < polyline.length - 1; i++) {
      final distance = _distanceToLineSegment(
        point,
        polyline[i],
        polyline[i + 1],
      );

      if (distance < threshold) {
        return true;
      }
    }

    return false;
  }

  /// Calcula la distancia de un punto a un segmento de línea
  ///
  /// Implementación del algoritmo de proyección perpendicular
  ///
  /// [point] - Punto a medir
  /// [lineStart] - Inicio del segmento
  /// [lineEnd] - Fin del segmento
  ///
  /// Retorna:
  /// - Distancia mínima en metros
  double _distanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    // Convertir LatLng a coordenadas cartesianas (simplificado)
    final px = point.latitude;
    final py = point.longitude;
    final x1 = lineStart.latitude;
    final y1 = lineStart.longitude;
    final x2 = lineEnd.latitude;
    final y2 = lineEnd.longitude;

    // Calcular longitud del segmento al cuadrado
    final segmentLengthSq = pow(x2 - x1, 2) + pow(y2 - y1, 2);

    // Si el segmento es un punto, retornar distancia al punto
    if (segmentLengthSq == 0) {
      return Geolocator.distanceBetween(px, py, x1, y1);
    }

    // Calcular parámetro t de la proyección
    var t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / segmentLengthSq;
    t = max(0, min(1, t)); // Clamp to [0, 1]

    // Punto proyectado en el segmento
    final projectedLat = x1 + t * (x2 - x1);
    final projectedLng = y1 + t * (y2 - y1);

    // Distancia desde el punto al punto proyectado
    return Geolocator.distanceBetween(px, py, projectedLat, projectedLng);
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Calcula la distancia entre dos puntos
  ///
  /// [lat1] - Latitud del punto 1
  /// [lng1] - Longitud del punto 1
  /// [lat2] - Latitud del punto 2
  /// [lng2] - Longitud del punto 2
  ///
  /// Retorna:
  /// - Distancia en metros
  double calcularDistancia({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calcula el bearing (dirección) entre dos puntos
  ///
  /// [from] - Punto de origen
  /// [to] - Punto de destino
  ///
  /// Retorna:
  /// - Bearing en grados (0-360)
  double calculateBearing({
    required LatLng from,
    required LatLng to,
  }) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}
