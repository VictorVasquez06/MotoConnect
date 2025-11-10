/// Modelo de Taller
///
/// Representa los datos de un taller mecánico en la aplicación
///
/// Este modelo es inmutable (final fields) y tiene:
/// - Constructor
/// - fromJson para deserialización
/// - toJson para serialización
library;

class TallerModel {
  /// ID único del taller (UUID de Supabase)
  final String id;

  /// Nombre del taller
  final String nombre;

  /// Dirección del taller
  final String? direccion;

  /// Teléfono de contacto
  final String? telefono;

  /// Horario de atención
  final String? horario;

  /// Latitud de ubicación
  final double? latitud;

  /// Longitud de ubicación
  final double? longitud;

  /// ID del usuario que creó el taller
  final String? creadoPor;

  /// Nombre del usuario creador (join con tabla usuarios)
  final String? nombreCreador;

  /// Constructor
  const TallerModel({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.horario,
    this.latitud,
    this.longitud,
    this.creadoPor,
    this.nombreCreador,
  });

  /// Crea una instancia desde JSON
  factory TallerModel.fromJson(Map<String, dynamic> json) {
    // Intentar obtener el nombre del creador del join
    String? nombreCreador;
    if (json['usuarios'] != null && json['usuarios'] is Map) {
      nombreCreador = json['usuarios']['nombre'] as String?;
    }

    return TallerModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      horario: json['horario'] as String?,
      latitud:
          json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud:
          json['longitud'] != null
              ? (json['longitud'] as num).toDouble()
              : null,
      creadoPor: json['creado_por'] as String?,
      nombreCreador: nombreCreador,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'horario': horario,
      'latitud': latitud,
      'longitud': longitud,
      'creado_por': creadoPor,
    };
  }

  /// Crea una copia con campos modificados
  TallerModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? horario,
    double? latitud,
    double? longitud,
    String? creadoPor,
    String? nombreCreador,
  }) {
    return TallerModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      horario: horario ?? this.horario,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      creadoPor: creadoPor ?? this.creadoPor,
      nombreCreador: nombreCreador ?? this.nombreCreador,
    );
  }

  /// Indica si el taller tiene coordenadas GPS
  bool get tieneUbicacion => latitud != null && longitud != null;
}
