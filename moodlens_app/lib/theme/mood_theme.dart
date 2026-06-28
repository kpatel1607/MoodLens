import 'package:flutter/material.dart';

class MoodTheme {
  final Color background;
  final Color card;
  final Color border;
  final Color accent;
  final Color text;
  final Color mutedText;

  const MoodTheme({
    required this.background,
    required this.card,
    required this.border,
    required this.accent,
    required this.text,
    required this.mutedText,
  });
}

class MoodThemes {
  // -----------------------------
  // MOOD BASED THEMES
  // -----------------------------

  static const neutral = MoodTheme(
    background: Color(0xFF171512),
    card: Color(0xFF25211C),
    border: Color(0xFF3A332B),
    accent: Color(0xFFD6A85B),
    text: Color(0xFFFFF7EA),
    mutedText: Color(0xFFC7B8A0),
  );

  static const positive = MoodTheme(
    background: Color(0xFF101A14),
    card: Color(0xFF1B2A20),
    border: Color(0xFF2F4B39),
    accent: Color(0xFF74C69D),
    text: Color(0xFFF1FFF6),
    mutedText: Color(0xFFB7D8C4),
  );

  static const negative = MoodTheme(
    background: Color(0xFF1E1111),
    card: Color(0xFF2B1A1A),
    border: Color(0xFF563030),
    accent: Color(0xFFFF8A7A),
    text: Color(0xFFFFF1EE),
    mutedText: Color(0xFFD8B8B0),
  );

  static const sarcastic = MoodTheme(
    background: Color(0xFF1F160B),
    card: Color(0xFF302112),
    border: Color(0xFF5A3B19),
    accent: Color(0xFFFFB84D),
    text: Color(0xFFFFF5DD),
    mutedText: Color(0xFFD9BF90),
  );

  // -----------------------------
  // USER SELECTABLE THEMES
  // -----------------------------

  static const calmDark = MoodTheme(
    background: Color(0xFF111827),
    card: Color(0xFF1F2937),
    border: Color(0xFF374151),
    accent: Color(0xFF9CA3AF),
    text: Color(0xFFF9FAFB),
    mutedText: Color(0xFFD1D5DB),
  );

  static const warmSunset = MoodTheme(
    background: Color(0xFF22150E),
    card: Color(0xFF362114),
    border: Color(0xFF5B3821),
    accent: Color(0xFFFFA94D),
    text: Color(0xFFFFF4E6),
    mutedText: Color(0xFFE7C7A4),
  );

  static const minimalFocus = MoodTheme(
    background: Color(0xFF111111),
    card: Color(0xFF1A1A1A),
    border: Color(0xFF303030),
    accent: Color(0xFFEAEAEA),
    text: Color(0xFFFFFFFF),
    mutedText: Color(0xFFAAAAAA),
  );

  // -----------------------------
  // MOOD BASED
  // -----------------------------

  static MoodTheme fromMood(String? mood) {
    final m = (mood ?? '').toLowerCase();

    if (m.contains('sarcasm')) {
      return sarcastic;
    }

    if (m.contains('positive')) {
      return positive;
    }

    if (m.contains('negative')) {
      return negative;
    }

    return neutral;
  }

  // -----------------------------
  // PROFILE THEME SELECTION
  // -----------------------------

  static MoodTheme fromProfileTheme(
    String? selectedTheme,
    String? mood,
  ) {
    switch ((selectedTheme ?? '').toLowerCase()) {
      case 'calm dark':
        return calmDark;

      case 'warm sunset':
        return warmSunset;

      case 'minimal focus':
        return minimalFocus;

      case 'mood based':
      default:
        return fromMood(mood);
    }
  }
}