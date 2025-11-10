import 'package:dartz/dartz.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/route_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Use case para guardar una ruta
/// 
/// Puede ser para crear una nueva ruta o guardar una ruta existente
/// como favorita del usuario
class SaveRouteUseCase {
  final RouteRepository _routeRepository;
  final UserRepository _userRepository;

  SaveRouteUseCase(
    this._routeRepository,
    this._userRepository,
  );

  /// Crea una nueva ruta desde cero
  /// 
  /// [routeData] - Mapa con los datos de la ruta
  /// Campos requeridos:
  /// - name: String
  /// - description: String
  /// - startPoint: Map<String, double> {'lat': ..., 'lng': ...}
  /// - endPoint: Map<String, double> {'lat': ..., 'lng': ...}
  /// - waypoints: List<Map<String, double>> (opcional)
  /// - distance: double (km)
  /// - difficulty: String
  /// - type: String
  /// 
  /// Retorna [Right] con la ruta creada si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, RouteModel>> createRoute({
    required Map<String, dynamic> routeData,
  }) async {
    try {
      // Validar datos de la ruta
      final validationResult = _validateRouteData(routeData);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Obtener usuario actual
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser == null) {
        return const Left('Usuario no autenticado');
      }

      // Aplicar reglas de negocio
      final processedData = _applyBusinessRules(routeData, currentUser.id);

      // Crear ruta en el repositorio
      final route = await _routeRepository.createRoute(processedData);

      return Right(route);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Guarda una ruta existente como favorita
  /// 
  /// [routeId] - ID de la ruta a guardar
  /// [userId] - ID del usuario (opcional, usa el usuario actual)
  /// 
  /// Retorna [Right] con la ruta guardada si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, RouteModel>> saveAsFavorite({
    required String routeId,
    String? userId,
  }) async {
    try {
      // Validar ID de la ruta
      if (routeId.isEmpty) {
        return const Left('ID de ruta inválido');
      }

      // Obtener ID del usuario actual si no se proporciona
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        return const Left('Usuario no autenticado');
      }

      // Verificar que la ruta existe
      final route = await _routeRepository.getRouteById(routeId);
      if (route == null) {
        return const Left('Ruta no encontrada');
      }

      // Verificar que no esté ya guardada
      final isAlreadySaved = await _routeRepository.isRouteSavedByUser(
        routeId: routeId,
        userId: currentUserId,
      );

      if (isAlreadySaved) {
        return const Left('Esta ruta ya está en tus favoritos');
      }

      // Guardar ruta como favorita
      final savedRoute = await _routeRepository.saveRouteForUser(
        routeId: routeId,
        userId: currentUserId,
      );

      return Right(savedRoute);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Clona una ruta existente para crear una versión personalizada
  /// 
  /// [routeId] - ID de la ruta a clonar
  /// [modifications] - Modificaciones opcionales a aplicar
  Future<Either<String, RouteModel>> cloneRoute({
    required String routeId,
    Map<String, dynamic>? modifications,
  }) async {
    try {
      // Obtener la ruta original
      final originalRoute = await _routeRepository.getRouteById(routeId);
      if (originalRoute == null) {
        return const Left('Ruta original no encontrada');
      }

      // Obtener usuario actual
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser == null) {
        return const Left('Usuario no autenticado');
      }

      // Crear datos para la nueva ruta
      final routeData = originalRoute.toJson();
      routeData['name'] = '${routeData['name']} (Copia)';
      routeData['creatorId'] = currentUser.id;
      routeData.remove('id'); // Remover ID para crear nueva

      // Aplicar modificaciones si existen
      if (modifications != null) {
        routeData.addAll(modifications);
      }

      // Validar los datos modificados
      final validationResult = _validateRouteData(routeData);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Crear la nueva ruta
      final newRoute = await _routeRepository.createRoute(routeData);

      return Right(newRoute);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Valida los datos de la ruta antes de crearla
  String? _validateRouteData(Map<String, dynamic> data) {
    // Validar nombre
    final name = data['name'] as String?;
    if (name == null || name.isEmpty) {
      return 'El nombre de la ruta es requerido';
    }
    if (name.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (name.length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }

    // Validar descripción
    final description = data['description'] as String?;
    if (description == null || description.isEmpty) {
      return 'La descripción es requerida';
    }
    if (description.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    // Validar punto de inicio
    final startPoint = data['startPoint'];
    if (startPoint == null) {
      return 'El punto de inicio es requerido';
    }
    final startValidation = _validateCoordinate(startPoint, 'inicio');
    if (startValidation != null) return startValidation;

    // Validar punto final
    final endPoint = data['endPoint'];
    if (endPoint == null) {
      return 'El punto final es requerido';
    }
    final endValidation = _validateCoordinate(endPoint, 'final');
    if (endValidation != null) return endValidation;

    // Validar waypoints si existen
    final waypoints = data['waypoints'] as List?;
    if (waypoints != null && waypoints.isNotEmpty) {
      if (waypoints.length > 50) {
        return 'No se pueden tener más de 50 puntos intermedios';
      }
      for (var i = 0; i < waypoints.length; i++) {
        final wpValidation = _validateCoordinate(
          waypoints[i],
          'intermedio ${i + 1}',
        );
        if (wpValidation != null) return wpValidation;
      }
    }

    // Validar distancia
    final distance = data['distance'];
    if (distance == null) {
      return 'La distancia es requerida';
    }
    if (distance is! double && distance is! int) {
      return 'La distancia debe ser un número';
    }
    if ((distance as num) <= 0) {
      return 'La distancia debe ser mayor a 0';
    }
    if (distance > 2000) {
      return 'La distancia no puede exceder 2000 km';
    }

    // Validar dificultad
    final difficulty = data['difficulty'] as String?;
    if (difficulty == null || difficulty.isEmpty) {
      return 'La dificultad es requerida';
    }
    final validDifficulties = ['fácil', 'moderada', 'difícil'];
    if (!validDifficulties.contains(difficulty.toLowerCase())) {
      return 'Dificultad inválida. Debe ser: ${validDifficulties.join(", ")}';
    }

    // Validar tipo
    final type = data['type'] as String?;
    if (type == null || type.isEmpty) {
      return 'El tipo de ruta es requerido';
    }
    final validTypes = ['recreativa', 'deportiva', 'turística', 'técnica'];
    if (!validTypes.contains(type.toLowerCase())) {
      return 'Tipo inválido. Debe ser: ${validTypes.join(", ")}';
    }

    return null;
  }

  /// Valida una coordenada
  String? _validateCoordinate(dynamic coordinate, String pointName) {
    if (coordinate is! Map) {
      return 'Coordenada de punto $pointName inválida';
    }

    final lat = coordinate['lat'] ?? coordinate['latitude'];
    final lng = coordinate['lng'] ?? coordinate['longitude'];

    if (lat == null || lng == null) {
      return 'Coordenadas de punto $pointName incompletas';
    }

    if (lat is! double && lat is! int) {
      return 'Latitud de punto $pointName debe ser un número';
    }

    if (lng is! double && lng is! int) {
      return 'Longitud de punto $pointName debe ser un número';
    }

    if ((lat as num) < -90 || lat > 90) {
      return 'Latitud de punto $pointName inválida (debe estar entre -90 y 90)';
    }

    if ((lng as num) < -180 || lng > 180) {
      return 'Longitud de punto $pointName inválida (debe estar entre -180 y 180)';
    }

    return null;
  }

  /// Aplica reglas de negocio adicionales
  Map<String, dynamic> _applyBusinessRules(
    Map<String, dynamic> data,
    String userId,
  ) {
    final processedData = Map<String, dynamic>.from(data);

    // Establecer el creador
    processedData['creatorId'] = userId;

    // Normalizar dificultad y tipo a minúsculas
    if (processedData['difficulty'] is String) {
      processedData['difficulty'] =
          (processedData['difficulty'] as String).toLowerCase();
    }

    if (processedData['type'] is String) {
      processedData['type'] = (processedData['type'] as String).toLowerCase();
    }

    // Establecer valores por defecto
    processedData['createdAt'] = DateTime.now().toIso8601String();
    processedData['rating'] = processedData['rating'] ?? 0.0;
    processedData['savesCount'] = 0;
    processedData['isPublic'] = processedData['isPublic'] ?? true;
    processedData['status'] = 'active';

    // Calcular duración estimada si no se proporciona
    if (!processedData.containsKey('estimatedDuration')) {
      final distance = processedData['distance'] as num;
      // Velocidad promedio aproximada: 50 km/h
      final hours = distance / 50;
      processedData['estimatedDuration'] = (hours * 60).round(); // en minutos
    }

    return processedData;
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
    if (error.toString().contains('duplicate')) {
      return 'Ya existe una ruta con ese nombre';
    } else if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para guardar rutas.';
    } else if (error.toString().contains('storage')) {
      return 'Error al guardar la ruta. Espacio insuficiente.';
    } else {
      return 'Error al guardar ruta: ${error.toString()}';
    }
  }
}
