import 'package:dartz/dartz.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/utils/error_handler.dart';

/// Use case para obtener la lista de eventos
/// 
/// Este use case maneja la lógica de negocio para recuperar
/// eventos desde el repositorio con filtros opcionales
class GetEventsUseCase {
  final EventRepository _eventRepository;

  GetEventsUseCase(this._eventRepository);

  /// Ejecuta el use case para obtener eventos
  /// 
  /// [filters] - Mapa opcional de filtros (ej: {'category': 'rally', 'status': 'upcoming'})
  /// [limit] - Número máximo de eventos a retornar
  /// [offset] - Offset para paginación
  /// 
  /// Retorna [Right] con lista de eventos si es exitoso
  /// Retorna [Left] con mensaje de error si falla
  Future<Either<String, List<EventModel>>> execute({
    Map<String, dynamic>? filters,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Validaciones de entrada
      if (limit <= 0) {
        return const Left('El límite debe ser mayor a 0');
      }
      
      if (offset < 0) {
        return const Left('El offset no puede ser negativo');
      }

      // Llamar al repositorio
      final events = await _eventRepository.getEvents(
        filters: filters,
        limit: limit,
        offset: offset,
      );

      // Aplicar lógica de negocio adicional si es necesario
      // Por ejemplo, ordenar por fecha, filtrar eventos caducados, etc.
      final sortedEvents = _sortEventsByDate(events);

      return Right(sortedEvents);
    } catch (e) {
      // Manejo de errores
      return Left(_handleError(e));
    }
  }

  /// Obtiene solo eventos futuros
  Future<Either<String, List<EventModel>>> getUpcomingEvents({
    int limit = 20,
  }) async {
    return execute(
      filters: {'status': 'upcoming'},
      limit: limit,
    );
  }

  /// Obtiene eventos por categoría
  Future<Either<String, List<EventModel>>> getEventsByCategory({
    required String category,
    int limit = 20,
  }) async {
    return execute(
      filters: {'category': category},
      limit: limit,
    );
  }

  /// Ordena eventos por fecha (más recientes primero)
  List<EventModel> _sortEventsByDate(List<EventModel> events) {
    final sortedList = List<EventModel>.from(events);
    sortedList.sort((a, b) {
      if (a.date == null || b.date == null) return 0;
      return b.date!.compareTo(a.date!);
    });
    return sortedList;
  }

  /// Maneja los diferentes tipos de errores
  String _handleError(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.toString().contains('timeout')) {
      return 'La solicitud tardó demasiado. Intenta de nuevo.';
    } else if (error.toString().contains('unauthorized')) {
      return 'No tienes permisos para ver los eventos.';
    } else {
      return 'Error al cargar eventos: ${error.toString()}';
    }
  }
}
