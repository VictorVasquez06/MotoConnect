import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/route_model.dart';
import '../../viewmodels/routes/saved_routes_viewmodel.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedRoutesViewModel>().loadRouteDetail(widget.routeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SavedRoutesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final route = viewModel.selectedRoute;
          if (route == null) {
            return const Center(child: Text('Ruta no encontrada'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(route),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRouteStats(route),
                      const SizedBox(height: 24),
                      _buildDescription(route),
                      const SizedBox(height: 24),
                      _buildRouteInfo(route),
                      const SizedBox(height: 24),
                      _buildMapPreview(route),
                      const SizedBox(height: 24),
                      _buildWaypoints(route),
                      const SizedBox(height: 24),
                      _buildCreatorInfo(route),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildAppBar(RouteModel route) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          route.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.route, size: 80, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStats(RouteModel route) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.straighten,
              '${route.distance.toStringAsFixed(1)} km',
              'Distancia',
            ),
            _buildStatItem(
              Icons.timer,
              _formatDuration(route.estimatedDuration),
              'Duración',
            ),
            _buildStatItem(
              Icons.terrain,
              route.difficulty ?? 'Media',
              'Dificultad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDescription(RouteModel route) {
    if (route.description == null || route.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          route.description!,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(RouteModel route) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la ruta',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, 'Inicio', route.startPoint),
            const Divider(height: 24),
            _buildInfoRow(Icons.flag, 'Destino', route.endPoint),
            if (route.roadType != null) ...[
              const Divider(height: 24),
              _buildInfoRow(Icons.road, 'Tipo de vía', route.roadType!),
            ],
            if (route.scenicValue != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.landscape,
                'Valor paisajístico',
                _getSceneryRating(route.scenicValue!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(RouteModel route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mapa de la ruta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Abrir mapa completo
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('Ver completo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Mapa interactivo',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaypoints(RouteModel route) {
    if (route.waypoints == null || route.waypoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puntos de interés',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: route.waypoints!.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final waypoint = route.waypoints![index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  waypoint.name ?? 'Punto ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    waypoint.description != null
                        ? Text(waypoint.description!)
                        : null,
                trailing: const Icon(Icons.location_on),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreatorInfo(RouteModel route) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            route.creatorName?[0].toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          route.creatorName ?? 'Usuario',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Creada el ${_formatDate(route.createdAt)}'),
        trailing: IconButton(
          onPressed: () {
            // TODO: Ver perfil del creador
          },
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Consumer<SavedRoutesViewModel>(
      builder: (context, viewModel, child) {
        final route = viewModel.selectedRoute;
        if (route == null) return const SizedBox.shrink();

        final isSaved = route.isSaved ?? false;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (isSaved) {
                      viewModel.unsaveRoute(route.id);
                    } else {
                      viewModel.saveRoute(route.id);
                    }
                  },
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Iniciar navegación
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text(
                      'Iniciar navegación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // TODO: Compartir ruta
                  },
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
  }

  String _getSceneryRating(int value) {
    if (value >= 4) return '⭐⭐⭐⭐⭐ Excepcional';
    if (value >= 3) return '⭐⭐⭐⭐ Muy bueno';
    if (value >= 2) return '⭐⭐⭐ Bueno';
    return '⭐⭐ Regular';
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
