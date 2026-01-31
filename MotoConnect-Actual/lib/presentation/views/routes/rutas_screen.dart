import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/routes/routes_bloc.dart';
import '../../blocs/routes/routes_event.dart';
import '../../blocs/routes/routes_state.dart';
import '../navigation/navigation_screen.dart';

class RutasScreen extends StatefulWidget {
  final Map<String, dynamic>? rutaInicial;
  final LatLng? destinoInicial;
  final String? nombreDestino;
  final bool modoSeleccion; // Modo para seleccionar ubicación y retornar

  const RutasScreen({
    super.key,
    this.rutaInicial,
    this.destinoInicial,
    this.nombreDestino,
    this.modoSeleccion = false, // Por defecto en modo normal
  });

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  GoogleMapController? _mapController;
  final LatLng _defaultPosition = const LatLng(7.116816, -73.105240);
  Position? _currentPosition;
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  final TextEditingController _searchController = TextEditingController();
  Marker? _searchedMarker;
  Marker? _userMarker;
  final List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  bool _siguiendoRuta = false;
  StreamSubscription<Position>? _posicionSub;
  final String _googleApiKey =
      "AIzaSyDTFLe8BeQLca2P5ES7vXetX3icv7jiFEE"; // Tu clave API
  // bool _cargando = false; // Descomentar si quieres usar un indicador de carga

  // Variables para modo selección
  LatLng? _ubicacionSeleccionada;
  String? _direccionSeleccionada;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    googlePlace = GooglePlace(_googleApiKey);
    // La lógica para 'rutaInicial' se ha movido a didChangeDependencies
  }

  // <<< NUEVO MÉTODO: didChangeDependencies >>>
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments != null && arguments is Map<String, dynamic>) {
      if (arguments.containsKey('ruta_id_para_cargar')) {
        // <<< NUEVA CONDICIÓN
        final String? rutaId = arguments['ruta_id_para_cargar'] as String?;
        if (rutaId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _cargarYRutaDesdeId(rutaId); // Nueva función para cargar por ID
            }
          });
        }
      } else {
        // Lógica existente para cuando se pasa la ruta completa
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mostrarRutaGuardada(arguments);
          }
        });
      }
    } else if (widget.rutaInicial != null) {
      // Si se pasó por constructor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mostrarRutaGuardada(widget.rutaInicial!);
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _posicionSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _getUserLocation();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _userMarker = Marker(
          markerId: const MarkerId("user"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: "Tu ubicación"),
        );
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );

      // Si hay un destino inicial, trazar la ruta automáticamente
      if (widget.destinoInicial != null) {
        _trazarRutaADestino(widget.destinoInicial!, widget.nombreDestino);
      }
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }

  void _autoCompleteSearch(String value) async {
    if (value.isNotEmpty && _currentPosition != null) {
      var result = await googlePlace.autocomplete.get(
        value,
        location: LatLon(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        radius: 15000, // Radio en metros
      );
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else if (mounted) {
      setState(() {
        predictions = [];
      });
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentPosition == null) return;
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      _googleApiKey,
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
    if (result.points.isNotEmpty && mounted) {
      _polylineCoordinates.clear();
      for (var point in result.points) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 6,
            points: _polylineCoordinates,
          ),
        };
      });
    }
  }

  /// Traza la ruta hacia un destino específico (usado para destino inicial desde eventos)
  Future<void> _trazarRutaADestino(
    LatLng destino,
    String? nombreDestino,
  ) async {
    if (!mounted) return;

    // Crear marcador en el destino
    setState(() {
      _searchedMarker = Marker(
        markerId: const MarkerId("destino_evento"),
        position: destino,
        infoWindow: InfoWindow(title: nombreDestino ?? "Destino"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      if (nombreDestino != null) {
        _searchController.text = nombreDestino;
      }
    });

    // Animar cámara para mostrar el destino
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(destino, 14));

    // Trazar la ruta desde la ubicación actual
    await _getRoute(destino);

    // Ajustar la cámara para mostrar toda la ruta
    if (_polylineCoordinates.isNotEmpty && _mapController != null) {
      final bounds = _calculateBounds(_polylineCoordinates);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100 es padding
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[700],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ruta trazada hacia ${nombreDestino ?? "el destino"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _selectPrediction(AutocompletePrediction prediction) async {
    FocusScope.of(context).unfocus();
    final detail = await googlePlace.details.get(prediction.placeId!);
    if (detail != null &&
        detail.result != null &&
        detail.result!.geometry != null &&
        mounted) {
      final location = detail.result!.geometry!.location!;
      final latLng = LatLng(location.lat!, location.lng!);

      // Si está en modo selección, guardar la ubicación y dirección
      if (widget.modoSeleccion) {
        setState(() {
          _ubicacionSeleccionada = latLng;
          _direccionSeleccionada =
              detail.result!.formattedAddress ??
              detail.result!.name ??
              prediction.description;
          _searchedMarker = Marker(
            markerId: MarkerId(prediction.placeId!),
            position: latLng,
            infoWindow: InfoWindow(title: detail.result!.name),
          );
          predictions = [];
          _searchController.text = detail.result!.name!;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      } else {
        // Modo normal, trazar ruta
        setState(() {
          _searchedMarker = Marker(
            markerId: MarkerId(prediction.placeId!),
            position: latLng,
            infoWindow: InfoWindow(title: detail.result!.name),
          );
          predictions = [];
          _searchController.text = detail.result!.name!;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        await _getRoute(latLng);
      }
    }
  }

  void _limpiarBusqueda() {
    if (mounted) {
      setState(() {
        _searchController.clear();
        predictions.clear();
        _searchedMarker = null;
        _polylines.clear();
        _detenerSeguimiento();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _iniciarSeguimiento() {
    if (_siguiendoRuta) return;
    setState(() {
      _siguiendoRuta = true;
    });
    _posicionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (!mounted) return;
      final pos = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
      setState(() {
        _userMarker = Marker(
          markerId: const MarkerId("user"),
          position: pos,
          infoWindow: const InfoWindow(title: "Tú"),
        );
      });
    });
  }

  void _detenerSeguimiento() {
    _posicionSub?.cancel();
    if (mounted) {
      setState(() {
        _siguiendoRuta = false;
      });
    }
  }

  Future<Map<String, String>?> _mostrarDialogoNombreRuta(
    BuildContext context,
  ) async {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Guardar Ruta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Nombre*",
                  hintText: "Dale un nombre a tu ruta",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: "Descripción (Opcional)",
                  hintText: "Añade detalles si quieres...",
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                final nombre = nombreController.text.trim();
                final descripcion = descripcionController.text.trim();
                if (nombre.isNotEmpty) {
                  Navigator.pop(context, {
                    'nombre': nombre,
                    'descripcion': descripcion,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("El nombre no puede estar vacío."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _guardarRutaActual() async {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay ruta activa para guardar.")),
      );
      return;
    }

    // Obtener userId desde AuthBloc
    final authState = context.read<AuthBloc>().state;
    String? uid;
    if (authState is AuthAuthenticated) {
      uid = authState.user.id;
    }

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes iniciar sesión para guardar rutas."),
        ),
      );
      return;
    }

    final Map<String, String>? rutaInfo = await _mostrarDialogoNombreRuta(
      context,
    );

    if (rutaInfo != null) {
      final String nombreRuta = rutaInfo['nombre']!;
      final String? descripcionRuta = rutaInfo['descripcion'];

      // Usar RoutesBloc para guardar la ruta
      if (mounted) {
        context.read<RoutesBloc>().add(
          RoutesCreateRequested(
            userId: uid,
            nombreRuta: nombreRuta,
            descripcionRuta:
                descripcionRuta?.isNotEmpty == true ? descripcionRuta : null,
            puntos: List<LatLng>.from(_polylineCoordinates),
            distanciaKm: 0.0, // Considera calcular esto si es necesario
            duracionMinutos: 0, // Considera calcular esto si es necesario
          ),
        );
      }
    } else {
      debugPrint("Guardado cancelado por el usuario.");
    }
  }

  /// Inicia navegación turn-by-turn
  void _iniciarNavegacion() {
    if (_searchedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay destino seleccionado.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NavigationScreen(
              destination: _searchedMarker!.position,
              destinationName:
                  _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
            ),
      ),
    );
  }

  void _mostrarRutaGuardada(Map<String, dynamic> ruta) {
    final List<dynamic>? puntos = ruta['puntos']; // Los puntos vienen como JSON
    if (puntos == null || puntos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Esta ruta no tiene puntos para mostrar."),
          ),
        );
      }
      return;
    }

    _limpiarBusqueda(); // Limpiamos cualquier búsqueda/ruta anterior

    _polylineCoordinates.clear();
    try {
      // Convertimos los puntos JSON a LatLng
      for (var punto in puntos) {
        // Asegúrate de que 'lat' y 'lng' existan y sean double
        if (punto is Map &&
            punto.containsKey('lat') &&
            punto.containsKey('lng')) {
          final lat = punto['lat'];
          final lng = punto['lng'];
          if (lat is double && lng is double) {
            _polylineCoordinates.add(LatLng(lat, lng));
          } else {
            // Podrías convertir si son num, int, o String numérico
            _polylineCoordinates.add(
              LatLng((lat as num).toDouble(), (lng as num).toDouble()),
            );
          }
        } else {
          print("Formato de punto inválido: $punto");
        }
      }

      if (mounted) {
        if (_polylineCoordinates.isEmpty && puntos.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudieron procesar los puntos de la ruta."),
            ),
          );
          return;
        }
        setState(() {
          _polylines = {
            Polyline(
              polylineId: PolylineId(
                "ruta_guardada_${ruta['id'] ?? DateTime.now().millisecondsSinceEpoch}",
              ), // ID único
              color: Colors.purple, // Un color diferente para distinguirla
              width: 6,
              points: _polylineCoordinates,
            ),
          };

          // Crear marcador en el destino (último punto) para habilitar navegación
          if (_polylineCoordinates.isNotEmpty) {
            final destino = _polylineCoordinates.last;
            _searchedMarker = Marker(
              markerId: const MarkerId("destino_ruta_guardada"),
              position: destino,
              infoWindow: InfoWindow(title: ruta['nombre_ruta'] ?? 'Destino'),
            );
            // Actualizar el texto de búsqueda con el nombre de la ruta
            _searchController.text = ruta['nombre_ruta'] ?? 'Ruta guardada';
          }
        });

        // Opcional: Centrar el mapa en la ruta
        if (_polylineCoordinates.isNotEmpty && _mapController != null) {
          LatLngBounds bounds;
          if (_polylineCoordinates.length == 1) {
            bounds = LatLngBounds(
              southwest: _polylineCoordinates.first,
              northeast: _polylineCoordinates.first,
            );
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_polylineCoordinates.first, 15),
            ); // Zoom a un solo punto
          } else {
            bounds = _calculateBounds(_polylineCoordinates);
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            ); // 50 es padding
          }
        }

        // Mostrar mensaje estético con la ruta seleccionada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[700],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ruta['nombre_ruta'] ?? 'Ruta guardada',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ruta['descripcion_ruta'] != null &&
                            ruta['descripcion_ruta'].toString().isNotEmpty)
                          Text(
                            ruta['descripcion_ruta'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
                ],
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Error al parsear o mostrar la ruta guardada: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al mostrar la ruta guardada.")),
        );
      }
    }
  }

  // <<< NUEVA FUNCIÓN en _RutasScreenState >>>
  Future<void> _cargarYRutaDesdeId(String rutaId) async {
    if (!mounted) return;
    // Aquí podrías mostrar un indicador de carga si lo deseas
    // setState(() => _cargando = true);

    try {
      final respuestaRuta =
          await Supabase.instance.client
              .from('rutas_realizadas')
              .select(
                'puntos, nombre_ruta, id',
              ) // Obtén los puntos y otros datos que necesites
              .eq('id', rutaId)
              .single(); // single() arrojará error si no hay exactamente un resultado o más de uno.

      // Asegúrate de que respuestaRuta no sea null y tenga los campos esperados
      if (mounted) {
        // Verificar mounted antes de llamar a _mostrarRutaGuardada
        _mostrarRutaGuardada(respuestaRuta);
      }
    } catch (e) {
      print("Error al cargar ruta por ID $rutaId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No se pudo cargar la ruta seleccionada: ${e.toString()}",
            ),
          ),
        );
      }
    } finally {
      // if (mounted) setState(() => _cargando = false);
    }
  }

  // Helper para calcular bounds para la cámara
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoutesBloc, RoutesState>(
      listener: (context, state) {
        if (state is RoutesOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is RoutesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Mapa de Rutas")),
        body: SafeArea(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _defaultPosition,
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // _getUserLocation(); // getUserLocation se llama en _checkPermission y a veces en onMapCreated.
                  // Si se maneja por didChangeDependencies, quizás no necesites llamarlo aquí de nuevo
                  // a menos que sea un fallback. Por ahora, lo dejo ya que estaba
                  // pero ten en cuenta que la ubicación y ruta podrían cargarse/actualizarse
                  // por didChangeDependencies
                },
                myLocationEnabled:
                    true, // Esto ya muestra un punto azul, considera si _userMarker es siempre necesario
                myLocationButtonEnabled: true,
                markers: {
                  if (_userMarker != null)
                    _userMarker!, // Podrías querer ocultar tu marcador si myLocationEnabled es true
                  if (_searchedMarker != null) _searchedMarker!,
                },
                polylines: _polylines,
                padding: const EdgeInsets.only(
                  top: 80, // Espacio para la barra de búsqueda
                  bottom:
                      100, // Espacio para botones inferiores y navegación del sistema
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _limpiarBusqueda,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              onChanged: _autoCompleteSearch,
                              decoration: const InputDecoration(
                                hintText: "Buscar ubicación...",
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (predictions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: predictions.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.black,
                              ),
                              title: Text(
                                predictions[index].description ?? "",
                                style: const TextStyle(color: Colors.black),
                              ),
                              onTap:
                                  () => _selectPrediction(predictions[index]),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              // Botón "Rutas guardadas" - Siempre visible
              Positioned(
                bottom: 20,
                left: 20,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.route),
                  label: const Text("Rutas guardadas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final resultado = await Navigator.pushNamed(
                      context,
                      '/rutas-recomendadas',
                    );
                    if (resultado != null &&
                        resultado is Map<String, dynamic>) {
                      if (mounted && resultado.containsKey('puntos')) {
                        _mostrarRutaGuardada(resultado);
                      } else if (mounted &&
                          resultado.containsKey('ruta_id_para_cargar')) {
                        final String? rutaId =
                            resultado['ruta_id_para_cargar'] as String?;
                        if (rutaId != null) {
                          _cargarYRutaDesdeId(rutaId);
                        }
                      }
                    }
                  },
                ),
              ),

              // Botón "Guardar ruta" - Solo visible cuando hay ruta
              if (_polylines.isNotEmpty)
                Positioned(
                  bottom: 70,
                  left: 20,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar ruta"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _guardarRutaActual,
                  ),
                ),

              // Botón "Iniciar Navegación" - Solo visible cuando hay ruta y destino
              if (_polylines.isNotEmpty && _searchedMarker != null)
                Positioned(
                  bottom: 120,
                  left: 20,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text("Iniciar Navegación"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _iniciarNavegacion,
                  ),
                ),
              // if (_cargando) // Descomentar si usas un indicador de carga
              //   const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        // Botón flotante para confirmar selección (solo en modo selección)
        floatingActionButton:
            widget.modoSeleccion && _ubicacionSeleccionada != null
                ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pop(context, {
                      'latitud': _ubicacionSeleccionada!.latitude,
                      'longitud': _ubicacionSeleccionada!.longitude,
                      'direccion': _direccionSeleccionada ?? '',
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Ubicación'),
                )
                : null,
      ),
    );
  }
}
