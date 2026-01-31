/// Eventos del AuthBloc
///
/// Define todas las acciones que pueden modificar el estado de autenticación.
library;

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos de autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación actual
class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// Evento para iniciar sesión con email y contraseña
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Evento para iniciar sesión con Google
class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

/// Evento para registrar un nuevo usuario
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.nombre,
  });

  @override
  List<Object?> get props => [email, password, nombre];
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Evento para recuperar contraseña
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
