import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  // -------------------------------------------------------
  // INSCRIPTION
  // -------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    required String role, // 'PASSENGER' ou 'DRIVER'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  // -------------------------------------------------------
  // CONNEXION
  // -------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ FIX : On sauvegarde TOUT sous les bonnes clés
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.keyAccessToken, data['access_token']);
        await prefs.setString(AppConfig.keyUserId, data['user']['id']);
        await prefs.setString(AppConfig.keyUserEmail, data['user']['email']);
        await prefs.setString(AppConfig.keyUserName, data['user']['name'] ?? '');
        await prefs.setString(AppConfig.keyUserRole, data['user']['role']);

        return {'success': true, 'user': data['user']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email ou mot de passe incorrect',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  // -------------------------------------------------------
  // DÉCONNEXION
  // -------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // -------------------------------------------------------
  // GETTERS
  // -------------------------------------------------------
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyAccessToken);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyUserId);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyUserRole);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyUserName);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
