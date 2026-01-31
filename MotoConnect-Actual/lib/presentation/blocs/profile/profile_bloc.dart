/// ProfileBloc - Business Logic Component para Perfil de Usuario
///
/// Maneja la lógica de negocio relacionada con el perfil:
/// - Cargar datos del perfil
/// - Actualizar perfil (nombre, moto, foto, apodo)
/// - Gestionar errores
///
/// Usa IUserRepository para abstracción de datos.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IUserRepository userRepository;

  ProfileBloc({required this.userRepository}) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePhotoUpdateRequested>(_onProfilePhotoUpdateRequested);
    on<ProfileClearRequested>(_onProfileClearRequested);
  }

  /// Maneja la carga del perfil del usuario
  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final user =
          event.userId != null
              ? await userRepository.getUserProfile(event.userId!)
              : await userRepository.getCurrentUserProfile();

      if (user != null) {
        emit(ProfileLoaded(user: user));
      } else {
        emit(
          const ProfileError(message: 'No se encontró el perfil del usuario'),
        );
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      emit(ProfileError(message: 'Error al cargar el perfil: ${e.toString()}'));
    }
  }

  /// Maneja la actualización del perfil del usuario
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Guardar el usuario actual para rollback en caso de error
    final currentUser =
        state is ProfileLoaded
            ? (state as ProfileLoaded).user
            : state is ProfileUpdateSuccess
            ? (state as ProfileUpdateSuccess).user
            : null;

    emit(const ProfileLoading());

    try {
      await userRepository.updateUserProfile(
        userId: event.userId,
        nombre: event.nombre,
        modeloMoto: event.modeloMoto,
        fotoPerfil: event.fotoPerfil,
      );

      // Recargar el perfil actualizado
      final updatedUser = await userRepository.getUserProfile(event.userId);

      if (updatedUser != null) {
        emit(
          ProfileUpdateSuccess(
            user: updatedUser,
            message: 'Perfil actualizado correctamente',
          ),
        );
      } else {
        emit(
          ProfileError(
            message: 'Error al verificar la actualización',
            previousUser: currentUser,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(
        ProfileError(
          message: 'Error al actualizar el perfil: ${e.toString()}',
          previousUser: currentUser,
        ),
      );
    }
  }

  /// Maneja la actualización de la foto de perfil
  Future<void> _onProfilePhotoUpdateRequested(
    ProfilePhotoUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentUser =
        state is ProfileLoaded
            ? (state as ProfileLoaded).user
            : state is ProfileUpdateSuccess
            ? (state as ProfileUpdateSuccess).user
            : null;

    emit(const ProfileLoading());

    try {
      await userRepository.updateUserProfile(
        userId: event.userId,
        fotoPerfil: event.photoUrl,
      );

      // Recargar el perfil actualizado
      final updatedUser = await userRepository.getUserProfile(event.userId);

      if (updatedUser != null) {
        emit(
          ProfileUpdateSuccess(
            user: updatedUser,
            message: 'Foto de perfil actualizada',
          ),
        );
      } else {
        emit(
          ProfileError(
            message: 'Error al verificar la actualización de la foto',
            previousUser: currentUser,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
      emit(
        ProfileError(
          message: 'Error al actualizar la foto: ${e.toString()}',
          previousUser: currentUser,
        ),
      );
    }
  }

  /// Limpia el estado del perfil (usado al cerrar sesión)
  void _onProfileClearRequested(
    ProfileClearRequested event,
    Emitter<ProfileState> emit,
  ) {
    emit(const ProfileInitial());
  }
}
