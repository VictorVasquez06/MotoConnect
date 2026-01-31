import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../blocs/grupos/grupos_bloc.dart';
import '../../blocs/grupos/grupos_event.dart';
import '../../blocs/grupos/grupos_state.dart';
import 'crear_grupo_screen.dart';
import 'unirse_grupo_screen.dart';
import 'detalle_grupo_screen.dart';

/// Pantalla de lista de grupos
///
/// Muestra todos los grupos de los que el usuario es miembro
/// Usa GruposBloc para gestión de estado.
class GruposScreen extends StatelessWidget {
  const GruposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GruposBloc>().add(const GruposRefreshRequested());
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocConsumer<GruposBloc, GruposState>(
        listener: (context, state) {
          if (state is GruposError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GruposOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GruposLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GruposInitial) {
            // Trigger fetch if not loaded yet
            context.read<GruposBloc>().add(const GruposFetchRequested());
            return const Center(child: CircularProgressIndicator());
          }

          // Get grupos from various states
          List<GrupoRutaModel> grupos = [];
          if (state is GruposLoaded) {
            grupos = state.grupos;
          } else if (state is GruposOperationSuccess) {
            grupos = state.grupos;
          } else if (state is GruposError && state.previousGrupos != null) {
            grupos = state.previousGrupos!;
          } else if (state is GruposDetailLoaded) {
            grupos = state.grupos;
          }

          if (grupos.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GruposBloc>().add(const GruposRefreshRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grupos.length,
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                return _GrupoCard(grupo: grupo);
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'unirse',
            onPressed: () => _unirseAGrupo(context),
            tooltip: 'Unirse a grupo',
            child: const Icon(Icons.vpn_key),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'crear',
            onPressed: () => _crearGrupo(context),
            tooltip: 'Crear grupo',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No tienes grupos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un grupo o únete a uno existente',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _crearGrupo(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear grupo'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _unirseAGrupo(context),
                icon: const Icon(Icons.vpn_key),
                label: const Text('Unirse con código'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _crearGrupo(BuildContext context) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CrearGrupoScreen()),
    );

    if (resultado == true && context.mounted) {
      context.read<GruposBloc>().add(const GruposFetchRequested());
    }
  }

  Future<void> _unirseAGrupo(BuildContext context) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const UnirseGrupoScreen()),
    );

    if (resultado == true && context.mounted) {
      context.read<GruposBloc>().add(const GruposFetchRequested());
    }
  }
}

/// Widget separado para la tarjeta de grupo
class _GrupoCard extends StatelessWidget {
  final GrupoRutaModel grupo;

  const _GrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(
          grupo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (grupo.descripcion != null && grupo.descripcion!.isNotEmpty)
              Text(grupo.descripcion!),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  grupo.codigoInvitacion,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _copiarCodigo(context, grupo.codigoInvitacion),
                  child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _abrirDetalleGrupo(context),
      ),
    );
  }

  void _copiarCodigo(BuildContext context, String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $codigo copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirDetalleGrupo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalleGrupoScreen(grupo: grupo)),
    ).then((_) {
      if (context.mounted) {
        context.read<GruposBloc>().add(const GruposFetchRequested());
      }
    });
  }
}
