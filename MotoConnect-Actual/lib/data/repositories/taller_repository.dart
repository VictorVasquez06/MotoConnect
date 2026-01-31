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

import '../../domain/repositories/i_taller_repository.dart';
import '../services/api/taller_api_service.dart';
import '../models/taller_model.dart';
import '../models/taller_details_models.dart';

class TallerRepository implements ITallerRepository {
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

  /// Obtiene el horario de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Lista de horarios del taller
  Future<List<TallerSchedule>> getTallerSchedule(String tallerId) async {
    try {
      final scheduleData = await _apiService.getTallerSchedule(tallerId);
      if (scheduleData == null) return [];

      // Si es un Map, convertirlo a lista
      if (scheduleData is Map<String, dynamic>) {
        final List<TallerSchedule> schedules = [];
        scheduleData.forEach((day, hours) {
          if (hours is Map) {
            schedules.add(
              TallerSchedule(
                day: day,
                openTime: hours['open'] as String? ?? '',
                closeTime: hours['close'] as String? ?? '',
                isOpen: hours['isOpen'] as bool? ?? true,
              ),
            );
          }
        });
        return schedules;
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener horario del taller: ${e.toString()}');
    }
  }

  /// Obtiene los servicios de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Lista de servicios ofrecidos por el taller
  Future<List<TallerService>> getTallerServices(String tallerId) async {
    try {
      final services = await _apiService.getTallerServices(tallerId);
      return services
          .map((service) => TallerService.fromString(service))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener servicios del taller: ${e.toString()}');
    }
  }

  /// Obtiene las reseñas de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Lista de reseñas del taller
  Future<List<TallerReview>> getTallerReviews(String tallerId) async {
    try {
      final reviewsData = await _apiService.getTallerReviews(tallerId);
      return reviewsData
          .map((review) => TallerReview.fromJson(review))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reseñas del taller: ${e.toString()}');
    }
  }

  /// Obtiene las reseñas de un taller con paginación
  ///
  /// [tallerId] - ID del taller
  /// [page] - Número de página
  /// [limit] - Cantidad de items por página (alias de pageSize)
  ///
  /// Retorna:
  /// - Lista de reseñas paginadas
  Future<List<TallerReview>> getTallerReviewsPaginated(
    String tallerId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final reviewsData = await _apiService.getTallerReviewsPaginated(
        tallerId,
        page: page,
        pageSize: limit,
      );
      return reviewsData
          .map((review) => TallerReview.fromJson(review))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reseñas paginadas: ${e.toString()}');
    }
  }

  /// Obtiene el conteo de reseñas de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Cantidad total de reseñas
  Future<int> getTallerReviewsCount(String tallerId) async {
    try {
      return await _apiService.getTallerReviewsCount(tallerId);
    } catch (e) {
      throw Exception('Error al obtener conteo de reseñas: ${e.toString()}');
    }
  }

  /// Obtiene la distribución de calificaciones de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Mapa con la distribución de calificaciones (1-5 estrellas)
  Future<Map<int, int>> getRatingDistribution(String tallerId) async {
    try {
      return await _apiService.getRatingDistribution(tallerId);
    } catch (e) {
      throw Exception(
        'Error al obtener distribución de calificaciones: ${e.toString()}',
      );
    }
  }

  /// Verifica si un taller es favorito del usuario
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el taller es favorito del usuario
  Future<bool> isFavoriteTaller(String tallerId, String userId) async {
    try {
      return await _apiService.isFavoriteTaller(tallerId, userId);
    } catch (e) {
      return false;
    }
  }

  /// Agrega un taller a favoritos
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  Future<void> addToFavorites(String tallerId, String userId) async {
    try {
      await _apiService.addToFavorites(tallerId, userId);
    } catch (e) {
      throw Exception('Error al agregar a favoritos: ${e.toString()}');
    }
  }

  /// Elimina un taller de favoritos
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  Future<void> removeFromFavorites(String tallerId, String userId) async {
    try {
      await _apiService.removeFromFavorites(tallerId, userId);
    } catch (e) {
      throw Exception('Error al remover de favoritos: ${e.toString()}');
    }
  }

  /// Verifica si un taller está abierto en este momento
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - true si el taller está abierto
  Future<bool> isTallerOpen(String tallerId) async {
    try {
      return await _apiService.isTallerOpen(tallerId);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la información de contacto de un taller
  ///
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Mapa con teléfono, dirección y horario
  Future<Map<String, String?>> getTallerContactInfo(String tallerId) async {
    try {
      return await _apiService.getTallerContactInfo(tallerId);
    } catch (e) {
      throw Exception(
        'Error al obtener información de contacto: ${e.toString()}',
      );
    }
  }

  /// Calcula la distancia entre un punto y un taller
  ///
  /// [lat1] - Latitud del punto de origen
  /// [lon1] - Longitud del punto de origen
  /// [tallerId] - ID del taller
  ///
  /// Retorna:
  /// - Distancia en kilómetros
  double calculateDistance(double lat1, double lon1, String tallerId) {
    try {
      return _apiService.calculateDistance(lat1, lon1, tallerId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtiene todos los talleres (alias para getTalleres)
  ///
  /// Retorna:
  /// - Lista de todos los talleres
  Future<List<TallerModel>> getAllTalleres() async {
    try {
      return await getTalleres();
    } catch (e) {
      throw Exception('Error al obtener todos los talleres: ${e.toString()}');
    }
  }

  /// Obtiene talleres por categoría
  ///
  /// [category] - Categoría del taller
  ///
  /// Retorna:
  /// - Lista de talleres de la categoría especificada
  Future<List<TallerModel>> getTalleresByCategory(String category) async {
    try {
      // Por ahora devuelve todos los talleres
      // Implementar cuando se agregue campo de categoría
      return await getTalleres();
    } catch (e) {
      throw Exception(
        'Error al obtener talleres por categoría: ${e.toString()}',
      );
    }
  }

  /// Obtiene talleres mejor calificados
  ///
  /// [limit] - Cantidad máxima de talleres a devolver
  ///
  /// Retorna:
  /// - Lista de talleres mejor calificados
  Future<List<TallerModel>> getTopRatedTalleres({int limit = 10}) async {
    try {
      // Por ahora devuelve todos los talleres
      // Implementar cuando se agregue sistema de calificaciones
      final talleres = await getTalleres();
      return talleres.take(limit).toList();
    } catch (e) {
      throw Exception(
        'Error al obtener talleres mejor calificados: ${e.toString()}',
      );
    }
  }

  /// Obtiene talleres filtrados
  ///
  /// [filters] - Mapa de filtros a aplicar
  ///
  /// Retorna:
  /// - Lista de talleres filtrados
  Future<List<TallerModel>> getTalleresFiltered(
    Map<String, dynamic> filters,
  ) async {
    try {
      // Implementar lógica de filtrado
      return await getTalleres();
    } catch (e) {
      throw Exception('Error al obtener talleres filtrados: ${e.toString()}');
    }
  }

  /// Obtiene talleres favoritos de un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de talleres favoritos del usuario
  Future<List<TallerModel>> getUserFavoriteTalleres(String userId) async {
    try {
      // Implementar cuando se cree la tabla de favoritos
      return [];
    } catch (e) {
      throw Exception('Error al obtener talleres favoritos: ${e.toString()}');
    }
  }

  /// Obtiene talleres con paginación
  ///
  /// [page] - Número de página
  /// [pageSize] - Cantidad de items por página
  ///
  /// Retorna:
  /// - Lista de talleres paginados
  Future<List<TallerModel>> getTalleresPaginated({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final talleres = await getTalleres();
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      if (startIndex >= talleres.length) return [];

      return talleres.sublist(
        startIndex,
        endIndex > talleres.length ? talleres.length : endIndex,
      );
    } catch (e) {
      throw Exception('Error al obtener talleres paginados: ${e.toString()}');
    }
  }

  /// Verifica si un usuario ha calificado un taller
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario ya calificó el taller
  Future<bool> hasUserRatedTaller(String tallerId, String userId) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crea una calificación para un taller
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  /// [rating] - Calificación (1-5)
  /// [comment] - Comentario (opcional)
  ///
  /// Retorna:
  /// - ID de la calificación creada
  Future<String> createRating({
    required String tallerId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
      return '';
    } catch (e) {
      throw Exception('Error al crear calificación: ${e.toString()}');
    }
  }

  /// Sube imágenes de una calificación
  ///
  /// [ratingId] - ID de la calificación
  /// [imagePaths] - Rutas de las imágenes a subir
  ///
  /// Retorna:
  /// - Lista de URLs de las imágenes subidas
  Future<List<String>> uploadRatingImages(
    String ratingId,
    List<String> imagePaths,
  ) async {
    try {
      // Implementar cuando se cree la funcionalidad de storage
      return [];
    } catch (e) {
      throw Exception('Error al subir imágenes: ${e.toString()}');
    }
  }

  /// Actualiza una calificación existente
  ///
  /// [ratingId] - ID de la calificación
  /// [rating] - Nueva calificación (opcional)
  /// [comment] - Nuevo comentario (opcional)
  Future<void> updateRating({
    required String ratingId,
    int? rating,
    String? comment,
  }) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
    } catch (e) {
      throw Exception('Error al actualizar calificación: ${e.toString()}');
    }
  }

  /// Elimina una calificación
  ///
  /// [ratingId] - ID de la calificación
  Future<void> deleteRating(String ratingId) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
    } catch (e) {
      throw Exception('Error al eliminar calificación: ${e.toString()}');
    }
  }

  /// Obtiene la calificación de un usuario para un taller
  ///
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Mapa con datos de la calificación o null
  Future<Map<String, dynamic>?> getUserRatingForTaller(
    String tallerId,
    String userId,
  ) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Reporta una calificación inapropiada
  ///
  /// [ratingId] - ID de la calificación
  /// [userId] - ID del usuario que reporta
  /// [reason] - Razón del reporte
  Future<void> reportRating({
    required String ratingId,
    required String userId,
    required String reason,
  }) async {
    try {
      // Implementar cuando se cree la funcionalidad de reportes
    } catch (e) {
      throw Exception('Error al reportar calificación: ${e.toString()}');
    }
  }

  /// Da like a una calificación
  ///
  /// [ratingId] - ID de la calificación
  /// [userId] - ID del usuario
  Future<void> likeRating(String ratingId, String userId) async {
    try {
      // Implementar cuando se cree la funcionalidad de likes
    } catch (e) {
      throw Exception('Error al dar like: ${e.toString()}');
    }
  }

  /// Quita like a una calificación
  ///
  /// [ratingId] - ID de la calificación
  /// [userId] - ID del usuario
  Future<void> unlikeRating(String ratingId, String userId) async {
    try {
      // Implementar cuando se cree la funcionalidad de likes
    } catch (e) {
      throw Exception('Error al quitar like: ${e.toString()}');
    }
  }

  /// Obtiene estadísticas de calificaciones de un usuario
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Mapa con estadísticas de calificaciones
  Future<Map<String, dynamic>> getUserRatingStatistics(String userId) async {
    try {
      // Implementar cuando se cree la tabla de calificaciones
      return {'total_ratings': 0, 'average_rating': 0.0, 'total_likes': 0};
    } catch (e) {
      throw Exception(
        'Error al obtener estadísticas de calificaciones: ${e.toString()}',
      );
    }
  }
}
