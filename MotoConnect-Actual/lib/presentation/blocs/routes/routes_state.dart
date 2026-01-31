/// Estados del RoutesBloc
///
/// Define todos los posibles estados de la gestión de rutas.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/route_model.dart';

/// Clase base abstracta para todos los estados de Routes
abstract class RoutesState extends Equatable {
  const RoutesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar rutas
class RoutesInitial extends RoutesState {
  const RoutesInitial();
}

/// Estado de carga durante operaciones
class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

/// Estado con lista de rutas cargada exitosamente
class RoutesLoaded extends RoutesState {
  final List<RouteModel> routes;
  final String? filterType; // 'user', 'recent', 'saved', 'search', 'location'

  const RoutesLoaded({required this.routes, this.filterType});

  @override
  List<Object?> get props => [routes, filterType];

  /// Crea una copia con rutas actualizadas
  RoutesLoaded copyWith({List<RouteModel>? routes, String? filterType}) {
    return RoutesLoaded(
      routes: routes ?? this.routes,
      filterType: filterType ?? this.filterType,
    );
  }
}

/// Estado con detalles de una ruta específica
class RoutesDetailLoaded extends RoutesState {
  final RouteModel route;
  final bool isSavedByUser;

  const RoutesDetailLoaded({required this.route, this.isSavedByUser = false});

  @override
  List<Object?> get props => [route, isSavedByUser];
}

/// Estado de error en operaciones de rutas
class RoutesError extends RoutesState {
  final String message;

  const RoutesError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado de operación exitosa (crear, actualizar, eliminar, favoritos)
class RoutesOperationSuccess extends RoutesState {
  final String message;
  final RoutesOperationType operationType;

  const RoutesOperationSuccess({
    required this.message,
    required this.operationType,
  });

  @override
  List<Object?> get props => [message, operationType];
}

/// Tipos de operaciones exitosas
enum RoutesOperationType {
  created,
  updated,
  deleted,
  savedToFavorites,
  removedFromFavorites,
}
