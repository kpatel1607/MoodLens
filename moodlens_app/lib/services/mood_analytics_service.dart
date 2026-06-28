import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_history_service.dart';

class MoodAnalyticsService {
  final LocalHistoryService _localHistoryService = LocalHistoryService();

  Future<MoodInsightsSummary> getInsights({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    List<Map<String, dynamic>> items = [];

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    bool isCloudMode = false;

    if (user != null && !user.isAnonymous) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mood_entries')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .get();

      items = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      items.sort(_sortByCreatedAt);
      isCloudMode = true;
    } else {
      final localItems = await _localHistoryService.getHistory();

      items = localItems.where((item) {
        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );

        if (createdAt == null) return false;

        return createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            createdAt.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      items.sort(_sortByCreatedAt);
      isCloudMode = false;
    }

    return _buildSummary(
      items: items,
      startDate: start,
      endDate: end,
      isCloudMode: isCloudMode,
    );
  }

  int _sortByCreatedAt(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aTime = a['created_at'];
    final bTime = b['created_at'];

    if (aTime is Timestamp && bTime is Timestamp) {
      return aTime.compareTo(bTime);
    }

    final aIso = DateTime.tryParse(
      a['created_at']?.toString() ??
          a['created_at_iso']?.toString() ??
          '',
    );

    final bIso = DateTime.tryParse(
      b['created_at']?.toString() ??
          b['created_at_iso']?.toString() ??
          '',
    );

    if (aIso == null || bIso == null) return 0;

    return aIso.compareTo(bIso);
  }

  MoodInsightsSummary _buildSummary({
    required List<Map<String, dynamic>> items,
    required DateTime startDate,
    required DateTime endDate,
    required bool isCloudMode,
  }) {
    if (items.isEmpty) {
      return MoodInsightsSummary.empty(
        startDate: startDate,
        endDate: endDate,
        isCloudMode: isCloudMode,
      );
    }

    double totalScore = 0;
    int sarcasmCount = 0;

    final Map<String, int> emotionCounts = {};
    final Map<String, List<double>> dayScores = {};
    final List<EntryInsightPoint> entryPoints = [];
    final List<MoodImpactItem> positiveItems = [];
    final List<MoodImpactItem> negativeItems = [];

    for (final item in items) {
      final overall = item['overall'] as Map<String, dynamic>? ?? {};

      final score = _toDouble(overall['mood_score']);
      final sarcasm = _toInt(overall['sarcasm_count']);
      final emotion = overall['dominant_emotion']?.toString() ?? 'unknown';
      final dateKey = item['date_key']?.toString() ?? _dateKeyFromItem(item);
      final text = item['input_text']?.toString() ?? '';

      totalScore += score;
      sarcasmCount += sarcasm;

      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;

      dayScores.putIfAbsent(dateKey, () => []);
      dayScores[dateKey]!.add(score);

      entryPoints.add(
        EntryInsightPoint(
          dateKey: dateKey,
          timeLabel: _timeLabel(item),
          score: score,
          mood: _moodLabel(score, sarcasm),
          emotion: emotion,
          sarcasmCount: sarcasm,
          text: text,
        ),
      );

      final impact = MoodImpactItem(
        text: text,
        score: score,
        emotion: emotion,
        sarcasmCount: sarcasm,
      );

      if (score > 0) {
        positiveItems.add(impact);
      } else if (score < 0) {
        negativeItems.add(impact);
      }
    }

    positiveItems.sort((a, b) => b.score.compareTo(a.score));
    negativeItems.sort((a, b) => a.score.compareTo(b.score));

    final averageScore = totalScore / items.length;

    final dailyAverages = dayScores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;

      return DailyInsightPoint(
        dateKey: entry.key,
        averageScore: double.parse(
          average.toStringAsFixed(2),
        ),
        entryCount: entry.value.length,
      );
    }).toList();

    dailyAverages.sort(
      (a, b) => a.dateKey.compareTo(b.dateKey),
    );

    final sortedEmotionEntries = emotionCounts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    final emotionDistribution = sortedEmotionEntries.map((entry) {
      return EmotionInsightItem(
        emotion: entry.key,
        count: entry.value,
        percentage: double.parse(
          ((entry.value / items.length) * 100).toStringAsFixed(1),
        ),
      );
    }).toList();

    final dominantEmotion = emotionDistribution.isEmpty
        ? 'unknown'
        : emotionDistribution.first.emotion;

    DailyInsightPoint? bestDay;
    DailyInsightPoint? worstDay;

    if (dailyAverages.isNotEmpty) {
      final sortedBestDays = [...dailyAverages];
      sortedBestDays.sort(
        (a, b) => b.averageScore.compareTo(a.averageScore),
      );

      final sortedWorstDays = [...dailyAverages];
      sortedWorstDays.sort(
        (a, b) => a.averageScore.compareTo(b.averageScore),
      );

      bestDay = sortedBestDays.first;
      worstDay = sortedWorstDays.first;
    }

    return MoodInsightsSummary(
      startDate: startDate,
      endDate: endDate,
      isCloudMode: isCloudMode,
      entryCount: items.length,
      averageScore: double.parse(
        averageScore.toStringAsFixed(2),
      ),
      overallMood: _moodLabel(
        averageScore,
        sarcasmCount,
      ),
      dominantEmotion: dominantEmotion,
      sarcasmCount: sarcasmCount,
      sarcasmPercentage: double.parse(
        ((sarcasmCount / items.length) * 100).toStringAsFixed(1),
      ),
      dailyAverages: dailyAverages,
      entryPoints: entryPoints,
      emotionDistribution: emotionDistribution,
      mostPositive: positiveItems.isNotEmpty ? positiveItems.first : null,
      mostNegative: negativeItems.isNotEmpty ? negativeItems.first : null,
      bestDay: bestDay,
      worstDay: worstDay,
      insight: _insightText(
        averageScore: averageScore,
        dominantEmotion: dominantEmotion,
        sarcasmCount: sarcasmCount,
        entryCount: items.length,
      ),
    );
  }

  String _insightText({
    required double averageScore,
    required String dominantEmotion,
    required int sarcasmCount,
    required int entryCount,
  }) {
    if (entryCount == 0) {
      return 'No entries found for this period.';
    }

    if (averageScore > 0) {
      return 'Your mood was positive overall. $dominantEmotion appeared most often during this period.';
    }

    if (averageScore < 0) {
      if (sarcasmCount > 0) {
        return 'Your mood leaned negative with sarcasm signals. This may suggest hidden frustration or emotional contrast.';
      }

      return 'Your mood leaned negative overall. $dominantEmotion appeared most often and may be an important pattern.';
    }

    return 'Your mood stayed close to neutral overall.';
  }

  String _moodLabel(
    double score,
    int sarcasmCount,
  ) {
    if (score > 0) return 'Positive';

    if (score < 0) {
      return sarcasmCount > 0 ? 'Negative with Sarcasm' : 'Negative';
    }

    return sarcasmCount > 0 ? 'Neutral with Sarcasm' : 'Neutral';
  }

  String _timeLabel(Map<String, dynamic> item) {
    final hour = _toInt(item['hour']);
    final minute = _toInt(item['minute']);

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _dateKeyFromItem(Map<String, dynamic> item) {
    final createdAt = item['created_at'];

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      return _dateKey(date);
    }

    final iso = DateTime.tryParse(
      item['created_at']?.toString() ??
          item['created_at_iso']?.toString() ??
          '',
    );

    if (iso == null) return 'unknown';

    return _dateKey(iso);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }
}

class MoodInsightsSummary {
  final DateTime startDate;
  final DateTime endDate;
  final bool isCloudMode;

  final int entryCount;
  final double averageScore;
  final String overallMood;
  final String dominantEmotion;
  final int sarcasmCount;
  final double sarcasmPercentage;

  final List<DailyInsightPoint> dailyAverages;
  final List<EntryInsightPoint> entryPoints;
  final List<EmotionInsightItem> emotionDistribution;

  final MoodImpactItem? mostPositive;
  final MoodImpactItem? mostNegative;
  final DailyInsightPoint? bestDay;
  final DailyInsightPoint? worstDay;

  final String insight;

  MoodInsightsSummary({
    required this.startDate,
    required this.endDate,
    required this.isCloudMode,
    required this.entryCount,
    required this.averageScore,
    required this.overallMood,
    required this.dominantEmotion,
    required this.sarcasmCount,
    required this.sarcasmPercentage,
    required this.dailyAverages,
    required this.entryPoints,
    required this.emotionDistribution,
    required this.mostPositive,
    required this.mostNegative,
    required this.bestDay,
    required this.worstDay,
    required this.insight,
  });

  factory MoodInsightsSummary.empty({
    required DateTime startDate,
    required DateTime endDate,
    required bool isCloudMode,
  }) {
    return MoodInsightsSummary(
      startDate: startDate,
      endDate: endDate,
      isCloudMode: isCloudMode,
      entryCount: 0,
      averageScore: 0,
      overallMood: 'No Data',
      dominantEmotion: 'unknown',
      sarcasmCount: 0,
      sarcasmPercentage: 0,
      dailyAverages: [],
      entryPoints: [],
      emotionDistribution: [],
      mostPositive: null,
      mostNegative: null,
      bestDay: null,
      worstDay: null,
      insight: 'No mood entries found for this period.',
    );
  }
}

class DailyInsightPoint {
  final String dateKey;
  final double averageScore;
  final int entryCount;

  DailyInsightPoint({
    required this.dateKey,
    required this.averageScore,
    required this.entryCount,
  });
}

class EntryInsightPoint {
  final String dateKey;
  final String timeLabel;
  final double score;
  final String mood;
  final String emotion;
  final int sarcasmCount;
  final String text;

  EntryInsightPoint({
    required this.dateKey,
    required this.timeLabel,
    required this.score,
    required this.mood,
    required this.emotion,
    required this.sarcasmCount,
    required this.text,
  });
}

class EmotionInsightItem {
  final String emotion;
  final int count;
  final double percentage;

  EmotionInsightItem({
    required this.emotion,
    required this.count,
    required this.percentage,
  });
}

class MoodImpactItem {
  final String text;
  final double score;
  final String emotion;
  final int sarcasmCount;

  MoodImpactItem({
    required this.text,
    required this.score,
    required this.emotion,
    required this.sarcasmCount,
  });
}