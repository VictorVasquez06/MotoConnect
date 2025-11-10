/// ViewModel para RoutesScreen (RutasScreen)
///
/// Responsabilidades:
/// - Gestionar el estado del mapa de Google Maps
/// - Manejar la búsqueda de lugares con Google Place
/// - Calcular y mostrar rutas entre ubicaciones
/// - Gestionar la ubicación del usuario en tiempo real
/// - Guardar rutas realizadas
/// - Cargar y mostrar rutas guardadas
/// - Gestionar el seguimiento de ruta
///
/// Patrón MVVM: Separa la lógica compleja de Google Maps de la UI
library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Estados posibles de la pantalla de rutas
enum RoutesStatus {
  initial,
  loadingLocation,
  locationLoaded,
  searchingPlaces,
  calculatingRoute,
  routeCalculated,
  savingRoute,
  routeSaved,
  loadingRoute,
  routeLoaded,
  error,
}

class RoutesViewModel extends ChangeNotifier {
  // ========================================
  // CONFIGURACIÓN
  // ========================================

  /// API Key de Google Maps
  final String googleApiKey;

  /// Posición por defecto (Bucaramanga)
  final LatLng defaultPosition = const LatLng(7.116816, -73.105240);

  // ========================================
  // CLIENTES Y SERVICIOS
  // ========================================

  final SupabaseClient _supabase = Supabase.instance.client;
  late GooglePlace _googlePlace;

  // ========================================
  // CONTROLADORES
  // ========================================

  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  StreamSubscription<Position>? posicionSubscription;

  // ========================================
  // ESTADO DEL MAPA
  // ========================================

  /// Estado actual
  RoutesStatus _status = RoutesStatus.initial;
  RoutesStatus get status => _status;

  /// Posición actual del usuario
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Marcador del usuario
  Marker? _userMarker;
  Marker? get userMarker => _userMarker;

  /// Marcador del lugar buscado
  Marker? _searchedMarker;
  Marker? get searchedMarker => _searchedMarker;

  /// Set de marcadores (combinación de user y searched)
  Set<Marker> get markers {
    final Set<Marker> allMarkers = {};
    if (_userMarker != null) allMarkers.add(_userMarker!);
    if (_searchedMarker != null) allMarkers.add(_searchedMarker!);
    return allMarkers;
  }

  /// Coordenadas de la polyline (ruta)
  final List<LatLng> _polylineCoordinates = [];
  List<LatLng> get polylineCoordinates => _polylineCoordinates;

  /// Set de polylines
  Set<Polyline> _polylines = {};
  Set<Polyline> get polylines => _polylines;

  /// Indica si se está siguiendo la ruta
  bool _siguiendoRuta = false;
  bool get siguiendoRuta => _siguiendoRuta;

  // ========================================
  // BÚSQUEDA
  // ========================================

  /// Predicciones de búsqueda de Google Place
  List<AutocompletePrediction> _predictions = [];
  List<AutocompletePrediction> get predictions => _predictions;

  /// Mensaje de error si existe
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========================================
  // CONSTRUCTOR
  // ========================================

  RoutesViewModel({required this.googleApiKey}) {
    _googlePlace = GooglePlace(googleApiKey);
  }

  // ========================================
  // MÉTODOS PÚBLICOS - INICIALIZACIÓN
  // ========================================

  /// Inicializa el ViewModel
  Future<void> initialize() async {
    await getUserLocation();
  }

  /// Callback cuando el mapa es creado
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    notifyListeners();
  }

  // ========================================
  // MÉTODOS PÚBLICOS - UBICACIÓN
  // ========================================

  /// Obtiene la ubicación actual del usuario
  Future<void> getUserLocation() async {
    _status = RoutesStatus.loadingLocation;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      _userMarker = Marker(
        markerId: const MarkerId("user"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: "Tu ubicación"),
      );

      // Animar cámara a la posición del usuario
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }

      _status = RoutesStatus.locationLoaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error obteniendo ubicación: ${e.toString()}';
      _status = RoutesStatus.error;
      debugPrint('Error en getUserLocation: $e');
    }

    notifyListeners();
  }

  // ========================================
  // MÉTODOS PÚBLICOS - BÚSQUEDA
  // ========================================

  /// Realiza autocompletado de búsqueda de lugares
  Future<void> autoCompleteSearch(String value) async {
    if (value.isEmpty) {
      _predictions = [];
      notifyListeners();
      return;
    }

    if (_currentPosition == null) {
      _errorMessage = 'Esperando ubicación del usuario';
      notifyListeners();
      return;
    }

    _status = RoutesStatus.searchingPlaces;
    notifyListeners();

    try {
      var result = await _googlePlace.autocomplete.get(
        value,
        location: LatLon(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        radius: 15000, // Radio en metros
      );

      if (result != null && result.predictions != null) {
        _predictions = result.predictions!;
      } else {
        _predictions = [];
      }

      _status = RoutesStatus.locationLoaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error en la búsqueda: ${e.toString()}';
      _predictions = [];
      debugPrint('Error en autoCompleteSearch: $e');
    }

    notifyListeners();
  }

  /// Selecciona una predicción de búsqueda
  Future<void> selectPrediction(AutocompletePrediction prediction) async {
    if (prediction.placeId == null) return;

    try {
      final detail = await _googlePlace.details.get(prediction.placeId!);

      if (detail != null &&
          detail.result != null &&
          detail.result!.geometry != null) {
        final location = detail.result!.geometry!.location!;
        final latLng = LatLng(location.lat!, location.lng!);

        _searchedMarker = Marker(
          markerId: MarkerId(prediction.placeId!),
          position: latLng,
          infoWindow: InfoWindow(title: detail.result!.name),
        );

        _predictions = [];
        searchController.text = detail.result!.name ?? '';

        // Animar cámara al lugar seleccionado
        if (mapController != null) {
          mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        }

        // Calcular ruta al destino
        await getRoute(latLng);

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al obtener detalles del lugar: ${e.toString()}';
      debugPrint('Error en selectPrediction: $e');
      notifyListeners();
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - RUTAS
  // ========================================

  /// Calcula la ruta entre la ubicación actual y un destino
  Future<void> getRoute(LatLng destination) async {
    if (_currentPosition == null) {
      _errorMessage = 'No se ha obtenido tu ubicación';
      notifyListeners();
      return;
    }

    _status = RoutesStatus.calculatingRoute;
    notifyListeners();

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        PointLatLng(destination.latitude, destination.longitude),
      );

      if (result.points.isNotEmpty) {
        _polylineCoordinates.clear();
        for (var point in result.points) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 6,
            points: _polylineCoordinates,
          ),
        };

        _status = RoutesStatus.routeCalculated;
        _errorMessage = null;
      } else {
        _errorMessage = 'No se pudo calcular la ruta';
        _status = RoutesStatus.error;
      }
    } catch (e) {
      _errorMessage = 'Error calculando ruta: ${e.toString()}';
      _status = RoutesStatus.error;
      debugPrint('Error en getRoute: $e');
    }

    notifyListeners();
  }

  /// Limpia la búsqueda y la ruta actual
  void limpiarBusqueda() {
    searchController.clear();
    _predictions.clear();
    _searchedMarker = null;
    _polylines.clear();
    detenerSeguimiento();
    _status = RoutesStatus.locationLoaded;
    notifyListeners();
  }

  // ========================================
  // MÉTODOS PÚBLICOS - SEGUIMIENTO
  // ========================================

  /// Inicia el seguimiento de la ruta en tiempo real
  void iniciarSeguimiento() {
    if (_siguiendoRuta) return;

    _siguiendoRuta = true;
    notifyListeners();

    posicionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).listen((Position position) {
      final pos = LatLng(position.latitude, position.longitude);

      // Actualizar posición del usuario
      _currentPosition = position;
      _userMarker = Marker(
        markerId: const MarkerId("user"),
        position: pos,
        infoWindow: const InfoWindow(title: "Tú"),
      );

      // Centrar cámara en la posición del usuario
      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(pos));
      }

      notifyListeners();
    });
  }

  /// Detiene el seguimiento de la ruta
  void detenerSeguimiento() {
    posicionSubscription?.cancel();
    _siguiendoRuta = false;
    notifyListeners();
  }

  // ========================================
  // MÉTODOS PÚBLICOS - GUARDAR RUTA
  // ========================================

  /// Guarda la ruta actual en Supabase
  ///
  /// [nombreRuta] - Nombre de la ruta
  /// [descripcionRuta] - Descripción opcional
  ///
  /// Retorna true si se guardó exitosamente, false en caso contrario
  Future<bool> guardarRutaActual(
    String nombreRuta,
    String? descripcionRuta,
  ) async {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) {
      _errorMessage = 'No hay ruta activa para guardar';
      notifyListeners();
      return false;
    }

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      _errorMessage = 'Debes iniciar sesión para guardar rutas';
      notifyListeners();
      return false;
    }

    if (nombreRuta.trim().isEmpty) {
      _errorMessage = 'El nombre de la ruta no puede estar vacío';
      notifyListeners();
      return false;
    }

    _status = RoutesStatus.savingRoute;
    notifyListeners();

    try {
      // Convertir puntos a JSON
      final puntosJson =
          _polylineCoordinates
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList();

      // Insertar en Supabase
      await _supabase.from('rutas_realizadas').insert({
        'usuario_id': uid,
        'nombre_ruta': nombreRuta.trim(),
        'fecha': DateTime.now().toIso8601String(),
        'puntos': puntosJson,
        'distancia_km': 0.0, // Podrías calcular esto
        'duracion_minutos': 0, // Podrías calcular esto
        'imagen_url': null,
        'descripcion_ruta':
            descripcionRuta == null || descripcionRuta.isEmpty
                ? null
                : descripcionRuta.trim(),
      });

      _status = RoutesStatus.routeSaved;
      _errorMessage = null;
      notifyListeners();

      // Después de un breve delay, volver al estado anterior
      await Future.delayed(const Duration(milliseconds: 500));
      _status = RoutesStatus.routeCalculated;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar la ruta: ${e.toString()}';
      _status = RoutesStatus.error;
      notifyListeners();
      debugPrint('Error en guardarRutaActual: $e');
      return false;
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - CARGAR RUTA
  // ========================================

  /// Muestra una ruta guardada en el mapa
  ///
  /// [ruta] - Mapa con los datos de la ruta
  Future<void> mostrarRutaGuardada(Map<String, dynamic> ruta) async {
    final List<dynamic>? puntos = ruta['puntos'];

    if (puntos == null || puntos.isEmpty) {
      _errorMessage = 'Esta ruta no tiene puntos para mostrar';
      notifyListeners();
      return;
    }

    _status = RoutesStatus.loadingRoute;
    notifyListeners();

    try {
      // Limpiar búsqueda anterior
      limpiarBusqueda();

      _polylineCoordinates.clear();

      // Convertir puntos JSON a LatLng
      for (var punto in puntos) {
        if (punto is Map &&
            punto.containsKey('lat') &&
            punto.containsKey('lng')) {
          final lat = punto['lat'];
          final lng = punto['lng'];
          _polylineCoordinates.add(
            LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          );
        }
      }

      if (_polylineCoordinates.isEmpty) {
        _errorMessage = 'No se pudieron procesar los puntos de la ruta';
        _status = RoutesStatus.error;
        notifyListeners();
        return;
      }

      // Crear polyline con color distintivo
      _polylines = {
        Polyline(
          polylineId: PolylineId(
            "ruta_guardada_${ruta['id'] ?? DateTime.now().millisecondsSinceEpoch}",
          ),
          color: Colors.purple,
          width: 6,
          points: _polylineCoordinates,
        ),
      };

      // Centrar el mapa en la ruta
      if (mapController != null && _polylineCoordinates.isNotEmpty) {
        if (_polylineCoordinates.length == 1) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_polylineCoordinates.first, 15),
          );
        } else {
          LatLngBounds bounds = _calculateBounds(_polylineCoordinates);
          mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }

      _status = RoutesStatus.routeLoaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al mostrar la ruta guardada: ${e.toString()}';
      _status = RoutesStatus.error;
      debugPrint('Error en mostrarRutaGuardada: $e');
    }

    notifyListeners();
  }

  /// Carga y muestra una ruta por su ID
  ///
  /// [rutaId] - ID de la ruta a cargar
  Future<void> cargarYMostrarRutaPorId(String rutaId) async {
    _status = RoutesStatus.loadingRoute;
    notifyListeners();

    try {
      final respuestaRuta =
          await _supabase
              .from('rutas_realizadas')
              .select('puntos, nombre_ruta, id')
              .eq('id', rutaId)
              .single();

      await mostrarRutaGuardada(respuestaRuta);
    } catch (e) {
      _errorMessage = 'No se pudo cargar la ruta: ${e.toString()}';
      _status = RoutesStatus.error;
      notifyListeners();
      debugPrint('Error en cargarYMostrarRutaPorId: $e');
    }
  }

  // ========================================
  // MÉTODOS PÚBLICOS - UTILIDADES
  // ========================================

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifica si hay una ruta activa
  bool tieneRutaActiva() {
    return _polylines.isNotEmpty && _polylineCoordinates.isNotEmpty;
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  /// Calcula los bounds para una lista de puntos
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

  // ========================================
  // DISPOSE
  // ========================================

  @override
  void dispose() {
    mapController?.dispose();
    searchController.dispose();
    posicionSubscription?.cancel();
    super.dispose();
  }
}
