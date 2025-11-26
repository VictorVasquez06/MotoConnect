import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/storage_service.dart';
import 'package:video_player/video_player.dart';

// Clase auxiliar para combinar datos de la publicación con el nombre del autor y detalles del evento/ruta
class PublicacionConAutor {
  final Map<String, dynamic> publicacionData;
  final String? nombreAutor; // Quién hizo la publicación en comunidad
  final String? nombreRutaCompartida;
  final String? idRutaCompartida;
  final Map<String, dynamic>?
  eventoCompartidoData; // Datos del evento compartido
  final String?
  nombreOrganizadorEvento; // Nombre del creador original del evento

  PublicacionConAutor({
    required this.publicacionData,
    this.nombreAutor,
    this.nombreRutaCompartida,
    this.idRutaCompartida,
    this.eventoCompartidoData,
    this.nombreOrganizadorEvento,
  });
}

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  List<PublicacionConAutor> _publicacionesConAutor = [];
  bool _cargando = true;
  final TextEditingController _textoController = TextEditingController();
  final Map<String, String> _cacheNombres = {}; // Cache para nombres de usuario
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // Estado para media seleccionada
  File? _selectedMediaFile;
  bool _isVideo = false;
  bool _subiendoMedia = false;

  @override
  void initState() {
    super.initState();
    _obtenerPublicaciones();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<String?> _obtenerNombreUsuario(String userId) async {
    if (_cacheNombres.containsKey(userId)) {
      return _cacheNombres[userId];
    }
    try {
      final respuesta =
          await Supabase.instance.client
              .from('usuarios')
              .select('nombre')
              .eq('id', userId)
              .single();
      final nombre = respuesta['nombre'] as String?;
      if (nombre != null && mounted) {
        _cacheNombres[userId] = nombre;
      }
      return nombre;
    } catch (e) {
      print("Error obteniendo nombre para usuario $userId (Comunidad): $e");
      return "Usuario Anónimo"; // O un placeholder que prefieras
    }
  }

  Future<void> _obtenerPublicaciones() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final respuestaPublicaciones = await Supabase.instance.client
          .from('comentarios_comunidad')
          .select() // Selecciona todos los campos de la publicación
          .order('fecha', ascending: false);

      List<PublicacionConAutor> tempLista = [];
      for (var publicacionData in respuestaPublicaciones) {
        String? nombreAutor; // Quién hizo la publicación en comunidad
        final autorId = publicacionData['usuario_id'] as String?;
        if (autorId != null) {
          nombreAutor = await _obtenerNombreUsuario(autorId);
        }

        String? nombreRutaComp;
        String? idRutaComp = publicacionData['referencia_ruta_id'] as String?;
        Map<String, dynamic>? eventoDataComp;
        String? nombreOrganizadorEv;
        String? idEventoComp =
            publicacionData['referencia_evento_id'] as String?;

        final tipoPublicacion = publicacionData['tipo'] as String?;

        if (tipoPublicacion == 'ruta_compartida' && idRutaComp != null) {
          try {
            final rutaRes =
                await Supabase.instance.client
                    .from('rutas_realizadas')
                    .select('nombre_ruta')
                    .eq('id', idRutaComp)
                    .single();
            nombreRutaComp = rutaRes['nombre_ruta'] as String?;
          } catch (e) {
            print("Error obteniendo nombre de ruta compartida $idRutaComp: $e");
            nombreRutaComp = "Ruta eliminada o no encontrada";
          }
        } else if (tipoPublicacion == 'evento_compartido' &&
            idEventoComp != null) {
          try {
            // Obtener todos los datos del evento
            final eventoRes =
                await Supabase.instance.client
                    .from('eventos')
                    .select() // Puedes ser más específico con los campos si lo deseas: 'titulo, descripcion, fecha_hora, ubicacion, creado_por, id'
                    .eq('id', idEventoComp)
                    .single();
            eventoDataComp = eventoRes;

            // Obtener nombre del organizador del evento
            final organizadorIdEvento = eventoDataComp['creado_por'] as String?;
            if (organizadorIdEvento != null) {
              nombreOrganizadorEv = await _obtenerNombreUsuario(
                organizadorIdEvento,
              );
            }
          } catch (e) {
            print(
              "Error obteniendo datos del evento compartido $idEventoComp: $e",
            );
            // Crear un mapa placeholder para que la UI no falle catastróficamente
            eventoDataComp = {
              'titulo': 'Evento no disponible',
              'descripcion': 'Este evento pudo haber sido eliminado.',
              'id': idEventoComp, // Mantenemos el ID por si acaso
            };
            nombreOrganizadorEv = "Desconocido";
          }
        }

        tempLista.add(
          PublicacionConAutor(
            publicacionData: publicacionData,
            nombreAutor: nombreAutor ?? "Usuario Anónimo",
            nombreRutaCompartida: nombreRutaComp,
            idRutaCompartida: idRutaComp,
            eventoCompartidoData: eventoDataComp,
            nombreOrganizadorEvento: nombreOrganizadorEv,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _publicacionesConAutor = tempLista;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error al cargar publicaciones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar publicaciones: ${e.toString()}"),
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  /// Selecciona una imagen de la galería
  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedMediaFile = File(image.path);
          _isVideo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Selecciona un video de la galería
  Future<void> _seleccionarVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2), // Máximo 2 minutos
      );

      if (video != null) {
        setState(() {
          _selectedMediaFile = File(video.path);
          _isVideo = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar video: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Limpia el archivo seleccionado
  void _limpiarMediaSeleccionada() {
    setState(() {
      _selectedMediaFile = null;
      _isVideo = false;
    });
  }

  /// Elimina una publicación
  Future<void> _eliminarPublicacion(String publicacionId, String? mediaUrl) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta publicación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      setState(() => _cargando = true);

      // Eliminar el archivo de media si existe
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        await _storageService.deleteCommunityMedia(mediaUrl: mediaUrl);
      }

      // Eliminar la publicación de la base de datos
      await Supabase.instance.client
          .from('comentarios_comunidad')
          .delete()
          .eq('id', publicacionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación eliminada')),
        );
        _obtenerPublicaciones();
      }
    } catch (e) {
      print("Error al eliminar publicación: $e");
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Edita una publicación
  Future<void> _editarPublicacion(String publicacionId, String contenidoActual) async {
    final controller = TextEditingController(text: contenidoActual);

    final nuevoContenido = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar publicación'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '¿Qué quieres compartir?',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoContenido == null || nuevoContenido.isEmpty) return;

    try {
      setState(() => _cargando = true);

      await Supabase.instance.client
          .from('comentarios_comunidad')
          .update({'contenido': nuevoContenido})
          .eq('id', publicacionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación actualizada')),
        );
        _obtenerPublicaciones();
      }
    } catch (e) {
      print("Error al editar publicación: $e");
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al editar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _crearPublicacionTexto() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para publicar.")),
        );
      }
      return;
    }

    final String contenido = _textoController.text.trim();
    if (contenido.isEmpty && _selectedMediaFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Escribe algo o selecciona una imagen/video."),
          ),
        );
      }
      return;
    }

    try {
      if (mounted) setState(() => _subiendoMedia = true);

      String? mediaUrl;
      String tipo = 'texto';

      // Si hay un archivo seleccionado, subirlo primero
      if (_selectedMediaFile != null) {
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        mediaUrl = await _storageService.uploadCommunityMedia(
          mediaFile: _selectedMediaFile!,
          userId: currentUser.id,
          postId: postId,
          isVideo: _isVideo,
        );
        tipo = _isVideo ? 'video' : 'imagen';
      }

      // Crear la publicación en la base de datos
      await Supabase.instance.client.from('comentarios_comunidad').insert({
        'usuario_id': currentUser.id,
        'contenido': contenido.isEmpty ? null : contenido,
        'tipo': tipo,
        'fecha': DateTime.now().toIso8601String(),
        'media_url': mediaUrl,
      });

      _textoController.clear();
      _limpiarMediaSeleccionada();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Publicación creada.")));
        _obtenerPublicaciones();
      }
    } catch (e) {
      print("Error al crear publicación: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al crear la publicación: ${e.toString()}"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoMedia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comunidad Biker")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _publicacionesConAutor.isEmpty
                      ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.forum_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Aún no hay publicaciones.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "¡Sé el primero en compartir algo!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _obtenerPublicaciones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _publicacionesConAutor.length,
                        itemBuilder: (context, index) {
                          final item = _publicacionesConAutor[index];
                          final publicacion = item.publicacionData;
                          final publicacionId = publicacion['id'] as String?;
                          final nombreAutor =
                              item.nombreAutor; // Quién compartió en comunidad
                          final nombreRutaCompartida =
                              item.nombreRutaCompartida;
                          final idRutaCompartida = item.idRutaCompartida;
                          final eventoCompartido =
                              item.eventoCompartidoData; // Datos del evento
                          final nombreOrganizadorEvento =
                              item.nombreOrganizadorEvento; // Nombre del creador del evento

                          String fechaFormateadaPublicacion =
                              'Fecha desconocida';
                          if (publicacion['fecha'] != null) {
                            try {
                              fechaFormateadaPublicacion = DateFormat(
                                'dd MMM yy, hh:mm a',
                                'es_CO',
                              ).format(
                                DateTime.parse(publicacion['fecha']).toLocal(),
                              );
                            } catch (e) {
                              print("Error formateando fecha publicación: $e");
                              fechaFormateadaPublicacion = publicacion['fecha'];
                            }
                          }
                          final String tipoPublicacion =
                              publicacion['tipo'] ?? 'texto';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondaryContainer,
                                        child: const Icon(Icons.person_outline),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombreAutor ?? "Usuario",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              fechaFormateadaPublicacion,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Menú de opciones (solo si es el autor)
                                      if (publicacion['usuario_id'] ==
                                          Supabase.instance.client.auth.currentUser?.id)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.grey,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'editar') {
                                              _editarPublicacion(
                                                publicacionId!,
                                                publicacion['contenido'] ?? '',
                                              );
                                            } else if (value == 'eliminar') {
                                              _eliminarPublicacion(
                                                publicacionId!,
                                                publicacion['media_url'],
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'eliminar',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Contenido textual de la publicación (mensaje del usuario)
                                  if (publicacion['contenido'] != null &&
                                      (publicacion['contenido'] as String)
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Text(publicacion['contenido']),
                                    ),

                                  // ---- INICIO: Mostrar IMAGEN ----
                                  if (tipoPublicacion == 'imagen' &&
                                      publicacion['media_url'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          publicacion['media_url'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          loadingBuilder:
                                              (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  // ---- FIN: Mostrar IMAGEN ----

                                  // ---- INICIO: Mostrar VIDEO ----
                                  if (tipoPublicacion == 'video' &&
                                      publicacion['media_url'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: _VideoPlayerWidget(
                                        videoUrl: publicacion['media_url'],
                                      ),
                                    ),
                                  // ---- FIN: Mostrar VIDEO ----

                                  // ---- INICIO: Lógica para mostrar RUTA COMPARTIDA ----
                                  if (tipoPublicacion == 'ruta_compartida')
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ha compartido la ruta:",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          nombreRutaCompartida ??
                                              "Nombre de ruta no disponible",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.map_outlined,
                                            size: 18,
                                          ),
                                          label: const Text("Ver Ruta en Mapa"),
                                          onPressed: () {
                                            if (idRutaCompartida != null) {
                                              Navigator.pushNamed(
                                                context,
                                                '/rutas',
                                                arguments: {
                                                  'ruta_id_para_cargar':
                                                      idRutaCompartida,
                                                },
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "No se puede abrir la ruta.",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  // ---- FIN: Lógica para mostrar RUTA COMPARTIDA ----

                                  // ---- INICIO: Lógica para mostrar EVENTO COMPARTIDO ----
                                  if (tipoPublicacion == 'evento_compartido' &&
                                      eventoCompartido != null)
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_note_rounded,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  eventoCompartido['titulo'] ??
                                                      'Evento Compartido',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (nombreOrganizadorEvento != null &&
                                              nombreOrganizadorEvento !=
                                                  "Usuario Anónimo" &&
                                              nombreOrganizadorEvento !=
                                                  item.nombreAutor) // No mostrar si el que comparte es el mismo organizador
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2.0,
                                                bottom: 4.0,
                                              ),
                                              child: Text(
                                                "Organizado por: $nombreOrganizadorEvento",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          if (eventoCompartido['fecha_hora'] !=
                                              null)
                                            Text(
                                              "🗓️ Fecha: ${DateFormat('dd MMM yy, hh:mm a', 'es_CO').format(DateTime.parse(eventoCompartido['fecha_hora']).toLocal())}",
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          const SizedBox(height: 4),
                                          if (eventoCompartido['ubicacion'] !=
                                                  null &&
                                              (eventoCompartido['ubicacion']
                                                      as String)
                                                  .isNotEmpty)
                                            Text(
                                              "📍 Lugar: ${eventoCompartido['ubicacion']}",
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),

                                          if (eventoCompartido['descripcion'] !=
                                                  null &&
                                              (eventoCompartido['descripcion']
                                                      as String)
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              child: Text(
                                                "ℹ️ ${eventoCompartido['descripcion']}",
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          if (eventoCompartido['id'] != null &&
                                              eventoCompartido['titulo'] !=
                                                  'Evento no disponible') // Solo mostrar si el evento es válido
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text("Ver Evento"),
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (ctx) => AlertDialog(
                                                          title: Text(
                                                            eventoCompartido['titulo'] ??
                                                                "Detalles del Evento",
                                                          ),
                                                          content: SingleChildScrollView(
                                                            child: ListBody(
                                                              children: <
                                                                Widget
                                                              >[
                                                                if (nombreOrganizadorEvento !=
                                                                    null)
                                                                  Text(
                                                                    "Organizador: $nombreOrganizadorEvento",
                                                                  ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                if (eventoCompartido['fecha_hora'] !=
                                                                    null)
                                                                  Text(
                                                                    "Fecha: ${DateFormat('dd MMM yy, hh:mm a', 'es_CO').format(DateTime.parse(eventoCompartido['fecha_hora']).toLocal())}",
                                                                  ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                if (eventoCompartido['ubicacion'] !=
                                                                    null)
                                                                  Text(
                                                                    "Lugar: ${eventoCompartido['ubicacion']}",
                                                                  ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                if (eventoCompartido['descripcion'] !=
                                                                    null)
                                                                  Text(
                                                                    "Descripción: ${eventoCompartido['descripcion']}",
                                                                  ),
                                                                // Podrías añadir más detalles del evento aquí si los obtuviste
                                                                // Por ejemplo, límite de asistentes, asistentes actuales, etc.
                                                                // Esto requeriría que la consulta en _obtenerPublicaciones para 'eventos' los incluya.
                                                              ],
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text(
                                                                "Cerrar",
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                },
                                              ),
                                            )
                                          else if (eventoCompartido['titulo'] ==
                                              'Evento no disponible')
                                            Text(
                                              eventoCompartido['descripcion'] ??
                                                  "Este evento ya no está disponible.",
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  // ---- FIN: Lógica para mostrar EVENTO COMPARTIDO ----
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
          const Divider(height: 1),
          // Vista previa del archivo seleccionado
          if (_selectedMediaFile != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            _isVideo
                                ? const Center(
                                  child: Icon(
                                    Icons.video_library,
                                    size: 40,
                                    color: Colors.black54,
                                  ),
                                )
                                : Image.file(
                                  _selectedMediaFile!,
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _limpiarMediaSeleccionada,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),
          // Input para texto y botones
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      onPressed: _subiendoMedia ? null : _seleccionarImagen,
                      tooltip: 'Seleccionar imagen',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_outlined),
                      onPressed: _subiendoMedia ? null : _seleccionarVideo,
                      tooltip: 'Seleccionar video',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textoController,
                        decoration: InputDecoration(
                          hintText: "¿Qué quieres compartir?",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (value) => _crearPublicacionTexto(),
                        enabled: !_subiendoMedia,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _subiendoMedia
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(Icons.send_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _crearPublicacionTexto,
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// Widget para reproducir videos
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            // Botón de reproducir/pausar
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
