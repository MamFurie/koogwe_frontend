import 'package:flutter/material.dart';
import 'ride_service.dart';
import 'socket_service.dart';
import 'theme/colors.dart';

class WalletScreen extends StatefulWidget {
  final String driverId;
  final VoidCallback? onBack;
  const WalletScreen({Key? key, this.driverId = '', this.onBack}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _rideService = RideService();
  final _socket = SocketService();
  bool _isLoading = true;
  bool _showReceived = true;
  List<Map<String, dynamic>> _transactions = [];
  int _totalReceived = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenRealTime(); // ✅ Temps réel
  }

  // ✅ Mise à jour instantanée quand une course se termine
  void _listenRealTime() {
    _socket.socket.on('trip_finished', (data) {
      if (!mounted || data == null) return;
      final price = (data['price'] as num?)?.toInt() ?? 0;
      setState(() {
        _totalReceived += price;
        _transactions.insert(0, {
          'name': data['passenger']?['name'] ?? 'Passager',
          'id': '#${data['id']?.toString().substring(0, 5) ?? '00000'}',
          'method': 'Cash',
          'amount': price,
          'date': _today(),
        });
      });
    });
  }

  Future<void> _loadData() async {
    final result = await _rideService.getRideHistory();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final rides = result['rides'] as List? ?? [];
        _transactions = rides.map((r) {
          final passenger = r['passenger'] ?? {};
          final price = (r['price'] as num?)?.toInt() ?? 0;
          return {
            'name': passenger['name'] ?? 'Passager',
            'id': '#${r['id']?.toString().substring(0, 5) ?? '00000'}',
            'method': 'Cash',
            'amount': price,
            'date': _formatDate(r['createdAt']),
          };
        }).toList();
        _totalReceived = _transactions.fold(0, (s, t) => s + (t['amount'] as int));
      }
    });
  }

  String _formatDate(dynamic d) {
    if (d == null) return _today();
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return _today(); }
  }

  String _today() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  @override
  void dispose() {
    _socket.off('trip_finished');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        actions: [
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
          // Carte solde
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: _walletStat('$_totalReceived FCFA', 'Reçu', Colors.green)),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(child: _walletStat('0 FCFA', 'Retiré', Colors.red)),
              ]),
              const Divider(color: Colors.white24, height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_totalReceived FCFA', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const Text('Solde actuel', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrait via Mobile Money — bientôt disponible'))),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Retirer', style: TextStyle(color: Colors.white)),
                ),
              ]),
            ]),
          ),

          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                _tab('Paiements reçus', _showReceived, () => setState(() => _showReceived = true)),
                _tab('Retraits', !_showReceived, () => setState(() => _showReceived = false)),
              ]),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _transactions.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        const Text('Aucune transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Vos paiements apparaîtront ici', style: TextStyle(color: Colors.grey)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _txItem(_transactions[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _walletStat(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
  ]);

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ),
    ),
  );

  Widget _txItem(Map<String, dynamic> tx) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    leading: CircleAvatar(
      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${tx['id']}'),
      backgroundColor: Colors.grey[200],
    ),
    title: Text(tx['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('ID: ${tx['id']} • ${tx['method']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('+ ${tx['amount']} FCFA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
      Text(tx['date'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]),
  );
}
