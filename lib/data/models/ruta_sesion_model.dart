/// Modelo de Ruta Compartida en Sesión
///
/// Representa la ruta que el líder comparte con los participantes
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RutaSesionModel {
  final String id;
  final String sesionId;
  final LatLng destino;
  final String? destinoNombre;
  final String compartidaPor;
  final DateTime fechaCompartida;
  final DateTime createdAt;

  const RutaSesionModel({
    required this.id,
    required this.sesionId,
    required this.destino,
    this.destinoNombre,
    required this.compartidaPor,
    required this.fechaCompartida,
    required this.createdAt,
  });

  /// Factory desde JSON
  factory RutaSesionModel.fromJson(Map<String, dynamic> json) {
    return RutaSesionModel(
      id: json['id'] as String,
      sesionId: json['sesion_id'] as String,
      destino: LatLng(
        json['destino_lat'] as double,
        json['destino_lng'] as double,
      ),
      destinoNombre: json['destino_nombre'] as String?,
      compartidaPor: json['compartida_por'] as String,
      fechaCompartida: DateTime.parse(json['fecha_compartida'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sesion_id': sesionId,
      'destino_lat': destino.latitude,
      'destino_lng': destino.longitude,
      'destino_nombre': destinoNombre,
      'compartida_por': compartidaPor,
      'fecha_compartida': fechaCompartida.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copiar con cambios
  RutaSesionModel copyWith({
    String? id,
    String? sesionId,
    LatLng? destino,
    String? destinoNombre,
    String? compartidaPor,
    DateTime? fechaCompartida,
    DateTime? createdAt,
  }) {
    return RutaSesionModel(
      id: id ?? this.id,
      sesionId: sesionId ?? this.sesionId,
      destino: destino ?? this.destino,
      destinoNombre: destinoNombre ?? this.destinoNombre,
      compartidaPor: compartidaPor ?? this.compartidaPor,
      fechaCompartida: fechaCompartida ?? this.fechaCompartida,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RutaSesionModel('
        'id: $id, '
        'destino: ${destinoNombre ?? destino.toString()}, '
        'compartidaPor: $compartidaPor'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RutaSesionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
