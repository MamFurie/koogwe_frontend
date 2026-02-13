import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/map_service.dart';
import '../../services/ride_service.dart';
import '../../services/socket_service.dart';
import 'ride_tracking_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final LatLng originLatLng;
  final LatLng destLatLng;
  final String originAddress;
  final String destAddress;
  final double distanceKm;

  const VehicleSelectionScreen({
    super.key,
    required this.originLatLng,
    required this.destLatLng,
    required this.originAddress,
    required this.destAddress,
    required this.distanceKm,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final _mapService = MapService();
  final _rideService = RideService();
  final _socket = SocketService();

  String _selected = 'Eco';
  bool _isLoading = false;

  final _vehicles = [
    {'type': 'Moto', 'icon': Icons.motorcycle, 'color': const Color(0xFFF59E0B), 'desc': 'Rapide & économique', 'time': '~5 min'},
    {'type': 'Eco', 'icon': Icons.directions_car, 'color': AppColors.success, 'desc': 'Confort standard', 'time': '~8 min'},
    {'type': 'Confort', 'icon': Icons.airline_seat_recline_extra, 'color': AppColors.primary, 'desc': 'Premium & spacieux', 'time': '~10 min'},
  ];

  double get _selectedPrice {
    return _mapService.calculatePrice(widget.distanceKm, _selected);
  }

  Future<void> _confirmRide() async {
    setState(() => _isLoading = true);

    final result = await _rideService.createRide(
      originLat: widget.originLatLng.latitude,
      originLng: widget.originLatLng.longitude,
      destLat: widget.destLatLng.latitude,
      destLng: widget.destLatLng.longitude,
      price: _selectedPrice,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final ride = result['ride'];

      // Notifier les chauffeurs via Socket
      _socket.connect();
      _socket.joinRideRoom(ride['id']);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideTrackingScreen(
            rideId: ride['id'],
            originAddress: widget.originAddress,
            destAddress: widget.destAddress,
            price: _selectedPrice,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de la réservation'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choisir un véhicule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Route summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
            ),
            child: Column(
              children: [
                _routePoint(Icons.radio_button_checked, AppColors.success, widget.originAddress),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: const Column(
                    children: [
                      SizedBox(height: 2), Text('· ', style: TextStyle(color: AppColors.textHint)), SizedBox(height: 2),
                      Text('· ', style: TextStyle(color: AppColors.textHint)), SizedBox(height: 2),
                    ],
                  ),
                ),
                _routePoint(Icons.location_on, AppColors.error, widget.destAddress),
              ],
            ),
          ),

          // Distance badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _infoBadge(Icons.straighten_outlined, '${widget.distanceKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 10),
                _infoBadge(Icons.access_time_outlined, '~8 min'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vehicle list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final v = _vehicles[i];
                final isSelected = _selected == v['type'];
                final price = _mapService.calculatePrice(widget.distanceKm, v['type'] as String);

                return GestureDetector(
                  onTap: () => setState(() => _selected = v['type'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                          : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: (v['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(v['icon'] as IconData, color: v['color'] as Color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['type'] as String, style: AppText.h4),
                              Text(v['desc'] as String, style: AppText.small),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${price.toInt()} FCFA',
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                )),
                            Text(v['time'] as String, style: AppText.small),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom confirm
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total estimé', style: AppText.bodySecondary),
                    Text(
                      '${_selectedPrice.toInt()} FCFA',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmRide,
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Confirmer la course'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routePoint(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: AppText.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
