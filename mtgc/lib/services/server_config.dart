import 'package:shared_preferences/shared_preferences.dart';

/// Persists the base URL of the Railway API server. Set in-app via the
/// "Configurar servidor" button on the login screen.
class ServerConfig {
  static const String _key = 'api_base_url';

  /// The saved server URL, or null if the user hasn't configured one yet.
  static Future<String?> baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Saves the server URL, stripping any trailing slash so callers can safely
  /// build paths as `$baseUrl/auth/login`.
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_key, cleaned);
  }
}
