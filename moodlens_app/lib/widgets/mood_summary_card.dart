import 'package:flutter/material.dart';

import '../models/moodlens_result.dart';
import '../theme/mood_theme.dart';

class MoodSummaryCard extends StatelessWidget {
  final MoodOverall overall;
  final MoodTheme moodTheme;

  const MoodSummaryCard({
    super.key,
    required this.overall,
    required this.moodTheme,
  });

  Color _scoreColor(double score) {
    if (score > 20) return const Color(0xFF74C69D);
    if (score < -20) return const Color(0xFFFF8A7A);
    return const Color(0xFFFFB84D);
  }

  Color _trendColor(String trend) {
    final t = trend.toLowerCase();

    if (t.contains('positive')) return const Color(0xFF74C69D);
    if (t.contains('negative')) return const Color(0xFFFF8A7A);
    if (t.contains('sarcastic')) return const Color(0xFFFFB84D);

    return moodTheme.mutedText;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(overall.moodScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: moodTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: moodTheme.accent.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Mood',
            style: TextStyle(
              color: moodTheme.mutedText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overall.overallMood,
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InfoChip(
                title: 'Score',
                value: overall.moodScore.toStringAsFixed(1),
                color: scoreColor,
                moodTheme: moodTheme,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                title: 'Emotion',
                value: overall.dominantEmotion,
                color: moodTheme.accent,
                moodTheme: moodTheme,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                title: 'Sarcasm',
                value: '${overall.sarcasmCount}',
                color: const Color(0xFFFFB84D),
                moodTheme: moodTheme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: overall.trend
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: _trendColor(item).withOpacity(0.12),
                    side: BorderSide(
                      color: _trendColor(item).withOpacity(0.45),
                    ),
                    labelStyle: TextStyle(
                      color: _trendColor(item),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final MoodTheme moodTheme;

  const _InfoChip({
    required this.title,
    required this.value,
    required this.color,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: moodTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: moodTheme.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: moodTheme.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}