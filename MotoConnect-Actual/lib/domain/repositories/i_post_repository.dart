/// Interface de Repositorio de Publicaciones de Comunidad
///
/// Define el contrato para las operaciones de publicaciones.
/// Permite testing con mocks y cambio de implementación sin afectar la lógica de negocio.
library;

import '../../data/models/post_model.dart';

abstract class IPostRepository {
  // ========================================
  // MÉTODOS DE OBTENER PUBLICACIONES
  // ========================================

  /// Obtiene todas las publicaciones de la comunidad
  Future<List<PostModel>> getPosts({int limit = 50});

  /// Alias de getPosts - Obtiene todas las publicaciones
  Future<List<PostModel>> getAllPosts();

  /// Obtiene publicaciones paginadas
  Future<List<PostModel>> getPostsPaginated({
    required int page,
    int limit = 10,
  });

  /// Obtiene una publicación por ID
  Future<PostModel?> getPostById(String postId);

  /// Obtiene publicaciones de un usuario específico
  Future<List<PostModel>> getUserPosts(String userId);

  /// Alias de getUserPosts
  Future<List<PostModel>> getPostsByUser(String userId);

  // ========================================
  // MÉTODOS DE CREAR PUBLICACIONES
  // ========================================

  /// Crea una nueva publicación (método genérico)
  Future<PostModel> createPost({
    required String content,
    required String userId,
    String? imageUrl,
  });

  /// Crea una nueva publicación de texto
  Future<PostModel> createTextPost({
    required String userId,
    required String contenido,
  });

  /// Sube una imagen al storage
  Future<String> uploadImage(String imagePath);

  /// Comparte una ruta en la comunidad
  Future<PostModel> shareRoute({
    required String userId,
    required String rutaId,
    String? mensaje,
  });

  /// Comparte un evento en la comunidad
  Future<PostModel> shareEvent({
    required String userId,
    required String eventoId,
    String? mensaje,
  });

  /// Comparte un taller en la comunidad
  Future<PostModel> shareTaller({
    required String userId,
    required String tallerId,
    String? mensaje,
  });

  // ========================================
  // MÉTODOS DE ACTUALIZAR/ELIMINAR
  // ========================================

  /// Actualiza una publicación
  Future<void> updatePost({required String postId, required String contenido});

  /// Elimina una publicación
  Future<void> deletePost(String postId);

  // ========================================
  // MÉTODOS DE LIKES
  // ========================================

  /// Da like a una publicación
  Future<void> likePost({required String postId, required String userId});

  /// Quita el like de una publicación
  Future<void> unlikePost({required String postId, required String userId});

  /// Verifica si un usuario ha dado like a una publicación
  Future<bool> hasUserLikedPost({
    required String postId,
    required String userId,
  });

  /// Obtiene la cantidad de likes de una publicación
  Future<int> getPostLikesCount(String postId);

  // ========================================
  // MÉTODOS DE COMENTARIOS
  // ========================================

  /// Agrega un comentario a una publicación
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String content,
  });

  /// Obtiene todos los comentarios de una publicación
  Future<List<CommentModel>> getPostComments(String postId);

  /// Obtiene comentarios paginados de una publicación
  Future<List<CommentModel>> getPostCommentsPaginated({
    required String postId,
    required int page,
    int limit = 20,
  });

  /// Elimina un comentario
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });

  /// Actualiza un comentario
  Future<CommentModel> updateComment({
    required String commentId,
    required String userId,
    required String content,
  });

  /// Obtiene la cantidad de comentarios de una publicación
  Future<int> getPostCommentsCount(String postId);

  // ========================================
  // MÉTODOS DE UTILIDADES
  // ========================================

  /// Verifica si un usuario es el autor de una publicación
  Future<bool> isUserAuthor(String postId, String userId);

  /// Filtra publicaciones por tipo
  List<PostModel> filterByType(List<PostModel> posts, String tipo);

  /// Obtiene solo publicaciones de texto
  List<PostModel> getTextPosts(List<PostModel> posts);

  /// Obtiene solo publicaciones de rutas compartidas
  List<PostModel> getSharedRoutes(List<PostModel> posts);

  /// Obtiene solo publicaciones de eventos compartidos
  List<PostModel> getSharedEvents(List<PostModel> posts);

  /// Obtiene solo publicaciones de talleres compartidos
  List<PostModel> getSharedTalleres(List<PostModel> posts);
}
