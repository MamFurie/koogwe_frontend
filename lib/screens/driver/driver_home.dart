import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../auth/login_screen.dart';
import 'driver_wallet_screen.dart';
import 'driver_history_screen.dart';
import 'driver_chat_screen.dart';

enum DriverState { offline, online, goingToPickup, arrived, inProgress, completed }

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final _socket = SocketService();
  DriverState _state = DriverState.offline;
  int _currentNavIndex = 0;
  String _driverName = '';
  String _driverId = '';
  Map<String, dynamic>? _currentRide;
  GoogleMapController? _mapController;
  Timer? _locationTimer; // ✅ NOUVEAU : timer GPS

  static LatLng get _lomeCenter => const LatLng(6.1375, 1.2125);

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _initSocket();
  }

  Future<void> _loadDriver() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString(AppConfig.keyUserName) ?? 'Chauffeur';
      _driverId = prefs.getString(AppConfig.keyUserId) ?? '';
    });
  }

  void _initSocket() {
    _socket.connect();
    _socket.onNewRide((data) {
      if (_state == DriverState.online) {
        _showNewRideDialog(data);
      }
    });
  }

  void _toggleOnline() {
    if (_state == DriverState.offline) {
      _socket.driverGoOnline(_driverId);
      setState(() => _state = DriverState.online);
    } else {
      _socket.driverGoOffline(_driverId);
      setState(() => _state = DriverState.offline);
    }
  }

  void _showNewRideDialog(Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewRideSheet(
        ride: ride,
        onAccept: () {
          Navigator.pop(context);
          _acceptRide(ride);
        },
        onReject: () => Navigator.pop(context),
      ),
    );
  }

  // ✅ MIS À JOUR : démarre le tracking GPS après acceptation
  void _acceptRide(Map<String, dynamic> ride) {
    _socket.acceptRide(ride['id'], _driverId);
    setState(() {
      _currentRide = ride;
      _state = DriverState.goingToPickup;
    });
    _listenToRideStatus(ride['id']);
    _startLocationTracking(ride['id']); // ✅ NOUVEAU
  }

  void _listenToRideStatus(String rideId) {
    _socket.onRideStatus(rideId, (data) {
      if (!mounted) return;
    });
  }

  // ✅ NOUVEAU : démarre l'envoi GPS toutes les 3 secondes
  Future<void> _startLocationTracking(String rideId) async {
    // Vérifie et demande la permission GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Permission GPS refusée');
      return;
    }

    // Envoie la position toutes les 3 secondes
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _socket.updateLocation(rideId, position.latitude, position.longitude);

        // Centre la carte sur la position du chauffeur
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      } catch (e) {
        debugPrint('Erreur GPS: $e');
      }
    });
  }

  // ✅ NOUVEAU : stoppe l'envoi GPS
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _stopLocationTracking(); // ✅ NOUVEAU
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildMainContent(),
      const DriverWalletScreen(),
      const DriverHistoryScreen(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tabs[_currentNavIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _lomeCenter, zoom: 14),
                onMapCreated: (c) => _mapController = c,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primarySurface,
                                child: Text(
                                  _driverName.isNotEmpty ? _driverName[0].toUpperCase() : 'D',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_driverName, style: AppText.label),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: _state == DriverState.offline ? AppColors.error : AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _state == DriverState.offline ? 'Hors ligne' : 'En ligne',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Poppins'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.navigation, color: AppColors.primary, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ NOUVEAU : badge GPS actif quand en course
              if (_state == DriverState.goingToPickup || _state == DriverState.inProgress)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text('GPS actif', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildStateCard(),
      ],
    );
  }

  Widget _buildStateCard() {
    switch (_state) {
      case DriverState.offline:
      case DriverState.online:
        return _offlineOnlineCard();
      case DriverState.goingToPickup:
        return _goingToPickupCard();
      case DriverState.arrived:
        return _arrivedCard();
      case DriverState.inProgress:
        return _inProgressCard();
      case DriverState.completed:
        return _completedCard();
    }
  }

  Widget _offlineOnlineCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          if (_state == DriverState.online) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('En recherche de courses...', style: AppText.h3),
            const SizedBox(height: 6),
            const Text('Restez disponible, une course peut arriver à tout moment', style: AppText.bodySecondary, textAlign: TextAlign.center),
          ] else ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new, color: AppColors.textSecondary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Vous êtes hors ligne', style: AppText.h3),
            const SizedBox(height: 6),
            const Text('Activez votre disponibilité pour recevoir des courses', style: AppText.bodySecondary, textAlign: TextAlign.center),
          ],

          const SizedBox(height: 24),

          GestureDetector(
            onTap: _toggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _state == DriverState.online ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: _state == DriverState.online ? Border.all(color: AppColors.error, width: 1.5) : null,
              ),
              child: Center(
                child: Text(
                  _state == DriverState.online ? 'Aller hors ligne' : 'Aller en ligne',
                  style: TextStyle(
                    color: _state == DriverState.online ? AppColors.error : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goingToPickupCard() {
    final passenger = _currentRide?['passenger'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${_currentRide?['passengerId']}'),
                backgroundColor: AppColors.primarySurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger?['name'] ?? 'Passager', style: AppText.h4),
                    const Text('En attente de ramassage', style: AppText.small),
                  ],
                ),
              ),
              _actionIcon(Icons.chat_bubble_outline, () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DriverChatScreen(
                    rideId: _currentRide?['id'] ?? '',
                    otherName: passenger?['name'] ?? 'Passager',
                  ),
                ));
              }),
              const SizedBox(width: 8),
              _actionIcon(Icons.phone_outlined, () {}),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          const Text('Rider Waiting — Move Now', style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Time to pick up your rider! Follow the navigation and arrive without delay',
            style: AppText.bodySecondary,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // ✅ FIX : SizedBox au lieu de Container sans width
          const SizedBox(
            height: 80,
            child: Icon(Icons.person_pin_circle, color: AppColors.primary, size: 72),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => setState(() => _state = DriverState.arrived),
            child: const Text('Go to Pickup Location'),
          ),
        ],
      ),
    );
  }

  Widget _arrivedCard() {
    final passenger = _currentRide?['passenger'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${_currentRide?['passengerId']}'),
                backgroundColor: AppColors.primarySurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger?['name'] ?? 'Passager', style: AppText.h4),
                    const Text('Arrivé au point de ramassage', style: AppText.small),
                  ],
                ),
              ),
              _actionIcon(Icons.chat_bubble_outline, () {}),
              const SizedBox(width: 8),
              _actionIcon(Icons.phone_outlined, () {}),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          const Text("You've Arrived at the Pickup Point", style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            "You've reached the pickup location. Please wait a few minutes for the rider to approach your vehicle.",
            style: AppText.bodySecondary,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // ✅ FIX : SizedBox au lieu de Container sans width
          const SizedBox(
            height: 80,
            child: Icon(Icons.directions_car, color: AppColors.primary, size: 72),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              _socket.driverArrived(_currentRide?['id'] ?? '');
              setState(() => _state = DriverState.inProgress);
              _socket.startTrip(_currentRide?['id'] ?? '');
            },
            child: const Text('Tap to Confirm Your Arrival'),
          ),
        ],
      ),
    );
  }

  Widget _inProgressCard() {
    final price = (_currentRide?['price'] ?? 0).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          const Text('Course en cours 🚗', style: AppText.h3),
          const SizedBox(height: 8),
          const Text('Conduisez vers la destination', style: AppText.bodySecondary),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.attach_money, '$price FCFA', AppColors.success),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              _socket.finishTrip(_currentRide?['id'] ?? '', (_currentRide?['price'] ?? 0).toDouble());
              _stopLocationTracking(); // ✅ NOUVEAU : stoppe le GPS quand la course se termine
              setState(() => _state = DriverState.completed);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Terminer la course'),
          ),
        ],
      ),
    );
  }

  Widget _completedCard() {
    final price = (_currentRide?['price'] ?? 0).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          const Text('Ride Is Complete ✅', style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('The trip has ended. Wait for the passenger to complete their cash payment before closing the ride.', style: AppText.bodySecondary, textAlign: TextAlign.center),

          const SizedBox(height: 20),

          // ✅ FIX : SizedBox au lieu de Container sans width
          const SizedBox(
            height: 80,
            child: Icon(Icons.check_circle, color: AppColors.success, size: 72),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _paymentRow('Payment Method', 'Cash'),
                const SizedBox(height: 8),
                _paymentRow('Service Charge', '$price FCFA'),
                const SizedBox(height: 8),
                _paymentRow('Discount', '0 FCFA'),
                const Divider(color: AppColors.border),
                _paymentRow('Total Amount :', '$price FCFA', highlight: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              setState(() {
                _state = DriverState.offline;
                _currentRide = null;
              });
            },
            child: const Text('Payment Received'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Mon Profil', style: AppText.h2),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  _driverName.isNotEmpty ? _driverName[0].toUpperCase() : 'D',
                  style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(_driverName, style: AppText.h3)),
            const Center(child: Text('Chauffeur Koogwz', style: AppText.bodySecondary)),
            const SizedBox(height: 32),
            _profileMenuItem(Icons.directions_car_outlined, 'Mon véhicule', () {}),
            _profileMenuItem(Icons.star_outline, 'Notes & avis', () {}),
            _profileMenuItem(Icons.settings_outlined, 'Paramètres', () {}),
            _profileMenuItem(Icons.logout, 'Déconnexion', () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'My Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Ride History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: highlight ? AppText.h4 : AppText.bodySecondary),
        Text(
          value,
          style: highlight
              ? const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')
              : AppText.body,
        ),
      ],
    );
  }

  Widget _profileMenuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppText.h4.copyWith(color: color ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ---- Sheet : Nouvelle course disponible ----
class _NewRideSheet extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _NewRideSheet({required this.ride, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final price = (ride['price'] ?? 0).toStringAsFixed(0);
    final passenger = ride['passenger'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  (passenger?['name'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger?['name'] ?? 'Passager', style: AppText.h3),
                    const Text('Nouvelle course', style: AppText.bodySecondary),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$price FCFA',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked, color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Pickup: ${ride['originLat']?.toStringAsFixed(4)}, ${ride['originLng']?.toStringAsFixed(4)}', style: AppText.body)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Dest: ${ride['destLat']?.toStringAsFixed(4)}, ${ride['destLng']?.toStringAsFixed(4)}', style: AppText.body)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  child: const Text('Accepter ✓'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}