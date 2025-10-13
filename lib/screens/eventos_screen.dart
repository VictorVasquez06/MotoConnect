import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_picker_screen.dart';

class EventoConNombre {
  final Map<String, dynamic> eventoData;
  final String? nombreOrganizador;
  bool usuarioAsiste;
  int asistentesActuales;

  EventoConNombre({
    required this.eventoData,
    this.nombreOrganizador,
    this.usuarioAsiste = false,
    this.asistentesActuales = 0,
  });
}

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  List<EventoConNombre> eventosConNombres = [];
  bool _cargando = true;
  final Map<String, String> _cacheNombres = {};

  @override
  void initState() {
    super.initState();
    _obtenerEventosConNombres();
  }

  Future<String?> _obtenerNombreUsuario(String userId) async {
    if (_cacheNombres.containsKey(userId)) {
      return _cacheNombres[userId];
    }
    try {
      final respuesta = await Supabase.instance.client
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
      print("Error obteniendo nombre para usuario $userId (Eventos): $e");
      return "Organizador Desconocido";
    }
  }

  Future<void> _obtenerEventosConNombres() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final respuestaEventos = await Supabase.instance.client
          .from('eventos')
          .select()
          .order('fecha_hora', ascending: true);

      List<EventoConNombre> tempLista = [];
      for (var eventoData in respuestaEventos) {
        String? nombreOrganizador;
        bool usuarioAsisteActual = false;
        int asistentesActuales = 0;

        final organizadorId = eventoData['creado_por'] as String?;
        final eventoId = eventoData['id'] as String;

        if (organizadorId != null) {
          nombreOrganizador = await _obtenerNombreUsuario(organizadorId);
        }

        try {
          final responseWithCount = await Supabase.instance.client
              .from('asistencias_eventos')
              .select()
              .eq('evento_id', eventoId)
              .count(CountOption.exact);
          
          asistentesActuales = responseWithCount.count;

        } catch (e) {
          print("Error específico al intentar contar asistentes para evento $eventoId: $e");
          asistentesActuales = 0; 
        }

        if (currentUserUid != null) {
          try {
            final asistenciaRespuesta = await Supabase.instance.client
                .from('asistencias_eventos')
                .select('id')
                .eq('evento_id', eventoId)
                .eq('usuario_id', currentUserUid)
                .maybeSingle(); 
            usuarioAsisteActual = asistenciaRespuesta != null;
          } catch (e) {
            print("Error verificando asistencia para evento $eventoId: $e");
          }
        }

        tempLista.add(EventoConNombre(
          eventoData: eventoData,
          nombreOrganizador: nombreOrganizador ?? "Organizador Desconocido",
          usuarioAsiste: usuarioAsisteActual,
          asistentesActuales: asistentesActuales,
        ));
      }

      if (mounted) {
        setState(() {
          eventosConNombres = tempLista;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error general al cargar eventos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar eventos: ${e.toString()}"))
        );
        setState(() => _cargando = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogoEvento(
    BuildContext context, {
    Map<String, dynamic>? eventoExistente,
  }) async {
    final bool modoEdicion = eventoExistente != null;
    final String tituloDialogo = modoEdicion ? 'Editar Evento' : 'Crear Nuevo Evento';
    final String textoBotonGuardar = modoEdicion ? 'Guardar Cambios' : 'Crear Evento';

    final TextEditingController tituloController =
        TextEditingController(text: modoEdicion ? eventoExistente['titulo'] ?? '' : '');
    final TextEditingController descripcionController =
        TextEditingController(text: modoEdicion ? eventoExistente['descripcion'] ?? '' : '');
    final TextEditingController limiteController = TextEditingController(
        text: modoEdicion ? (eventoExistente['limite_asistentes'] ?? '').toString() : '');
    
    final TextEditingController ubicacionTextoManualController = 
        TextEditingController(text: modoEdicion ? eventoExistente['ubicacion'] ?? '' : '');
    
    DateTime? fechaHoraSeleccionada = modoEdicion && eventoExistente['fecha_hora'] != null
        ? DateTime.parse(eventoExistente['fecha_hora']).toLocal()
        : null;
    
    final formKeyDialog = GlobalKey<FormState>();

    LatLng? _selectedEventLatLng;
    String? _selectedEventAddressString;

    if (modoEdicion) {
      if (eventoExistente['latitud'] != null && eventoExistente['longitud'] != null) {
         try {
            _selectedEventLatLng = LatLng(
                (eventoExistente['latitud'] as num).toDouble(),
                (eventoExistente['longitud'] as num).toDouble()
            );
          } catch (e) {
            print("Error al parsear LatLng del evento existente: $e");
            _selectedEventLatLng = null;
          }
      }
      _selectedEventAddressString = eventoExistente['ubicacion'] as String?;
      if (_selectedEventAddressString != null) {
          ubicacionTextoManualController.text = _selectedEventAddressString;
      }
    }
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (stfContext, setDialogState) { 
          return AlertDialog(
            title: Text(tituloDialogo),
            content: SingleChildScrollView(
              child: Form(
                key: formKeyDialog,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: tituloController,
                      autofocus: !modoEdicion,
                      decoration: const InputDecoration(labelText: "Título del Evento*"),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'El título es obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: "Descripción (Opcional)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text("Ubicación del Evento*", style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedEventAddressString ?? "No se ha seleccionado ubicación en mapa",
                              style: TextStyle(color: _selectedEventAddressString == null ? Colors.grey : Colors.black),
                            ),
                          ),
                          Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary)
                        ],
                      ),
                    ),
                    if (_selectedEventLatLng != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: Text(
                          "Lat: ${_selectedEventLatLng!.latitude.toStringAsFixed(5)}, Lng: ${_selectedEventLatLng!.longitude.toStringAsFixed(5)}",
                          style: Theme.of(context).textTheme.bodySmall,
                         ),
                       ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: Text(_selectedEventLatLng == null ? "Seleccionar en Mapa" : "Cambiar Ubicación en Mapa"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                      onPressed: () async {
                        final Map<String, dynamic>? result = await Navigator.push(
                          dialogContext, 
                          MaterialPageRoute(
                            builder: (context) => MapPickerScreen(
                              initialPosition: _selectedEventLatLng,
                              initialSearchQuery: _selectedEventAddressString ?? ubicacionTextoManualController.text,
                            ),
                          ),
                        );

                        if (result != null && result.containsKey('latlng') && result.containsKey('address')) {
                          setDialogState(() { 
                            _selectedEventLatLng = result['latlng'] as LatLng;
                            _selectedEventAddressString = result['address'] as String;
                            ubicacionTextoManualController.text = _selectedEventAddressString!; 
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Text("O ingresa la dirección manualmente:", style: Theme.of(context).textTheme.bodySmall),
                    TextFormField(
                      controller: ubicacionTextoManualController,
                      decoration: const InputDecoration(labelText: "Dirección (texto manual)"),
                      onChanged: (value) {
                        if (_selectedEventAddressString != value || _selectedEventLatLng != null) {
                          setDialogState(() {
                            _selectedEventLatLng = null;
                            _selectedEventAddressString = null; 
                          });
                        }
                      },
                       validator: (value) {
                          if ((_selectedEventAddressString == null || _selectedEventAddressString!.isEmpty) && 
                              (value == null || value.trim().isEmpty)) {
                            return 'La ubicación es obligatoria (mapa o manual)';
                          }
                          return null;
                        },
                    ),
                    const SizedBox(height: 16),
                    Text("Fecha y Hora del Evento*", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    Row(
                      children: [
                        Expanded(
                          child: Text(fechaHoraSeleccionada == null
                              ? 'No seleccionada'
                              : DateFormat('dd MMM yy, hh:mm a', 'es_CO').format(fechaHoraSeleccionada!)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime initialPickerDate = fechaHoraSeleccionada ?? DateTime.now();
                            final DateTime? fecha = await showDatePicker(
                              context: dialogContext,
                              initialDate: initialPickerDate.isBefore(DateTime.now()) && !modoEdicion ? DateTime.now() : initialPickerDate,
                              firstDate: modoEdicion ? DateTime(2020) : DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (fecha != null) {
                              final TimeOfDay? hora = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(fechaHoraSeleccionada ?? initialPickerDate),
                              );
                              if (hora != null) {
                                setDialogState(() { 
                                  fechaHoraSeleccionada = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
                                });
                              }
                            }
                          },
                        )
                      ],
                    ),
                    if (fechaHoraSeleccionada == null)
                       Padding(
                         padding: const EdgeInsets.only(top:4.0),
                         child: Text("La fecha y hora son obligatorias", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                       ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: limiteController,
                      decoration: const InputDecoration(labelText: "Límite de Asistentes (Opcional)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final n = int.tryParse(value.trim());
                          if (n == null) return 'Número inválido';
                          if (n < 0) return 'No puede ser negativo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                child: Text(textoBotonGuardar),
                onPressed: () {
                  if (formKeyDialog.currentState!.validate()) {
                    if (fechaHoraSeleccionada == null) { 
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Por favor, selecciona la fecha y hora del evento."))
                      );
                      return;
                    }

                    final String direccionFinal = _selectedEventAddressString?.isNotEmpty == true 
                                                  ? _selectedEventAddressString! 
                                                  : ubicacionTextoManualController.text.trim();

                    if (direccionFinal.isEmpty) {
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text("Por favor, selecciona o ingresa una ubicación para el evento."))
                        );
                        return;
                    }

                    Map<String, dynamic> datosDevueltos = {
                      'titulo': tituloController.text.trim(),
                      'descripcion': descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                      'limite_asistentes': limiteController.text.trim().isEmpty ? null : int.tryParse(limiteController.text.trim()),
                      'fecha_hora': fechaHoraSeleccionada!.toIso8601String(), 
                      'ubicacion': direccionFinal,
                      'latitud': _selectedEventLatLng?.latitude,
                      'longitud': _selectedEventLatLng?.longitude,
                    };
                    if (modoEdicion) {
                      datosDevueltos['id'] = eventoExistente['id'];
                    }
                    Navigator.pop(dialogContext, datosDevueltos);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _crearNuevoEvento() async {
    final Map<String, dynamic>? datosEvento = await _mostrarDialogoEvento(context);
    if (datosEvento != null) {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes iniciar sesión para crear un evento.")));
        return;
      }

      if (mounted) setState(() => _cargando = true);

      try {
        final List<dynamic> eventoInsertado = await Supabase.instance.client.from('eventos').insert({
          'titulo': datosEvento['titulo'],
          'descripcion': datosEvento['descripcion'],
          'fecha_hora': datosEvento['fecha_hora'],
          'creado_por': currentUserUid,
          'limite_asistentes': datosEvento['limite_asistentes'],
          'ubicacion': datosEvento['ubicacion'],
          'latitud': datosEvento['latitud'],
          'longitud': datosEvento['longitud'],
        }).select('id'); 

        if (eventoInsertado.isNotEmpty) {
          final String eventoIdCreado = eventoInsertado[0]['id'];
          await Supabase.instance.client.from('asistencias_eventos').insert({
            'evento_id': eventoIdCreado,
            'usuario_id': currentUserUid,
          });
        } else {
          throw Exception("No se pudo obtener el ID del evento creado.");
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento creado con éxito. ¡Te has unido automáticamente!")));
          _obtenerEventosConNombres();
        }
      } catch (e) {
        print("Error al crear evento: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear el evento: ${e.toString()}")));
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _actualizarEvento(Map<String, dynamic> datosEventoEditado) async {
    final eventoId = datosEventoEditado['id'];
    if (eventoId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: ID de evento no encontrado para actualizar.")));
      return;
    }
    
    if (mounted) setState(() => _cargando = true);
    final Map<String, dynamic> datosParaActualizar = {
      'titulo': datosEventoEditado['titulo'],
      'descripcion': datosEventoEditado['descripcion'],
      'fecha_hora': datosEventoEditado['fecha_hora'],
      'limite_asistentes': datosEventoEditado['limite_asistentes'],
      'ubicacion': datosEventoEditado['ubicacion'],
      'latitud': datosEventoEditado['latitud'],     
      'longitud': datosEventoEditado['longitud'],
    };

    try {
      await Supabase.instance.client
          .from('eventos')
          .update(datosParaActualizar)
          .eq('id', eventoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento actualizado con éxito.")));
        _obtenerEventosConNombres(); 
      }
    } catch (e) {
      print("Error al actualizar evento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar el evento: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
  
  Future<void> _eliminarEvento(String eventoId, String nombreEvento) async {
    if (eventoId.isEmpty) return;
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: Text("¿Seguro que quieres eliminar el evento '$nombreEvento'? Esta acción no se puede deshacer."),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancelar")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Eliminar")
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (mounted) setState(() => _cargando = true);
      try {
        await Supabase.instance.client.from('asistencias_eventos').delete().eq('evento_id', eventoId);
        await Supabase.instance.client.from('comentarios_comunidad').delete().eq('referencia_evento_id', eventoId);
        await Supabase.instance.client.from('eventos').delete().eq('id', eventoId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evento '$nombreEvento' eliminado.")));
          _obtenerEventosConNombres();
        }
      } catch (e) {
        print("Error al eliminar evento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar el evento: ${e.toString()}")));
        }
      } finally {
        if (mounted && _cargando) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _compartirEventoEnComunidad(Map<String, dynamic> eventoData) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Debes iniciar sesión para compartir.")));
      }
      return;
    }

    String? mensajeUsuario;
    final TextEditingController mensajeController = TextEditingController();

    final bool? confirmarCompartir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Compartir Evento: ${eventoData['titulo'] ?? 'Evento'}"),
          content: TextField(
            controller: mensajeController,
            decoration:
                const InputDecoration(hintText: "Añade un mensaje (opcional)..."),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                mensajeUsuario = mensajeController.text.trim();
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Compartir"),
            ),
          ],
        );
      },
    );

    if (confirmarCompartir != true) {
      return;
    }

    if (mounted) setState(() => _cargando = true);

    try {
      await Supabase.instance.client.from('comentarios_comunidad').insert({
        'usuario_id': currentUserUid,
        'contenido': mensajeUsuario?.isEmpty ?? true
            ? "¡Revisen este evento: ${eventoData['titulo'] ?? 'Interesante'}!"
            : mensajeUsuario,
        'tipo': 'evento_compartido', 
        'referencia_evento_id': eventoData['id'], 
        'fecha': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Evento compartido en la comunidad!")));
      }
    } catch (e) {
      print("Error al compartir evento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error al compartir el evento: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _unirseAEvento(String eventoId, int indexEnLista) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes iniciar sesión.")));
      return;
    }
    final eventoItem = eventosConNombres[indexEnLista];
    final limiteAsistentes = eventoItem.eventoData['limite_asistentes'] as int?;
    if (limiteAsistentes != null && eventoItem.asistentesActuales >= limiteAsistentes && !eventoItem.usuarioAsiste) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento con cupos llenos.")));
      return;
    }
    try {
      await Supabase.instance.client.from('asistencias_eventos').insert({
        'evento_id': eventoId,
        'usuario_id': currentUserUid,
      });
      if (mounted) {
        setState(() {
          eventosConNombres[indexEnLista].usuarioAsiste = true;
          eventosConNombres[indexEnLista].asistentesActuales++;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Te has unido al evento!")));
      }
    } catch (e) {
      print("Error al unirse: $e");
      if (e is PostgrestException && e.code == '23505') { 
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ya estás unido a este evento.")));
           if (!eventosConNombres[indexEnLista].usuarioAsiste) { 
             setState(() => eventosConNombres[indexEnLista].usuarioAsiste = true);
           }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al unirse: ${e.toString()}")));
      }
    }
  }

  Future<void> _cancelarAsistencia(String eventoId, int indexEnLista) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return; 
    try {
      await Supabase.instance.client
          .from('asistencias_eventos')
          .delete()
          .eq('evento_id', eventoId)
          .eq('usuario_id', currentUserUid);
      if (mounted) {
        setState(() {
          eventosConNombres[indexEnLista].usuarioAsiste = false;
          eventosConNombres[indexEnLista].asistentesActuales--;
          if (eventosConNombres[indexEnLista].asistentesActuales < 0) { 
            eventosConNombres[indexEnLista].asistentesActuales = 0;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Has cancelado tu asistencia.")));
      }
    } catch (e) {
      print("Error al cancelar asistencia: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cancelar: ${e.toString()}")));
    }
  }

  Future<void> _abrirUbicacionEnMapaExterno({
    required double lat,
    required double lon,
    String? label,
    String? address,
  }) async {
    Uri? mapUri;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      mapUri = Uri.parse('maps://?q=$lat,$lon(${Uri.encodeComponent(label ?? address ?? 'Ubicación')})');
    } else { 
      mapUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(label ?? address ?? 'Ubicación')})');
    }

    try {
      if (await canLaunchUrl(mapUri)) { 
        await launchUrl(mapUri);
      } else {
        throw 'No se puede lanzar $mapUri';
      }
    } catch (e) {
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el mapa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eventos Próximos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerEventosConNombres,
            tooltip: 'Recargar Eventos',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : eventosConNombres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Aún no hay eventos programados.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text("¡Anímate a crear el primero!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _obtenerEventosConNombres,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), 
                    itemCount: eventosConNombres.length,
                    itemBuilder: (context, index) {
                      final item = eventosConNombres[index];
                      final evento = item.eventoData;
                      final nombreOrganizador = item.nombreOrganizador;
                      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
                      final bool esCreador = (currentUserUid != null && evento['creado_por'] == currentUserUid);
                      final bool puedeInteractuarAsistencia = !esCreador && currentUserUid != null;
                      final bool estaLogueado = currentUserUid != null;
                      final limiteAsistentes = evento['limite_asistentes'] as int?;
                      final bool hayCupo = limiteAsistentes == null || item.asistentesActuales < limiteAsistentes;
                      
                      String fechaFormateada = 'Fecha no especificada';
                      if (evento['fecha_hora'] != null) {
                        try {
                           final fecha = DateTime.parse(evento['fecha_hora']).toLocal();
                           fechaFormateada = DateFormat('dd MMM yy, hh:mm a', 'es_CO').format(fecha);
                        } catch(e){
                          print("Error formateando fecha para evento ${evento['id']}: $e");
                          fechaFormateada = evento['fecha_hora'];
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.event_seat_rounded, size: 38, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          evento['titulo'] ?? 'Evento sin título',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        if (nombreOrganizador != null && nombreOrganizador != "Organizador Desconocido")
                                          Text("Por: $nombreOrganizador", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                  if (estaLogueado)
                                    IconButton(
                                      icon: Icon(Icons.share_outlined, color: Colors.blueAccent, size: 20),
                                      tooltip: 'Compartir este evento',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _compartirEventoEnComunidad(evento),
                                    ),
                                  if (esCreador)
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 22),
                                      tooltip: "Más opciones",
                                      iconSize: 22,
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                                      onSelected: (value) async {
                                        if (value == 'editar') {
                                          final Map<String, dynamic>? datosEditados = await _mostrarDialogoEvento(context, eventoExistente: evento);
                                          if (datosEditados != null) {
                                            await _actualizarEvento(datosEditados);
                                          }
                                        } else if (value == 'eliminar') {
                                          _eliminarEvento(evento['id'] as String, evento['titulo'] ?? 'Evento');
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'editar',
                                          child: ListTile(leading: Icon(Icons.edit_calendar_outlined), title: Text('Editar Evento')),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'eliminar',
                                          child: ListTile(leading: Icon(Icons.delete_forever_outlined, color: Colors.red), title: Text('Eliminar Evento', style: TextStyle(color: Colors.red))),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 0.5),
                              Text("🗓️ Fecha: $fechaFormateada", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              if (evento['ubicacion'] != null && (evento['ubicacion'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(evento['ubicacion'], style: Theme.of(context).textTheme.bodyMedium)),
                                      if (evento['latitud'] != null && evento['longitud'] != null)
                                        IconButton(
                                          icon: Icon(Icons.map_outlined, color: Colors.blueAccent, size: 20),
                                          tooltip: "Ver en mapa externo",
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            _abrirUbicacionEnMapaExterno(
                                              lat: (evento['latitud'] as num).toDouble(),
                                              lon: (evento['longitud'] as num).toDouble(),
                                              label: evento['titulo'] ?? 'Ubicación del Evento',
                                              address: evento['ubicacion']
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              if (evento['descripcion'] != null && (evento['descripcion'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                  child: Text("ℹ️ Detalles: ${evento['descripcion']}", style: Theme.of(context).textTheme.bodySmall),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text("👥 Asistentes: ${item.asistentesActuales}${limiteAsistentes != null ? '/'+limiteAsistentes.toString() : ' (Abierto)'}", style: Theme.of(context).textTheme.bodyMedium),
                              ),
                              if (puedeInteractuarAsistencia)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: item.usuarioAsiste
                                        ? ElevatedButton.icon(
                                            icon: const Icon(Icons.check_circle_outline, size: 18),
                                            label: const Text("Asistiendo"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueGrey,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            onPressed: () => _cancelarAsistencia(evento['id'] as String, index),
                                          )
                                        : (hayCupo
                                            ? ElevatedButton.icon(
                                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                                label: const Text("Asistiré"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[600],
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                                onPressed: () => _unirseAEvento(evento['id'] as String, index),
                                              )
                                            : Chip(
                                                avatar: const Icon(Icons.block, color: Colors.white, size: 16),
                                                label: const Text("Cupos llenos"),
                                                backgroundColor: Colors.red[300],
                                                labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              )
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearNuevoEvento,
        label: const Text("Crear Evento"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}