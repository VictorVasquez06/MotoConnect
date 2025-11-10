/// ViewModel para HomeScreen
///
/// Responsabilidades:
/// - Gestionar el estado de autenticación del usuario
/// - Manejar la lógica de navegación
/// - Proporcionar información del usuario actual
///
/// Patrón MVVM: Este ViewModel separa la lógica de negocio de la UI
library;

import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

/// Estados posibles de la pantalla Home
enum HomeStatus { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Repository de autenticación
  final AuthRepository _authRepository;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [authRepository] - Repository para operaciones de autenticación
  HomeViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  // ========================================
  // ESTADO
  // ========================================

  /// Estado actual de la pantalla
  HomeStatus _status = HomeStatus.initial;
  HomeStatus get status => _status;

  /// Usuario actual
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Indica si hay una operación en proceso
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el ViewModel cargando los datos del usuario
  Future<void> initialize() async {
    _status = HomeStatus.loading;
    notifyListeners();

    try {
      await loadCurrentUser();
      _status = HomeStatus.loaded;
    } catch (e) {
      _errorMessage = 'Error al cargar información del usuario';
      _status = HomeStatus.error;
      debugPrint('Error inicializando HomeViewModel: $e');
    }

    notifyListeners();
  }

  /// Carga la información del usuario actual
  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al obtener usuario actual';
      debugPrint('Error cargando usuario: $e');
      rethrow;
    }
  }

  /// Cierra la sesión del usuario
  ///
  /// Retorna true si el logout fue exitoso, false en caso contrario
  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en logout: $e');
      return false;
    }
  }

  /// Refresca los datos del usuario
  Future<void> refresh() async {
    await loadCurrentUser();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
