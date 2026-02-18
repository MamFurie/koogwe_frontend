import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'login_options_screen.dart';
import 'signup_screen.dart';
import 'home_passenger.dart';
import 'home_driver.dart';
import 'verification_screen.dart';
import 'face_verification_screen.dart';
import 'document_upload_screen.dart';
import 'pending_validation_screen.dart';
import 'config.dart';
import 'theme/colors.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Veuillez remplir tous les champs', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);

    final success = await _authService.login(_emailController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);

    if (!success) {
      _showSnack('Email ou mot de passe incorrect', Colors.redAccent);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(kKeyUserRole);
    final name = prefs.getString(kKeyUserName) ?? 'Utilisateur';

    if (!mounted) return;

    _showSnack('Bon retour, $name ! 👋', Colors.green);

    if (role == 'PASSENGER') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePassenger()), (r) => false);
    } else if (role == 'DRIVER') {
      // Check driver onboarding status
      final faceVerified = prefs.getBool('face_verified') ?? false;
      final docsUploaded = prefs.getBool('documents_uploaded') ?? false;

      if (!faceVerified) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => FaceVerificationScreen()), (r) => false);
      } else if (!docsUploaded) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => DocumentUploadScreen()), (r) => false);
      } else {
        // Check if admin-approved via backend (simplified: show pending or home)
        // TODO: Add server-side check for adminApproved flag
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PendingValidationScreen()), (r) => false);
      }
    } else {
      _showSnack('Erreur: Rôle inconnu', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                // Logo
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 18, offset: Offset(0, 6))],
                    ),
                    child: Icon(Icons.local_taxi_rounded, size: 46, color: Colors.white),
                  ),
                ),
                SizedBox(height: 28),
                Text('Content de vous revoir !', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 8),
                Text('Connectez-vous pour continuer.', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                SizedBox(height: 36),

                // EMAIL
                _label('Email'),
                _inputBox(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(hintText: 'exemple@email.com', border: InputBorder.none, icon: Icon(Icons.email_outlined, color: Colors.grey)),
                  ),
                ),
                SizedBox(height: 16),

                // PASSWORD
                _label('Mot de passe'),
                _inputBox(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••', border: InputBorder.none,
                      icon: Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),

                SizedBox(height: 10),

                // Login button
                SizedBox(
                  width: double.infinity, height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      elevation: 6, shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('SE CONNECTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Pas encore de compte ? ', style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen())),
                      child: Text('Créer un compte', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                SizedBox(height: 32),
                Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(color: Colors.grey[400]))), Expanded(child: Divider())]),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _socialBtn(Icons.g_mobiledata, Colors.red),
                    _socialBtn(Icons.apple, Colors.black),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
  );

  Widget _inputBox({required Widget child}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _socialBtn(IconData icon, Color color) => Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)]),
    child: Icon(icon, color: color, size: 30),
  );
}
