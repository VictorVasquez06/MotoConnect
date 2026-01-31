/// Eventos del RoutesBloc
///
/// Define todas las acciones que pueden modificar el estado de rutas.
library;

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Clase base abstracta para todos los eventos de Routes
abstract class RoutesEvent extends Equatable {
  const RoutesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar rutas del usuario
class RoutesFetchRequested extends RoutesEvent {
  final String userId;

  const RoutesFetchRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para cargar rutas recientes de todos los usuarios
class RoutesFetchRecentRequested extends RoutesEvent {
  final int limit;

  const RoutesFetchRecentRequested({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

/// Evento para cargar rutas guardadas/favoritas
class RoutesFetchSavedRequested extends RoutesEvent {
  final String userId;

  const RoutesFetchSavedRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para crear una nueva ruta
class RoutesCreateRequested extends RoutesEvent {
  final String userId;
  final String nombreRuta;
  final String? descripcionRuta;
  final List<LatLng> puntos;
  final double? distanciaKm;
  final int? duracionMinutos;
  final String? imagenUrl;

  const RoutesCreateRequested({
    required this.userId,
    required this.nombreRuta,
    this.descripcionRuta,
    required this.puntos,
    this.distanciaKm,
    this.duracionMinutos,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [
    userId,
    nombreRuta,
    descripcionRuta,
    puntos,
    distanciaKm,
    duracionMinutos,
    imagenUrl,
  ];
}

/// Evento para actualizar una ruta existente
class RoutesUpdateRequested extends RoutesEvent {
  final String routeId;
  final String? nombreRuta;
  final String? descripcionRuta;
  final List<LatLng>? puntos;
  final double? distanciaKm;
  final int? duracionMinutos;
  final String? imagenUrl;

  const RoutesUpdateRequested({
    required this.routeId,
    this.nombreRuta,
    this.descripcionRuta,
    this.puntos,
    this.distanciaKm,
    this.duracionMinutos,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [routeId, nombreRuta, descripcionRuta];
}

/// Evento para eliminar una ruta
class RoutesDeleteRequested extends RoutesEvent {
  final String routeId;

  const RoutesDeleteRequested({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

/// Evento para guardar ruta en favoritos
class RoutesSaveToFavoritesRequested extends RoutesEvent {
  final String routeId;
  final String userId;

  const RoutesSaveToFavoritesRequested({
    required this.routeId,
    required this.userId,
  });

  @override
  List<Object?> get props => [routeId, userId];
}

/// Evento para eliminar ruta de favoritos
class RoutesRemoveFromFavoritesRequested extends RoutesEvent {
  final String routeId;
  final String userId;

  const RoutesRemoveFromFavoritesRequested({
    required this.routeId,
    required this.userId,
  });

  @override
  List<Object?> get props => [routeId, userId];
}

/// Evento para buscar rutas
class RoutesSearchRequested extends RoutesEvent {
  final String query;
  final String? userId;

  const RoutesSearchRequested({required this.query, this.userId});

  @override
  List<Object?> get props => [query, userId];
}

/// Evento para cargar detalles de una ruta específica
class RoutesLoadDetailsRequested extends RoutesEvent {
  final String routeId;

  const RoutesLoadDetailsRequested({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

/// Evento para buscar rutas por ubicación
class RoutesFetchByLocationRequested extends RoutesEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const RoutesFetchByLocationRequested({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}
