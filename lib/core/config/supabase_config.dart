// ============================================================================
// ARCHIVO 1: lib/core/config/supabase_config.dart
// ============================================================================

/// Configuración centralizada de Supabase
///
/// Este archivo encapsula toda la lógica de inicialización de Supabase,
/// siguiendo el principio de responsabilidad única.
///
/// Ventajas:
/// - Fácil de testear (mock)
/// - Centraliza la configuración
/// - Facilita cambios futuros
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Singleton pattern para asegurar una sola instancia
  static SupabaseClient? _instance;

  /// Obtiene la instancia actual del cliente Supabase
  ///
  /// Lanza una excepción si no ha sido inicializado
  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception(
        'Supabase no ha sido inicializado. '
        'Llama a SupabaseConfig.initialize() primero.',
      );
    }
    return _instance!;
  }

  /// Inicializa Supabase con las credenciales del proyecto
  ///
  /// [url] - URL del proyecto Supabase (https://xxx.supabase.co)
  /// [anonKey] - Clave anónima del proyecto
  ///
  /// Debe llamarse en main() antes de runApp()
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      // Opciones adicionales de configuración
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // Más seguro
      ),
    );

    _instance = Supabase.instance.client;
  }

  /// Verifica si Supabase está inicializado
  static bool get isInitialized => _instance != null;
}
