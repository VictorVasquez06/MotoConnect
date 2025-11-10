import 'package:motoconnect/data/models/post_model.dart';
import 'package:motoconnect/data/repositories/post_repository.dart';

/// Caso de uso para obtener los posts de la comunidad
class GetPostsUseCase {
  final PostRepository _postRepository;

  GetPostsUseCase(this._postRepository);

  /// Ejecuta el caso de uso para obtener todos los posts
  /// 
  /// Retorna una lista de [PostModel] ordenados por fecha de creación
  /// Lanza una excepción si ocurre un error
  Future<List<PostModel>> call() async {
    try {
      final posts = await _postRepository.getAllPosts();
      return posts;
    } catch (e) {
      throw Exception('Error al obtener los posts: $e');
    }
  }

  /// Obtiene posts paginados
  /// 
  /// [page] - número de página a obtener
  /// [limit] - cantidad de posts por página
  Future<List<PostModel>> getPaginated({
    required int page,
    int limit = 10,
  }) async {
    try {
      final posts = await _postRepository.getPostsPaginated(
        page: page,
        limit: limit,
      );
      return posts;
    } catch (e) {
      throw Exception('Error al obtener posts paginados: $e');
    }
  }

  /// Obtiene posts de un usuario específico
  /// 
  /// [userId] - ID del usuario
  Future<List<PostModel>> getByUser(String userId) async {
    try {
      final posts = await _postRepository.getPostsByUser(userId);
      return posts;
    } catch (e) {
      throw Exception('Error al obtener posts del usuario: $e');
    }
  }
}
