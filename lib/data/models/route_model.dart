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
    );
  }
}
