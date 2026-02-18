import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'theme/colors.dart';

class LoginOptionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: Stack(
        children: [
          // Decorative background
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.07),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 24, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Icon(Icons.local_taxi_rounded, size: 55, color: Colors.white),
                  ),
                  SizedBox(height: 28),
                  Text('KOOGWE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D3436), letterSpacing: 4)),
                  SizedBox(height: 10),
                  Text('Votre course, en toute confiance', style: TextStyle(fontSize: 15, color: Colors.grey[500], letterSpacing: 0.3)),

                  Spacer(),

                  // Illustration
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text('🚖', style: TextStyle(fontSize: 72)),
                        SizedBox(height: 16),
                        Text('Prêt à partir ?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
                        SizedBox(height: 8),
                        Text('Connectez-vous ou créez votre compte\npour commencer.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Buttons
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        elevation: 6, shadowColor: AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text('Se connecter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text('Créer un compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
