// Módulo: Community (publicaciones de la comunidad)
// Fuente: lib/presentation/blocs/community/community_bloc.dart
//         lib/presentation/blocs/community/community_event.dart
//         lib/presentation/blocs/community/community_state.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:motoconnect/presentation/blocs/community/community_bloc.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockCommunityRepository mockCommunityRepository;

  setUp(() {
    mockCommunityRepository = MockCommunityRepository();
  });

  group('CommunityBloc', () {
    test('estado inicial es CommunityState con status initial', () {
      final bloc = CommunityBloc(communityRepository: mockCommunityRepository);
      expect(bloc.state, const CommunityState());
      expect(bloc.state.status, CommunityStatus.initial);
      expect(bloc.state.publicaciones, isEmpty);
      bloc.close();
    });

    blocTest<CommunityBloc, CommunityState>(
      'emite [loading, loaded] cuando CommunityLoadRequested es exitoso con lista vacía',
      build: () {
        when(() => mockCommunityRepository.getPublicaciones())
            .thenAnswer((_) async => []);
        when(() => mockCommunityRepository.getCurrentUserId())
            .thenReturn('test-uid');
        return CommunityBloc(communityRepository: mockCommunityRepository);
      },
      act: (bloc) => bloc.add(const CommunityLoadRequested()),
      expect: () => [
        const CommunityState(status: CommunityStatus.loading),
        const CommunityState(
          status: CommunityStatus.loaded,
          publicaciones: [],
          currentUserId: 'test-uid',
        ),
      ],
      verify: (_) {
        verify(() => mockCommunityRepository.getPublicaciones()).called(1);
        verify(() => mockCommunityRepository.getCurrentUserId()).called(1);
      },
    );

    blocTest<CommunityBloc, CommunityState>(
      'emite [loading, error] cuando CommunityLoadRequested falla',
      build: () {
        when(() => mockCommunityRepository.getPublicaciones())
            .thenThrow(Exception('Error de red'));
        return CommunityBloc(communityRepository: mockCommunityRepository);
      },
      act: (bloc) => bloc.add(const CommunityLoadRequested()),
      expect: () => [
        const CommunityState(status: CommunityStatus.loading),
        isA<CommunityState>()
            .having((s) => s.status, 'status', CommunityStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Error'),
            ),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'CommunityErrorCleared limpia el errorMessage manteniendo status',
      build: () =>
          CommunityBloc(communityRepository: mockCommunityRepository),
      seed: () => const CommunityState(
        status: CommunityStatus.error,
        errorMessage: 'Algún error',
      ),
      act: (bloc) => bloc.add(const CommunityErrorCleared()),
      expect: () => [
        const CommunityState(status: CommunityStatus.error),
      ],
    );
  });
}
