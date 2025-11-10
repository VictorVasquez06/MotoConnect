import 'package:dartz/dartz.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Caso de uso para el registro de nuevos usuarios
class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  /// Ejecuta el registro de un nuevo usuario
  ///
  /// Retorna [Right(UserModel)] si el registro es exitoso
  /// Retorna [Left(String)] con el mensaje de error si falla
  Future<Either<String, UserModel>> execute({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Validar que los campos requeridos no estén vacíos
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return const Left('Todos los campos son requeridos');
      }

      // Validar formato de email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return const Left('Email inválido');
      }

      // Validar longitud mínima de contraseña
      if (password.length < 6) {
        return const Left('La contraseña debe tener al menos 6 caracteres');
      }

      // Validar longitud del nombre
      if (name.length < 2) {
        return const Left('El nombre debe tener al menos 2 caracteres');
      }

      // Validar teléfono si se proporciona
      if (phone != null && phone.isNotEmpty) {
        final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
        if (!phoneRegex.hasMatch(phone)) {
          return const Left('Número de teléfono inválido');
        }
      }

      // Ejecutar el registro a través del repositorio
      final result = await _authRepository.signUp(
        email: email,
        password: password,
        nombre: name,
      );

      return Right(result);
    } catch (e) {
      return Left('Error inesperado: ${e.toString()}');
    }
  }
}
