/// Pantalla de Navegación Turn-by-Turn
///
/// Pantalla principal de navegación con:
/// - Mapa de Google Maps con polyline
/// - Panel de instrucciones
/// - Controles de navegación
/// - Manejo de estados via NavigationBloc
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../blocs/navigation/navigation_bloc.dart';
import '../../blocs/navigation/navigation_event.dart';
import '../../blocs/navigation/navigation_state.dart';
import '../../widgets/navigation/navigation_panel.dart';
import '../../widgets/navigation/navigation_controls.dart';
import '../../../data/services/navigation/google_directions_service.dart';
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
  StreamSubscription<Position>? _positionSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se requieren permisos de ubicación'),
              ),
            );
          }
          return;
        }
      }

      // Obtener ubicación actual
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // Calcular ruta usando Google Directions
      final directionsService = GoogleDirectionsService(
        apiKey: ApiConstants.googleMapsApiKey,
      );

      final directionsResponse = await directionsService.getDirections(
        origin: origin,
        destination: widget.destination,
      );

      if (!mounted) return;

      // Extraer datos de la respuesta
      final steps = directionsService.extractNavigationSteps(
        directionsResponse,
      );
      final polyline = directionsService.extractCompletePolyline(
        directionsResponse,
      );
      final totalDistance = directionsService.getTotalDistance(
        directionsResponse,
      );
      final totalDuration = directionsService.getTotalDuration(
        directionsResponse,
      );

      // Iniciar navegación en el BLoC
      context.read<NavigationBloc>().add(
        NavigationStarted(
          origin: origin,
          destination: widget.destination,
          destinationName: widget.destinationName,
          sesionGrupalId: widget.sesionGrupalId,
          steps: steps,
          polyline: polyline,
          totalDistanceMeters: totalDistance,
          totalDurationSeconds: totalDuration,
        ),
      );

      // Iniciar stream de ubicación para actualizaciones
      _startLocationUpdates();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al calcular ruta: ${e.toString()}')),
        );
      }
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Actualizar cada 5 metros
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        context.read<NavigationBloc>().add(
          NavigationPositionUpdated(
            currentLocation: LatLng(position.latitude, position.longitude),
            speedKmh: position.speed * 3.6, // m/s a km/h
            heading: position.heading,
          ),
        );
      }
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_mapController == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          17,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          // Manejar llegada al destino
          if (state is NavigationArrival) {
            _showArrivalDialog(state);
          }
          // Manejar errores
          else if (state is NavigationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Manejar navegación detenida
          else if (state is NavigationInitial && _isInitialized) {
            Navigator.pop(context);
          }
          // Manejar recálculo de ruta
          else if (state is NavigationRecalculating) {
            _recalculateRoute(state);
          }
        },
        builder: (context, state) {
          // Estado de carga inicial
          if (state is NavigationLoading || !_isInitialized) {
            return _buildLoadingScreen(
              state is NavigationLoading ? state.message : null,
            );
          }

          // Error sin sesión activa
          if (state is NavigationError && state.previousSession == null) {
            return _buildErrorScreen(state.message);
          }

          // Llegada al destino
          if (state is NavigationArrival) {
            return _buildCompletedScreen(state);
          }

          // Navegación activa
          if (state is NavigationActive) {
            return _buildNavigationUI(state);
          }

          // Navegación pausada
          if (state is NavigationPausedState) {
            return _buildPausedUI(state);
          }

          // Estado inicial o desconocido
          return _buildLoadingScreen(null);
        },
      ),
    );
  }

  Widget _buildNavigationUI(NavigationActive state) {
    return Stack(
      children: [
        // Mapa
        _NavigationMap(
          state: state,
          destination: widget.destination,
          destinationName: widget.destinationName,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        // Panel de instrucciones
        NavigationPanel(
          state: state,
          onCenterLocation: _centerOnCurrentLocation,
          onEndNavigation: () => _showEndNavigationDialog(context),
        ),

        // Controles
        NavigationControls(
          isPaused: false,
          onPauseResume: () {
            context.read<NavigationBloc>().add(const NavigationPaused());
          },
        ),

        // Indicador de off-route
        if (state.isOffRoute) _buildOffRouteIndicator(),

        // Alerta de proximidad a giro
        if (state.isNearNextTurn && state.nextStep != null)
          _buildNearTurnAlert(state),
      ],
    );
  }

  Widget _buildPausedUI(NavigationPausedState state) {
    return Stack(
      children: [
        // Mapa estático
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.lastKnownLocation,
            zoom: 16,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('destination'),
              position: state.session.destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: state.session.completePolyline,
              color: Colors.grey,
              width: 6,
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        // Indicador de pausa
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        // Controles (reanudar)
        NavigationControls(
          isPaused: true,
          onPauseResume: () {
            context.read<NavigationBloc>().add(const NavigationResumed());
          },
        ),

        // Panel inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black87,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => _showEndNavigationDialog(context),
                ),
                const Text(
                  'Pausado',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _centerOnCurrentLocation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffRouteIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Fuera de ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  final state = context.read<NavigationBloc>().state;
                  if (state is NavigationActive) {
                    context.read<NavigationBloc>().add(
                      NavigationRecalculateRequested(
                        currentLocation: state.currentLocation,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Recalcular',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearTurnAlert(NavigationActive state) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 150,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.blue[700],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(state.nextStep!.maneuverIcon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'En ${state.distanceToNextTurnText}: ${state.nextStep!.maneuverDescription}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message ?? 'Calculando ruta...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al iniciar navegación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildCompletedScreen(NavigationArrival state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            '¡Has llegado a tu destino!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Tiempo: ${state.totalDurationText}\nDistancia: ${state.totalDistanceText}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
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

  void _showArrivalDialog(NavigationArrival state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¡Has llegado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text('Tiempo total: ${state.totalDurationText}'),
                Text('Distancia recorrida: ${state.totalDistanceText}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Finalizar'),
              ),
            ],
          ),
    );
  }

  void _showEndNavigationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancelar Navegación'),
            content: const Text('¿Deseas cancelar la navegación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('NO'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<NavigationBloc>().add(const NavigationStopped());
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('SÍ, CANCELAR'),
              ),
            ],
          ),
    );
  }

  Future<void> _recalculateRoute(NavigationRecalculating state) async {
    try {
      final directionsService = GoogleDirectionsService(
        apiKey: ApiConstants.googleMapsApiKey,
      );

      final directionsResponse = await directionsService.getDirections(
        origin: state.currentLocation,
        destination: state.currentSession.destination,
      );

      if (!mounted) return;

      // Extraer datos de la respuesta
      final steps = directionsService.extractNavigationSteps(
        directionsResponse,
      );
      final polyline = directionsService.extractCompletePolyline(
        directionsResponse,
      );
      final totalDistance = directionsService.getTotalDistance(
        directionsResponse,
      );
      final totalDuration = directionsService.getTotalDuration(
        directionsResponse,
      );

      // Reiniciar navegación con nueva ruta
      context.read<NavigationBloc>().add(
        NavigationStarted(
          origin: state.currentLocation,
          destination: state.currentSession.destination,
          destinationName: state.currentSession.destinationName,
          sesionGrupalId: state.currentSession.sesionGrupalId,
          steps: steps,
          polyline: polyline,
          totalDistanceMeters: totalDistance,
          totalDurationSeconds: totalDuration,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al recalcular: ${e.toString()}')),
        );
      }
    }
  }
}

// ========================================
// WIDGET INTERNO DEL MAPA
// ========================================

class _NavigationMap extends StatelessWidget {
  final NavigationActive state;
  final LatLng destination;
  final String? destinationName;
  final void Function(GoogleMapController)? onMapCreated;

  const _NavigationMap({
    required this.state,
    required this.destination,
    this.destinationName,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: state.currentLocation,
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
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: destinationName ?? 'Destino'),
        ),
      },
      polylines: {
        // Polyline de la ruta
        Polyline(
          polylineId: const PolylineId('route'),
          points: state.polyline,
          color: Colors.blue,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      },
    );
  }
}
