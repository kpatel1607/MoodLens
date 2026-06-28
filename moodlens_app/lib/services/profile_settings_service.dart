import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsService {
  static const String _themeKey = 'profile_theme';
  static const String _emojiKey = 'emoji_style';
  static const String _analyticsKey = 'analytics_depth';
  static const String _privacyKey = 'privacy_mode';

  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'Mood Based';
  }

  Future<String> getEmojiStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emojiKey) ?? 'Soft Emojis';
  }

  Future<String> getAnalyticsDepth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_analyticsKey) ?? 'Balanced';
  }

  Future<String> getPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_privacyKey) ?? 'Private';
  }

  Future<void> saveTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value);
  }

  Future<void> saveEmojiStyle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emojiKey, value);
  }

  Future<void> saveAnalyticsDepth(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analyticsKey, value);
  }

  Future<void> savePrivacyMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privacyKey, value);
  }
}