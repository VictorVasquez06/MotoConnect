/// Pruebas unitarias para AuthBloc
///
/// Valida la lógica de negocio de autenticación sin necesidad de UI.
/// Usa FakeAuthRepository para simular respuestas del repositorio.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motoconnect/data/models/user_model.dart';
import 'package:motoconnect/domain/repositories/i_auth_repository.dart';
import 'package:motoconnect/presentation/blocs/auth/auth_bloc.dart';
import 'package:motoconnect/presentation/blocs/auth/auth_event.dart';
import 'package:motoconnect/presentation/blocs/auth/auth_state.dart';

// ============================================================================
// FAKE REPOSITORY - Implementación manual para testing
// ============================================================================

/// Mock manual del repositorio de autenticación
/// Permite configurar respuestas simuladas para diferentes escenarios de test
class FakeAuthRepository implements IAuthRepository {
  // Configuración de comportamiento
  bool shouldSucceed = true;
  bool isUserAuthenticated = false;
  String errorMessage = 'Credenciales inválidas';
  UserModel? mockUser;

  /// Usuario de prueba por defecto
  UserModel get defaultUser => const UserModel(
        id: 'test-user-id',
        email: 'test@example.com',
        nombre: 'Usuario Test',
        modeloMoto: null,
        fotoPerfil: null,
        apodo: null,
      );

  @override
  Future<bool> isAuthenticated() async {
    return isUserAuthenticated;
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (!shouldSucceed) {
      throw Exception(errorMessage);
    }
    return mockUser ?? defaultUser;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nombre,
  }) async {
    if (!shouldSucceed) {
      throw Exception(errorMessage);
    }
    return mockUser ?? defaultUser;
  }

  @override
  Future<void> signOut() async {
    if (!shouldSucceed) {
      throw Exception('Error al cerrar sesión');
    }
    isUserAuthenticated = false;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (isUserAuthenticated) {
      return mockUser ?? defaultUser;
    }
    return null;
  }

  @override
  Future<void> resetPassword(String email) async {
    if (!shouldSucceed) {
      throw Exception('Error al enviar correo de recuperación');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!shouldSucceed) {
      throw Exception('Error en inicio de sesión con Google');
    }
    return mockUser ?? defaultUser;
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthBloc authBloc;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    // ========================================================================
    // TEST: Estado Inicial
    // ========================================================================
    test('estado inicial debe ser AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    // ========================================================================
    // TEST: AuthCheckStatus - Usuario Autenticado
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando hay sesión activa',
      build: () {
        fakeRepository.isUserAuthenticated = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthCheckStatus()),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    // ========================================================================
    // TEST: AuthCheckStatus - Usuario No Autenticado
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthUnauthenticated] cuando no hay sesión',
      build: () {
        fakeRepository.isUserAuthenticated = false;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthCheckStatus()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    // ========================================================================
    // TEST: Login Exitoso
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando login es exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthAuthenticated;
        expect(state.user.email, 'test@example.com');
      },
    );

    // ========================================================================
    // TEST: Login Fallido
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthError] cuando login falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'Invalid login credentials';
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthError;
        expect(state.message, contains('Credenciales inválidas'));
      },
    );

    // ========================================================================
    // TEST: Login con Google Exitoso
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando login con Google es exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthGoogleLoginRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    // ========================================================================
    // TEST: Registro Exitoso
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando registro es exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        email: 'nuevo@example.com',
        password: 'password123',
        nombre: 'Nuevo Usuario',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    // ========================================================================
    // TEST: Registro Fallido
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthError] cuando registro falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'User already registered';
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        email: 'existente@example.com',
        password: 'password123',
        nombre: 'Usuario Existente',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthError;
        expect(state.message, contains('ya está registrado'));
      },
    );

    // ========================================================================
    // TEST: Logout Exitoso
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthUnauthenticated] cuando logout es exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    // ========================================================================
    // TEST: Logout Fallido
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthError] cuando logout falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        fakeRepository.errorMessage = 'Error al cerrar sesión';
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    // ========================================================================
    // TEST: Reset Password Exitoso
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthOperationSuccess] cuando reset password es exitoso',
      build: () {
        fakeRepository.shouldSucceed = true;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthPasswordResetRequested(
        email: 'test@example.com',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthOperationSuccess>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthOperationSuccess;
        expect(state.message, contains('correo de recuperación'));
      },
    );

    // ========================================================================
    // TEST: Reset Password Fallido
    // ========================================================================
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthError] cuando reset password falla',
      build: () {
        fakeRepository.shouldSucceed = false;
        return AuthBloc(authRepository: fakeRepository);
      },
      act: (bloc) => bloc.add(const AuthPasswordResetRequested(
        email: 'noexiste@example.com',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });
}
