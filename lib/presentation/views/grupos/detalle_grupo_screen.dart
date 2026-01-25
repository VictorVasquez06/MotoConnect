import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/miembro_grupo_model.dart';
import '../../../data/models/sesion_ruta_activa_model.dart';
import '../../../data/repositories/grupo_repository.dart';
import 'editar_grupo_screen.dart';
import 'mapa_compartido_screen.dart';

/// Pantalla de detalle de un grupo
///
/// Muestra información del grupo, miembros y sesiones activas
class DetalleGrupoScreen extends StatefulWidget {
  final GrupoRutaModel grupo;

  const DetalleGrupoScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<DetalleGrupoScreen> createState() => _DetalleGrupoScreenState();
}

class _DetalleGrupoScreenState extends State<DetalleGrupoScreen>
    with SingleTickerProviderStateMixin {
  final GrupoRepository _grupoRepository = GrupoRepository();

  late TabController _tabController;
  List<MiembroGrupoModel> _miembros = [];
  List<SesionRutaActivaModel> _sesionesActivas = [];
  bool _isLoading = true;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final miembros =
          await _grupoRepository.obtenerMiembrosGrupo(widget.grupo.id);
      final sesiones =
          await _grupoRepository.obtenerSesionesActivas(widget.grupo.id);
      final esAdmin = await _grupoRepository.esAdminDeGrupo(widget.grupo.id);

      setState(() {
        _miembros = miembros;
        _sesionesActivas = sesiones;
        _esAdmin = esAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
          if (_esAdmin)
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              itemBuilder: (context) => [
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
                      Text('Eliminar grupo', style: TextStyle(color: Colors.red)),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMiembrosTab(),
          _buildSesionesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _iniciarSesion,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Sesión'),
      ),
    );
  }

  Widget _buildMiembrosTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: Column(
        children: [
          _buildGrupoInfo(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _miembros.length,
              itemBuilder: (context, index) {
                final miembro = _miembros[index];
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
            // Foto del grupo (si existe)
            if (widget.grupo.fotoUrl != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.grupo.fotoUrl!),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copiarCodigo(widget.grupo.codigoInvitacion),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text('${_miembros.length} miembros'),
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
          backgroundImage: miembro.fotoPerfilUsuario != null
              ? NetworkImage(miembro.fotoPerfilUsuario!)
              : null,
          child: miembro.fotoPerfilUsuario == null
              ? Text(miembro.nombreUsuario?.substring(0, 1).toUpperCase() ?? 'U')
              : null,
        ),
        title: Text(miembro.nombreUsuario ?? 'Usuario'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (miembro.apodoUsuario != null) Text('Apodo: ${miembro.apodoUsuario}'),
            Text(
              'Unido: ${_formatFecha(miembro.fechaUnion)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: miembro.esAdmin
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

  Widget _buildSesionesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sesionesActivas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay sesiones activas'),
            const SizedBox(height: 8),
            const Text(
              'Inicia una sesión para comenzar a compartir ubicaciones en tiempo real',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sesionesActivas.length,
        itemBuilder: (context, index) {
          final sesion = _sesionesActivas[index];
          return _buildSesionCard(sesion);
        },
      ),
    );
  }

  Widget _buildSesionCard(SesionRutaActivaModel sesion) {
    // Verificar si el usuario actual es el líder de esta sesión o admin del grupo
    final supabase = Supabase.instance.client;
    final miUsuarioId = supabase.auth.currentUser?.id;
    final esLiderDeSesion = sesion.iniciadaPor == miUsuarioId;
    final puedeFinalizarSesion = esLiderDeSesion || _esAdmin;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de finalizar sesión (solo líder o admin)
            if (puedeFinalizarSesion && sesion.estaActiva)
              IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                onPressed: () => _finalizarSesionDesdeLista(sesion),
                tooltip: 'Finalizar sesión',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (puedeFinalizarSesion && sesion.estaActiva)
              const SizedBox(width: 8),
            // Flecha para abrir
            Icon(
              sesion.estaActiva ? Icons.arrow_forward_ios : Icons.history,
              size: 16,
            ),
          ],
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

  Future<void> _iniciarSesion() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Sesión'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la sesión *',
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un nombre')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      try {
        final sesion = await _grupoRepository.iniciarSesion(
          grupoId: widget.grupo.id,
          nombreSesion: nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
        );

        if (mounted) {
          _abrirMapaCompartido(sesion);
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString();

          // Detectar si el error es por sesión activa existente
          if (errorMsg.contains('Ya tienes una sesión activa')) {
            // Mostrar diálogo con opción de ir a la sesión existente
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sesión Activa Existente'),
                content: Text(
                  errorMsg.replaceAll('Exception: ', ''),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Obtener la sesión existente y abrirla
                      final sesionExistente =
                          await _grupoRepository.obtenerSesionActivaDelUsuario();
                      if (sesionExistente != null && mounted) {
                        _abrirMapaCompartido(sesionExistente);
                      }
                    },
                    child: const Text('Ir a Mi Sesión'),
                  ),
                ],
              ),
            );
          } else {
            // Mostrar error genérico
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al iniciar sesión: $errorMsg'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
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
        builder: (context) => MapaCompartidoScreen(
          sesion: sesion,
          grupo: widget.grupo,
        ),
      ),
    ).then((_) => _cargarDatos());
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'editar':
        _editarGrupo();
        break;
      case 'eliminar':
        _eliminarGrupo();
        break;
    }
  }

  void _editarGrupo() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarGrupoScreen(grupo: widget.grupo),
      ),
    );

    // Si se actualizó, recargar datos del grupo
    if (resultado == true && mounted) {
      setState(() {
        // El widget.grupo se actualizará automáticamente vía stream
      });
    }
  }

  Future<void> _finalizarSesionDesdeLista(SesionRutaActivaModel sesion) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Sesión'),
        content: Text(
          '¿Estás seguro de que deseas finalizar la sesión "${sesion.nombreSesion}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      try {
        await _grupoRepository.finalizarSesion(sesion.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión finalizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Recargar datos para actualizar la lista
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al finalizar sesión: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarGrupo() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este grupo? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      try {
        await _grupoRepository.eliminarGrupo(widget.grupo.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar grupo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
