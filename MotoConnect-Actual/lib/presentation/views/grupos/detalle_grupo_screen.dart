import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/miembro_grupo_model.dart';
import '../../../data/models/sesion_ruta_activa_model.dart';
import '../../../domain/repositories/i_grupo_repository.dart';
import '../../blocs/grupos/grupos_bloc.dart';
import '../../blocs/grupos/grupos_event.dart';
import '../../blocs/grupos/grupos_state.dart';
import 'mapa_compartido_screen.dart';

/// Pantalla de detalle de un grupo
///
/// Muestra información del grupo, miembros y sesiones activas.
/// Usa GruposBloc para gestión de estado.
class DetalleGrupoScreen extends StatefulWidget {
  final GrupoRutaModel grupo;

  const DetalleGrupoScreen({super.key, required this.grupo});

  @override
  State<DetalleGrupoScreen> createState() => _DetalleGrupoScreenState();
}

class _DetalleGrupoScreenState extends State<DetalleGrupoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar detalle del grupo via BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GruposBloc>().add(
        GruposLoadDetail(grupoId: widget.grupo.id),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GruposBloc, GruposState>(
      listener: (context, state) {
        if (state is GruposError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is GruposOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Si fue eliminación, regresar
          if (state.message.contains('eliminado') ||
              state.message.contains('salido')) {
            Navigator.pop(context, true);
          }
        }
      },
      builder: (context, state) {
        // Extraer datos del estado
        List<MiembroGrupoModel> miembros = [];
        List<SesionRutaActivaModel> sesionesActivas = [];
        bool esAdmin = false;
        bool isLoading = state is GruposLoading;

        if (state is GruposDetailLoaded) {
          miembros = state.miembros;
          sesionesActivas = state.sesionesActivas;
          esAdmin = state.isAdmin;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.grupo.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<GruposBloc>().add(
                    GruposLoadDetail(grupoId: widget.grupo.id),
                  );
                },
              ),
              if (esAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) => _onMenuSelected(value, context),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Editar grupo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Eliminar grupo',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Miembros', icon: Icon(Icons.people)),
                Tab(text: 'Sesiones', icon: Icon(Icons.route)),
              ],
            ),
          ),
          body:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMiembrosTab(miembros),
                      _buildSesionesTab(sesionesActivas),
                    ],
                  ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _iniciarSesion(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Ruta'),
          ),
        );
      },
    );
  }

  Widget _buildMiembrosTab(List<MiembroGrupoModel> miembros) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<GruposBloc>().add(
          GruposLoadDetail(grupoId: widget.grupo.id),
        );
      },
      child: Column(
        children: [
          _buildGrupoInfo(),
          Expanded(
            child:
                miembros.isEmpty
                    ? const Center(child: Text('No hay miembros'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: miembros.length,
                      itemBuilder: (context, index) {
                        final miembro = miembros[index];
                        return _buildMiembroCard(miembro);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.grupo.descripcion != null &&
                widget.grupo.descripcion!.isNotEmpty) ...[
              Text(
                widget.grupo.descripcion!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Código: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.grupo.codigoInvitacion,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copiarCodigo(widget.grupo.codigoInvitacion),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiembroCard(MiembroGrupoModel miembro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              miembro.fotoPerfilUsuario != null
                  ? NetworkImage(miembro.fotoPerfilUsuario!)
                  : null,
          child:
              miembro.fotoPerfilUsuario == null
                  ? Text(
                    miembro.nombreUsuario?.substring(0, 1).toUpperCase() ?? 'U',
                  )
                  : null,
        ),
        title: Text(miembro.nombreUsuario ?? 'Usuario'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (miembro.apodoUsuario != null)
              Text('Apodo: ${miembro.apodoUsuario}'),
            Text(
              'Unido: ${_formatFecha(miembro.fechaUnion)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing:
            miembro.esAdmin
                ? Chip(
                  label: const Text(
                    'Admin',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                )
                : null,
      ),
    );
  }

  Widget _buildSesionesTab(List<SesionRutaActivaModel> sesionesActivas) {
    if (sesionesActivas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay sesiones activas'),
            const SizedBox(height: 8),
            const Text(
              'Inicia una ruta para comenzar a compartir ubicaciones',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GruposBloc>().add(
          GruposLoadDetail(grupoId: widget.grupo.id),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sesionesActivas.length,
        itemBuilder: (context, index) {
          final sesion = sesionesActivas[index];
          return _buildSesionCard(sesion);
        },
      ),
    );
  }

  Widget _buildSesionCard(SesionRutaActivaModel sesion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sesion.estaActiva ? Colors.green : Colors.orange,
          child: Icon(
            sesion.estaActiva ? Icons.navigation : Icons.pause,
            color: Colors.white,
          ),
        ),
        title: Text(
          sesion.nombreSesion,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sesion.descripcion != null) Text(sesion.descripcion!),
            Text(
              'Iniciada: ${_formatFecha(sesion.fechaInicio)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (sesion.duracion != null)
              Text(
                'Duración: ${_formatDuracion(sesion.duracion!)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Icon(
          sesion.estaActiva ? Icons.arrow_forward_ios : Icons.history,
          size: 16,
        ),
        onTap: () => _abrirMapaCompartido(sesion),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }

  String _formatDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    if (horas > 0) {
      return '$horas h $minutos min';
    }
    return '$minutos min';
  }

  void _copiarCodigo(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  Future<void> _iniciarSesion(BuildContext context) async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    // Capturar referencias antes de cualquier await
    final grupoRepository = context.read<IGrupoRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final resultado = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Iniciar Ruta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la ruta *',
                      hintText: 'Ej: Ruta al Volcán',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nombreController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Ingresa un nombre')),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('INICIAR'),
              ),
            ],
          ),
    );

    if (resultado == true && mounted) {
      try {
        // Usar el repositorio directamente para iniciar sesión
        // ya que necesitamos el resultado para abrir el mapa
        final sesion = await grupoRepository.iniciarSesion(
          grupoId: widget.grupo.id,
          nombreSesion: nombreController.text.trim(),
          descripcion:
              descripcionController.text.trim().isEmpty
                  ? null
                  : descripcionController.text.trim(),
        );

        if (mounted) {
          _abrirMapaCompartido(sesion);
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error al iniciar sesión: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    nombreController.dispose();
    descripcionController.dispose();
  }

  void _abrirMapaCompartido(SesionRutaActivaModel sesion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MapaCompartidoScreen(sesion: sesion, grupo: widget.grupo),
      ),
    ).then((_) {
      if (mounted) {
        context.read<GruposBloc>().add(
          GruposLoadDetail(grupoId: widget.grupo.id),
        );
      }
    });
  }

  void _onMenuSelected(String value, BuildContext context) {
    switch (value) {
      case 'editar':
        _editarGrupo();
        break;
      case 'eliminar':
        _eliminarGrupo(context);
        break;
    }
  }

  void _editarGrupo() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función próximamente')));
  }

  Future<void> _eliminarGrupo(BuildContext context) async {
    // Capturar referencia antes del await
    final gruposBloc = context.read<GruposBloc>();

    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar Grupo'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este grupo? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ELIMINAR'),
              ),
            ],
          ),
    );

    if (confirmacion == true && mounted) {
      gruposBloc.add(GruposDeleteRequested(grupoId: widget.grupo.id));
    }
  }
}
