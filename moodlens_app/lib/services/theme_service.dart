import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'profile_theme';

  static final ValueNotifier<String> selectedThemeNotifier =
      ValueNotifier<String>('Mood Based');

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    selectedThemeNotifier.value =
        prefs.getString(_themeKey) ?? 'Mood Based';
  }

  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeKey) ?? 'Mood Based';
  }

  static Future<void> saveSelectedTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeKey, value);

    selectedThemeNotifier.value = value;
  }
}