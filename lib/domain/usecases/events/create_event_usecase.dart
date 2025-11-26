import 'package:dartz/dartz.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';

/// Use case para crear un nuevo evento
/// 
/// Maneja la lógica de negocio para la creación de eventos,
/// incluyendo validaciones y reglas de negocio
class CreateEventUseCase {
  final EventRepository _eventRepository;

  CreateEventUseCase(this._eventRepository);

  /// Ejecuta el use case para crear un evento
  /// 
  /// [eventData] - Mapa con los datos del evento a crear
  /// Campos requeridos:
  /// - title: String
  /// - description: String
  /// - date: DateTime
  /// - location: String
  /// - category: String
  /// - maxParticipants: int (opcional)
  /// 
  /// Retorna [Right] con el evento creado si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, EventModel>> execute({
    required Map<String, dynamic> eventData,
  }) async {
    try {
      // Validar datos del evento
      final validationResult = _validateEventData(eventData);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Aplicar reglas de negocio
      final processedData = _applyBusinessRules(eventData);

      // Extraer fecha
      DateTime eventDate;
      final date = processedData['date'];
      if (date is String) {
        eventDate = DateTime.parse(date);
      } else if (date is DateTime) {
        eventDate = date;
      } else {
        return const Left('Fecha inválida');
      }

      // Crear evento en el repositorio
      final event = await _eventRepository.createEvent(
        title: processedData['title'] as String,
        description: processedData['description'] as String,
        date: eventDate,
        puntoEncuentro: processedData['punto_encuentro'] as String? ??
                        processedData['puntoEncuentro'] as String? ??
                        processedData['location'] as String? ?? '',
        createdBy: processedData['createdBy'] as String? ??
                   processedData['userId'] as String? ??
                   processedData['organizerId'] as String? ?? '',
        destino: processedData['destino'] as String?,
        puntoEncuentroLat: (processedData['punto_encuentro_lat'] as num?)?.toDouble() ??
                           (processedData['puntoEncuentroLat'] as num?)?.toDouble(),
        puntoEncuentroLng: (processedData['punto_encuentro_lng'] as num?)?.toDouble() ??
                           (processedData['puntoEncuentroLng'] as num?)?.toDouble(),
        destinoLat: (processedData['destino_lat'] as num?)?.toDouble() ??
                    (processedData['destinoLat'] as num?)?.toDouble(),
        destinoLng: (processedData['destino_lng'] as num?)?.toDouble() ??
                    (processedData['destinoLng'] as num?)?.toDouble(),
        fotoUrl: processedData['foto_url'] as String? ??
                 processedData['fotoUrl'] as String?,
        grupoId: processedData['grupo_id'] as String? ??
                 processedData['grupoId'] as String?,
        isPublic: processedData['is_public'] as bool? ??
                  processedData['isPublic'] as bool? ?? true,
      );

      return Right(event);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Crea un evento con un objeto EventModel
  Future<Either<String, EventModel>> createFromModel({
    required EventModel event,
  }) async {
    return execute(
      eventData: event.toJson(),
    );
  }

  /// Valida los datos del evento antes de crearlo
  String? _validateEventData(Map<String, dynamic> data) {
    // Validar título
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      return 'El título es requerido';
    }
    if (title.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    if (title.length > 100) {
      return 'El título no puede exceder 100 caracteres';
    }

    // Validar descripción
    final description = data['description'] as String?;
    if (description == null || description.isEmpty) {
      return 'La descripción es requerida';
    }
    if (description.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    // Validar fecha
    final date = data['date'];
    if (date == null) {
      return 'La fecha es requerida';
    }
    
    DateTime? eventDate;
    if (date is String) {
      eventDate = DateTime.tryParse(date);
    } else if (date is DateTime) {
      eventDate = date;
    }

    if (eventDate == null) {
      return 'Fecha inválida';
    }

    if (eventDate.isBefore(DateTime.now())) {
      return 'La fecha del evento no puede ser en el pasado';
    }

    // Validar ubicación
    final location = data['location'] as String?;
    if (location == null || location.isEmpty) {
      return 'La ubicación es requerida';
    }

    // Validar categoría
    final category = data['category'] as String?;
    if (category == null || category.isEmpty) {
      return 'La categoría es requerida';
    }

    final validCategories = [
      'rally',
      'rodada',
      'encuentro',
      'competencia',
      'mantenimiento',
      'social',
      'otro'
    ];

    if (!validCategories.contains(category.toLowerCase())) {
      return 'Categoría inválida. Debe ser una de: ${validCategories.join(", ")}';
    }

    // Validar máximo de participantes (opcional)
    final maxParticipants = data['maxParticipants'];
    if (maxParticipants != null) {
      if (maxParticipants is! int || maxParticipants <= 0) {
        return 'El máximo de participantes debe ser un número positivo';
      }
      if (maxParticipants > 1000) {
        return 'El máximo de participantes no puede exceder 1000';
      }
    }

    return null;
  }

  /// Aplica reglas de negocio adicionales
  Map<String, dynamic> _applyBusinessRules(Map<String, dynamic> data) {
    final processedData = Map<String, dynamic>.from(data);

    // Normalizar categoría a minúsculas
    if (processedData['category'] is String) {
      processedData['category'] = 
          (processedData['category'] as String).toLowerCase();
    }

    // Establecer valores por defecto
    processedData['status'] = processedData['status'] ?? 'upcoming';
    processedData['createdAt'] = DateTime.now().toIso8601String();
    processedData['participants'] = processedData['participants'] ?? [];
    processedData['isPublic'] = processedData['isPublic'] ?? true;

    // Si no tiene máximo de participantes, establecer uno alto por defecto
    processedData['maxParticipants'] = 
        processedData['maxParticipants'] ?? 100;

    return processedData;
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('duplicate')) {
      return 'Ya existe un evento con ese título en esa fecha';
    } else if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para crear eventos.';
    } else if (error.toString().contains('permission')) {
      return 'Permisos insuficientes para crear eventos.';
    } else {
      return 'Error al crear evento: ${error.toString()}';
    }
  }
}
