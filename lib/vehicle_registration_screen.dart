import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_driver.dart'; // Ton écran d'accueil chauffeur
import 'theme/colors.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  @override
  _VehicleRegistrationScreenState createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs
  final _makeController = TextEditingController();  // Marque
  final _modelController = TextEditingController(); // Modèle
  final _colorController = TextEditingController(); // Couleur (Nouveau !)
  final _plateController = TextEditingController(); // Plaque
  
  bool _isLoading = false;

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    // ⚠️ Assure-toi d'avoir créé cette route dans ton Backend (UsersController)
    final url = Uri.parse('http://192.168.1.73:3000/users/update-vehicle'); 

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "vehicleMake": _makeController.text,
          "vehicleModel": _modelController.text,
          "vehicleColor": _colorController.text, // On envoie la couleur
          "licensePlate": _plateController.text,
        })
      );

      if (response.statusCode == 200) {
        // 🎉 SUCCÈS : On peut enfin entrer dans l'application
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => HomeDriver()), 
          (route) => false
        );
      } else {
        _showError("Erreur serveur: ${response.body}");
      }
    } catch (e) {
      _showError("Erreur de connexion");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Dernière étape"), 
        centerTitle: true,
        backgroundColor: Colors.white, 
        elevation: 0, 
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // Pas de retour possible, il faut remplir !
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SYMPA
              Center(
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                  child: Icon(Icons.directions_car, size: 50, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 20),
              Text("Votre Véhicule", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Ces informations aident le client à vous identifier.", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30),
              
              // CHAMPS
              _inputField("Marque", "Ex: Toyota", _makeController),
              SizedBox(height: 15),
              _inputField("Modèle", "Ex: Corolla", _modelController),
              SizedBox(height: 15),
              _inputField("Couleur", "Ex: Noir, Gris...", _colorController),
              SizedBox(height: 15),
              _inputField("Immatriculation", "Ex: TG-1234-AZ", _plateController),
              
              SizedBox(height: 40),
              
              // BOUTON TERMINER
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white) 
                    : Text("TERMINER L'INSCRIPTION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Colors.grey[50],
        prefixIcon: Icon(Icons.edit, color: Colors.grey, size: 18)
      ),
      validator: (v) => v!.isEmpty ? "Requis" : null,
    );
  }
}