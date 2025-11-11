import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class ProfileService {
  // Getter para evaluación perezosa (lazy evaluation)
  // Esto previene el error de acceso a Supabase antes de inicialización
  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response =
          await _supabase
              .from('usuarios')
              .select()
              .eq('id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  /// Obtener perfil de cualquier usuario por ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('usuarios')
              .select()
              .eq('id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  /// Actualizar perfil
  Future<void> updateProfile({
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

      await _supabase.from('usuarios').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }
}
