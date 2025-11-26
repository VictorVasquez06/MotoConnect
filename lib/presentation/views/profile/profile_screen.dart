import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/storage_service.dart';

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

  bool _cargando = true;
  bool _subiendoImagen = false;
  String? _userId; // Para guardar el UID del usuario actual
  String? _avatarUrl; // URL de la foto de perfil
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _modeloMotoController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
    });

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      _userId = supabaseUser.id;
      _correoController.text = supabaseUser.email ?? 'No disponible';

      // <<< INICIO DE LA MODIFICACIÓN: Verificación explícita de _userId >>>
      if (_userId == null) {
        print(
          "Error crítico: _userId es nulo antes de la consulta a Supabase en _cargarDatosUsuario.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error fatal: No se pudo identificar al usuario."),
            ),
          );
          setState(() {
            _cargando = false;
            _nombreController.text = 'Error de ID';
            _modeloMotoController.text = '';
          });
        }
        return; // Salimos de la función si _userId es nulo
      }
      // <<< FIN DE LA MODIFICACIÓN >>>

      try {
        final respuesta =
            await Supabase.instance.client
                .from('usuarios')
                .select('nombre, modelo_moto, foto_perfil_url, apodo')
                .eq(
                  'id',
                  _userId!,
                ) // El '!' es más seguro después de la verificación explícita
                .single();

        if (mounted) {
          _nombreController.text = respuesta['nombre'] ?? 'Completa tu nombre';
          _modeloMotoController.text = respuesta['modelo_moto'] ?? '';
          _apodoController.text = respuesta['apodo'] ?? '';
          _avatarUrl = respuesta['foto_perfil_url'] as String?;
        }
      } catch (e) {
        print("Error al cargar datos de 'usuarios' en Supabase: $e");
        if (mounted) {
          _nombreController.text = '';
          _modeloMotoController.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No se pudieron cargar los datos del perfil: ${e.toString()}",
              ),
            ),
          );
        }
      }
    } else {
      print("Error: Usuario de Firebase no encontrado en PerfilScreen.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no autenticado.")),
        );
        // Considera navegar a login si esto ocurre:
        // Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        // Esta guarda es crucial
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: No se pudo identificar al usuario. Intenta recargar.",
              ),
            ),
          );
        }
        setState(() => _cargando = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _cargando = true;
      });

      try {
        await Supabase.instance.client.from('usuarios').upsert({
          'id': _userId!,
          'correo': _correoController.text.trim(),
          'nombre': _nombreController.text.trim(),
          'modelo_moto':
              _modeloMotoController.text.trim().isEmpty
                  ? null
                  : _modeloMotoController.text.trim(),
          'apodo':
              _apodoController.text.trim().isEmpty
                  ? null
                  : _apodoController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil guardado con éxito.")),
          );
        }
      } catch (e) {
        print("Error al guardar perfil en Supabase: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al guardar perfil: ${e.toString()}")),
          );
        }
      }

      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  /// Muestra las opciones para cambiar la foto de perfil
  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
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
    if (_userId == null) {
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
        userId: _userId!,
      );

      // Actualizar la URL en la base de datos
      await Supabase.instance.client.from('usuarios').update({
        'foto_perfil_url': imageUrl,
      }).eq('id', _userId!);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
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
    // Confirmar antes de cerrar sesión
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

    if (confirmar != true) return;

    setState(() => _cargando = true);

    try {
      // Cerrar sesión en Supabase - esto limpia toda la sesión persistida
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        // Navegar a login y limpiar todo el stack de navegación
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Elimina la foto de perfil
  Future<void> _eliminarFoto() async {
    if (_userId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto de perfil'),
        content: const Text('¿Estás seguro de que deseas eliminar tu foto de perfil?'),
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
      // Eliminar imagen del storage
      await _storageService.deleteAvatar(userId: _userId!);

      // Actualizar la base de datos
      await Supabase.instance.client.from('usuarios').update({
        'foto_perfil_url': null,
      }).eq('id', _userId!);

      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada')),
        );
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
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
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
                                  _avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                              child:
                                  _avatarUrl == null
                                      ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      )
                                      : null,
                            ),
                            if (_subiendoImagen)
                              Positioned.fill(
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.black54,
                                  child: const CircularProgressIndicator(
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
                                      _subiendoImagen
                                          ? null
                                          : _mostrarOpcionesFoto,
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
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text("Guardar Cambios"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: _cargando ? null : _guardarPerfil,
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
                        onPressed: _cargando ? null : _cerrarSesion,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }
}
