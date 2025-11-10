/// Modelo de Publicación de Comunidad
///
/// Representa los datos de una publicación en la comunidad
///
/// Este modelo es inmutable (final fields) y tiene:
/// - Constructor
/// - fromJson para deserialización
/// - toJson para serialización
library;

class PostModel {
  /// ID único de la publicación (UUID de Supabase)
  final String id;

  /// ID del usuario que creó la publicación
  final String usuarioId;

  /// Nombre del usuario (join con tabla usuarios)
  final String? nombreUsuario;

  /// Contenido de la publicación
  final String? contenido;

  /// Tipo de publicación (texto, ruta_compartida, evento_compartido, taller_compartido)
  final String tipo;

  /// Fecha de creación
  final DateTime fecha;

  /// ID de la ruta compartida (si aplica)
  final String? referenciaRutaId;

  /// Nombre de la ruta compartida (join con rutas_realizadas)
  final String? nombreRutaCompartida;

  /// ID del evento compartido (si aplica)
  final String? referenciaEventoId;

  /// Datos del evento compartido (join con eventos)
  final Map<String, dynamic>? eventoCompartidoData;

  /// Nombre del organizador del evento (para eventos compartidos)
  final String? nombreOrganizadorEvento;

  /// ID del taller compartido (si aplica)
  final String? referenciaTallerId;

  /// URL de imagen (opcional)
  final String? imagenUrl;

  /// URL del avatar del autor
  final String? authorAvatar;

  /// Categoría de la publicación
  final String? category;

  /// Título de la publicación
  final String? title;

  /// Contador de likes
  final int likesCount;

  /// Contador de comentarios
  final int commentsCount;

  /// Indica si el usuario actual dio like
  final bool isLiked;

  /// Indica si el usuario actual guardó el post
  final bool isSaved;

  /// Lista de comentarios
  final List<CommentModel>? comments;

  /// Constructor
  /// Constructor
  const PostModel({
    required this.id,
    required this.usuarioId,
    this.nombreUsuario,
    this.contenido,
    required this.tipo,
    required this.fecha,
    this.referenciaRutaId,
    this.nombreRutaCompartida,
    this.referenciaEventoId,
    this.eventoCompartidoData,
    this.nombreOrganizadorEvento,
    this.referenciaTallerId,
    this.imagenUrl,
    // Nuevos campos
    this.authorAvatar,
    this.category,
    this.title,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.comments,
  });

  /// Crea una instancia desde JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombreUsuario: json['nombre_usuario'] as String?,
      contenido: json['contenido'] as String?,
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      referenciaRutaId: json['referencia_ruta_id'] as String?,
      nombreRutaCompartida: json['nombre_ruta_compartida'] as String?,
      referenciaEventoId: json['referencia_evento_id'] as String?,
      eventoCompartidoData:
          json['evento_compartido_data'] as Map<String, dynamic>?,
      nombreOrganizadorEvento: json['nombre_organizador_evento'] as String?,
      referenciaTallerId: json['referencia_taller_id'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      // Nuevos campos
      authorAvatar: json['author_avatar'] as String?,
      category: json['categoria'] as String?,
      title: json['titulo'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'contenido': contenido,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'referencia_ruta_id': referenciaRutaId,
      'referencia_evento_id': referenciaEventoId,
      'referencia_taller_id': referenciaTallerId,
      'imagen_url': imagenUrl,
    };
  }

  /// Crea una copia con campos modificados
  PostModel copyWith({
    String? id,
    String? usuarioId,
    String? nombreUsuario,
    String? contenido,
    String? tipo,
    DateTime? fecha,
    String? referenciaRutaId,
    String? nombreRutaCompartida,
    String? referenciaEventoId,
    Map<String, dynamic>? eventoCompartidoData,
    String? nombreOrganizadorEvento,
    String? referenciaTallerId,
    String? imagenUrl,
    String? authorAvatar,
    String? category,
    String? title,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
    List<CommentModel>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      contenido: contenido ?? this.contenido,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      referenciaRutaId: referenciaRutaId ?? this.referenciaRutaId,
      nombreRutaCompartida: nombreRutaCompartida ?? this.nombreRutaCompartida,
      referenciaEventoId: referenciaEventoId ?? this.referenciaEventoId,
      eventoCompartidoData: eventoCompartidoData ?? this.eventoCompartidoData,
      nombreOrganizadorEvento:
          nombreOrganizadorEvento ?? this.nombreOrganizadorEvento,
      referenciaTallerId: referenciaTallerId ?? this.referenciaTallerId,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      title: title ?? this.title,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      comments: comments ?? this.comments,
    );
  }

  /// Indica si la publicación es de tipo texto
  bool get esTexto => tipo == 'texto';

  /// Indica si la publicación comparte una ruta
  bool get esRutaCompartida => tipo == 'ruta_compartida';

  /// Indica si la publicación comparte un evento
  bool get esEventoCompartido => tipo == 'evento_compartido';

  /// Indica si la publicación comparte un taller
  bool get esTallerCompartido => tipo == 'taller_compartido';

  /// Nombre del autor (alias para compatibilidad)
  String get authorName => nombreUsuario ?? 'Usuario Anónimo';
}

/// Modelo de Comentario
class CommentModel {
  final String id;
  final String postId;
  final String usuarioId;
  final String nombreUsuario;
  final String contenido;
  final DateTime fecha;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.contenido,
    required this.fecha,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombreUsuario: json['nombre_usuario'] as String,
      contenido: json['contenido'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}
