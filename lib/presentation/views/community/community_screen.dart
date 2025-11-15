import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

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
    if (contenido.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Escribe algo para publicar.")),
        );
      }
      return;
    }

    try {
      if (mounted) setState(() => _cargando = true);

      await Supabase.instance.client.from('comentarios_comunidad').insert({
        'usuario_id': currentUser.id,
        'contenido': contenido,
        'tipo': 'texto',
        'fecha': DateTime.now().toIso8601String(),
      });

      _textoController.clear();
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
      if (mounted) setState(() => _cargando = false);
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
                                                  nombreAutor) // No mostrar si el que comparte es el mismo organizador
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _crearPublicacionTexto,
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
