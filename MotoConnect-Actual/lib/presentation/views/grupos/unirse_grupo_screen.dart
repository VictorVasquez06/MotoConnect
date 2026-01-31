import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/grupos/grupos_bloc.dart';
import '../../blocs/grupos/grupos_event.dart';
import '../../blocs/grupos/grupos_state.dart';

/// Pantalla para unirse a un grupo mediante código
/// Usa GruposBloc para gestión de estado.
class UnirseGrupoScreen extends StatefulWidget {
  const UnirseGrupoScreen({super.key});

  @override
  State<UnirseGrupoScreen> createState() => _UnirseGrupoScreenState();
}

class _UnirseGrupoScreenState extends State<UnirseGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
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
          // Mostrar diálogo de éxito
          _mostrarDialogoExito(context, state.createdGrupo!);
        }
      },
      child: BlocBuilder<GruposBloc, GruposState>(
        builder: (context, state) {
          final isLoading = state is GruposLoading;

          return Scaffold(
            appBar: AppBar(title: const Text('Unirse a Grupo')),
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
                              Icons.vpn_key,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Únete a un grupo',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingresa el código de invitación que te compartieron',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _codigoController,
                              decoration: const InputDecoration(
                                labelText: 'Código de invitación *',
                                prefixIcon: Icon(Icons.vpn_key),
                                border: OutlineInputBorder(),
                                hintText: 'Ej: ABC123',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 6,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el código';
                                }
                                if (value.trim().length != 6) {
                                  return 'El código debe tener 6 caracteres';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Convertir a mayúsculas automáticamente
                                final upperValue = value.toUpperCase();
                                if (value != upperValue) {
                                  _codigoController.value = TextEditingValue(
                                    text: upperValue,
                                    selection: TextSelection.collapsed(
                                      offset: upperValue.length,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _unirseAGrupo,
                              icon: const Icon(Icons.login),
                              label: const Text('Unirse al Grupo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Importante',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '• El código debe tener exactamente 6 caracteres',
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '• Solo puedes unirte a grupos activos',
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '• Una vez dentro, podrás compartir tu ubicación',
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

  void _unirseAGrupo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<GruposBloc>().add(
      GruposJoinRequested(codigo: _codigoController.text.trim().toUpperCase()),
    );
  }

  void _mostrarDialogoExito(BuildContext context, dynamic grupo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¡Te uniste al grupo!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Ahora eres miembro de:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  grupo.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (grupo.descripcion != null &&
                    grupo.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    grupo.descripcion!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
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
