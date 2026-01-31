/// Servicio de API de Usuario/Perfil
///
/// Capa más baja de abstracción - interactúa directamente con Supabase
///
/// Responsabilidades:
/// - Llamadas a Supabase para usuarios
/// - Conversión de respuestas a modelos
/// - Manejo de errores de API
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

class UserApiService {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ========================================
  // MÉTODOS PÚBLICOS - PERFIL
  // ========================================

  /// Obtiene el perfil de un usuario por ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.usersTable)
              .select()
              .eq('id', userId)
              .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  /// Obtiene el perfil del usuario actual
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      return await getUserProfile(currentUser.id);
    } catch (e) {
      throw Exception('Error al obtener perfil actual: ${e.toString()}');
    }
  }

  /// Actualiza el perfil de un usuario
  Future<void> updateUserProfile({
    required String userId,
    String? nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (nombre != null) updates['nombre'] = nombre;
      if (modeloMoto != null) updates['modelo_moto'] = modeloMoto;
      if (fotoPerfil != null) updates['foto_perfil_url'] = fotoPerfil;

      if (updates.isEmpty) return;

      await _supabase
          .from(ApiConstants.usersTable)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }

  /// Crea o actualiza el perfil de un usuario (upsert)
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    try {
      await _supabase.from(ApiConstants.usersTable).upsert({
        'id': userId,
        'correo': email,
        'nombre': nombre,
        'modelo_moto': modeloMoto,
        'foto_perfil_url': fotoPerfil,
      });
    } catch (e) {
      throw Exception('Error al guardar perfil: ${e.toString()}');
    }
  }

  /// Elimina el perfil de un usuario
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _supabase.from(ApiConstants.usersTable).delete().eq('id', userId);
    } catch (e) {
      throw Exception('Error al eliminar perfil: ${e.toString()}');
    }
  }

  /// Obtiene múltiples perfiles de usuarios por IDs
  Future<List<UserModel>> getUserProfiles(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final response = await _supabase
          .from(ApiConstants.usersTable)
          .select()
          .inFilter('id', userIds);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener perfiles: ${e.toString()}');
    }
  }

  /// Busca usuarios por nombre
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from(ApiConstants.usersTable)
          .select()
          .ilike('nombre', '%$query%')
          .limit(20);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: ${e.toString()}');
    }
  }

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from(ApiConstants.usersTable)
          .select()
          .limit(1000);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener todos los usuarios: ${e.toString()}');
    }
  }
}
