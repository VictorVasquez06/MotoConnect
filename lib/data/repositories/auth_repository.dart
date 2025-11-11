/// Repository de Autenticación
///
/// Patrón Repository:
/// - Abstrae la fuente de datos
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones de autenticación (login, registro, logout)
/// - Gestión de sesión
/// - Comunicación con AuthApiService
library;

import '../services/api/auth_api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de autenticación
  final AuthApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de autenticación
  AuthRepository({AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Verifica si hay un usuario autenticado
  ///
  /// Retorna:
  /// - true si hay sesión activa
  /// - false si no hay sesión
  Future<bool> isAuthenticated() async {
    try {
      final user = await _apiService.getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Inicia sesión con email y contraseña
  ///
  /// [email] - Correo electrónico del usuario
  /// [password] - Contraseña del usuario
  ///
  /// Retorna:
  /// - UserModel si el login es exitoso
  ///
  /// Lanza:
  /// - AuthException si las credenciales son inválidas
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _apiService.signIn(email: email, password: password);
    } catch (e) {
      rethrow; // Propaga la excepción al ViewModel
    }
  }

  /// Registra un nuevo usuario
  ///
  /// [email] - Correo electrónico
  /// [password] - Contraseña
  /// [nombre] - Nombre completo del usuario
  ///
  /// Retorna:
  /// - UserModel del usuario creado
  ///
  /// Lanza:
  /// - AuthException si el registro falla
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      return await _apiService.signUp(
        email: email,
        password: password,
        nombre: nombre,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _apiService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el usuario actual
  ///
  /// Retorna:
  /// - UserModel del usuario autenticado
  /// - null si no hay sesión activa
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  /// Envía correo de recuperación de contraseña
  ///
  /// [email] - Correo electrónico del usuario
  Future<void> resetPassword(String email) async {
    try {
      await _apiService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Inicia sesión con Google
  ///
  /// Retorna:
  /// - UserModel del usuario autenticado con Google
  ///
  /// Lanza:
  /// - AuthException si el proceso falla o es cancelado
  Future<UserModel> signInWithGoogle() async {
    try {
      return await _apiService.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }
}
