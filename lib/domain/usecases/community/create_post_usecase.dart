import 'package:motoconnect/data/models/post_model.dart';
import 'package:motoconnect/data/repositories/post_repository.dart';

/// Caso de uso para crear un nuevo post en la comunidad
class CreatePostUseCase {
  final PostRepository _postRepository;

  CreatePostUseCase(this._postRepository);

  /// Ejecuta el caso de uso para crear un nuevo post
  /// 
  /// [content] - contenido del post
  /// [userId] - ID del usuario que crea el post
  /// [imageUrl] - URL de la imagen (opcional)
  /// 
  /// Retorna el [PostModel] creado
  /// Lanza una excepción si ocurre un error
  Future<PostModel> call({
    required String content,
    required String userId,
    String? imageUrl,
  }) async {
    // Validaciones
    if (content.trim().isEmpty) {
      throw Exception('El contenido del post no puede estar vacío');
    }

    if (content.length > 1000) {
      throw Exception('El contenido del post no puede exceder 1000 caracteres');
    }

    try {
      final post = await _postRepository.createPost(
        content: content,
        userId: userId,
        imageUrl: imageUrl,
      );
      return post;
    } catch (e) {
      throw Exception('Error al crear el post: $e');
    }
  }

  /// Crea un post con imagen
  /// 
  /// [content] - contenido del post
  /// [userId] - ID del usuario
  /// [imagePath] - ruta local de la imagen a subir
  Future<PostModel> createWithImage({
    required String content,
    required String userId,
    required String imagePath,
  }) async {
    if (content.trim().isEmpty) {
      throw Exception('El contenido del post no puede estar vacío');
    }

    try {
      // Primero subir la imagen
      final imageUrl = await _postRepository.uploadImage(imagePath);
      
      // Luego crear el post con la URL de la imagen
      final post = await _postRepository.createPost(
        content: content,
        userId: userId,
        imageUrl: imageUrl,
      );
      
      return post;
    } catch (e) {
      throw Exception('Error al crear post con imagen: $e');
    }
  }
}
