/// Estados del AuthBloc
///
/// Define todos los posibles estados de autenticación de la aplicación.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

/// Clase base abstracta para todos los estados de autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de verificar autenticación
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga durante operaciones de autenticación
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado de usuario autenticado exitosamente
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Estado de usuario no autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error en autenticación
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito para operaciones como reset de contraseña
class AuthOperationSuccess extends AuthState {
  final String message;

  const AuthOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
