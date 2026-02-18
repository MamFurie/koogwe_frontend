import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'home_passenger.dart';
import 'home_driver.dart';
import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: Duration(milliseconds: 2200), vsync: this);

    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.3, 0.7, curve: Curves.easeIn)),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.7, 1.0, curve: Curves.easeInOut)),
    );

    _controller.forward();

    Future.delayed(Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final bool languageSelected = prefs.getBool('language_selected') ?? false;
    final String? token = prefs.getString(kKeyToken);
    final String? role = prefs.getString(kKeyUserRole);

    if (!mounted) return;

    if (!onboardingComplete) {
      Navigator.pushReplacement(context, _fadeRoute(WelcomeScreen()));
    } else if (!languageSelected) {
      Navigator.pushReplacement(context, _fadeRoute(LanguageScreen()));
    } else if (token != null && role != null) {
      if (role == 'DRIVER') {
        Navigator.pushReplacement(context, _fadeRoute(HomeDriver()));
      } else {
        Navigator.pushReplacement(context, _fadeRoute(HomePassenger()));
      }
    } else {
      Navigator.pushReplacement(context, _fadeRoute(LoginScreen()));
    }
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: 600),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF6B6B),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnim.value * (_controller.value > 0.7 ? _pulseAnim.value : 1.0),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.local_taxi, size: 65, color: Color(0xFFFF6B6B)),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'KOOGWE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Votre course, en toute confiance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
