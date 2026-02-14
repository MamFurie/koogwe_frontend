import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ride_tracking_screen.dart';

class RidePreviewScreen extends StatefulWidget {
  final String destination;
  final String vehicleName;
  final double price;

  const RidePreviewScreen({
    Key? key, 
    required this.destination, 
    required this.vehicleName, 
    required this.price
  }) : super(key: key);

  @override
  _RidePreviewScreenState createState() => _RidePreviewScreenState();
}

class _RidePreviewScreenState extends State<RidePreviewScreen> {
  bool _isLoading = false;

  Future<void> _submitOrder() async {
    setState(() => _isLoading = true);

    print("🔵 DÉBUT DE LA COMMANDE...");

    // 1. VÉRIFICATION DU TOKEN
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token == null) {
      print("🔴 ERREUR : Aucun token trouvé dans le téléphone !");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: Non connecté. Relancez l'appli."), backgroundColor: Colors.red));
      return;
    }
    print("🟢 Token trouvé : ${token.substring(0, 10)}..."); // On affiche juste le début

    // 2. PRÉPARATION DES DONNÉES
    // ⚠️ ATTENTION : Vérifie bien que cette IP est celle de ton PC (ipconfig)
    final url = Uri.parse('http://192.168.1.73:3000/rides'); 
    
    // On s'assure que les chiffres sont bien des chiffres (pas de texte)
    final Map<String, dynamic> data = {
      "originLat": 6.1375,
      "originLng": 1.2125,
      "destLat": 6.1750,
      "destLng": 1.2300,
      "price": widget.price.toDouble() // Force en nombre à virgule
    };

    print("🔵 Envoi des données au serveur : $data");

    try {
      // 3. ENVOI DE LA REQUÊTE
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // La clé magique
        },
        body: jsonEncode(data)
      );

      print("🔵 Réponse Serveur : Code ${response.statusCode}");
      print("🔵 Corps de la réponse : ${response.body}");

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // SUCCÈS
        final responseData = jsonDecode(response.body);
        final String realRideId = responseData['id']; 

        print("✅ SUCCÈS TOTAL ! ID Course : $realRideId");

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: realRideId))
        );
      } else {
        // ÉCHEC SERVEUR (400, 401, 500...)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur Serveur (${response.statusCode}) : ${response.body}"),
          backgroundColor: Colors.orange
        ));
      }
    } catch (e) {
      // ÉCHEC CONNEXION (Internet coupé, mauvaise IP...)
      setState(() => _isLoading = false);
      print("🔴 CRASH CONNEXION : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Impossible de joindre le serveur. Vérifiez l'IP."),
        backgroundColor: Colors.red
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      appBar: AppBar(title: Text("Confirmer", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Résumé
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(children: [
                Text("Destination", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5),
                Text(widget.destination, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Divider(height: 30),
                Text("Prix Total", style: TextStyle(color: Colors.grey)),
                Text("${widget.price.toInt()} FCFA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
            ),
            Spacer(),
            // BOUTON
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("COMMANDER MAINTENANT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}