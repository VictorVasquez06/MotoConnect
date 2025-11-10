import 'package:dartz/dartz.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Caso de uso para verificar el estado de autenticación del usuario
class CheckAuthStatusUseCase {
  final AuthRepository _authRepository;

  CheckAuthStatusUseCase(this._authRepository);

  /// Verifica si hay un usuario autenticado actualmente
  ///
  /// Retorna [Right(UserModel)] si hay un usuario autenticado
  /// Retorna [Left(String)] si no hay usuario autenticado o si hay un error
  Future<Either<String, UserModel>> execute() async {
    try {
      // Verificar el estado de autenticación a través del repositorio
      final result = await _authRepository.getCurrentUser();

      if (result == null) {
        return const Left('No hay usuario autenticado');
      }

      return Right(result);
    } catch (e) {
      return Left('Error al verificar autenticación: ${e.toString()}');
    }
  }

  /// Verifica si el usuario está autenticado (retorna un booleano)
  ///
  /// Retorna true si hay un usuario autenticado, false en caso contrario
  Future<bool> isAuthenticated() async {
    try {
      final result = await _authRepository.getCurrentUser();
      return result != null;
    } catch (e) {
      return false;
    }
  }
}
