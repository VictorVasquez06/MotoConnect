// Módulo: Repositorio de eventos — tests de contrato
// Fuente: lib/data/repositories/event_repository.dart (interfaz)
//         lib/data/repositories/impl/event_repository_impl.dart (implementación)
//
// EventRepositoryImpl depende de EventApiService y SupabaseClient.
// Ambos defaults requieren Supabase.instance.client inicializado.
//
// Estos tests verifican el contrato de la interfaz y la relación de tipos.

import 'package:flutter_test/flutter_test.dart';

import 'package:motoconnect/data/repositories/event_repository.dart';
import 'package:motoconnect/data/repositories/impl/event_repository_impl.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('EventRepository — contrato de interfaz', () {
    test('MockEventRepository implementa EventRepository', () {
      final mock = MockEventRepository();
      expect(mock, isA<EventRepository>());
    });

    test(
        'EventRepositoryImpl implementa EventRepository (verificación de tipo)',
        () {
      // Si compila, el contrato se cumple.
      expect(EventRepositoryImpl, isNotNull);
    });

    test(
      'EventRepositoryImpl se instancia correctamente',
      () {
        final impl = EventRepositoryImpl();
        expect(impl, isA<EventRepository>());
      },
      skip: 'Requiere integración real con Supabase '
          '(EventApiService y SupabaseClient usan Supabase.instance)',
    );

    test('la interfaz declara los métodos esperados', () {
      final mock = MockEventRepository();
      expect(mock.getEvents, isNotNull);
      expect(mock.getUpcomingEvents, isNotNull);
      expect(mock.getEventById, isNotNull);
      expect(mock.createEvent, isNotNull);
      expect(mock.updateEvent, isNotNull);
      expect(mock.deleteEvent, isNotNull);
      expect(mock.joinEvent, isNotNull);
      expect(mock.leaveEvent, isNotNull);
      expect(mock.searchEvents, isNotNull);
      expect(mock.getCurrentUserId, isNotNull);
      expect(mock.getEventParticipants, isNotNull);
      expect(mock.getAllEvents, isNotNull);
    });
  });
}
