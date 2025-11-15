/// ViewModel para ProfileScreen
///
/// Responsabilidades:
/// - Cargar datos del perfil del usuario
/// - Validar y actualizar información del perfil
/// - Gestionar el estado de carga y errores
///
/// Patrón MVVM: Separa la lógica de negocio de la UI
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Estados posibles del perfil
enum ProfileStatus { initial, loading, loaded, saving, saved, error }

class ProfileViewModel extends ChangeNotifier {
  // ========================================
  // CONTROLADORES DE TEXTO
  // ========================================

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController modeloMotoController = TextEditingController();

  // ========================================
  // ESTADO
  // ========================================

  /// Estado actual del perfil
  ProfileStatus _status = ProfileStatus.initial;
  ProfileStatus get status => _status;

  /// ID del usuario actual
  String? _userId;
  String? get userId => _userId;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Indica si hay cambios sin guardar
  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  // Getter para evaluación perezosa (lazy evaluation)
  // Esto previene el error de acceso a Supabase antes de inicialización
  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  ProfileViewModel() {
    // Escuchar cambios en los controladores para detectar modificaciones
    nombreController.addListener(_onFieldChanged);
    modeloMotoController.addListener(_onFieldChanged);
  }

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el ViewModel cargando los datos del usuario
  Future<void> initialize() async {
    await cargarDatosUsuario();
  }

  /// Carga los datos del usuario actual desde Supabase
  Future<void> cargarDatosUsuario() async {
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      // Obtener usuario de Supabase Auth
      final supabaseUser = _supabase.auth.currentUser;

      if (supabaseUser == null) {
        throw Exception('Usuario no autenticado');
      }

      _userId = supabaseUser.id;
      correoController.text = supabaseUser.email ?? 'No disponible';

      // Validación explícita de _userId
      if (_userId == null) {
        throw Exception('Error: No se pudo identificar al usuario');
      }

      // Obtener datos adicionales de la tabla usuarios
      final respuesta =
          await _supabase
              .from('usuarios')
              .select('nombre, modelo_moto')
              .eq('id', _userId!)
              .maybeSingle();

      // Si el perfil no existe, crearlo
      if (respuesta == null) {
        debugPrint(
          'Perfil no encontrado, creando uno nuevo para el usuario $_userId',
        );
        await _crearPerfilInicial(supabaseUser);
      } else {
        nombreController.text = respuesta['nombre'] ?? '';
        modeloMotoController.text = respuesta['modelo_moto'] ?? '';
      }

      _status = ProfileStatus.loaded;
      _hasUnsavedChanges = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los datos del perfil: ${e.toString()}';
      _status = ProfileStatus.error;
      debugPrint('Error en cargarDatosUsuario: $e');
    }

    notifyListeners();
  }

  /// Crea un perfil inicial para el usuario
  Future<void> _crearPerfilInicial(User supabaseUser) async {
    try {
      // Extraer nombre de los metadatos o del email
      final nombre = supabaseUser.userMetadata?['nombre'] as String? ??
          supabaseUser.userMetadata?['full_name'] as String? ??
          supabaseUser.userMetadata?['name'] as String? ??
          supabaseUser.email?.split('@')[0] ??
          'Usuario';

      // Crear el perfil en la base de datos
      await _supabase.from('usuarios').insert({
        'id': supabaseUser.id,
        'correo': supabaseUser.email ?? '',
        'nombre': nombre,
        'modelo_moto': null,
      });

      // Actualizar los controladores
      nombreController.text = nombre;
      modeloMotoController.text = '';

      debugPrint('Perfil inicial creado exitosamente');
    } catch (e) {
      debugPrint('Error al crear perfil inicial: $e');
      // Si falla la creación, usar valores por defecto
      nombreController.text =
          supabaseUser.userMetadata?['nombre'] as String? ?? 'Usuario';
      modeloMotoController.text = '';
      rethrow;
    }
  }

  /// Guarda los cambios del perfil
  ///
  /// Retorna true si se guardó exitosamente, false en caso contrario
  Future<bool> guardarPerfil() async {
    // Validación de campos requeridos
    if (nombreController.text.trim().isEmpty) {
      _errorMessage = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }

    if (_userId == null) {
      _errorMessage = 'Error: No se pudo identificar al usuario';
      notifyListeners();
      return false;
    }

    _status = ProfileStatus.saving;
    notifyListeners();

    try {
      // Preparar datos para actualizar
      final datosActualizados = {
        'id': _userId!,
        'correo': correoController.text.trim(),
        'nombre': nombreController.text.trim(),
        'modelo_moto':
            modeloMotoController.text.trim().isEmpty
                ? null
                : modeloMotoController.text.trim(),
      };

      // Actualizar en Supabase usando upsert
      await _supabase.from('usuarios').upsert(datosActualizados);

      _status = ProfileStatus.saved;
      _hasUnsavedChanges = false;
      _errorMessage = null;
      notifyListeners();

      // Después de un breve delay, volver al estado loaded
      await Future.delayed(const Duration(milliseconds: 500));
      _status = ProfileStatus.loaded;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar perfil: ${e.toString()}';
      _status = ProfileStatus.error;
      notifyListeners();
      debugPrint('Error en guardarPerfil: $e');
      return false;
    }
  }

  /// Valida el nombre del usuario
  ///
  /// Retorna null si es válido, o un mensaje de error si no lo es
  String? validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu nombre';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Recarga los datos del perfil
  Future<void> refresh() async {
    await cargarDatosUsuario();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Descarta los cambios no guardados
  void discardChanges() {
    cargarDatosUsuario();
  }

  /// Actualiza el perfil del usuario
  ///
  /// [nombre] - Nuevo nombre del usuario
  /// [modeloMoto] - Nuevo modelo de moto (opcional)
  Future<bool> updateProfile({
    required String nombre,
    String? modeloMoto,
  }) async {
    nombreController.text = nombre;
    if (modeloMoto != null) {
      modeloMotoController.text = modeloMoto;
    }
    return await guardarPerfil();
  }

  /// Elimina la cuenta del usuario
  ///
  /// ADVERTENCIA: Esta acción es irreversible
  Future<bool> deleteAccount() async {
    if (_userId == null) {
      _errorMessage = 'Error: No se pudo identificar al usuario';
      notifyListeners();
      return false;
    }

    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      // Primero eliminar los datos del usuario de la tabla usuarios
      await _supabase.from('usuarios').delete().eq('id', _userId!);

      // Nota: La eliminación de la cuenta de Auth se debe hacer desde el servidor
      // o con privilegios especiales. Por seguridad, solo eliminamos los datos.

      _status = ProfileStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar cuenta: ${e.toString()}';
      _status = ProfileStatus.error;
      notifyListeners();
      debugPrint('Error en deleteAccount: $e');
      return false;
    }
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Detecta cambios en los campos del formulario
  void _onFieldChanged() {
    if (_status == ProfileStatus.loaded || _status == ProfileStatus.saved) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ========================================
  // DISPOSE
  // ========================================

  @override
  void dispose() {
    // Remover listeners antes de dispose
    nombreController.removeListener(_onFieldChanged);
    modeloMotoController.removeListener(_onFieldChanged);

    // Limpiar controladores
    nombreController.dispose();
    correoController.dispose();
    modeloMotoController.dispose();
    super.dispose();
  }
}
