import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's Gemini API key locally using SharedPreferences.
class ApiKeyStorage {
  static const String _apiKeyKey = 'tempus_gemini_api_key';

  /// Saves the API key.
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  /// Loads the stored API key. Returns null if not set.
  static Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  /// Removes the stored API key.
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }

  /// Returns true if an API key is stored.
  static Future<bool> hasApiKey() async {
    final key = await loadApiKey();
    return key != null && key.isNotEmpty;
  }
}
