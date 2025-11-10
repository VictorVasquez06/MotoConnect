/// ViewModel para CommunityScreen
///
/// Responsabilidades:
/// - Cargar publicaciones de la comunidad
/// - Crear nuevas publicaciones de texto
/// - Gestionar información de autores, rutas y eventos compartidos
/// - Cachear nombres de usuarios
/// - Gestionar el estado de carga y errores
///
/// Patrón MVVM: Separa la lógica de negocio de la UI
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/post_model.dart';

/// Clase auxiliar para combinar datos de la publicación con información adicional
class PublicacionConAutor {
  final Map<String, dynamic> publicacionData;
  final String? nombreAutor;
  final String? nombreRutaCompartida;
  final String? idRutaCompartida;
  final Map<String, dynamic>? eventoCompartidoData;
  final String? nombreOrganizadorEvento;

  PublicacionConAutor({
    required this.publicacionData,
    this.nombreAutor,
    this.nombreRutaCompartida,
    this.idRutaCompartida,
    this.eventoCompartidoData,
    this.nombreOrganizadorEvento,
  });
}

/// Estados posibles de la pantalla de comunidad
enum CommunityStatus { initial, loading, loaded, posting, error }

class CommunityViewModel extends ChangeNotifier {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // CONTROLADORES
  // ========================================

  final TextEditingController textoController = TextEditingController();

  // ========================================
  // ESTADO
  // ========================================

  /// Lista de publicaciones con información completa
  List<PublicacionConAutor> _publicacionesConAutor = [];
  List<PublicacionConAutor> get publicacionesConAutor => _publicacionesConAutor;

  /// Estado actual
  CommunityStatus _status = CommunityStatus.initial;
  CommunityStatus get status => _status;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Cache de nombres de usuarios
  final Map<String, String> _cacheNombres = {};

  /// Indica si hay una operación en proceso
  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Inicializa el ViewModel cargando las publicaciones
  Future<void> initialize() async {
    await obtenerPublicaciones();
  }

  /// Obtiene todas las publicaciones de la comunidad
  Future<void> obtenerPublicaciones() async {
    _status = CommunityStatus.loading;
    notifyListeners();

    try {
      // Obtener publicaciones ordenadas por fecha descendente
      final respuestaPublicaciones = await _supabase
          .from('comentarios_comunidad')
          .select()
          .order('fecha', ascending: false);

      List<PublicacionConAutor> tempLista = [];

      // Procesar cada publicación
      for (var publicacionData in respuestaPublicaciones) {
        // Obtener nombre del autor
        String? nombreAutor;
        final autorId = publicacionData['usuario_id'] as String?;
        if (autorId != null) {
          nombreAutor = await _obtenerNombreUsuario(autorId);
        }

        // Variables para rutas y eventos compartidos
        String? nombreRutaComp;
        String? idRutaComp = publicacionData['referencia_ruta_id'] as String?;
        Map<String, dynamic>? eventoDataComp;
        String? nombreOrganizadorEv;
        String? idEventoComp =
            publicacionData['referencia_evento_id'] as String?;

        final tipoPublicacion = publicacionData['tipo'] as String?;

        // Si es una ruta compartida, obtener su nombre
        if (tipoPublicacion == 'ruta_compartida' && idRutaComp != null) {
          try {
            final rutaRes =
                await _supabase
                    .from('rutas_realizadas')
                    .select('nombre_ruta')
                    .eq('id', idRutaComp)
                    .single();
            nombreRutaComp = rutaRes['nombre_ruta'] as String?;
          } catch (e) {
            debugPrint(
              'Error obteniendo nombre de ruta compartida $idRutaComp: $e',
            );
            nombreRutaComp = "Ruta eliminada o no encontrada";
          }
        }
        // Si es un evento compartido, obtener sus datos
        else if (tipoPublicacion == 'evento_compartido' &&
            idEventoComp != null) {
          try {
            final eventoRes =
                await _supabase
                    .from('eventos')
                    .select()
                    .eq('id', idEventoComp)
                    .single();
            eventoDataComp = eventoRes;

            // Obtener nombre del organizador del evento
            final organizadorIdEvento = eventoDataComp['creado_por'] as String?;
            if (organizadorIdEvento != null) {
              nombreOrganizadorEv = await _obtenerNombreUsuario(
                organizadorIdEvento,
              );
            }
          } catch (e) {
            debugPrint(
              'Error obteniendo datos del evento compartido $idEventoComp: $e',
            );
            // Crear un mapa placeholder
            eventoDataComp = {
              'titulo': 'Evento no disponible',
              'descripcion': 'Este evento pudo haber sido eliminado.',
              'id': idEventoComp,
            };
            nombreOrganizadorEv = "Desconocido";
          }
        }

        tempLista.add(
          PublicacionConAutor(
            publicacionData: publicacionData,
            nombreAutor: nombreAutor ?? "Usuario Anónimo",
            nombreRutaCompartida: nombreRutaComp,
            idRutaCompartida: idRutaComp,
            eventoCompartidoData: eventoDataComp,
            nombreOrganizadorEvento: nombreOrganizadorEv,
          ),
        );
      }

      _publicacionesConAutor = tempLista;
      _status = CommunityStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar publicaciones: ${e.toString()}';
      _status = CommunityStatus.error;
      debugPrint('Error en obtenerPublicaciones: $e');
    }

    notifyListeners();
  }

  /// Crea una nueva publicación de texto
  ///
  /// Retorna true si se creó exitosamente, false en caso contrario
  Future<bool> crearPublicacionTexto() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión para publicar';
      notifyListeners();
      return false;
    }

    final String contenido = textoController.text.trim();
    if (contenido.isEmpty) {
      _errorMessage = 'Escribe algo para publicar';
      notifyListeners();
      return false;
    }

    _status = CommunityStatus.posting;
    notifyListeners();

    try {
      await _supabase.from('comentarios_comunidad').insert({
        'usuario_id': currentUser.id,
        'contenido': contenido,
        'tipo': 'texto',
        'fecha': DateTime.now().toIso8601String(),
      });

      // Limpiar el campo de texto
      textoController.clear();

      // Recargar publicaciones
      await obtenerPublicaciones();

      return true;
    } catch (e) {
      _errorMessage = 'Error al crear la publicación: ${e.toString()}';
      _status = CommunityStatus.error;
      notifyListeners();
      debugPrint('Error en crearPublicacionTexto: $e');
      return false;
    }
  }

  /// Crea una nueva publicación con todos los campos
  Future<bool> createPost(Map<String, dynamic> postData) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión para publicar';
      notifyListeners();
      return false;
    }

    _status = CommunityStatus.posting;
    notifyListeners();

    try {
      await _supabase.from('comentarios_comunidad').insert({
        'usuario_id': currentUser.id,
        'contenido': postData['content'],
        'tipo': 'texto',
        'categoria': postData['category'],
        'titulo': postData['title'],
        'es_anonimo': postData['is_anonymous'] ?? false,
        'fecha': DateTime.now().toIso8601String(),
      });

      // Recargar publicaciones
      await obtenerPublicaciones();

      return true;
    } catch (e) {
      _errorMessage = 'Error al crear publicación: ${e.toString()}';
      _status = CommunityStatus.error;
      notifyListeners();
      debugPrint('Error en createPost: $e');
      return false;
    }
  }

  /// Variable para almacenar la publicación actual en detalle
  PublicacionConAutor? _publicacionActual;
  PublicacionConAutor? get publicacionActual => _publicacionActual;

  /// Valida que el usuario esté autenticado
  ///
  /// Retorna true si está autenticado, false en caso contrario
  bool validarUsuarioAutenticado() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Obtiene el ID del usuario actual
  String? obtenerUsuarioActualId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Refresca las publicaciones
  Future<void> refresh() async {
    await obtenerPublicaciones();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el campo de texto
  void clearTexto() {
    textoController.clear();
    notifyListeners();
  }

  /// Filtra publicaciones por contenido
  ///
  /// [query] - Texto de búsqueda
  ///
  /// Retorna lista filtrada de publicaciones
  List<PublicacionConAutor> filtrarPublicaciones(String query) {
    if (query.trim().isEmpty) {
      return _publicacionesConAutor;
    }

    final queryLower = query.toLowerCase();
    return _publicacionesConAutor.where((pubConAutor) {
      final contenido =
          (pubConAutor.publicacionData['contenido'] as String?)
              ?.toLowerCase() ??
          '';
      final nombreAutor = pubConAutor.nombreAutor?.toLowerCase() ?? '';
      return contenido.contains(queryLower) || nombreAutor.contains(queryLower);
    }).toList();
  }

  /// Obtiene publicaciones por tipo
  ///
  /// [tipo] - Tipo de publicación ('texto', 'ruta_compartida', 'evento_compartido')
  ///
  /// Retorna lista filtrada por tipo
  List<PublicacionConAutor> obtenerPublicacionesPorTipo(String tipo) {
    return _publicacionesConAutor.where((pubConAutor) {
      return pubConAutor.publicacionData['tipo'] == tipo;
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
    if (_cacheNombres.containsKey(userId)) {
      return _cacheNombres[userId];
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
        _cacheNombres[userId] = nombre;
      }
      return nombre;
    } catch (e) {
      debugPrint('Error obteniendo nombre para usuario $userId: $e');
      return "Usuario Anónimo";
    }
  }

  /// Variable para almacenar la publicación actual en detalle
  PostModel? _selectedPost;
  PostModel? get selectedPost => _selectedPost;

  /// Carga el detalle de una publicación específica
  Future<void> loadPostDetail(String postId) async {
    _status = CommunityStatus.loading;
    notifyListeners();

    try {
      final publicacionData =
          await _supabase
              .from('comentarios_comunidad')
              .select()
              .eq('id', postId)
              .single();

      String? nombreAutor;
      final autorId = publicacionData['usuario_id'] as String?;
      if (autorId != null) {
        nombreAutor = await _obtenerNombreUsuario(autorId);
      }

      _publicacionActual = PublicacionConAutor(
        publicacionData: publicacionData,
        nombreAutor: nombreAutor ?? 'Usuario Anónimo',
      );

      // Convertir a PostModel
      _selectedPost = PostModel.fromJson({
        'id': publicacionData['id'],
        'usuario_id': publicacionData['usuario_id'],
        'nombre_usuario': nombreAutor,
        'contenido': publicacionData['contenido'],
        'tipo': publicacionData['tipo'] ?? 'texto',
        'fecha': publicacionData['fecha'],
        'categoria': publicacionData['categoria'],
        'titulo': publicacionData['titulo'],
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
        'is_saved': false,
      });

      _status = CommunityStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar publicación: ${e.toString()}';
      _status = CommunityStatus.error;
      notifyListeners();
      debugPrint('Error en loadPostDetail: $e');
    }
  }

  /// Toggle like en publicación
  Future<void> toggleLike(String postId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // TODO: Implementar lógica real de likes en la base de datos
      // Por ahora solo actualiza el estado local

      if (_selectedPost != null) {
        final newLikesCount =
            _selectedPost!.isLiked
                ? _selectedPost!.likesCount - 1
                : _selectedPost!.likesCount + 1;

        _selectedPost = _selectedPost!.copyWith(
          isLiked: !_selectedPost!.isLiked,
          likesCount: newLikesCount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al dar like: $e');
    }
  }

  /// Toggle guardar publicación
  Future<void> toggleSavePost(String postId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // TODO: Implementar lógica real de guardado en la base de datos
      // Por ahora solo actualiza el estado local

      if (_selectedPost != null) {
        _selectedPost = _selectedPost!.copyWith(
          isSaved: !_selectedPost!.isSaved,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al guardar publicación: $e');
    }
  }

  /// Agregar comentario a una publicación
  Future<void> addComment(String postId, String comment) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión para comentar';
      notifyListeners();
      return;
    }

    try {
      // Insertar comentario en la base de datos
      await _supabase.from('comentarios_posts').insert({
        'post_id': postId,
        'usuario_id': currentUser.id,
        'contenido': comment,
        'fecha': DateTime.now().toIso8601String(),
      });

      // Recargar el detalle del post para actualizar los comentarios
      await loadPostDetail(postId);
    } catch (e) {
      _errorMessage = 'Error al agregar comentario: ${e.toString()}';
      notifyListeners();
      debugPrint('Error en addComment: $e');
    }
  }

  /// Eliminar una publicación
  Future<bool> deletePost(String postId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión';
      notifyListeners();
      return false;
    }

    try {
      _status = CommunityStatus.loading;
      notifyListeners();

      // Eliminar la publicación
      await _supabase
          .from('comentarios_comunidad')
          .delete()
          .eq('id', postId)
          .eq('usuario_id', currentUser.id); // Solo el dueño puede eliminar

      _status = CommunityStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar publicación: ${e.toString()}';
      _status = CommunityStatus.error;
      notifyListeners();
      debugPrint('Error en deletePost: $e');
      return false;
    }
  }

  // ========================================
  // DISPOSE
  // ========================================

  @override
  void dispose() {
    textoController.dispose();
    super.dispose();
  }
}
