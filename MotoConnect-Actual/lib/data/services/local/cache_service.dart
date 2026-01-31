import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar caché de datos en memoria y persistente
///
/// Características:
/// - Cache en memoria para acceso rápido
/// - Cache persistente con SharedPreferences
/// - Expiración de cache configurable
/// - Estrategias de invalidación
/// - Gestión de tamaño de cache
class CacheService {
  static CacheService? _instance;
  static SharedPreferences? _prefs;

  // Cache en memoria
  final Map<String, _CacheEntry> _memoryCache = {};

  // Configuración
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_ts_';
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const int _maxMemoryCacheSize =
      100; // Máximo número de entradas en memoria

  CacheService._();

  /// Obtiene la instancia singleton del servicio
  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==================== Cache en Memoria ====================

  /// Guarda datos en cache de memoria
  void setMemory<T>(String key, T data, {Duration? expiration}) {
    // Si se alcanza el límite, eliminar la entrada más antigua
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _removeOldestMemoryEntry();
    }

    _memoryCache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiration: expiration ?? _defaultExpiration,
    );
  }

  /// Obtiene datos del cache de memoria
  T? getMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // Verificar si expiró
    if (_isExpired(entry.timestamp, entry.expiration)) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Elimina una entrada del cache de memoria
  void removeMemory(String key) {
    _memoryCache.remove(key);
  }

  /// Limpia todo el cache de memoria
  void clearMemory() {
    _memoryCache.clear();
  }

  /// Obtiene el tamaño del cache en memoria
  int getMemorySize() {
    return _memoryCache.length;
  }

  // ==================== Cache Persistente ====================

  /// Guarda datos en cache persistente
  Future<bool> set<T>(
    String key,
    T data, {
    Duration? expiration,
    bool alsoInMemory = true,
  }) async {
    try {
      final cacheKey = _cachePrefix + key;
      final timestampKey = _cacheTimestampPrefix + key;

      // Serializar datos
      String jsonString;
      if (data is String) {
        jsonString = data;
      } else if (data is Map || data is List) {
        jsonString = json.encode(data);
      } else {
        jsonString = data.toString();
      }

      // Guardar en SharedPreferences
      await _prefs!.setString(cacheKey, jsonString);
      await _prefs!.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      // También guardar en memoria si se solicita
      if (alsoInMemory) {
        setMemory(key, data, expiration: expiration);
      }

      return true;
    } catch (e) {
      // Error saving to cache
      return false;
    }
  }

  /// Obtiene datos del cache persistente
  Future<T?> get<T>(
    String key, {
    Duration? expiration,
    bool checkMemoryFirst = true,
  }) async {
    // Primero verificar en memoria
    if (checkMemoryFirst) {
      final memoryData = getMemory<T>(key);
      if (memoryData != null) {
        return memoryData;
      }
    }

    try {
      final cacheKey = _cachePrefix + key;
      final timestampKey = _cacheTimestampPrefix + key;

      // Obtener timestamp
      final timestamp = _prefs!.getInt(timestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expirationDuration = expiration ?? _defaultExpiration;

      // Verificar si expiró
      if (_isExpired(cacheTime, expirationDuration)) {
        await remove(key);
        return null;
      }

      // Obtener datos
      final jsonString = _prefs!.getString(cacheKey);
      if (jsonString == null) return null;

      // Deserializar según el tipo
      if (T == String) {
        return jsonString as T;
      }
      // Para otros tipos, intentar decodificar JSON
      try {
        final decoded = json.decode(jsonString);
        return decoded as T;
      } catch (_) {
        // Si falla la decodificación, devolver el string como está
        return jsonString as T;
      }
    } catch (e) {
      // Error getting from cache
      return null;
    }
  }

  /// Elimina una entrada del cache persistente
  Future<bool> remove(String key) async {
    final cacheKey = _cachePrefix + key;
    final timestampKey = _cacheTimestampPrefix + key;

    // Eliminar de memoria también
    removeMemory(key);

    // Eliminar de persistencia
    await _prefs!.remove(cacheKey);
    await _prefs!.remove(timestampKey);

    return true;
  }

  /// Limpia todo el cache persistente
  Future<void> clear() async {
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) ||
          key.startsWith(_cacheTimestampPrefix)) {
        await _prefs!.remove(key);
      }
    }
    clearMemory();
  }

  // ==================== Métodos de Utilidad ====================

  /// Verifica si una entrada de cache existe y es válida
  Future<bool> has(String key, {Duration? expiration}) async {
    final data = await get(key, expiration: expiration);
    return data != null;
  }

  /// Obtiene o carga datos (patrón cache-aside)
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() loader, {
    Duration? expiration,
    bool forceRefresh = false,
  }) async {
    // Si se fuerza refresh, ir directo al loader
    if (!forceRefresh) {
      final cached = await get<T>(key, expiration: expiration);
      if (cached != null) {
        return cached;
      }
    }

    // Cargar datos frescos
    final data = await loader();
    await set(key, data, expiration: expiration);
    return data;
  }

  /// Invalida cache que coincida con un patrón
  Future<void> invalidatePattern(String pattern) async {
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final originalKey = key.substring(_cachePrefix.length);
        if (originalKey.contains(pattern)) {
          await remove(originalKey);
        }
      }
    }
  }

  /// Obtiene la edad de una entrada de cache
  Future<Duration?> getCacheAge(String key) async {
    final timestampKey = _cacheTimestampPrefix + key;
    final timestamp = _prefs!.getInt(timestampKey);

    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime);
  }

  /// Verifica si una entrada de cache ha expirado
  Future<bool> isExpired(String key, {Duration? expiration}) async {
    final age = await getCacheAge(key);
    if (age == null) return true;

    final expirationDuration = expiration ?? _defaultExpiration;
    return age > expirationDuration;
  }

  /// Limpia entradas expiradas
  Future<void> clearExpired() async {
    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix));

    for (final cacheKey in cacheKeys) {
      final originalKey = cacheKey.substring(_cachePrefix.length);
      final expired = await isExpired(originalKey);
      if (expired) {
        await remove(originalKey);
      }
    }
  }

  /// Obtiene estadísticas del cache
  Future<CacheStats> getStats() async {
    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();

    int validCount = 0;
    int expiredCount = 0;

    for (final cacheKey in cacheKeys) {
      final originalKey = cacheKey.substring(_cachePrefix.length);
      final expired = await isExpired(originalKey);
      if (expired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return CacheStats(
      totalEntries: cacheKeys.length,
      validEntries: validCount,
      expiredEntries: expiredCount,
      memoryEntries: _memoryCache.length,
    );
  }

  /// Imprime información del cache (para debug)
  Future<void> printStats() async {
    await getStats();
    // Debug: Cache Statistics
    // Total entries, valid entries, expired entries, memory entries
  }

  // ==================== Métodos Privados ====================

  /// Verifica si un timestamp ha expirado
  bool _isExpired(DateTime timestamp, Duration expiration) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference > expiration;
  }

  /// Elimina la entrada más antigua del cache en memoria
  void _removeOldestMemoryEntry() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.timestamp;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
    }
  }
}

// ==================== Clases de Soporte ====================

/// Entrada de cache en memoria
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
  });
}

/// Estadísticas del cache
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int memoryEntries;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.memoryEntries,
  });

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, '
        'expired: $expiredEntries, memory: $memoryEntries)';
  }
}

// ==================== Constantes para claves de cache ====================

/// Clase con constantes para las claves de cache comunes
class CacheKeys {
  // API responses
  static const String userList = 'user_list';
  static const String userDetail = 'user_detail_';
  static const String posts = 'posts';
  static const String comments = 'comments_';

  // Configuración
  static const String appConfig = 'app_config';
  static const String featureFlags = 'feature_flags';

  // Datos temporales
  static const String searchResults = 'search_results_';
  static const String recentSearches = 'recent_searches';

  // Imágenes y media
  static const String imageCache = 'image_';
  static const String thumbnails = 'thumb_';
}

/// Duraciones de expiración predefinidas
class CacheExpiration {
  static const Duration short = Duration(minutes: 5);
  static const Duration medium = Duration(hours: 1);
  static const Duration long = Duration(hours: 24);
  static const Duration veryLong = Duration(days: 7);
  static const Duration permanent = Duration(days: 365);
}
