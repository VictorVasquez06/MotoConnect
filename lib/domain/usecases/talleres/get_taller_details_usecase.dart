import 'package:motoconnect/data/models/taller_model.dart';
import 'package:motoconnect/data/repositories/taller_repository.dart';
import 'package:motoconnect/data/models/taller_details_models.dart';

/// Modelo para detalles completos del taller
class TallerDetails {
  final TallerModel taller;
  final List<TallerSchedule> schedule;
  final List<TallerService> services;
  final List<TallerReview> reviews;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}
  final bool isFavorite;
  final double? distanceKm;

  TallerDetails({
    required this.taller,
    required this.schedule,
    required this.services,
    required this.reviews,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.isFavorite,
    this.distanceKm,
  });
}

/// Caso de uso para obtener los detalles completos de un taller
class GetTallerDetailsUseCase {
  final TallerRepository _tallerRepository;

  GetTallerDetailsUseCase(this._tallerRepository);

  /// Ejecuta el caso de uso para obtener los detalles de un taller
  /// 
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario (opcional, para verificar favoritos)
  /// [userLatitude] - latitud del usuario (opcional, para calcular distancia)
  /// [userLongitude] - longitud del usuario (opcional, para calcular distancia)
  /// 
  /// Retorna un objeto [TallerDetails] con toda la información del taller
  /// Lanza una excepción si ocurre un error
  Future<TallerDetails> call({
    required String tallerId,
    String? userId,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // Obtener información básica del taller
      final taller = await _tallerRepository.getTallerById(tallerId);
      
      if (taller == null) {
        throw Exception('Taller no encontrado');
      }

      // Obtener horario del taller
      final schedule = await _tallerRepository.getTallerSchedule(tallerId);
      
      // Obtener servicios del taller
      final services = await _tallerRepository.getTallerServices(tallerId);
      
      // Obtener reseñas del taller (primeras 10)
      final reviews = await _tallerRepository.getTallerReviewsPaginated(
        tallerId,
        limit: 10,
      );
      
      // Obtener total de reseñas
      final totalReviews = await _tallerRepository.getTallerReviewsCount(tallerId);
      
      // Obtener distribución de calificaciones
      final ratingDistribution = await _tallerRepository.getRatingDistribution(tallerId);
      
      // Verificar si es favorito del usuario
      bool isFavorite = false;
      if (userId != null) {
        isFavorite = await _tallerRepository.isFavoriteTaller(tallerId, userId);
      }
      
      // Calcular distancia si se proporcionan coordenadas
      double? distanceKm;
      if (userLatitude != null && userLongitude != null) {
        distanceKm = _tallerRepository.calculateDistance(userLatitude, userLongitude, tallerId);
      }

      return TallerDetails(
        taller: taller,
        schedule: schedule,
        services: services,
        reviews: reviews,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        isFavorite: isFavorite,
        distanceKm: distanceKm,
      );
    } catch (e) {
      throw Exception('Error al obtener detalles del taller: $e');
    }
  }

  /// Obtiene solo la información básica del taller
  /// 
  /// [tallerId] - ID del taller
  Future<TallerModel> getBasicInfo(String tallerId) async {
    try {
      final taller = await _tallerRepository.getTallerById(tallerId);
      
      if (taller == null) {
        throw Exception('Taller no encontrado');
      }
      
      return taller;
    } catch (e) {
      throw Exception('Error al obtener información del taller: $e');
    }
  }

  /// Obtiene el horario del taller
  /// 
  /// [tallerId] - ID del taller
  Future<List<TallerSchedule>> getSchedule(String tallerId) async {
    try {
      return await _tallerRepository.getTallerSchedule(tallerId);
    } catch (e) {
      throw Exception('Error al obtener horario del taller: $e');
    }
  }

  /// Obtiene los servicios del taller
  /// 
  /// [tallerId] - ID del taller
  Future<List<TallerService>> getServices(String tallerId) async {
    try {
      return await _tallerRepository.getTallerServices(tallerId);
    } catch (e) {
      throw Exception('Error al obtener servicios del taller: $e');
    }
  }

  /// Obtiene las reseñas del taller con paginación
  /// 
  /// [tallerId] - ID del taller
  /// [page] - número de página
  /// [limit] - cantidad de reseñas por página
  Future<List<TallerReview>> getReviews({
    required String tallerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      return await _tallerRepository.getTallerReviewsPaginated(
        tallerId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Error al obtener reseñas del taller: $e');
    }
  }

  /// Verifica si el taller está abierto actualmente
  /// 
  /// [tallerId] - ID del taller
  Future<bool> isCurrentlyOpen(String tallerId) async {
    try {
      return await _tallerRepository.isTallerOpen(tallerId);
    } catch (e) {
      throw Exception('Error al verificar si el taller está abierto: $e');
    }
  }

  /// Agrega o quita un taller de favoritos
  /// 
  /// [tallerId] - ID del taller
  /// [userId] - ID del usuario
  /// [isFavorite] - true para agregar, false para quitar
  Future<bool> toggleFavorite({
    required String tallerId,
    required String userId,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await _tallerRepository.addToFavorites(tallerId, userId);
      } else {
        await _tallerRepository.removeFromFavorites(tallerId, userId);
      }
      return !isFavorite;
    } catch (e) {
      throw Exception('Error al actualizar favoritos: $e');
    }
  }

  /// Obtiene información de contacto del taller
  /// 
  /// [tallerId] - ID del taller
  Future<Map<String, dynamic>> getContactInfo(String tallerId) async {
    try {
      return await _tallerRepository.getTallerContactInfo(tallerId);
    } catch (e) {
      throw Exception('Error al obtener información de contacto: $e');
    }
  }
}
