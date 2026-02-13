import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class RideService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ FIX CRITIQUE : Utilise la même clé que auth_service.dart
    return prefs.getString(AppConfig.keyAccessToken);
  }

  // ---- Créer une course ----
  Future<Map<String, dynamic>> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required double price,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Non connecté'};

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/rides'),
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
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'ride': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur serveur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  // ---- Historique des courses ----
  Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Non connecté'};

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/rides/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'rides': data};
      } else {
        return {'success': false, 'message': 'Erreur serveur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  // ---- Mettre à jour le véhicule (chauffeur) ----
  Future<Map<String, dynamic>> updateVehicle({
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleColor,
    required String licensePlate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Non connecté'};

      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/users/update-vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicleMake': vehicleMake,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'licensePlate': licensePlate,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }
}
