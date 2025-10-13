import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// ASUMIENDO QUE USAS google_place como en RutasScreen
import 'package:google_place/google_place.dart';
// Y para geocodificación inversa si mantienes el tap en el mapa:
import 'package:geocoding/geocoding.dart'
    as geocoding; // O tu alternativa preferida

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialSearchQuery;

  const MapPickerScreen({
    super.key,
    this.initialPosition,
    this.initialSearchQuery,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  Marker? _marker;
  String _currentAddress = "Mueve el mapa o busca una dirección";
  bool _isLoadingAddress = false; // Para la geocodificación inversa

  // --- Configuración de Google Place ---
  // DEBES CONFIGURAR TU API KEY AQUÍ, la misma que usas en RutasScreen
  final String _googleApiKey =
      "AIzaSyDTFLe8BeQLca2P5ES7vXetX3icv7jiFEE"; // Reemplaza con tu clave real
  GooglePlace? googlePlace;
  List<AutocompletePrediction> _placePredictions = [];
  final TextEditingController _searchController = TextEditingController();
  // --- Fin Configuración de Google Place ---

  final LatLng _defaultInitialPiedecuesta = const LatLng(7.0039, -73.0530);

  @override
  void initState() {
    super.initState();
    if (_googleApiKey != "TU_Maps_API_KEY" && _googleApiKey.isNotEmpty) {
      googlePlace = GooglePlace(_googleApiKey);
    } else {
      print(
        "ADVERTENCIA: Google API Key no configurada para MapPickerScreen. La búsqueda de lugares no funcionará.",
      );
    }

    if (widget.initialPosition != null) {
      _pickedLocation = widget.initialPosition;
      // Si tenemos una posición inicial, intentamos obtener su dirección
      _updateMarkerAndAddress(
        _pickedLocation!,
        fromSearch: widget.initialSearchQuery != null,
      );
    } else {
      _requestPermissionAndGetCurrentLocation();
    }

    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      // Podrías iniciar una búsqueda aquí si lo deseas
      if (googlePlace != null) _searchPlace(widget.initialSearchQuery!);
    }
  }

  Future<void> _requestPermissionAndGetCurrentLocation() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        LatLng currentLocation = LatLng(position.latitude, position.longitude);
        if (mounted && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 15),
          );
        }
      } catch (e) {
        print("Error obteniendo ubicación actual: $e");
        if (mounted && _mapController != null && _pickedLocation == null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_defaultInitialPiedecuesta, 13),
          );
        }
      }
    } else {
      print("Permiso de ubicación denegado.");
      if (mounted && _mapController != null && _pickedLocation == null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_defaultInitialPiedecuesta, 13),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickedLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pickedLocation!, 16),
      );
    } else if (widget.initialPosition == null) {
      _requestPermissionAndGetCurrentLocation();
    }
  }

  // Actualiza marcador y dirección. 'fromSearch' indica si la LatLng vino de una búsqueda de lugar.
  Future<void> _updateMarkerAndAddress(
    LatLng position, {
    String? addressFromSearch,
    bool fromSearch = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _pickedLocation = position;
      _marker = Marker(
        markerId: const MarkerId('pickedLocation'),
        position: _pickedLocation!,
        infoWindow: InfoWindow(
          title: addressFromSearch ?? 'Ubicación Seleccionada',
        ),
        draggable: true,
        onDragEnd: (newPosition) {
          _updateMarkerAndAddress(newPosition); // Llama sin addressFromSearch
        },
      );
      if (addressFromSearch == null) {
        // Solo cargar si no tenemos ya la dirección de una búsqueda
        _isLoadingAddress = true;
        _currentAddress = "Obteniendo dirección...";
      } else {
        _currentAddress = addressFromSearch;
        _searchController.text =
            addressFromSearch; // Actualizar barra de búsqueda
      }
    });

    if (!fromSearch) {
      // No mover cámara si es por drag o búsqueda, solo por tap directo
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }

    // Solo hacer geocodificación inversa si no tenemos la dirección de una búsqueda
    if (addressFromSearch == null) {
      try {
        List<geocoding.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          setState(() {
            _currentAddress =
                "${place.street ?? ''}"
                "${place.subLocality != null && place.subLocality!.isNotEmpty ? ', ${place.subLocality}' : ''}"
                "${place.locality != null && place.locality!.isNotEmpty ? ', ${place.locality}' : ''}"
                "${place.administrativeArea != null && place.administrativeArea!.isNotEmpty ? ', ${place.administrativeArea}' : ''}";
            _currentAddress =
                _currentAddress.startsWith(", ")
                    ? _currentAddress.substring(2)
                    : _currentAddress;
            _searchController.text =
                _currentAddress; // Actualizar barra de búsqueda
          });
        } else if (mounted) {
          setState(
            () =>
                _currentAddress =
                    "No se encontró dirección para esta ubicación.",
          );
        }
      } catch (e) {
        print("Error en geocodificación inversa: $e");
        if (mounted)
          setState(() => _currentAddress = "Error obteniendo dirección.");
      } finally {
        if (mounted) setState(() => _isLoadingAddress = false);
      }
    } else {
      if (mounted)
        setState(() => _isLoadingAddress = false); // Ya tenemos la dirección
    }
  }

  void _onTapMap(LatLng position) {
    // Cuando se toca el mapa, no tenemos 'addressFromSearch'
    _updateMarkerAndAddress(position);
  }

  // --- Lógica de Búsqueda con Google Place (similar a RutasScreen) ---
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty || googlePlace == null) {
      if (mounted) setState(() => _placePredictions = []);
      return;
    }
    // Considera usar la ubicación actual para sesgar los resultados de búsqueda:
    // LatLng? biasLocation;
    // if (_mapController != null) {
    //   try {
    //     LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();
    //     biasLocation = LatLng(
    //       (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
    //       (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
    //     );
    //   } catch (e) { print("Error getting map center for search bias: $e"); }
    // }

    final result = await googlePlace!.autocomplete.get(
      query,
      region: "co", // Filtrar por Colombia
      // language: "es", // Para que las predicciones vengan en español
      // location: biasLocation != null ? LatLon(biasLocation.latitude, biasLocation.longitude) : null,
      // radius: biasLocation != null ? 50000 : null, // Radio en metros (ej. 50km) si se usa location
    );

    if (result != null && result.predictions != null && mounted) {
      setState(() => _placePredictions = result.predictions!);
    } else if (mounted) {
      setState(() => _placePredictions = []);
    }
  }

  Future<void> _selectSearchedPlace(AutocompletePrediction prediction) async {
    if (googlePlace == null || prediction.placeId == null) return;

    // Limpiar predicciones y ocultar teclado
    if (mounted) setState(() => _placePredictions = []);
    FocusScope.of(context).unfocus();

    final details = await googlePlace!.details.get(
      prediction.placeId!,
      language: "es",
    ); // Pedir detalles en español
    if (details != null &&
        details.result != null &&
        details.result!.geometry != null) {
      final lat = details.result!.geometry!.location!.lat!;
      final lng = details.result!.geometry!.location!.lng!;
      final newPos = LatLng(lat, lng);
      // Usar la dirección formateada de Google o el nombre del lugar
      final String address =
          details.result!.formattedAddress ??
          details.result!.name ??
          prediction.description ??
          "Dirección no disponible";
      _searchController.text = address;

      _updateMarkerAndAddress(
        newPos,
        addressFromSearch: address,
        fromSearch: true,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
    }
  }
  // --- Fin Lógica de Búsqueda ---

  void _confirmSelection() {
    // ... (sin cambios)
    if (_pickedLocation != null) {
      Navigator.pop(context, {
        'latlng': _pickedLocation,
        'address': _currentAddress,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona una ubicación en el mapa."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Ubicación"),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmSelection,
              tooltip: "Confirmar Ubicación",
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            /* ... (sin cambios) ... */
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition ?? _defaultInitialPiedecuesta,
              zoom: widget.initialPosition != null ? 16 : 12,
            ),
            onTap: _onTapMap,
            markers: _marker != null ? {_marker!} : {},
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar dirección o lugar...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  if (mounted)
                                    setState(() => _placePredictions = []);
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(15),
                    ),
                    onChanged:
                        _searchPlace, // Llamar a la búsqueda con google_place
                  ),
                  // Mostrar Predicciones de Búsqueda
                  if (_placePredictions.isNotEmpty)
                    Material(
                      // Necesario para que las InkWell de ListTile funcionen bien sobre el mapa
                      elevation: 2, // Sombra sutil
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ), // Limitar altura
                        child: ListView.builder(
                          shrinkWrap: true, // Importante dentro de Column
                          itemCount: _placePredictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _placePredictions[index];
                            return ListTile(
                              leading: const Icon(Icons.pin_drop_outlined),
                              title: Text(prediction.description ?? ''),
                              onTap: () => _selectSearchedPlace(prediction),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            // ... (Mostrar dirección actual, sin cambios) ...
            bottom: 70,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingAddress
                            ? "Obteniendo dirección..."
                            : _currentAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _pickedLocation != null
              ? FloatingActionButton.extended(
                onPressed: _confirmSelection,
                label: const Text("Confirmar"),
                icon: const Icon(Icons.check_circle_outline),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
