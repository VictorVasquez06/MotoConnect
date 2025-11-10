import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

/// ViewModel para la pantalla de login.
///
/// Gestiona el estado de la UI (como el indicador de carga) y la lógica
/// de negocio para el inicio de sesión, delegando las operaciones de red
/// al [AuthRepository].
///
/// Utiliza [ChangeNotifier] para notificar a la vista (View) cuando el estado cambia,
/// permitiendo que la UI se reconstruya automáticamente.
class LoginViewModel extends ChangeNotifier {
  // Cambiado de AuthService a AuthRepository (patrón correcto)
  final AuthRepository _authRepository = AuthRepository();

  // Controladores para los campos de texto, gestionados por el ViewModel.
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Actualiza el estado de carga y notifica a los oyentes.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Actualiza el mensaje de error y notifica a los oyentes.
  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Cambia la visibilidad de la contraseña.
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  /// Lógica para iniciar sesión.
  Future<bool> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _setErrorMessage('Por favor, ingresa correo y contraseña.');
      return false;
    }

    _setLoading(true);
    _setErrorMessage(null);

    try {
      // Usa el Repository en lugar del Service directamente
      await _authRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      _setLoading(false);
      return true; // Éxito
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false; // Fracaso
    }
  }

  /// Lógica para restablecer la contraseña.
  Future<String> resetPassword() async {
    if (emailController.text.isEmpty) {
      return 'Por favor, ingresa tu correo para restablecer la contraseña.';
    }
    _setLoading(true);
    String message = 'Se ha enviado un correo de recuperación.';
    try {
      await _authRepository.resetPassword(emailController.text.trim());
    } catch (e) {
      message = e.toString();
    }
    _setLoading(false);
    return message;
  }

  @override
  void dispose() {
    // Limpia los controladores cuando el ViewModel ya no se necesite.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
