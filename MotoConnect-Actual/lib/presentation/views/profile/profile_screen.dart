/// Pantalla de Perfil de Usuario
///
/// Muestra y permite editar el perfil del usuario actual.
/// Usa ProfileBloc para gestión de estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _modeloMotoController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();

  bool _subiendoImagen = false;
  String? _avatarUrl;
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _modeloMotoController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  void _cargarPerfil() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(
        ProfileLoadRequested(userId: authState.user.id),
      );
    }
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  void _guardarPerfil() {
    if (!_formKey.currentState!.validate()) return;

    final userId = _getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: No se pudo identificar al usuario."),
        ),
      );
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        userId: userId,
        nombre: _nombreController.text.trim(),
        modeloMoto:
            _modeloMotoController.text.trim().isNotEmpty
                ? _modeloMotoController.text.trim()
                : null,
        apodo:
            _apodoController.text.trim().isNotEmpty
                ? _apodoController.text.trim()
                : null,
      ),
    );
  }

  /// Muestra las opciones para cambiar la foto de perfil
  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _tomarFoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarDeGaleria();
                  },
                ),
                if (_avatarUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _eliminarFoto();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  /// Toma una foto con la cámara
  Future<void> _tomarFoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (photo != null) {
        await _subirImagen(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: ${e.toString()}')),
        );
      }
    }
  }

  /// Selecciona una imagen de la galería
  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        await _subirImagen(File(image.path));
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

  /// Sube la imagen al bucket de Supabase
  Future<void> _subirImagen(File imageFile) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no identificado')),
        );
      }
      return;
    }

    setState(() => _subiendoImagen = true);

    try {
      // Subir imagen a Supabase Storage
      final imageUrl = await _storageService.uploadAvatar(
        imageFile: imageFile,
        userId: userId,
      );

      // Actualizar via ProfileBloc
      if (mounted) {
        context.read<ProfileBloc>().add(
          ProfilePhotoUpdateRequested(userId: userId, photoUrl: imageUrl),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _subiendoImagen = false);
      }
    }
  }

  /// Cierra la sesión del usuario
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );

    if (confirmar != true || !mounted) return;

    // Limpiar estado del perfil
    context.read<ProfileBloc>().add(const ProfileClearRequested());

    // Cerrar sesión via AuthBloc
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  /// Elimina la foto de perfil
  Future<void> _eliminarFoto() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar foto de perfil'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar tu foto de perfil?',
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

    setState(() => _subiendoImagen = true);

    try {
      await _storageService.deleteAvatar(userId: userId);

      if (mounted) {
        context.read<ProfileBloc>().add(
          ProfilePhotoUpdateRequested(userId: userId, photoUrl: ''),
        );
        setState(() => _avatarUrl = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _subiendoImagen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            // Actualizar controllers con datos del perfil
            _nombreController.text = state.user.nombre;
            _correoController.text = state.user.email;
            _modeloMotoController.text = state.user.modeloMoto ?? '';
            _apodoController.text = state.user.apodo ?? '';
            _avatarUrl = state.user.fotoPerfil;
          } else if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Actualizar controllers con datos actualizados
            _nombreController.text = state.user.nombre;
            _modeloMotoController.text = state.user.modeloMoto ?? '';
            _apodoController.text = state.user.apodo ?? '';
            _avatarUrl = state.user.fotoPerfil;
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isLoaded =
              state is ProfileLoaded || state is ProfileUpdateSuccess;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                          child:
                              _avatarUrl == null || _avatarUrl!.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[600],
                                  )
                                  : null,
                        ),
                        if (_subiendoImagen)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black54,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed:
                                  _subiendoImagen ? null : _mostrarOpcionesFoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apodoController,
                    decoration: const InputDecoration(
                      labelText: "Apodo",
                      hintText: "Se mostrará en rutas grupales",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _correoController,
                    decoration: const InputDecoration(
                      labelText: "Correo Electrónico",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modeloMotoController,
                    decoration: const InputDecoration(
                      labelText: "Modelo de Moto",
                      hintText: "Ej: Yamaha MT-07",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.motorcycle_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final isUpdating = state is ProfileLoading;
                      return ElevatedButton.icon(
                        icon:
                            isUpdating
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save_alt_outlined),
                        label: Text(
                          isUpdating ? "Guardando..." : "Guardar Cambios",
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed:
                            isUpdating || !isLoaded ? null : _guardarPerfil,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    "Mis Rutas Guardadas",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text("Ver mis rutas"),
                    onPressed: () async {
                      final resultado = await Navigator.pushNamed(
                        context,
                        '/rutas-recomendadas',
                      );
                      if (resultado != null &&
                          resultado is Map<String, dynamic>) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            '/rutas',
                            arguments: resultado,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar Sesión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _cerrarSesion,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
