import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'home_passenger.dart'; // L'écran d'accueil Passager
import 'vehicle_registration_screen.dart'; // L'écran d'enregistrement voiture
import 'theme/colors.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Contrôleurs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'PASSENGER'; // Par défaut
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- LOGIQUE D'INSCRIPTION & REDIRECTION ---
  void _submit() async {
    // 1. Validation basique
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veuillez remplir tous les champs obligatoires"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    
    // 2. Tentative d'inscription
    final registerSuccess = await _authService.register(
      _nameController.text.trim(), 
      _emailController.text.trim(), 
      _passwordController.text, 
      _phoneController.text.trim(), 
      _selectedRole
    );
    
    if (registerSuccess) {
      print("✅ Inscription réussie, tentative de connexion automatique...");

      // 3. AUTO-LOGIN (Le secret pour une UX fluide)
      // On connecte l'utilisateur tout de suite pour récupérer le Token
      final loginSuccess = await _authService.login(
        _emailController.text.trim(), 
        _passwordController.text
      );

      setState(() => _isLoading = false);

      if (loginSuccess) {
        // 4. REDIRECTION SELON LE RÔLE
        if (_selectedRole == 'DRIVER') {
          // 🚖 CHAUFFEUR -> On va enregistrer la voiture
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => VehicleRegistrationScreen()), 
            (route) => false
          );
        } else {
          // 👤 PASSAGER -> On va à l'accueil
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => HomePassenger()), 
            (route) => false
          );
        }
      } else {
        // Si l'inscription marche mais pas le login (rare)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      }

    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur d'inscription. Cet email est peut-être déjà utilisé."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO
                Center(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.person_add, size: 50, color: AppColors.primary),
                  ),
                ),
                SizedBox(height: 20),

                // TITRES
                Text("Bienvenue chez Koogwe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Créez votre compte en quelques secondes.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 30),
                
                // FORMULAIRE
                _label("Nom complet"),
                _buildInputContainer(
                  child: TextField(
                    controller: _nameController,
                    decoration: _inputDeco("Votre nom", Icons.person),
                  )
                ),
                SizedBox(height: 15),

                _label("Email"),
                _buildInputContainer(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDeco("exemple@email.com", Icons.email),
                  )
                ),
                SizedBox(height: 15),

                _label("Téléphone"),
                _buildInputContainer(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco("+228 90 00 00 00", Icons.phone),
                  )
                ),
                SizedBox(height: 15),

                _label("Mot de passe"),
                _buildInputContainer(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "••••••••",
                      border: InputBorder.none,
                      icon: Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  )
                ),
                SizedBox(height: 15),
                
                // SÉLECTEUR DE RÔLE (Passager / Chauffeur)
                _label("Je veux m'inscrire comme"),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      items: [
                        DropdownMenuItem(
                          value: 'PASSENGER', 
                          child: Row(children: [Icon(Icons.person, color: Colors.grey), SizedBox(width: 10), Text("Passager")])
                        ),
                        DropdownMenuItem(
                          value: 'DRIVER', 
                          child: Row(children: [Icon(Icons.directions_car, color: AppColors.primary), SizedBox(width: 10), Text("Chauffeur", style: TextStyle(fontWeight: FontWeight.bold))])
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ),
                ),

                SizedBox(height: 30),
                
                // BOUTON S'INSCRIRE
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? CircularProgressIndicator(color: Colors.white) 
                      : Text(_selectedRole == 'DRIVER' ? "SUIVANT ➔" : "S'INSCRIRE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                SizedBox(height: 20),

                // LIEN LOGIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                      child: Text("Se connecter", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Styles
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      border: InputBorder.none,
      icon: Icon(icon, color: Colors.grey),
    );
  }
}