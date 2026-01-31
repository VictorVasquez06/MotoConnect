/// Pantalla de Creación de Ruta
///
/// Permite crear una nueva ruta con información detallada.
/// Usa RoutesBloc para persistencia.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/routes/routes_bloc.dart';
import '../../blocs/routes/routes_event.dart';
import '../../blocs/routes/routes_state.dart';

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

  // Puntos para la ruta (se llenarán cuando se seleccione en el mapa)
  List<LatLng> _routePoints = [];

  final List<Map<String, dynamic>> _waypoints = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    super.dispose();
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoutesBloc, RoutesState>(
      listener: (context, state) {
        if (state is RoutesOperationSuccess &&
            state.operationType == RoutesOperationType.created) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is RoutesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crear Nueva Ruta'),
          actions: [
            BlocBuilder<RoutesBloc, RoutesState>(
              builder: (context, state) {
                final isLoading = state is RoutesLoading;
                return TextButton(
                  onPressed: isLoading ? null : _saveRoute,
                  child:
                      isLoading
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
          value: _selectedDifficulty,
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
          value: _selectedRoadType,
          decoration: const InputDecoration(
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
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/map-picker');
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  if (result['points'] != null) {
                    _routePoints = List<LatLng>.from(result['points']);
                  }
                });
              }
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    _routePoints.isEmpty
                        ? 'Toca para abrir el mapa'
                        : '${_routePoints.length} puntos trazados',
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
    Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: {'isStartPoint': isStartPoint},
    ).then((result) {
      if (result != null && result is Map) {
        setState(() {
          if (isStartPoint) {
            _startPointController.text = result['address'] ?? '';
            if (result['position'] != null) {
              _routePoints.insert(0, result['position'] as LatLng);
            }
          } else {
            _endPointController.text = result['address'] ?? '';
            if (result['position'] != null) {
              _routePoints.add(result['position'] as LatLng);
            }
          }
        });
      }
    });
  }

  void _addWaypoint() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext);
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
      final userId = _getCurrentUserId();

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para crear rutas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Si no hay puntos de ruta, crear puntos por defecto basados en las direcciones
      List<LatLng> puntosRuta = _routePoints;
      if (puntosRuta.isEmpty) {
        // Puntos por defecto (Bogotá) - en producción esto vendría del mapa
        puntosRuta = [
          const LatLng(4.5981, -74.0758),
          const LatLng(4.6500, -74.1000),
        ];
      }

      context.read<RoutesBloc>().add(
        RoutesCreateRequested(
          userId: userId,
          nombreRuta: _nameController.text.trim(),
          descripcionRuta:
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
          puntos: puntosRuta,
          distanciaKm: _estimatedDistance,
          duracionMinutos: _estimatedDuration,
        ),
      );
    }
  }
}
