/// Eventos del ProfileBloc
///
/// Define todas las acciones que pueden ocurrir relacionadas con el perfil.
library;

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos del perfil
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los datos del perfil del usuario
///
/// [userId] - ID del usuario a cargar. Si es null, carga el usuario actual.
class ProfileLoadRequested extends ProfileEvent {
  final String? userId;

  const ProfileLoadRequested({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para actualizar el perfil del usuario
///
/// Permite actualizar campos individuales del perfil.
class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final String? nombre;
  final String? modeloMoto;
  final String? fotoPerfil;
  final String? apodo;

  const ProfileUpdateRequested({
    required this.userId,
    this.nombre,
    this.modeloMoto,
    this.fotoPerfil,
    this.apodo,
  });

  @override
  List<Object?> get props => [userId, nombre, modeloMoto, fotoPerfil, apodo];
}

/// Evento para actualizar la foto de perfil
class ProfilePhotoUpdateRequested extends ProfileEvent {
  final String userId;
  final String photoUrl;

  const ProfilePhotoUpdateRequested({
    required this.userId,
    required this.photoUrl,
  });

  @override
  List<Object?> get props => [userId, photoUrl];
}

/// Evento para limpiar el estado del perfil (ej: al cerrar sesión)
class ProfileClearRequested extends ProfileEvent {
  const ProfileClearRequested();
}
