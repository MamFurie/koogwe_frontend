import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koogwz_mobile/login_screen.dart';
import 'signup_screen.dart';
import 'home_passenger.dart';
import 'home_driver.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vérifier si l'utilisateur est déjà connecté
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString(kKeyToken);
  final String? role = prefs.getString(kKeyUserRole);
  
  Widget initialScreen = LoginScreen();
  
  if (token != null && role != null) {
    // Utilisateur connecté - rediriger vers son écran d'accueil
    if (role == 'DRIVER') {
      initialScreen = HomeDriver();
    } else {
      initialScreen = HomePassenger();
    }
  }
  
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Koogwe',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: initialScreen,
  ));
}