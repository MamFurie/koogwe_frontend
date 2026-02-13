import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  bool _showReceived = true;

  final List<Map<String, dynamic>> _transactions = [
    {'name': 'Esther Howard', 'id': '#23242', 'method': 'Cash', 'amount': 3200, 'date': '03/15/2026'},
    {'name': 'Oliver Green', 'id': '#23243', 'method': 'Cash', 'amount': 3200, 'date': '03/15/2026'},
    {'name': 'Ethan Brown', 'id': '#23244', 'method': 'Cash', 'amount': 4500, 'date': '03/15/2026'},
    {'name': 'Aiden Clark', 'id': '#23245', 'method': 'Cash', 'amount': 3200, 'date': '03/15/2026'},
    {'name': 'James White', 'id': '#23246', 'method': 'Cash', 'amount': 5000, 'date': '03/14/2026'},
    {'name': 'Noah Harris', 'id': '#23247', 'method': 'Cash', 'amount': 6000, 'date': '03/14/2026'},
  ];

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
                  const Text('My Wallet', style: AppText.h2),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Balance card (dark)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _walletStat('89,000 FCFA', 'Payment Received', AppColors.success)),
                        Container(width: 1, height: 36, color: Colors.white24),
                        Expanded(child: _walletStat('19,000 FCFA', 'Payment Withdrew', AppColors.error)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('54,700 FCFA', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                            SizedBox(height: 2),
                            Text('Current Balance', style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(100, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Withdraw', style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Transactions section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transactions', style: AppText.h3),
                  const Text('03/15/2026', style: AppText.bodySecondary),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Toggle tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _tabBtn('Payment Received', _showReceived, () => setState(() => _showReceived = true)),
                    _tabBtn('Withdraw History', !_showReceived, () => setState(() => _showReceived = false)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Transactions list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, i) => _transactionItem(_transactions[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Poppins'), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _transactionItem(Map<String, dynamic> tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${tx['id']}'),
            backgroundColor: AppColors.primarySurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['name'], style: AppText.h4),
                Text('ID: ${tx['id']} • Method: ${tx['method']}', style: AppText.small),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+ ${tx['amount']} F', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins')),
              Text(tx['date'], style: AppText.small),
            ],
          ),
        ],
      ),
    );
  }
}
