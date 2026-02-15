import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koogwz_mobile/searching_driver_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ride_tracking_screen.dart';
import 'searching_driver_screen.dart'; // ✅ AJOUTÉ
import 'config.dart';

class RidePreviewScreen extends StatefulWidget {
  final String destination;
  final String vehicleName;
  final double price;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  const RidePreviewScreen({
    Key? key, 
    required this.destination, 
    required this.vehicleName, 
    required this.price,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
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
    final url = Uri.parse('$kBaseUrl/rides'); 
    
    // Conversion du nom du véhicule en type enum backend
    String vehicleType = 'MOTO';
    if (widget.vehicleName.contains('Eco')) {
      vehicleType = 'ECO';
    } else if (widget.vehicleName.contains('Confort')) {
      vehicleType = 'CONFORT';
    }

    final Map<String, dynamic> data = {
      "originLat": widget.originLat,
      "originLng": widget.originLng,
      "destLat": widget.destLat,
      "destLng": widget.destLng,
      "price": widget.price.toDouble(),
      "vehicleType": vehicleType,
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

        // ✅ MODIFIÉ : Redirection vers SearchingDriverScreen au lieu de RideTrackingScreen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => SearchingDriverScreen(
              rideId: realRideId,
              destination: widget.destination,
              price: widget.price,
            ),
          ),
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