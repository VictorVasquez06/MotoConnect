/// Controles de Navegación - Estilo Google Maps
///
/// Botón lateral para:
/// - Pausar/Reanudar navegación
///
/// Recibe estado y callback como parámetros en lugar de usar ViewModel.
library;

import 'package:flutter/material.dart';

class NavigationControls extends StatelessWidget {
  final bool isPaused;
  final VoidCallback? onPauseResume;

  const NavigationControls({
    super.key,
    required this.isPaused,
    this.onPauseResume,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 120,
      child: _buildControlButton(
        icon: isPaused ? Icons.play_arrow : Icons.pause,
        color: isPaused ? Colors.green : Colors.orange,
        onPressed: onPauseResume,
        tooltip: isPaused ? 'Reanudar' : 'Pausar',
      ),
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
        icon:
            isLoading
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
