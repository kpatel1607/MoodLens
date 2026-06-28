import 'package:flutter/material.dart';

import '../models/moodlens_result.dart';
import '../theme/mood_theme.dart';

class StatementCard extends StatelessWidget {
  final MoodStatement statement;
  final int index;
  final MoodTheme moodTheme;

  const StatementCard({
    super.key,
    required this.statement,
    required this.index,
    required this.moodTheme,
  });

  Color get sentimentColor {
    final s = statement.sentiment.toLowerCase();

    if (s.contains('positive')) {
      return const Color(0xFF74C69D);
    }

    if (s.contains('negative')) {
      return const Color(0xFFFF8A7A);
    }

    if (s.contains('sarcastic')) {
      return const Color(0xFFFFB84D);
    }

    return moodTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    final isSarcastic =
        statement.sarcasmLabel.toLowerCase().contains('sarcastic');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSarcastic
              ? const Color(0xFFFFB84D).withOpacity(0.6)
              : moodTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: moodTheme.accent.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statement ${index + 1}',
            style: TextStyle(
              color: moodTheme.mutedText,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            statement.text,
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                label:
                    '${statement.primaryEmotion} ${statement.emotionScore.toStringAsFixed(1)}%',
                color: moodTheme.accent,
              ),

              _Tag(
                label:
                    '${statement.sarcasmLabel} ${statement.sarcasmScore.toStringAsFixed(1)}%',
                color: isSarcastic
                    ? const Color(0xFFFFB84D)
                    : const Color(0xFF74C69D),
              ),

              _Tag(
                label: statement.sentiment,
                color: sentimentColor,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            statement.interpretation,
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}