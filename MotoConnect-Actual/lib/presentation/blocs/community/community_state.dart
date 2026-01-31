/// Estados del CommunityBloc
///
/// Define todos los posibles estados de la comunidad/feed.
library;

import 'package:equatable/equatable.dart';
import '../../../data/models/post_model.dart';

/// Clase base abstracta para todos los estados de comunidad
abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar publicaciones
class CommunityInitial extends CommunityState {
  const CommunityInitial();
}

/// Estado de carga durante operaciones
class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

/// Estado con publicaciones cargadas exitosamente
class CommunityLoaded extends CommunityState {
  final List<PostModel> posts;
  final bool isRefreshing;

  const CommunityLoaded({required this.posts, this.isRefreshing = false});

  @override
  List<Object?> get props => [posts, isRefreshing];

  /// Crea una copia con campos modificados
  CommunityLoaded copyWith({List<PostModel>? posts, bool? isRefreshing}) {
    return CommunityLoaded(
      posts: posts ?? this.posts,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Estado de error en operaciones de comunidad
class CommunityError extends CommunityState {
  final String message;
  final List<PostModel>? previousPosts;

  const CommunityError({required this.message, this.previousPosts});

  @override
  List<Object?> get props => [message, previousPosts];
}

/// Estado de éxito para operaciones como crear post
class CommunityOperationSuccess extends CommunityState {
  final String message;
  final List<PostModel> posts;

  const CommunityOperationSuccess({required this.message, required this.posts});

  @override
  List<Object?> get props => [message, posts];
}

/// Estado para cuando se están cargando los comentarios de un post
class CommunityLoadingComments extends CommunityState {
  final List<PostModel> posts;
  final String loadingPostId;

  const CommunityLoadingComments({
    required this.posts,
    required this.loadingPostId,
  });

  @override
  List<Object?> get props => [posts, loadingPostId];
}
