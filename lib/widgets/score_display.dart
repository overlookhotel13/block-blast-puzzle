/// score_display.dart
/// Animated score widget shown in the game HUD.
/// Uses an implicit animation to count up to the new score value whenever
/// it changes, giving satisfying visual feedback on clears.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Displays the current session score with an animated count-up.
class ScoreDisplay extends StatefulWidget {
  /// Current score to display
  final int score;

  /// High score to display below the main score
  final int highScore;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.highScore,
  });

  @override
  State<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;

    // Short controller for the count-up animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(ScoreDisplay old) {
    super.didUpdateWidget(old);
    if (widget.score != old.score) {
      _previousScore = old.score;
      // Restart the animation every time the score changes
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main score (animated) ─────────────────────────────
        AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            final displayed = (_previousScore +
                    (_animation.value * (widget.score - _previousScore)))
                .round();
            return Text(
              formatScore(displayed),
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kColorTextPrimary,
                letterSpacing: 1.2,
              ),
            );
          },
        ),

        // ── Best score label ──────────────────────────────────
        Text(
          'BEST ${formatScore(widget.highScore)}',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kColorTextSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
