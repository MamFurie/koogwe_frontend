import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      illustration: '🗺️',
      title: 'Trouvez un chauffeur\nfacilement',
      description: 'Commandez une course en quelques secondes, où que vous soyez au Togo.',
      color: Color(0xFFFF6B6B),
      bgColor: Color(0xFFFFF0F0),
    ),
    _OnboardingData(
      illustration: '🚗',
      title: 'Courses rapides\net sûres',
      description: 'Des chauffeurs vérifiés, un trajet en temps réel, vous arrivez en toute sécurité.',
      color: Color(0xFF4ECDC4),
      bgColor: Color(0xFFEFFBFA),
    ),
    _OnboardingData(
      illustration: '💳',
      title: 'Tarifs\ntransparents',
      description: 'Prix fixé avant de partir. Payez en cash ou mobile money, sans surprise.',
      color: Color(0xFF6C63FF),
      bgColor: Color(0xFFF0EEFF),
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LanguageScreen(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: page.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? page.color : page.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _complete,
                      child: Text('Passer', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 15)),
                    )
                  else
                    SizedBox(width: 70),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, index) {
                  final p = _pages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(color: p.color.withOpacity(0.12), shape: BoxShape.circle),
                          child: Center(child: Text(p.illustration, style: TextStyle(fontSize: 90))),
                        ),
                        SizedBox(height: 48),
                        Text(p.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF2D3436), height: 1.2)),
                        SizedBox(height: 20),
                        Text(p.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.color, foregroundColor: Colors.white,
                    elevation: 6, shadowColor: page.color.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(_currentPage < _pages.length - 1 ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String illustration, title, description;
  final Color color, bgColor;
  const _OnboardingData({required this.illustration, required this.title, required this.description, required this.color, required this.bgColor});
}
