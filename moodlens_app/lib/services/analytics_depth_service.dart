import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsDepthService {
  static const String _analyticsKey = 'analytics_depth';
  static const String defaultDepth = 'Balanced';

  static final ValueNotifier<String> selectedDepthNotifier =
      ValueNotifier<String>(defaultDepth);

  static Future<void> loadDepth() async {
    final prefs = await SharedPreferences.getInstance();

    selectedDepthNotifier.value =
        prefs.getString(_analyticsKey) ?? defaultDepth;
  }

  static Future<String> getSelectedDepth() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_analyticsKey) ?? defaultDepth;
  }

  static Future<void> saveSelectedDepth(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_analyticsKey, value);

    selectedDepthNotifier.value = value;
  }
}
