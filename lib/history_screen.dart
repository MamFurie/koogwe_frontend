import 'package:flutter/material.dart';
import 'ride_service.dart';
import 'socket_service.dart';
import 'theme/colors.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const HistoryScreen({Key? key, this.onBack}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _rideService = RideService();
  final _socket = SocketService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenRealTime(); // ✅ Temps réel
  }

  // ✅ Mise à jour automatique à chaque course terminée
  void _listenRealTime() {
    _socket.socket.on('trip_finished', (data) {
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _rides.insert(0, _formatRide(Map<String, dynamic>.from(data)));
        });
      }
    });
    _socket.socket.on('ride_completed', (_) {
      if (!mounted) return;
      _loadHistory();
    });
  }

  Map<String, dynamic> _formatRide(Map<String, dynamic> r) {
    final passenger = r['passenger'] ?? {};
    final driver = r['driver'] ?? {};
    final price = r['price'] is int ? r['price'] as int : ((r['price'] as num?)?.toInt() ?? 0);
    return {
      'otherName': passenger['name'] ?? driver['name'] ?? 'Utilisateur',
      'vehicleType': r['vehicleType'] ?? 'Moto',
      'price': price,
      'status': r['status'] ?? 'COMPLETED',
      'date': _formatDate(r['createdAt']),
    };
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return ''; }
  }

  Future<void> _loadHistory() async {
    final result = await _rideService.getRideHistory();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _rides = (result['rides'] as List).map((r) => _formatRide(Map<String, dynamic>.from(r))).toList();
      }
    });
  }

  @override
  void dispose() {
    _socket.off('trip_finished');
    _socket.off('ride_completed');
    super.dispose();
  }

  int get _totalEarnings => _rides.fold(0, (s, r) => s + (r['price'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        actions: [
          // ✅ Badge temps réel
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                SizedBox(width: 5),
                Text('En direct', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            )),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          if (!_isLoading && _rides.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Expanded(child: _stat('${_rides.length}', 'Courses', Icons.directions_car)),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _stat('$_totalEarnings FCFA', 'Gains totaux', Icons.attach_money)),
              ]),
            ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _rides.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rides.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => _rideItem(_rides[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) => Column(children: [
    Icon(icon, color: Colors.white70, size: 20),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);

  Widget _rideItem(Map<String, dynamic> ride) {
    final price = ride['price'] as int;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.directions_car, color: AppColors.primary),
      ),
      title: Text(ride['otherName'] ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${ride['vehicleType']} • ${ride['date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$price FCFA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Text('Terminée', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.history, color: Colors.grey, size: 64),
    const SizedBox(height: 16),
    const Text('Aucune course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Votre historique apparaîtra ici', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 24),
    TextButton.icon(onPressed: _loadHistory, icon: const Icon(Icons.refresh), label: const Text('Actualiser')),
  ]));
}
