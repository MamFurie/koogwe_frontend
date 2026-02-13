import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/ride_service.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _rideService = RideService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _rides = [];

  // Demo data pour l'affichage (comme dans le design ReadyRide)
  final List<Map<String, dynamic>> _demoRides = [
    {'name': 'Oliver Green', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 3200, 'date': '03/15/2026'},
    {'name': 'Ethan Brown', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 3200, 'date': '03/15/2026'},
    {'name': 'Aiden Clark', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 4500, 'date': '03/12/2026'},
    {'name': 'James White', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 5000, 'date': '03/12/2026'},
    {'name': 'Noah Harris', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 6000, 'date': '03/12/2026'},
    {'name': 'Lucas Martin', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 7500, 'date': '03/10/2026'},
    {'name': 'Emma Williams', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 8000, 'date': '03/10/2026'},
    {'name': 'Noah Smith', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '6.0', 'price': 9000, 'date': '03/10/2026'},
    {'name': 'Olivia Brown', 'type': 'Bike', 'dist': '2.3 km', 'time': '30 min', 'rating': '5.0', 'price': 10000, 'date': '03/09/2026'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await _rideService.getRideHistory();
    setState(() {
      _isLoading = false;
      if (result['success'] && (result['rides'] as List).isNotEmpty) {
        _rides = List<Map<String, dynamic>>.from(result['rides']);
      } else {
        // Fallback to demo data
        _rides = _demoRides;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ride History', style: AppText.h2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 14),
                        SizedBox(width: 6),
                        Text('Today', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _rides.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _rides.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                          itemBuilder: (_, i) => _rideItem(_rides[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideItem(Map<String, dynamic> ride) {
    final price = ride['price'] is int ? ride['price'] : (ride['price'] as double).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${ride['name']}'),
            backgroundColor: AppColors.primarySurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride['name'] ?? 'Passager', style: AppText.h4),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _miniChip(Icons.motorcycle, ride['type'] ?? 'Moto'),
                    _miniChip(Icons.straighten, ride['dist'] ?? '—'),
                    _miniChip(Icons.access_time, ride['time'] ?? '—'),
                    _miniChip(Icons.star, ride['rating'] ?? '5.0', color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price FCFA', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins')),
              Text(ride['date'] ?? '', style: AppText.small),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, {Color color = AppColors.textSecondary}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, color: AppColors.border, size: 64),
          const SizedBox(height: 16),
          const Text('Aucune course pour le moment', style: AppText.h3),
          const SizedBox(height: 8),
          const Text('Votre historique de courses\napparaîtra ici', style: AppText.bodySecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
