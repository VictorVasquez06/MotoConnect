import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';

/// Servicio para gestionar la autenticación de usuarios.
///
/// Abstrae la lógica de comunicación con el backend de autenticación (Firebase en este caso),
/// permitiendo que el resto de la aplicación no dependa directamente de una implementación específica.
/// En una arquitectura de microservicios pura, aquí se harían las llamadas HTTP al servicio de autenticación.
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  /// Inicia sesión con email y contraseña.
  ///
  /// Devuelve un objeto [User] si el inicio de sesión es exitoso.
  /// Lanza una excepción [AuthException] si ocurre un error.
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw AuthException('No se pudo obtener el usuario.');
      }
      return User(
        uid: credential.user!.uid,
        email: credential.user!.email!,
        displayName: credential.user!.displayName,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Mapea los errores de Firebase a excepciones personalizadas y más claras.
      throw AuthException(_mapFirebaseErrorToMessage(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado.');
    }
  }

  /// Registra un nuevo usuario.
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
       if (credential.user == null) {
        throw AuthException('No se pudo crear el usuario.');
      }
      return User(
        uid: credential.user!.uid,
        email: credential.user!.email!,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado.');
    }
  }

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
     try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorToMessage(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado.');
    }
  }


  /// Mapea los códigos de error de Firebase a mensajes legibles.
  String _mapFirebaseErrorToMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No se encontró usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El formato del correo es incorrecto.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      default:
        return 'Error de autenticación.';
    }
  }
}

/// Excepción personalizada para errores de autenticación.
///
/// Permite manejar los errores de forma más limpia en el ViewModel.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}