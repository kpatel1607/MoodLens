import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/analytics_depth_service.dart';
import '../services/profile_settings_service.dart';
import '../theme/mood_theme.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileSettingsService _settingsService = ProfileSettingsService();

  String _theme = 'Mood Based';
  String _emojiStyle = 'Soft Emojis';
  String _analyticsDepth = 'Balanced';
  String _privacyMode = 'Private';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _settingsService.getTheme();
    final emoji = await _settingsService.getEmojiStyle();
    final analytics = await _settingsService.getAnalyticsDepth();
    final privacy = await _settingsService.getPrivacyMode();

    if (!mounted) return;

    setState(() {
      _theme = theme;
      _emojiStyle = emoji;
      _analyticsDepth = analytics;
      _privacyMode = privacy;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    await _authService.ensureAnonymousLogin();

    if (!mounted) return;

    Navigator.pop(context);
  }

  String _avatarEmoji(User? user) {
    if (user == null || user.isAnonymous) return '🌙';

    final name = user.displayName?.toLowerCase() ?? '';

    if (name.contains('kunj')) return '🧠';

    return '✨';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeService.selectedThemeNotifier,
      builder: (context, selectedTheme, _) {
        final moodTheme = MoodThemes.fromProfileTheme(selectedTheme, null);

        return StreamBuilder<User?>(
          stream: _authService.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isGuest = user == null || user.isAnonymous;

            return Scaffold(
              backgroundColor: moodTheme.background,
              appBar: AppBar(
                backgroundColor: moodTheme.background,
                foregroundColor: moodTheme.text,
                title: const Text('Profile'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _ProfileHero(
                    moodTheme: moodTheme,
                    user: user,
                    isGuest: isGuest,
                    emoji: _avatarEmoji(user),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Personalization', moodTheme: moodTheme),
                  const SizedBox(height: 12),
                  _OptionCard(
                    title: 'Theme Style',
                    subtitle: 'Control how MoodLens feels visually.',
                    value: _theme,
                    icon: Icons.palette_outlined,
                    options: const [
                      'Mood Based',
                      'Calm Dark',
                      'Warm Sunset',
                      'Minimal Focus',
                    ],
                    moodTheme: moodTheme,
                    onChanged: (value) async {
                      await ThemeService.saveSelectedTheme(value);

                      setState(() {
                        _theme = value;
                      });
                    },
                  ),
                  _OptionCard(
                    title: 'Emoji Personality',
                    subtitle: 'Choose how expressive the app feels.',
                    value: _emojiStyle,
                    icon: Icons.emoji_emotions_outlined,
                    options: const [
                      'Soft Emojis',
                      'Expressive Emojis',
                      'Minimal Icons',
                      'No Emojis',
                    ],
                    moodTheme: moodTheme,
                    onChanged: (value) async {
                      await _settingsService.saveEmojiStyle(value);
                      setState(() => _emojiStyle = value);
                    },
                  ),
                  _OptionCard(
                    title: 'Analytics Depth',
                    subtitle:
                        'Decide how detailed your mood analysis should be.',
                    value: _analyticsDepth,
                    icon: Icons.insights_outlined,
                    options: const [
                      'Simple',
                      'Balanced',
                      'Deep',
                      'Research Mode',
                    ],
                    moodTheme: moodTheme,
                    onChanged: (value) async {
                      await AnalyticsDepthService.saveSelectedDepth(value);
                      setState(() => _analyticsDepth = value);
                    },
                  ),
                  _OptionCard(
                    title: 'Privacy Mode',
                    subtitle: 'Control how sensitive your saved history feels.',
                    value: _privacyMode,
                    icon: Icons.lock_outline,
                    options: const [
                      'Private',
                      'Blur Text Preview',
                      'Hide Raw Text',
                      'Local Only',
                    ],
                    moodTheme: moodTheme,
                    onChanged: (value) async {
                      await _settingsService.savePrivacyMode(value);
                      setState(() => _privacyMode = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Mood Identity', moodTheme: moodTheme),
                  const SizedBox(height: 12),
                  _MoodIdentityCard(
                    moodTheme: moodTheme,
                    analyticsDepth: _analyticsDepth,
                    emojiStyle: _emojiStyle,
                    privacyMode: _privacyMode,
                  ),
                  const SizedBox(height: 18),
                  if (!isGuest)
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  if (isGuest)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Login from Home'),
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

class _ProfileHero extends StatelessWidget {
  final MoodTheme moodTheme;
  final User? user;
  final bool isGuest;
  final String emoji;

  const _ProfileHero({
    required this.moodTheme,
    required this.user,
    required this.isGuest,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: moodTheme.border),
        boxShadow: [
          BoxShadow(
            color: moodTheme.accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: moodTheme.accent.withValues(alpha: 0.18),
            backgroundImage: user?.photoURL != null && !isGuest
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null || isGuest
                ? Text(emoji, style: const TextStyle(fontSize: 38))
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest
                      ? 'Guest Mood Explorer'
                      : user?.displayName ?? 'MoodLens User',
                  style: TextStyle(
                    color: moodTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isGuest
                      ? 'Login to sync your emotional journey.'
                      : user?.email ?? 'Cloud sync enabled',
                  style: TextStyle(color: moodTheme.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final MoodTheme moodTheme;

  const _SectionTitle({required this.title, required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: moodTheme.text,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final List<String> options;
  final MoodTheme moodTheme;
  final ValueChanged<String> onChanged;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.options,
    required this.moodTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: moodTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: moodTheme.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: moodTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: moodTheme.mutedText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: moodTheme.card,
            underline: const SizedBox.shrink(),
            style: TextStyle(
              color: moodTheme.text,
              fontWeight: FontWeight.w700,
            ),
            items: options.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (selected) {
              if (selected == null) return;
              onChanged(selected);
            },
          ),
        ],
      ),
    );
  }
}

class _MoodIdentityCard extends StatelessWidget {
  final MoodTheme moodTheme;
  final String analyticsDepth;
  final String emojiStyle;
  final String privacyMode;

  const _MoodIdentityCard({
    required this.moodTheme,
    required this.analyticsDepth,
    required this.emojiStyle,
    required this.privacyMode,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your MoodLens Style',
            style: TextStyle(
              color: moodTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _MiniChip(
            label: 'Analytics: $analyticsDepth',
            color: moodTheme.accent,
          ),
          const SizedBox(height: 8),
          _MiniChip(
            label: 'Expression: $emojiStyle',
            color: const Color(0xFFFFB84D),
          ),
          const SizedBox(height: 8),
          _MiniChip(
            label: 'Privacy: $privacyMode',
            color: const Color(0xFF74C69D),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
