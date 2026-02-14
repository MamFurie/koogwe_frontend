import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'config.dart';
import 'login_screen.dart';
import 'socket_service.dart';
import 'ride_service.dart';
import 'history_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'theme/colors.dart';

enum DriverState {
  OFFLINE,
  ONLINE_IDLE,
  GOING_TO_PICKUP,
  ARRIVED,
  IN_PROGRESS,
  PAYMENT_SUMMARY,
}

class HomeDriver extends StatefulWidget {
  @override
  _HomeDriverState createState() => _HomeDriverState();
}

class _HomeDriverState extends State<HomeDriver> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  LatLng _currentPos = const LatLng(6.1375, 1.2125);
  
  final _socket = SocketService();
  final _rideService = RideService();

  String driverName = 'Chauffeur';
  String driverId = '';
  double dailyEarnings = 0.0;
  int ridesCount = 0;
  int _navIndex = 0;

  DriverState _currentState = DriverState.OFFLINE;
  dynamic _currentRideData;

  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _initSocket();
    _getUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      driverName = prefs.getString(kKeyUserName) ?? 'Chauffeur';
      driverId = prefs.getString(kKeyUserId) ?? '';
    });
  }

  // ✅ FIX GPS — try/catch pour éviter le crash si permission refusée
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentPos = LatLng(locationData.latitude!, locationData.longitude!);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPos));
      }
    } catch (e) {
      print('GPS non disponible: $e');
      // ✅ Pas de crash — on reste sur Lomé par défaut
    }
  }

  void _initSocket() {
    _socket.connect(); // ✅ Railway dans socket_service.dart

    _socket.onNewRide((data) {
      if (_currentState == DriverState.ONLINE_IDLE && mounted) {
        _showRideRequestModal(data);
      }
    });

    _socket.onTripFinished((data) {
      if (data != null && _currentRideData != null) {
        if (data['id'] == _currentRideData['id']) {
          _completePayment();
        }
      }
    });
  }

  void _toggleOnlineStatus() {
    setState(() {
      if (_currentState == DriverState.OFFLINE) {
        _currentState = DriverState.ONLINE_IDLE;
        _socket.driverGoOnline(driverId);
      } else if (_currentState == DriverState.ONLINE_IDLE) {
        _currentState = DriverState.OFFLINE;
        _socket.driverGoOffline(driverId);
      }
    });
  }

  void _acceptRide(dynamic rideData) {
    Navigator.pop(context);
    setState(() {
      _currentState = DriverState.GOING_TO_PICKUP;
      _currentRideData = rideData;
    });
    _socket.acceptRide(rideData['id'], driverId, driverName);
    _startLiveTracking();
  }

  void _notifyArrival() {
    setState(() => _currentState = DriverState.ARRIVED);
    _socket.driverArrived(_currentRideData['id']);
  }

  void _startTrip() {
    setState(() => _currentState = DriverState.IN_PROGRESS);
    _socket.startTrip(_currentRideData['id']);
  }

  void _finishTrip() {
    setState(() => _currentState = DriverState.PAYMENT_SUMMARY);
    _socket.finishTrip(_currentRideData['id'], (_currentRideData['price'] as num).toDouble());
    _locationSubscription?.cancel();
  }

  void _completePayment() {
    final price = (_currentRideData?['price'] as num?)?.toDouble() ?? 0;
    setState(() {
      dailyEarnings += price;
      ridesCount++;
      _currentState = DriverState.ONLINE_IDLE;
      _currentRideData = null;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 16));
  }

  // ✅ FIX GPS — try/catch dans le tracking aussi
  void _startLiveTracking() async {
    try {
      await _location.enableBackgroundMode(enable: false);
      _locationSubscription = _location.onLocationChanged.listen((LocationData loc) {
        if (_socket.isConnected && _currentRideData != null && loc.latitude != null) {
          setState(() => _currentPos = LatLng(loc.latitude!, loc.longitude!));
          _socket.updateLocation(_currentRideData['id'], loc.latitude!, loc.longitude!);
          _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPos));
        }
      });
    } catch (e) {
      print('Erreur tracking: $e');
      // Pas de crash — le chauffeur reste visible à sa dernière position
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) return WalletScreen(driverId: driverId, onBack: () => setState(() => _navIndex = 0));
    if (_navIndex == 2) return HistoryScreen(onBack: () => setState(() => _navIndex = 0));
    if (_navIndex == 3) return ProfileScreen(isDriver: true, onBack: () => setState(() => _navIndex = 0));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 16.0),
            onMapCreated: (ctrl) => _mapController = ctrl,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Barre supérieure
          if (_currentState != DriverState.PAYMENT_SUMMARY)
            Positioned(
              top: 50, left: 20, right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _locationChip(),
                      _onlineToggle(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_currentState == DriverState.OFFLINE || _currentState == DriverState.ONLINE_IDLE)
                    Row(children: [
                      Expanded(child: _statCard('Recette du jour', '${dailyEarnings.toStringAsFixed(0)} FCFA', Icons.account_balance_wallet, Colors.black)),
                      const SizedBox(width: 15),
                      Expanded(child: _statCard('Courses', '$ridesCount', Icons.local_taxi, AppColors.primary)),
                    ]),
                ],
              ),
            ),

          // Indicateur GPS actif
          if (_currentState == DriverState.GOING_TO_PICKUP || _currentState == DriverState.IN_PROGRESS)
            Positioned(
              bottom: 220, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.gps_fixed, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text('GPS actif', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),

          if (_currentState == DriverState.GOING_TO_PICKUP) _buildGoingToPickupSheet(),
          if (_currentState == DriverState.ARRIVED) _buildArrivedSheet(),
          if (_currentState == DriverState.IN_PROGRESS) _buildInProgressSheet(),
          if (_currentState == DriverState.PAYMENT_SUMMARY) _buildPaymentSheet(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _showRideRequestModal(dynamic data) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 25, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.black)),
              title: Text(data['passenger']?['name'] ?? 'Client Koogwz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${data['price']} FCFA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                const Text('Cash', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            const Divider(),
            _addressRow(Icons.my_location, 'Départ', 'Position du client'),
            const SizedBox(height: 10),
            _addressRow(Icons.location_on, 'Destination', 'Destination du client'),
            const SizedBox(height: 25),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('REFUSER'))),
              const SizedBox(width: 15),
              Expanded(child: ElevatedButton(
                onPressed: () => _acceptRide(data),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('ACCEPTER', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildGoingToPickupSheet() => _bottomPanel(
    title: 'En route vers le client',
    passengerName: _currentRideData?['passenger']?['name'],
    buttonText: 'JE SUIS ARRIVÉ',
    onPressed: _notifyArrival,
  );

  Widget _buildArrivedSheet() => _bottomPanel(
    title: 'Arrivé au point de ramassage',
    subtitle: 'Attendez le client et confirmez.',
    passengerName: _currentRideData?['passenger']?['name'],
    buttonText: 'CONFIRMER & DÉMARRER',
    onPressed: _startTrip,
  );

  Widget _buildInProgressSheet() => _bottomPanel(
    title: 'Course en cours 🚗',
    subtitle: 'Navigation vers la destination.',
    passengerName: _currentRideData?['passenger']?['name'],
    buttonText: 'ARRIVÉ À DESTINATION',
    onPressed: _finishTrip,
  );

  Widget _buildPaymentSheet() {
    final price = _currentRideData?['price'] ?? 0;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 10),
          const Text('Course Terminée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Encaissez le montant ci-dessous.', style: TextStyle(color: Colors.grey)),
          const Divider(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Montant Total', style: TextStyle(fontSize: 18)),
            Text('$price FCFA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Mode de paiement', style: TextStyle(color: Colors.grey)),
            Text('Espèces (Cash)', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
            onPressed: _completePayment,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text('PAIEMENT REÇU', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  Widget _bottomPanel({required String title, String? subtitle, String? passengerName, required String buttonText, required VoidCallback onPressed}) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (passengerName != null) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Icon(Icons.person, color: AppColors.primary)),
            title: Text(passengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: CircleAvatar(backgroundColor: Colors.green, child: IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {})),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  Widget _locationChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
    child: Row(children: [Icon(Icons.location_on, color: AppColors.primary, size: 18), const SizedBox(width: 5), const Text('Lomé, Togo', style: TextStyle(fontWeight: FontWeight.bold))]),
  );

  Widget _onlineToggle() {
    final isOffline = _currentState == DriverState.OFFLINE;
    return GestureDetector(
      onTap: _currentState == DriverState.ONLINE_IDLE || isOffline ? _toggleOnlineStatus : null,
      child: Container(
        width: 110, height: 40,
        decoration: BoxDecoration(color: isOffline ? Colors.grey[300] : AppColors.primary, borderRadius: BorderRadius.circular(30)),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: isOffline ? 60 : 0,
            child: Container(
              width: 50, height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)]),
              child: Icon(isOffline ? Icons.power_settings_new : Icons.bolt, color: isOffline ? Colors.grey : AppColors.primary),
            ),
          ),
          Center(child: Text(isOffline ? '     Offline' : 'Online     ', style: TextStyle(color: isOffline ? Colors.grey[700] : Colors.white, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );

  Widget _addressRow(IconData icon, String title, String address) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 20),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(address, style: const TextStyle(fontWeight: FontWeight.bold)),
    ])),
  ]);
}
