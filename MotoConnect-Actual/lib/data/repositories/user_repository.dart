/// Repository de Usuario/Perfil
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de usuarios
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de perfiles de usuario
/// - Gestión de datos de usuario
/// - Comunicación con UserApiService
library;

import '../../domain/repositories/i_user_repository.dart';
import '../services/api/user_api_service.dart';
import '../models/user_model.dart';

class UserRepository implements IUserRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de usuarios
  final UserApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de usuarios
  UserRepository({UserApiService? apiService})
    : _apiService = apiService ?? UserApiService();

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Obtiene el perfil del usuario actual
  ///
  /// Retorna:
  /// - UserModel del usuario autenticado
  /// - null si no hay sesión activa
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      return await _apiService.getCurrentUserProfile();
    } catch (e) {
      throw Exception('Error al obtener perfil actual: ${e.toString()}');
    }
  }

  /// Obtiene el perfil de un usuario por ID
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - UserModel del usuario
  /// - null si no se encuentra
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      return await _apiService.getUserProfile(userId);
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  /// Actualiza el perfil del usuario
  ///
  /// [userId] - ID del usuario
  /// [nombre] - Nuevo nombre (opcional)
  /// [modeloMoto] - Nuevo modelo de moto (opcional)
  /// [fotoPerfil] - Nueva URL de foto (opcional)
  Future<void> updateUserProfile({
    required String userId,
    String? nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    try {
      await _apiService.updateUserProfile(
        userId: userId,
        nombre: nombre,
        modeloMoto: modeloMoto,
        fotoPerfil: fotoPerfil,
      );
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }

  /// Crea o actualiza el perfil de un usuario (upsert)
  ///
  /// [userId] - ID del usuario
  /// [email] - Email del usuario
  /// [nombre] - Nombre del usuario
  /// [modeloMoto] - Modelo de moto (opcional)
  /// [fotoPerfil] - URL de foto de perfil (opcional)
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    try {
      await _apiService.upsertUserProfile(
        userId: userId,
        email: email,
        nombre: nombre,
        modeloMoto: modeloMoto,
        fotoPerfil: fotoPerfil,
      );
    } catch (e) {
      throw Exception('Error al guardar perfil: ${e.toString()}');
    }
  }

  /// Elimina el perfil de un usuario
  ///
  /// [userId] - ID del usuario
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _apiService.deleteUserProfile(userId);
    } catch (e) {
      throw Exception('Error al eliminar perfil: ${e.toString()}');
    }
  }

  /// Obtiene múltiples perfiles de usuarios
  ///
  /// [userIds] - Lista de IDs de usuarios
  ///
  /// Retorna:
  /// - Lista de UserModel
  Future<List<UserModel>> getUserProfiles(List<String> userIds) async {
    try {
      return await _apiService.getUserProfiles(userIds);
    } catch (e) {
      throw Exception('Error al obtener perfiles: ${e.toString()}');
    }
  }

  /// Busca usuarios por nombre
  ///
  /// [query] - Texto a buscar
  ///
  /// Retorna:
  /// - Lista de usuarios que coinciden con la búsqueda
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _apiService.searchUsersByName(query);
    } catch (e) {
      throw Exception('Error al buscar usuarios: ${e.toString()}');
    }
  }

  /// Obtiene todos los usuarios
  ///
  /// Retorna:
  /// - Lista de todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    try {
      return await _apiService.getAllUsers();
    } catch (e) {
      throw Exception('Error al obtener todos los usuarios: ${e.toString()}');
    }
  }

  /// Obtiene un usuario por ID (alias de getUserProfile)
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - UserModel del usuario
  /// - null si no se encuentra
  Future<UserModel?> getUserById(String userId) async {
    return await getUserProfile(userId);
  }

  /// Obtiene el usuario actual (alias de getCurrentUserProfile)
  ///
  /// Retorna:
  /// - UserModel del usuario autenticado
  /// - null si no hay sesión activa
  Future<UserModel?> getCurrentUser() async {
    return await getCurrentUserProfile();
  }

  /// Elimina un usuario (alias de deleteUserProfile)
  ///
  /// [userId] - ID del usuario
  Future<void> deleteUser(String userId) async {
    return await deleteUserProfile(userId);
  }
}
