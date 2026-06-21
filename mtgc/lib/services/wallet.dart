import 'package:shared_preferences/shared_preferences.dart';

class Wallet {
  static const String _key = 'wallet_balance';

  static Future<double> balance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? 0.0;
  }

  static Future<double> add(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getDouble(_key) ?? 0.0) + delta;
    await prefs.setDouble(_key, next);
    return next;
  }
}
