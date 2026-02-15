import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'config.dart';
import 'course_screen.dart';
import 'history_screen.dart';
// ❌ SUPPRIMÉ : import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'ride_service.dart';
import 'theme/colors.dart';

class HomePassenger extends StatefulWidget {
  @override
  _HomePassengerState createState() => _HomePassengerState();
}

class _HomePassengerState extends State<HomePassenger> {
  String userName = 'Chargement...';
  int _navIndex = 0;
  List<Map<String, dynamic>> _recentRides = [];
  bool _loadingRides = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadRecentRides();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userName = prefs.getString(kKeyUserName) ?? 'Client');
  }

  Future<void> _loadRecentRides() async {
    setState(() => _loadingRides = true);
    final result = await RideService().getRideHistory();
    if (!mounted) return;
    setState(() {
      _loadingRides = false;
      if (result['success'] == true) {
        final all = result['rides'] as List? ?? [];
        _recentRides = all.take(3).map((r) {
          final driver = r['driver'] ?? {};
          final price = (r['price'] as num?)?.toInt() ?? 0;
          return {
            'driverName': driver['name'] ?? 'Chauffeur',
            'price': price,
            'date': _formatDate(r['createdAt']),
          };
        }).toList();
      }
    });
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    // Navigation entre les onglets (WALLET SUPPRIMÉ)
    // ❌ SUPPRIMÉ : if (_navIndex == 1) return WalletScreen(...)
    if (_navIndex == 1) return HistoryScreen(onBack: () => setState(() => _navIndex = 0));
    if (_navIndex == 2) return ProfileScreen(isDriver: false, onBack: () => setState(() => _navIndex = 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { await _loadRecentRides(); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EN-TÊTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bonjour 👋', style: TextStyle(color: Colors.grey)),
                      Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ]),
                    GestureDetector(
                      onTap: () => setState(() => _navIndex = 2),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats rapides
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _buildStat(Icons.directions_car, '${_recentRides.length}', 'Courses', Colors.orange),
                    _buildStat(Icons.history, '${_recentRides.length}', 'Historique', Colors.teal),
                    _buildStat(Icons.star, '4.9', 'Note', Colors.amber),
                  ]),
                ),

                const SizedBox(height: 20),

                // Bouton prendre une course (grand CTA)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.search, color: Colors.white, size: 28),
                      SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Où allez-vous ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Trouvez un chauffeur maintenant', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // ✅ GRILLE 2x2 SANS WALLET
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.4,
                  children: [
                    _buildServiceCard(context, 'Course', Icons.directions_car, AppColors.serviceCourse, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CourseScreen()));
                    }),
                    _buildServiceCard(context, 'Historique', Icons.history, AppColors.servicePlanifier, () {
                      setState(() => _navIndex = 1);
                    }),
                    _buildServiceCard(context, 'Profil', Icons.person, AppColors.serviceServices, () {
                      setState(() => _navIndex = 2);
                    }),
                    // ✅ 4ème case : Support ou autre service
                    _buildServiceCard(context, 'Support', Icons.headset_mic, AppColors.serviceCovoit, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support disponible bientôt'))
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // Courses récentes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Courses récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _navIndex = 1),
                      child: Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_loadingRides)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (_recentRides.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                    child: Row(children: [
                      Icon(Icons.directions_car, color: AppColors.primary, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Aucune course récente', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Votre historique apparaîtra ici', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ])),
                    ]),
                  )
                else
                  ..._recentRides.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Icon(Icons.person, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Course avec ${r['driverName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(r['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ])),
                      Text('${r['price']} FCFA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  )),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      // ✅ BARRE DE NAVIGATION SANS WALLET
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String val, String label, Color color) => Column(children: [
    Icon(icon, color: color),
    const SizedBox(height: 5),
    Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  ]);

  Widget _buildServiceCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }
}