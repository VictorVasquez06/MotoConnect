/// Utilidad para manejo de errores
///
/// Proporciona funciones para manejar errores de manera consistente
/// en toda la aplicación
library;

/// Maneja un error genérico y devuelve un mensaje de error formateado
String handleError(dynamic error) {
  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  return error.toString();
}

/// Maneja errores de red
String handleNetworkError(dynamic error) {
  // Lógica específica para errores de red
  return 'Error de conexión: ${handleError(error)}';
}

/// Maneja errores de autenticación
String handleAuthError(dynamic error) {
  // Lógica específica para errores de autenticación
  return 'Error de autenticación: ${handleError(error)}';
}

/// Maneja errores de validación
String handleValidationError(String field, String message) {
  return 'Error en $field: $message';
}

/// Registra un error para debugging (puede ser extendido con logging services)
void logError(dynamic error, [StackTrace? stackTrace]) {
  // Debug: registrar error
  // En producción, esto podría enviar a un servicio de logging
  if (stackTrace != null) {
    // Error con stack trace
  }
}

/// Verifica si un error es de tipo específico
bool isNetworkError(dynamic error) {
  return error.toString().contains('SocketException') ||
      error.toString().contains('TimeoutException') ||
      error.toString().contains('network');
}

/// Verifica si un error es de autenticación
bool isAuthError(dynamic error) {
  return error.toString().contains('auth') ||
      error.toString().contains('unauthorized') ||
      error.toString().contains('forbidden');
}
