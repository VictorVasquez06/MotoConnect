/// Repository de Talleres
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de talleres
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de talleres
/// - Búsqueda de talleres
/// - Comunicación con TallerApiService
library;

import '../services/api/taller_api_service.dart';
import '../models/taller_model.dart';

class TallerRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de talleres
  final TallerApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de talleres
  TallerRepository({TallerApiService? apiService})
    : _apiService = apiService ?? TallerApiService();

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Obtiene todos los talleres
  ///
  /// Retorna:
  /// - Lista de talleres ordenados por nombre
  Future<List<TallerModel>> getTalleres() async {
    try {
      return await _apiService.getTalleres();
    } catch (e) {
      throw Exception('Error al obtener talleres: ${e.toString()}');
    }
  }

  /// Obtiene un taller por ID
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - TallerModel del taller
  /// - null si no se encuentra
  Future<TallerModel?> getTallerById(String tallerId) async {
    try {
      return await _apiService.getTallerById(tallerId);
    } catch (e) {
      throw Exception('Error al obtener taller: ${e.toString()}');
    }
  }

  /// Crea un nuevo taller
  ///
  /// [nombre] - Nombre del taller
  /// [direccion] - Dirección (opcional)
  /// [telefono] - Teléfono de contacto (opcional)
  /// [horario] - Horario de atención (opcional)
  /// [latitud] - Latitud de ubicación (opcional)
  /// [longitud] - Longitud de ubicación (opcional)
  /// [creadoPor] - ID del usuario que crea el taller
  ///
  /// Retorna:
  /// - TallerModel del taller creado
  Future<TallerModel> createTaller({
    required String nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
    required String creadoPor,
  }) async {
    try {
      if (nombre.trim().isEmpty) {
        throw Exception('El nombre del taller es obligatorio');
      }

      return await _apiService.createTaller(
        nombre: nombre,
        direccion: direccion,
        telefono: telefono,
        horario: horario,
        latitud: latitud,
        longitud: longitud,
        creadoPor: creadoPor,
      );
    } catch (e) {
      throw Exception('Error al crear taller: ${e.toString()}');
    }
  }

  /// Actualiza un taller existente
  ///
  /// [tallerId] - ID del taller
  /// [nombre] - Nuevo nombre (opcional)
  /// [direccion] - Nueva dirección (opcional)
  /// [telefono] - Nuevo teléfono (opcional)
  /// [horario] - Nuevo horario (opcional)
  /// [latitud] - Nueva latitud (opcional)
  /// [longitud] - Nueva longitud (opcional)
  Future<void> updateTaller({
    required String tallerId,
    String? nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
  }) async {
    try {
      await _apiService.updateTaller(
        tallerId: tallerId,
        nombre: nombre,
        direccion: direccion,
        telefono: telefono,
        horario: horario,
        latitud: latitud,
        longitud: longitud,
      );
    } catch (e) {
      throw Exception('Error al actualizar taller: ${e.toString()}');
    }
  }

  /// Elimina un taller
  ///
  /// [tallerId] - ID del taller
  Future<void> deleteTaller(String tallerId) async {
    try {
      await _apiService.deleteTaller(tallerId);
    } catch (e) {
      throw Exception('Error al eliminar taller: ${e.toString()}');
    }
  }

  /// Obtiene talleres creados por un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de talleres creados por el usuario
  Future<List<TallerModel>> getTalleresByUser(String userId) async {
    try {
      return await _apiService.getTalleresByUser(userId);
    } catch (e) {
      throw Exception('Error al obtener talleres del usuario: ${e.toString()}');
    }
  }

  /// Busca talleres por nombre o dirección
  ///
  /// [query] - Texto a buscar
  ///
  /// Retorna:
  /// - Lista de talleres que coinciden con la búsqueda
  Future<List<TallerModel>> searchTalleres(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _apiService.searchTalleres(query);
    } catch (e) {
      throw Exception('Error al buscar talleres: ${e.toString()}');
    }
  }

  /// Obtiene talleres cercanos a una ubicación
  ///
  /// [latitude] - Latitud de la ubicación
  /// [longitude] - Longitud de la ubicación
  /// [radiusKm] - Radio de búsqueda en kilómetros (default: 10km)
  ///
  /// Retorna:
  /// - Lista de talleres dentro del radio especificado
  Future<List<TallerModel>> getTalleresNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      return await _apiService.getTalleresNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw Exception('Error al obtener talleres cercanos: ${e.toString()}');
    }
  }

  /// Verifica si un usuario es el creador de un taller
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario es el creador
  Future<bool> isUserCreator(String tallerId, String userId) async {
    try {
      final taller = await getTallerById(tallerId);
      return taller?.creadoPor == userId;
    } catch (e) {
      return false;
    }
  }
}
