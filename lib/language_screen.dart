import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_options_screen.dart';
import 'theme/colors.dart';

class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'es';

  final List<_Lang> _languages = [
    _Lang(code: 'es', flag: '🇪🇸', name: 'Español', subtitle: 'Español (América del Sur)'),
    _Lang(code: 'en', flag: '🇬🇧', name: 'English', subtitle: 'English'),
    _Lang(code: 'pt', flag: '🇧🇷', name: 'Português', subtitle: 'Português (Brasil)'),
    _Lang(code: 'fr', flag: '🇫🇷', name: 'Français', subtitle: 'Français'),
  ];

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selected);
    await prefs.setBool('language_selected', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginOptionsScreen(),
        transitionDuration: Duration(milliseconds: 450),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.language_rounded, size: 48, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 28),
              Text('Choisissez votre langue', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
              SizedBox(height: 8),
              Text('Choose your language', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
              SizedBox(height: 36),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final lang = _languages[i];
                    final isSelected = lang.code == _selected;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = lang.code),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: Offset(0, 4))
                          ] : [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag, style: TextStyle(fontSize: 32)),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : Color(0xFF2D3436))),
                                  Text(lang.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 250),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade400, width: 2),
                              ),
                              child: isSelected ? Icon(Icons.check, color: Colors.white, size: 14) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    elevation: 6, shadowColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text('Confirmer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Lang {
  final String code, flag, name, subtitle;
  const _Lang({required this.code, required this.flag, required this.name, required this.subtitle});
}
