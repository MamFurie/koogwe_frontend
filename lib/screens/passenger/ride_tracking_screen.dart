import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/socket_service.dart';
import '../passenger/passenger_home.dart';
import 'passenger_chat_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final String originAddress;
  final String destAddress;
  final double price;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
    required this.originAddress,
    required this.destAddress,
    required this.price,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final _socket = SocketService();
  GoogleMapController? _mapController;
  Map<String, dynamic>? _rideStatus;
  LatLng? _driverLocation;
  Set<Marker> _markers = {};
  String _statusText = 'Recherche d\'un chauffeur...';
  String _statusSubText = 'Un chauffeur va accepter votre course dans quelques instants';

  static const LatLng _lomeCenter = LatLng(6.1375, 1.2125);

  @override
  void initState() {
    super.initState();
    _listenSocket();
  }

  void _listenSocket() {
    _socket.onRideStatus(widget.rideId, (data) {
      if (!mounted) return;
      setState(() {
        _rideStatus = Map<String, dynamic>.from(data);
        _updateStatus(data['status']);
      });
    });

    _socket.onDriverLocation(widget.rideId, (data) {
      if (!mounted) return;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final driverPos = LatLng(lat, lng);

      setState(() {
        _driverLocation = driverPos;
        _markers = {
          Marker(
            markerId: const MarkerId('driver'),
            position: driverPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(title: _rideStatus?['driverName'] ?? 'Chauffeur'),
          ),
        };
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(driverPos));
    });
  }

  void _updateStatus(String? status) {
    switch (status) {
      case 'ACCEPTED':
        _statusText = 'Chauffeur en route 🚗';
        _statusSubText = 'Votre chauffeur arrive vers vous';
        break;
      case 'ARRIVED':
        _statusText = 'Chauffeur arrivé ! 📍';
        _statusSubText = 'Votre chauffeur vous attend';
        break;
      case 'IN_PROGRESS':
        _statusText = 'En route vers la destination 🛣️';
        _statusSubText = 'Asseyez-vous confortablement';
        break;
      case 'COMPLETED':
        _statusText = 'Course terminée ✅';
        _statusSubText = 'Merci d\'avoir utilisé Koogwz !';
        break;
      default:
        _statusText = 'Recherche d\'un chauffeur...';
        _statusSubText = 'Patientez un moment';
    }
  }

  @override
  void dispose() {
    _socket.off('ride_status_${widget.rideId}');
    _socket.off('driver_location_${widget.rideId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _rideStatus?['status'];
    final isCompleted = status == 'COMPLETED';
    final hasDriver = _rideStatus != null && status != null && status != 'REQUESTED';

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _lomeCenter, zoom: 14),
            onMapCreated: (c) => _mapController = c,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),

                  // Status
                  Text(_statusText, style: AppText.h3, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(_statusSubText, style: AppText.bodySecondary, textAlign: TextAlign.center),

                  // Driver info (si accepté)
                  if (hasDriver && _rideStatus != null) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(_rideStatus?['driverImage'] ?? 'https://i.pravatar.cc/150'),
                          backgroundColor: AppColors.primarySurface,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_rideStatus?['driverName'] ?? 'Chauffeur', style: AppText.h4),
                              Text(_rideStatus?['vehicleInfo'] ?? '', style: AppText.small),
                              if (_rideStatus?['licensePlate'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(_rideStatus!['licensePlate'], style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _actionBtn(Icons.chat_bubble_outline, () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PassengerChatScreen(
                                  rideId: widget.rideId,
                                  driverName: _rideStatus?['driverName'] ?? 'Chauffeur',
                                ),
                              ));
                            }),
                            const SizedBox(width: 8),
                            _actionBtn(Icons.phone_outlined, () {}),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Searching indicator
                  if (!hasDriver) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.primarySurface,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prix estimé', style: AppText.bodySecondary),
                      Text('${widget.price.toInt()} FCFA', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Poppins')),
                    ],
                  ),

                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PassengerHome()),
                        (_) => false,
                      ),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
