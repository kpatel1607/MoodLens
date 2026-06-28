import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/moodlens_result.dart';

class LocalHistoryService {
  static const String _key = 'moodlens_history';

  String _dateKey(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String _dayName(DateTime dateTime) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[dateTime.weekday - 1];
  }

  Future<void> saveResult(MoodLensResult result) async {
    final prefs = await SharedPreferences.getInstance();

    final history = prefs.getStringList(_key) ?? [];

    final now = DateTime.now();

    final item = {
      'id': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'date_key': _dateKey(now),
      'day_name': _dayName(now),
      'hour': now.hour,
      'minute': now.minute,
      'input_text': result.inputText,
      'statement_count': result.statementCount,
      'overall': {
        'overall_mood': result.overall.overallMood,
        'mood_score': result.overall.moodScore,
        'dominant_emotion': result.overall.dominantEmotion,
        'sarcasm_count': result.overall.sarcasmCount,
        'trend': result.overall.trend,
      },
      'statements': result.statements
          .map(
            (s) => {
              'text': s.text,
              'primary_emotion': s.primaryEmotion,
              'emotion_score': s.emotionScore,
              'sarcasm_label': s.sarcasmLabel,
              'sarcasm_score': s.sarcasmScore,
              'sentiment': s.sentiment,
              'interpretation': s.interpretation,
            },
          )
          .toList(),
    };

    history.insert(0, jsonEncode(item));

    if (history.length > 300) {
      history.removeRange(300, history.length);
    }

    await prefs.setStringList(_key, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final history = prefs.getStringList(_key) ?? [];

    return history
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getHistoryForDate(
    String dateKey,
  ) async {
    final history = await getHistory();

    return history.where((item) {
      return item['date_key'] == dateKey;
    }).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> getGroupedByDay() async {
    final history = await getHistory();

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in history) {
      final dateKey = item['date_key'] ?? 'unknown';

      grouped.putIfAbsent(dateKey, () => []);

      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}