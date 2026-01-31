/// Estados del TalleresBloc
///
/// Define todos los posibles estados de la gestión de talleres.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/taller_model.dart';

/// Clase base abstracta para todos los estados de talleres
abstract class TalleresState extends Equatable {
  const TalleresState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar talleres
class TalleresInitial extends TalleresState {
  const TalleresInitial();
}

/// Estado de carga durante operaciones
class TalleresLoading extends TalleresState {
  const TalleresLoading();
}

/// Estado con talleres cargados exitosamente
class TalleresLoaded extends TalleresState {
  final List<TallerModel> talleres;
  final TallerModel? selectedTaller;
  final bool isRefreshing;

  const TalleresLoaded({
    required this.talleres,
    this.selectedTaller,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [talleres, selectedTaller, isRefreshing];

  /// Crea una copia con campos modificados
  TalleresLoaded copyWith({
    List<TallerModel>? talleres,
    TallerModel? selectedTaller,
    bool? isRefreshing,
    bool clearSelection = false,
  }) {
    return TalleresLoaded(
      talleres: talleres ?? this.talleres,
      selectedTaller:
          clearSelection ? null : (selectedTaller ?? this.selectedTaller),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Estado de carga del detalle de un taller
class TalleresLoadingDetail extends TalleresState {
  final List<TallerModel> talleres;

  const TalleresLoadingDetail({required this.talleres});

  @override
  List<Object?> get props => [talleres];
}

/// Estado de error en operaciones de talleres
class TalleresError extends TalleresState {
  final String message;
  final List<TallerModel>? previousTalleres;

  const TalleresError({required this.message, this.previousTalleres});

  @override
  List<Object?> get props => [message, previousTalleres];
}
