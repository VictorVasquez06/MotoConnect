/// Modelos para detalles de talleres
///
/// Este archivo contiene los modelos utilizados para representar
/// información detallada de talleres, incluyendo horarios, servicios y reseñas.
library;

/// Modelo para representar el horario de un taller
class TallerSchedule {
  final String day;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  TallerSchedule({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  factory TallerSchedule.fromJson(Map<String, dynamic> json) {
    return TallerSchedule(
      day: json['day'] as String? ?? json['dia'] as String? ?? '',
      openTime: json['open_time'] as String? ?? json['hora_apertura'] as String? ?? '',
      closeTime: json['close_time'] as String? ?? json['hora_cierre'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? json['abierto'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'open_time': openTime,
      'close_time': closeTime,
      'is_open': isOpen,
    };
  }
}

/// Modelo para representar un servicio del taller
class TallerService {
  final String id;
  final String name;
  final String description;
  final double price;
  final int estimatedDuration; // en minutos

  TallerService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.estimatedDuration,
  });

  factory TallerService.fromJson(Map<String, dynamic> json) {
    return TallerService(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['nombre'] as String? ?? '',
      description: json['description'] as String? ?? json['descripcion'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? (json['precio'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: json['estimated_duration'] as int? ?? json['duracion_estimada'] as int? ?? 0,
    );
  }

  /// Factory para crear desde String (para compatibilidad)
  factory TallerService.fromString(String name) {
    return TallerService(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      description: '',
      price: 0.0,
      estimatedDuration: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'estimated_duration': estimatedDuration,
    };
  }
}

/// Modelo para representar una reseña del taller
class TallerReview {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images;

  TallerReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
  });

  factory TallerReview.fromJson(Map<String, dynamic> json) {
    return TallerReview(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['usuario_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? json['nombre_usuario'] as String? ?? '',
      userAvatar: json['user_avatar'] as String? ?? json['avatar_usuario'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? json['comentario'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['fecha_creacion'] != null
              ? DateTime.parse(json['fecha_creacion'] as String)
              : DateTime.now(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : json['imagenes'] != null
              ? List<String>.from(json['imagenes'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'images': images,
    };
  }
}

/// Modelo para representar una calificación de un taller
class TallerRating {
  final String id;
  final String tallerId;
  final String userId;
  final String userName;
  final int rating; // 1-5 estrellas
  final String? comment;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, int>? categoryRatings; // {calidad: 5, atencion: 4, ...}

  TallerRating({
    required this.id,
    required this.tallerId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    this.images,
    required this.createdAt,
    this.updatedAt,
    this.categoryRatings,
  });

  factory TallerRating.fromJson(Map<String, dynamic> json) {
    return TallerRating(
      id: json['id'] as String,
      tallerId: json['taller_id'] as String,
      userId: json['user_id'] as String? ?? json['usuario_id'] as String,
      userName: json['user_name'] as String? ?? json['nombre_usuario'] as String? ?? '',
      rating: json['rating'] as int? ?? json['calificacion'] as int? ?? 0,
      comment: json['comment'] as String? ?? json['comentario'] as String?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      categoryRatings: json['category_ratings'] != null
          ? Map<String, int>.from(json['category_ratings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taller_id': tallerId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'category_ratings': categoryRatings,
    };
  }
}
