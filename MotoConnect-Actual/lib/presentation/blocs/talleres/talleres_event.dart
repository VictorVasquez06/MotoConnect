/// Eventos del TalleresBloc
///
/// Define todas las acciones que pueden modificar el estado de talleres.
library;

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos de talleres
abstract class TalleresEvent extends Equatable {
  const TalleresEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de talleres
class TalleresFetchRequested extends TalleresEvent {
  const TalleresFetchRequested();
}

/// Evento para buscar talleres
class TalleresSearchRequested extends TalleresEvent {
  final String query;

  const TalleresSearchRequested({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Evento para cargar el detalle de un taller específico
class TalleresLoadDetail extends TalleresEvent {
  final String tallerId;

  const TalleresLoadDetail({required this.tallerId});

  @override
  List<Object?> get props => [tallerId];
}

/// Evento para cargar talleres cercanos
class TalleresFetchNearby extends TalleresEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const TalleresFetchNearby({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

/// Evento para refrescar la lista de talleres
class TalleresRefreshRequested extends TalleresEvent {
  const TalleresRefreshRequested();
}

/// Evento para limpiar el taller seleccionado
class TalleresClearSelection extends TalleresEvent {
  const TalleresClearSelection();
}
