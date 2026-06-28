import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/moodlens_result.dart';

class CloudHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final user = _auth.currentUser;

    if (user == null) return;

    final now = DateTime.now();
    final dateKey = _dateKey(now);

    final data = {
      'created_at': Timestamp.fromDate(now),
      'created_at_iso': now.toIso8601String(),
      'date_key': dateKey,
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
      'statements': result.statements.map((s) {
        return {
          'text': s.text,
          'primary_emotion': s.primaryEmotion,
          'emotion_score': s.emotionScore,
          'sarcasm_label': s.sarcasmLabel,
          'sarcasm_score': s.sarcasmScore,
          'sentiment': s.sentiment,
          'interpretation': s.interpretation,
        };
      }).toList(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('mood_entries')
        .add(data);
  }
}