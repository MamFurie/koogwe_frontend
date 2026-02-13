class AppConfig {
  // ---- CHANGE THIS TO YOUR SERVER IP ----
  // Pour tester sur PC (Chrome) : 'http://localhost:3000'
  // Pour tester sur Android (même WiFi) : 'http://192.168.X.X:3000'
 static const String baseUrl = 'https://web-koogwe-cc4006.up.railway.app';
static const String socketUrl = 'https://web-koogwe-cc4006.up.railway.app';

  // Prix par km en FCFA
  static const double motoBaseFare = 200;
  static const double motoPricePerKm = 150;
  static const double ecoBaseFare = 200;
  static const double ecoPricePerKm = 300;
  static const double confortBaseFare = 200;
  static const double confortPricePerKm = 500;

  // SharedPreferences keys
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
}
