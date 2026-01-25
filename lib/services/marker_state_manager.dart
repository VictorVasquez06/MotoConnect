import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/map_colors.dart';

/// Estados posibles de un marcador
enum MarkerState {
  pending,  // Esperando carga
  loading,  // Cargando foto
  ready,    // Listo en cache
  failed,   // Falló, usando fallback
  stale,    // Cache expirado, necesita refresh
}

/// Metadata de un marcador con información de estado y cache
class MarkerMetadata {
  final String userId;
  final MarkerState state;
  final BitmapDescriptor? icon;
  final DateTime? cachedAt;
  final int retryCount;
  final String? photoUrl;
  final Duration ttl;

  MarkerMetadata({
    required this.userId,
    required this.state,
    this.icon,
    this.cachedAt,
    required this.retryCount,
    this.photoUrl,
    required this.ttl,
  });

  /// Verifica si el cache ha expirado
  bool get isExpired =>
      cachedAt != null && DateTime.now().difference(cachedAt!) > ttl;

  /// Verifica si se debe reintentar
  bool get shouldRetry => retryCount < 3 && state == MarkerState.failed;

  /// Crea una copia con campos modificados
  MarkerMetadata copyWith({
    String? userId,
    MarkerState? state,
    BitmapDescriptor? icon,
    DateTime? cachedAt,
    int? retryCount,
    String? photoUrl,
    Duration? ttl,
  }) {
    return MarkerMetadata(
      userId: userId ?? this.userId,
      state: state ?? this.state,
      icon: icon ?? this.icon,
      cachedAt: cachedAt ?? this.cachedAt,
      retryCount: retryCount ?? this.retryCount,
      photoUrl: photoUrl ?? this.photoUrl,
      ttl: ttl ?? this.ttl,
    );
  }
}

/// Tarea de retry en la cola de prioridad
class MarkerRetryTask implements Comparable<MarkerRetryTask> {
  final String cacheKey;
  final String userId;
  final String? photoUrl;
  final String displayName;
  final int colorMap;
  final bool isPaused;
  final int priority;
  final DateTime scheduledFor;

  MarkerRetryTask({
    required this.cacheKey,
    required this.userId,
    required this.photoUrl,
    required this.displayName,
    required this.colorMap,
    required this.isPaused,
    required this.priority,
    required this.scheduledFor,
  });

  @override
  int compareTo(MarkerRetryTask other) {
    // Mayor prioridad primero (menos intentos = mayor prioridad)
    final priorityCompare = other.priority.compareTo(priority);
    if (priorityCompare != 0) return priorityCompare;

    // Si tienen misma prioridad, el más antiguo primero
    return scheduledFor.compareTo(other.scheduledFor);
  }
}

/// Gestor de estados de marcadores con retry automático y cache TTL
///
/// Este gestor maneja el ciclo de vida completo de los marcadores:
/// - Cache con TTL de 24 horas
/// - Retry automático con exponential backoff
/// - Invalidación manual cuando cambian fotos
/// - Eviction periódica de marcadores expirados
class MarkerStateManager {
  // Cache con metadata
  final Map<String, MarkerMetadata> _markerMetadata = {};

  // Cola de retry (priority queue: menos intentos = mayor prioridad)
  final _retryQueue = PriorityQueue<MarkerRetryTask>();

  // Timer para procesamiento de retry en background
  Timer? _retryTimer;

  // Configuración
  static const Duration cacheTTL = Duration(hours: 24);
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(seconds: 2);

  // Estadísticas (para debugging)
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRetries = 0;

  /// Obtener o crear marcador con retry automático
  ///
  /// Este es el método principal que debe usarse para obtener marcadores.
  /// Maneja cache, invalidación, y retry automático de forma transparente.
  Future<BitmapDescriptor> getOrCreateMarker({
    required String userId,
    required String? photoUrl,
    required String displayName,
    required int colorMap,
    required bool isPaused,
  }) async {
    final cacheKey = '${userId}_${isPaused ? 'paused' : 'active'}';
    final metadata = _markerMetadata[cacheKey];

    // Cache hit válido
    if (metadata?.state == MarkerState.ready &&
        metadata?.photoUrl == photoUrl &&
        !metadata!.isExpired) {
      _cacheHits++;
      debugPrint('💾 Cache hit ($_cacheHits hits, $_cacheMisses misses): $displayName');
      return metadata.icon!;
    }

    _cacheMisses++;

    // URL cambió o cache expiró: invalidar y recargar
    if (metadata != null &&
        (metadata.photoUrl != photoUrl || metadata.isExpired)) {
      debugPrint('🔄 Invalidando cache obsoleto: $displayName (${metadata.isExpired ? 'expirado' : 'URL cambió'})');
      _markerMetadata.remove(cacheKey);
    }

    // Crear nuevo marcador
    return await _createMarker(
      userId: userId,
      photoUrl: photoUrl,
      displayName: displayName,
      colorMap: colorMap,
      isPaused: isPaused,
      cacheKey: cacheKey,
    );
  }

  /// Crea un marcador y lo cachea
  Future<BitmapDescriptor> _createMarker({
    required String userId,
    required String? photoUrl,
    required String displayName,
    required int colorMap,
    required bool isPaused,
    required String cacheKey,
  }) async {
    // Marcar como loading
    _markerMetadata[cacheKey] = MarkerMetadata(
      userId: userId,
      state: MarkerState.loading,
      photoUrl: photoUrl,
      retryCount: 0,
      ttl: cacheTTL,
    );

    try {
      final icon = await _buildMarkerIcon(
        photoUrl: photoUrl,
        displayName: displayName,
        colorMap: colorMap,
        isPaused: isPaused,
      );

      // Éxito: cachear con timestamp
      _markerMetadata[cacheKey] = MarkerMetadata(
        userId: userId,
        state: MarkerState.ready,
        icon: icon,
        photoUrl: photoUrl,
        cachedAt: DateTime.now(),
        retryCount: 0,
        ttl: cacheTTL,
      );

      debugPrint('✅ Marcador creado y cacheado: $displayName');
      return icon;
    } catch (e) {
      debugPrint('❌ Error creando marcador: $displayName - $e');

      // Encolar retry con exponential backoff
      _enqueueRetry(cacheKey, userId, photoUrl, displayName, colorMap, isPaused);

      // Retornar fallback inmediatamente (color)
      return _createFallbackMarker(colorMap);
    }
  }

  /// Encola un retry con exponential backoff
  void _enqueueRetry(
    String cacheKey,
    String userId,
    String? photoUrl,
    String displayName,
    int colorMap,
    bool isPaused,
  ) {
    final metadata = _markerMetadata[cacheKey];
    if (metadata == null || metadata.retryCount >= maxRetries) {
      debugPrint('🚫 Max retries alcanzado para: $displayName');
      return;
    }

    final retryCount = metadata.retryCount + 1;
    // Exponential backoff: 2s, 4s, 8s
    final delayMultiplier = pow(2, retryCount - 1).toInt();
    final delay = retryBaseDelay * delayMultiplier;
    _totalRetries++;

    _retryQueue.add(MarkerRetryTask(
      cacheKey: cacheKey,
      userId: userId,
      photoUrl: photoUrl,
      displayName: displayName,
      colorMap: colorMap,
      isPaused: isPaused,
      priority: maxRetries - retryCount, // Menos intentos = mayor prioridad
      scheduledFor: DateTime.now().add(delay),
    ));

    _markerMetadata[cacheKey] = metadata.copyWith(
      state: MarkerState.failed,
      retryCount: retryCount,
    );

    debugPrint('🔁 Retry encolado ($retryCount/$maxRetries) para: $displayName en ${delay.inSeconds}s');

    _scheduleRetryProcessor();
  }

  /// Inicia el procesador de retry en background
  void _scheduleRetryProcessor() {
    _retryTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _processRetryQueue();
    });
  }

  /// Procesa la cola de retry
  Future<void> _processRetryQueue() async {
    final now = DateTime.now();

    while (_retryQueue.isNotEmpty &&
        _retryQueue.first.scheduledFor.isBefore(now)) {
      final task = _retryQueue.removeFirst();
      final metadata = _markerMetadata[task.cacheKey];

      // Skip si ya está listo o fue eliminado
      if (metadata == null || metadata.state == MarkerState.ready) {
        continue;
      }

      debugPrint('♻️ Procesando retry: ${task.displayName}');

      // Reintentar creación
      await _createMarker(
        userId: task.userId,
        photoUrl: task.photoUrl,
        displayName: task.displayName,
        colorMap: task.colorMap,
        isPaused: task.isPaused,
        cacheKey: task.cacheKey,
      );
    }
  }

  /// Construye el marcador con foto de perfil o iniciales
  Future<BitmapDescriptor> _buildMarkerIcon({
    required String? photoUrl,
    required String displayName,
    required int colorMap,
    required bool isPaused,
  }) async {
    try {
      // Tamaño del marcador optimizado para evitar saturación visual
      const size = 70;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fondo circular con color del usuario (o gris si está pausado)
      final paint = Paint()
        ..color = isPaused
            ? Colors.grey.withValues(alpha: 0.5)
            : MapColors.getColorUI(colorMap);

      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        paint,
      );

      // Borde blanco para resaltar el marcador
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;

      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        borderPaint,
      );

      bool usarIniciales = true;

      // Intentar cargar y dibujar foto de perfil
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          debugPrint('🖼️ Cargando foto para $displayName: $photoUrl');

          // Timeout de 5 segundos para no bloquear
          final response = await http
              .get(Uri.parse(photoUrl))
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('⏱️ Timeout al cargar foto de $displayName');
                  throw TimeoutException('Timeout cargando foto');
                },
              );

          if (response.statusCode == 200) {
            if (response.bodyBytes.isEmpty) {
              debugPrint('⚠️ Foto vacía para $displayName');
              throw Exception('Imagen vacía');
            }

            final bytes = response.bodyBytes;

            // Validar que sea una imagen válida
            final codec = await ui.instantiateImageCodec(
              bytes,
              targetWidth: size - 12,
              targetHeight: size - 12,
            ).timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                debugPrint('⏱️ Timeout decodificando imagen de $displayName');
                throw TimeoutException('Timeout decodificando imagen');
              },
            );

            final frame = await codec.getNextFrame();

            // Clip circular para la imagen
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: const Offset(size / 2, size / 2),
                radius: (size / 2) - 6,
              ));

            canvas.save();
            canvas.clipPath(path);
            canvas.drawImage(
              frame.image,
              const Offset(6, 6),
              Paint(),
            );
            canvas.restore();

            usarIniciales = false;
            debugPrint('✅ Foto cargada exitosamente para $displayName (${bytes.length} bytes)');
          } else if (response.statusCode >= 500) {
            // Error de servidor - vale la pena reintentar
            debugPrint('⚠️ Error servidor ${response.statusCode} para $displayName - se reintentará');
            throw Exception('Server error ${response.statusCode}');
          } else if (response.statusCode == 404) {
            // No encontrado - no vale la pena reintentar
            debugPrint('🚫 Foto no encontrada (404) para $displayName - usando iniciales');
            // No lanzar error, usar iniciales directamente
          } else {
            debugPrint('⚠️ Error HTTP ${response.statusCode} para $displayName');
            throw Exception('HTTP ${response.statusCode}');
          }
        } on TimeoutException catch (e) {
          debugPrint('⏱️ Timeout cargando foto de $displayName: $e');
          // Lanzar para retry
          rethrow;
        } catch (e) {
          debugPrint('❌ Error al cargar foto de $displayName: $e');
          // Lanzar error para que se encole retry
          rethrow;
        }
      } else {
        debugPrint('📝 Sin foto para $displayName, usando iniciales');
      }

      // Si no se pudo cargar la foto, usar iniciales
      if (usarIniciales) {
        _dibujarIniciales(canvas, displayName, size);
      }

      // Convertir canvas a BitmapDescriptor
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Error: byteData es null para $displayName');
        throw Exception('No se pudo convertir imagen a bytes');
      }

      final bytes = byteData.buffer.asUint8List();

      debugPrint('✅ Marcador construido para $displayName (${bytes.length} bytes)');
      return BitmapDescriptor.bytes(bytes);
    } catch (e) {
      debugPrint('❌ Error crítico al construir marcador para $displayName: $e');
      // Lanzar error para que se encole retry
      rethrow;
    }
  }

  /// Dibuja las iniciales del usuario en el canvas
  void _dibujarIniciales(Canvas canvas, String nombre, int size) {
    // Extraer iniciales (máximo 2 letras)
    final iniciales = nombre
        .split(' ')
        .take(2)
        .where((n) => n.isNotEmpty)
        .map((n) => n[0].toUpperCase())
        .join();

    debugPrint('📝 Dibujando iniciales "$iniciales" para $nombre');

    final textPainter = TextPainter(
      text: TextSpan(
        text: iniciales.isEmpty ? '?' : iniciales,
        style: TextStyle(
          color: Colors.white,
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
  }

  /// Crea marcador fallback (color sólido) cuando falla carga de foto
  BitmapDescriptor _createFallbackMarker(int colorMap) {
    return BitmapDescriptor.defaultMarkerWithHue(
      MapColors.hues[colorMap % MapColors.hues.length],
    );
  }

  /// Invalida cache de usuario (cuando cambia foto)
  void invalidateUser(String userId) {
    final removed = _markerMetadata.keys
        .where((key) => _markerMetadata[key]?.userId == userId)
        .toList();

    for (final key in removed) {
      _markerMetadata.remove(key);
    }

    debugPrint('🗑️ Cache invalidado para usuario: $userId (${removed.length} marcadores)');
  }

  /// Limpia cache antiguo (llamar periódicamente)
  int evictStale() {
    final initialSize = _markerMetadata.length;

    _markerMetadata.removeWhere((key, metadata) =>
        metadata.isExpired && metadata.state != MarkerState.loading);

    final removed = initialSize - _markerMetadata.length;

    if (removed > 0) {
      debugPrint('🧹 Limpieza de cache: $removed marcadores expirados removidos');
    }

    return removed;
  }

  /// Obtiene estadísticas del gestor (para debugging)
  Map<String, dynamic> getStats() {
    return {
      'cache_size': _markerMetadata.length,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate': _cacheHits + _cacheMisses > 0
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
          : '0.0',
      'retry_queue_size': _retryQueue.length,
      'total_retries': _totalRetries,
      'states': {
        'ready': _markerMetadata.values
            .where((m) => m.state == MarkerState.ready)
            .length,
        'loading': _markerMetadata.values
            .where((m) => m.state == MarkerState.loading)
            .length,
        'failed': _markerMetadata.values
            .where((m) => m.state == MarkerState.failed)
            .length,
        'stale': _markerMetadata.values.where((m) => m.isExpired).length,
      },
    };
  }

  /// Diagnóstico detallado del estado de los marcadores (para debugging avanzado)
  void printDiagnostics() {
    debugPrint('╔═══════════════════════════════════════════════════╗');
    debugPrint('║      MarkerStateManager - Diagnóstico            ║');
    debugPrint('╠═══════════════════════════════════════════════════╣');

    final stats = getStats();
    debugPrint('║ Cache Size: ${stats['cache_size']}');
    debugPrint('║ Hit Rate: ${stats['hit_rate']}% (${stats['cache_hits']} hits, ${stats['cache_misses']} misses)');
    debugPrint('║ Retry Queue: ${stats['retry_queue_size']} pendientes');
    debugPrint('║ Total Retries: ${stats['total_retries']}');
    debugPrint('╠═══════════════════════════════════════════════════╣');

    final states = stats['states'] as Map<String, dynamic>;
    debugPrint('║ Estados:');
    debugPrint('║   ✅ Ready:   ${states['ready']}');
    debugPrint('║   ⏳ Loading: ${states['loading']}');
    debugPrint('║   ❌ Failed:  ${states['failed']}');
    debugPrint('║   🕐 Stale:   ${states['stale']}');
    debugPrint('╠═══════════════════════════════════════════════════╣');

    if (_markerMetadata.isNotEmpty) {
      debugPrint('║ Detalle de marcadores:');
      var count = 0;
      for (final entry in _markerMetadata.entries) {
        if (count >= 5) {
          debugPrint('║   ... y ${_markerMetadata.length - 5} más');
          break;
        }
        final metadata = entry.value;
        final icon = metadata.state == MarkerState.ready
            ? '✅'
            : metadata.state == MarkerState.loading
                ? '⏳'
                : metadata.state == MarkerState.failed
                    ? '❌'
                    : '🕐';
        final age = metadata.cachedAt != null
            ? DateTime.now().difference(metadata.cachedAt!).inMinutes
            : -1;
        debugPrint(
            '║   $icon ${entry.key}: ${metadata.state.name} ${age >= 0 ? '($age min)' : ''}');
        count++;
      }
    }

    debugPrint('╚═══════════════════════════════════════════════════╝');
  }

  /// Limpia todos los recursos
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _markerMetadata.clear();
    _retryQueue.clear();
    debugPrint('🧹 MarkerStateManager disposed');
  }
}

/// Priority Queue simple para retry tasks
class PriorityQueue<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort();
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  T get first => _items.first;

  bool get isNotEmpty => _items.isNotEmpty;

  bool get isEmpty => _items.isEmpty;

  int get length => _items.length;

  void clear() {
    _items.clear();
  }
}
