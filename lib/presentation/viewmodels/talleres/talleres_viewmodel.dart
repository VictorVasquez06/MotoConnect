/// ViewModel para TalleresScreen
///
/// Responsabilidades:
/// - Cargar lista de talleres
/// - Crear, editar y eliminar talleres
/// - Compartir talleres en la comunidad
/// - Gestionar el estado de carga y errores
/// - Cachear nombres de creadores
///
/// Patrón MVVM: Separa la lógica de negocio de la UI
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase auxiliar para combinar datos del taller con el nombre del creador
class TallerConCreador {
  final Map<String, dynamic> tallerData;
  final String? nombreCreador;

  TallerConCreador({required this.tallerData, this.nombreCreador});
}

/// Estados posibles de la pantalla de talleres
enum TalleresStatus { initial, loading, loaded, saving, error }

class TalleresViewModel extends ChangeNotifier {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // ESTADO
  // ========================================

  /// Lista de talleres con información del creador
  List<TallerConCreador> _talleresConCreador = [];
  List<TallerConCreador> get talleresConCreador => _talleresConCreador;

  /// Estado actual
  TalleresStatus _status = TalleresStatus.initial;
  TalleresStatus get status => _status;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Cache de nombres de usuarios
  final Map<String, String> _cacheNombresCreadores = {};

  /// Indica si hay una operación en proceso
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el ViewModel cargando los talleres
  Future<void> initialize() async {
    await obtenerTalleres();
  }

  /// Obtiene todos los talleres con información del creador
  Future<void> obtenerTalleres() async {
    _status = TalleresStatus.loading;
    notifyListeners();

    try {
      final respuesta = await _supabase
          .from('talleres')
          .select('*, usuarios(nombre)')
          .order('nombre', ascending: true);

      final List<Map<String, dynamic>> talleresData =
          List<Map<String, dynamic>>.from(respuesta);

      List<TallerConCreador> tempTalleres = [];

      for (var tallerMap in talleresData) {
        String? nombreCreador;

        // Intentar obtener nombre del creador desde el join
        if (tallerMap['usuarios'] != null &&
            tallerMap['usuarios']['nombre'] != null) {
          nombreCreador = tallerMap['usuarios']['nombre'] as String;
        } else if (tallerMap['creado_por'] != null) {
          // Si el join no funcionó, obtener directamente
          nombreCreador = await _obtenerNombreUsuario(
            tallerMap['creado_por'] as String,
          );
        }

        tempTalleres.add(
          TallerConCreador(
            tallerData: tallerMap,
            nombreCreador: nombreCreador ?? 'N/A',
          ),
        );
      }

      _talleresConCreador = tempTalleres;
      _status = TalleresStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar talleres: ${e.toString()}';
      _status = TalleresStatus.error;
      debugPrint('Error en obtenerTalleres: $e');
    }

    notifyListeners();
  }

  /// Crea un nuevo taller
  ///
  /// [datosTaller] - Mapa con los datos del taller
  ///
  /// Retorna true si se creó exitosamente, false en caso contrario
  Future<bool> crearTaller(Map<String, dynamic> datosTaller) async {
    final currentUserUid = _supabase.auth.currentUser?.id;

    if (currentUserUid == null) {
      _errorMessage = 'Debes iniciar sesión';
      notifyListeners();
      return false;
    }

    // Validación básica
    if (datosTaller['nombre'] == null ||
        (datosTaller['nombre'] as String).trim().isEmpty) {
      _errorMessage = 'El nombre del taller es obligatorio';
      notifyListeners();
      return false;
    }

    _status = TalleresStatus.saving;
    notifyListeners();

    try {
      final datosParaGuardar = {
        'nombre': datosTaller['nombre'],
        'direccion': datosTaller['direccion'],
        'telefono': datosTaller['telefono'],
        'horario': datosTaller['horario'],
        'latitud': datosTaller['latitud'],
        'longitud': datosTaller['longitud'],
        'creado_por': currentUserUid,
      };

      await _supabase.from('talleres').insert(datosParaGuardar);

      // Recargar la lista de talleres
      await obtenerTalleres();

      return true;
    } catch (e) {
      _errorMessage = 'Error al crear taller: ${e.toString()}';
      _status = TalleresStatus.error;
      notifyListeners();
      debugPrint('Error en crearTaller: $e');
      return false;
    }
  }

  /// Actualiza un taller existente
  ///
  /// [tallerId] - ID del taller a actualizar
  /// [datosTaller] - Mapa con los nuevos datos
  ///
  /// Retorna true si se actualizó exitosamente, false en caso contrario
  Future<bool> actualizarTaller(
    String tallerId,
    Map<String, dynamic> datosTaller,
  ) async {
    // Validación básica
    if (datosTaller['nombre'] == null ||
        (datosTaller['nombre'] as String).trim().isEmpty) {
      _errorMessage = 'El nombre del taller es obligatorio';
      notifyListeners();
      return false;
    }

    _status = TalleresStatus.saving;
    notifyListeners();

    try {
      final datosParaActualizar = {
        'nombre': datosTaller['nombre'],
        'direccion': datosTaller['direccion'],
        'telefono': datosTaller['telefono'],
        'horario': datosTaller['horario'],
        'latitud': datosTaller['latitud'],
        'longitud': datosTaller['longitud'],
      };

      await _supabase
          .from('talleres')
          .update(datosParaActualizar)
          .eq('id', tallerId);

      // Recargar la lista de talleres
      await obtenerTalleres();

      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar taller: ${e.toString()}';
      _status = TalleresStatus.error;
      notifyListeners();
      debugPrint('Error en actualizarTaller: $e');
      return false;
    }
  }

  /// Elimina un taller
  ///
  /// [tallerId] - ID del taller a eliminar
  ///
  /// Retorna true si se eliminó exitosamente, false en caso contrario
  Future<bool> eliminarTaller(String tallerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('talleres').delete().eq('id', tallerId);

      // Remover de la lista local
      _talleresConCreador.removeWhere((t) => t.tallerData['id'] == tallerId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar taller: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en eliminarTaller: $e');
      return false;
    }
  }

  /// Comparte un taller en la comunidad
  ///
  /// [tallerData] - Datos del taller a compartir
  /// [mensajeUsuario] - Mensaje opcional del usuario
  ///
  /// Retorna true si se compartió exitosamente, false en caso contrario
  Future<bool> compartirTallerEnComunidad(
    Map<String, dynamic> tallerData, {
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
      // Construir el contenido de la publicación
      String contenidoPublicacion =
          mensajeUsuario?.trim().isNotEmpty == true
              ? mensajeUsuario!.trim()
              : "";

      contenidoPublicacion +=
          "\n\n¡Revisen este taller!: ${tallerData['nombre'] ?? 'Sin nombre'}";

      if (tallerData['direccion'] != null &&
          (tallerData['direccion'] as String).isNotEmpty) {
        contenidoPublicacion += "\nDirección: ${tallerData['direccion']}";
      }

      if (tallerData['telefono'] != null &&
          (tallerData['telefono'] as String).isNotEmpty) {
        contenidoPublicacion += "\nTeléfono: ${tallerData['telefono']}";
      }

      if (tallerData['horario'] != null &&
          (tallerData['horario'] as String).isNotEmpty) {
        contenidoPublicacion += "\nHorario: ${tallerData['horario']}";
      }

      // Crear publicación en la comunidad
      await _supabase.from('comentarios_comunidad').insert({
        'usuario_id': currentUserUid,
        'contenido': contenidoPublicacion,
        'tipo': 'taller_compartido',
        'referencia_taller_id': tallerData['id'],
        'fecha': DateTime.now().toIso8601String(),
      });

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al compartir taller: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en compartirTallerEnComunidad: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual es el creador de un taller
  ///
  /// [tallerData] - Datos del taller
  ///
  /// Retorna true si el usuario es el creador, false en caso contrario
  bool esCreadorDelTaller(Map<String, dynamic> tallerData) {
    final currentUserUid = _supabase.auth.currentUser?.id;
    return currentUserUid != null && tallerData['creado_por'] == currentUserUid;
  }

  /// Refresca la lista de talleres
  Future<void> refresh() async {
    await obtenerTalleres();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Filtra talleres por nombre o dirección
  ///
  /// [query] - Texto de búsqueda
  ///
  /// Retorna lista filtrada de talleres
  List<TallerConCreador> filtrarTalleres(String query) {
    if (query.trim().isEmpty) {
      return _talleresConCreador;
    }

    final queryLower = query.toLowerCase();
    return _talleresConCreador.where((tallerConCreador) {
      final taller = tallerConCreador.tallerData;
      final nombre = (taller['nombre'] as String?)?.toLowerCase() ?? '';
      final direccion = (taller['direccion'] as String?)?.toLowerCase() ?? '';
      return nombre.contains(queryLower) || direccion.contains(queryLower);
    }).toList();
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Obtiene el nombre de un usuario por su ID
  ///
  /// Utiliza caché para evitar consultas repetidas
  Future<String?> _obtenerNombreUsuario(String userId) async {
    // Verificar si está en caché
    if (_cacheNombresCreadores.containsKey(userId)) {
      return _cacheNombresCreadores[userId];
    }

    try {
      final respuesta =
          await _supabase
              .from('usuarios')
              .select('nombre')
              .eq('id', userId)
              .single();

      final nombre = respuesta['nombre'] as String?;
      if (nombre != null) {
        _cacheNombresCreadores[userId] = nombre;
      }
      return nombre;
    } catch (e) {
      debugPrint('Error al obtener nombre de usuario $userId: $e');
      return 'Desconocido';
    }
  }
}
