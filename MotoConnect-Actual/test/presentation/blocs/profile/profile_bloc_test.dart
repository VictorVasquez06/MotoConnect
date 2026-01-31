/// Tests unitarios para ProfileBloc
///
/// Verifica el correcto funcionamiento del manejo de estado del perfil:
/// - Carga de perfil (éxito y error)
/// - Actualización de perfil
/// - Limpieza de estado
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motoconnect/data/models/user_model.dart';
import 'package:motoconnect/domain/repositories/i_user_repository.dart';
import 'package:motoconnect/presentation/blocs/profile/profile_bloc.dart';
import 'package:motoconnect/presentation/blocs/profile/profile_event.dart';
import 'package:motoconnect/presentation/blocs/profile/profile_state.dart';

// =============================================================================
// FAKE REPOSITORY
// =============================================================================

/// Implementación fake del repositorio de usuarios para testing
class FakeUserRepository implements IUserRepository {
  bool shouldFail = false;
  UserModel? userToReturn;
  List<UserModel> usersToReturn = [];

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    if (shouldFail) throw Exception('Error simulado');
    return userToReturn;
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    if (shouldFail) throw Exception('Error simulado');
    return userToReturn;
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    if (shouldFail) throw Exception('Error simulado');
    if (userToReturn != null) {
      userToReturn = userToReturn!.copyWith(
        nombre: nombre ?? userToReturn!.nombre,
        modeloMoto: modeloMoto ?? userToReturn!.modeloMoto,
        fotoPerfil: fotoPerfil ?? userToReturn!.fotoPerfil,
      );
    }
  }

  @override
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    String? modeloMoto,
    String? fotoPerfil,
  }) async {
    if (shouldFail) throw Exception('Error simulado');
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    if (shouldFail) throw Exception('Error simulado');
  }

  @override
  Future<List<UserModel>> getUserProfiles(List<String> userIds) async {
    if (shouldFail) throw Exception('Error simulado');
    return usersToReturn;
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    if (shouldFail) throw Exception('Error simulado');
    return usersToReturn
        .where((u) => u.nombre.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    if (shouldFail) throw Exception('Error simulado');
    return usersToReturn;
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    return getUserProfile(userId);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return getCurrentUserProfile();
  }

  @override
  Future<void> deleteUser(String userId) async {
    return deleteUserProfile(userId);
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  late FakeUserRepository fakeUserRepository;
  late ProfileBloc profileBloc;

  final testUser = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    nombre: 'Usuario Test',
    modeloMoto: 'Yamaha R3',
    fotoPerfil: 'https://example.com/photo.jpg',
    apodo: 'Rider',
  );

  setUp(() {
    fakeUserRepository = FakeUserRepository();
    profileBloc = ProfileBloc(userRepository: fakeUserRepository);
  });

  tearDown(() {
    profileBloc.close();
  });

  group('ProfileBloc', () {
    // =========================================================================
    // Estado Inicial
    // =========================================================================
    test('estado inicial debe ser ProfileInitial', () {
      expect(profileBloc.state, equals(const ProfileInitial()));
    });

    // =========================================================================
    // ProfileLoadRequested - Carga Exitosa
    // =========================================================================
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileLoaded] cuando ProfileLoadRequested exitoso',
      build: () {
        fakeUserRepository.userToReturn = testUser;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested(userId: 'user-123')),
      expect: () => [const ProfileLoading(), ProfileLoaded(user: testUser)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileLoaded] para usuario actual (sin userId)',
      build: () {
        fakeUserRepository.userToReturn = testUser;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [const ProfileLoading(), ProfileLoaded(user: testUser)],
    );

    // =========================================================================
    // ProfileLoadRequested - Carga Fallida
    // =========================================================================
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileError] cuando ProfileLoadRequested falla',
      build: () {
        fakeUserRepository.shouldFail = true;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested(userId: 'user-123')),
      expect: () => [const ProfileLoading(), isA<ProfileError>()],
      verify: (bloc) {
        final state = bloc.state as ProfileError;
        expect(state.message.isNotEmpty, true);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileError] cuando usuario no encontrado',
      build: () {
        fakeUserRepository.userToReturn = null;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested(userId: 'unknown')),
      expect:
          () => [
            const ProfileLoading(),
            const ProfileError(message: 'No se encontró el perfil del usuario'),
          ],
    );

    // =========================================================================
    // ProfileUpdateRequested - Actualización Exitosa
    // =========================================================================
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileUpdateSuccess] cuando actualización exitosa',
      build: () {
        fakeUserRepository.userToReturn = testUser;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act:
          (bloc) => bloc.add(
            const ProfileUpdateRequested(
              userId: 'user-123',
              nombre: 'Nuevo Nombre',
              modeloMoto: 'Honda CBR 600',
            ),
          ),
      expect: () => [const ProfileLoading(), isA<ProfileUpdateSuccess>()],
      verify: (bloc) {
        final state = bloc.state as ProfileUpdateSuccess;
        expect(state.message, 'Perfil actualizado correctamente');
        expect(state.user, isA<UserModel>());
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileError] cuando actualización falla',
      build: () {
        fakeUserRepository.shouldFail = true;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act:
          (bloc) => bloc.add(
            const ProfileUpdateRequested(
              userId: 'user-123',
              nombre: 'Nuevo Nombre',
            ),
          ),
      expect: () => [const ProfileLoading(), isA<ProfileError>()],
      verify: (bloc) {
        final state = bloc.state as ProfileError;
        expect(state.message, contains('Error al actualizar'));
      },
    );

    // =========================================================================
    // ProfilePhotoUpdateRequested
    // =========================================================================
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileLoading, ProfileUpdateSuccess] cuando foto actualizada',
      build: () {
        fakeUserRepository.userToReturn = testUser;
        return ProfileBloc(userRepository: fakeUserRepository);
      },
      act:
          (bloc) => bloc.add(
            const ProfilePhotoUpdateRequested(
              userId: 'user-123',
              photoUrl: 'https://example.com/new-photo.jpg',
            ),
          ),
      expect: () => [const ProfileLoading(), isA<ProfileUpdateSuccess>()],
      verify: (bloc) {
        final state = bloc.state as ProfileUpdateSuccess;
        expect(state.message, 'Foto de perfil actualizada');
      },
    );

    // =========================================================================
    // ProfileClearRequested
    // =========================================================================
    blocTest<ProfileBloc, ProfileState>(
      'emite [ProfileInitial] cuando ProfileClearRequested',
      build: () => ProfileBloc(userRepository: fakeUserRepository),
      seed: () => ProfileLoaded(user: testUser),
      act: (bloc) => bloc.add(const ProfileClearRequested()),
      expect: () => [const ProfileInitial()],
    );
  });
}
