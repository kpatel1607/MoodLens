import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/local_history_service.dart';
import '../theme/mood_theme.dart';
import '../services/theme_service.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({
    super.key,
  });

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final LocalHistoryService _localHistoryService = LocalHistoryService();

  _DailySummary? _summary;
  bool _isLoading = true;
  bool _isCloudMode = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  String _todayDateKey() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadToday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final dateKey = _todayDateKey();

      List<Map<String, dynamic>> items = [];

      if (user != null && !user.isAnonymous) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('mood_entries')
            .where('date_key', isEqualTo: dateKey)
            .get();

        items = snapshot.docs.map((doc) => doc.data()).toList();

        items.sort((a, b) {
          final aTime = a['created_at'];
          final bTime = b['created_at'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return aTime.compareTo(bTime);
          }

          return 0;
        });

        _isCloudMode = true;
      } else {
        items = await _localHistoryService.getHistoryForDate(dateKey);
        items = items.reversed.toList();
        _isCloudMode = false;
      }

      if (!mounted) return;

      setState(() {
        _summary = _buildSummary(dateKey, items);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summary = _DailySummary.empty(_todayDateKey());
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load today summary: $e',
          ),
        ),
      );
    }
  }

  _DailySummary _buildSummary(
    String dateKey,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) {
      return _DailySummary.empty(dateKey);
    }

    double totalScore = 0;
    int sarcasmCount = 0;

    final Map<String, int> emotionCounts = {};
    final List<_HourlyPoint> points = [];
    final List<_ImpactItem> positiveItems = [];
    final List<_ImpactItem> negativeItems = [];

    for (final item in items) {
      final overall = item['overall'] as Map<String, dynamic>? ?? {};

      final score = _toDouble(overall['mood_score']);
      final emotion = overall['dominant_emotion']?.toString() ?? 'unknown';
      final sarcasm = _toInt(overall['sarcasm_count']);

      totalScore += score;
      sarcasmCount += sarcasm;

      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;

      points.add(
        _HourlyPoint(
          hour: _toInt(item['hour']),
          minute: _toInt(item['minute']),
          score: score,
        ),
      );

      final impact = _ImpactItem(
        text: item['input_text']?.toString() ?? '',
        score: score,
        emotion: emotion,
      );

      if (score > 0) {
        positiveItems.add(impact);
      } else if (score < 0) {
        negativeItems.add(impact);
      }
    }

    positiveItems.sort((a, b) => b.score.compareTo(a.score));
    negativeItems.sort((a, b) => a.score.compareTo(b.score));

    final average = totalScore / items.length;

    final dominantEmotion = emotionCounts.isEmpty
        ? 'unknown'
        : emotionCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return _DailySummary(
      dateKey: dateKey,
      entryCount: items.length,
      averageScore: double.parse(average.toStringAsFixed(2)),
      overallMood: _moodLabel(average, sarcasmCount),
      dominantEmotion: dominantEmotion,
      sarcasmCount: sarcasmCount,
      points: points,
      mostPositive: positiveItems.isNotEmpty ? positiveItems.first : null,
      mostNegative: negativeItems.isNotEmpty ? negativeItems.first : null,
      insight: _dailyInsight(
        average,
        dominantEmotion,
        sarcasmCount,
        items.length,
      ),
    );
  }

  String _moodLabel(double score, int sarcasmCount) {
    if (score > 0) return 'Positive';
    if (score < 0) {
      return sarcasmCount > 0 ? 'Negative with Sarcasm' : 'Negative';
    }

    return sarcasmCount > 0 ? 'Neutral with Sarcasm' : 'Neutral';
  }

  String _dailyInsight(
    double average,
    String emotion,
    int sarcasmCount,
    int count,
  ) {
    if (count == 1) {
      return 'Only one mood check was recorded today. Add more entries for a clearer daily pattern.';
    }

    if (average > 0) {
      return 'Today is overall positive. $emotion appeared most often, and positive moments outweighed negative ones.';
    }

    if (average < 0) {
      if (sarcasmCount > 0) {
        return 'Today leans negative with sarcasm present. This may suggest hidden frustration, stress, or emotional contrast.';
      }

      return 'Today leans negative overall. $emotion appeared most often and may have affected your mood strongly.';
    }

    return 'Today is close to neutral overall.';
  }

  Color _scoreColor(double score) {
    if (score > 0) return const Color(0xFF74C69D);
    if (score < 0) return const Color(0xFFFF8A7A);

    return const Color(0xFFFFB84D);
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

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return ValueListenableBuilder<String>(
      valueListenable: ThemeService.selectedThemeNotifier,
      builder: (context, selectedTheme, _) {
        final moodTheme = MoodThemes.fromProfileTheme(
          selectedTheme,
          summary?.overallMood,
        );

        return Scaffold(
          backgroundColor: moodTheme.background,
          appBar: AppBar(
            backgroundColor: moodTheme.background,
            foregroundColor: moodTheme.text,
            title: Text(
              _isCloudMode ? 'Today Summary' : 'Today Summary',
            ),
          ),
          body: _isLoading
              ? Center(
            child: CircularProgressIndicator(color: moodTheme.accent),
          )
              : summary == null
              ? const SizedBox.shrink()
              : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TopSummaryCard(
                summary: summary,
                moodTheme: moodTheme,
                scoreColor: _scoreColor(summary.averageScore),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Daily Insight',
                text: summary.insight,
                moodTheme: moodTheme,
              ),
              const SizedBox(height: 16),
              _TimelineCard(
                summary: summary,
                moodTheme: moodTheme,
              ),
              const SizedBox(height: 16),
              _ImpactCard(
                summary: summary,
                moodTheme: moodTheme,
              ),
            ],
          ),
        );
      }
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  final _DailySummary summary;
  final MoodTheme moodTheme;
  final Color scoreColor;

  const _TopSummaryCard({
    required this.summary,
    required this.moodTheme,
    required this.scoreColor,
  });

  String get emoji {
    final mood = summary.overallMood.toLowerCase();

    if (mood.contains('positive')) return '😊';
    if (mood.contains('negative')) return '😞';
    if (mood.contains('sarcasm')) return '🙃';

    return '😐';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: moodTheme.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.overallMood,
                  style: TextStyle(
                    color: moodTheme.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Average score: ${summary.averageScore}',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.entryCount} entries • ${summary.sarcasmCount} sarcastic',
                  style: TextStyle(color: moodTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String text;
  final MoodTheme moodTheme;

  const _InfoCard({
    required this.title,
    required this.text,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: moodTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: moodTheme.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final _DailySummary summary;
  final MoodTheme moodTheme;

  const _TimelineCard({
    required this.summary,
    required this.moodTheme,
  });

  Color _color(double score) {
    if (score > 0) return const Color(0xFF74C69D);
    if (score < 0) return const Color(0xFFFF8A7A);

    return const Color(0xFFFFB84D);
  }

  String _emoji(double score) {
    if (score > 0) return '😊';
    if (score < 0) return '😞';

    return '😐';
  }

  @override
  Widget build(BuildContext context) {
    if (summary.points.isEmpty) {
      return _InfoCard(
        title: 'Today Mood Timeline',
        text: 'No timeline data for today.',
        moodTheme: moodTheme,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today Mood Timeline',
              style: TextStyle(
                color: moodTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: summary.points.length,
              separatorBuilder: (_, __) => Center(
                child: Container(
                  width: 28,
                  height: 2,
                  color: moodTheme.border,
                ),
              ),
              itemBuilder: (context, index) {
                final point = summary.points[index];
                final color = _color(point.score);

                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.55)),
                      ),
                      child: Text(
                        _emoji(point.score),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      point.timeLabel,
                      style: TextStyle(
                        color: moodTheme.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final _DailySummary summary;
  final MoodTheme moodTheme;

  const _ImpactCard({
    required this.summary,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    final positive = summary.mostPositive;
    final negative = summary.mostNegative;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What affected today most',
              style: TextStyle(
                color: moodTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 14),
          if (positive != null)
            _ImpactRow(
              title: 'Most positive',
              item: positive,
              color: const Color(0xFF74C69D),
              moodTheme: moodTheme,
            ),
          if (positive == null)
            Text(
              'No positive mood entries above zero today.',
              style: TextStyle(color: moodTheme.mutedText),
            ),
          const SizedBox(height: 12),
          if (negative != null)
            _ImpactRow(
              title: 'Most negative',
              item: negative,
              color: const Color(0xFFFF8A7A),
              moodTheme: moodTheme,
            ),
          if (negative == null)
            Text(
              'No negative mood entries below zero today.',
              style: TextStyle(color: moodTheme.mutedText),
            ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String title;
  final _ImpactItem item;
  final Color color;
  final MoodTheme moodTheme;

  const _ImpactRow({
    required this.title,
    required this.item,
    required this.color,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: moodTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title • ${item.score}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text(
            item.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: moodTheme.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySummary {
  final String dateKey;
  final int entryCount;
  final double averageScore;
  final String overallMood;
  final String dominantEmotion;
  final int sarcasmCount;
  final List<_HourlyPoint> points;
  final _ImpactItem? mostPositive;
  final _ImpactItem? mostNegative;
  final String insight;

  _DailySummary({
    required this.dateKey,
    required this.entryCount,
    required this.averageScore,
    required this.overallMood,
    required this.dominantEmotion,
    required this.sarcasmCount,
    required this.points,
    required this.mostPositive,
    required this.mostNegative,
    required this.insight,
  });

  factory _DailySummary.empty(String dateKey) {
    return _DailySummary(
      dateKey: dateKey,
      entryCount: 0,
      averageScore: 0,
      overallMood: 'No Data',
      dominantEmotion: 'unknown',
      sarcasmCount: 0,
      points: [],
      mostPositive: null,
      mostNegative: null,
      insight: 'No mood entries found for today.',
    );
  }
}

class _HourlyPoint {
  final int hour;
  final int minute;
  final double score;

  _HourlyPoint({
    required this.hour,
    required this.minute,
    required this.score,
  });

  String get timeLabel {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _ImpactItem {
  final String text;
  final double score;
  final String emotion;

  _ImpactItem({
    required this.text,
    required this.score,
    required this.emotion,
  });
}