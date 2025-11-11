import 'package:dartz/dartz.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/route_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Use case para eliminar rutas
///
/// Puede eliminar una ruta creada por el usuario o
/// remover una ruta de los favoritos
class DeleteRouteUseCase {
  final RouteRepository _routeRepository;
  final UserRepository _userRepository;

  DeleteRouteUseCase(this._routeRepository, this._userRepository);

  /// Elimina una ruta creada por el usuario
  ///
  /// [routeId] - ID de la ruta a eliminar
  /// [userId] - ID del usuario (opcional, usa el usuario actual)
  ///
  /// Retorna [Right] con true si se eliminó correctamente
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, bool>> deleteOwnRoute({
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

      // Verificar que el usuario es el creador de la ruta
      if (route.creatorId != currentUserId) {
        return const Left('Solo el creador puede eliminar esta ruta');
      }

      // Validar si la ruta puede ser eliminada
      final canDelete = await _canDeleteRoute(route);
      if (!canDelete.isRight()) {
        return canDelete;
      }

      // Eliminar la ruta
      await _routeRepository.deleteRoute(routeId);

      // Notificar a usuarios que tenían la ruta guardada (opcional)
      await _notifySavedUsers(route);

      return const Right(true);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Remueve una ruta de los favoritos del usuario
  ///
  /// [routeId] - ID de la ruta a remover de favoritos
  /// [userId] - ID del usuario (opcional, usa el usuario actual)
  ///
  /// Retorna [Right] con true si se removió correctamente
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, bool>> removeFromFavorites({
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

      // Verificar que la ruta está en favoritos
      final isSaved = await _routeRepository.isRouteSavedByUser(
        routeId,
        currentUserId,
      );

      if (!isSaved) {
        return const Left('Esta ruta no está en tus favoritos');
      }

      // Remover de favoritos
      await _routeRepository.removeRouteFromUserFavorites(
        routeId,
        currentUserId,
      );

      return const Right(true);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Elimina múltiples rutas a la vez
  ///
  /// [routeIds] - Lista de IDs de rutas a eliminar
  /// [onlyFavorites] - Si true, solo remueve de favoritos; si false, elimina las rutas
  ///
  /// Retorna [Right] con el número de rutas eliminadas/removidas
  /// Retorna [Left] con mensaje de error si falla completamente
  Future<Either<String, int>> deleteBulk({
    required List<String> routeIds,
    bool onlyFavorites = false,
  }) async {
    try {
      if (routeIds.isEmpty) {
        return const Left('No se especificaron rutas para eliminar');
      }

      int successCount = 0;
      final errors = <String>[];

      for (final routeId in routeIds) {
        Either<String, bool> result;

        if (onlyFavorites) {
          result = await removeFromFavorites(routeId: routeId);
        } else {
          result = await deleteOwnRoute(routeId: routeId);
        }

        result.fold(
          (error) => errors.add('$routeId: $error'),
          (_) => successCount++,
        );
      }

      if (successCount == 0) {
        return Left('No se pudo eliminar ninguna ruta: ${errors.join(", ")}');
      }

      if (errors.isNotEmpty && successCount < routeIds.length) {
        // Algunas fallaron
        return Right(successCount);
      }

      return Right(successCount);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Desactiva una ruta en lugar de eliminarla (soft delete)
  ///
  /// Útil para mantener historial pero hacerla no visible
  Future<Either<String, bool>> deactivateRoute({
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

      // Verificar que la ruta existe
      final route = await _routeRepository.getRouteById(routeId);
      if (route == null) {
        return const Left('Ruta no encontrada');
      }

      // Verificar permisos
      if (route.creatorId != currentUserId) {
        return const Left('Solo el creador puede desactivar esta ruta');
      }

      // Desactivar la ruta
      await _routeRepository.updateRouteStatus(routeId, 'inactive');

      return const Right(true);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Verifica si una ruta puede ser eliminada
  Future<Either<String, bool>> _canDeleteRoute(RouteModel route) async {
    // Verificar si la ruta está siendo usada en eventos activos
    final isUsedInEvents = await _routeRepository.isRouteUsedInActiveEvents(
      route.id,
    );

    if (isUsedInEvents) {
      return const Left(
        'No se puede eliminar. La ruta está siendo usada en eventos activos.',
      );
    }

    // Verificar si tiene muchos usuarios que la guardaron
    // TODO: Implementar conteo de usuarios que guardaron la ruta
    // if (route.savesCount != null && route.savesCount! > 100) {
    //   return const Left(
    //     'Esta ruta es muy popular. Considera desactivarla en lugar de eliminarla.',
    //   );
    // }

    return const Right(true);
  }

  /// Notifica a usuarios que tenían la ruta guardada
  Future<void> _notifySavedUsers(RouteModel route) async {
    try {
      // Aquí se implementaría la lógica de notificaciones
      // Por ejemplo, enviar notificación push o email a usuarios afectados

      // TODO: Implementar sistema de notificaciones
      // if (route.savesCount != null && route.savesCount! > 0) {
      //   await _notificationService.notifyRouteDeleted(
      //     routeId: route.id!,
      //     routeName: route.name,
      //   );
      // }
    } catch (e) {
      // No fallar si la notificación falla
      // Error al notificar usuarios
    }
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

  /// Obtiene estadísticas antes de eliminar (para confirmación)
  Future<Either<String, RouteDeleteStats>> getDeleteStats({
    required String routeId,
  }) async {
    try {
      final route = await _routeRepository.getRouteById(routeId);
      if (route == null) {
        return const Left('Ruta no encontrada');
      }

      final usersCount = route.savesCount ?? 0;
      final isUsedInEvents = await _routeRepository.isRouteUsedInActiveEvents(
        routeId,
      );

      final stats = RouteDeleteStats(
        routeName: route.name ?? 'Sin nombre',
        savedByUsersCount: usersCount,
        isUsedInActiveEvents: isUsedInEvents,
        canBeDeleted: !isUsedInEvents,
        recommendSoftDelete: usersCount > 100 || isUsedInEvents,
      );

      return Right(stats);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para eliminar esta ruta.';
    } else if (error.toString().contains('not found')) {
      return 'La ruta no existe o ya fue eliminada.';
    } else if (error.toString().contains('in use')) {
      return 'No se puede eliminar. La ruta está en uso.';
    } else {
      return 'Error al eliminar ruta: ${error.toString()}';
    }
  }
}

/// Estadísticas de eliminación de ruta
class RouteDeleteStats {
  final String routeName;
  final int savedByUsersCount;
  final bool isUsedInActiveEvents;
  final bool canBeDeleted;
  final bool recommendSoftDelete;

  RouteDeleteStats({
    required this.routeName,
    required this.savedByUsersCount,
    required this.isUsedInActiveEvents,
    required this.canBeDeleted,
    required this.recommendSoftDelete,
  });

  /// Obtiene un mensaje de advertencia
  String getWarningMessage() {
    if (isUsedInActiveEvents) {
      return 'Esta ruta está siendo usada en eventos activos y no puede ser eliminada.';
    } else if (savedByUsersCount > 100) {
      return 'Esta ruta ha sido guardada por $savedByUsersCount usuarios. '
          'Considera desactivarla en lugar de eliminarla permanentemente.';
    } else if (savedByUsersCount > 0) {
      return 'Esta ruta ha sido guardada por $savedByUsersCount usuario(s).';
    } else {
      return 'Esta ruta puede ser eliminada sin afectar a otros usuarios.';
    }
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'savedByUsersCount': savedByUsersCount,
      'isUsedInActiveEvents': isUsedInActiveEvents,
      'canBeDeleted': canBeDeleted,
      'recommendSoftDelete': recommendSoftDelete,
      'warningMessage': getWarningMessage(),
    };
  }
}
