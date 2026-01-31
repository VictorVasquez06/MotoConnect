/// Estados del ProfileBloc
///
/// Define todos los posibles estados del perfil de usuario.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

/// Clase base abstracta para todos los estados del perfil
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar el perfil
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Estado de carga durante operaciones del perfil
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Estado de perfil cargado exitosamente
class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Estado de actualización exitosa del perfil
///
/// Contiene el usuario actualizado y un mensaje de confirmación.
class ProfileUpdateSuccess extends ProfileState {
  final UserModel user;
  final String message;

  const ProfileUpdateSuccess({
    required this.user,
    this.message = 'Perfil actualizado correctamente',
  });

  @override
  List<Object?> get props => [user, message];
}

/// Estado de error en operaciones del perfil
class ProfileError extends ProfileState {
  final String message;
  final UserModel? previousUser;

  const ProfileError({required this.message, this.previousUser});

  @override
  List<Object?> get props => [message, previousUser];
}
