import 'package:dartz/dartz.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/route_repository.dart';

/// Use case para obtener rutas disponibles
/// 
/// Maneja la lógica de negocio para recuperar rutas
/// con filtros, ordenamiento y paginación
class GetRoutesUseCase {
  final RouteRepository _routeRepository;

  GetRoutesUseCase(this._routeRepository);

  /// Ejecuta el use case para obtener rutas
  /// 
  /// [filters] - Mapa opcional de filtros
  ///   - 'difficulty': String ('fácil', 'moderada', 'difícil')
  ///   - 'type': String ('recreativa', 'deportiva', 'turística', 'técnica')
  ///   - 'minDistance': double (km)
  ///   - 'maxDistance': double (km)
  ///   - 'region': String
  /// [limit] - Número máximo de rutas a retornar
  /// [offset] - Offset para paginación
  /// [sortBy] - Campo por el cual ordenar ('distance', 'rating', 'created_at')
  /// 
  /// Retorna [Right] con lista de rutas si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, List<RouteModel>>> execute({
    Map<String, dynamic>? filters,
    int limit = 20,
    int offset = 0,
    String sortBy = 'created_at',
  }) async {
    try {
      // Validaciones de entrada
      if (limit <= 0) {
        return const Left('El límite debe ser mayor a 0');
      }
      
      if (offset < 0) {
        return const Left('El offset no puede ser negativo');
      }

      // Validar filtros si existen
      final validationError = _validateFilters(filters);
      if (validationError != null) {
        return Left(validationError);
      }

      // Llamar al repositorio
      final routes = await _routeRepository.getRoutes(
        filters: filters,
        limit: limit,
        offset: offset,
      );

      // Ordenar rutas según el criterio especificado
      final sortedRoutes = _sortRoutes(routes, sortBy);

      return Right(sortedRoutes);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene rutas por nivel de dificultad
  /// 
  /// [difficulty] - 'fácil', 'moderada', 'difícil'
  Future<Either<String, List<RouteModel>>> getByDifficulty({
    required String difficulty,
    int limit = 20,
  }) async {
    final validDifficulties = ['fácil', 'moderada', 'difícil'];
    
    if (!validDifficulties.contains(difficulty.toLowerCase())) {
      return Left(
        'Dificultad inválida. Debe ser: ${validDifficulties.join(", ")}'
      );
    }

    return execute(
      filters: {'difficulty': difficulty.toLowerCase()},
      limit: limit,
    );
  }

  /// Obtiene rutas por tipo
  /// 
  /// [type] - 'recreativa', 'deportiva', 'turística', 'técnica'
  Future<Either<String, List<RouteModel>>> getByType({
    required String type,
    int limit = 20,
  }) async {
    final validTypes = ['recreativa', 'deportiva', 'turística', 'técnica'];
    
    if (!validTypes.contains(type.toLowerCase())) {
      return Left(
        'Tipo inválido. Debe ser: ${validTypes.join(", ")}'
      );
    }

    return execute(
      filters: {'type': type.toLowerCase()},
      limit: limit,
    );
  }

  /// Obtiene rutas por rango de distancia
  /// 
  /// [minDistance] - Distancia mínima en km
  /// [maxDistance] - Distancia máxima en km
  Future<Either<String, List<RouteModel>>> getByDistanceRange({
    required double minDistance,
    required double maxDistance,
    int limit = 20,
  }) async {
    if (minDistance < 0 || maxDistance < 0) {
      return const Left('Las distancias no pueden ser negativas');
    }

    if (minDistance > maxDistance) {
      return const Left('La distancia mínima no puede ser mayor que la máxima');
    }

    return execute(
      filters: {
        'minDistance': minDistance,
        'maxDistance': maxDistance,
      },
      limit: limit,
    );
  }

  /// Obtiene rutas cercanas a una ubicación
  /// 
  /// [latitude] - Latitud de la ubicación
  /// [longitude] - Longitud de la ubicación
  /// [radiusKm] - Radio de búsqueda en kilómetros
  Future<Either<String, List<RouteModel>>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    if (latitude < -90 || latitude > 90) {
      return const Left('Latitud inválida (debe estar entre -90 y 90)');
    }

    if (longitude < -180 || longitude > 180) {
      return const Left('Longitud inválida (debe estar entre -180 y 180)');
    }

    if (radiusKm <= 0) {
      return const Left('El radio debe ser mayor a 0');
    }

    return execute(
      filters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusKm,
      },
      limit: limit,
    );
  }

  /// Obtiene las rutas mejor valoradas
  Future<Either<String, List<RouteModel>>> getTopRated({
    int limit = 10,
  }) async {
    return execute(
      limit: limit,
      sortBy: 'rating',
    );
  }

  /// Obtiene rutas más populares (más guardadas)
  Future<Either<String, List<RouteModel>>> getMostPopular({
    int limit = 10,
  }) async {
    return execute(
      filters: {'popular': true},
      limit: limit,
      sortBy: 'saves_count',
    );
  }

  /// Valida los filtros proporcionados
  String? _validateFilters(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      return null;
    }

    // Validar dificultad si existe
    if (filters.containsKey('difficulty')) {
      final difficulty = filters['difficulty'] as String?;
      final validDifficulties = ['fácil', 'moderada', 'difícil'];
      if (difficulty != null && !validDifficulties.contains(difficulty.toLowerCase())) {
        return 'Dificultad inválida';
      }
    }

    // Validar tipo si existe
    if (filters.containsKey('type')) {
      final type = filters['type'] as String?;
      final validTypes = ['recreativa', 'deportiva', 'turística', 'técnica'];
      if (type != null && !validTypes.contains(type.toLowerCase())) {
        return 'Tipo de ruta inválido';
      }
    }

    // Validar distancias
    if (filters.containsKey('minDistance')) {
      final minDistance = filters['minDistance'];
      if (minDistance is! double && minDistance is! int) {
        return 'Distancia mínima debe ser un número';
      }
      if ((minDistance as num) < 0) {
        return 'Distancia mínima no puede ser negativa';
      }
    }

    if (filters.containsKey('maxDistance')) {
      final maxDistance = filters['maxDistance'];
      if (maxDistance is! double && maxDistance is! int) {
        return 'Distancia máxima debe ser un número';
      }
      if ((maxDistance as num) < 0) {
        return 'Distancia máxima no puede ser negativa';
      }
    }

    return null;
  }

  /// Ordena las rutas según el criterio especificado
  List<RouteModel> _sortRoutes(List<RouteModel> routes, String sortBy) {
    final sortedList = List<RouteModel>.from(routes);

    switch (sortBy.toLowerCase()) {
      case 'distance':
        sortedList.sort((a, b) {
          final aDistance = a.distance ?? 0;
          final bDistance = b.distance ?? 0;
          return aDistance.compareTo(bDistance);
        });
        break;

      case 'rating':
        sortedList.sort((a, b) {
          final aRating = a.rating ?? 0;
          final bRating = b.rating ?? 0;
          return bRating.compareTo(aRating); // Descendente
        });
        break;

      case 'saves_count':
        sortedList.sort((a, b) {
          final aSaves = a.savesCount ?? 0;
          final bSaves = b.savesCount ?? 0;
          return bSaves.compareTo(aSaves); // Descendente
        });
        break;

      case 'created_at':
      default:
        sortedList.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!); // Más recientes primero
        });
        break;
    }

    return sortedList;
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('timeout')) {
      return 'La solicitud tardó demasiado. Intenta de nuevo.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para ver las rutas.';
    } else {
      return 'Error al cargar rutas: ${error.toString()}';
    }
  }
}
