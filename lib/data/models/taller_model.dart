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

  /// Email de contacto
  final String? email;

  /// Sitio web
  final String? website;

  /// Calificación promedio
  final double? rating;

  /// Cantidad de reseñas
  final int? reviewsCount;

  /// Indica si el taller está abierto
  final bool? isOpen;

  /// Especialización del taller
  final String? specialization;

  /// Años de experiencia
  final int? yearsExperience;

  /// Descripción del taller
  final String? description;

  /// Lista de servicios ofrecidos
  final List<String>? services;

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
    this.email,
    this.website,
    this.rating,
    this.reviewsCount,
    this.isOpen,
    this.specialization,
    this.yearsExperience,
    this.description,
    this.services,
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
      email: json['email'] as String?,
      website: json['website'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? json['isOpen'] as bool?,
      specialization: json['specialization'] as String? ?? json['especializacion'] as String?,
      yearsExperience: json['years_experience'] as int? ?? json['anios_experiencia'] as int?,
      description: json['description'] as String? ?? json['descripcion'] as String?,
      services: json['services'] != null ? List<String>.from(json['services']) : json['servicios'] != null ? List<String>.from(json['servicios']) : null,
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
      'email': email,
      'website': website,
      'rating': rating,
      'reviews_count': reviewsCount,
      'is_open': isOpen,
      'specialization': specialization,
      'years_experience': yearsExperience,
      'description': description,
      'services': services,
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
    String? email,
    String? website,
    double? rating,
    int? reviewsCount,
    bool? isOpen,
    String? specialization,
    int? yearsExperience,
    String? description,
    List<String>? services,
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
      email: email ?? this.email,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isOpen: isOpen ?? this.isOpen,
      specialization: specialization ?? this.specialization,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      description: description ?? this.description,
      services: services ?? this.services,
    );
  }

  /// Indica si el taller tiene coordenadas GPS
  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Alias en inglés para compatibilidad con el código
  String get name => nombre;
  String? get phone => telefono;
  String? get address => direccion;
  String? get schedule => horario;
  double? get latitude => latitud;
  double? get longitude => longitud;
  String? get imageUrl => null; // TODO: Agregar campo de imagen en el futuro
}
