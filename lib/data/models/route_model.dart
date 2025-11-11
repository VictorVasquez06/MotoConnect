/// Modelo de Ruta
///
/// Representa los datos de una ruta guardada en la aplicación
///
/// Este modelo es inmutable (final fields) y tiene:
/// - Constructor
/// - fromJson para deserialización
/// - toJson para serialización
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  /// ID único de la ruta (UUID de Supabase)
  final String id;

  /// ID del usuario que creó la ruta
  final String userId;

  /// Nombre de la ruta
  final String nombreRuta;

  /// Descripción de la ruta (opcional)
  final String? descripcionRuta;

  /// Fecha en que se realizó la ruta
  final DateTime fecha;

  /// Puntos GPS de la ruta (latitud, longitud)
  final List<LatLng> puntos;

  /// Distancia total en kilómetros
  final double? distanciaKm;

  /// Duración en minutos
  final int? duracionMinutos;

  /// URL de la imagen asociada (opcional)
  final String? imagenUrl;

  /// ID del creador de la ruta (alias de userId)
  final String? creatorId;

  /// Nombre del creador de la ruta
  final String? creatorName;

  /// Duración estimada en horas (alias de duracionMinutos)
  final double? estimatedDuration;

  /// Punto de inicio
  final String? startPoint;

  /// Punto final
  final String? endPoint;

  /// Tipo de camino (carretera, montaña, ciudad, etc.)
  final String? roadType;

  /// Valor escénico (1-5)
  final int? scenicValue;

  /// Puntos de interés/paradas en la ruta
  final List<Map<String, dynamic>>? waypoints;

  /// Constructor
  const RouteModel({
    required this.id,
    required this.userId,
    required this.nombreRuta,
    this.descripcionRuta,
    required this.fecha,
    required this.puntos,
    this.distanciaKm,
    this.duracionMinutos,
    this.imagenUrl,
    this.creatorId,
    this.creatorName,
    this.estimatedDuration,
    this.startPoint,
    this.endPoint,
    this.roadType,
    this.scenicValue,
    this.waypoints,
  });

  /// Crea una instancia desde JSON
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Parsear puntos desde JSON
    List<LatLng> parsedPuntos = [];
    if (json['puntos'] != null) {
      final List<dynamic> puntosJson = json['puntos'] as List<dynamic>;
      parsedPuntos =
          puntosJson.map((punto) {
            if (punto is Map) {
              final lat = (punto['lat'] as num).toDouble();
              final lng = (punto['lng'] as num).toDouble();
              return LatLng(lat, lng);
            }
            throw Exception('Formato de punto inválido');
          }).toList();
    }

    return RouteModel(
      id: json['id'] as String,
      userId: json['usuario_id'] as String,
      nombreRuta: json['nombre_ruta'] as String,
      descripcionRuta: json['descripcion_ruta'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      puntos: parsedPuntos,
      distanciaKm:
          json['distancia_km'] != null
              ? (json['distancia_km'] as num).toDouble()
              : null,
      duracionMinutos: json['duracion_minutos'] as int?,
      imagenUrl: json['imagen_url'] as String?,
      creatorId: json['creator_id'] as String? ?? json['usuario_id'] as String?,
      creatorName: json['creator_name'] as String? ?? json['nombre_creador'] as String?,
      estimatedDuration: json['estimated_duration'] != null
          ? (json['estimated_duration'] as num).toDouble()
          : json['duracion_minutos'] != null
              ? (json['duracion_minutos'] as num) / 60.0
              : null,
      startPoint: json['start_point'] as String? ?? json['punto_inicio'] as String?,
      endPoint: json['end_point'] as String? ?? json['punto_fin'] as String?,
      roadType: json['road_type'] as String? ?? json['tipo_camino'] as String?,
      scenicValue: json['scenic_value'] as int? ?? json['valor_escenico'] as int?,
      waypoints: json['waypoints'] != null
          ? List<Map<String, dynamic>>.from(json['waypoints'])
          : json['puntos_interes'] != null
              ? List<Map<String, dynamic>>.from(json['puntos_interes'])
              : null,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': userId,
      'nombre_ruta': nombreRuta,
      'descripcion_ruta': descripcionRuta,
      'fecha': fecha.toIso8601String(),
      'puntos':
          puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'distancia_km': distanciaKm,
      'duracion_minutos': duracionMinutos,
      'imagen_url': imagenUrl,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'estimated_duration': estimatedDuration,
      'start_point': startPoint,
      'end_point': endPoint,
      'road_type': roadType,
      'scenic_value': scenicValue,
      'waypoints': waypoints,
    };
  }

  /// Crea una copia con campos modificados
  RouteModel copyWith({
    String? id,
    String? userId,
    String? nombreRuta,
    String? descripcionRuta,
    DateTime? fecha,
    List<LatLng>? puntos,
    double? distanciaKm,
    int? duracionMinutos,
    String? imagenUrl,
    String? creatorId,
    String? creatorName,
    double? estimatedDuration,
    String? startPoint,
    String? endPoint,
    String? roadType,
    int? scenicValue,
    List<Map<String, dynamic>>? waypoints,
  }) {
    return RouteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombreRuta: nombreRuta ?? this.nombreRuta,
      descripcionRuta: descripcionRuta ?? this.descripcionRuta,
      fecha: fecha ?? this.fecha,
      puntos: puntos ?? this.puntos,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      roadType: roadType ?? this.roadType,
      scenicValue: scenicValue ?? this.scenicValue,
      waypoints: waypoints ?? this.waypoints,
    );
  }

  /// Getters de conveniencia para compatibilidad con diferentes nombres
  String get name => nombreRuta;
  String? get description => descripcionRuta;
  double? get distance => distanciaKm;
  DateTime get createdAt => fecha;

  /// Propiedades calculadas o por defecto
  double? get rating => null; // TODO: Implementar sistema de calificaciones
  int? get savesCount => null; // TODO: Implementar conteo de guardados
  String? get difficulty => null; // TODO: Implementar dificultad
  String? get type => null; // TODO: Implementar tipo de ruta
}
