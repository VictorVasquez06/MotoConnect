/// Eventos del CommunityBloc
///
/// Define todas las acciones que pueden modificar el estado de la comunidad.
library;

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos de comunidad
abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el feed de publicaciones
class CommunityFetchPosts extends CommunityEvent {
  final int? limit;

  const CommunityFetchPosts({this.limit});

  @override
  List<Object?> get props => [limit];
}

/// Evento para refrescar el feed (pull-to-refresh)
class CommunityRefreshPosts extends CommunityEvent {
  const CommunityRefreshPosts();
}

/// Evento para crear una nueva publicación de texto
class CommunityCreatePost extends CommunityEvent {
  final String userId;
  final String content;
  final String? imageUrl;

  const CommunityCreatePost({
    required this.userId,
    required this.content,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [userId, content, imageUrl];
}

/// Evento para compartir una ruta
class CommunityShareRoute extends CommunityEvent {
  final String userId;
  final String rutaId;
  final String? mensaje;

  const CommunityShareRoute({
    required this.userId,
    required this.rutaId,
    this.mensaje,
  });

  @override
  List<Object?> get props => [userId, rutaId, mensaje];
}

/// Evento para compartir un evento
class CommunityShareEvent extends CommunityEvent {
  final String userId;
  final String eventoId;
  final String? mensaje;

  const CommunityShareEvent({
    required this.userId,
    required this.eventoId,
    this.mensaje,
  });

  @override
  List<Object?> get props => [userId, eventoId, mensaje];
}

/// Evento para dar/quitar like a una publicación (toggle)
class CommunityLikePost extends CommunityEvent {
  final String postId;
  final String userId;

  const CommunityLikePost({required this.postId, required this.userId});

  @override
  List<Object?> get props => [postId, userId];
}

/// Evento para agregar un comentario a una publicación
class CommunityAddComment extends CommunityEvent {
  final String postId;
  final String userId;
  final String content;

  const CommunityAddComment({
    required this.postId,
    required this.userId,
    required this.content,
  });

  @override
  List<Object?> get props => [postId, userId, content];
}

/// Evento para eliminar un comentario
class CommunityDeleteComment extends CommunityEvent {
  final String commentId;
  final String userId;

  const CommunityDeleteComment({required this.commentId, required this.userId});

  @override
  List<Object?> get props => [commentId, userId];
}

/// Evento para eliminar una publicación
class CommunityDeletePost extends CommunityEvent {
  final String postId;

  const CommunityDeletePost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

/// Evento para cargar comentarios de una publicación específica
class CommunityFetchComments extends CommunityEvent {
  final String postId;

  const CommunityFetchComments({required this.postId});

  @override
  List<Object?> get props => [postId];
}
