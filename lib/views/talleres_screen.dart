import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';

class TallerConCreador {
  final Map<String, dynamic> tallerData;
  final String? nombreCreador;

  TallerConCreador({
    required this.tallerData,
    this.nombreCreador,
  });
}

class TalleresScreen extends StatefulWidget {
  const TalleresScreen({super.key});

  @override
  State<TalleresScreen> createState() => _TalleresScreenState();
}

class _TalleresScreenState extends State<TalleresScreen> {
  List<TallerConCreador> _talleresConCreador = [];
  bool _cargando = true;
  String? _error;
  final Map<String, String> _cacheNombresCreadores = {};

  @override
  void initState() {
    super.initState();
    _obtenerTalleres();
  }

  Future<String?> _obtenerNombreUsuario(String userId) async {
    if (_cacheNombresCreadores.containsKey(userId)) {
      return _cacheNombresCreadores[userId];
    }
    try {
      final respuesta = await Supabase.instance.client
          .from('usuarios')
          .select('nombre')
          .eq('id', userId)
          .single();

      if (mounted && respuesta['nombre'] != null) {
        final nombre = respuesta['nombre'] as String;
        _cacheNombresCreadores[userId] = nombre;
        return nombre;
      }
    } catch (e) {
      print('Error al obtener nombre de usuario $userId: $e');
    }
    return 'Desconocido';
  }

  Future<void> _obtenerTalleres() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await Supabase.instance.client
          .from('talleres')
          .select('*, usuarios(nombre)')
          .order('nombre', ascending: true);

      if (!mounted) return;

      final List<Map<String, dynamic>> talleresData = List<Map<String, dynamic>>.from(respuesta);
      List<TallerConCreador> tempTalleres = [];

      for (var tallerMap in talleresData) {
        String? nombreCreador;
        if (tallerMap['usuarios'] != null && tallerMap['usuarios']['nombre'] != null) {
          nombreCreador = tallerMap['usuarios']['nombre'] as String;
        } else if (tallerMap['creado_por'] != null) {
          nombreCreador = await _obtenerNombreUsuario(tallerMap['creado_por'] as String);
        }

        tempTalleres.add(TallerConCreador(
          tallerData: tallerMap,
          nombreCreador: nombreCreador ?? 'N/A',
        ));
      }

      if (mounted) {
        setState(() {
          _talleresConCreador = tempTalleres;
          _cargando = false;
        });
      }

    } catch (e) {
      if (!mounted) return;
      print('Error al obtener talleres: $e');
      setState(() {
        _error = "Error al cargar talleres: ${e.toString()}";
        _cargando = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogoTaller(
    BuildContext context, {
    Map<String, dynamic>? tallerExistente,
  }) async {
    final bool modoEdicion = tallerExistente != null;
    final String tituloDialogo = modoEdicion ? 'Editar Taller' : 'Crear Nuevo Taller';

    final TextEditingController nombreController =
        TextEditingController(text: modoEdicion ? tallerExistente['nombre'] ?? '' : '');
    final TextEditingController direccionTextoManualController =
        TextEditingController(text: modoEdicion ? tallerExistente['direccion'] ?? '' : '');
    final TextEditingController telefonoController =
        TextEditingController(text: modoEdicion ? tallerExistente['telefono'] ?? '' : '');
    final TextEditingController horarioController =
        TextEditingController(text: modoEdicion ? tallerExistente['horario'] ?? '' : '');

    final formKeyDialog = GlobalKey<FormState>();

    LatLng? _selectedLatLng;
    String? _selectedAddressString;

    if (modoEdicion) {
      if (tallerExistente['latitud'] != null && tallerExistente['longitud'] != null) {
        try {
          _selectedLatLng = LatLng(
            (tallerExistente['latitud'] as num).toDouble(),
            (tallerExistente['longitud'] as num).toDouble()
          );
        } catch (e) {
          print("Error parseando LatLng en modo edición (Taller): $e");
          _selectedLatLng = null;
        }
      }
      _selectedAddressString = tallerExistente['direccion'] as String?;
      if (_selectedAddressString != null) {
          direccionTextoManualController.text = _selectedAddressString;
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
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
                        controller: nombreController,
                        autofocus: !modoEdicion,
                        decoration: const InputDecoration(labelText: "Nombre del Taller*"),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      Text("Ubicación del Taller*", style: Theme.of(context).textTheme.titleSmall),
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
                                _selectedAddressString ?? "No se ha seleccionado ubicación",
                                style: TextStyle(color: _selectedAddressString == null ? Colors.grey : Colors.black),
                              ),
                            ),
                            Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary)
                          ],
                        ),
                      ),
                      if (_selectedLatLng != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 4.0),
                           child: Text(
                            "Lat: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(5)}",
                            style: Theme.of(context).textTheme.bodySmall,
                           ),
                         ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: Text(_selectedLatLng == null ? "Seleccionar en Mapa" : "Cambiar Ubicación"),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                        onPressed: () async {
                          final Map<String, dynamic>? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerScreen(
                                initialPosition: _selectedLatLng,
                                initialSearchQuery: _selectedAddressString ?? direccionTextoManualController.text,
                              ),
                            ),
                          );

                          if (result != null && result.containsKey('latlng') && result.containsKey('address')) {
                            setDialogState(() {
                              _selectedLatLng = result['latlng'] as LatLng;
                              _selectedAddressString = result['address'] as String;
                              direccionTextoManualController.text = _selectedAddressString!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                       Text("O ingresa la dirección manualmente:", style: Theme.of(context).textTheme.bodySmall),
                      TextFormField(
                        controller: direccionTextoManualController,
                        decoration: const InputDecoration(labelText: "Dirección (texto manual)"),
                        onChanged: (value) {
                          if (_selectedAddressString != value || _selectedLatLng != null) {
                            setDialogState(() {
                              _selectedLatLng = null;
                              _selectedAddressString = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(labelText: "Teléfono"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: horarioController,
                        decoration: const InputDecoration(labelText: "Horario (Ej: Lun-Vie 9am-6pm)"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                ElevatedButton(
                  child: Text(modoEdicion ? 'Guardar Cambios' : 'Crear Taller'),
                  onPressed: () {
                    if (formKeyDialog.currentState!.validate()) {
                      final direccionFinal = _selectedAddressString ?? direccionTextoManualController.text.trim();

                      if (direccionFinal.isEmpty && _selectedLatLng == null) {
                         ScaffoldMessenger.of(dialogContext).showSnackBar(
                           const SnackBar(content: Text("Por favor, selecciona o ingresa una dirección para el taller."))
                         );
                         return;
                      }

                      Map<String, dynamic> datosDevueltos = {
                        'nombre': nombreController.text.trim(),
                        'direccion': direccionFinal.isEmpty ? null : direccionFinal,
                        'telefono': telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
                        'horario': horarioController.text.trim().isEmpty ? null : horarioController.text.trim(),
                        'latitud': _selectedLatLng?.latitude,
                        'longitud': _selectedLatLng?.longitude,
                      };

                      if (modoEdicion) {
                        datosDevueltos['id'] = tallerExistente['id'];
                      }
                      Navigator.pop(dialogContext, datosDevueltos);
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _accionCrearOEditarTaller({Map<String, dynamic>? tallerExistente}) async {
    final Map<String, dynamic>? datosTaller = await _mostrarDialogoTaller(context, tallerExistente: tallerExistente);

    if (datosTaller != null) {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Debes iniciar sesión.")),
          );
        }
        return;
      }

      if (mounted) setState(() => _cargando = true);

      final datosParaGuardar = {
        'nombre': datosTaller['nombre'],
        'direccion': datosTaller['direccion'],
        'telefono': datosTaller['telefono'],
        'horario': datosTaller['horario'],
        'latitud': datosTaller['latitud'],
        'longitud': datosTaller['longitud'],
        'creado_por': tallerExistente == null ? currentUserUid : tallerExistente['creado_por'],
      };

      try {
        if (tallerExistente == null) {
          await Supabase.instance.client.from('talleres').insert(datosParaGuardar);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Taller creado con éxito.")));
        } else {
          await Supabase.instance.client.from('talleres').update(datosParaGuardar).eq('id', tallerExistente['id'] as String);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Taller actualizado con éxito.")));
        }
        _obtenerTalleres();
      } catch (e) {
        print("Error al guardar taller: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al guardar el taller: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _eliminarTaller(String tallerId, String nombreTaller) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: Text("¿Seguro que quieres eliminar el taller '$nombreTaller'?"),
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
        await Supabase.instance.client.from('talleres').delete().eq('id', tallerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Taller '$nombreTaller' eliminado.")));
          _obtenerTalleres();
        }
      } catch (e) {
        print("Error al eliminar taller: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: ${e.toString()}")));
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _abrirEnMapa(Map<String, dynamic> taller) async {
    final lat = taller['latitud'] as double?;
    final lon = taller['longitud'] as double?;
    final address = taller['direccion'] as String?;

    Uri? mapUri;

    if (lat != null && lon != null) {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        mapUri = Uri.parse('maps://?q=$lat,$lon');
      } else {
        mapUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(taller['nombre'] ?? 'Taller')})');
      }
    } else if (address != null && address.isNotEmpty) {
       if (Theme.of(context).platform == TargetPlatform.iOS) {
        mapUri = Uri.parse('maps://?q=${Uri.encodeComponent(address)}');
      } else {
        mapUri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
      }
    }

    if (mapUri != null) {
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
        } else {
            print('Error al abrir mapa (context no mounted): $e');
        }
      }
    } else {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay dirección o coordenadas disponibles para mostrar en el mapa')),
          );
      } else {
          print('No hay dirección o coordenadas para el mapa (context no mounted)');
      }
    }
  }

  Future<void> _compartirTallerEnComunidad(Map<String, dynamic> tallerData) async {
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
          title: Text("Compartir Taller: ${tallerData['nombre'] ?? 'Taller'}"),
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
      String contenidoPublicacion = mensajeUsuario?.isNotEmpty == true ? mensajeUsuario! : "";
      contenidoPublicacion += "\n\n¡Revisen este taller!: ${tallerData['nombre'] ?? 'Sin nombre'}";
      if (tallerData['direccion'] != null && (tallerData['direccion'] as String).isNotEmpty) {
        contenidoPublicacion += "\nDirección: ${tallerData['direccion']}";
      }
      if (tallerData['telefono'] != null && (tallerData['telefono'] as String).isNotEmpty) {
        contenidoPublicacion += "\nTeléfono: ${tallerData['telefono']}";
      }
       if (tallerData['horario'] != null && (tallerData['horario'] as String).isNotEmpty) {
        contenidoPublicacion += "\nHorario: ${tallerData['horario']}";
      }

      await Supabase.instance.client.from('comentarios_comunidad').insert({
        'usuario_id': currentUserUid,
        'contenido': contenidoPublicacion,
        'tipo': 'taller_compartido',
        'referencia_taller_id': tallerData['id'],
        'fecha': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Taller compartido en la comunidad!")));
      }
    } catch (e) {
      print("Error al compartir taller: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error al compartir el taller: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Talleres Disponibles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerTalleres,
            tooltip: 'Recargar Talleres',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _obtenerTalleres, child: const Text("Reintentar"))
                      ],
                    )
                  ),
                )
              : _talleresConCreador.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.build_circle_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text("No hay talleres registrados.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text("¡Sé el primero en agregar uno!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _obtenerTalleres,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                        itemCount: _talleresConCreador.length,
                        itemBuilder: (context, index) {
                          final tallerConCreador = _talleresConCreador[index];
                          final taller = tallerConCreador.tallerData;
                          final nombreTaller = taller['nombre'] as String? ?? 'Nombre no disponible';
                          final direccion = taller['direccion'] as String? ?? '';
                          final telefono = taller['telefono'] as String? ?? '';
                          final horario = taller['horario'] as String? ?? '';
                          final nombreCreador = tallerConCreador.nombreCreador;
                          final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
                          final esCreador = (currentUserUid != null && taller['creado_por'] == currentUserUid);
                          final bool estaLogueado = currentUserUid != null;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.handyman_outlined, size: 36, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(nombreTaller, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 17)),
                                            if (nombreCreador != null && nombreCreador != 'N/A')
                                              Text("Por: $nombreCreador", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700])),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (estaLogueado)
                                            IconButton(
                                              icon: Icon(Icons.share_outlined, color: Colors.blueAccent, size: 20),
                                              tooltip: 'Compartir este taller',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _compartirTallerEnComunidad(taller),
                                            ),
                                          if (esCreador)
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                              tooltip: "Más opciones",
                                              onSelected: (value) {
                                                if (value == 'editar') {
                                                  _accionCrearOEditarTaller(tallerExistente: taller);
                                                } else if (value == 'eliminar') {
                                                  _eliminarTaller(taller['id'] as String, nombreTaller);
                                                }
                                              },
                                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                const PopupMenuItem<String>(
                                                  value: 'editar',
                                                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar')),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'eliminar',
                                                  child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                                ),
                                              ],
                                            ),
                                        ],
                                      )
                                    ],
                                  ),
                                  const Divider(height: 18, thickness: 0.5),
                                  if (direccion.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(direccion, style: Theme.of(context).textTheme.bodyMedium)),
                                        IconButton(
                                          icon: Icon(Icons.map_outlined, color: Colors.blueAccent[700], size: 22),
                                          tooltip: 'Ver en mapa',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _abrirEnMapa(taller),
                                        ),
                                      ],
                                    ),
                                  if (telefono.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone_outlined, color: Colors.grey[700], size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(telefono, style: Theme.of(context).textTheme.bodyMedium)),
                                        ],
                                      ),
                                    ),
                                  if (horario.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_outlined, color: Colors.grey[700], size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(horario, style: Theme.of(context).textTheme.bodyMedium)),
                                        ],
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
        onPressed: () => _accionCrearOEditarTaller(),
        label: const Text("Agregar Taller"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}