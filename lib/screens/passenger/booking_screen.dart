import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/map_service.dart';
import 'vehicle_selection_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _mapService = MapService();
  final _destController = TextEditingController();
  final _originController = TextEditingController();
  GoogleMapController? _mapController;

  static const LatLng _lomeCenter = LatLng(6.1375, 1.2125);
  LatLng? _originLatLng;
  LatLng? _destLatLng;
  String? _originAddress;
  String? _destAddress;
  List<Map<String, dynamic>> _suggestions = [];
  bool _searchingDest = true;
  bool _isSearching = false;
  double? _distanceKm;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Position par défaut = Lomé
    _originLatLng = _lomeCenter;
    _originAddress = 'Votre position actuelle';
    _originController.text = 'Votre position actuelle';
  }

  @override
  void dispose() {
    _destController.dispose();
    _originController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query, bool isDest) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await _mapService.searchAddress(query);
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _selectLocation(Map<String, dynamic> place, bool isDest) async {
    final latLng = LatLng(place['lat'], place['lng']);
    final shortName = (place['name'] as String).split(',').first;

    setState(() {
      _suggestions = [];
      if (isDest) {
        _destLatLng = latLng;
        _destAddress = shortName;
        _destController.text = shortName;
      } else {
        _originLatLng = latLng;
        _originAddress = shortName;
        _originController.text = shortName;
      }
    });

    // Move camera
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

    // Update markers
    _updateMarkers();

    // If both set, draw route
    if (_originLatLng != null && _destLatLng != null) {
      _drawRoute();
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    if (_originLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: _originLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: _originAddress ?? 'Départ'),
      ));
    }
    if (_destLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: _destLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destAddress ?? 'Arrivée'),
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _drawRoute() async {
    final route = await _mapService.getRoute(_originLatLng!, _destLatLng!);
    if (route == null) return;

    setState(() {
      _distanceKm = route['distanceKm'];
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: List<LatLng>.from(route['polylinePoints']),
          color: AppColors.primary,
          width: 5,
        ),
      };
    });

    // Fit camera to route
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          [_originLatLng!.latitude, _destLatLng!.latitude].reduce((a, b) => a < b ? a : b),
          [_originLatLng!.longitude, _destLatLng!.longitude].reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          [_originLatLng!.latitude, _destLatLng!.latitude].reduce((a, b) => a > b ? a : b),
          [_originLatLng!.longitude, _destLatLng!.longitude].reduce((a, b) => a > b ? a : b),
        ),
      ),
      80,
    ));
  }

  void _goToVehicleSelection() {
    if (_destLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une destination'), backgroundColor: AppColors.error),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleSelectionScreen(
          originLatLng: _originLatLng!,
          destLatLng: _destLatLng!,
          originAddress: _originAddress ?? '',
          destAddress: _destAddress ?? '',
          distanceKm: _distanceKm ?? 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _lomeCenter, zoom: 13),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            polylines: _polylines,
            markers: _markers,
          ),

          // Top search panel
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16)],
                    ),
                    child: Column(
                      children: [
                        // Origin
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              const Icon(Icons.radio_button_checked, color: AppColors.success, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _originController,
                                  decoration: const InputDecoration(
                                    hintText: 'Point de départ',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) => _searchAddress(v, false),
                                  onTap: () => setState(() => _searchingDest = false),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.textSecondary),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),

                        const Divider(color: AppColors.divider, indent: 48, height: 12),

                        // Destination
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _destController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Où voulez-vous aller ?',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) => _searchAddress(v, true),
                                  onTap: () => setState(() => _searchingDest = true),
                                ),
                              ),
                              if (_isSearching)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Suggestions
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          title: Text(
                            (s['name'] as String).split(',').first,
                            style: AppText.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            s['name'],
                            style: AppText.small,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          dense: true,
                          onTap: () => _selectLocation(s, _searchingDest),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom CTA
          if (_destLatLng != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_distanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.straighten, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text('${_distanceKm!.toStringAsFixed(1)} km', style: AppText.h4),
                          ],
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _goToVehicleSelection,
                      child: const Text('Choisir un véhicule'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
