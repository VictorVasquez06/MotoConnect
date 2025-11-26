import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/api_constants.dart';

/// Widget reutilizable para búsqueda de ubicaciones usando Google Places
class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final Function(String address, LatLng coordinates) onLocationSelected;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  GooglePlace? _googlePlace;
  List<AutocompletePrediction> _predictions = [];
  bool _isSearching = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(ApiConstants.googleMapsApiKey);
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await _googlePlace?.autocomplete.get(
        query,
        language: 'es',
        components: [Component('country', 'co')], // Filtrar por Colombia
      );

      if (result != null && result.predictions != null && mounted) {
        setState(() {
          _predictions = result.predictions!;
          _isSearching = false;
        });
        _showOverlay();
      }
    } catch (e) {
      debugPrint('Error en búsqueda de lugares: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_predictions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 32,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 65),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, size: 20),
                      title: Text(
                        prediction.structuredFormatting?.mainText ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        prediction.structuredFormatting?.secondaryText ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _selectPlace(prediction),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    _removeOverlay();

    try {
      final details = await _googlePlace?.details.get(prediction.placeId ?? '');

      if (details != null &&
          details.result != null &&
          details.result!.geometry != null) {
        final lat = details.result!.geometry!.location!.lat;
        final lng = details.result!.geometry!.location!.lng;
        final address = details.result!.formattedAddress ?? prediction.description ?? '';

        if (mounted) {
          setState(() {
            widget.controller.text = address;
            _predictions = [];
          });

          widget.onLocationSelected(
            address,
            LatLng(lat!, lng!),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al obtener detalles del lugar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Ubicación',
          hintText: widget.hintText ?? 'Buscar lugar...',
          border: const OutlineInputBorder(),
          prefixIcon: Icon(widget.prefixIcon ?? Icons.location_on),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {
                          _predictions = [];
                        });
                        _removeOverlay();
                      },
                    )
                  : null,
        ),
        validator: widget.validator,
        onChanged: (value) {
          _searchPlaces(value);
        },
        onTap: () {
          if (_predictions.isNotEmpty) {
            _showOverlay();
          }
        },
      ),
    );
  }
}
