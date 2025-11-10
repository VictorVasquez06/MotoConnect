// ============================================================================
// ARCHIVO 4: lib/core/constants/app_constants.dart
// ============================================================================

/// Constantes generales de la aplicación
///
/// Valores constantes usados en toda la app
library;

class AppConstants {
  AppConstants._();

  // ========================================
  // INFORMACIÓN DE LA APP
  // ========================================

  /// Nombre de la aplicación
  static const String appName = 'MotoConnect';

  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  /// Email de soporte
  static const String supportEmail = 'soporte@motoconnect.com';

  // ========================================
  // VALIDACIONES
  // ========================================

  /// Longitud mínima de contraseña
  static const int minPasswordLength = 8;

  /// Longitud máxima de nombre
  static const int maxNameLength = 50;

  /// Longitud máxima de descripción
  static const int maxDescriptionLength = 500;

  // ========================================
  // MAPAS
  // ========================================

  /// Latitud por defecto (Bucaramanga)
  static const double defaultLatitude = 7.116816;

  /// Longitud por defecto (Bucaramanga)
  static const double defaultLongitude = -73.105240;

  /// Nivel de zoom inicial del mapa
  static const double defaultMapZoom = 14.0;

  // ========================================
  // PAGINACIÓN
  // ========================================

  /// Número de items por página
  static const int itemsPerPage = 20;

  /// Número de eventos a mostrar
  static const int maxEventsToShow = 50;

  // ========================================
  // CACHÉ
  // ========================================

  /// Duración del caché en memoria (en minutos)
  static const int cacheDurationMinutes = 15;
}
