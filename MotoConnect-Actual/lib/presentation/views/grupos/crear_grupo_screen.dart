import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/grupos/grupos_bloc.dart';
import '../../blocs/grupos/grupos_event.dart';
import '../../blocs/grupos/grupos_state.dart';

/// Pantalla para crear un nuevo grupo
/// Usa GruposBloc para gestión de estado.
class CrearGrupoScreen extends StatefulWidget {
  const CrearGrupoScreen({super.key});

  @override
  State<CrearGrupoScreen> createState() => _CrearGrupoScreenState();
}

class _CrearGrupoScreenState extends State<CrearGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GruposBloc, GruposState>(
      listener: (context, state) {
        if (state is GruposError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is GruposOperationSuccess &&
            state.createdGrupo != null) {
          // Mostrar diálogo con el código de invitación
          _mostrarDialogoExito(context, state.createdGrupo!.codigoInvitacion);
        }
      },
      child: BlocBuilder<GruposBloc, GruposState>(
        builder: (context, state) {
          final isLoading = state is GruposLoading;

          return Scaffold(
            appBar: AppBar(title: const Text('Crear Grupo')),
            body:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.groups,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Crea un grupo para compartir rutas',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Invita a tus amigos y compartan su ubicación en tiempo real',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del grupo *',
                                prefixIcon: Icon(Icons.label),
                                border: OutlineInputBorder(),
                                hintText: 'Ej: Riders del Norte',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa un nombre';
                                }
                                if (value.trim().length < 3) {
                                  return 'El nombre debe tener al menos 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descripcionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripción (opcional)',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                                hintText: 'Describe el propósito del grupo',
                              ),
                              maxLines: 3,
                              maxLength: 200,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _crearGrupo,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Grupo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '¿Qué puedes hacer?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoItem(
                                      '• Compartir ubicación en tiempo real',
                                    ),
                                    _buildInfoItem(
                                      '• Ver la ubicación de todos los miembros',
                                    ),
                                    _buildInfoItem(
                                      '• Planificar rutas grupales',
                                    ),
                                    _buildInfoItem(
                                      '• Invitar miembros con un código',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(text),
    );
  }

  void _crearGrupo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<GruposBloc>().add(
      GruposCreateRequested(
        nombre: _nombreController.text.trim(),
        descripcion:
            _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
      ),
    );
  }

  void _mostrarDialogoExito(BuildContext context, String codigoInvitacion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¡Grupo creado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Tu código de invitación es:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    codigoInvitacion,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comparte este código con tus amigos para que se unan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Cerrar diálogo
                  Navigator.pop(context, true); // Volver a la lista
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          ),
    );
  }
}
