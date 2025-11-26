import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/repositories/grupo_repository.dart';
import '../../../data/models/grupo_ruta_model.dart';
import 'crear_grupo_screen.dart';
import 'unirse_grupo_screen.dart';
import 'detalle_grupo_screen.dart';

/// Pantalla de lista de grupos
///
/// Muestra todos los grupos de los que el usuario es miembro
class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final GrupoRepository _grupoRepository = GrupoRepository();
  List<GrupoRutaModel> _grupos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final grupos = await _grupoRepository.obtenerMisGrupos();
      setState(() {
        _grupos = grupos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar grupos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGrupos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'unirse',
            onPressed: _unirseAGrupo,
            tooltip: 'Unirse a grupo',
            child: const Icon(Icons.vpn_key),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'crear',
            onPressed: _crearGrupo,
            tooltip: 'Crear grupo',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarGrupos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_grupos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes grupos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un grupo o únete a uno existente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _crearGrupo,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear grupo'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _unirseAGrupo,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Unirse con código'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarGrupos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grupos.length,
        itemBuilder: (context, index) {
          final grupo = _grupos[index];
          return _buildGrupoCard(grupo);
        },
      ),
    );
  }

  Widget _buildGrupoCard(GrupoRutaModel grupo) {
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
                  onTap: () => _copiarCodigo(grupo.codigoInvitacion),
                  child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _abrirDetalleGrupo(grupo),
      ),
    );
  }

  void _copiarCodigo(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $codigo copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _crearGrupo() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearGrupoScreen(),
      ),
    );

    if (resultado == true) {
      _cargarGrupos();
    }
  }

  Future<void> _unirseAGrupo() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const UnirseGrupoScreen(),
      ),
    );

    if (resultado == true) {
      _cargarGrupos();
    }
  }

  void _abrirDetalleGrupo(GrupoRutaModel grupo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleGrupoScreen(grupo: grupo),
      ),
    ).then((_) => _cargarGrupos());
  }
}
