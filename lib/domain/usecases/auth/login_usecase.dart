import 'package:dartz/dartz.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Caso de uso para el inicio de sesión de usuarios
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  /// Ejecuta el inicio de sesión con email y contraseña
  ///
  /// Retorna [Right(UserModel)] si el login es exitoso
  /// Retorna [Left(String)] con el mensaje de error si falla
  Future<Either<String, UserModel>> execute({
    required String email,
    required String password,
  }) async {
    try {
      // Validar que los campos no estén vacíos
      if (email.isEmpty || password.isEmpty) {
        return const Left('Email y contraseña son requeridos');
      }

      // Validar formato de email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return const Left('Email inválido');
      }

      // Ejecutar el login a través del repositorio
      final result = await _authRepository.signIn(
        email: email,
        password: password,
      );

      return Right(result);
    } catch (e) {
      return Left('Error inesperado: ${e.toString()}');
    }
  }
}
