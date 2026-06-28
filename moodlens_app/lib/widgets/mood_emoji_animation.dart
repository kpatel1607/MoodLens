import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/mood_theme.dart';

class MoodEmojiAnimation extends StatefulWidget {
  final String mood;
  final double score;
  final MoodTheme moodTheme;

  const MoodEmojiAnimation({
    super.key,
    required this.mood,
    required this.score,
    required this.moodTheme,
  });

  @override
  State<MoodEmojiAnimation> createState() => _MoodEmojiAnimationState();
}

class _MoodEmojiAnimationState extends State<MoodEmojiAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _float;

  int _emojiIndex = 0;
  Timer? _timer;

  List<String> get _emojis {
    final mood = widget.mood.toLowerCase();

    if (mood.contains('sarcasm')) {
      return ['🙃', '😏', '😮‍💨'];
    }

    if (mood.contains('positive')) {
      return ['😊', '✨', '😌'];
    }

    if (mood.contains('negative')) {
      return ['😞', '😤', '🌧️'];
    }

    return ['😐', '🌙', '🫧'];
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _float = Tween<double>(
      begin: -4,
      end: 4,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) return;

        setState(() {
          _emojiIndex = (_emojiIndex + 1) % _emojis.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _moodLabel {
    final mood = widget.mood;

    if (mood.trim().isEmpty) {
      return 'Waiting for your mood';
    }

    return mood;
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[_emojiIndex];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.moodTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.moodTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.moodTheme.accent.withOpacity(0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                emoji,
                key: ValueKey(emoji),
                style: const TextStyle(
                  fontSize: 46,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _moodLabel,
                    style: TextStyle(
                      color: widget.moodTheme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Mood score: ${widget.score.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: widget.moodTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}