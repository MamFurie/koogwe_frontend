import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'theme/colors.dart'; // On utilise les couleurs Koogwe

class VerificationScreen extends StatefulWidget {
  final String email;
  VerificationScreen({required this.email});
  
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _submit() async {
    if (_codeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Code incomplet"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await _authService.verifyCode(widget.email, _codeController.text);
    
    setState(() => _isLoading = false);

    if (success) {
      // Succès : On affiche une popup verte et on va au Login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Compte vérifié !", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Vous pouvez maintenant vous connecter.", textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Ferme la popup
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: Text("SE CONNECTER", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Code invalide ou expiré"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fond Crème
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONE ENVELOPPE
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read, size: 60, color: AppColors.primary),
              ),
              
              SizedBox(height: 30),

              Text("Vérifiez votre email", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 10),
              Text("Nous avons envoyé un code à 4 chiffres à :", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              Text(widget.email, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              
              SizedBox(height: 40),

              // CHAMP DE CODE STYLISÉ
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 20, color: AppColors.primary),
                  decoration: InputDecoration(
                    counterText: "", // Cache le compteur "0/4"
                    border: InputBorder.none,
                    hintText: "0000",
                    hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 20),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // BOUTON VALIDER
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
                    : Text("VÉRIFIER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 20),

              // RENVOYER LE CODE
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Code renvoyé !")));
                  // TODO: Appeler authService.resendCode(widget.email)
                },
                child: Text("Je n'ai rien reçu ? Renvoyer", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}