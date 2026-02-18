import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'document_upload_screen.dart';
import 'login_options_screen.dart';
import 'theme/colors.dart';

class PendingValidationScreen extends StatefulWidget {
  @override
  _PendingValidationScreenState createState() => _PendingValidationScreenState();
}

class _PendingValidationScreenState extends State<PendingValidationScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  String _driverName = 'Chauffeur';

  @override
  void initState() {
    super.initState();
    _loadName();
    _pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1800))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 2400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _driverName = prefs.getString('user_name') ?? 'Chauffeur');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Se déconnecter ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Vous pourrez vous reconnecter plus tard pour vérifier votre statut.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginOptionsScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              // Top - logout
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, size: 18, color: Colors.grey),
                  label: Text('Déconnexion', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Spacer(),

              // Animated illustration
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFF3E0),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 30, offset: Offset(0, 10))],
                      ),
                      child: Center(child: Text('⏳', style: TextStyle(fontSize: 68))),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 36),

              Text(
                'Bonjour, $_driverName !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3436)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text('Compte en cours de vérification', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              SizedBox(height: 24),

              Text(
                'Vos documents ont été soumis avec succès. Notre équipe les examine actuellement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.6),
              ),
              SizedBox(height: 32),

              // Timeline
              _timelineStep(
                icon: '✅', label: 'Inscription complète',
                sublabel: 'Compte créé', done: true,
              ),
              _timelineStep(
                icon: '📸', label: 'Vérification faciale',
                sublabel: 'Identité confirmée', done: true,
              ),
              _timelineStep(
                icon: '📄', label: 'Documents soumis',
                sublabel: 'En attente de révision', done: true,
              ),
              _timelineStep(
                icon: '🔍', label: 'Examen admin',
                sublabel: 'Temps estimé : 24–48 heures', done: false, isCurrent: true,
              ),
              _timelineStep(
                icon: '🎉', label: 'Compte activé !',
                sublabel: 'Vous pouvez accepter des courses', done: false, isLast: true,
              ),

              Spacer(),

              // Info box
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous recevrez une notification dès que votre compte sera approuvé.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Upload more docs
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentUploadScreen())),
                icon: Icon(Icons.upload_file, size: 18),
                label: Text('Ajouter / modifier des documents'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineStep({
    required String icon, required String label, required String sublabel,
    bool done = false, bool isCurrent = false, bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.green.withOpacity(0.12) : isCurrent ? AppColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                border: Border.all(
                  color: done ? Colors.green.withOpacity(0.5) : isCurrent ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade200,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: 16))),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: done ? Colors.green.withOpacity(0.3) : Colors.grey.shade200),
          ],
        ),
        SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: done || isCurrent ? Color(0xFF2D3436) : Colors.grey[400])),
                Text(sublabel, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
        if (done) Padding(padding: EdgeInsets.only(top: 8), child: Icon(Icons.check_circle, color: Colors.green, size: 18)),
        if (isCurrent) Padding(
          padding: EdgeInsets.only(top: 10),
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        ),
      ],
    );
  }
}
