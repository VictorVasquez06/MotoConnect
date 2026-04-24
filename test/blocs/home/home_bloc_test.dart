// Módulo: Home (navegación de tabs principal)
// Fuente: lib/presentation/blocs/home/home_bloc.dart
//         lib/presentation/blocs/home/home_event.dart
//         lib/presentation/blocs/home/home_state.dart
//
// Nota: HomeState y HomeEvent NO extienden Equatable.
// Se usan matchers isA<>() para las verificaciones.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motoconnect/presentation/blocs/home/home_bloc.dart';
import 'package:motoconnect/presentation/blocs/home/home_event.dart';
import 'package:motoconnect/presentation/blocs/home/home_state.dart';

void main() {
  group('HomeBloc', () {
    test('estado inicial es HomeInitial', () {
      final bloc = HomeBloc();
      expect(bloc.state, isA<HomeInitial>());
      bloc.close();
    });

    blocTest<HomeBloc, HomeState>(
      'emite [HomeNavigationRequested, HomeInitial] cuando se selecciona una ruta',
      build: () => HomeBloc(),
      act: (bloc) => bloc.add(HomeRouteSelected('/comunidad')),
      expect: () => [
        isA<HomeNavigationRequested>(),
        isA<HomeInitial>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'HomeRouteSelected contiene la ruta correcta',
      build: () => HomeBloc(),
      act: (bloc) => bloc.add(HomeRouteSelected('/talleres')),
      expect: () => [
        isA<HomeNavigationRequested>().having(
          (s) => s.route,
          'route',
          '/talleres',
        ),
        isA<HomeInitial>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emite [HomeNavigationRequested(/perfil), HomeInitial] cuando se selecciona perfil',
      build: () => HomeBloc(),
      act: (bloc) => bloc.add(HomeProfileSelected()),
      expect: () => [
        isA<HomeNavigationRequested>().having(
          (s) => s.route,
          'route',
          '/perfil',
        ),
        isA<HomeInitial>(),
      ],
    );
  });
}
