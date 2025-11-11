import 'package:dartz/dartz.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/route_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Use case para obtener las rutas guardadas/favoritas del usuario
///
/// Maneja la lógica de negocio para recuperar rutas que el usuario
/// ha guardado como favoritas o creado
class GetSavedRoutesUseCase {
  final RouteRepository _routeRepository;
  final UserRepository _userRepository;

  GetSavedRoutesUseCase(this._routeRepository, this._userRepository);

  /// Ejecuta el use case para obtener rutas guardadas
  ///
  /// [userId] - ID del usuario (opcional, usa el usuario actual)
  /// [includeOwn] - Si debe incluir rutas creadas por el usuario
  /// [filters] - Filtros opcionales adicionales
  /// [limit] - Número máximo de rutas a retornar
  /// [offset] - Offset para paginación
  /// [sortBy] - Campo por el cual ordenar
  ///
  /// Retorna [Right] con lista de rutas si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, List<RouteModel>>> execute({
    String? userId,
    bool includeOwn = false,
    Map<String, dynamic>? filters,
    int limit = 20,
    int offset = 0,
    String sortBy = 'saved_at',
  }) async {
    try {
      // Validaciones de entrada
      if (limit <= 0) {
        return const Left('El límite debe ser mayor a 0');
      }

      if (offset < 0) {
        return const Left('El offset no puede ser negativo');
      }

      // Obtener ID del usuario actual si no se proporciona
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Obtener rutas guardadas del repositorio
      var savedRoutes = await _routeRepository.getSavedRoutesForUser(
        currentUserId,
      );

      // Aplicar filtros, límite y offset manualmente
      if (offset != null && offset > 0) {
        savedRoutes = savedRoutes.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        savedRoutes = savedRoutes.take(limit).toList();
      }

      // Si se solicita, incluir rutas creadas por el usuario
      List<RouteModel> allRoutes = savedRoutes;
      if (includeOwn) {
        final ownRoutes = await _routeRepository.getRoutesCreatedByUser(
          currentUserId,
        );

        // Combinar y eliminar duplicados
        allRoutes = _mergeLists(savedRoutes, ownRoutes);
      }

      // Ordenar rutas según el criterio especificado
      final sortedRoutes = _sortRoutes(allRoutes, sortBy);

      return Right(sortedRoutes);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene solo las rutas creadas por el usuario
  Future<Either<String, List<RouteModel>>> getCreatedRoutes({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      final routes = await _routeRepository.getRoutesCreatedByUser(
        currentUserId,
      );

      return Right(routes);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene solo las rutas favoritas (no creadas por el usuario)
  Future<Either<String, List<RouteModel>>> getFavoriteRoutes({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      var routes = await _routeRepository.getSavedRoutesForUser(currentUserId);

      // Aplicar offset y limit
      if (offset > 0) {
        routes = routes.skip(offset).toList();
      }
      if (limit > 0) {
        routes = routes.take(limit).toList();
      }

      // Filtrar para excluir las creadas por el usuario
      final favoriteRoutes =
          routes.where((route) => route.creatorId != currentUserId).toList();

      return Right(favoriteRoutes);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Obtiene rutas guardadas por dificultad
  Future<Either<String, List<RouteModel>>> getSavedByDifficulty({
    required String difficulty,
    String? userId,
    int limit = 20,
  }) async {
    final validDifficulties = ['fácil', 'moderada', 'difícil'];

    if (!validDifficulties.contains(difficulty.toLowerCase())) {
      return Left(
        'Dificultad inválida. Debe ser: ${validDifficulties.join(", ")}',
      );
    }

    return execute(
      userId: userId,
      filters: {'difficulty': difficulty.toLowerCase()},
      limit: limit,
    );
  }

  /// Obtiene rutas guardadas por tipo
  Future<Either<String, List<RouteModel>>> getSavedByType({
    required String type,
    String? userId,
    int limit = 20,
  }) async {
    final validTypes = ['recreativa', 'deportiva', 'turística', 'técnica'];

    if (!validTypes.contains(type.toLowerCase())) {
      return Left('Tipo inválido. Debe ser: ${validTypes.join(", ")}');
    }

    return execute(
      userId: userId,
      filters: {'type': type.toLowerCase()},
      limit: limit,
    );
  }

  /// Obtiene estadísticas de rutas guardadas del usuario
  Future<Either<String, SavedRoutesStats>> getStats({String? userId}) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Obtener todas las rutas (sin límite para estadísticas)
      final savedRoutes = await _routeRepository.getSavedRoutesForUser(
        currentUserId,
      );

      final createdRoutes = await _routeRepository.getRoutesCreatedByUser(
        currentUserId,
      );

      // Calcular estadísticas
      final stats = _calculateStats(savedRoutes, createdRoutes);

      return Right(stats);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Busca en las rutas guardadas
  Future<Either<String, List<RouteModel>>> searchSaved({
    required String query,
    String? userId,
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty || query.length < 2) {
        return const Left('La búsqueda debe tener al menos 2 caracteres');
      }

      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Obtener todas las rutas guardadas
      final routes = await _routeRepository.getSavedRoutesForUser(
        currentUserId,
      );

      // Filtrar por query
      final queryLower = query.toLowerCase();
      final filteredRoutes =
          routes
              .where((route) {
                final name = route.name?.toLowerCase() ?? '';
                final description = route.description?.toLowerCase() ?? '';
                return name.contains(queryLower) ||
                    description.contains(queryLower);
              })
              .take(limit)
              .toList();

      return Right(filteredRoutes);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Verifica si una ruta específica está guardada
  Future<Either<String, bool>> isRouteSaved({
    required String routeId,
    String? userId,
  }) async {
    try {
      if (routeId.isEmpty) {
        return const Left('ID de ruta inválido');
      }

      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      final isSaved = await _routeRepository.isRouteSavedByUser(
        routeId,
        currentUserId,
      );

      return Right(isSaved);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Calcula estadísticas de las rutas
  SavedRoutesStats _calculateStats(
    List<RouteModel> savedRoutes,
    List<RouteModel> createdRoutes,
  ) {
    // Contar rutas por dificultad
    final byDifficulty = <String, int>{};
    for (final route in savedRoutes) {
      final diff = route.difficulty ?? 'desconocida';
      byDifficulty[diff] = (byDifficulty[diff] ?? 0) + 1;
    }

    // Contar rutas por tipo
    final byType = <String, int>{};
    for (final route in savedRoutes) {
      final type = route.type ?? 'otro';
      byType[type] = (byType[type] ?? 0) + 1;
    }

    // Calcular distancia total
    double totalDistance = 0;
    for (final route in savedRoutes) {
      totalDistance += route.distance ?? 0;
    }

    // Encontrar ruta más larga y más corta
    RouteModel? longestRoute;
    RouteModel? shortestRoute;

    if (savedRoutes.isNotEmpty) {
      longestRoute = savedRoutes.reduce(
        (a, b) => (a.distance ?? 0) > (b.distance ?? 0) ? a : b,
      );

      shortestRoute = savedRoutes.reduce(
        (a, b) => (a.distance ?? 0) < (b.distance ?? 0) ? a : b,
      );
    }

    return SavedRoutesStats(
      totalSaved: savedRoutes.length,
      totalCreated: createdRoutes.length,
      byDifficulty: byDifficulty,
      byType: byType,
      totalDistance: totalDistance,
      averageDistance:
          savedRoutes.isNotEmpty ? totalDistance / savedRoutes.length : 0,
      longestRoute: longestRoute,
      shortestRoute: shortestRoute,
    );
  }

  /// Combina dos listas eliminando duplicados
  List<RouteModel> _mergeLists(List<RouteModel> list1, List<RouteModel> list2) {
    final map = <String, RouteModel>{};

    for (final route in list1) {
      map[route.id!] = route;
    }

    for (final route in list2) {
      map[route.id!] = route;
    }

    return map.values.toList();
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

      case 'name':
        sortedList.sort((a, b) {
          final aName = a.name ?? '';
          final bName = b.name ?? '';
          return aName.compareTo(bName);
        });
        break;

      case 'saved_at':
      case 'created_at':
      default:
        sortedList.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.now();
          final bDate = b.createdAt ?? DateTime.now();
          return bDate.compareTo(aDate); // Más recientes primero
        });
        break;
    }

    return sortedList;
  }

  /// Obtiene el ID del usuario actual
  Future<String?> _getCurrentUserId() async {
    try {
      final user = await _userRepository.getCurrentUser();
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('timeout')) {
      return 'La solicitud tardó demasiado. Intenta de nuevo.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para acceder a las rutas.';
    } else {
      return 'Error al cargar rutas guardadas: ${error.toString()}';
    }
  }
}

/// Estadísticas de rutas guardadas
class SavedRoutesStats {
  final int totalSaved;
  final int totalCreated;
  final Map<String, int> byDifficulty;
  final Map<String, int> byType;
  final double totalDistance;
  final double averageDistance;
  final RouteModel? longestRoute;
  final RouteModel? shortestRoute;

  SavedRoutesStats({
    required this.totalSaved,
    required this.totalCreated,
    required this.byDifficulty,
    required this.byType,
    required this.totalDistance,
    required this.averageDistance,
    this.longestRoute,
    this.shortestRoute,
  });

  /// Obtiene la dificultad más común
  String getMostCommonDifficulty() {
    if (byDifficulty.isEmpty) return 'N/A';

    var maxEntry = byDifficulty.entries.first;
    for (final entry in byDifficulty.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  /// Obtiene el tipo más común
  String getMostCommonType() {
    if (byType.isEmpty) return 'N/A';

    var maxEntry = byType.entries.first;
    for (final entry in byType.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSaved': totalSaved,
      'totalCreated': totalCreated,
      'byDifficulty': byDifficulty,
      'byType': byType,
      'totalDistance': totalDistance,
      'averageDistance': averageDistance,
      'longestRoute': longestRoute?.toJson(),
      'shortestRoute': shortestRoute?.toJson(),
      'mostCommonDifficulty': getMostCommonDifficulty(),
      'mostCommonType': getMostCommonType(),
    };
  }

  /// Obtiene un resumen en texto
  String getSummary() {
    return '''
Total de rutas guardadas: $totalSaved
Total de rutas creadas: $totalCreated
Distancia total: ${totalDistance.toStringAsFixed(1)} km
Distancia promedio: ${averageDistance.toStringAsFixed(1)} km
Dificultad más común: ${getMostCommonDifficulty()}
Tipo más común: ${getMostCommonType()}
''';
  }
}
