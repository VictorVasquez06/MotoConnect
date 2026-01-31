/// Panel de Navegación Turn-by-Turn - Estilo Google Maps
///
/// Diseño minimalista con:
/// - Panel superior compacto: instrucción actual + siguiente paso
/// - Panel inferior: tiempo, distancia, hora de llegada
///
/// Usa datos del NavigationActive state en lugar de ViewModel.
library;

import 'package:flutter/material.dart';
import '../../blocs/navigation/navigation_state.dart';

class NavigationPanel extends StatelessWidget {
  final NavigationActive state;
  final Future<void> Function()? onCenterLocation;
  final VoidCallback? onEndNavigation;

  const NavigationPanel({
    super.key,
    required this.state,
    this.onCenterLocation,
    this.onEndNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Panel superior compacto con instrucciones
        _buildTopPanel(context),

        // Panel inferior con tiempo y distancia
        _buildBottomPanel(context),
      ],
    );
  }

  Widget _buildTopPanel(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 80,
      child: Card(
        color: Colors.teal[700],
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    state.currentManeuverIcon,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distancia al siguiente giro
                        Text(
                          state.distanceToNextTurnText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.currentInstruction,
                          style: const TextStyle(
                            fontSize: 14,
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
              if (state.nextStep != null) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.white24),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      state.nextStep!.maneuverIcon,
                      size: 20,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Luego: ${state.nextStep!.maneuverDescription}',
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

  Widget _buildBottomPanel(BuildContext context) {
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
              onPressed: onEndNavigation,
              tooltip: 'Cancelar navegación',
            ),

            // Información central: tiempo y distancia
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiempo estimado (grande)
                  Text(
                    state.timeRemainingText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Distancia y hora de llegada
                  Text(
                    '${state.distanceRemainingText} • Llegada: ${state.etaText}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Botón centrar
            IconButton(
              icon: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onCenterLocation,
              tooltip: 'Centrar en mi ubicación',
            ),
          ],
        ),
      ),
    );
  }
}
