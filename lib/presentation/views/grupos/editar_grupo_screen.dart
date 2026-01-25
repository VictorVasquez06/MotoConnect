import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/repositories/grupo_repository.dart';

/// Pantalla para editar un grupo existente
///
/// Permite editar:
/// - Nombre del grupo
/// - Descripción
/// - Foto del grupo
class EditarGrupoScreen extends StatefulWidget {
  final GrupoRutaModel grupo;

  const EditarGrupoScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<EditarGrupoScreen> createState() => _EditarGrupoScreenState();
}

class _EditarGrupoScreenState extends State<EditarGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final GrupoRepository _grupoRepository = GrupoRepository();
  final ImagePicker _picker = ImagePicker();

  File? _imagenSeleccionada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-cargar valores actuales
    _nombreController.text = widget.grupo.nombre;
    _descripcionController.text = widget.grupo.descripcion ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagenSeleccionada = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? fotoUrl = widget.grupo.fotoUrl;

      // Si hay nueva imagen, subirla
      if (_imagenSeleccionada != null) {
        debugPrint('📤 Subiendo nueva foto del grupo...');
        fotoUrl = await _grupoRepository.subirFotoGrupo(
          grupoId: widget.grupo.id,
          imagePath: _imagenSeleccionada!.path,
        );
        debugPrint('✅ Foto subida: $fotoUrl');
      }

      // Actualizar grupo
      debugPrint('💾 Actualizando datos del grupo...');
      await _grupoRepository.actualizarGrupo(
        grupoId: widget.grupo.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        fotoUrl: fotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar actualización
      }
    } catch (e) {
      debugPrint('❌ Error al guardar cambios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Grupo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando cambios...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto del grupo
                    Center(
                      child: GestureDetector(
                        onTap: _seleccionarImagen,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _imagenSeleccionada != null
                                  ? FileImage(_imagenSeleccionada!)
                                  : (widget.grupo.fotoUrl != null
                                      ? NetworkImage(widget.grupo.fotoUrl!)
                                      : null) as ImageProvider?,
                              child: (_imagenSeleccionada == null &&
                                      widget.grupo.fotoUrl == null)
                                  ? Icon(
                                      Icons.group,
                                      size: 50,
                                      color: Colors.grey[600],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca para cambiar la foto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nombre del grupo
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del grupo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (value.trim().length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    ElevatedButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
