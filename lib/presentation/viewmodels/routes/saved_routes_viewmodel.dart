/// ViewModel para SavedRoutesScreen (RutasRecomendadasScreen)
///
/// Responsabilidades:
/// - Cargar rutas guardadas del usuario
/// - Eliminar rutas
/// - Compartir rutas en la comunidad
/// - Gestionar el estado de carga y errores
///
/// Patrón MVVM: Separa la lógica de negocio de la UI
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estados posibles de la pantalla de rutas guardadas
enum SavedRoutesStatus { initial, loading, loaded, error }

class SavedRoutesViewModel extends ChangeNotifier {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // ESTADO
  // ========================================

  /// Lista de rutas guardadas
  List<Map<String, dynamic>> _rutas = [];
  List<Map<String, dynamic>> get rutas => _rutas;

  /// Estado actual
  SavedRoutesStatus _status = SavedRoutesStatus.initial;
  SavedRoutesStatus get status => _status;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Indica si hay una operación en proceso
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el ViewModel cargando las rutas
  Future<void> initialize() async {
    await obtenerRutasGuardadas();
  }

  /// Obtiene las rutas guardadas del usuario actual
  Future<void> obtenerRutasGuardadas() async {
    _status = SavedRoutesStatus.loading;
    notifyListeners();

    try {
      final currentUserUid = _supabase.auth.currentUser?.id;

      if (currentUserUid == null) {
        _rutas = [];
        _status = SavedRoutesStatus.loaded;
        notifyListeners();
        return;
      }

      final respuesta = await _supabase
          .from('rutas_realizadas')
          .select()
          .eq('usuario_id', currentUserUid)
          .order('fecha', ascending: false);

      _rutas = List<Map<String, dynamic>>.from(respuesta);
      _status = SavedRoutesStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar rutas: ${e.toString()}';
      _status = SavedRoutesStatus.error;
      debugPrint('Error en obtenerRutasGuardadas: $e');
    }

    notifyListeners();
  }

  /// Elimina una ruta
  ///
  /// [rutaId] - ID de la ruta a eliminar
  /// [nombreRuta] - Nombre de la ruta (para confirmación)
  ///
  /// Retorna true si se eliminó exitosamente, false en caso contrario
  Future<bool> eliminarRuta(String rutaId, String nombreRuta) async {
    try {
      await _supabase.from('rutas_realizadas').delete().eq('id', rutaId);

      // Remover la ruta de la lista local
      _rutas.removeWhere((r) => r['id'] == rutaId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar la ruta: ${e.toString()}';
      notifyListeners();
      debugPrint('Error en eliminarRuta: $e');
      return false;
    }
  }

  /// Comparte una ruta en la comunidad
  ///
  /// [rutaData] - Datos de la ruta a compartir
  /// [mensajeUsuario] - Mensaje opcional del usuario (puede ser null o vacío)
  ///
  /// Retorna true si se compartió exitosamente, false en caso contrario
  Future<bool> compartirRutaEnComunidad(
    Map<String, dynamic> rutaData, {
    String? mensajeUsuario,
  }) async {
    final currentUserUid = _supabase.auth.currentUser?.id;

    if (currentUserUid == null) {
      _errorMessage = 'Debes iniciar sesión para compartir';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Preparar el contenido de la publicación
      String contenido;
      if (mensajeUsuario != null && mensajeUsuario.trim().isNotEmpty) {
        contenido = mensajeUsuario.trim();
      } else {
        // Mensaje por defecto
        contenido =
            "¡Echen un vistazo a esta ruta que guardé: ${rutaData['nombre_ruta'] ?? 'Sin nombre'}!";
      }

      // Crear publicación en la comunidad
      await _supabase.from('comentarios_comunidad').insert({
        'usuario_id': currentUserUid,
        'contenido': contenido,
        'tipo': 'ruta_compartida',
        'referencia_ruta_id': rutaData['id'],
        'fecha': DateTime.now().toIso8601String(),
      });

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al compartir la ruta: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en compartirRutaEnComunidad: $e');
      return false;
    }
  }

  /// Obtiene una ruta específica por ID
  ///
  /// [rutaId] - ID de la ruta a obtener
  ///
  /// Retorna los datos de la ruta o null si no se encuentra
  Map<String, dynamic>? obtenerRutaPorId(String rutaId) {
    try {
      return _rutas.firstWhere((ruta) => ruta['id'] == rutaId);
    } catch (e) {
      return null;
    }
  }

  /// Refresca la lista de rutas
  Future<void> refresh() async {
    await obtenerRutasGuardadas();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Filtra rutas por nombre
  ///
  /// [query] - Texto de búsqueda
  ///
  /// Retorna lista filtrada de rutas
  List<Map<String, dynamic>> filtrarRutas(String query) {
    if (query.trim().isEmpty) {
      return _rutas;
    }

    final queryLower = query.toLowerCase();
    return _rutas.where((ruta) {
      final nombre = (ruta['nombre_ruta'] as String?)?.toLowerCase() ?? '';
      final descripcion =
          (ruta['descripcion_ruta'] as String?)?.toLowerCase() ?? '';
      return nombre.contains(queryLower) || descripcion.contains(queryLower);
    }).toList();
  }
}
