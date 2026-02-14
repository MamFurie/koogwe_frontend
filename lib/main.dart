import 'package:flutter/material.dart';
import 'package:koogwz_mobile/login_screen.dart';
import 'signup_screen.dart'; // <--- Importe le nouveau fichier

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Koogwe',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: LoginScreen(), // <--- Démarre ici !
  ));
}