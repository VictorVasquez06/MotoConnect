import 'package:motoconnect/data/repositories/taller_repository.dart';

/// Modelo para representar una calificación de taller
class TallerRating {
  final String id;
  final String tallerId;
  final String userId;
  final double rating;
  final String comment;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, double>? categoryRatings; // {servicio: 5.0, precio: 4.0, atencion: 5.0}

  TallerRating({
    required this.id,
    required this.tallerId,
    required this.userId,
    required this.rating,
    required this.comment,
    this.images,
    required this.createdAt,
    this.updatedAt,
    this.categoryRatings,
  });
}

/// Caso de uso para calificar un taller
class RateTallerUseCase {
  final TallerRepository _tallerRepository;

  RateTallerUseCase(this._tallerRepository);

  /// Ejecuta el caso de uso para calificar un taller
  /// 
  /// [tallerId] - ID del taller a calificar
  /// [userId] - ID del usuario que califica
  /// [rating] - calificación de 1 a 5
  /// [comment] - comentario de la reseña
  /// [images] - imágenes opcionales de la reseña
  /// [categoryRatings] - calificaciones por categoría (opcional)
  /// 
  /// Retorna el objeto [TallerRating] creado
  /// Lanza una excepción si ocurre un error
  Future<TallerRating> call({
    required String tallerId,
    required String userId,
    required double rating,
    required String comment,
    List<String>? images,
    Map<String, double>? categoryRatings,
  }) async {
    // Validaciones
    if (rating < 1.0 || rating > 5.0) {
      throw Exception('La calificación debe estar entre 1 y 5');
    }

    if (comment.trim().isEmpty) {
      throw Exception('El comentario no puede estar vacío');
    }

    if (comment.length < 10) {
      throw Exception('El comentario debe tener al menos 10 caracteres');
    }

    if (comment.length > 500) {
      throw Exception('El comentario no puede exceder 500 caracteres');
    }

    // Validar calificaciones por categoría si existen
    if (categoryRatings != null) {
      for (var categoryRating in categoryRatings.values) {
        if (categoryRating < 1.0 || categoryRating > 5.0) {
          throw Exception('Todas las calificaciones por categoría deben estar entre 1 y 5');
        }
      }
    }

    try {
      // Verificar si el usuario ya calificó este taller
      final hasRated = await _tallerRepository.hasUserRatedTaller(
        tallerId: tallerId,
        userId: userId,
      );

      if (hasRated) {
        throw Exception('Ya has calificado este taller. Usa editRating() para modificar tu calificación.');
      }

      final tallerRating = await _tallerRepository.createRating(
        tallerId: tallerId,
        userId: userId,
        rating: rating,
        comment: comment,
        images: images,
        categoryRatings: categoryRatings,
      );

      return tallerRating;
    } catch (e) {
      throw Exception('Error al calificar el taller: $e');
    }
  }

  /// Crea una calificación con imágenes
  /// 
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  /// [rating] - calificación
  /// [comment] - comentario
  /// [imagePaths] - rutas locales de las imágenes
  Future<TallerRating> rateWithImages({
    required String tallerId,
    required String userId,
    required double rating,
    required String comment,
    required List<String> imagePaths,
    Map<String, double>? categoryRatings,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('Debe proporcionar al menos una imagen');
    }

    if (imagePaths.length > 5) {
      throw Exception('No se pueden subir más de 5 imágenes');
    }

    try {
      // Subir las imágenes
      final imageUrls = await _tallerRepository.uploadRatingImages(imagePaths);

      // Crear la calificación con las URLs de las imágenes
      return await call(
        tallerId: tallerId,
        userId: userId,
        rating: rating,
        comment: comment,
        images: imageUrls,
        categoryRatings: categoryRatings,
      );
    } catch (e) {
      throw Exception('Error al calificar con imágenes: $e');
    }
  }

  /// Edita una calificación existente
  /// 
  /// [ratingId] - ID de la calificación a editar
  /// [userId] - ID del usuario (debe ser el autor)
  /// [rating] - nueva calificación
  /// [comment] - nuevo comentario
  /// [images] - nuevas imágenes (opcional)
  Future<TallerRating> editRating({
    required String ratingId,
    required String userId,
    required double rating,
    required String comment,
    List<String>? images,
    Map<String, double>? categoryRatings,
  }) async {
    // Validaciones
    if (rating < 1.0 || rating > 5.0) {
      throw Exception('La calificación debe estar entre 1 y 5');
    }

    if (comment.trim().isEmpty) {
      throw Exception('El comentario no puede estar vacío');
    }

    if (comment.length < 10) {
      throw Exception('El comentario debe tener al menos 10 caracteres');
    }

    if (comment.length > 500) {
      throw Exception('El comentario no puede exceder 500 caracteres');
    }

    try {
      final updatedRating = await _tallerRepository.updateRating(
        ratingId: ratingId,
        userId: userId,
        rating: rating,
        comment: comment,
        images: images,
        categoryRatings: categoryRatings,
      );

      return updatedRating;
    } catch (e) {
      throw Exception('Error al editar la calificación: $e');
    }
  }

  /// Elimina una calificación
  /// 
  /// [ratingId] - ID de la calificación a eliminar
  /// [userId] - ID del usuario (debe ser el autor)
  Future<bool> deleteRating({
    required String ratingId,
    required String userId,
  }) async {
    try {
      await _tallerRepository.deleteRating(
        ratingId: ratingId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al eliminar la calificación: $e');
    }
  }

  /// Obtiene la calificación del usuario para un taller
  /// 
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  /// 
  /// Retorna la calificación si existe, null si no
  Future<TallerRating?> getUserRating({
    required String tallerId,
    required String userId,
  }) async {
    try {
      return await _tallerRepository.getUserRatingForTaller(
        tallerId: tallerId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Error al obtener la calificación del usuario: $e');
    }
  }

  /// Verifica si el usuario ya calificó el taller
  /// 
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  Future<bool> hasUserRated({
    required String tallerId,
    required String userId,
  }) async {
    try {
      return await _tallerRepository.hasUserRatedTaller(
        tallerId: tallerId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Error al verificar calificación: $e');
    }
  }

  /// Reporta una reseña como inapropiada
  /// 
  /// [ratingId] - ID de la calificación a reportar
  /// [userId] - ID del usuario que reporta
  /// [reason] - razón del reporte
  Future<bool> reportRating({
    required String ratingId,
    required String userId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Debe proporcionar una razón para el reporte');
    }

    try {
      await _tallerRepository.reportRating(
        ratingId: ratingId,
        userId: userId,
        reason: reason,
      );
      return true;
    } catch (e) {
      throw Exception('Error al reportar la reseña: $e');
    }
  }

  /// Da "me gusta" a una reseña
  /// 
  /// [ratingId] - ID de la calificación
  /// [userId] - ID del usuario
  Future<bool> likeRating({
    required String ratingId,
    required String userId,
  }) async {
    try {
      await _tallerRepository.likeRating(
        ratingId: ratingId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al dar me gusta a la reseña: $e');
    }
  }

  /// Quita el "me gusta" de una reseña
  /// 
  /// [ratingId] - ID de la calificación
  /// [userId] - ID del usuario
  Future<bool> unlikeRating({
    required String ratingId,
    required String userId,
  }) async {
    try {
      await _tallerRepository.unlikeRating(
        ratingId: ratingId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al quitar me gusta de la reseña: $e');
    }
  }

  /// Obtiene estadísticas de las calificaciones del usuario
  /// 
  /// [userId] - ID del usuario
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    try {
      return await _tallerRepository.getUserRatingStatistics(userId);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
