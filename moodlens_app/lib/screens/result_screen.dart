import 'package:flutter/material.dart';

import '../models/moodlens_result.dart';
import '../theme/mood_theme.dart';
import '../widgets/mood_summary_card.dart';
import '../widgets/statement_card.dart';
import '../widgets/mood_emoji_animation.dart';
import '../widgets/mood_timeline.dart';
import '../services/theme_service.dart';

class ResultScreen extends StatelessWidget {
  final MoodLensResult result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<String>(
      valueListenable: ThemeService.selectedThemeNotifier,
      builder: (context, selectedTheme, _) {
        final moodTheme = MoodThemes.fromProfileTheme(
          selectedTheme,
          result.overall.overallMood,
        );

        return Scaffold(
          backgroundColor: moodTheme.background,
          appBar: AppBar(
            backgroundColor: moodTheme.background,
            foregroundColor: moodTheme.text,
            elevation: 0,
            title: const Text('Mood Result'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [

              MoodEmojiAnimation(
                mood: result.overall.overallMood,
                score: result.overall.moodScore,
                moodTheme: moodTheme,
              ),

              const SizedBox(height: 16),

              MoodSummaryCard(
                overall: result.overall,
                moodTheme: moodTheme,
              ),

              const SizedBox(height: 16),

              MoodTimeline(
                result: result,
                moodTheme: moodTheme,
              ),

              const SizedBox(height: 22),

              Text(
                'Statement Breakdown',
                style: TextStyle(
                  color: moodTheme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...result.statements
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    StatementCard(
                      statement: entry.value,
                      index: entry.key,
                      moodTheme: moodTheme,
                    ),
              ),
            ],
          ),
        );
      }
    );
  }
}