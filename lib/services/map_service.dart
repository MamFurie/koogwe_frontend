import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String _osrmUrl = 'https://router.project-osrm.org';
  static const String _userAgent = 'KoogwzApp/1.0 (contact@koogwz.app)';

  // ---- Chercher une adresse ----
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=tg',
        ),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        return results.map((r) => {
          'name': r['display_name'],
          'lat': double.parse(r['lat']),
          'lng': double.parse(r['lon']),
        }).toList();
      }
    } catch (e) {
      print('Erreur recherche adresse: $e');
    }
    return [];
  }

  // ---- Adresse inverse (coordonnées → texte) ----
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_nominatimUrl/reverse?lat=$lat&lon=$lng&format=json'),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      print('Erreur reverse geocoding: $e');
    }
    return null;
  }

  // ---- Calculer distance et route (OSRM) ----
  Future<Map<String, dynamic>?> getRoute(LatLng origin, LatLng dest) async {
    try {
      final url = '$_osrmUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes'][0];
        final distance = route['distance'] / 1000; // km
        final duration = route['duration'] / 60; // minutes
        final coordinates = route['geometry']['coordinates'] as List;

        final polylinePoints = coordinates.map<LatLng>((coord) =>
          LatLng(coord[1].toDouble(), coord[0].toDouble()),
        ).toList();

        return {
          'distanceKm': distance,
          'durationMin': duration,
          'polylinePoints': polylinePoints,
        };
      }
    } catch (e) {
      print('Erreur calcul route: $e');
    }
    return null;
  }

  // ---- Calculer le prix selon le type de véhicule ----
  double calculatePrice(double distanceKm, String vehicleType) {
    switch (vehicleType) {
      case 'Moto':
        return (200 + distanceKm * 150).roundToDouble();
      case 'Eco':
        return (200 + distanceKm * 300).roundToDouble();
      case 'Confort':
        return (200 + distanceKm * 500).roundToDouble();
      default:
        return (200 + distanceKm * 300).roundToDouble();
    }
  }
}
