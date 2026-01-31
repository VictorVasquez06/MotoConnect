/// Repository de Navegación
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de navegación
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - CRUD de sesiones de navegación
/// - Actualizar progreso en tiempo real
/// - Compartir navegación en grupos
/// - Streams de progreso grupal
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/repositories/i_navigation_repository.dart';
import '../models/navigation_session.dart';
import '../models/navigation_progress.dart';
import '../models/navigation_step.dart';

class NavigationRepository implements INavigationRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  NavigationRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  // ========================================
  // MÉTODOS DE SESIONES DE NAVEGACIÓN
  // ========================================

  /// Crea una nueva sesión de navegación
  ///
  /// [origin] - Ubicación de origen
  /// [destination] - Ubicación de destino
  /// [destinationName] - Nombre del destino (opcional)
  /// [sesionGrupalId] - ID de sesión grupal (null si es individual)
  /// [steps] - Pasos de navegación
  /// [completePolyline] - Polyline completa de la ruta
  ///
  /// Retorna:
  /// - NavigationSession creada
  Future<NavigationSession> createNavigationSession({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    String? sesionGrupalId,
    required List<NavigationStep> steps,
    required List<LatLng> completePolyline,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Convertir steps a JSON
      final stepsJson = steps.map((s) => s.toJson()).toList();

      // Convertir polyline a JSON
      final polylineJson = completePolyline
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      // Calcular totales
      final totalDistance = steps.fold<double>(
        0.0,
        (sum, step) => sum + step.distanceMeters,
      );

      final totalDuration = steps.fold<int>(
        0,
        (sum, step) => sum + step.durationSeconds,
      );

      // Insertar en base de datos
      final response = await _supabase
          .from('sesiones_navegacion')
          .insert({
            'usuario_id': userId,
            'sesion_grupal_id': sesionGrupalId,
            'origen_lat': origin.latitude,
            'origen_lng': origin.longitude,
            'destino_lat': destination.latitude,
            'destino_lng': destination.longitude,
            'destino_nombre': destinationName,
            'steps': stepsJson,
            'polyline': polylineJson,
            'distancia_total_metros': totalDistance,
            'duracion_total_segundos': totalDuration,
            'estado': 'navigating',
            'paso_actual': 0,
            'distancia_recorrida_metros': 0,
          })
          .select()
          .single();

      return NavigationSession.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear sesión de navegación: ${e.toString()}');
    }
  }

  /// Obtiene una sesión de navegación por ID
  ///
  /// [sessionId] - ID de la sesión
  ///
  /// Retorna:
  /// - NavigationSession o null si no existe
  Future<NavigationSession?> getNavigationSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('sesiones_navegacion')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (response == null) return null;

      return NavigationSession.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener sesión de navegación: ${e.toString()}');
    }
  }

  /// Obtiene las sesiones de navegación del usuario actual
  ///
  /// [limit] - Número máximo de sesiones a retornar
  ///
  /// Retorna:
  /// - Lista de sesiones de navegación
  Future<List<NavigationSession>> getUserNavigationSessions({
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('sesiones_navegacion')
          .select()
          .eq('usuario_id', userId)
          .order('fecha_inicio', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => NavigationSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener sesiones del usuario: ${e.toString()}');
    }
  }

  /// Actualiza el progreso de una sesión de navegación
  ///
  /// [sessionId] - ID de la sesión
  /// [currentStepIndex] - Índice del paso actual
  /// [distanceTraveled] - Distancia recorrida (opcional)
  ///
  /// Retorna:
  /// - void
  Future<void> updateNavigationSession({
    required String sessionId,
    int? currentStepIndex,
    double? distanceTraveled,
    NavigationStatus? status,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (currentStepIndex != null) {
        updates['paso_actual'] = currentStepIndex;
      }

      if (distanceTraveled != null) {
        updates['distancia_recorrida_metros'] = distanceTraveled;
      }

      if (status != null) {
        updates['estado'] = status.toStringValue();
      }

      if (updates.isEmpty) return;

      await _supabase
          .from('sesiones_navegacion')
          .update(updates)
          .eq('id', sessionId);
    } catch (e) {
      throw Exception(
        'Error al actualizar sesión de navegación: ${e.toString()}',
      );
    }
  }

  /// Pausa una sesión de navegación
  ///
  /// [sessionId] - ID de la sesión
  Future<void> pauseNavigation(String sessionId) async {
    try {
      await _supabase
          .from('sesiones_navegacion')
          .update({'estado': 'paused'})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al pausar navegación: ${e.toString()}');
    }
  }

  /// Reanuda una sesión de navegación
  ///
  /// [sessionId] - ID de la sesión
  Future<void> resumeNavigation(String sessionId) async {
    try {
      await _supabase
          .from('sesiones_navegacion')
          .update({'estado': 'navigating'})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al reanudar navegación: ${e.toString()}');
    }
  }

  /// Finaliza una sesión de navegación
  ///
  /// [sessionId] - ID de la sesión
  /// [status] - Estado final (completed o cancelled)
  Future<void> endNavigation({
    required String sessionId,
    required NavigationStatus status,
  }) async {
    try {
      if (status != NavigationStatus.completed &&
          status != NavigationStatus.cancelled) {
        throw Exception('Estado final debe ser completed o cancelled');
      }

      await _supabase
          .from('sesiones_navegacion')
          .update({
            'estado': status.toStringValue(),
            'fecha_fin': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al finalizar navegación: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS DE PROGRESO EN TIEMPO REAL
  // ========================================

  /// Actualiza el progreso de navegación en tiempo real
  ///
  /// Usado para compartir el progreso en navegación grupal
  ///
  /// [sessionId] - ID de la sesión de navegación
  /// [currentStepIndex] - Índice del paso actual
  /// [currentLocation] - Ubicación actual
  /// [distanceToNextStep] - Distancia al siguiente paso
  /// [etaSeconds] - ETA en segundos
  /// [remainingDistance] - Distancia restante
  Future<void> updateNavigationProgress({
    required String sessionId,
    required int currentStepIndex,
    required LatLng currentLocation,
    double? distanceToNextStep,
    int? etaSeconds,
    double? remainingDistance,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('progreso_navegacion_tiempo_real').upsert({
        'sesion_navegacion_id': sessionId,
        'usuario_id': userId,
        'paso_actual': currentStepIndex,
        'ubicacion_lat': currentLocation.latitude,
        'ubicacion_lng': currentLocation.longitude,
        'distancia_siguiente_paso': distanceToNextStep,
        'eta_segundos': etaSeconds,
        'distancia_restante_metros': remainingDistance,
        'ultima_actualizacion': DateTime.now().toIso8601String(),
      });

      // También actualizar la sesión principal
      await updateNavigationSession(
        sessionId: sessionId,
        currentStepIndex: currentStepIndex,
      );
    } catch (e) {
      throw Exception(
        'Error al actualizar progreso de navegación: ${e.toString()}',
      );
    }
  }

  /// Stream de progreso de navegación grupal
  ///
  /// Suscribirse a este stream para recibir actualizaciones en tiempo real
  /// del progreso de todos los miembros del grupo
  ///
  /// [sesionGrupalId] - ID de la sesión grupal
  ///
  /// Retorna:
  /// - Stream de lista de NavigationProgress
  Stream<List<NavigationProgress>> streamGroupNavigationProgress(
    String sesionGrupalId,
  ) {
    return _supabase
        .from('vista_progreso_navegacion_actual')
        .stream(primaryKey: ['id'])
        .eq('sesion_grupal_id', sesionGrupalId)
        .map((data) {
          return (data as List)
              .map((json) => NavigationProgress.fromJson(json))
              .toList();
        });
  }

  /// Obtiene el progreso actual de un usuario en una sesión
  ///
  /// [sessionId] - ID de la sesión
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - NavigationProgress o null si no existe
  Future<NavigationProgress?> getUserProgress({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('progreso_navegacion_tiempo_real')
          .select()
          .eq('sesion_navegacion_id', sessionId)
          .eq('usuario_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return NavigationProgress.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener progreso del usuario: ${e.toString()}');
    }
  }

  /// Elimina el progreso de un usuario (cuando finaliza navegación)
  ///
  /// [sessionId] - ID de la sesión
  Future<void> deleteUserProgress(String sessionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('progreso_navegacion_tiempo_real')
          .delete()
          .eq('sesion_navegacion_id', sessionId)
          .eq('usuario_id', userId);
    } catch (e) {
      throw Exception('Error al eliminar progreso: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS DE UTILIDAD
  // ========================================

  /// Elimina una sesión de navegación
  ///
  /// [sessionId] - ID de la sesión
  Future<void> deleteNavigationSession(String sessionId) async {
    try {
      await _supabase.from('sesiones_navegacion').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al eliminar sesión: ${e.toString()}');
    }
  }

  /// Verifica si un usuario tiene una navegación activa
  ///
  /// Retorna:
  /// - NavigationSession activa o null
  Future<NavigationSession?> getActiveNavigation() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('sesiones_navegacion')
          .select()
          .eq('usuario_id', userId)
          .eq('estado', 'navigating')
          .order('fecha_inicio', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return NavigationSession.fromJson(response);
    } catch (e) {
      throw Exception('Error al verificar navegación activa: ${e.toString()}');
    }
  }
}
