import 'package:motoconnect/data/repositories/taller_repository.dart';
import 'package:motoconnect/data/models/taller_details_models.dart';

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
      final hasRated = await _tallerRepository.hasUserRatedTaller(tallerId, userId);

      if (hasRated) {
        throw Exception('Ya has calificado este taller. Usa editRating() para modificar tu calificación.');
      }

      final ratingId = await _tallerRepository.createRating(
        tallerId: tallerId,
        userId: userId,
        rating: rating.toInt(),
        comment: comment,
      );

      // Si hay imágenes, subirlas
      List<String>? uploadedImages;
      if (images != null && images.isNotEmpty) {
        uploadedImages = await _tallerRepository.uploadRatingImages(ratingId, images);
      }

      // Crear y retornar el objeto TallerRating
      return TallerRating(
        id: ratingId,
        tallerId: tallerId,
        userId: userId,
        userName: '', // Se puede obtener del user repository si es necesario
        rating: rating.toInt(),
        comment: comment,
        images: uploadedImages,
        createdAt: DateTime.now(),
        categoryRatings: categoryRatings != null
            ? Map<String, int>.fromEntries(
                categoryRatings.entries.map((e) => MapEntry(e.key, e.value.toInt()))
              )
            : null,
      );
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
      // Primero crear el rating básico
      final ratingResult = await call(
        tallerId: tallerId,
        userId: userId,
        rating: rating,
        comment: comment,
        images: imagePaths, // Usar las rutas locales temporalmente
        categoryRatings: categoryRatings,
      );

      return ratingResult;
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
      await _tallerRepository.updateRating(
        ratingId: ratingId,
        rating: rating.toInt(),
        comment: comment,
      );

      // Crear y retornar el objeto TallerRating actualizado
      return TallerRating(
        id: ratingId,
        tallerId: '', // No lo tenemos aquí, se podría pasar como parámetro
        userId: userId,
        userName: '', // Se puede obtener del user repository si es necesario
        rating: rating.toInt(),
        comment: comment,
        images: images,
        createdAt: DateTime.now(), // No tenemos la fecha original
        updatedAt: DateTime.now(),
        categoryRatings: categoryRatings != null
            ? Map<String, int>.fromEntries(
                categoryRatings.entries.map((e) => MapEntry(e.key, e.value.toInt()))
              )
            : null,
      );
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
      await _tallerRepository.deleteRating(ratingId);
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
      final ratingData = await _tallerRepository.getUserRatingForTaller(tallerId, userId);
      if (ratingData == null) return null;
      return TallerRating.fromJson(ratingData);
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
      return await _tallerRepository.hasUserRatedTaller(tallerId, userId);
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
      await _tallerRepository.likeRating(ratingId, userId);
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
      await _tallerRepository.unlikeRating(ratingId, userId);
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
