import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/routes/saved_routes_viewmodel.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startPointController = TextEditingController();
  final _endPointController = TextEditingController();

  String _selectedDifficulty = 'Media';
  String _selectedRoadType = 'Mixto';
  int _scenicValue = 3;
  double _estimatedDistance = 0.0;
  int _estimatedDuration = 0;

  final List<Map<String, dynamic>> _waypoints = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Ruta'),
        actions: [
          TextButton(
            onPressed: _saveRoute,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildRouteDetailsSection(),
              const SizedBox(height: 24),
              _buildMapSection(),
              const SizedBox(height: 24),
              _buildWaypointsSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información básica',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la ruta *',
            hintText: 'Ej: Ruta Sierra Nevada',
            prefixIcon: Icon(Icons.route),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa un nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Describe la ruta...',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicaciones',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _startPointController,
          decoration: InputDecoration(
            labelText: 'Punto de inicio *',
            hintText: 'Selecciona el punto de inicio',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _selectLocationOnMap(true),
            ),
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona el punto de inicio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _endPointController,
          decoration: InputDecoration(
            labelText: 'Punto de destino *',
            hintText: 'Selecciona el punto de destino',
            prefixIcon: const Icon(Icons.flag),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _selectLocationOnMap(false),
            ),
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona el punto de destino';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRouteDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de la ruta',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Distancia (km) *',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _estimatedDistance = double.tryParse(value) ?? 0.0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Duración (min) *',
                  prefixIcon: Icon(Icons.timer),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _estimatedDuration = int.tryParse(value) ?? 0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedDifficulty,
          decoration: const InputDecoration(
            labelText: 'Dificultad',
            prefixIcon: Icon(Icons.terrain),
            border: OutlineInputBorder(),
          ),
          items:
              ['Fácil', 'Media', 'Difícil', 'Experto']
                  .map(
                    (difficulty) => DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDifficulty = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRoadType,
          decoration: InputDecoration(
            labelText: 'Tipo de vía',
            prefixIcon: Icon(Icons.route),
            border: OutlineInputBorder(),
          ),
          items:
              ['Carretera', 'Montaña', 'Urbano', 'Mixto']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRoadType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trazar ruta en mapa',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Abrir mapa para trazar ruta
              Navigator.pushNamed(context, '/map-picker');
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Toca para abrir el mapa',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Traza tu ruta en el mapa interactivo',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Puntos de interés',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addWaypoint,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_waypoints.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay puntos de interés',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega lugares interesantes en tu ruta',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _waypoints.length,
            itemBuilder: (context, index) {
              final waypoint = _waypoints[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(waypoint['name'] ?? 'Punto ${index + 1}'),
                  subtitle:
                      waypoint['description'] != null
                          ? Text(waypoint['description'])
                          : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeWaypoint(index),
                  ),
                ),
              );
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
          'Información adicional',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor paisajístico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _scenicValue ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _scenicValue = index + 1;
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectLocationOnMap(bool isStartPoint) {
    // TODO: Navegar a pantalla de selección en mapa
    Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: {'isStartPoint': isStartPoint},
    ).then((result) {
      if (result != null && result is Map) {
        setState(() {
          if (isStartPoint) {
            _startPointController.text = result['address'] ?? '';
          } else {
            _endPointController.text = result['address'] ?? '';
          }
        });
      }
    });
  }

  void _addWaypoint() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();

        return AlertDialog(
          title: const Text('Agregar punto de interés'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del lugar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _waypoints.add({
                      'name': nameController.text,
                      'description':
                          descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('AGREGAR'),
            ),
          ],
        );
      },
    );
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
  }

  void _saveRoute() {
    if (_formKey.currentState!.validate()) {
      final routeData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'start_point': _startPointController.text,
        'end_point': _endPointController.text,
        'distance': _estimatedDistance,
        'estimated_duration': _estimatedDuration,
        'difficulty': _selectedDifficulty,
        'road_type': _selectedRoadType,
        'scenic_value': _scenicValue,
        'waypoints': _waypoints,
      };

      context.read<SavedRoutesViewModel>().createRoute(routeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }
}
