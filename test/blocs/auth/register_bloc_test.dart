// Módulo: Auth — Register
// Fuente: lib/presentation/blocs/auth/register/register_bloc.dart
//         lib/presentation/blocs/auth/register/register_event.dart
//         lib/presentation/blocs/auth/register/register_state.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:motoconnect/data/models/user_model.dart';
import 'package:motoconnect/presentation/blocs/auth/register/register_bloc.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  const testUser = UserModel(
    id: 'new-uid-456',
    email: 'nuevo@example.com',
    nombre: 'Nuevo Usuario',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('RegisterBloc', () {
    test('estado inicial es RegisterState con status initial', () {
      final bloc = RegisterBloc(authRepository: mockAuthRepository);
      expect(bloc.state, const RegisterState());
      expect(bloc.state.status, RegisterStatus.initial);
      expect(bloc.state.nombre, '');
      expect(bloc.state.email, '');
      bloc.close();
    });

    blocTest<RegisterBloc, RegisterState>(
      'emite [loading, success] cuando registro es exitoso',
      build: () {
        when(
          () => mockAuthRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            nombre: any(named: 'nombre'),
          ),
        ).thenAnswer((_) async => testUser);
        return RegisterBloc(authRepository: mockAuthRepository);
      },
      seed: () => const RegisterState(
        nombre: 'Nuevo Usuario',
        email: 'nuevo@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      ),
      act: (bloc) => bloc.add(const RegisterSubmitted()),
      expect: () => [
        const RegisterState(
          status: RegisterStatus.loading,
          nombre: 'Nuevo Usuario',
          email: 'nuevo@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        ),
        const RegisterState(
          status: RegisterStatus.success,
          nombre: 'Nuevo Usuario',
          email: 'nuevo@example.com',
          password: 'password123',
          confirmPassword: 'password123',
          registeredNombre: 'Nuevo Usuario',
        ),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepository.signUp(
            email: 'nuevo@example.com',
            password: 'password123',
            nombre: 'Nuevo Usuario',
          ),
        ).called(1);
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite failure cuando las contraseñas no coinciden',
      build: () => RegisterBloc(authRepository: mockAuthRepository),
      seed: () => const RegisterState(
        nombre: 'Nuevo Usuario',
        email: 'nuevo@example.com',
        password: 'password123',
        confirmPassword: 'diferente456',
      ),
      act: (bloc) => bloc.add(const RegisterSubmitted()),
      expect: () => [
        const RegisterState(
          status: RegisterStatus.failure,
          nombre: 'Nuevo Usuario',
          email: 'nuevo@example.com',
          password: 'password123',
          confirmPassword: 'diferente456',
          errorMessage: 'Las contraseñas no coinciden.',
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite failure cuando el nombre está vacío',
      build: () => RegisterBloc(authRepository: mockAuthRepository),
      seed: () => const RegisterState(
        nombre: '',
        email: 'nuevo@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      ),
      act: (bloc) => bloc.add(const RegisterSubmitted()),
      expect: () => [
        const RegisterState(
          status: RegisterStatus.failure,
          nombre: '',
          email: 'nuevo@example.com',
          password: 'password123',
          confirmPassword: 'password123',
          errorMessage: 'Por favor ingresa tu nombre.',
        ),
      ],
    );
  });
}
