import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/post_model.dart';
import '../../blocs/community/community_bloc.dart';
import '../../blocs/community/community_event.dart';
import '../../blocs/community/community_state.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Cargar comentarios del post
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityBloc>().add(
        CommunityFetchComments(postId: widget.postId),
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Obtiene el post actual del estado del BLoC
  PostModel? _getPost(CommunityState state) {
    List<PostModel> posts = [];
    if (state is CommunityLoaded) {
      posts = state.posts;
    } else if (state is CommunityLoadingComments) {
      posts = state.posts;
    } else if (state is CommunityOperationSuccess) {
      posts = state.posts;
    }

    try {
      return posts.firstWhere((p) => p.id == widget.postId);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el ID del usuario actual
  String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              final post = _getPost(state);
              final currentUserId = _getCurrentUserId();

              // Verificar si el usuario actual es el dueño del post
              if (post != null &&
                  currentUserId != null &&
                  post.usuarioId == currentUserId) {
                return PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPost();
                    } else if (value == 'delete') {
                      _deletePost();
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CommunityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = _getPost(state);
          if (post == null) {
            return const Center(child: Text('Publicación no encontrada'));
          }

          final isLoadingComments =
              state is CommunityLoadingComments &&
              state.loadingPostId == widget.postId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostHeader(post),
                      _buildPostContent(post),
                      _buildPostStats(post),
                      const Divider(thickness: 8),
                      _buildComments(post, isLoadingComments),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                post.authorAvatar != null
                    ? NetworkImage(post.authorAvatar!)
                    : null,
            child:
                post.authorAvatar == null
                    ? Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(post.fecha),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (post.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getCategoryColor(post.category!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.category!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.title != null)
            Text(
              post.title!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          if (post.title != null) const SizedBox(height: 12),
          Text(
            post.contenido ?? '',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPostStats(PostModel post) {
    final currentUserId = _getCurrentUserId();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: post.isLiked ? Colors.red : Colors.grey[700]!,
            label: '${post.likesCount}',
            onTap: () {
              if (currentUserId != null) {
                context.read<CommunityBloc>().add(
                  CommunityLikePost(postId: post.id, userId: currentUserId),
                );
              }
            },
          ),
          const SizedBox(width: 24),
          _buildStatButton(
            icon: Icons.comment_outlined,
            iconColor: Colors.grey[700]!,
            label: '${post.commentsCount}',
            onTap: () {
              // Scroll to comments
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              post.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
              color:
                  post.isSaved == true
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
            ),
            onPressed: () {
              // TODO: Implementar toggle save cuando esté en el repositorio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de guardar próximamente disponible'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(PostModel post, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Comentarios (${post.commentsCount})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (post.comments == null || post.comments!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay comentarios aún',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sé el primero en comentar',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post.comments!.length,
            itemBuilder: (context, index) {
              final comment = post.comments![index];
              return _buildCommentItem(comment);
            },
          ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(comment.nombreUsuario[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.nombreUsuario,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(comment.contenido, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(comment.fecha),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Escribe un comentario...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendComment,
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para comentar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<CommunityBloc>().add(
      CommunityAddComment(
        postId: widget.postId,
        userId: currentUserId,
        content: _commentController.text.trim(),
      ),
    );

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _editPost() {
    Navigator.pushNamed(
      context,
      '/community/edit-post',
      arguments: widget.postId,
    );
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar publicación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta publicación? '
              'Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<CommunityBloc>().add(
                    CommunityDeletePost(postId: widget.postId),
                  );
                  Navigator.pop(dialogContext); // Cerrar diálogo
                  Navigator.pop(context); // Volver a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ELIMINAR'),
              ),
            ],
          ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'pregunta':
        return Colors.blue;
      case 'consejo':
        return Colors.green;
      case 'evento':
        return Colors.orange;
      case 'experiencia':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Ahora';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      final months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }
}
