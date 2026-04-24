// Módulo: Talleres (gestión de talleres mecánicos)
// Fuente: lib/presentation/blocs/talleres/talleres_bloc.dart
//         lib/presentation/blocs/talleres/talleres_event.dart
//         lib/presentation/blocs/talleres/talleres_state.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:motoconnect/presentation/blocs/talleres/talleres_bloc.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockTallerRepository mockTallerRepository;

  setUp(() {
    mockTallerRepository = MockTallerRepository();
  });

  group('TalleresBloc', () {
    test('estado inicial es TalleresState con status initial', () {
      final bloc = TalleresBloc(tallerRepository: mockTallerRepository);
      expect(bloc.state, const TalleresState());
      expect(bloc.state.status, TalleresStatus.initial);
      expect(bloc.state.talleres, isEmpty);
      bloc.close();
    });

    blocTest<TalleresBloc, TalleresState>(
      'emite [loading, loaded] cuando TalleresLoadRequested es exitoso',
      build: () {
        when(() => mockTallerRepository.getTalleres())
            .thenAnswer((_) async => []);
        when(() => mockTallerRepository.getCurrentUserId())
            .thenReturn('test-uid');
        return TalleresBloc(tallerRepository: mockTallerRepository);
      },
      act: (bloc) => bloc.add(const TalleresLoadRequested()),
      expect: () => [
        const TalleresState(status: TalleresStatus.loading),
        const TalleresState(
          status: TalleresStatus.loaded,
          talleres: [],
          currentUserId: 'test-uid',
        ),
      ],
      verify: (_) {
        verify(() => mockTallerRepository.getTalleres()).called(1);
        verify(() => mockTallerRepository.getCurrentUserId()).called(1);
      },
    );

    blocTest<TalleresBloc, TalleresState>(
      'emite [loading, error] cuando TalleresLoadRequested falla',
      build: () {
        when(() => mockTallerRepository.getTalleres())
            .thenThrow(Exception('Error de conexión'));
        return TalleresBloc(tallerRepository: mockTallerRepository);
      },
      act: (bloc) => bloc.add(const TalleresLoadRequested()),
      expect: () => [
        const TalleresState(status: TalleresStatus.loading),
        isA<TalleresState>()
            .having((s) => s.status, 'status', TalleresStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Error'),
            ),
      ],
    );

    blocTest<TalleresBloc, TalleresState>(
      'TalleresErrorCleared limpia el errorMessage manteniendo status',
      build: () => TalleresBloc(tallerRepository: mockTallerRepository),
      seed: () => const TalleresState(
        status: TalleresStatus.error,
        errorMessage: 'Error previo',
      ),
      act: (bloc) => bloc.add(const TalleresErrorCleared()),
      expect: () => [
        const TalleresState(status: TalleresStatus.error),
      ],
    );
  });
}
