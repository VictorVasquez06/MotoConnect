/// Representa el modelo de datos para un evento.
///
/// Encapsula toda la información relacionada con un evento,
/// como su título, descripción, fecha y lugar.
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String? organizerId;
  final String? createdBy;
  final List<String>? participants;
  final String? imageUrl;
  final int? maxParticipants;
  final DateTime? createdAt;
  final String? status;
  final bool? requiresApproval;
  final bool? isPublic;
  final String? creatorId;
  final String? time;
  final int? participantsCount;
  final bool? isUserRegistered;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.organizerId,
    this.createdBy,
    this.participants,
    this.imageUrl,
    this.maxParticipants,
    this.createdAt,
    this.status,
    this.requiresApproval,
    this.isPublic,
    this.creatorId,
    this.time,
    this.participantsCount,
    this.isUserRegistered,
  });

  /// Factory constructor para crear una instancia de Event desde un mapa (JSON).
  /// Esto es útil cuando se decodifican datos de una API.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['eventId'] ?? json['id'],
      title: json['titulo'] ?? json['title'],
      description: json['descripcion'] ?? json['description'],
      date: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      location: json['puntoEncuentro'] ?? json['location'] ?? '',
      organizerId: json['organizerId'] ?? json['organizer_id'],
      createdBy: json['createdBy'] ?? json['created_by'],
      participants: json['participants'] != null
          ? List<String>.from(json['participants'])
          : null,
      imageUrl: json['imageUrl'] ?? json['image_url'],
      maxParticipants: json['maxParticipants'] ?? json['max_participants'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      status: json['status'] ?? json['estado'],
      requiresApproval: json['requiresApproval'] ?? json['requires_approval'],
      isPublic: json['isPublic'] ?? json['is_public'],
      creatorId: json['creatorId'] ?? json['creator_id'] ?? json['organizerId'] ?? json['organizer_id'],
      time: json['time'] ?? json['hora'],
      participantsCount: json['participantsCount'] ?? json['participants_count'] ?? (json['participants'] as List?)?.length,
      isUserRegistered: json['isUserRegistered'] ?? json['is_user_registered'],
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'organizerId': organizerId,
      'createdBy': createdBy,
      'participants': participants,
      'imageUrl': imageUrl,
      'maxParticipants': maxParticipants,
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
      'requiresApproval': requiresApproval,
      'isPublic': isPublic,
      'creatorId': creatorId,
      'time': time,
      'participantsCount': participantsCount,
      'isUserRegistered': isUserRegistered,
    };
  }

  /// Copia el modelo con campos modificados
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? organizerId,
    String? createdBy,
    List<String>? participants,
    String? imageUrl,
    int? maxParticipants,
    DateTime? createdAt,
    String? status,
    bool? requiresApproval,
    bool? isPublic,
    String? creatorId,
    String? time,
    int? participantsCount,
    bool? isUserRegistered,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      imageUrl: imageUrl ?? this.imageUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isPublic: isPublic ?? this.isPublic,
      creatorId: creatorId ?? this.creatorId,
      time: time ?? this.time,
      participantsCount: participantsCount ?? this.participantsCount,
      isUserRegistered: isUserRegistered ?? this.isUserRegistered,
    );
  }
}

/// Alias para mantener compatibilidad
typedef EventModel = Event;