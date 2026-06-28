import 'package:flutter/material.dart';

import '../services/analytics_depth_service.dart';
import '../services/mood_analytics_service.dart';
import '../services/theme_service.dart';
import '../theme/mood_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final MoodAnalyticsService _analyticsService = MoodAnalyticsService();

  MoodInsightsSummary? _summary;

  bool _isLoading = true;

  int _selectedPresetDays = 7;
  int _selectedTabIndex = 0;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final List<int> _presetDays = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadPresetRange(7);
  }

  Future<void> _loadPresetRange(int days) async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final end = DateTime(now.year, now.month, now.day);

    setState(() {
      _isLoading = true;
      _selectedPresetDays = days;
      _customStartDate = null;
      _customEndDate = null;
    });

    await _loadRange(startDate: start, endDate: end);
  }

  Future<void> _loadRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final summary = await _analyticsService.getInsights(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summary = MoodInsightsSummary.empty(
          startDate: startDate,
          endDate: endDate,
          isCloudMode: false,
        );
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load insights: $e')));
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
    );

    if (picked == null) return;

    setState(() {
      _selectedPresetDays = 0;
      _customStartDate = picked.start;
      _customEndDate = picked.end;
      _isLoading = true;
    });

    await _loadRange(startDate: picked.start, endDate: picked.end);
  }

  String _rangeLabel() {
    final summary = _summary;

    if (summary == null) return 'Loading';

    if (_customStartDate != null && _customEndDate != null) {
      return '${_dateShort(_customStartDate!)} - ${_dateShort(_customEndDate!)}';
    }

    return 'Last $_selectedPresetDays days';
  }

  String _dateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Color _scoreColor(double score) {
    if (score > 0) return const Color(0xFF74C69D);
    if (score < 0) return const Color(0xFFFF8A7A);

    return const Color(0xFFFFB84D);
  }

  String _scoreEmoji(double score, int sarcasmCount) {
    if (sarcasmCount > 0 && score <= 0) return '🙃';
    if (score > 0) return '😊';
    if (score < 0) return '😞';

    return '😐';
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

        return ValueListenableBuilder<String>(
          valueListenable: AnalyticsDepthService.selectedDepthNotifier,
          builder: (context, analyticsDepth, _) {
            final depthConfig = _AnalyticsDepthConfig.fromDepth(analyticsDepth);
            final selectedTabIndex = _selectedTabIndex.clamp(
              0,
              depthConfig.tabs.length - 1,
            );

            return Scaffold(
              backgroundColor: moodTheme.background,
              appBar: AppBar(
                backgroundColor: moodTheme.background,
                foregroundColor: moodTheme.text,
                title: const Text('View Insights'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _RangeHeader(
                    moodTheme: moodTheme,
                    label: _rangeLabel(),
                    isCloudMode: summary?.isCloudMode ?? false,
                    analyticsDepth: analyticsDepth,
                    onCustomTap: _pickCustomRange,
                  ),
                  const SizedBox(height: 14),
                  _PresetSelector(
                    moodTheme: moodTheme,
                    presetDays: _presetDays,
                    selectedDays: _selectedPresetDays,
                    onSelected: _loadPresetRange,
                  ),
                  const SizedBox(height: 16),
                  _TabSelector(
                    moodTheme: moodTheme,
                    tabs: depthConfig.tabs,
                    selectedIndex: selectedTabIndex,
                    onChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: moodTheme.accent,
                        ),
                      ),
                    )
                  else if (summary != null)
                    _SelectedInsightSection(
                      tab: depthConfig.tabs[selectedTabIndex],
                      summary: summary,
                      moodTheme: moodTheme,
                      depthConfig: depthConfig,
                      scoreColor: _scoreColor,
                      scoreEmoji: _scoreEmoji,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsDepthConfig {
  final List<String> tabs;
  final bool showImpactGrid;
  final bool showEntryText;
  final bool showEntryDiagnostics;
  final bool showTrendEntryCounts;
  final bool showResearchMetrics;

  const _AnalyticsDepthConfig({
    required this.tabs,
    required this.showImpactGrid,
    required this.showEntryText,
    required this.showEntryDiagnostics,
    required this.showTrendEntryCounts,
    required this.showResearchMetrics,
  });

  factory _AnalyticsDepthConfig.fromDepth(String depth) {
    if (depth == 'Simple') {
      return const _AnalyticsDepthConfig(
        tabs: ['Overview'],
        showImpactGrid: false,
        showEntryText: false,
        showEntryDiagnostics: false,
        showTrendEntryCounts: false,
        showResearchMetrics: false,
      );
    }

    if (depth == 'Deep') {
      return const _AnalyticsDepthConfig(
        tabs: ['Overview', 'Trends', 'Emotions', 'Entries'],
        showImpactGrid: true,
        showEntryText: true,
        showEntryDiagnostics: true,
        showTrendEntryCounts: true,
        showResearchMetrics: false,
      );
    }

    if (depth == 'Research Mode') {
      return const _AnalyticsDepthConfig(
        tabs: ['Overview', 'Trends', 'Emotions', 'Entries', 'Signals'],
        showImpactGrid: true,
        showEntryText: true,
        showEntryDiagnostics: true,
        showTrendEntryCounts: true,
        showResearchMetrics: true,
      );
    }

    return const _AnalyticsDepthConfig(
      tabs: ['Overview', 'Trends', 'Emotions'],
      showImpactGrid: true,
      showEntryText: false,
      showEntryDiagnostics: false,
      showTrendEntryCounts: false,
      showResearchMetrics: false,
    );
  }
}

class _RangeHeader extends StatelessWidget {
  final MoodTheme moodTheme;
  final String label;
  final bool isCloudMode;
  final String analyticsDepth;
  final VoidCallback onCustomTap;

  const _RangeHeader({
    required this.moodTheme,
    required this.label,
    required this.isCloudMode,
    required this.analyticsDepth,
    required this.onCustomTap,
  });

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
          Icon(Icons.insights, color: moodTheme.accent, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Insights',
                  style: TextStyle(
                    color: moodTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$label • ${isCloudMode ? 'Cloud' : 'Local'}',
                  style: TextStyle(color: moodTheme.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  analyticsDepth,
                  style: TextStyle(
                    color: moodTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCustomTap,
            icon: Icon(Icons.date_range, color: moodTheme.accent),
            tooltip: 'Custom date range',
          ),
        ],
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final MoodTheme moodTheme;
  final List<int> presetDays;
  final int selectedDays;
  final ValueChanged<int> onSelected;

  const _PresetSelector({
    required this.moodTheme,
    required this.presetDays,
    required this.selectedDays,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...presetDays.map((days) {
          final selected = selectedDays == days;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text('${days}D'),
                selectedColor: moodTheme.accent,
                backgroundColor: moodTheme.card,
                side: BorderSide(color: moodTheme.border),
                labelStyle: TextStyle(
                  color: selected ? Colors.black : moodTheme.text,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => onSelected(days),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TabSelector extends StatelessWidget {
  final MoodTheme moodTheme;
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TabSelector({
    required this.moodTheme,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: moodTheme.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? moodTheme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.black : moodTheme.mutedText,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SelectedInsightSection extends StatelessWidget {
  final String tab;
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final _AnalyticsDepthConfig depthConfig;
  final Color Function(double score) scoreColor;
  final String Function(double score, int sarcasmCount) scoreEmoji;

  const _SelectedInsightSection({
    required this.tab,
    required this.summary,
    required this.moodTheme,
    required this.depthConfig,
    required this.scoreColor,
    required this.scoreEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (tab == 'Overview') {
      return _OverviewSection(
        summary: summary,
        moodTheme: moodTheme,
        depthConfig: depthConfig,
        scoreColor: scoreColor,
        scoreEmoji: scoreEmoji,
      );
    }

    if (tab == 'Trends') {
      return _TrendsSection(
        summary: summary,
        moodTheme: moodTheme,
        depthConfig: depthConfig,
        scoreColor: scoreColor,
        scoreEmoji: scoreEmoji,
      );
    }

    if (tab == 'Emotions') {
      return _EmotionsSection(summary: summary, moodTheme: moodTheme);
    }

    if (tab == 'Signals') {
      return _SignalsSection(summary: summary, moodTheme: moodTheme);
    }

    return _EntriesSection(
      summary: summary,
      moodTheme: moodTheme,
      depthConfig: depthConfig,
      scoreColor: scoreColor,
      scoreEmoji: scoreEmoji,
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final _AnalyticsDepthConfig depthConfig;
  final Color Function(double score) scoreColor;
  final String Function(double score, int sarcasmCount) scoreEmoji;

  const _OverviewSection({
    required this.summary,
    required this.moodTheme,
    required this.depthConfig,
    required this.scoreColor,
    required this.scoreEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroScoreCard(
          summary: summary,
          moodTheme: moodTheme,
          scoreColor: scoreColor(summary.averageScore),
          emoji: scoreEmoji(summary.averageScore, summary.sarcasmCount),
        ),
        const SizedBox(height: 14),
        _InsightTextCard(text: summary.insight, moodTheme: moodTheme),
        if (depthConfig.showImpactGrid) ...[
          const SizedBox(height: 14),
          _ImpactGrid(
            summary: summary,
            moodTheme: moodTheme,
            showResearchMetrics: depthConfig.showResearchMetrics,
          ),
        ],
      ],
    );
  }
}

class _HeroScoreCard extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final Color scoreColor;
  final String emoji;

  const _HeroScoreCard({
    required this.summary,
    required this.moodTheme,
    required this.scoreColor,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: moodTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  summary.overallMood,
                  style: TextStyle(
                    color: moodTheme.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            summary.averageScore.toString(),
            style: TextStyle(
              color: scoreColor,
              fontSize: 46,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Average mood score from ${summary.entryCount} entries',
            style: TextStyle(color: moodTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _InsightTextCard extends StatelessWidget {
  final String text;
  final MoodTheme moodTheme;

  const _InsightTextCard({required this.text, required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: moodTheme.mutedText, height: 1.45),
      ),
    );
  }
}

class _ImpactGrid extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final bool showResearchMetrics;

  const _ImpactGrid({
    required this.summary,
    required this.moodTheme,
    required this.showResearchMetrics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _MiniMetricCard(
              title: 'Entries',
              value: '${summary.entryCount}',
              moodTheme: moodTheme,
            ),
            const SizedBox(width: 10),
            _MiniMetricCard(
              title: 'Sarcasm',
              value: '${summary.sarcasmPercentage}%',
              moodTheme: moodTheme,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MiniMetricCard(
              title: 'Best Day',
              value: summary.bestDay?.averageScore.toString() ?? '--',
              moodTheme: moodTheme,
            ),
            const SizedBox(width: 10),
            _MiniMetricCard(
              title: 'Worst Day',
              value: summary.worstDay?.averageScore.toString() ?? '--',
              moodTheme: moodTheme,
            ),
          ],
        ),
        if (showResearchMetrics) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniMetricCard(
                title: 'Dominant',
                value: summary.dominantEmotion,
                moodTheme: moodTheme,
              ),
              const SizedBox(width: 10),
              _MiniMetricCard(
                title: 'Sarcasm Hits',
                value: '${summary.sarcasmCount}',
                moodTheme: moodTheme,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final MoodTheme moodTheme;

  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: moodTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: moodTheme.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: moodTheme.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(color: moodTheme.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendsSection extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final _AnalyticsDepthConfig depthConfig;
  final Color Function(double score) scoreColor;
  final String Function(double score, int sarcasmCount) scoreEmoji;

  const _TrendsSection({
    required this.summary,
    required this.moodTheme,
    required this.depthConfig,
    required this.scoreColor,
    required this.scoreEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.dailyAverages.isEmpty) {
      return _EmptyCard(moodTheme: moodTheme, text: 'No trend data found.');
    }

    return Column(
      children: [
        _SectionHeader(
          title: 'Daily Mood Trend',
          subtitle: 'Average score per day',
          moodTheme: moodTheme,
        ),
        const SizedBox(height: 12),
        ...summary.dailyAverages.map((point) {
          final color = scoreColor(point.averageScore);

          return _TrendRow(
            date: point.dateKey,
            score: point.averageScore,
            entryCount: point.entryCount,
            color: color,
            emoji: scoreEmoji(point.averageScore, 0),
            moodTheme: moodTheme,
            showEntryCount: depthConfig.showTrendEntryCounts,
          );
        }),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  final String date;
  final double score;
  final int entryCount;
  final Color color;
  final String emoji;
  final MoodTheme moodTheme;
  final bool showEntryCount;

  const _TrendRow({
    required this.date,
    required this.score,
    required this.entryCount,
    required this.color,
    required this.emoji,
    required this.moodTheme,
    required this.showEntryCount,
  });

  @override
  Widget build(BuildContext context) {
    final widthFactor = (score.abs() / 100).clamp(0.08, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: moodTheme.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              date.substring(5),
              style: TextStyle(
                color: moodTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: moodTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            showEntryCount
                ? '${score.toString()} / $entryCount'
                : score.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmotionsSection extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;

  const _EmotionsSection({required this.summary, required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    if (summary.emotionDistribution.isEmpty) {
      return _EmptyCard(moodTheme: moodTheme, text: 'No emotion data found.');
    }

    return Column(
      children: [
        _SectionHeader(
          title: 'Emotion Distribution',
          subtitle: 'Most repeated emotional patterns',
          moodTheme: moodTheme,
        ),
        const SizedBox(height: 12),
        ...summary.emotionDistribution.map(
          (item) => _EmotionBar(item: item, moodTheme: moodTheme),
        ),
      ],
    );
  }
}

class _EmotionBar extends StatelessWidget {
  final EmotionInsightItem item;
  final MoodTheme moodTheme;

  const _EmotionBar({required this.item, required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    final widthFactor = (item.percentage / 100).clamp(0.05, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: moodTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.emotion,
                  style: TextStyle(
                    color: moodTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${item.percentage}%',
                style: TextStyle(
                  color: moodTheme.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 9,
                decoration: BoxDecoration(
                  color: moodTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: widthFactor,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: moodTheme.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntriesSection extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;
  final _AnalyticsDepthConfig depthConfig;
  final Color Function(double score) scoreColor;
  final String Function(double score, int sarcasmCount) scoreEmoji;

  const _EntriesSection({
    required this.summary,
    required this.moodTheme,
    required this.depthConfig,
    required this.scoreColor,
    required this.scoreEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.entryPoints.isEmpty) {
      return _EmptyCard(moodTheme: moodTheme, text: 'No entries found.');
    }

    return Column(
      children: [
        _SectionHeader(
          title: 'Entries',
          subtitle: 'Every mood check in selected range',
          moodTheme: moodTheme,
        ),
        const SizedBox(height: 12),
        ...summary.entryPoints.reversed.map((point) {
          final color = scoreColor(point.score);

          return _EntryCard(
            point: point,
            color: color,
            emoji: scoreEmoji(point.score, point.sarcasmCount),
            moodTheme: moodTheme,
            showText: depthConfig.showEntryText,
            showDiagnostics: depthConfig.showEntryDiagnostics,
          );
        }),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EntryInsightPoint point;
  final Color color;
  final String emoji;
  final MoodTheme moodTheme;
  final bool showText;
  final bool showDiagnostics;

  const _EntryCard({
    required this.point,
    required this.color,
    required this.emoji,
    required this.moodTheme,
    required this.showText,
    required this.showDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodTheme.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${point.dateKey.substring(5)} • ${point.timeLabel}',
                  style: TextStyle(
                    color: moodTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showText) ...[
                  const SizedBox(height: 4),
                  Text(
                    point.text,
                    maxLines: showDiagnostics ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: moodTheme.mutedText, height: 1.35),
                  ),
                ],
                if (showDiagnostics) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${point.mood} / ${point.emotion} / sarcasm ${point.sarcasmCount}',
                    style: TextStyle(
                      color: moodTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            point.score.toStringAsFixed(1),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SignalsSection extends StatelessWidget {
  final MoodInsightsSummary summary;
  final MoodTheme moodTheme;

  const _SignalsSection({required this.summary, required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    final strongestEmotion = summary.emotionDistribution.isEmpty
        ? 'unknown'
        : summary.emotionDistribution.first.emotion;
    final volatility = summary.dailyAverages.length < 2
        ? 0.0
        : _scoreRange(summary.dailyAverages);

    return Column(
      children: [
        _SectionHeader(
          title: 'Research Signals',
          subtitle: 'Rawer pattern markers for deeper review',
          moodTheme: moodTheme,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniMetricCard(
              title: 'Score Range',
              value: volatility.toStringAsFixed(1),
              moodTheme: moodTheme,
            ),
            const SizedBox(width: 10),
            _MiniMetricCard(
              title: 'Top Emotion',
              value: strongestEmotion,
              moodTheme: moodTheme,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MiniMetricCard(
              title: 'Sarcasm Rate',
              value: '${summary.sarcasmPercentage}%',
              moodTheme: moodTheme,
            ),
            const SizedBox(width: 10),
            _MiniMetricCard(
              title: 'Entry Count',
              value: '${summary.entryCount}',
              moodTheme: moodTheme,
            ),
          ],
        ),
      ],
    );
  }

  double _scoreRange(List<DailyInsightPoint> points) {
    final scores = points.map((point) => point.averageScore).toList();
    scores.sort();

    return scores.last - scores.first;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final MoodTheme moodTheme;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: moodTheme.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final MoodTheme moodTheme;
  final String text;

  const _EmptyCard({required this.moodTheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Text(text, style: TextStyle(color: moodTheme.mutedText)),
    );
  }
}
