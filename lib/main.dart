import 'package:flutter/material.dart';
import 'package:koogwz_mobile/welcom_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koogwz_mobile/login_screen.dart';
import 'package:koogwz_mobile/welcome_screen.dart';
import 'signup_screen.dart';
import 'home_passenger.dart';
import 'home_driver.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Vérifier si c'est la première fois
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  // Vérifier si l'utilisateur est connecté
  final String? token = prefs.getString(kKeyToken);
  final String? role = prefs.getString(kKeyUserRole);
  
  Widget initialScreen;
  
  // Logique de navigation
  if (!onboardingComplete) {
    // Première fois → Welcome Screen
    initialScreen = WelcomeScreen();
  } else if (token != null && role != null) {
    // Utilisateur connecté → Home
    if (role == 'DRIVER') {
      initialScreen = HomeDriver();
    } else {
      initialScreen = HomePassenger();
    }
  } else {
    // Utilisateur déjà vu le welcome mais pas connecté → Login
    initialScreen = LoginScreen();
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