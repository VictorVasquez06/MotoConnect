// Módulo: Auth — Login
// Fuente: lib/presentation/blocs/auth/login/login_bloc.dart
//         lib/presentation/blocs/auth/login/login_event.dart
//         lib/presentation/blocs/auth/login/login_state.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:motoconnect/data/models/user_model.dart';
import 'package:motoconnect/presentation/blocs/auth/login/login_bloc.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  const testUser = UserModel(
    id: 'test-uid-123',
    email: 'test@example.com',
    nombre: 'Test User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('LoginBloc', () {
    test('estado inicial es LoginState con status initial', () {
      final bloc = LoginBloc(authRepository: mockAuthRepository);
      expect(bloc.state, const LoginState());
      expect(bloc.state.status, LoginStatus.initial);
      expect(bloc.state.email, '');
      expect(bloc.state.password, '');
      bloc.close();
    });

    blocTest<LoginBloc, LoginState>(
      'emite failure cuando se envía LoginSubmitted con campos vacíos',
      build: () => LoginBloc(authRepository: mockAuthRepository),
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        const LoginState(
          status: LoginStatus.failure,
          errorMessage: 'Por favor, ingresa correo y contraseña.',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [loading, success] cuando login es exitoso',
      build: () {
        when(
          () => mockAuthRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => testUser);
        return LoginBloc(authRepository: mockAuthRepository);
      },
      seed: () => const LoginState(
        email: 'test@example.com',
        password: 'password123',
      ),
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          email: 'test@example.com',
          password: 'password123',
        ),
        const LoginState(
          status: LoginStatus.success,
          email: 'test@example.com',
          password: 'password123',
        ),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepository.signIn(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emite [loading, failure] cuando login falla',
      build: () {
        when(
          () => mockAuthRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Credenciales inválidas'));
        return LoginBloc(authRepository: mockAuthRepository);
      },
      seed: () => const LoginState(
        email: 'test@example.com',
        password: 'wrongpass',
      ),
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          email: 'test@example.com',
          password: 'wrongpass',
        ),
        const LoginState(
          status: LoginStatus.failure,
          email: 'test@example.com',
          password: 'wrongpass',
          errorMessage: 'Exception: Credenciales inválidas',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'LoginEmailChanged actualiza el email en el estado',
      build: () => LoginBloc(authRepository: mockAuthRepository),
      act: (bloc) => bloc.add(const LoginEmailChanged('nuevo@email.com')),
      expect: () => [
        const LoginState(email: 'nuevo@email.com'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'LoginPasswordVisibilityToggled alterna la visibilidad',
      build: () => LoginBloc(authRepository: mockAuthRepository),
      act: (bloc) => bloc.add(const LoginPasswordVisibilityToggled()),
      expect: () => [
        const LoginState(isPasswordVisible: true),
      ],
    );
  });
}
