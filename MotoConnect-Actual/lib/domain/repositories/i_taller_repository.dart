/// Interface de Repositorio de Talleres
///
/// Define el contrato para las operaciones de talleres.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/taller_model.dart';
import '../../data/models/taller_details_models.dart';

abstract class ITallerRepository {
  /// Obtiene todos los talleres
  Future<List<TallerModel>> getTalleres();

  /// Obtiene un taller por ID
  Future<TallerModel?> getTallerById(String tallerId);

  /// Crea un nuevo taller
  Future<TallerModel> createTaller({
    required String nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
    required String creadoPor,
  });

  /// Actualiza un taller existente
  Future<void> updateTaller({
    required String tallerId,
    String? nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
  });

  /// Elimina un taller
  Future<void> deleteTaller(String tallerId);

  /// Obtiene talleres creados por un usuario
  Future<List<TallerModel>> getTalleresByUser(String userId);

  /// Busca talleres por nombre o dirección
  Future<List<TallerModel>> searchTalleres(String query);

  /// Obtiene talleres cercanos a una ubicación
  Future<List<TallerModel>> getTalleresNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Verifica si un usuario es el creador de un taller
  Future<bool> isUserCreator(String tallerId, String userId);

  /// Obtiene el horario de un taller
  Future<List<TallerSchedule>> getTallerSchedule(String tallerId);

  /// Obtiene los servicios de un taller
  Future<List<TallerService>> getTallerServices(String tallerId);

  /// Obtiene las reseñas de un taller
  Future<List<TallerReview>> getTallerReviews(String tallerId);

  /// Obtiene las reseñas de un taller con paginación
  Future<List<TallerReview>> getTallerReviewsPaginated(
    String tallerId, {
    int page = 1,
    int limit = 10,
  });

  /// Obtiene el conteo de reseñas de un taller
  Future<int> getTallerReviewsCount(String tallerId);

  /// Obtiene la distribución de calificaciones de un taller
  Future<Map<int, int>> getRatingDistribution(String tallerId);

  /// Verifica si un taller es favorito del usuario
  Future<bool> isFavoriteTaller(String tallerId, String userId);

  /// Agrega un taller a favoritos
  Future<void> addToFavorites(String tallerId, String userId);

  /// Elimina un taller de favoritos
  Future<void> removeFromFavorites(String tallerId, String userId);

  /// Verifica si un taller está abierto en este momento
  Future<bool> isTallerOpen(String tallerId);

  /// Obtiene la información de contacto de un taller
  Future<Map<String, String?>> getTallerContactInfo(String tallerId);

  /// Calcula la distancia entre un punto y un taller
  double calculateDistance(double lat1, double lon1, String tallerId);

  /// Obtiene todos los talleres (alias)
  Future<List<TallerModel>> getAllTalleres();

  /// Obtiene talleres por categoría
  Future<List<TallerModel>> getTalleresByCategory(String category);

  /// Obtiene talleres mejor calificados
  Future<List<TallerModel>> getTopRatedTalleres({int limit = 10});

  /// Obtiene talleres filtrados
  Future<List<TallerModel>> getTalleresFiltered(Map<String, dynamic> filters);

  /// Obtiene talleres favoritos de un usuario
  Future<List<TallerModel>> getUserFavoriteTalleres(String userId);

  /// Obtiene talleres con paginación
  Future<List<TallerModel>> getTalleresPaginated({
    int page = 1,
    int pageSize = 10,
  });

  /// Verifica si un usuario ha calificado un taller
  Future<bool> hasUserRatedTaller(String tallerId, String userId);

  /// Crea una calificación para un taller
  Future<String> createRating({
    required String tallerId,
    required String userId,
    required int rating,
    String? comment,
  });

  /// Sube imágenes de una calificación
  Future<List<String>> uploadRatingImages(
    String ratingId,
    List<String> imagePaths,
  );

  /// Actualiza una calificación existente
  Future<void> updateRating({
    required String ratingId,
    int? rating,
    String? comment,
  });

  /// Elimina una calificación
  Future<void> deleteRating(String ratingId);

  /// Obtiene la calificación de un usuario para un taller
  Future<Map<String, dynamic>?> getUserRatingForTaller(
    String tallerId,
    String userId,
  );

  /// Reporta una calificación inapropiada
  Future<void> reportRating({
    required String ratingId,
    required String userId,
    required String reason,
  });

  /// Da like a una calificación
  Future<void> likeRating(String ratingId, String userId);

  /// Quita like a una calificación
  Future<void> unlikeRating(String ratingId, String userId);

  /// Obtiene estadísticas de calificaciones de un usuario
  Future<Map<String, dynamic>> getUserRatingStatistics(String userId);
}
