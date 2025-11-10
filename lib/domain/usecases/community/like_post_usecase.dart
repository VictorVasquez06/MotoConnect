import 'package:motoconnect/data/repositories/post_repository.dart';

/// Caso de uso para gestionar los likes de los posts
class LikePostUseCase {
  final PostRepository _postRepository;

  LikePostUseCase(this._postRepository);

  /// Ejecuta el caso de uso para dar like a un post
  /// 
  /// [postId] - ID del post al que se le dará like
  /// [userId] - ID del usuario que da el like
  /// 
  /// Retorna true si el like fue agregado exitosamente
  /// Lanza una excepción si ocurre un error
  Future<bool> call({
    required String postId,
    required String userId,
  }) async {
    try {
      await _postRepository.likePost(
        postId: postId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al dar like al post: $e');
    }
  }

  /// Remueve el like de un post
  /// 
  /// [postId] - ID del post
  /// [userId] - ID del usuario
  /// 
  /// Retorna true si el like fue removido exitosamente
  Future<bool> unlike({
    required String postId,
    required String userId,
  }) async {
    try {
      await _postRepository.unlikePost(
        postId: postId,
        userId: userId,
      );
      return true;
    } catch (e) {
      throw Exception('Error al quitar like del post: $e');
    }
  }

  /// Alterna el estado del like (toggle)
  /// Si tiene like, lo remueve. Si no tiene like, lo agrega.
  /// 
  /// [postId] - ID del post
  /// [userId] - ID del usuario
  /// [isLiked] - estado actual del like
  /// 
  /// Retorna el nuevo estado del like
  Future<bool> toggle({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      if (isLiked) {
        await unlike(postId: postId, userId: userId);
        return false;
      } else {
        await call(postId: postId, userId: userId);
        return true;
      }
    } catch (e) {
      throw Exception('Error al alternar like del post: $e');
    }
  }

  /// Verifica si un usuario ha dado like a un post
  /// 
  /// [postId] - ID del post
  /// [userId] - ID del usuario
  /// 
  /// Retorna true si el usuario ha dado like al post
  Future<bool> hasLiked({
    required String postId,
    required String userId,
  }) async {
    try {
      return await _postRepository.hasUserLikedPost(
        postId: postId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Error al verificar like del post: $e');
    }
  }

  /// Obtiene la cantidad de likes de un post
  /// 
  /// [postId] - ID del post
  /// 
  /// Retorna el número de likes
  Future<int> getLikesCount(String postId) async {
    try {
      return await _postRepository.getPostLikesCount(postId);
    } catch (e) {
      throw Exception('Error al obtener cantidad de likes: $e');
    }
  }
}
