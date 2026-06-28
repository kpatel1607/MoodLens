class MoodLensResult {
  final String inputText;
  final int statementCount;
  final MoodOverall overall;
  final List<MoodStatement> statements;

  MoodLensResult({
    required this.inputText,
    required this.statementCount,
    required this.overall,
    required this.statements,
  });

  factory MoodLensResult.fromJson(Map<String, dynamic> json) {
    return MoodLensResult(
      inputText: json['input_text'] ?? '',
      statementCount: json['statement_count'] ?? 0,
      overall: MoodOverall.fromJson(json['overall'] ?? {}),
      statements: (json['statements'] as List<dynamic>? ?? [])
          .map((item) => MoodStatement.fromJson(item))
          .toList(),
    );
  }
}

class MoodOverall {
  final String overallMood;
  final double moodScore;
  final String dominantEmotion;
  final int sarcasmCount;
  final List<String> trend;

  MoodOverall({
    required this.overallMood,
    required this.moodScore,
    required this.dominantEmotion,
    required this.sarcasmCount,
    required this.trend,
  });

  factory MoodOverall.fromJson(Map<String, dynamic> json) {
    return MoodOverall(
      overallMood: json['overall_mood'] ?? 'Unknown',
      moodScore: (json['mood_score'] ?? 0).toDouble(),
      dominantEmotion: json['dominant_emotion'] ?? 'unknown',
      sarcasmCount: json['sarcasm_count'] ?? 0,
      trend: (json['trend'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class MoodStatement {
  final String text;
  final String primaryEmotion;
  final double emotionScore;
  final String sarcasmLabel;
  final double sarcasmScore;
  final String sentiment;
  final String interpretation;

  MoodStatement({
    required this.text,
    required this.primaryEmotion,
    required this.emotionScore,
    required this.sarcasmLabel,
    required this.sarcasmScore,
    required this.sentiment,
    required this.interpretation,
  });

  factory MoodStatement.fromJson(Map<String, dynamic> json) {
    return MoodStatement(
      text: json['text'] ?? '',
      primaryEmotion: json['primary_emotion'] ?? 'unknown',
      emotionScore: (json['emotion_score'] ?? 0).toDouble(),
      sarcasmLabel: json['sarcasm_label'] ?? 'Unknown',
      sarcasmScore: (json['sarcasm_score'] ?? 0).toDouble(),
      sentiment: json['sentiment'] ?? 'Unknown',
      interpretation: json['interpretation'] ?? '',
    );
  }
}