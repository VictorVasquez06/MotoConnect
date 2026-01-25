/// Servicio de Text-to-Speech para Navegación
///
/// Proporciona anuncios de voz durante la navegación:
/// - Instrucciones de navegación
/// - Alertas de proximidad a giros
/// - Anuncios periódicos de progreso
/// - Anuncio de llegada al destino
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NavigationVoiceService {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  late final FlutterTts _flutterTts;

  // ========================================
  // ESTADO
  // ========================================

  /// Indica si actualmente está hablando
  bool _isSpeaking = false;

  /// Índice del último paso anunciado (para evitar repeticiones)
  int? _lastAnnouncedStepIndex;

  /// Última distancia de alerta de proximidad anunciada
  int? _lastProximityAlertDistance;

  /// Indica si el servicio está inicializado
  bool _isInitialized = false;

  // ========================================
  // GETTERS
  // ========================================

  /// Indica si está hablando
  bool get isSpeaking => _isSpeaking;

  /// Indica si está inicializado
  bool get isInitialized => _isInitialized;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el servicio de TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Configurar idioma español
      await _flutterTts.setLanguage("es-ES");

      // Velocidad moderada para motociclistas
      await _flutterTts.setSpeechRate(0.5);

      // Volumen máximo para que se escuche con casco
      await _flutterTts.setVolume(1.0);

      // Tono normal
      await _flutterTts.setPitch(1.0);

      // Configurar callbacks para trackear estado
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('Error en TTS: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('NavigationVoiceService inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar TTS: $e');
      _isInitialized = false;
    }
  }

  /// Anuncia una instrucción de navegación
  ///
  /// [instruction] - Texto de la instrucción (puede contener HTML)
  /// [distanceText] - Distancia formateada (ej: "200 m", "1.5 km")
  /// [stepIndex] - Índice del paso (opcional, para evitar repeticiones)
  Future<void> announceInstruction(
    String instruction,
    String distanceText, {
    int? stepIndex,
  }) async {
    if (!_isInitialized) {
      debugPrint('TTS no inicializado, no se puede anunciar instrucción');
      return;
    }

    // Evitar anunciar el mismo paso dos veces
    if (stepIndex != null && stepIndex == _lastAnnouncedStepIndex) {
      return;
    }

    // Limpiar HTML de la instrucción
    final cleanInstruction = _cleanHtmlTags(instruction);

    // Construir mensaje
    final message = 'En $distanceText, $cleanInstruction';

    // Anunciar
    await _speak(message);

    // Actualizar último paso anunciado
    if (stepIndex != null) {
      _lastAnnouncedStepIndex = stepIndex;
    }

    debugPrint('Anunciado: $message');
  }

  /// Anuncia una alerta de proximidad a un giro
  ///
  /// [instruction] - Texto de la instrucción
  /// [distanceMeters] - Distancia en metros al giro
  Future<void> announceProximityAlert(
    String instruction,
    int distanceMeters,
  ) async {
    if (!_isInitialized) return;

    // Evitar repetir la misma alerta
    if (_lastProximityAlertDistance == distanceMeters) {
      return;
    }

    // Limpiar HTML
    final cleanInstruction = _cleanHtmlTags(instruction);

    // Construir mensaje
    String message;
    if (distanceMeters <= 100) {
      message = 'Prepárate para $cleanInstruction';
    } else {
      message = 'En $distanceMeters metros, $cleanInstruction';
    }

    // Anunciar
    await _speak(message);

    // Actualizar última alerta
    _lastProximityAlertDistance = distanceMeters;

    debugPrint('Alerta de proximidad: $message');
  }

  /// Anuncia el progreso de la navegación
  ///
  /// [remainingDistance] - Distancia restante formateada
  /// [remainingTime] - Tiempo restante formateado
  Future<void> announceProgress(
    String remainingDistance,
    String remainingTime,
  ) async {
    if (!_isInitialized) return;

    final message =
        'Tiempo restante: $remainingTime. Distancia: $remainingDistance';

    await _speak(message);

    debugPrint('Progreso anunciado: $message');
  }

  /// Anuncia la llegada al destino
  Future<void> announceArrival() async {
    if (!_isInitialized) return;

    const message = 'Has llegado a tu destino';

    await _speak(message);

    debugPrint('Llegada anunciada');
  }

  /// Detiene el TTS inmediatamente
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error al detener TTS: $e');
    }
  }

  /// Limpia recursos
  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
      _isInitialized = false;
      _isSpeaking = false;
      _lastAnnouncedStepIndex = null;
      _lastProximityAlertDistance = null;
      debugPrint('NavigationVoiceService disposed');
    }
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Habla un mensaje usando TTS
  Future<void> _speak(String message) async {
    if (!_isInitialized) return;

    try {
      // Si ya está hablando, esperar un poco y reintentar
      if (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_isSpeaking) {
          // Si todavía está hablando, encolar para después
          debugPrint('TTS ocupado, mensaje encolado: $message');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Hablar
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint('Error al hablar: $e');
      _isSpeaking = false;
    }
  }

  /// Limpia tags HTML de un texto
  ///
  /// Google Directions API devuelve instrucciones con HTML
  /// Ejemplo: "Gira a la <b>derecha</b>" → "Gira a la derecha"
  String _cleanHtmlTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remover tags HTML
        .replaceAll('&nbsp;', ' ') // Remover espacios no separables
        .replaceAll('&amp;', 'y') // Remover ampersands
        .replaceAll('&lt;', '<') // Remover <
        .replaceAll('&gt;', '>') // Remover >
        .trim();
  }

  // ========================================
  // CONFIGURACIÓN AVANZADA (OPCIONAL)
  // ========================================

  /// Cambia el idioma del TTS
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.setLanguage(language);
      debugPrint('Idioma cambiado a: $language');
    } catch (e) {
      debugPrint('Error al cambiar idioma: $e');
    }
  }

  /// Cambia la velocidad del habla
  ///
  /// [rate] - Velocidad (0.0 - 1.0)
  /// 0.5 = normal, 0.0 = muy lento, 1.0 = muy rápido
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
      debugPrint('Velocidad de habla cambiada a: $rate');
    } catch (e) {
      debugPrint('Error al cambiar velocidad: $e');
    }
  }

  /// Cambia el volumen
  ///
  /// [volume] - Volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('Volumen cambiado a: $volume');
    } catch (e) {
      debugPrint('Error al cambiar volumen: $e');
    }
  }

  /// Reinicia los contadores de anuncios
  ///
  /// Útil cuando se recalcula la ruta
  void resetAnnouncementTracking() {
    _lastAnnouncedStepIndex = null;
    _lastProximityAlertDistance = null;
    debugPrint('Tracking de anuncios reiniciado');
  }
}
