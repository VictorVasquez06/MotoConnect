/// Pantalla de Edición de Perfil
///
/// Permite editar información detallada del perfil.
/// Usa ProfileBloc para gestión de estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _apodoController = TextEditingController();

  String? _selectedMotorcycleBrand;
  String? _selectedMotorcycleModel;
  String? _motorcycleYear;
  String? _profileImageUrl;

  bool _isLoading = false;
  bool _hasLoadedData = false;

  final List<String> _motorcycleBrands = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Kawasaki',
    'Ducati',
    'BMW',
    'Harley-Davidson',
    'KTM',
    'Triumph',
    'Aprilia',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Intentar cargar desde el estado actual del ProfileBloc
    final profileState = context.read<ProfileBloc>().state;

    if (profileState is ProfileLoaded) {
      _populateFields(profileState);
    } else if (profileState is ProfileUpdateSuccess) {
      _populateFieldsFromUpdateSuccess(profileState);
    } else {
      // Si no hay datos, cargar el perfil
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<ProfileBloc>().add(
          ProfileLoadRequested(userId: authState.user.id),
        );
      }
    }
  }

  void _populateFields(ProfileLoaded state) {
    if (_hasLoadedData) return;
    _hasLoadedData = true;

    final user = state.user;
    _nameController.text = user.nombre;
    _emailController.text = user.email;
    _apodoController.text = user.apodo ?? '';
    _profileImageUrl = user.fotoPerfil;

    // Parsear modelo de moto si existe
    if (user.modeloMoto != null && user.modeloMoto!.isNotEmpty) {
      _selectedMotorcycleModel = user.modeloMoto;
    }
  }

  void _populateFieldsFromUpdateSuccess(ProfileUpdateSuccess state) {
    if (_hasLoadedData) return;
    _hasLoadedData = true;

    final user = state.user;
    _nameController.text = user.nombre;
    _emailController.text = user.email;
    _apodoController.text = user.apodo ?? '';
    _profileImageUrl = user.fotoPerfil;

    if (user.modeloMoto != null && user.modeloMoto!.isNotEmpty) {
      _selectedMotorcycleModel = user.modeloMoto;
    }
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && !_hasLoadedData) {
          _populateFields(state);
          setState(() {});
        } else if (state is ProfileUpdateSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is ProfileLoading) {
          // Solo mostrar loading si estamos guardando
          if (_isLoading) {
            // Ya está en estado de carga
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final isSaving = state is ProfileLoading && _isLoading;
                return TextButton(
                  onPressed: isSaving ? null : _saveProfile,
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'GUARDAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading && !_hasLoadedData) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 32),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildMotorcycleInfoSection(),
                    const SizedBox(height: 24),
                    _buildAdditionalInfoSection(),
                    const SizedBox(height: 32),
                    _buildDangerZone(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : null,
            child:
                _profileImageUrl == null || _profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 60)
                    : null,
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
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _changeProfileImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _apodoController,
          decoration: const InputDecoration(
            labelText: 'Apodo',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
            hintText: 'Se mostrará en rutas grupales',
          ),
          maxLength: 20,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico *',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // El email no se puede cambiar
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Ubicación',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
            hintText: 'Ciudad, País',
          ),
        ),
      ],
    );
  }

  Widget _buildMotorcycleInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Motocicleta',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedMotorcycleBrand,
          decoration: const InputDecoration(
            labelText: 'Marca',
            prefixIcon: Icon(Icons.motorcycle),
            border: OutlineInputBorder(),
          ),
          items:
              _motorcycleBrands
                  .map(
                    (brand) =>
                        DropdownMenuItem(value: brand, child: Text(brand)),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMotorcycleBrand = value;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _selectedMotorcycleModel,
          decoration: const InputDecoration(
            labelText: 'Modelo',
            prefixIcon: Icon(Icons.directions_bike),
            border: OutlineInputBorder(),
            hintText: 'Ej: CBR 600RR',
          ),
          onChanged: (value) {
            _selectedMotorcycleModel = value;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _motorcycleYear,
          decoration: const InputDecoration(
            labelText: 'Año',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
            hintText: 'Ej: 2023',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _motorcycleYear = value;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Adicional',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Biografía',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
            hintText: 'Cuéntanos sobre ti...',
          ),
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zona de Peligro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red[50],
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.orange),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Actualiza tu contraseña'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changePassword,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Eliminar cuenta',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Esta acción no se puede deshacer'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changeProfileImage() {
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
                    _takePhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _takePhoto() {
    // TODO: Implementar captura de foto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de cámara próximamente disponible'),
      ),
    );
  }

  void _pickFromGallery() {
    // TODO: Implementar selección de galería
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de galería próximamente disponible'),
      ),
    );
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageUrl = null;
    });
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = _getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Construir modelo de moto combinado
    String? modeloMoto;
    if (_selectedMotorcycleBrand != null || _selectedMotorcycleModel != null) {
      final parts = <String>[];
      if (_selectedMotorcycleBrand != null)
        parts.add(_selectedMotorcycleBrand!);
      if (_selectedMotorcycleModel != null &&
          _selectedMotorcycleModel!.isNotEmpty) {
        parts.add(_selectedMotorcycleModel!);
      }
      if (_motorcycleYear != null && _motorcycleYear!.isNotEmpty) {
        parts.add(_motorcycleYear!);
      }
      modeloMoto = parts.join(' ');
    }

    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        userId: userId,
        nombre: _nameController.text.trim(),
        modeloMoto: modeloMoto?.isNotEmpty == true ? modeloMoto : null,
        apodo:
            _apodoController.text.trim().isNotEmpty
                ? _apodoController.text.trim()
                : null,
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cambiar Contraseña'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar cambio de contraseña via AuthBloc
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidad pendiente de implementación',
                      ),
                    ),
                  );
                },
                child: const Text('CAMBIAR'),
              ),
            ],
          ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Cuenta'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de que deseas eliminar tu cuenta?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Esta acción:'),
                SizedBox(height: 8),
                Text('• Eliminará permanentemente todos tus datos'),
                Text('• Cancelará todas tus inscripciones a eventos'),
                Text('• Eliminará todas tus publicaciones'),
                Text('• No se puede deshacer'),
                SizedBox(height: 16),
                Text(
                  'Esta acción es irreversible.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteAccount();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ELIMINAR CUENTA'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteAccount() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Por favor, ingresa tu contraseña para confirmar:'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar eliminación de cuenta via AuthBloc
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidad pendiente de implementación',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
    );
  }
}
