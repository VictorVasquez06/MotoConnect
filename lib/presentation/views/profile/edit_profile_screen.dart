import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';

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

  String? _selectedMotorcycleBrand;
  String? _selectedMotorcycleModel;
  String? _motorcycleYear;
  String? _profileImageUrl;

  bool _isLoading = false;

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
    final viewModel = context.read<ProfileViewModel>();
    final user = viewModel.currentUser;

    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _bioController.text = user.bio ?? '';
      _locationController.text = user.location ?? '';
      _selectedMotorcycleBrand = user.motorcycleBrand;
      _selectedMotorcycleModel = user.motorcycleModel;
      _motorcycleYear = user.motorcycleYear;
      _profileImageUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'GUARDAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
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
                _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
            child:
                _profileImageUrl == null
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
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico *',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu correo';
            }
            if (!value.contains('@')) {
              return 'Por favor ingresa un correo válido';
            }
            return null;
          },
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
          initialValue: _selectedMotorcycleBrand,
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
              _selectedMotorcycleModel = null;
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
                if (_profileImageUrl != null)
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

    setState(() {
      _isLoading = true;
    });

    final profileData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'motorcycle_brand': _selectedMotorcycleBrand,
      'motorcycle_model': _selectedMotorcycleModel,
      'motorcycle_year': _motorcycleYear,
      'avatar_url': _profileImageUrl,
    };

    context
        .read<ProfileViewModel>()
        .updateProfile(profileData)
        .then((_) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        })
        .catchError((error) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar perfil: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
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
                  // TODO: Implementar cambio de contraseña
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada'),
                      backgroundColor: Colors.green,
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
                  // TODO: Implementar eliminación de cuenta
                  Navigator.pop(context);
                  context.read<ProfileViewModel>().deleteAccount();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
    );
  }
}
