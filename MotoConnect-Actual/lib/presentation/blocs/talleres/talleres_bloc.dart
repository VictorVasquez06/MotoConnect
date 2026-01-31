/// TalleresBloc - Gestión de estado de talleres mecánicos
///
/// Implementa la lógica de negocio para talleres usando BLoC pattern.
/// Depende de ITallerRepository para abstracción de datos.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_taller_repository.dart';
import '../../../data/models/taller_model.dart';
import 'talleres_event.dart';
import 'talleres_state.dart';

class TalleresBloc extends Bloc<TalleresEvent, TalleresState> {
  final ITallerRepository tallerRepository;

  TalleresBloc({required this.tallerRepository})
    : super(const TalleresInitial()) {
    on<TalleresFetchRequested>(_onFetchRequested);
    on<TalleresSearchRequested>(_onSearchRequested);
    on<TalleresLoadDetail>(_onLoadDetail);
    on<TalleresFetchNearby>(_onFetchNearby);
    on<TalleresRefreshRequested>(_onRefreshRequested);
    on<TalleresClearSelection>(_onClearSelection);
  }

  /// Carga la lista de talleres
  Future<void> _onFetchRequested(
    TalleresFetchRequested event,
    Emitter<TalleresState> emit,
  ) async {
    emit(const TalleresLoading());
    try {
      final talleres = await tallerRepository.getTalleres();
      emit(TalleresLoaded(talleres: talleres));
    } catch (e) {
      emit(TalleresError(message: _parseErrorMessage(e)));
    }
  }

  /// Busca talleres por query
  Future<void> _onSearchRequested(
    TalleresSearchRequested event,
    Emitter<TalleresState> emit,
  ) async {
    final currentState = state;
    final currentTalleres = _getCurrentTalleres(currentState);

    if (event.query.isEmpty) {
      // Si el query está vacío, recargar todos
      emit(const TalleresLoading());
      try {
        final talleres = await tallerRepository.getTalleres();
        emit(TalleresLoaded(talleres: talleres));
      } catch (e) {
        emit(
          TalleresError(
            message: _parseErrorMessage(e),
            previousTalleres: currentTalleres,
          ),
        );
      }
      return;
    }

    emit(const TalleresLoading());
    try {
      final talleres = await tallerRepository.searchTalleres(event.query);
      emit(TalleresLoaded(talleres: talleres));
    } catch (e) {
      emit(
        TalleresError(
          message: _parseErrorMessage(e),
          previousTalleres: currentTalleres,
        ),
      );
    }
  }

  /// Carga el detalle de un taller específico
  Future<void> _onLoadDetail(
    TalleresLoadDetail event,
    Emitter<TalleresState> emit,
  ) async {
    final currentState = state;
    final currentTalleres = _getCurrentTalleres(currentState);

    emit(TalleresLoadingDetail(talleres: currentTalleres));

    try {
      final taller = await tallerRepository.getTallerById(event.tallerId);
      if (taller != null) {
        emit(TalleresLoaded(talleres: currentTalleres, selectedTaller: taller));
      } else {
        emit(
          TalleresError(
            message: 'Taller no encontrado',
            previousTalleres: currentTalleres,
          ),
        );
      }
    } catch (e) {
      emit(
        TalleresError(
          message: _parseErrorMessage(e),
          previousTalleres: currentTalleres,
        ),
      );
    }
  }

  /// Carga talleres cercanos a una ubicación
  Future<void> _onFetchNearby(
    TalleresFetchNearby event,
    Emitter<TalleresState> emit,
  ) async {
    emit(const TalleresLoading());
    try {
      final talleres = await tallerRepository.getTalleresNearby(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      emit(TalleresLoaded(talleres: talleres));
    } catch (e) {
      emit(TalleresError(message: _parseErrorMessage(e)));
    }
  }

  /// Refresca la lista de talleres
  Future<void> _onRefreshRequested(
    TalleresRefreshRequested event,
    Emitter<TalleresState> emit,
  ) async {
    final currentState = state;
    if (currentState is TalleresLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      final talleres = await tallerRepository.getTalleres();
      final selectedTaller =
          currentState is TalleresLoaded ? currentState.selectedTaller : null;
      emit(TalleresLoaded(talleres: talleres, selectedTaller: selectedTaller));
    } catch (e) {
      final previousTalleres =
          currentState is TalleresLoaded ? currentState.talleres : null;
      emit(
        TalleresError(
          message: _parseErrorMessage(e),
          previousTalleres: previousTalleres,
        ),
      );
    }
  }

  /// Limpia el taller seleccionado
  void _onClearSelection(
    TalleresClearSelection event,
    Emitter<TalleresState> emit,
  ) {
    final currentState = state;
    if (currentState is TalleresLoaded) {
      emit(currentState.copyWith(clearSelection: true));
    }
  }

  /// Helper para obtener los talleres actuales del estado
  List<TallerModel> _getCurrentTalleres(TalleresState state) {
    if (state is TalleresLoaded) return state.talleres;
    if (state is TalleresLoadingDetail) return state.talleres;
    if (state is TalleresError) return state.previousTalleres ?? [];
    return [];
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (message.contains('not found')) {
      return 'Taller no encontrado';
    }
    return 'Error al cargar talleres: $message';
  }
}
