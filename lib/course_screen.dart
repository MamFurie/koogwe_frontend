import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'vehicle_selection_screen.dart';
import 'map_service.dart';

class CourseScreen extends StatefulWidget {
  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final TextEditingController _destController = TextEditingController();
  final MapService _mapService = MapService();
  
  bool _isSearching = false;
  GoogleMapController? _mapController;
  
  // Position de départ (sera récupérée du GPS)
  LatLng? _startPos;
  bool _loadingPosition = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _startPos = LatLng(6.1375, 1.2125); // Fallback Centre Lomé
            _loadingPosition = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _startPos = LatLng(6.1375, 1.2125); // Fallback
          _loadingPosition = false;
        });
        return;
      }

      // Obtenir la vraie position GPS
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _startPos = LatLng(position.latitude, position.longitude);
        _loadingPosition = false;
      });

      // Déplacer la caméra vers la position actuelle
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_startPos!),
      );

      print("✅ Position GPS récupérée: ${_startPos!.latitude}, ${_startPos!.longitude}");
    } catch (e) {
      print("❌ Erreur GPS: $e");
      setState(() {
        _startPos = LatLng(6.1375, 1.2125); // Fallback en cas d'erreur
        _loadingPosition = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Attendre que la position GPS soit chargée
    if (_loadingPosition || _startPos == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF6B6B)),
              SizedBox(height: 20),
              Text("Récupération de votre position...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // FOND CARTE (On garde Google Maps pour l'affichage visuel seulement, c'est gratuit sur mobile)
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _startPos!, zoom: 14.0),
            onMapCreated: (c) => _mapController = c,
            zoomControlsEnabled: false,
            myLocationEnabled: true, 
            myLocationButtonEnabled: false,
          ),
          
          Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.white, child: BackButton(color: Colors.black))),
          
          // VISEUR
          Center(child: Padding(padding: EdgeInsets.only(bottom: 200), child: Icon(Icons.location_on, color: Colors.red, size: 40))),

          // PANNEAU BAS
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Où allez-vous ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  
                  // DÉPART
                  _field(Icons.my_location, "Ma position", Colors.green, enabled: false),
                  SizedBox(height: 10),
                  
                  // DESTINATION (Champ texte)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _destController,
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Colors.red),
                        hintText: "Ex: Aéroport, Stade de Kégué...",
                        border: InputBorder.none,
                        suffixIcon: _isSearching ? Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : null
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // BOUTON "CALCULER ET CHOISIR"
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSearchAndNavigate,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF6B6B), foregroundColor: Colors.white),
                      child: Text("Choisir un véhicule", style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // LA LOGIQUE MAGIQUE 🧙‍♂️
  void _handleSearchAndNavigate() async {
    String query = _destController.text;
    if (query.isEmpty) return;

    if (_startPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'obtenir votre position"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isSearching = true);

    // 1. CHERCHER L'ADRESSE
    List<dynamic> results = await _mapService.searchPlaces(query);

    if (results.isNotEmpty) {
      // On prend le premier résultat
      var bestResult = results[0];
      double lat = double.parse(bestResult['lat']);
      double lon = double.parse(bestResult['lon']);
      String name = bestResult['display_name'].split(',')[0]; // On garde juste le nom court

      // 2. CALCULER LA DISTANCE
      double km = await _mapService.getDistanceFromRoute(_startPos!, LatLng(lat, lon));

      setState(() => _isSearching = false);

      // 3. ON NAVIGUE - AVEC LES VRAIES COORDONNÉES GPS !
      Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleSelectionScreen(
        destinationAddress: name,
        distanceKm: km,
        originLat: _startPos!.latitude,  // ✅ VRAIE POSITION
        originLng: _startPos!.longitude, // ✅ VRAIE POSITION
        destLat: lat,
        destLng: lon,
      )));

    } else {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lieu introuvable. Essayez d'être plus précis."), backgroundColor: Colors.red));
    }
  }

  Widget _field(IconData i, String t, Color c, {bool enabled = true}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Row(children: [Icon(i, color: c), SizedBox(width: 10), Text(t, style: TextStyle(color: enabled ? Colors.black : Colors.grey))]),
    );
  }
}