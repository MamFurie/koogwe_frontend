import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Juste pour le type LatLng

class MapService {
  // 1. RECHERCHE D'ADRESSE (Gratuit via Nominatim)
  Future<List<dynamic>> searchPlaces(String query) async {
    // On ajoute "Lomé" pour préciser la recherche au Togo
    String q = Uri.encodeComponent("$query Lomé Togo"); 
    String url = "https://nominatim.openstreetmap.org/search?q=$q&format=json&addressdetails=1&limit=5";

    try {
      // Il est important d'ajouter un User-Agent pour respecter les règles d'OSM
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'KoogweApp/1.0 (contact@koogwe.com)' 
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Erreur Recherche: $e");
    }
    return [];
  }

  // 2. CALCUL DISTANCE (Gratuit via OSRM)
  Future<double> getDistanceFromRoute(LatLng start, LatLng end) async {
    String url = "http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=false";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // La distance est en mètres, on convertit en KM
          double meters = data['routes'][0]['distance'];
          return meters / 1000.0; 
        }
      }
    } catch (e) {
      print("Erreur Distance: $e");
    }
    return 0.0;
  }
}