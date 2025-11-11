/// Repository de Publicaciones de Comunidad
///
/// Patrón Repository:
/// - Abstrae la fuente de datos de publicaciones
/// - Permite cambiar implementación sin afectar ViewModels
/// - Facilita testing con mocks
///
/// Responsabilidades:
/// - Operaciones CRUD de publicaciones
/// - Gestión de likes y comentarios
/// - Compartir contenido en la comunidad
/// - Comunicación con PostApiService
library;

import '../services/api/post_api_service.dart';
import '../models/post_model.dart';

class PostRepository {
  // ========================================
  // DEPENDENCIAS
  // ========================================

  /// Servicio de API de publicaciones
  final PostApiService _apiService;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  /// Constructor con inyección de dependencias
  ///
  /// [apiService] - Servicio para llamadas a API de publicaciones
  PostRepository({PostApiService? apiService})
    : _apiService = apiService ?? PostApiService();

  // ========================================
  // MÉTODOS PÚBLICOS - OBTENER PUBLICACIONES
  // ========================================

  /// Obtiene todas las publicaciones de la comunidad
  ///
  /// [limit] - Número máximo de publicaciones (default: 50)
  ///
  /// Retorna:
  /// - Lista de publicaciones ordenadas por fecha (más reciente primero)
  Future<List<PostModel>> getPosts({int limit = 50}) async {
    try {
      return await _apiService.getPosts(limit: limit);
    } catch (e) {
      throw Exception('Error al obtener publicaciones: ${e.toString()}');
    }
  }

  /// Alias de getPosts - Obtiene todas las publicaciones
  Future<List<PostModel>> getAllPosts() async {
    return await getPosts(limit: 100);
  }

  /// Obtiene publicaciones paginadas
  ///
  /// [page] - Número de página (empieza en 1)
  /// [limit] - Cantidad de posts por página
  Future<List<PostModel>> getPostsPaginated({
    required int page,
    int limit = 10,
  }) async {
    try {
      return await _apiService.getPostsPaginated(page: page, limit: limit);
    } catch (e) {
      throw Exception('Error al obtener posts paginados: ${e.toString()}');
    }
  }

  /// Obtiene una publicación por ID
  ///
  /// [postId] - ID de la publicación
  ///
  /// Retorna:
  /// - PostModel de la publicación
  /// - null si no se encuentra
  Future<PostModel?> getPostById(String postId) async {
    try {
      return await _apiService.getPostById(postId);
    } catch (e) {
      throw Exception('Error al obtener publicación: ${e.toString()}');
    }
  }

  /// Obtiene publicaciones de un usuario específico
  ///
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - Lista de publicaciones del usuario
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      return await _apiService.getUserPosts(userId);
    } catch (e) {
      throw Exception(
        'Error al obtener publicaciones del usuario: ${e.toString()}',
      );
    }
  }

  /// Alias de getUserPosts
  Future<List<PostModel>> getPostsByUser(String userId) async {
    return await getUserPosts(userId);
  }

  // ========================================
  // MÉTODOS PÚBLICOS - CREAR PUBLICACIONES
  // ========================================

  /// Crea una nueva publicación (método genérico)
  ///
  /// [content] - Contenido de la publicación
  /// [userId] - ID del usuario que crea la publicación
  /// [imageUrl] - URL de imagen opcional
  ///
  /// Retorna:
  /// - PostModel de la publicación creada
  Future<PostModel> createPost({
    required String content,
    required String userId,
    String? imageUrl,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('El contenido no puede estar vacío');
      }

      return await _apiService.createPost(
        userId: userId,
        contenido: content,
        imagenUrl: imageUrl,
      );
    } catch (e) {
      throw Exception('Error al crear publicación: ${e.toString()}');
    }
  }

  /// Crea una nueva publicación de texto
  ///
  /// [userId] - ID del usuario que crea la publicación
  /// [contenido] - Contenido de texto de la publicación
  ///
  /// Retorna:
  /// - PostModel de la publicación creada
  Future<PostModel> createTextPost({
    required String userId,
    required String contenido,
  }) async {
    try {
      if (contenido.trim().isEmpty) {
        throw Exception('El contenido no puede estar vacío');
      }

      return await _apiService.createTextPost(
        userId: userId,
        contenido: contenido,
      );
    } catch (e) {
      throw Exception('Error al crear publicación: ${e.toString()}');
    }
  }

  /// Sube una imagen al storage
  ///
  /// [imagePath] - Ruta local de la imagen
  ///
  /// Retorna:
  /// - URL pública de la imagen subida
  Future<String> uploadImage(String imagePath) async {
    try {
      return await _apiService.uploadImage(imagePath);
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  /// Comparte una ruta en la comunidad
  ///
  /// [userId] - ID del usuario que comparte
  /// [rutaId] - ID de la ruta a compartir
  /// [mensaje] - Mensaje opcional de acompañamiento
  ///
  /// Retorna:
  /// - PostModel de la publicación creada
  Future<PostModel> shareRoute({
    required String userId,
    required String rutaId,
    String? mensaje,
  }) async {
    try {
      return await _apiService.shareRoute(
        userId: userId,
        rutaId: rutaId,
        mensaje: mensaje,
      );
    } catch (e) {
      throw Exception('Error al compartir ruta: ${e.toString()}');
    }
  }

  /// Comparte un evento en la comunidad
  ///
  /// [userId] - ID del usuario que comparte
  /// [eventoId] - ID del evento a compartir
  /// [mensaje] - Mensaje opcional de acompañamiento
  ///
  /// Retorna:
  /// - PostModel de la publicación creada
  Future<PostModel> shareEvent({
    required String userId,
    required String eventoId,
    String? mensaje,
  }) async {
    try {
      return await _apiService.shareEvent(
        userId: userId,
        eventoId: eventoId,
        mensaje: mensaje,
      );
    } catch (e) {
      throw Exception('Error al compartir evento: ${e.toString()}');
    }
  }

  /// Comparte un taller en la comunidad
  ///
  /// [userId] - ID del usuario que comparte
  /// [tallerId] - ID del taller a compartir
  /// [mensaje] - Mensaje opcional de acompañamiento
  ///
  /// Retorna:
  /// - PostModel de la publicación creada
  Future<PostModel> shareTaller({
    required String userId,
    required String tallerId,
    String? mensaje,
  }) async {
    try {
      return await _apiService.shareTaller(
        userId: userId,
        tallerId: tallerId,
        mensaje: mensaje,
      );
    } catch (e) {
      throw Exception('Error al compartir taller: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - ACTUALIZAR/ELIMINAR
  // ========================================

  /// Actualiza una publicación
  ///
  /// [postId] - ID de la publicación
  /// [contenido] - Nuevo contenido
  Future<void> updatePost({
    required String postId,
    required String contenido,
  }) async {
    try {
      if (contenido.trim().isEmpty) {
        throw Exception('El contenido no puede estar vacío');
      }

      await _apiService.updatePost(postId: postId, contenido: contenido);
    } catch (e) {
      throw Exception('Error al actualizar publicación: ${e.toString()}');
    }
  }

  /// Elimina una publicación
  ///
  /// [postId] - ID de la publicación
  Future<void> deletePost(String postId) async {
    try {
      await _apiService.deletePost(postId);
    } catch (e) {
      throw Exception('Error al eliminar publicación: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - LIKES
  // ========================================

  /// Da like a una publicación
  ///
  /// [postId] - ID de la publicación
  /// [userId] - ID del usuario que da like
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _apiService.likePost(postId: postId, userId: userId);
    } catch (e) {
      throw Exception('Error al dar like: ${e.toString()}');
    }
  }

  /// Quita el like de una publicación
  ///
  /// [postId] - ID de la publicación
  /// [userId] - ID del usuario
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _apiService.unlikePost(postId: postId, userId: userId);
    } catch (e) {
      throw Exception('Error al quitar like: ${e.toString()}');
    }
  }

  /// Verifica si un usuario ha dado like a una publicación
  ///
  /// [postId] - ID de la publicación
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario ha dado like
  Future<bool> hasUserLikedPost({
    required String postId,
    required String userId,
  }) async {
    try {
      return await _apiService.hasUserLikedPost(postId: postId, userId: userId);
    } catch (e) {
      throw Exception('Error al verificar like: ${e.toString()}');
    }
  }

  /// Obtiene la cantidad de likes de una publicación
  ///
  /// [postId] - ID de la publicación
  ///
  /// Retorna:
  /// - Número de likes
  Future<int> getPostLikesCount(String postId) async {
    try {
      return await _apiService.getPostLikesCount(postId);
    } catch (e) {
      throw Exception('Error al obtener cantidad de likes: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - COMENTARIOS
  // ========================================

  /// Agrega un comentario a una publicación
  ///
  /// [postId] - ID de la publicación
  /// [userId] - ID del usuario que comenta
  /// [content] - Contenido del comentario
  ///
  /// Retorna:
  /// - CommentModel creado
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      return await _apiService.addComment(
        postId: postId,
        userId: userId,
        content: content,
      );
    } catch (e) {
      throw Exception('Error al agregar comentario: ${e.toString()}');
    }
  }

  /// Obtiene todos los comentarios de una publicación
  ///
  /// [postId] - ID de la publicación
  ///
  /// Retorna:
  /// - Lista de comentarios
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      return await _apiService.getPostComments(postId);
    } catch (e) {
      throw Exception('Error al obtener comentarios: ${e.toString()}');
    }
  }

  /// Obtiene comentarios paginados de una publicación
  ///
  /// [postId] - ID de la publicación
  /// [page] - Número de página
  /// [limit] - Cantidad de comentarios por página
  Future<List<CommentModel>> getPostCommentsPaginated({
    required String postId,
    required int page,
    int limit = 20,
  }) async {
    try {
      return await _apiService.getPostCommentsPaginated(
        postId: postId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw Exception(
        'Error al obtener comentarios paginados: ${e.toString()}',
      );
    }
  }

  /// Elimina un comentario
  ///
  /// [commentId] - ID del comentario
  /// [userId] - ID del usuario (debe ser el autor)
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      await _apiService.deleteComment(commentId: commentId, userId: userId);
    } catch (e) {
      throw Exception('Error al eliminar comentario: ${e.toString()}');
    }
  }

  /// Actualiza un comentario
  ///
  /// [commentId] - ID del comentario
  /// [userId] - ID del usuario (debe ser el autor)
  /// [content] - Nuevo contenido
  ///
  /// Retorna:
  /// - CommentModel actualizado
  Future<CommentModel> updateComment({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    try {
      return await _apiService.updateComment(
        commentId: commentId,
        userId: userId,
        content: content,
      );
    } catch (e) {
      throw Exception('Error al actualizar comentario: ${e.toString()}');
    }
  }

  /// Obtiene la cantidad de comentarios de una publicación
  ///
  /// [postId] - ID de la publicación
  ///
  /// Retorna:
  /// - Número de comentarios
  Future<int> getPostCommentsCount(String postId) async {
    try {
      return await _apiService.getPostCommentsCount(postId);
    } catch (e) {
      throw Exception(
        'Error al obtener cantidad de comentarios: ${e.toString()}',
      );
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - UTILIDADES
  // ========================================

  /// Verifica si un usuario es el autor de una publicación
  ///
  /// [postId] - ID de la publicación
  /// [userId] - ID del usuario
  ///
  /// Retorna:
  /// - true si el usuario es el autor
  Future<bool> isUserAuthor(String postId, String userId) async {
    try {
      final post = await getPostById(postId);
      return post?.usuarioId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Filtra publicaciones por tipo
  ///
  /// [posts] - Lista de publicaciones
  /// [tipo] - Tipo de publicación a filtrar
  ///
  /// Retorna:
  /// - Lista de publicaciones del tipo especificado
  List<PostModel> filterByType(List<PostModel> posts, String tipo) {
    return posts.where((post) => post.tipo == tipo).toList();
  }

  /// Obtiene solo publicaciones de texto
  List<PostModel> getTextPosts(List<PostModel> posts) {
    return filterByType(posts, 'texto');
  }

  /// Obtiene solo publicaciones de rutas compartidas
  List<PostModel> getSharedRoutes(List<PostModel> posts) {
    return filterByType(posts, 'ruta_compartida');
  }

  /// Obtiene solo publicaciones de eventos compartidos
  List<PostModel> getSharedEvents(List<PostModel> posts) {
    return filterByType(posts, 'evento_compartido');
  }

  /// Obtiene solo publicaciones de talleres compartidos
  List<PostModel> getSharedTalleres(List<PostModel> posts) {
    return filterByType(posts, 'taller_compartido');
  }
}
