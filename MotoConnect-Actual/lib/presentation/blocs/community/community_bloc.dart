/// CommunityBloc - Gestión de estado de la comunidad/feed social
///
/// Implementa la lógica de negocio para publicaciones usando BLoC pattern.
/// Depende de IPostRepository para abstracción de datos.
/// Implementa actualización optimista para likes.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_post_repository.dart';
import '../../../data/models/post_model.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final IPostRepository postRepository;

  CommunityBloc({required this.postRepository})
    : super(const CommunityInitial()) {
    on<CommunityFetchPosts>(_onFetchPosts);
    on<CommunityRefreshPosts>(_onRefreshPosts);
    on<CommunityCreatePost>(_onCreatePost);
    on<CommunityShareRoute>(_onShareRoute);
    on<CommunityShareEvent>(_onShareEvent);
    on<CommunityLikePost>(_onLikePost);
    on<CommunityAddComment>(_onAddComment);
    on<CommunityDeleteComment>(_onDeleteComment);
    on<CommunityDeletePost>(_onDeletePost);
    on<CommunityFetchComments>(_onFetchComments);
  }

  /// Carga el feed de publicaciones
  Future<void> _onFetchPosts(
    CommunityFetchPosts event,
    Emitter<CommunityState> emit,
  ) async {
    emit(const CommunityLoading());
    try {
      final posts = await postRepository.getPosts(limit: event.limit ?? 50);
      emit(CommunityLoaded(posts: posts));
    } catch (e) {
      emit(CommunityError(message: _parseErrorMessage(e)));
    }
  }

  /// Refresca el feed (pull-to-refresh)
  Future<void> _onRefreshPosts(
    CommunityRefreshPosts event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    if (currentState is CommunityLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      final posts = await postRepository.getPosts();
      emit(CommunityLoaded(posts: posts));
    } catch (e) {
      final previousPosts =
          currentState is CommunityLoaded ? currentState.posts : null;
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: previousPosts,
        ),
      );
    }
  }

  /// Crea una nueva publicación
  Future<void> _onCreatePost(
    CommunityCreatePost event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    emit(const CommunityLoading());
    try {
      final newPost = await postRepository.createPost(
        content: event.content,
        userId: event.userId,
        imageUrl: event.imageUrl,
      );

      // Agregar el nuevo post al inicio del feed
      final updatedPosts = [newPost, ...currentPosts];
      emit(
        CommunityOperationSuccess(
          message: 'Publicación creada exitosamente',
          posts: updatedPosts,
        ),
      );
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Comparte una ruta en la comunidad
  Future<void> _onShareRoute(
    CommunityShareRoute event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    emit(const CommunityLoading());
    try {
      final newPost = await postRepository.shareRoute(
        userId: event.userId,
        rutaId: event.rutaId,
        mensaje: event.mensaje,
      );

      final updatedPosts = [newPost, ...currentPosts];
      emit(
        CommunityOperationSuccess(
          message: 'Ruta compartida exitosamente',
          posts: updatedPosts,
        ),
      );
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Comparte un evento en la comunidad
  Future<void> _onShareEvent(
    CommunityShareEvent event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    emit(const CommunityLoading());
    try {
      final newPost = await postRepository.shareEvent(
        userId: event.userId,
        eventoId: event.eventoId,
        mensaje: event.mensaje,
      );

      final updatedPosts = [newPost, ...currentPosts];
      emit(
        CommunityOperationSuccess(
          message: 'Evento compartido exitosamente',
          posts: updatedPosts,
        ),
      );
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Da/quita like a una publicación (actualización optimista)
  Future<void> _onLikePost(
    CommunityLikePost event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    final posts = currentState.posts;
    final postIndex = posts.indexWhere((p) => p.id == event.postId);
    if (postIndex == -1) return;

    final post = posts[postIndex];
    final wasLiked = post.isLiked;

    // Actualización optimista: actualiza UI inmediatamente
    final optimisticPost = post.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );

    final optimisticPosts = List<PostModel>.from(posts);
    optimisticPosts[postIndex] = optimisticPost;
    emit(CommunityLoaded(posts: optimisticPosts));

    try {
      // Llamar a la API
      if (wasLiked) {
        await postRepository.unlikePost(
          postId: event.postId,
          userId: event.userId,
        );
      } else {
        await postRepository.likePost(
          postId: event.postId,
          userId: event.userId,
        );
      }
      // El estado optimista ya está correcto, no hacemos nada
    } catch (e) {
      // Revertir cambio optimista en caso de error
      final revertedPosts = List<PostModel>.from(optimisticPosts);
      revertedPosts[postIndex] = post;
      emit(CommunityLoaded(posts: revertedPosts));
    }
  }

  /// Agrega un comentario a una publicación
  Future<void> _onAddComment(
    CommunityAddComment event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    try {
      final newComment = await postRepository.addComment(
        postId: event.postId,
        userId: event.userId,
        content: event.content,
      );

      // Actualizar el contador de comentarios del post
      final updatedPosts =
          currentPosts.map((post) {
            if (post.id == event.postId) {
              final updatedComments = List<CommentModel>.from(
                post.comments ?? [],
              )..add(newComment);
              return post.copyWith(
                commentsCount: post.commentsCount + 1,
                comments: updatedComments,
              );
            }
            return post;
          }).toList();

      emit(CommunityLoaded(posts: updatedPosts));
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Elimina un comentario
  Future<void> _onDeleteComment(
    CommunityDeleteComment event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    try {
      await postRepository.deleteComment(
        commentId: event.commentId,
        userId: event.userId,
      );

      // Actualizar localmente eliminando el comentario
      final updatedPosts =
          currentPosts.map((post) {
            if (post.comments?.any((c) => c.id == event.commentId) == true) {
              return post.copyWith(
                commentsCount: post.commentsCount - 1,
                comments:
                    post.comments
                        ?.where((c) => c.id != event.commentId)
                        .toList(),
              );
            }
            return post;
          }).toList();

      emit(CommunityLoaded(posts: updatedPosts));
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Elimina una publicación
  Future<void> _onDeletePost(
    CommunityDeletePost event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    try {
      await postRepository.deletePost(event.postId);

      final updatedPosts =
          currentPosts.where((p) => p.id != event.postId).toList();
      emit(
        CommunityOperationSuccess(
          message: 'Publicación eliminada',
          posts: updatedPosts,
        ),
      );
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Carga los comentarios de una publicación específica
  Future<void> _onFetchComments(
    CommunityFetchComments event,
    Emitter<CommunityState> emit,
  ) async {
    final currentState = state;
    final currentPosts = _getCurrentPosts(currentState);

    emit(
      CommunityLoadingComments(
        posts: currentPosts,
        loadingPostId: event.postId,
      ),
    );

    try {
      final comments = await postRepository.getPostComments(event.postId);

      final updatedPosts =
          currentPosts.map((post) {
            if (post.id == event.postId) {
              return post.copyWith(comments: comments);
            }
            return post;
          }).toList();

      emit(CommunityLoaded(posts: updatedPosts));
    } catch (e) {
      emit(
        CommunityError(
          message: _parseErrorMessage(e),
          previousPosts: currentPosts,
        ),
      );
    }
  }

  /// Helper para obtener los posts actuales del estado
  List<PostModel> _getCurrentPosts(CommunityState state) {
    if (state is CommunityLoaded) return state.posts;
    if (state is CommunityOperationSuccess) return state.posts;
    if (state is CommunityError) return state.previousPosts ?? [];
    if (state is CommunityLoadingComments) return state.posts;
    return [];
  }

  /// Parsea mensajes de error para mostrar al usuario
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (message.contains('Permission')) {
      return 'No tienes permiso para esta acción';
    } else if (message.contains('not found')) {
      return 'Publicación no encontrada';
    }
    return 'Error: $message';
  }
}
