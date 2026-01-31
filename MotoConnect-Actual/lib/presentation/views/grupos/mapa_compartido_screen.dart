import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/sesion_ruta_activa_model.dart';
import '../../../data/models/grupo_ruta_model.dart';
import '../../../data/models/ubicacion_tiempo_real_model.dart';
import '../../../data/models/navigation_progress.dart';
import '../../../domain/repositories/i_grupo_repository.dart';
import '../../../domain/repositories/i_navigation_repository.dart';
import '../../../data/repositories/navigation_repository.dart';
import '../../../services/location_tracking_service.dart';
import '../../blocs/grupos/grupos_bloc.dart';
import '../../blocs/grupos/grupos_event.dart';
import '../../blocs/grupos/grupos_state.dart';

/// Pantalla de mapa compartido con ubicaciones en tiempo real
///
/// Muestra la ubicación de todos los miembros del grupo en un mapa.
/// Mantiene GoogleMapController en el State local.
/// Usa GruposBloc para suscribirse a ubicaciones y enviar actualizaciones.
class MapaCompartidoScreen extends StatefulWidget {
  final SesionRutaActivaModel sesion;
  final GrupoRutaModel grupo;

  const MapaCompartidoScreen({
    super.key,
    required this.sesion,
    required this.grupo,
  });

  @override
  State<MapaCompartidoScreen> createState() => _MapaCompartidoScreenState();
}

class _MapaCompartidoScreenState extends State<MapaCompartidoScreen> {
  // Controladores de mapa - se mantienen en el State local
  GoogleMapController? _mapController;
  final LocationTrackingService _trackingService = LocationTrackingService();

  // Estado local para UI del mapa
  Map<String, Marker> _markers = {};
  Map<String, NavigationProgress> _navigationProgress = {};
  StreamSubscription? _ubicacionesSubscription;
  StreamSubscription? _navigationProgressSubscription;
  bool _trackingActivo = false;
  bool _centrarEnMi = true;
  String? _miUsuarioId;

  // Repositorios inyectados
  late final IGrupoRepository _grupoRepository;
  late final INavigationRepository _navigationRepository;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener repositorios del contexto
    _grupoRepository = context.read<IGrupoRepository>();
    // NavigationRepository puede no estar inyectado globalmente,
    // así que lo instanciamos directamente
    _navigationRepository = NavigationRepository();
  }

  @override
  void dispose() {
    _ubicacionesSubscription?.cancel();
    _navigationProgressSubscription?.cancel();
    if (_trackingActivo) {
      _trackingService.detenerTracking();
    }
    _trackingService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    try {
      // Obtener ID del usuario actual desde Supabase
      final supabase = Supabase.instance.client;
      _miUsuarioId = supabase.auth.currentUser?.id;

      // Suscribirse a ubicaciones en tiempo real usando BLoC
      context.read<GruposBloc>().add(
        GruposSubscribeToLocations(sesionId: widget.sesion.id),
      );

      // Suscribirse a ubicaciones localmente también para actualizar markers
      _suscribirseAUbicaciones();

      // Suscribirse a progreso de navegación
      _suscribirseAProgresoNavegacion();

      // Iniciar tracking de ubicación propia
      await _iniciarTracking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _suscribirseAProgresoNavegacion() {
    _navigationProgressSubscription = _navigationRepository
        .streamGroupNavigationProgress(widget.sesion.id)
        .listen((progresos) {
          final progressMap = <String, NavigationProgress>{};
          for (final progreso in progresos) {
            progressMap[progreso.userId] = progreso;
          }

          setState(() {
            _navigationProgress = progressMap;
          });
        });
  }

  void _suscribirseAUbicaciones() {
    _ubicacionesSubscription = _grupoRepository
        .suscribirseAUbicaciones(widget.sesion.id)
        .listen((ubicaciones) {
          _actualizarMarcadores(ubicaciones);
        });
  }

  Future<void> _iniciarTracking() async {
    try {
      // Verificar y solicitar permisos
      if (!await _trackingService.tienePermisos()) {
        await _trackingService.solicitarPermisos();
      }

      // Iniciar tracking
      await _trackingService.iniciarTracking(
        sesionId: widget.sesion.id,
        config: TrackingConfig.estandar,
      );

      setState(() {
        _trackingActivo = true;
      });

      // Obtener ubicación inicial y centrar mapa
      final position = await _trackingService.obtenerUbicacionActual();
      _centrarMapa(LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar tracking: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _actualizarMarcadores(List<UbicacionTiempoRealModel> ubicaciones) {
    final nuevosMarkers = <String, Marker>{};

    for (final ubicacion in ubicaciones) {
      final markerId = MarkerId(ubicacion.usuarioId);
      final esMiUbicacion = ubicacion.usuarioId == _miUsuarioId;

      // Color del marcador
      final color =
          esMiUbicacion
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : ubicacion.esReciente
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              );

      // Obtener progreso de navegación si existe
      final progreso = _navigationProgress[ubicacion.usuarioId];

      final marker = Marker(
        markerId: markerId,
        position: ubicacion.posicion,
        icon: color,
        infoWindow: InfoWindow(
          title: ubicacion.nombreMostrar,
          snippet: _buildSnippet(ubicacion, progreso),
        ),
        rotation: ubicacion.direccion ?? 0,
      );

      nuevosMarkers[ubicacion.usuarioId] = marker;

      // Si es mi ubicación y centrar en mí está activo, centrar mapa
      if (esMiUbicacion && _centrarEnMi) {
        _centrarMapa(ubicacion.posicion);
      }
    }

    setState(() {
      _markers = nuevosMarkers;
    });
  }

  String _buildSnippet(
    UbicacionTiempoRealModel ubicacion,
    NavigationProgress? progreso,
  ) {
    final parts = <String>[];

    if (ubicacion.velocidad != null && ubicacion.velocidad! > 0) {
      parts.add('${ubicacion.velocidad!.toStringAsFixed(1)} km/h');
    }

    // Agregar info de navegación si está navegando
    if (progreso != null) {
      parts.add('Paso ${progreso.currentStepIndex + 1}');
      if (progreso.etaSeconds != null) {
        parts.add('ETA: ${progreso.etaText}');
      }
    }

    parts.add(ubicacion.tiempoTranscurrido);

    return parts.join(' • ');
  }

  void _centrarMapa(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GruposBloc, GruposState>(
      listener: (context, state) {
        // Manejar actualizaciones de ubicaciones desde el BLoC si es necesario
        if (state is GruposMapaActivo) {
          _actualizarMarcadores(state.ubicaciones);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sesion.nombreSesion),
              Text(widget.grupo.nombre, style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            if (_trackingActivo)
              const Icon(Icons.circle, color: Colors.green, size: 12),
            IconButton(
              icon: Icon(_centrarEnMi ? Icons.gps_fixed : Icons.gps_not_fixed),
              onPressed: () {
                setState(() {
                  _centrarEnMi = !_centrarEnMi;
                });
              },
              tooltip:
                  _centrarEnMi
                      ? 'Desactivar seguimiento'
                      : 'Activar seguimiento',
            ),
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'pausa',
                      child: Row(
                        children: [
                          Icon(
                            _trackingActivo ? Icons.pause : Icons.play_arrow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _trackingActivo
                                ? 'Pausar tracking'
                                : 'Reanudar tracking',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'finalizar',
                      child: Row(
                        children: [
                          Icon(Icons.stop, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Finalizar sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 15,
              ),
              markers: Set<Marker>.of(_markers.values),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            _buildInfoPanel(),
          ],
        ),
        floatingActionButton:
            _centrarEnMi
                ? null
                : FloatingActionButton(
                  onPressed: () async {
                    final position =
                        await _trackingService.obtenerUbicacionActual();
                    _centrarMapa(LatLng(position.latitude, position.longitude));
                  },
                  child: const Icon(Icons.my_location),
                ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_markers.length} participantes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (widget.sesion.duracion != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 20),
                    const SizedBox(width: 8),
                    Text(_formatDuracion(widget.sesion.duracion!)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    final segundos = duracion.inSeconds % 60;

    if (horas > 0) {
      return '$horas:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  void _onMenuSelected(String value) async {
    switch (value) {
      case 'pausa':
        if (_trackingActivo) {
          _trackingService.pausarTracking();
          setState(() {
            _trackingActivo = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tracking pausado')));
        } else {
          _trackingService.reanudarTracking();
          setState(() {
            _trackingActivo = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tracking reanudado')));
        }
        break;

      case 'finalizar':
        await _finalizarSesion();
        break;
    }
  }

  Future<void> _finalizarSesion() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Finalizar Sesión'),
            content: const Text(
              '¿Estás seguro de que deseas finalizar esta sesión? '
              'Esto detendrá el tracking para todos los participantes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('FINALIZAR'),
              ),
            ],
          ),
    );

    if (confirmacion == true && mounted) {
      try {
        // Cancelar suscripción de ubicaciones via BLoC
        context.read<GruposBloc>().add(const GruposUnsubscribeFromLocations());

        await _grupoRepository.finalizarSesion(widget.sesion.id);
        await _trackingService.detenerTracking();

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al finalizar sesión: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
