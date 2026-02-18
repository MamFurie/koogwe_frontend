import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'login_options_screen.dart';
import 'home_passenger.dart';
import 'face_verification_screen.dart';
import 'theme/colors.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'PASSENGER';
  String _selectedCountryCode = '+228';
  String _selectedCountryFlag = '🇹🇬';
  String _selectedCountry = 'Togo';

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<Map<String, String>> _countries = [
    {'flag': '🇹🇬', 'name': 'Togo', 'code': '+228'},
    {'flag': '🇧🇯', 'name': 'Bénin', 'code': '+229'},
    {'flag': '🇨🇮', 'name': "Côte d'Ivoire", 'code': '+225'},
    {'flag': '🇬🇭', 'name': 'Ghana', 'code': '+233'},
    {'flag': '🇸🇳', 'name': 'Sénégal', 'code': '+221'},
    {'flag': '🇳🇬', 'name': 'Nigeria', 'code': '+234'},
    {'flag': '🇫🇷', 'name': 'France', 'code': '+33'},
    {'flag': '🇺🇸', 'name': 'États-Unis', 'code': '+1'},
    {'flag': '🇪🇸', 'name': 'Espagne', 'code': '+34'},
    {'flag': '🇧🇷', 'name': 'Brésil', 'code': '+55'},
  ];

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 16),
            Text('Sélectionnez votre pays', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (_, i) {
                  final c = _countries[i];
                  return ListTile(
                    leading: Text(c['flag']!, style: TextStyle(fontSize: 28)),
                    title: Text(c['name']!, style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(c['code']!, style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      setState(() {
                        _selectedCountry = c['name']!;
                        _selectedCountryCode = c['code']!;
                        _selectedCountryFlag = c['flag']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Veuillez remplir tous les champs obligatoires', Colors.orange);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Les mots de passe ne correspondent pas', Colors.red);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Le mot de passe doit contenir au moins 6 caractères', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    final registerSuccess = await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      phone,
      _selectedRole,
    );

    if (registerSuccess) {
      final loginSuccess = await _authService.login(_emailController.text.trim(), _passwordController.text);
      setState(() => _isLoading = false);

      if (loginSuccess) {
        if (_selectedRole == 'DRIVER') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => FaceVerificationScreen()), (r) => false);
        } else {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePassenger()), (r) => false);
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      }
    } else {
      setState(() => _isLoading = false);
      _showSnack("Erreur d'inscription. Cet email est peut-être déjà utilisé.", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Créer un compte', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAYS
            _label('🌍 Pays'),
            GestureDetector(
              onTap: _showCountryPicker,
              child: _buildContainer(
                child: Row(
                  children: [
                    Text(_selectedCountryFlag, style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(child: Text('$_selectedCountry ($_selectedCountryCode)', style: TextStyle(fontSize: 16))),
                    Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),

            // NOM
            _label('👤 Nom complet'),
            _buildContainer(child: _field(_nameController, 'Votre nom complet', Icons.person_outline)),
            SizedBox(height: 14),

            // TÉLÉPHONE
            _label('📞 Téléphone'),
            _buildContainer(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: Text('$_selectedCountryFlag $_selectedCountryCode', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(hintText: '90 00 00 00', border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),

            // EMAIL
            _label('📧 Email'),
            _buildContainer(child: _field(_emailController, 'exemple@email.com', Icons.email_outlined, TextInputType.emailAddress)),
            SizedBox(height: 14),

            // MOT DE PASSE
            _label('🔒 Mot de passe'),
            _buildContainer(
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
            SizedBox(height: 14),

            // CONFIRMER MOT DE PASSE
            _label('🔒 Confirmer le mot de passe'),
            _buildContainer(
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••', border: InputBorder.none,
                  icon: Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // RÔLE
            _label('👤 Je veux m\'inscrire comme'),
            Row(
              children: [
                Expanded(child: _roleCard('PASSENGER', '🧍', 'Passager')),
                SizedBox(width: 12),
                Expanded(child: _roleCard('DRIVER', '🚗', 'Chauffeur')),
              ],
            ),
            SizedBox(height: 30),

            // BOUTON
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
                  : Text(_selectedRole == 'DRIVER' ? 'SUIVANT →' : "S'INSCRIRE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                  child: Text('Se connecter', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(String role, String emoji, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : Colors.black87, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14)),
  );

  Widget _buildContainer({required Widget child}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, [TextInputType? type]) => TextField(
    controller: ctrl, keyboardType: type,
    decoration: InputDecoration(hintText: hint, border: InputBorder.none, icon: Icon(icon, color: Colors.grey)),
  );
}
