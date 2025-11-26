import 'package:flutter/material.dart';
import '../../../data/repositories/grupo_repository.dart';

/// Pantalla para unirse a un grupo mediante código
class UnirseGrupoScreen extends StatefulWidget {
  const UnirseGrupoScreen({super.key});

  @override
  State<UnirseGrupoScreen> createState() => _UnirseGrupoScreenState();
}

class _UnirseGrupoScreenState extends State<UnirseGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final GrupoRepository _grupoRepository = GrupoRepository();

  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse a Grupo'),
      ),
      body: _isLoading
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
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
                                Icon(Icons.info, color: Colors.orange[700]),
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
  }

  Future<void> _unirseAGrupo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final grupo = await _grupoRepository.unirseAGrupo(
        _codigoController.text.trim().toUpperCase(),
      );

      if (mounted) {
        // Mostrar diálogo de éxito
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
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
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context, true); // Volver a la lista
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Error al unirse al grupo';
        if (e.toString().contains('inválido')) {
          errorMessage = 'Código de invitación inválido';
        } else if (e.toString().contains('ya eres miembro')) {
          errorMessage = 'Ya eres miembro de este grupo';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
