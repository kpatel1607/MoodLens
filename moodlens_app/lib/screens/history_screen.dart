import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/local_history_service.dart';
import '../services/theme_service.dart';
import '../theme/mood_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LocalHistoryService _localHistoryService =
      LocalHistoryService();

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isCloudMode = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.isAnonymous) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('mood_entries')
            .orderBy(
              'created_at',
              descending: true,
            )
            .get();

        final cloudItems = snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          _history = cloudItems;
          _isCloudMode = true;
          _isLoading = false;
        });

        return;
      }

      final localItems =
          await _localHistoryService.getHistory();

      if (!mounted) return;

      setState(() {
        _history = localItems;
        _isCloudMode = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _history = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load history: $e',
          ),
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.isAnonymous) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mood_entries')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      await _localHistoryService.clearHistory();
    }

    await _loadHistory();
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in items) {
      final dateKey =
          item['date_key']?.toString() ?? 'Unknown Date';

      grouped.putIfAbsent(
        dateKey,
        () => [],
      );

      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  String _timeLabel(Map<String, dynamic> item) {
    final hour = item['hour'] ?? 0;
    final minute = item['minute'] ?? 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeService.selectedThemeNotifier,
      builder: (context, selectedTheme, _) {
        final moodTheme = MoodThemes.fromProfileTheme(
          selectedTheme,
          null,
        );

        final grouped = _groupByDate(_history);
        final dateKeys = grouped.keys.toList();

        return Scaffold(
          backgroundColor: moodTheme.background,
          appBar: AppBar(
            backgroundColor: moodTheme.background,
            foregroundColor: moodTheme.text,
            title: Text(
              _isCloudMode ? 'Cloud History' : 'Local History',
            ),
            actions: [
              if (_history.isNotEmpty)
                IconButton(
                  onPressed: _clearHistory,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: moodTheme.accent,
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Text(
                        'No mood history yet.',
                        style: TextStyle(
                          color: moodTheme.mutedText,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: dateKeys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = dateKeys[dateIndex];
                        final items = grouped[dateKey] ?? [];

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateKey,
                              style: TextStyle(
                                color: moodTheme.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            ...items.map(
                              (item) => _HistoryItemCard(
                                item: item,
                                timeLabel: _timeLabel(item),
                                selectedTheme: selectedTheme,
                              ),
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                          ],
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String timeLabel;
  final String selectedTheme;

  const _HistoryItemCard({
    required this.item,
    required this.timeLabel,
    required this.selectedTheme,
  });

  @override
  Widget build(BuildContext context) {
    final overall =
        item['overall'] as Map<String, dynamic>? ?? {};

    final mood = overall['overall_mood'] ?? 'Unknown';
    final score = overall['mood_score'] ?? 0;
    final emotion =
        overall['dominant_emotion'] ?? 'unknown';
    final sarcasm = overall['sarcasm_count'] ?? 0;

    final itemTheme = MoodThemes.fromProfileTheme(
      selectedTheme,
      mood.toString(),
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: itemTheme.card,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: itemTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MoodEmoji(
                mood: mood.toString(),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  mood.toString(),
                  style: TextStyle(
                    color: itemTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: TextStyle(
                  color: itemTheme.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            item['input_text'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: itemTheme.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryTag(
                label: 'Score $score',
                color: itemTheme.accent,
              ),
              _HistoryTag(
                label: emotion.toString(),
                color: itemTheme.accent,
              ),
              _HistoryTag(
                label: 'Sarcasm $sarcasm',
                color: const Color(
                  0xFFFFB84D,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  final String mood;

  const _MoodEmoji({
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final m = mood.toLowerCase();

    final emoji = m.contains('positive')
        ? '😊'
        : m.contains('negative')
            ? '😞'
            : m.contains('sarcasm')
                ? '🙃'
                : '😐';

    return Text(
      emoji,
      style: const TextStyle(
        fontSize: 24,
      ),
    );
  }
}

class _HistoryTag extends StatelessWidget {
  final String label;
  final Color color;

  const _HistoryTag({
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
        color: color.withOpacity(
          0.12,
        ),
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: color.withOpacity(
            0.45,
          ),
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