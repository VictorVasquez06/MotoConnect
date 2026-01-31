import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Servicio para manejar almacenamiento local seguro y no seguro
/// 
/// Proporciona métodos para:
/// - Almacenamiento simple con SharedPreferences
/// - Almacenamiento seguro con FlutterSecureStorage (para tokens, contraseñas, etc.)
/// - Serialización/deserialización de objetos complejos
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  StorageService._();

  /// Obtiene la instancia singleton del servicio
  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==================== SharedPreferences (Datos no sensibles) ====================

  /// Guarda un valor String
  Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }

  /// Obtiene un valor String
  String? getString(String key, {String? defaultValue}) {
    return _prefs!.getString(key) ?? defaultValue;
  }

  /// Guarda un valor int
  Future<bool> setInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }

  /// Obtiene un valor int
  int? getInt(String key, {int? defaultValue}) {
    return _prefs!.getInt(key) ?? defaultValue;
  }

  /// Guarda un valor double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs!.setDouble(key, value);
  }

  /// Obtiene un valor double
  double? getDouble(String key, {double? defaultValue}) {
    return _prefs!.getDouble(key) ?? defaultValue;
  }

  /// Guarda un valor bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }

  /// Obtiene un valor bool
  bool? getBool(String key, {bool? defaultValue}) {
    return _prefs!.getBool(key) ?? defaultValue;
  }

  /// Guarda una lista de Strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }

  /// Obtiene una lista de Strings
  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }

  /// Guarda un objeto como JSON
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    return await _prefs!.setString(key, jsonString);
  }

  /// Obtiene un objeto desde JSON
  Map<String, dynamic>? getObject(String key) {
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Guarda una lista de objetos como JSON
  Future<bool> setObjectList(String key, List<Map<String, dynamic>> value) async {
    final jsonString = json.encode(value);
    return await _prefs!.setString(key, jsonString);
  }

  /// Obtiene una lista de objetos desde JSON
  List<Map<String, dynamic>>? getObjectList(String key) {
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return null;
    }
  }

  /// Elimina un valor específico
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }

  /// Verifica si existe una clave
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }

  /// Limpia todos los datos de SharedPreferences
  Future<bool> clear() async {
    return await _prefs!.clear();
  }

  /// Obtiene todas las claves almacenadas
  Set<String> getKeys() {
    return _prefs!.getKeys();
  }

  // ==================== Secure Storage (Datos sensibles) ====================

  /// Guarda un valor de forma segura (para tokens, contraseñas, etc.)
  Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Obtiene un valor seguro
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Guarda un objeto JSON de forma segura
  Future<void> setSecureObject(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    await _secureStorage.write(key: key, value: jsonString);
  }

  /// Obtiene un objeto JSON seguro
  Future<Map<String, dynamic>?> getSecureObject(String key) async {
    final jsonString = await _secureStorage.read(key: key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Elimina un valor seguro
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Verifica si existe una clave segura
  Future<bool> containsSecureKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }

  /// Limpia todos los datos seguros
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  /// Obtiene todas las claves seguras
  Future<Map<String, String>> getAllSecure() async {
    return await _secureStorage.readAll();
  }

  // ==================== Métodos de utilidad ====================

  /// Limpia todo el almacenamiento (SharedPreferences y SecureStorage)
  Future<void> clearAll() async {
    await clear();
    await clearSecure();
  }

  /// Exporta todos los datos no seguros para backup
  Map<String, dynamic> exportData() {
    final Map<String, dynamic> data = {};
    final keys = getKeys();
    for (final key in keys) {
      final value = _prefs!.get(key);
      data[key] = value;
    }
    return data;
  }

  /// Imprime estadísticas de almacenamiento (para debug)
  void printStats() {
    getKeys();
    // Debug: Storage Statistics
    // Total keys and key names
  }
}

// ==================== Constantes para claves comunes ====================

/// Clase con constantes para las claves de almacenamiento
/// Esto ayuda a evitar errores de escritura y facilita el mantenimiento
class StorageKeys {
  // Autenticación
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';
  
  // Preferencias de usuario
  static const String theme = 'theme';
  static const String language = 'language';
  static const String notifications = 'notifications_enabled';
  
  // Onboarding
  static const String isFirstLaunch = 'is_first_launch';
  static const String onboardingCompleted = 'onboarding_completed';
  
  // Cache
  static const String lastSyncTime = 'last_sync_time';
  static const String cacheVersion = 'cache_version';
  
  // Datos de usuario
  static const String userProfile = 'user_profile';
  static const String userPreferences = 'user_preferences';
}
