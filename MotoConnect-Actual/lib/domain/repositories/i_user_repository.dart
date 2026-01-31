/// Interface de Repositorio de Usuario/Perfil
///
/// Define el contrato para las operaciones de usuarios.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/user_model.dart';

abstract class IUserRepository {
  /// Obtiene el perfil del usuario actual
  Future<UserModel?> getCurrentUserProfile();

  /// Obtiene el perfil de un usuario por ID
  Future<UserModel?> getUserProfile(String userId);

  /// Actualiza el perfil del usuario
  Future<void> updateUserProfile({
    required String userId,
    String? nombre,
    String? modeloMoto,
    String? fotoPerfil,
  });

  /// Crea o actualiza el perfil de un usuario (upsert)
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    String? modeloMoto,
    String? fotoPerfil,
  });

  /// Elimina el perfil de un usuario
  Future<void> deleteUserProfile(String userId);

  /// Obtiene múltiples perfiles de usuarios
  Future<List<UserModel>> getUserProfiles(List<String> userIds);

  /// Busca usuarios por nombre
  Future<List<UserModel>> searchUsers(String query);

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers();

  /// Obtiene un usuario por ID (alias de getUserProfile)
  Future<UserModel?> getUserById(String userId);

  /// Obtiene el usuario actual (alias de getCurrentUserProfile)
  Future<UserModel?> getCurrentUser();

  /// Elimina un usuario (alias de deleteUserProfile)
  Future<void> deleteUser(String userId);
}
