/// Pantalla de Detalles de Ruta
///
/// Muestra información detallada de una ruta específica.
/// Usa RoutesBloc para gestión de estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/route_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/routes/routes_bloc.dart';
import '../../blocs/routes/routes_event.dart';
import '../../blocs/routes/routes_state.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutesBloc>().add(
        RoutesLoadDetailsRequested(routeId: widget.routeId),
      );
    });
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
    return Scaffold(
      body: BlocConsumer<RoutesBloc, RoutesState>(
        listener: (context, state) {
          if (state is RoutesOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (state.operationType == RoutesOperationType.savedToFavorites) {
              setState(() => _isSaved = true);
            } else if (state.operationType ==
                RoutesOperationType.removedFromFavorites) {
              setState(() => _isSaved = false);
            }
          } else if (state is RoutesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RoutesDetailLoaded) {
            setState(() {
              _isSaved = state.isSavedByUser;
            });
          }
        },
        builder: (context, state) {
          if (state is RoutesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoutesDetailLoaded) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(state.route),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRouteStats(state.route),
                        const SizedBox(height: 24),
                        _buildDescription(state.route),
                        const SizedBox(height: 24),
                        _buildRouteInfo(state.route),
                        const SizedBox(height: 24),
                        _buildMapPreview(state.route),
                        const SizedBox(height: 24),
                        _buildWaypoints(state.route),
                        const SizedBox(height: 24),
                        _buildCreatorInfo(state.route),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is RoutesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<RoutesBloc>().add(
                        RoutesLoadDetailsRequested(routeId: widget.routeId),
                      );
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Ruta no encontrada'));
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
          route.nombreRuta,
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
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
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
    final distance = route.distanciaKm ?? 0;
    final duration = route.duracionMinutos ?? 0;
    const difficulty = 'Media'; // TODO: Add difficulty to RouteModel

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.straighten,
              '${distance.toStringAsFixed(1)} km',
              'Distancia',
            ),
            _buildStatItem(Icons.timer, _formatDuration(duration), 'Duración'),
            _buildStatItem(Icons.terrain, difficulty, 'Dificultad'),
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
    final description = route.descripcionRuta;

    if (description == null || description.isEmpty) {
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
        Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
      ],
    );
  }

  Widget _buildRouteInfo(RouteModel route) {
    final startPoint = route.startPoint ?? 'No especificado';
    final endPoint = route.endPoint ?? 'No especificado';
    final roadType = route.roadType;
    final scenicValue = route.scenicValue;

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
            _buildInfoRow(Icons.location_on, 'Inicio', startPoint),
            const Divider(height: 24),
            _buildInfoRow(Icons.flag, 'Destino', endPoint),
            if (roadType != null) ...[
              const Divider(height: 24),
              _buildInfoRow(Icons.route, 'Tipo de vía', roadType),
            ],
            if (scenicValue != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.landscape,
                'Valor paisajístico',
                _getSceneryRating(scenicValue),
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
                // TODO: Abrir mapa completo con la ruta
                Navigator.pushNamed(
                  context,
                  '/rutas',
                  arguments: route.toJson(),
                );
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
                  '${route.puntos.length} puntos en la ruta',
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
    final waypoints = route.waypoints;

    if (waypoints == null || waypoints.isEmpty) {
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
          itemCount: waypoints.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final waypoint = waypoints[index];
            final name = waypoint['nombre'] as String? ?? 'Punto ${index + 1}';
            final description = waypoint['descripcion'] as String?;

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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: description != null ? Text(description) : null,
                trailing: const Icon(Icons.location_on),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreatorInfo(RouteModel route) {
    final creatorName = route.creatorName ?? 'Usuario';
    final createdAt = route.fecha;

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          creatorName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Creada el ${_formatDate(createdAt)}'),
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
    return BlocBuilder<RoutesBloc, RoutesState>(
      builder: (context, state) {
        if (state is! RoutesDetailLoaded) {
          return const SizedBox.shrink();
        }

        final route = state.route;
        final userId = _getCurrentUserId();
        final isLoading = context.read<RoutesBloc>().state is RoutesLoading;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      isLoading || userId == null
                          ? null
                          : () {
                            if (_isSaved) {
                              context.read<RoutesBloc>().add(
                                RoutesRemoveFromFavoritesRequested(
                                  routeId: route.id,
                                  userId: userId,
                                ),
                              );
                            } else {
                              context.read<RoutesBloc>().add(
                                RoutesSaveToFavoritesRequested(
                                  routeId: route.id,
                                  userId: userId,
                                ),
                              );
                            }
                          },
                  icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Iniciar navegación - navegar a la pantalla de rutas con esta ruta
                      Navigator.pushNamed(
                        context,
                        '/rutas',
                        arguments: route.toJson(),
                      );
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
