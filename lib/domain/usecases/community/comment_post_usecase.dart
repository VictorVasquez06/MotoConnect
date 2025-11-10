import 'package:motoconnect/data/repositories/post_repository.dart';

/// Modelo para representar un comentario
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userAvatar;
  final String? userName;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userAvatar,
    this.userName,
  });
}

/// Caso de uso para gestionar los comentarios de los posts
class CommentPostUseCase {
  final PostRepository _postRepository;

  CommentPostUseCase(this._postRepository);

  /// Ejecuta el caso de uso para agregar un comentario a un post
  /// 
  /// [postId] - ID del post al que se le agregará el comentario
  /// [userId] - ID del usuario que comenta
  /// [content] - contenido del comentario
  /// 
  /// Retorna el [Comment] creado
  /// Lanza una excepción si ocurre un error
  Future<Comment> call({
    required String postId,
    required String userId,
    required String content,
  }) async {
    // Validaciones
    if (content.trim().isEmpty) {
      throw Exception('El comentario no puede estar vacío');
    }

    if (content.length > 500) {
      throw Exception('El comentario no puede exceder 500 caracteres');
    }

    try {
      final comment = await _postRepository.addComment(
        postId: postId,
        userId: userId,
        content: content,
      );
      return comment;
    } catch (e) {
      throw Exception('Error al agregar comentario: $e');
    }
  }

  /// Obtiene todos los comentarios de un post
  /// 
  /// [postId] - ID del post
  /// 
  /// Retorna una lista de [Comment]
  Future<List<Comment>> getComments(String postId) async {
    try {
      final comments = await _postRepository.getPostComments(postId);
      return comments;
    } catch (e) {
      throw Exception('Error al obtener comentarios: $e');
    }
  }

  /// Obtiene comentarios paginados de un post
  /// 
  /// [postId] - ID del post
  /// [page] - número de página
  /// [limit] - cantidad de comentarios por página
  Future<List<Comment>> getCommentsPaginated({
    required String postId,
    required int page,
    int limit = 20,
  }) async {
    try {
      final comments = await _postRepository.getPostCommentsPaginated(
        postId: postId,
        page: page,
        limit: limit,
      );
      return comments;
    } catch (e) {
      throw Exception('Error al obtener comentarios paginados: $e');
    }
  }

  /// Elimina un comentario
  /// 
  /// [commentId] - ID del comentario a eliminar
  /// [userId] - ID del usuario que intenta eliminar (debe ser el autor)
  /// 
  /// Retorna true si se eliminó exitosamente
  Future<bool> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      await _postRepository.deleteComment(
        commentId: commentId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al eliminar comentario: $e');
    }
  }

  /// Edita un comentario existente
  /// 
  /// [commentId] - ID del comentario
  /// [userId] - ID del usuario (debe ser el autor)
  /// [newContent] - nuevo contenido del comentario
  /// 
  /// Retorna el [Comment] actualizado
  Future<Comment> editComment({
    required String commentId,
    required String userId,
    required String newContent,
  }) async {
    // Validaciones
    if (newContent.trim().isEmpty) {
      throw Exception('El comentario no puede estar vacío');
    }

    if (newContent.length > 500) {
      throw Exception('El comentario no puede exceder 500 caracteres');
    }

    try {
      final comment = await _postRepository.updateComment(
        commentId: commentId,
        userId: userId,
        content: newContent,
      );
      return comment;
    } catch (e) {
      throw Exception('Error al editar comentario: $e');
    }
  }

  /// Obtiene la cantidad de comentarios de un post
  /// 
  /// [postId] - ID del post
  /// 
  /// Retorna el número de comentarios
  Future<int> getCommentsCount(String postId) async {
    try {
      return await _postRepository.getPostCommentsCount(postId);
    } catch (e) {
      throw Exception('Error al obtener cantidad de comentarios: $e');
    }
  }
}
