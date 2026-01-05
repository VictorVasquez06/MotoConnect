/// Pantalla de Navegación Turn-by-Turn
///
/// Pantalla principal de navegación con:
/// - Mapa de Google Maps con polyline
/// - Panel de instrucciones
/// - Controles de navegación
/// - Manejo de estados (loading, error, navegando)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../viewmodels/navigation/navigation_viewmodel.dart';
import '../../widgets/navigation/navigation_panel.dart';
import '../../widgets/navigation/navigation_controls.dart';
import '../../../data/models/navigation_session.dart';
import '../../../domain/usecases/navigation/start_navigation_usecase.dart';
import '../../../domain/usecases/navigation/update_navigation_progress_usecase.dart';
import '../../../domain/usecases/navigation/pause_navigation_usecase.dart';
import '../../../domain/usecases/navigation/resume_navigation_usecase.dart';
import '../../../domain/usecases/navigation/end_navigation_usecase.dart';
import '../../../domain/usecases/navigation/recalculate_route_usecase.dart';
import '../../../data/services/navigation/google_directions_service.dart';
import '../../../data/services/navigation/navigation_tracking_service.dart';
import '../../../data/repositories/navigation_repository.dart';
import '../../../services/location_tracking_service.dart';
import '../../../core/constants/api_constants.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String? destinationName;
  final String? sesionGrupalId;

  const NavigationScreen({
    super.key,
    required this.destination,
    this.destinationName,
    this.sesionGrupalId,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  LocationTrackingService? _locationService;

  Future<void> _centerOnCurrentLocation() async {
    if (_mapController == null || _locationService == null) return;

    try {
      final position = await _locationService!.obtenerUbicacionActual();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          17,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        // Crear dependencias
        final directionsService = GoogleDirectionsService(
          apiKey: ApiConstants.googleMapsApiKey,
        );
        final trackingService = NavigationTrackingService();
        final navigationRepository = NavigationRepository();
        final locationService = LocationTrackingService();

        // Guardar referencia al location service para usar en el botón de centrar
        _locationService = locationService;

        // Crear UseCases
        final startNavigationUseCase = StartNavigationUseCase(
          directionsService: directionsService,
          navigationRepository: navigationRepository,
          locationService: locationService,
        );

        final updateProgressUseCase = UpdateNavigationProgressUseCase(
          trackingService: trackingService,
          navigationRepository: navigationRepository,
        );

        final pauseNavigationUseCase = PauseNavigationUseCase(
          repository: navigationRepository,
          locationService: locationService,
        );

        final resumeNavigationUseCase = ResumeNavigationUseCase(
          repository: navigationRepository,
          locationService: locationService,
        );

        final endNavigationUseCase = EndNavigationUseCase(
          repository: navigationRepository,
          locationService: locationService,
        );

        final recalculateRouteUseCase = RecalculateRouteUseCase(
          directionsService: directionsService,
          locationService: locationService,
        );

        // Crear ViewModel
        final viewModel = NavigationViewModel(
          startNavigationUseCase: startNavigationUseCase,
          updateProgressUseCase: updateProgressUseCase,
          pauseNavigationUseCase: pauseNavigationUseCase,
          resumeNavigationUseCase: resumeNavigationUseCase,
          endNavigationUseCase: endNavigationUseCase,
          recalculateRouteUseCase: recalculateRouteUseCase,
          locationService: locationService,
        );

        // Iniciar navegación automáticamente
        viewModel.startNavigation(
          destination: widget.destination,
          destinationName: widget.destinationName,
          sesionGrupalId: widget.sesionGrupalId,
        );

        return viewModel;
      },
      child: Scaffold(
        body: Consumer<NavigationViewModel>(
          builder: (context, vm, _) {
            // Mostrar estado de carga
            if (vm.isCalculating && vm.currentSession == null) {
              return _buildLoadingScreen();
            }

            // Mostrar error
            if (vm.errorMessage != null && vm.currentSession == null) {
              return _buildErrorScreen(vm.errorMessage!);
            }

            // Mostrar pantalla de navegación completada
            if (vm.isCompleted) {
              return _buildCompletedScreen();
            }

            // Mostrar mapa con navegación
            return Stack(
              children: [
                _NavigationMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                NavigationPanel(
                  onCenterLocation: _centerOnCurrentLocation,
                ),
                const NavigationControls(),

                // Indicador de estado pausado
                if (vm.isPaused)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Navegación pausada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Calculando ruta...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al iniciar navegación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Has llegado a tu destino!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}

// ========================================
// WIDGET INTERNO DEL MAPA
// ========================================

class _NavigationMap extends StatelessWidget {
  final void Function(GoogleMapController)? onMapCreated;

  const _NavigationMap({this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, vm, _) {
        if (vm.currentSession == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final session = vm.currentSession!;

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: session.origin,
            zoom: 16,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: onMapCreated,
          markers: {
            // Marcador de destino
            Marker(
              markerId: const MarkerId('destination'),
              position: session.destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: session.destinationName ?? 'Destino',
              ),
            ),
          },
          polylines: {
            // Polyline de la ruta
            Polyline(
              polylineId: const PolylineId('route'),
              points: session.completePolyline,
              color: Colors.blue,
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          },
        );
      },
    );
  }
}
