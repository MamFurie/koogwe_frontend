import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'signup_screen.dart';
import 'home_passenger.dart'; 
import 'home_driver.dart';
import 'theme/colors.dart'; // On utilise les couleurs Koogwe

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text
    );

    setState(() => _isLoading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final name = prefs.getString('user_name') ?? "Utilisateur";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bon retour, $name ! 👋"), 
          backgroundColor: Colors.green,
        ),
      );

      if (role == 'PASSENGER') {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => HomePassenger()), 
          (route) => false 
        );
      } else if (role == 'DRIVER') {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => HomeDriver()), 
          (route) => false
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: Rôle inconnu')));
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email ou mot de passe incorrect'), 
          backgroundColor: Colors.redAccent
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fond Crème Koogwe
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: _formKey, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LOGO
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1), // Orange pâle
                        shape: BoxShape.circle
                      ),
                      child: Icon(Icons.local_taxi, size: 60, color: AppColors.primary), // Orange Koogwe
                    ),
                  ),
                  SizedBox(height: 30),

                  // TEXTES
                  Text("Content de vous revoir !", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 10),
                  Text("Connectez-vous pour continuer vos courses.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  
                  SizedBox(height: 40),

                  // CHAMP EMAIL
                  Text("Email", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 8),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "exemple@email.com",
                        border: InputBorder.none,
                        icon: Icon(Icons.email_outlined, color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Entrez votre email';
                        if (!value.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: 20),

                  // CHAMP MOT DE PASSE
                  Text("Mot de passe", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 8),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        border: InputBorder.none,
                        icon: Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Entrez votre mot de passe';
                        if (value.length < 6) return 'Mot de passe trop court';
                        return null;
                      },
                    ),
                  ),

                  // MOT DE PASSE OUBLIÉ
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text("Mot de passe oublié ?", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  SizedBox(height: 20),

                  // BOUTON DE CONNEXION (Orange Koogwe)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // L'orange défini dans colors.dart
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("SE CONNECTER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  SizedBox(height: 30),

                  // INSCRIPTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Pas encore de compte ? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignupScreen()));
                        },
                        child: Text("Créer un compte", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // SOCIAL
                  Center(child: Text("Ou connectez-vous avec", style: TextStyle(color: Colors.grey[400]))),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialButton(Icons.g_mobiledata, Colors.red),
                      _socialButton(Icons.apple, Colors.black),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Design des champs (Fond blanc + Ombre douce)
  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}