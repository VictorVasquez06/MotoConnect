/// RoutesBloc - Gestión de estado de rutas
///
/// Implementa la lógica de negocio para rutas usando BLoC pattern.
/// Depende de IRouteRepository para abstracción de datos.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_route_repository.dart';
import 'routes_event.dart';
import 'routes_state.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final IRouteRepository routeRepository;

  RoutesBloc({required this.routeRepository}) : super(const RoutesInitial()) {
    on<RoutesFetchRequested>(_onFetchRequested);
    on<RoutesFetchRecentRequested>(_onFetchRecentRequested);
    on<RoutesFetchSavedRequested>(_onFetchSavedRequested);
    on<RoutesCreateRequested>(_onCreateRequested);
    on<RoutesUpdateRequested>(_onUpdateRequested);
    on<RoutesDeleteRequested>(_onDeleteRequested);
    on<RoutesSaveToFavoritesRequested>(_onSaveToFavoritesRequested);
    on<RoutesRemoveFromFavoritesRequested>(_onRemoveFromFavoritesRequested);
    on<RoutesSearchRequested>(_onSearchRequested);
    on<RoutesLoadDetailsRequested>(_onLoadDetailsRequested);
    on<RoutesFetchByLocationRequested>(_onFetchByLocationRequested);
  }

  /// Carga rutas del usuario
  Future<void> _onFetchRequested(
    RoutesFetchRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final routes = await routeRepository.getUserRoutes(event.userId);
      emit(RoutesLoaded(routes: routes, filterType: 'user'));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga rutas recientes
  Future<void> _onFetchRecentRequested(
    RoutesFetchRecentRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final routes = await routeRepository.getRecentRoutes(limit: event.limit);
      emit(RoutesLoaded(routes: routes, filterType: 'recent'));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga rutas guardadas/favoritas
  Future<void> _onFetchSavedRequested(
    RoutesFetchSavedRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final routes = await routeRepository.getSavedRoutesForUser(event.userId);
      emit(RoutesLoaded(routes: routes, filterType: 'saved'));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Crea una nueva ruta
  Future<void> _onCreateRequested(
    RoutesCreateRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      await routeRepository.createRoute(
        userId: event.userId,
        nombreRuta: event.nombreRuta,
        descripcionRuta: event.descripcionRuta,
        puntos: event.puntos,
        distanciaKm: event.distanciaKm,
        duracionMinutos: event.duracionMinutos,
        imagenUrl: event.imagenUrl,
      );
      emit(
        const RoutesOperationSuccess(
          message: 'Ruta creada exitosamente',
          operationType: RoutesOperationType.created,
        ),
      );
      // Recargar rutas del usuario
      add(RoutesFetchRequested(userId: event.userId));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Actualiza una ruta existente
  Future<void> _onUpdateRequested(
    RoutesUpdateRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      await routeRepository.updateRoute(
        routeId: event.routeId,
        nombreRuta: event.nombreRuta,
        descripcionRuta: event.descripcionRuta,
        puntos: event.puntos,
        distanciaKm: event.distanciaKm,
        duracionMinutos: event.duracionMinutos,
        imagenUrl: event.imagenUrl,
      );
      emit(
        const RoutesOperationSuccess(
          message: 'Ruta actualizada exitosamente',
          operationType: RoutesOperationType.updated,
        ),
      );
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Elimina una ruta
  Future<void> _onDeleteRequested(
    RoutesDeleteRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      await routeRepository.deleteRoute(event.routeId);
      emit(
        const RoutesOperationSuccess(
          message: 'Ruta eliminada exitosamente',
          operationType: RoutesOperationType.deleted,
        ),
      );
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Guarda ruta en favoritos
  Future<void> _onSaveToFavoritesRequested(
    RoutesSaveToFavoritesRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      await routeRepository.saveRouteForUser(event.routeId, event.userId);
      emit(
        const RoutesOperationSuccess(
          message: 'Ruta guardada en favoritos',
          operationType: RoutesOperationType.savedToFavorites,
        ),
      );
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Elimina ruta de favoritos
  Future<void> _onRemoveFromFavoritesRequested(
    RoutesRemoveFromFavoritesRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      await routeRepository.removeRouteFromUserFavorites(
        event.routeId,
        event.userId,
      );
      emit(
        const RoutesOperationSuccess(
          message: 'Ruta eliminada de favoritos',
          operationType: RoutesOperationType.removedFromFavorites,
        ),
      );
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Busca rutas
  Future<void> _onSearchRequested(
    RoutesSearchRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final routes = await routeRepository.searchRoutes(
        event.query,
        userId: event.userId,
      );
      emit(RoutesLoaded(routes: routes, filterType: 'search'));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Carga detalles de una ruta específica
  Future<void> _onLoadDetailsRequested(
    RoutesLoadDetailsRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final route = await routeRepository.getRouteById(event.routeId);
      if (route == null) {
        emit(const RoutesError(message: 'Ruta no encontrada'));
        return;
      }
      emit(RoutesDetailLoaded(route: route));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Busca rutas por ubicación
  Future<void> _onFetchByLocationRequested(
    RoutesFetchByLocationRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());
    try {
      final routes = await routeRepository.getRoutesByLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      emit(RoutesLoaded(routes: routes, filterType: 'location'));
    } catch (e) {
      emit(RoutesError(message: _parseErrorMessage(e)));
    }
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('permission denied')) {
      return 'No tienes permiso para realizar esta acción';
    } else if (message.contains('not found')) {
      return 'Ruta no encontrada';
    } else if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (message.contains('already exists')) {
      return 'Ya existe una ruta con ese nombre';
    }
    return 'Error: $message';
  }
}
