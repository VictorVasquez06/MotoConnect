/// Controles de Navegación - Estilo Google Maps
///
/// Botones laterales para:
/// - Pausar/Reanudar navegación
/// - Recalcular ruta
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation/navigation_viewmodel.dart';

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, vm, _) {
        return Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 120,
          child: _buildControlButton(
            icon: vm.isPaused ? Icons.play_arrow : Icons.pause,
            color: vm.isPaused ? Colors.green : Colors.orange,
            onPressed: () {
              if (vm.isPaused) {
                vm.resumeNavigation();
              } else {
                vm.pauseNavigation();
              }
            },
            tooltip: vm.isPaused ? 'Reanudar' : 'Pausar',
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, color: color, size: 24),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
