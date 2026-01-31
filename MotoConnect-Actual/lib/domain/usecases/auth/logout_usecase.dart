import 'package:dartz/dartz.dart';
import '../../../data/repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión de usuarios
class LogoutUseCase {
  final AuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  /// Ejecuta el cierre de sesión del usuario actual
  ///
  /// Retorna [Right(true)] si el logout es exitoso
  /// Retorna [Left(String)] con el mensaje de error si falla
  Future<Either<String, bool>> execute() async {
    try {
      // Ejecutar el logout a través del repositorio
      await _authRepository.signOut();

      return const Right(true);
    } catch (e) {
      return Left('Error al cerrar sesión: ${e.toString()}');
    }
  }
}
