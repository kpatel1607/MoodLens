import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cloud_history_service.dart';
import '../services/local_history_service.dart';
import '../services/moodlens_api_service.dart';
import '../theme/mood_theme.dart';
import '../services/theme_service.dart';

import 'analytics_screen.dart';
import 'daily_summary_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  final MoodLensApiService _apiService = MoodLensApiService();
  final LocalHistoryService _historyService = LocalHistoryService();
  final CloudHistoryService _cloudHistoryService = CloudHistoryService();
  final AuthService _authService = AuthService();

  final List<String> _demoTexts = [
    "I woke up late. My laptop crashed before class. Great, perfect start to the day. But I still completed my work.",
    "I passed my exam. I am extremely happy. My parents are proud of me.",
    "The server crashed. Great. Exactly what I needed.",
    "My project got deleted. Wonderful. I spent two weeks on it.",
    "Today was peaceful. I finished my tasks. I feel satisfied with my progress.",
    "I missed my bus. Then it started raining. What an amazing morning.",
    "My friend surprised me with a gift. It completely made my day.",
    "I worked for six hours debugging. The issue was a missing semicolon. Fantastic.",
    "The interview went better than expected. I feel hopeful about the future.",
    "I studied hard for weeks. The exam got postponed again. Lovely.",
    "I completed my workout today. I feel stronger and more energetic.",
    "The internet stopped working during my presentation. Perfect timing.",
    "I finally finished my AI project. Everything is working correctly now.",
    "My code failed five minutes before the deadline. This is fine.",
    "I spent the evening with family. It was relaxing and enjoyable.",
    "Another meeting that could have been an email. Wonderful.",
    "I received positive feedback from my mentor. That boosted my confidence.",
    "I forgot to save the document. Hours of work disappeared instantly.",
    "The weather was beautiful today. I went for a long walk and felt refreshed.",
    "My alarm never rang. I missed the most important class of the week. Amazing."
  ];

  bool _isLoading = false;
  String? _error;

  Future<void> _analyze() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.analyzeSequence(
        _controller.text,
      );

      await _historyService.saveResult(result);

      try {
        await _cloudHistoryService.saveResult(result);
      } catch (_) {}

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(
                result: result,
              ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _insertDemo() {
    final random = Random();

    _controller.text = _demoTexts[
    random.nextInt(_demoTexts.length)
    ];
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
      ),
    );
  }

  void _openTodaySummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailySummaryScreen(),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(),
      ),
    );
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

          return AnimatedTheme(
            duration: const Duration(milliseconds: 500),
            data: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: moodTheme.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: moodTheme.accent,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            child: Scaffold(
              backgroundColor: moodTheme.background,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: StreamBuilder<User?>(
                          stream: _authService.authStateChanges(),
                          builder: (context, snapshot) {
                            final user = snapshot.data;

                            return _Header(
                              user: user,
                              onAccountTap: _openProfile,
                              onDemoTap: _insertDemo,
                              onHistoryTap: _openHistory,
                              onTodayTap: _openTodaySummary,
                              onAnalyticsTap: _openAnalytics,
                              moodTheme: moodTheme,
                            );
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: _InputCard(
                          controller: _controller,
                          isLoading: _isLoading,
                          onAnalyze: _analyze,
                          moodTheme: moodTheme,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      SliverPadding(
                        padding: const EdgeInsets.all(28),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: moodTheme.accent,
                            ),
                          ),
                        ),
                      ),
                    if (_error != null)
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverToBoxAdapter(
                          child: _ErrorBox(
                            message: _error!,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                      sliver: SliverToBoxAdapter(
                        child: _QuickActionsSection(
                          moodTheme: moodTheme,
                          onTodayTap: _openTodaySummary,
                          onAnalyticsTap: _openAnalytics,
                          onHistoryTap: _openHistory,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      sliver: SliverToBoxAdapter(
                        child: _InfoSection(
                          moodTheme: moodTheme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;
  final VoidCallback onAccountTap;
  final VoidCallback onDemoTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onTodayTap;
  final VoidCallback onAnalyticsTap;
  final MoodTheme moodTheme;

  const _Header({
    required this.user,
    required this.onAccountTap,
    required this.onDemoTap,
    required this.onHistoryTap,
    required this.onTodayTap,
    required this.onAnalyticsTap,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = user != null && !user!.isAnonymous;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MoodLens',
                style: TextStyle(
                  color: moodTheme.text,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLoggedIn
                    ? 'Signed in • mood history sync enabled.'
                    : 'Analyze emotions, sarcasm and mood flow.',
                style: TextStyle(
                  color: moodTheme.mutedText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAccountTap,
          icon: user?.photoURL != null && isLoggedIn
              ? CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(user!.photoURL!),
                )
              : Icon(
                  isLoggedIn ? Icons.verified_user : Icons.account_circle,
                  color: moodTheme.accent,
                ),
          tooltip: isLoggedIn ? 'Profile' : 'Login / Profile',
        ),
        IconButton(
          onPressed: onDemoTap,
          icon: Icon(
            Icons.auto_awesome,
            color: moodTheme.accent,
          ),
          tooltip: 'Insert demo',
        ),
        PopupMenuButton<String>(
          color: moodTheme.card,
          iconColor: moodTheme.accent,
          onSelected: (value) {
            if (value == 'today') {
              onTodayTap();
            } else if (value == 'analytics') {
              onAnalyticsTap();
            } else if (value == 'history') {
              onHistoryTap();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'today',
              child: Row(
                children: [
                  Icon(
                    Icons.today,
                    color: moodTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  const Text('Today Summary'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(
                    Icons.query_stats,
                    color: moodTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  const Text('Analytics'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: moodTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  const Text('History'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAnalyze;
  final MoodTheme moodTheme;

  const _InputCard({
    required this.controller,
    required this.isLoading,
    required this.onAnalyze,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: moodTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: moodTheme.accent.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: 10,
            style: TextStyle(
              color: moodTheme.text,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText:
                  'Write a journal entry, message, or sequence of statements...',
              hintStyle: TextStyle(
                color: moodTheme.mutedText.withOpacity(0.75),
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: moodTheme.accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: moodTheme.border,
              ),
              onPressed: isLoading ? null : onAnalyze,
              icon: const Icon(Icons.psychology_alt),
              label: Text(
                isLoading ? 'Analyzing...' : 'Analyze Mood',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final MoodTheme moodTheme;
  final VoidCallback onTodayTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onHistoryTap;

  const _QuickActionsSection({
    required this.moodTheme,
    required this.onTodayTap,
    required this.onAnalyticsTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionCard(
          title: 'Today',
          subtitle: 'Daily mood',
          icon: Icons.today,
          moodTheme: moodTheme,
          onTap: onTodayTap,
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          title: 'Analytics',
          subtitle: 'View mood insights',
          icon: Icons.query_stats,
          moodTheme: moodTheme,
          onTap: onAnalyticsTap,
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          title: 'History',
          subtitle: 'Past checks',
          icon: Icons.history,
          moodTheme: moodTheme,
          onTap: onHistoryTap,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MoodTheme moodTheme;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.moodTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: moodTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: moodTheme.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: moodTheme.accent,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: moodTheme.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: moodTheme.mutedText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final MoodTheme moodTheme;

  const _InfoSection({
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: moodTheme.card.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: moodTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What MoodLens checks',
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoPoint(
            icon: Icons.favorite_border,
            text: 'Detects emotions across multiple statements.',
            moodTheme: moodTheme,
          ),
          _InfoPoint(
            icon: Icons.theater_comedy_outlined,
            text: 'Finds sarcasm and hidden emotional tone.',
            moodTheme: moodTheme,
          ),
          _InfoPoint(
            icon: Icons.timeline,
            text: 'Shows how your mood changes through the text.',
            moodTheme: moodTheme,
          ),
          _InfoPoint(
            icon: Icons.calendar_month,
            text: 'Builds daily, weekly and monthly mood patterns.',
            moodTheme: moodTheme,
          ),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  final MoodTheme moodTheme;

  const _InfoPoint({
    required this.icon,
    required this.text,
    required this.moodTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: moodTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: moodTheme.mutedText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.5),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
        ),
      ),
    );
  }
}