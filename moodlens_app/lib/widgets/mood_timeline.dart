import 'package:flutter/material.dart';

import '../models/moodlens_result.dart';
import '../theme/mood_theme.dart';

class MoodTimeline extends StatelessWidget {
  final MoodLensResult result;
  final MoodTheme moodTheme;

  const MoodTimeline({
    super.key,
    required this.result,
    required this.moodTheme,
  });

  String _emojiForTrend(String trend) {
    final t = trend.toLowerCase();

    if (t.contains('positive')) return '😊';
    if (t.contains('negative')) return '😞';
    if (t.contains('sarcastic')) return '🙃';

    return '😐';
  }

  Color _colorForTrend(String trend) {
    final t = trend.toLowerCase();

    if (t.contains('positive')) return const Color(0xFF74C69D);
    if (t.contains('negative')) return const Color(0xFFFF8A7A);
    if (t.contains('sarcastic')) return const Color(0xFFFFB84D);

    return moodTheme.mutedText;
  }

  @override
  Widget build(BuildContext context) {
    final trend = result.overall.trend;

    if (trend.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: moodTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Timeline',
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trend.length,
              separatorBuilder: (context, index) {
                return Center(
                  child: Container(
                    width: 32,
                    height: 2,
                    color: moodTheme.border,
                  ),
                );
              },
              itemBuilder: (context, index) {
                final item = trend[index];
                final color = _colorForTrend(item);

                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(0.55),
                        ),
                      ),
                      child: Text(
                        _emojiForTrend(item),
                        style: const TextStyle(
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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