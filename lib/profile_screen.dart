import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'config.dart';
import 'login_screen.dart';
import 'theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDriver;
  final VoidCallback? onBack;
  const ProfileScreen({Key? key, this.isDriver = false, this.onBack}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString(kKeyUserName) ?? 'Utilisateur';
      _email = prefs.getString(kKeyUserEmail) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                    style: TextStyle(color: AppColors.primary, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                )),
              ],
            )),
            const SizedBox(height: 12),
            Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                widget.isDriver ? 'Chauffeur Koogwz' : 'Passager Koogwz',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),

            const SizedBox(height: 30),

            // Stats rapides
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _quickStat('0', widget.isDriver ? 'Courses' : 'Courses', Icons.directions_car, AppColors.primary),
                _quickStat('4.9', 'Note', Icons.star, Colors.amber),
                _quickStat('0', widget.isDriver ? 'FCFA gagnés' : 'FCFA dépensés', Icons.attach_money, Colors.green),
              ]),
            ),

            const SizedBox(height: 24),

            // Menu
            _section('Compte'),
            _item(Icons.person_outline, 'Modifier le profil', () => _editDialog()),
            _item(Icons.phone_outlined, 'Numéro de téléphone', () {}),
            _item(Icons.lock_outline, 'Changer le mot de passe', () {}),

            const SizedBox(height: 16),

            _section('Préférences'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Icon(Icons.notifications_outlined, color: AppColors.primary)),
              title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v), activeColor: AppColors.primary),
            ),
            _item(Icons.help_outline, 'Aide & Support', () {}),
            _item(Icons.info_outline, 'À propos de Koogwz', () => _aboutDialog()),

            const SizedBox(height: 24),

            // Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await _logoutDialog();
                  if (confirm == true && mounted) {
                    await AuthService().logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String value, String label, IconData icon, Color color) => Column(children: [
    Icon(icon, color: color, size: 24),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
  ]);

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
  );

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Icon(icon, color: AppColors.primary, size: 20)),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    onTap: onTap,
  );

  void _editDialog() {
    final ctrl = TextEditingController(text: _name);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Modifier le profil', style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom complet')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(kKeyUserName, ctrl.text);
            setState(() => _name = ctrl.text);
            if (mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _aboutDialog() => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Koogwz', style: TextStyle(fontWeight: FontWeight.bold)),
    content: const Text('Application de ride-hailing pour Lomé, Togo.\n\nVersion 1.0.0\n© 2026 Koogwz'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: AppColors.primary)))],
  ));

  Future<bool?> _logoutDialog() => showDialog<bool>(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Déconnexion', style: TextStyle(color: Colors.white))),
    ],
  ));
}
