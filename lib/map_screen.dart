import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc; // Utilisation d'un alias pour éviter les conflits
import 'ride_service.dart'; 

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  
  // Correction 1 : Utilisation de la vraie classe Location du package
  final loc.Location _location = loc.Location();
  
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  LatLng? _destinationPosition;

  static const CameraPosition _lome = CameraPosition(
    target: LatLng(6.1375, 1.2125),
    zoom: 14.0,
  );

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _locateUser(); 
  }

  // 1. GESTION DU GPS
  Future<void> _locateUser() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) return;
    }

    final locData = await _location.getLocation();
    
    // Correction 2 : On vérifie que les coordonnées ne sont pas nulles
    if (locData.latitude == null || locData.longitude == null) return;

    setState(() {
      _currentPosition = LatLng(locData.latitude!, locData.longitude!);
      
      // Mise à jour du marqueur "MOI"
      _markers.removeWhere((m) => m.markerId.value == 'moi');
      _markers.add(
        Marker(
          markerId: MarkerId('moi'),
          position: _currentPosition!,
          infoWindow: InfoWindow(title: "Ma Position"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
  }

  // 2. QUAND ON CLIQUE SUR LA CARTE
  void _onMapTapped(LatLng position) {
    setState(() {
      _destinationPosition = position;
      
      // Correction 3 : On remplace l'ancien marqueur destination s'il existe
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: position,
          infoWindow: InfoWindow(title: "Destination"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  // 3. ENVOYER LA COMMANDE
  void _orderRide() async {
    if (_currentPosition == null || _destinationPosition == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recherche d'un chauffeur... 🚕"))
    );

    // Note : RideService doit être implémenté dans ride_service.dart
   bool success = (await 
   RideService().createRide(
      originLat: _currentPosition!.latitude,
      originLng: _currentPosition!.longitude,
      destLat: _destinationPosition!.latitude,
      destLng: _destinationPosition!.longitude,
      price: 1500.0,
    )) as bool;

    if (mounted) { // Sécurité pour éviter les erreurs si l'écran est fermé pendant l'appel
      if (success == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Succès !"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 50),
                SizedBox(height: 10),
                Text("Votre chauffeur a été contacté."),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigator.pop(context); // Décommente si tu veux fermer la carte
                },
                child: Text("OK"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur de connexion serveur"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _lome,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true, 
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onTap: _onMapTapped,
          ),

          // BOUTON RETOUR
          Positioned(
            top: 50, left: 20,
            child: GestureDetector( // Plus propre que InkWell ici
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]
                ),
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // PANNEAU DE COMMANDE
          if (_destinationPosition != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Course Standard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Prix estimé: 1500 FCFA", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: _orderRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("COMMANDER MAINTENANT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      
      floatingActionButton: _destinationPosition == null ? FloatingActionButton(
        onPressed: _locateUser,
        backgroundColor: Colors.white,
        child: Icon(Icons.gps_fixed, color: Colors.blue),
      ) : null,
    );
  }
}

// Suppression de la classe vide "Location" en bas qui créait un conflit avec le package