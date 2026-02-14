import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class RideService {
  final String baseUrl = kBaseUrl; // ✅ Railway

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kKeyToken);
  }

  // Créer une course
  Future<Map<String, dynamic>> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required double price,
    String vehicleType = 'MOTO',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Non connecté'};

      final response = await http.post(
        Uri.parse('$baseUrl/rides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
          'price': price,
          'vehicleType': vehicleType,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'ride': jsonDecode(response.body)};
      } else {
        print('❌ Erreur création course: ${response.body}');
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('❌ Erreur réseau: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Historique des courses
  Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'rides': []};

      final response = await http.get(
        Uri.parse('$baseUrl/rides/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'rides': data is List ? data : data['rides'] ?? []};
      } else {
        return {'success': false, 'rides': []};
      }
    } catch (e) {
      print('❌ Erreur historique: $e');
      return {'success': false, 'rides': []};
    }
  }

  // Stats du chauffeur (gains du jour, nb de courses)
  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false};

      final response = await http.get(
        Uri.parse('$baseUrl/rides/driver/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }
}
