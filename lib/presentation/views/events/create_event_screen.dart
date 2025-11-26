import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/grupo_repository.dart';
import '../routes/rutas_screen.dart';

/// Pantalla para crear o editar un evento
class CreateEventScreen extends StatefulWidget {
  /// Evento a editar (null para crear nuevo)
  final Event? event;

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _labelPuntoEncuentroController = TextEditingController();
  final _labelDestinoController = TextEditingController();

  // Coordenadas y direcciones de las ubicaciones
  double? _puntoEncuentroLat;
  double? _puntoEncuentroLng;
  String? _puntoEncuentroDireccion;

  double? _destinoLat;
  double? _destinoLng;
  String? _destinoDireccion;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;
  String? _imageUrl;
  GrupoRutaModel? _selectedGrupo;
  List<GrupoRutaModel> _grupos = [];
  bool _isPublic = true; // Por defecto los eventos son públicos

  bool _isLoading = false;
  bool _isLoadingGrupos = true;

  final _eventRepository = EventRepository();
  final _grupoRepository = GrupoRepository();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGrupos();
    if (widget.event != null) {
      _initializeFromEvent();
    }
  }

  void _initializeFromEvent() {
    final event = widget.event!;
    _tituloController.text = event.title;
    _descripcionController.text = event.description;

    // Inicializar punto de encuentro
    _puntoEncuentroDireccion = event.puntoEncuentro;
    _puntoEncuentroLat = event.puntoEncuentroLat;
    _puntoEncuentroLng = event.puntoEncuentroLng;

    // Inicializar destino si existe
    if (event.destino != null && event.destino!.isNotEmpty) {
      _destinoDireccion = event.destino!;
      _destinoLat = event.destinoLat;
      _destinoLng = event.destinoLng;
    }

    _selectedDate = event.date;
    _selectedTime = TimeOfDay.fromDateTime(event.date);
    _imageUrl = event.fotoUrl;
    _isPublic = event.isPublic;
  }

  Future<void> _loadGrupos() async {
    try {
      final grupos = await _grupoRepository.obtenerMisGrupos();
      setState(() {
        _grupos = grupos;
        _isLoadingGrupos = false;

        // Si estamos editando y el evento tiene un grupo, seleccionarlo
        if (widget.event?.grupoId != null) {
          _selectedGrupo = grupos.firstWhere(
            (g) => g.id == widget.event!.grupoId,
            orElse: () => grupos.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingGrupos = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Error: Usuario no autenticado');
        return null;
      }

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('Subiendo imagen con nombre: $fileName');

      // Subir el archivo
      await Supabase.instance.client.storage
          .from(ApiConstants.eventsBucket)
          .upload(
            fileName,
            _selectedImage!,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener la URL pública
      final publicUrl = Supabase.instance.client.storage
          .from(ApiConstants.eventsBucket)
          .getPublicUrl(fileName);

      debugPrint('URL pública generada: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona fecha y hora')),
      );
      return;
    }

    if (_puntoEncuentroDireccion == null || _puntoEncuentroDireccion!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona el punto de encuentro')),
      );
      return;
    }

    if (!_isPublic && _selectedGrupo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los eventos privados requieren un grupo asociado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Subir imagen si hay una nueva
      String? fotoUrl = _imageUrl;
      if (_selectedImage != null) {
        debugPrint('Subiendo imagen...');
        fotoUrl = await _uploadImage();
        debugPrint('Resultado de subida - fotoUrl: $fotoUrl');
      } else {
        debugPrint('No hay imagen seleccionada, usando _imageUrl: $_imageUrl');
      }

      // Combinar fecha y hora
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Determinar qué texto usar para punto de encuentro (label personalizado o dirección)
      final String puntoEncuentroTexto = _labelPuntoEncuentroController.text.trim().isNotEmpty
          ? '${_labelPuntoEncuentroController.text.trim()} ($_puntoEncuentroDireccion)'
          : _puntoEncuentroDireccion!;

      // Determinar qué texto usar para destino
      String? destinoTexto;
      if (_destinoDireccion != null && _destinoDireccion!.isNotEmpty) {
        destinoTexto = _labelDestinoController.text.trim().isNotEmpty
            ? '${_labelDestinoController.text.trim()} ($_destinoDireccion)'
            : _destinoDireccion;
      }

      if (widget.event == null) {
        // Crear nuevo evento
        debugPrint('Creando evento con fotoUrl: $fotoUrl');
        await _eventRepository.createEvent(
          title: _tituloController.text.trim(),
          description: _descripcionController.text.trim(),
          date: dateTime,
          puntoEncuentro: puntoEncuentroTexto,
          createdBy: userId,
          destino: destinoTexto,
          puntoEncuentroLat: _puntoEncuentroLat,
          puntoEncuentroLng: _puntoEncuentroLng,
          destinoLat: _destinoLat,
          destinoLng: _destinoLng,
          fotoUrl: fotoUrl,
          grupoId: _selectedGrupo?.id,
          isPublic: _isPublic,
        );
        debugPrint('Evento creado exitosamente');
      } else {
        // Actualizar evento existente
        await _eventRepository.updateEvent(
          eventId: widget.event!.id,
          title: _tituloController.text.trim(),
          description: _descripcionController.text.trim(),
          date: dateTime,
          puntoEncuentro: puntoEncuentroTexto,
          destino: destinoTexto,
          puntoEncuentroLat: _puntoEncuentroLat,
          puntoEncuentroLng: _puntoEncuentroLng,
          destinoLat: _destinoLat,
          destinoLng: _destinoLng,
          fotoUrl: fotoUrl,
          grupoId: _selectedGrupo?.id,
          isPublic: _isPublic,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null
                ? 'Evento creado exitosamente'
                : 'Evento actualizado exitosamente'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seleccionarUbicacion(bool esPuntoEncuentro) async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => RutasScreen(modoSeleccion: true),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        if (esPuntoEncuentro) {
          _puntoEncuentroLat = resultado['latitud'] as double?;
          _puntoEncuentroLng = resultado['longitud'] as double?;
          _puntoEncuentroDireccion = resultado['direccion'] as String?;
        } else {
          _destinoLat = resultado['latitud'] as double?;
          _destinoLng = resultado['longitud'] as double?;
          _destinoDireccion = resultado['direccion'] as String?;
        }
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _labelPuntoEncuentroController.dispose();
    _labelDestinoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el padding del sistema para zonas seguras
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomPadding + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen del evento
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    // Título
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título del evento *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Punto de Encuentro
                    _buildUbicacionSelector(
                      titulo: 'Punto de Encuentro *',
                      icono: Icons.flag,
                      direccion: _puntoEncuentroDireccion,
                      latitud: _puntoEncuentroLat,
                      longitud: _puntoEncuentroLng,
                      labelController: _labelPuntoEncuentroController,
                      onSeleccionar: () => _seleccionarUbicacion(true),
                      onVerRuta: _puntoEncuentroLat != null && _puntoEncuentroLng != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RutasScreen(
                                    destinoInicial: LatLng(_puntoEncuentroLat!, _puntoEncuentroLng!),
                                    nombreDestino: _puntoEncuentroDireccion,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Destino
                    _buildUbicacionSelector(
                      titulo: 'Destino (Opcional)',
                      icono: Icons.location_on,
                      direccion: _destinoDireccion,
                      latitud: _destinoLat,
                      longitud: _destinoLng,
                      labelController: _labelDestinoController,
                      onSeleccionar: () => _seleccionarUbicacion(false),
                      onVerRuta: _destinoLat != null && _destinoLng != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RutasScreen(
                                    destinoInicial: LatLng(_destinoLat!, _destinoLng!),
                                    nombreDestino: _destinoDireccion,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Fecha
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Seleccionar fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hora
                    InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Seleccionar hora'
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de grupo
                    if (_isLoadingGrupos)
                      const Center(child: CircularProgressIndicator())
                    else if (_grupos.isNotEmpty)
                      DropdownButtonFormField<GrupoRutaModel>(
                        decoration: const InputDecoration(
                          labelText: 'Grupo (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                          hintText: 'Sin grupo',
                        ),
                        items: [
                          const DropdownMenuItem<GrupoRutaModel>(
                            value: null,
                            child: Text('Sin grupo'),
                          ),
                          ..._grupos.map((grupo) {
                            return DropdownMenuItem<GrupoRutaModel>(
                              value: grupo,
                              child: Text(grupo.nombre),
                            );
                          }),
                        ],
                        onChanged: (GrupoRutaModel? value) {
                          setState(() {
                            _selectedGrupo = value;
                          });
                        },
                        value: _selectedGrupo,
                      ),
                    const SizedBox(height: 24),

                    // Privacidad del evento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacidad del Evento',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _isPublic ? 'Público' : 'Privado',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              _isPublic
                                  ? 'Todos los usuarios pueden ver y unirse'
                                  : 'Solo miembros del grupo pueden ver y unirse',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isPublic,
                            onChanged: (bool value) {
                              setState(() {
                                _isPublic = value;
                              });
                            },
                            activeTrackColor: Colors.blue.withValues(alpha: 0.5),
                            activeThumbColor: Colors.blue,
                          ),
                          if (!_isPublic && _selectedGrupo == null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Los eventos privados requieren un grupo asociado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón de guardar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.event == null ? 'Crear Evento' : 'Guardar Cambios',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUbicacionSelector({
    required String titulo,
    required IconData icono,
    required String? direccion,
    required double? latitud,
    required double? longitud,
    required TextEditingController labelController,
    required VoidCallback onSeleccionar,
    required VoidCallback? onVerRuta,
  }) {
    final tieneUbicacion = direccion != null && direccion.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (!tieneUbicacion)
          // Botón para seleccionar ubicación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSeleccionar,
              icon: Icon(icono),
              label: const Text('Seleccionar en Mapa'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )
        else
          // Mostrar ubicación seleccionada con campo de label
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo para label personalizado
                  TextField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Nombre personalizado (opcional)',
                      hintText: 'Ej: Casa de Juan, Aeropuerto...',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(icono),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dirección de Google Places
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccion,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (latitud != null && longitud != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${latitud.toStringAsFixed(4)}, Lng: ${longitud.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSeleccionar,
                          icon: const Icon(Icons.edit_location),
                          label: const Text('Cambiar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onVerRuta,
                          icon: const Icon(Icons.directions),
                          label: const Text('Ver Ruta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, size: 48),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Seleccionar foto'),
        ),
      ],
    );
  }
}
