// ============================================================================
// ARCHIVO 6: lib/core/utils/validators.dart
// ============================================================================

/// Validadores comunes para formularios
///
/// Funciones reutilizables para validar entradas de usuario
library;

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  /// Valida formato de email
  ///
  /// Retorna mensaje de error o null si es válido
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }

    // Patrón regex para email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }

    return null;
  }

  /// Valida contraseña
  ///
  /// Verifica longitud mínima
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }

    return null;
  }

  /// Valida confirmación de contraseña
  ///
  /// Verifica que coincida con la contraseña original
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida nombre
  ///
  /// Verifica que no esté vacío y no exceda longitud máxima
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (value.length > AppConstants.maxNameLength) {
      return 'El nombre no puede exceder ${AppConstants.maxNameLength} caracteres';
    }

    return null;
  }

  /// Valida campo requerido
  ///
  /// Validación genérica para campos obligatorios
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    return null;
  }
}
