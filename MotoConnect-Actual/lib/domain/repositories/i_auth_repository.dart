/// Interface de Repositorio de Autenticación
///
/// Define el contrato para las operaciones de autenticación.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/user_model.dart';

abstract class IAuthRepository {
  /// Verifica si hay un usuario autenticado
  Future<bool> isAuthenticated();

  /// Inicia sesión con email y contraseña
  Future<UserModel> signIn({required String email, required String password});

  /// Registra un nuevo usuario
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nombre,
  });

  /// Cierra la sesión del usuario actual
  Future<void> signOut();

  /// Obtiene el usuario actual
  Future<UserModel?> getCurrentUser();

  /// Envía correo de recuperación de contraseña
  Future<void> resetPassword(String email);

  /// Inicia sesión con Google
  Future<UserModel> signInWithGoogle();
}
