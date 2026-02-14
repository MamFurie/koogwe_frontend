import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AuthService {
  final String baseUrl = kBaseUrl; // ✅ Railway — marche sur Android ET iOS

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kKeyToken, token);

        if (data['user'] != null) {
          await prefs.setString(kKeyUserName, data['user']['name'] ?? 'Utilisateur');
          await prefs.setString(kKeyUserRole, data['user']['role'] ?? 'PASSENGER');
          await prefs.setString(kKeyUserId, data['user']['id']?.toString() ?? '');
          await prefs.setString(kKeyUserEmail, data['user']['email'] ?? '');
        }

        print('✅ Connexion réussie : ${data['user']?['role']}');
        return true;
      } else {
        print('❌ Erreur login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur réseau login: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Inscription réussie !');
        return true;
      } else {
        print('❌ Erreur inscription: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur réseau inscription: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> verifyCode(String email, String code) async {
    return true;
  }
}
