/// Pantalla de Rutas Guardadas
///
/// Muestra las rutas que el usuario ha guardado.
/// Usa RoutesBloc para gestión de estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/routes/routes_bloc.dart';
import '../../blocs/routes/routes_event.dart';
import '../../blocs/routes/routes_state.dart';

class RutasRecomendadasScreen extends StatefulWidget {
  const RutasRecomendadasScreen({super.key});

  @override
  State<RutasRecomendadasScreen> createState() =>
      _RutasRecomendadasScreenState();
}

class _RutasRecomendadasScreenState extends State<RutasRecomendadasScreen> {
  @override
  void initState() {
    super.initState();
    _cargarRutas();
  }

  void _cargarRutas() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<RoutesBloc>().add(
        RoutesFetchSavedRequested(userId: authState.user.id),
      );
    }
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  Future<void> _eliminarRuta(String rutaId, String nombreRuta) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Eliminación"),
          content: Text(
            "¿Estás seguro de que quieres eliminar la ruta '$nombreRuta'?",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmar == true && mounted) {
      context.read<RoutesBloc>().add(RoutesDeleteRequested(routeId: rutaId));
    }
  }

  Future<void> _compartirRutaEnComunidad(Map<String, dynamic> rutaData) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para compartir.")),
        );
      }
      return;
    }

    final TextEditingController mensajeController = TextEditingController();

    final bool? confirmarCompartir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Compartir Ruta: ${rutaData['nombre_ruta'] ?? 'Ruta'}"),
          content: TextField(
            controller: mensajeController,
            decoration: const InputDecoration(
              hintText: "Añade un mensaje (opcional)...",
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Compartir"),
            ),
          ],
        );
      },
    );

    if (confirmarCompartir != true || !mounted) return;

    // TODO: Implementar compartir en comunidad via CommunityBloc cuando esté disponible
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Funcionalidad de compartir pendiente de migración a BLoC",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas Guardadas")),
      body: BlocConsumer<RoutesBloc, RoutesState>(
        listener: (context, state) {
          if (state is RoutesOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Recargar rutas después de eliminar
            if (state.operationType == RoutesOperationType.deleted) {
              _cargarRutas();
            }
          } else if (state is RoutesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoutesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoutesLoaded) {
            final rutas = state.routes;

            if (rutas.isEmpty) {
              return const Center(child: Text("No hay rutas guardadas."));
            }

            return ListView.builder(
              itemCount: rutas.length,
              itemBuilder: (context, index) {
                final ruta = rutas[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(ruta.nombreRuta),
                    subtitle: Text(
                      "Fecha: ${ruta.fecha.toString().split(' ').first}\n"
                      "${ruta.descripcionRuta ?? ''}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: Colors.green[700],
                          ),
                          tooltip: 'Compartir en comunidad',
                          onPressed: () {
                            _compartirRutaEnComunidad(ruta.toJson());
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Eliminar ruta',
                          onPressed:
                              () => _eliminarRuta(ruta.id, ruta.nombreRuta),
                        ),
                        const Icon(Icons.map_outlined),
                      ],
                    ),
                    onTap: () {
                      // Devolvemos la ruta al hacer tap (formato Map para compatibilidad)
                      Navigator.pop(context, ruta.toJson());
                    },
                  ),
                );
              },
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
                    onPressed: _cargarRutas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Estado inicial o cualquier otro
          return const Center(child: Text("No hay rutas guardadas."));
        },
      ),
    );
  }
}
