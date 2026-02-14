import 'package:flutter/material.dart';
import 'ride_preview_screen.dart'; 

class VehicleSelectionScreen extends StatefulWidget {
  // On reçoit ces 2 infos venant de l'écran précédent (CourseScreen)
  final String destinationAddress;
  final double distanceKm; 

  const VehicleSelectionScreen({
    Key? key, 
    required this.destinationAddress,
    required this.distanceKm, 
  }) : super(key: key);

  @override
  _VehicleSelectionScreenState createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  int _selIndex = 1; // Par défaut, on sélectionne "Eco"

  // 💰 TA FORMULE DE PRIX (Modifie les chiffres ici si tu veux changer les tarifs)
  final double prixMotoPerKm = 150.0;
  final double prixEcoPerKm = 300.0;
  final double prixConfortPerKm = 500.0;
  
  // Prise en charge (Prix de départ fixe, pour être réaliste)
  final double baseFare = 200.0; 

  @override
  Widget build(BuildContext context) {
    // ON PRÉPARE LES DONNÉES DYNAMIQUES
    // On calcule le prix pour chaque type de véhicule selon la distance
    
    final List<Map<String, dynamic>> _vehicules = [
      {
        "name": "MOTO", 
        // Formule : (Distance * 150) + 200
        "price": ((widget.distanceKm * prixMotoPerKm) + baseFare).toStringAsFixed(0), 
        "icon": Icons.two_wheeler, 
        "color": Colors.blue,
        "time": "${(widget.distanceKm * 2.5).toInt()} min" // Est. 2.5 min par km
      },
      {
        "name": "KOOGWE Eco", 
        // Formule : (Distance * 300) + 200
        "price": ((widget.distanceKm * prixEcoPerKm) + baseFare).toStringAsFixed(0), 
        "icon": Icons.local_taxi, 
        "color": Colors.green,
        "time": "${(widget.distanceKm * 3).toInt()} min" // Auto un peu plus lente en ville
      },
      {
        "name": "KOOGWE Confort", 
        // Formule : (Distance * 500) + 200 + 500 (Bonus Clim/Luxe)
        "price": ((widget.distanceKm * prixConfortPerKm) + baseFare + 500).toStringAsFixed(0), 
        "icon": Icons.stars, 
        "color": Colors.deepOrange,
        "time": "${(widget.distanceKm * 3).toInt()} min"
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9), // Fond très léger
      appBar: AppBar(
        title: Text("Choisir un véhicule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true,
        leading: BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. RÉSUMÉ DU TRAJET (Bandeau gris en haut)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.deepOrange),
                SizedBox(width: 15),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Vers : ${widget.destinationAddress}", style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Distance totale : ${widget.distanceKm.toStringAsFixed(1)} km", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),
          
          // 2. LISTE DES VÉHICULES
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(20),
              itemCount: _vehicules.length,
              separatorBuilder: (_, __) => SizedBox(height: 15),
              itemBuilder: (ctx, i) {
                final v = _vehicules[i];
                bool isSelected = _selIndex == i;

                return GestureDetector(
                  onTap: () => setState(() => _selIndex = i),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFFFF0E3) : Colors.white, // Fond Orange pâle si sélectionné
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected ? Border.all(color: Colors.deepOrange, width: 2) : Border.all(color: Colors.transparent),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))]
                    ),
                    child: Row(children: [
                      // Icône colorée
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: (v['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(v['icon'], color: v['color'], size: 28),
                      ),
                      SizedBox(width: 15),
                      
                      // Nom et Temps
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(v['time'], style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ]),
                        ],
                      )),
                      
                      // PRIX CALCULÉ
                      Text("${v['price']} FCFA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                    ]),
                  ),
                );
              },
            ),
          ),
          
          // 3. BOUTON CONTINUER
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // ON RÉCUPÈRE LE VÉHICULE CHOISI
                  final selectedCar = _vehicules[_selIndex];
                  
                  // ON ENVOIE TOUT À L'ÉCRAN SUIVANT (Aperçu)
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RidePreviewScreen(
                    destination: widget.destinationAddress,
                    vehicleName: selectedCar['name'],
                    // Important : On convertit le prix "String" en "double" pour le backend
                    price: double.parse(selectedCar['price']),
                  )));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5
                ),
                child: Text("CONFIRMER LA COMMANDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}