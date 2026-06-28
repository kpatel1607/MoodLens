class MoodHistoryItem {
  final String id;
  final String createdAt;
  final String dateKey;
  final String dayName;
  final int hour;
  final int minute;
  final String inputText;
  final String overallMood;
  final double moodScore;
  final String dominantEmotion;
  final int sarcasmCount;
  final List<String> trend;

  MoodHistoryItem({
    required this.id,
    required this.createdAt,
    required this.dateKey,
    required this.dayName,
    required this.hour,
    required this.minute,
    required this.inputText,
    required this.overallMood,
    required this.moodScore,
    required this.dominantEmotion,
    required this.sarcasmCount,
    required this.trend,
  });

  factory MoodHistoryItem.fromJson(Map<String, dynamic> json) {
    final overall = json['overall'] as Map<String, dynamic>? ?? {};

    return MoodHistoryItem(
      id: json['id'] ?? '',
      createdAt: json['created_at'] ?? '',
      dateKey: json['date_key'] ?? '',
      dayName: json['day_name'] ?? '',
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      inputText: json['input_text'] ?? '',
      overallMood: overall['overall_mood'] ?? 'Unknown',
      moodScore: (overall['mood_score'] ?? 0).toDouble(),
      dominantEmotion: overall['dominant_emotion'] ?? 'unknown',
      sarcasmCount: overall['sarcasm_count'] ?? 0,
      trend: (overall['trend'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}