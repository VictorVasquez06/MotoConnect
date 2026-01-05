/// Panel de Navegación Turn-by-Turn - Estilo Google Maps
///
/// Diseño minimalista con:
/// - Panel superior compacto: instrucción actual + siguiente paso
/// - Panel inferior: tiempo, distancia, hora de llegada
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation/navigation_viewmodel.dart';

class NavigationPanel extends StatelessWidget {
  final Future<void> Function()? onCenterLocation;

  const NavigationPanel({
    super.key,
    this.onCenterLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, vm, _) {
        if (vm.currentStep == null) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Panel superior compacto con instrucciones
            _buildTopPanel(context, vm),

            // Panel inferior con tiempo y distancia
            _buildBottomPanel(context, vm),
          ],
        );
      },
    );
  }

  Widget _buildTopPanel(BuildContext context, NavigationViewModel vm) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 80,
      child: Card(
        color: Colors.teal[700],
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instrucción actual
              Row(
                children: [
                  Icon(
                    vm.currentStep!.maneuverIcon,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.currentStep!.instruction,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Siguiente paso
              if (vm.nextStep != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      vm.nextStep!.maneuverIcon,
                      size: 20,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Luego ${vm.nextStep!.instruction}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, NavigationViewModel vm) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón cerrar/cancelar
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => _showEndNavigationDialog(context, vm),
              tooltip: 'Cancelar navegación',
            ),

            // Información central: tiempo y distancia
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiempo estimado (grande)
                  Text(
                    vm.currentSession?.remainingDurationText ?? '--',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Distancia y hora de llegada
                  Text(
                    '${vm.currentSession?.remainingDistanceText ?? '--'} • ${vm.etaFormatted ?? '--:--'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Botón centrar
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white, size: 28),
              onPressed: onCenterLocation,
              tooltip: 'Centrar en mi ubicación',
            ),
          ],
        ),
      ),
    );
  }

  void _showEndNavigationDialog(
    BuildContext context,
    NavigationViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Navegación'),
        content: const Text('¿Deseas cancelar la navegación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () async {
              await vm.endNavigation(completed: false);
              if (context.mounted) {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a pantalla anterior
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SÍ, CANCELAR'),
          ),
        ],
      ),
    );
  }
}
