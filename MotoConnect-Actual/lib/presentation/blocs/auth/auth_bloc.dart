/// AuthBloc - Gestión de estado de autenticación
///
/// Implementa la lógica de negocio para autenticación usando BLoC pattern.
/// Depende de IAuthRepository para abstracción de datos.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  /// Verifica el estado de autenticación actual
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isAuthenticated = await authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Maneja el inicio de sesión con email/contraseña
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _parseErrorMessage(e)));
    }
  }

  /// Maneja el inicio de sesión con Google
  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _parseErrorMessage(e)));
    }
  }

  /// Maneja el registro de nuevo usuario
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signUp(
        email: event.email,
        password: event.password,
        nombre: event.nombre,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _parseErrorMessage(e)));
    }
  }

  /// Maneja el cierre de sesión
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: _parseErrorMessage(e)));
    }
  }

  /// Maneja la recuperación de contraseña
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.resetPassword(event.email);
      emit(
        const AuthOperationSuccess(
          message: 'Se ha enviado un correo de recuperación',
        ),
      );
    } catch (e) {
      emit(AuthError(message: _parseErrorMessage(e)));
    }
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Credenciales inválidas';
    } else if (message.contains('Email not confirmed')) {
      return 'Por favor, confirma tu correo electrónico';
    } else if (message.contains('User already registered')) {
      return 'El usuario ya está registrado';
    } else if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    }
    return 'Error: $message';
  }
}
