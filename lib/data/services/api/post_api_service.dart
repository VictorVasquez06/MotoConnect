/// Servicio de API de Publicaciones de Comunidad
///
/// Capa más baja de abstracción - interactúa directamente con Supabase
///
/// Responsabilidades:
/// - Llamadas a Supabase para publicaciones de comunidad
/// - Gestión de likes y comentarios
/// - Upload de imágenes
/// - Conversión de respuestas a modelos
/// - Manejo de errores de API
library;

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/post_model.dart';
import '../../usecases/comment_post_usecase.dart';

class PostApiService {
  // ========================================
  // CLIENTE SUPABASE
  // ========================================

  /// Cliente de Supabase
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ========================================
  // MÉTODOS PÚBLICOS - CRUD PUBLICACIONES
  // ========================================

  /// Obtiene todas las publicaciones de la comunidad
  Future<List<PostModel>> getPosts({int limit = 50}) async {
    try {
      final response = await _supabase
          .from(ApiConstants.postsTable)
          .select()
          .order('fecha', ascending: false)
          .limit(limit);

      final List<Map<String, dynamic>> postsData =
          List<Map<String, dynamic>>.from(response);

      List<PostModel> posts = [];

      for (var postData in postsData) {
        // Obtener nombre del usuario
        String? nombreUsuario;
        if (postData['usuario_id'] != null) {
          nombreUsuario = await _getUserName(postData['usuario_id'] as String);
        }

        // Obtener información adicional según el tipo de publicación
        String? nombreRuta;
        Map<String, dynamic>? eventoData;
        String? nombreOrganizador;

        final tipo = postData['tipo'] as String?;

        if (tipo == 'ruta_compartida' &&
            postData['referencia_ruta_id'] != null) {
          nombreRuta = await _getRouteName(
            postData['referencia_ruta_id'] as String,
          );
        } else if (tipo == 'evento_compartido' &&
            postData['referencia_evento_id'] != null) {
          eventoData = await _getEventData(
            postData['referencia_evento_id'] as String,
          );
          if (eventoData != null && eventoData['creado_por'] != null) {
            nombreOrganizador = await _getUserName(
              eventoData['creado_por'] as String,
            );
          }
        }

        posts.add(
          PostModel(
            id: postData['id'] as String,
            usuarioId: postData['usuario_id'] as String,
            nombreUsuario: nombreUsuario,
            contenido: postData['contenido'] as String?,
            tipo: tipo ?? 'texto',
            fecha: DateTime.parse(postData['fecha'] as String),
            referenciaRutaId: postData['referencia_ruta_id'] as String?,
            nombreRutaCompartida: nombreRuta,
            referenciaEventoId: postData['referencia_evento_id'] as String?,
            eventoCompartidoData: eventoData,
            nombreOrganizadorEvento: nombreOrganizador,
            referenciaTallerId: postData['referencia_taller_id'] as String?,
            imagenUrl: postData['imagen_url'] as String?,
          ),
        );
      }

      return posts;
    } catch (e) {
      throw Exception('Error al obtener publicaciones: ${e.toString()}');
    }
  }

  /// Obtiene publicaciones paginadas
  Future<List<PostModel>> getPostsPaginated({
    required int page,
    int limit = 10,
  }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from(ApiConstants.postsTable)
          .select()
          .order('fecha', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Map<String, dynamic>> postsData =
          List<Map<String, dynamic>>.from(response);

      List<PostModel> posts = [];

      for (var postData in postsData) {
        String? nombreUsuario;
        if (postData['usuario_id'] != null) {
          nombreUsuario = await _getUserName(postData['usuario_id'] as String);
        }

        posts.add(
          PostModel(
            id: postData['id'] as String,
            usuarioId: postData['usuario_id'] as String,
            nombreUsuario: nombreUsuario,
            contenido: postData['contenido'] as String?,
            tipo: postData['tipo'] as String? ?? 'texto',
            fecha: DateTime.parse(postData['fecha'] as String),
            imagenUrl: postData['imagen_url'] as String?,
          ),
        );
      }

      return posts;
    } catch (e) {
      throw Exception('Error al obtener posts paginados: ${e.toString()}');
    }
  }

  /// Obtiene una publicación por ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .select()
              .eq('id', postId)
              .maybeSingle();

      if (response == null) return null;

      // Similar processing as in getPosts but for a single post
      final postData = response;

      String? nombreUsuario;
      if (postData['usuario_id'] != null) {
        nombreUsuario = await _getUserName(postData['usuario_id'] as String);
      }

      return PostModel.fromJson({...postData, 'nombre_usuario': nombreUsuario});
    } catch (e) {
      throw Exception('Error al obtener publicación: ${e.toString()}');
    }
  }

  /// Crea una nueva publicación (método genérico)
  Future<PostModel> createPost({
    required String userId,
    required String contenido,
    String? imagenUrl,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .insert({
                'usuario_id': userId,
                'contenido': contenido,
                'tipo': 'texto',
                'fecha': DateTime.now().toIso8601String(),
                if (imagenUrl != null) 'imagen_url': imagenUrl,
              })
              .select()
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear publicación: ${e.toString()}');
    }
  }

  /// Crea una nueva publicación de texto
  Future<PostModel> createTextPost({
    required String userId,
    required String contenido,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .insert({
                'usuario_id': userId,
                'contenido': contenido,
                'tipo': 'texto',
                'fecha': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear publicación: ${e.toString()}');
    }
  }

  /// Sube una imagen al storage de Supabase
  Future<String> uploadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final bucketName = 'posts'; // Ajusta según tu configuración

      await _supabase.storage
          .from(bucketName)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  /// Comparte una ruta en la comunidad
  Future<PostModel> shareRoute({
    required String userId,
    required String rutaId,
    String? mensaje,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .insert({
                'usuario_id': userId,
                'contenido': mensaje,
                'tipo': 'ruta_compartida',
                'referencia_ruta_id': rutaId,
                'fecha': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al compartir ruta: ${e.toString()}');
    }
  }

  /// Comparte un evento en la comunidad
  Future<PostModel> shareEvent({
    required String userId,
    required String eventoId,
    String? mensaje,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .insert({
                'usuario_id': userId,
                'contenido': mensaje,
                'tipo': 'evento_compartido',
                'referencia_evento_id': eventoId,
                'fecha': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al compartir evento: ${e.toString()}');
    }
  }

  /// Comparte un taller en la comunidad
  Future<PostModel> shareTaller({
    required String userId,
    required String tallerId,
    String? mensaje,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.postsTable)
              .insert({
                'usuario_id': userId,
                'contenido': mensaje,
                'tipo': 'taller_compartido',
                'referencia_taller_id': tallerId,
                'fecha': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al compartir taller: ${e.toString()}');
    }
  }

  /// Actualiza una publicación
  Future<void> updatePost({required String postId, String? contenido}) async {
    try {
      if (contenido == null) return;

      await _supabase
          .from(ApiConstants.postsTable)
          .update({'contenido': contenido})
          .eq('id', postId);
    } catch (e) {
      throw Exception('Error al actualizar publicación: ${e.toString()}');
    }
  }

  /// Elimina una publicación
  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from(ApiConstants.postsTable).delete().eq('id', postId);
    } catch (e) {
      throw Exception('Error al eliminar publicación: ${e.toString()}');
    }
  }

  /// Obtiene publicaciones de un usuario específico
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.postsTable)
          .select()
          .eq('usuario_id', userId)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Error al obtener publicaciones del usuario: ${e.toString()}',
      );
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - LIKES
  // ========================================

  /// Da like a una publicación
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase.from(ApiConstants.likesTable).insert({
        'post_id': postId,
        'usuario_id': userId,
        'fecha': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al dar like: ${e.toString()}');
    }
  }

  /// Quita el like de una publicación
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(ApiConstants.likesTable)
          .delete()
          .eq('post_id', postId)
          .eq('usuario_id', userId);
    } catch (e) {
      throw Exception('Error al quitar like: ${e.toString()}');
    }
  }

  /// Verifica si un usuario ha dado like a una publicación
  Future<bool> hasUserLikedPost({
    required String postId,
    required String userId,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.likesTable)
              .select()
              .eq('post_id', postId)
              .eq('usuario_id', userId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Error al verificar like: ${e.toString()}');
    }
  }

  /// Obtiene la cantidad de likes de una publicación
  Future<int> getPostLikesCount(String postId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.likesTable)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);

      // La respuesta incluye el conteo en el header
      return (response as List).length;
    } catch (e) {
      throw Exception('Error al obtener cantidad de likes: ${e.toString()}');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - COMENTARIOS
  // ========================================

  /// Agrega un comentario a una publicación
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.commentsTable)
              .insert({
                'post_id': postId,
                'usuario_id': userId,
                'contenido': content,
                'fecha': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      // Obtener nombre del usuario
      final userName = await _getUserName(userId);

      return Comment(
        id: response['id'] as String,
        postId: response['post_id'] as String,
        userId: response['usuario_id'] as String,
        content: response['contenido'] as String,
        createdAt: DateTime.parse(response['fecha'] as String),
        userName: userName,
      );
    } catch (e) {
      throw Exception('Error al agregar comentario: ${e.toString()}');
    }
  }

  /// Obtiene todos los comentarios de una publicación
  Future<List<Comment>> getPostComments(String postId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.commentsTable)
          .select()
          .eq('post_id', postId)
          .order('fecha', ascending: true);

      final List<Comment> comments = [];

      for (var commentData in response as List) {
        final userName = await _getUserName(
          commentData['usuario_id'] as String,
        );

        comments.add(
          Comment(
            id: commentData['id'] as String,
            postId: commentData['post_id'] as String,
            userId: commentData['usuario_id'] as String,
            content: commentData['contenido'] as String,
            createdAt: DateTime.parse(commentData['fecha'] as String),
            userName: userName,
          ),
        );
      }

      return comments;
    } catch (e) {
      throw Exception('Error al obtener comentarios: ${e.toString()}');
    }
  }

  /// Obtiene comentarios paginados de una publicación
  Future<List<Comment>> getPostCommentsPaginated({
    required String postId,
    required int page,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from(ApiConstants.commentsTable)
          .select()
          .eq('post_id', postId)
          .order('fecha', ascending: true)
          .range(offset, offset + limit - 1);

      final List<Comment> comments = [];

      for (var commentData in response as List) {
        final userName = await _getUserName(
          commentData['usuario_id'] as String,
        );

        comments.add(
          Comment(
            id: commentData['id'] as String,
            postId: commentData['post_id'] as String,
            userId: commentData['usuario_id'] as String,
            content: commentData['contenido'] as String,
            createdAt: DateTime.parse(commentData['fecha'] as String),
            userName: userName,
          ),
        );
      }

      return comments;
    } catch (e) {
      throw Exception(
        'Error al obtener comentarios paginados: ${e.toString()}',
      );
    }
  }

  /// Elimina un comentario
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      // Verificar que el usuario es el autor del comentario
      final comment =
          await _supabase
              .from(ApiConstants.commentsTable)
              .select()
              .eq('id', commentId)
              .single();

      if (comment['usuario_id'] != userId) {
        throw Exception('No tienes permisos para eliminar este comentario');
      }

      await _supabase
          .from(ApiConstants.commentsTable)
          .delete()
          .eq('id', commentId);
    } catch (e) {
      throw Exception('Error al eliminar comentario: ${e.toString()}');
    }
  }

  /// Actualiza un comentario
  Future<Comment> updateComment({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    try {
      // Verificar que el usuario es el autor del comentario
      final comment =
          await _supabase
              .from(ApiConstants.commentsTable)
              .select()
              .eq('id', commentId)
              .single();

      if (comment['usuario_id'] != userId) {
        throw Exception('No tienes permisos para editar este comentario');
      }

      final response =
          await _supabase
              .from(ApiConstants.commentsTable)
              .update({'contenido': content})
              .eq('id', commentId)
              .select()
              .single();

      final userName = await _getUserName(userId);

      return Comment(
        id: response['id'] as String,
        postId: response['post_id'] as String,
        userId: response['usuario_id'] as String,
        content: response['contenido'] as String,
        createdAt: DateTime.parse(response['fecha'] as String),
        userName: userName,
      );
    } catch (e) {
      throw Exception('Error al actualizar comentario: ${e.toString()}');
    }
  }

  /// Obtiene la cantidad de comentarios de una publicación
  Future<int> getPostCommentsCount(String postId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.commentsTable)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      throw Exception(
        'Error al obtener cantidad de comentarios: ${e.toString()}',
      );
    }
  }

  // ========================================
  // MÉTODOS PRIVADOS - HELPERS
  // ========================================

  /// Obtiene el nombre de un usuario
  Future<String?> _getUserName(String userId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.usersTable)
              .select('nombre')
              .eq('id', userId)
              .maybeSingle();

      return response?['nombre'] as String?;
    } catch (e) {
      print('Error obteniendo nombre de usuario: $e');
      return null;
    }
  }

  /// Obtiene el nombre de una ruta
  Future<String?> _getRouteName(String rutaId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.routesTable)
              .select('nombre_ruta')
              .eq('id', rutaId)
              .maybeSingle();

      return response?['nombre_ruta'] as String?;
    } catch (e) {
      print('Error obteniendo nombre de ruta: $e');
      return null;
    }
  }

  /// Obtiene los datos de un evento
  Future<Map<String, dynamic>?> _getEventData(String eventoId) async {
    try {
      final response =
          await _supabase
              .from(ApiConstants.eventsTable)
              .select()
              .eq('id', eventoId)
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error obteniendo datos de evento: $e');
      return null;
    }
  }
}
