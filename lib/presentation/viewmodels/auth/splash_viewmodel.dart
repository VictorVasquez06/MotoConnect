/// ViewModel para SplashScreen
///
/// Responsabilidades:
/// - Verificar estado de autenticación
/// - Comunicarse con AuthRepository
///
/// Este es un ejemplo de ViewModel siguiendo mejores prácticas
library;

import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashViewModel extends ChangeNotifier {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Repository de autenticación
  /// Inyectado para permitir testing y desacoplamiento
  final AuthRepository _authRepository;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [authRepository] - Repository para operaciones de autenticación
  SplashViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  // ========================================
  // ESTADO
  // ========================================

  /// Indica si se está verificando autenticación
  bool _isChecking = false;
  bool get isChecking => _isChecking;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Verifica si hay un usuario autenticado
  ///
  /// Retorna:
  /// - true si el usuario está autenticado
  /// - false si no hay sesión activa
  Future<bool> checkAuthentication() async {
    _isChecking = true;
    notifyListeners();

    try {
      // Pequeño delay para que el splash sea visible
      await Future.delayed(const Duration(seconds: 2));

      // Verifica si hay usuario autenticado
      final isAuthenticated = await _authRepository.isAuthenticated();

      return isAuthenticated;
    } catch (e) {
      // En caso de error, asume no autenticado
      debugPrint('Error verificando autenticación: $e');
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
