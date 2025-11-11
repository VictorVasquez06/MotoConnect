import 'package:motoconnect/data/models/taller_model.dart';
import 'package:motoconnect/data/repositories/taller_repository.dart';

/// Caso de uso para obtener la lista de talleres
class GetTalleresUseCase {
  final TallerRepository _tallerRepository;

  GetTalleresUseCase(this._tallerRepository);

  /// Ejecuta el caso de uso para obtener todos los talleres
  /// 
  /// Retorna una lista de [TallerModel]
  /// Lanza una excepción si ocurre un error
  Future<List<TallerModel>> call() async {
    try {
      final talleres = await _tallerRepository.getAllTalleres();
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener los talleres: $e');
    }
  }

  /// Obtiene talleres cercanos a una ubicación específica
  /// 
  /// [latitude] - latitud de la ubicación
  /// [longitude] - longitud de la ubicación
  /// [radiusKm] - radio de búsqueda en kilómetros (por defecto 10km)
  /// 
  /// Retorna una lista de [TallerModel] ordenados por distancia
  Future<List<TallerModel>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final talleres = await _tallerRepository.getTalleresNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres cercanos: $e');
    }
  }

  /// Obtiene talleres filtrados por categoría
  /// 
  /// [category] - categoría del servicio (mecánica, eléctrica, neumáticos, etc.)
  Future<List<TallerModel>> getByCategory(String category) async {
    if (category.trim().isEmpty) {
      throw Exception('La categoría no puede estar vacía');
    }

    try {
      final talleres = await _tallerRepository.getTalleresByCategory(category);
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres por categoría: $e');
    }
  }

  /// Busca talleres por nombre o descripción
  /// 
  /// [query] - término de búsqueda
  Future<List<TallerModel>> search(String query) async {
    if (query.trim().isEmpty) {
      throw Exception('El término de búsqueda no puede estar vacío');
    }

    if (query.trim().length < 3) {
      throw Exception('El término de búsqueda debe tener al menos 3 caracteres');
    }

    try {
      final talleres = await _tallerRepository.searchTalleres(query);
      return talleres;
    } catch (e) {
      throw Exception('Error al buscar talleres: $e');
    }
  }

  /// Obtiene talleres ordenados por calificación
  /// 
  /// [limit] - número máximo de talleres a retornar
  Future<List<TallerModel>> getTopRated({int limit = 10}) async {
    try {
      final talleres = await _tallerRepository.getTopRatedTalleres(limit: limit);
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres mejor calificados: $e');
    }
  }

  /// Obtiene talleres con filtros avanzados
  /// 
  /// [minRating] - calificación mínima
  /// [maxDistance] - distancia máxima en km
  /// [categories] - lista de categorías
  /// [isOpen] - filtrar solo talleres abiertos
  Future<List<TallerModel>> getFiltered({
    double? minRating,
    double? maxDistance,
    List<String>? categories,
    bool? isOpen,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // Construir el mapa de filtros
      final filters = <String, dynamic>{
        if (minRating != null) 'minRating': minRating,
        if (maxDistance != null) 'maxDistance': maxDistance,
        if (categories != null) 'categories': categories,
        if (isOpen != null) 'isOpen': isOpen,
        if (userLatitude != null) 'userLatitude': userLatitude,
        if (userLongitude != null) 'userLongitude': userLongitude,
      };

      final talleres = await _tallerRepository.getTalleresFiltered(filters);
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres filtrados: $e');
    }
  }

  /// Obtiene talleres favoritos del usuario
  /// 
  /// [userId] - ID del usuario
  Future<List<TallerModel>> getFavorites(String userId) async {
    try {
      final talleres = await _tallerRepository.getUserFavoriteTalleres(userId);
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres favoritos: $e');
    }
  }

  /// Obtiene talleres paginados
  /// 
  /// [page] - número de página
  /// [limit] - cantidad de talleres por página
  Future<List<TallerModel>> getPaginated({
    required int page,
    int limit = 20,
  }) async {
    try {
      final talleres = await _tallerRepository.getTalleresPaginated(
        page: page,
        pageSize: limit,
      );
      return talleres;
    } catch (e) {
      throw Exception('Error al obtener talleres paginados: $e');
    }
  }
}
