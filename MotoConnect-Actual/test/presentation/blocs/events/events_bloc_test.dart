/// Pruebas unitarias para EventsBloc
///
/// Valida la lógica de negocio de eventos sin necesidad de UI.
/// Usa FakeEventRepository para simular respuestas del repositorio.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motoconnect/data/models/event_model.dart';
import 'package:motoconnect/data/models/event_participant_model.dart';
import 'package:motoconnect/domain/repositories/i_event_repository.dart';
import 'package:motoconnect/presentation/blocs/events/events_bloc.dart';
import 'package:motoconnect/presentation/blocs/events/events_event.dart';
import 'package:motoconnect/presentation/blocs/events/events_state.dart';

// ============================================================================
// FAKE REPOSITORY - Implementación manual para testing
// ============================================================================

class FakeEventRepository implements IEventRepository {
  bool shouldSucceed = true;
  String errorMessage = 'Error de prueba';
  List<Event> mockEvents = [];

  /// Eventos de prueba por defecto
  List<Event> get defaultEvents => [
    Event(
      id: 'event-1',
      title: 'Ruta al Páramo',
      description: 'Evento de prueba 1',
      date: DateTime.now().add(const Duration(days: 7)),
      puntoEncuentro: 'Plaza Central',
    ),
    Event(
      id: 'event-2',
      title: 'Rodada Nocturna',
      description: 'Evento de prueba 2',
      date: DateTime.now().add(const Duration(days: 14)),
      puntoEncuentro: 'Centro Comercial',
    ),
  ];

  @override
  Future<List<Event>> getEvents() async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return mockEvents.isNotEmpty ? mockEvents : defaultEvents;
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return mockEvents.isNotEmpty ? mockEvents : defaultEvents;
  }

  @override
  Future<List<Event>> getPastEvents() async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return [];
  }

  @override
  Future<Event?> getEventById(String eventId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents.first;
  }

  @override
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String puntoEncuentro,
    required String createdBy,
    String? destino,
    double? puntoEncuentroLat,
    double? puntoEncuentroLng,
    double? destinoLat,
    double? destinoLng,
    String? fotoUrl,
    String? grupoId,
    bool isPublic = true,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return Event(
      id: 'new-event-id',
      title: title,
      description: description,
      date: date,
      puntoEncuentro: puntoEncuentro,
      createdBy: createdBy,
    );
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    String? puntoEncuentro,
    String? destino,
    double? puntoEncuentroLat,
    double? puntoEncuentroLng,
    double? destinoLat,
    double? destinoLng,
    String? fotoUrl,
    String? grupoId,
    bool? isPublic,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> joinEvent(
    String eventId,
    String userId, {
    EstadoAsistencia estado = EstadoAsistencia.confirmado,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> updateAttendanceStatus(
    String eventId,
    String userId,
    EstadoAsistencia estado,
  ) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
  }

  @override
  Future<List<String>> getEventParticipants(String eventId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return ['user-1', 'user-2'];
  }

  @override
  Future<bool> isUserJoined(String eventId, String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return false;
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents
        .where((e) => e.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Event>> getEventsByUser(String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents;
  }

  @override
  Future<List<Event>> getEventsUserJoined(String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return [];
  }

  @override
  Future<int> getEventParticipantsCount(String eventId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return 5;
  }

  @override
  Future<List<EventParticipantModel>> getEventParticipantsDetailed(
    String eventId,
  ) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return [];
  }

  @override
  Future<bool> isUserCreator(String eventId, String userId) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return false;
  }

  @override
  Future<List<Event>> getEventsByLocation({required String location}) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents;
  }

  @override
  Future<List<Event>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents;
  }

  @override
  Future<List<Event>> getAllEvents() async {
    if (!shouldSucceed) throw Exception(errorMessage);
    return defaultEvents;
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late FakeEventRepository fakeRepository;
  late EventsBloc eventsBloc;

  setUp(() {
    fakeRepository = FakeEventRepository();
    eventsBloc = EventsBloc(eventRepository: fakeRepository);
  });

  tearDown(() {
    eventsBloc.close();
  });

  group('EventsBloc', () {
    // ========================================================================
    // TEST: Estado Inicial
    // ========================================================================
    test('estado inicial debe ser EventsInitial', () {
      expect(eventsBloc.state, const EventsInitial());
    });

    // ========================================================================
    // TEST: Carga Exitosa de Eventos
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsLoaded] cuando carga exitosamente',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const EventsFetchRequested()),
      expect: () => [const EventsLoading(), isA<EventsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as EventsLoaded;
        expect(state.events.length, 2);
        expect(state.filterType, 'all');
      },
    );

    // ========================================================================
    // TEST: Error de Carga
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsError] cuando carga falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'Network error';
        return EventsBloc(eventRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const EventsFetchRequested()),
      expect: () => [const EventsLoading(), isA<EventsError>()],
    );

    // ========================================================================
    // TEST: Carga Eventos Próximos Exitosa
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsLoaded] para eventos próximos',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const EventsFetchUpcomingRequested()),
      expect: () => [const EventsLoading(), isA<EventsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as EventsLoaded;
        expect(state.filterType, 'upcoming');
      },
    );

    // ========================================================================
    // TEST: Creación Exitosa
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsOperationSuccess, ...] al crear evento',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            EventsCreateRequested(
              title: 'Nuevo Evento',
              description: 'Descripción del evento',
              date: DateTime.now().add(const Duration(days: 30)),
              puntoEncuentro: 'Plaza Mayor',
              createdBy: 'user-123',
            ),
          ),
      expect:
          () => [
            const EventsLoading(),
            isA<EventsOperationSuccess>(),
            // Después recarga eventos
            const EventsLoading(),
            isA<EventsLoaded>(),
          ],
      verify: (bloc) {
        // El estado final debe ser EventsLoaded
        expect(bloc.state, isA<EventsLoaded>());
      },
    );

    // ========================================================================
    // TEST: Creación Fallida
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsError] cuando crear evento falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            EventsCreateRequested(
              title: 'Evento Fallido',
              description: 'Descripción',
              date: DateTime.now(),
              puntoEncuentro: 'Lugar',
              createdBy: 'user-123',
            ),
          ),
      expect: () => [const EventsLoading(), isA<EventsError>()],
    );

    // ========================================================================
    // TEST: Eliminar Evento Exitoso
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsOperationSuccess, ...] al eliminar',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const EventsDeleteRequested(eventId: 'event-1')),
      expect:
          () => [
            const EventsLoading(),
            isA<EventsOperationSuccess>(),
            const EventsLoading(),
            isA<EventsLoaded>(),
          ],
    );

    // ========================================================================
    // TEST: Unirse a Evento Exitoso
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsOperationSuccess] al unirse a evento',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const EventsJoinRequested(eventId: 'event-1', userId: 'user-123'),
          ),
      expect: () => [const EventsLoading(), isA<EventsOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as EventsOperationSuccess;
        expect(state.operationType, EventsOperationType.joined);
      },
    );

    // ========================================================================
    // TEST: Salir de Evento Exitoso
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsOperationSuccess] al salir de evento',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act:
          (bloc) => bloc.add(
            const EventsLeaveRequested(eventId: 'event-1', userId: 'user-123'),
          ),
      expect: () => [const EventsLoading(), isA<EventsOperationSuccess>()],
      verify: (bloc) {
        final state = bloc.state as EventsOperationSuccess;
        expect(state.operationType, EventsOperationType.left);
      },
    );

    // ========================================================================
    // TEST: Búsqueda Exitosa
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsLoaded] al buscar eventos',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const EventsSearchRequested(query: 'Páramo')),
      expect: () => [const EventsLoading(), isA<EventsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as EventsLoaded;
        expect(state.filterType, 'search');
      },
    );

    // ========================================================================
    // TEST: Cargar Detalles de Evento
    // ========================================================================
    blocTest<EventsBloc, EventsState>(
      'emite [EventsLoading, EventsDetailLoaded] al cargar detalles',
      build: () {
        fakeRepository.shouldSucceed = true;
        return EventsBloc(eventRepository: fakeRepository);
      },
      act:
          (bloc) =>
              bloc.add(const EventsLoadDetailsRequested(eventId: 'event-1')),
      expect: () => [const EventsLoading(), isA<EventsDetailLoaded>()],
      verify: (bloc) {
        final state = bloc.state as EventsDetailLoaded;
        expect(state.participantsCount, 5);
      },
    );
  });
}
